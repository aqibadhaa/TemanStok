# Spesifikasi Workflow n8n: OTP Request & Verify

Dokumen desain node-demi-node untuk dua webhook yang jadi tumpuan Track A.
Ini bukan file workflow n8n asli (`.json` export) — ditulis sebagai
spesifikasi supaya begitu instance n8n sudah live, tinggal dibangun tanpa
perlu mikir ulang desain, alur, atau skema datanya.

Kontrak HTTP di bawah ini sudah disepakati dan **kode client sudah
diimplementasikan mengikuti kontrak ini** (`lib/src/services/auth_service.dart`).
Perubahan pada kontrak (nama field, kondisi respons) butuh perubahan balik
di client.

## Environment variable yang dibutuhkan (n8n)

| Variable | Isi |
|---|---|
| `FONNTE_API_KEY` | API key WhatsApp gateway. Migrasi dari `secrets.dart` lama — rotate dulu key-nya di dashboard Fonnte sebelum dipakai di sini, karena key lama sempat ter-commit plaintext ke repo. |
| `FIREBASE_SERVICE_ACCOUNT_B64` | JSON service account Firebase (Project Settings → Service Accounts → Generate new private key), di-base64-encode dulu supaya newline di `private_key` gak berantakan sebagai env var. |
| `OTP_EXPIRY_MINUTES` | Default `5`. Umur OTP sebelum dianggap kedaluwarsa. |
| `OTP_MAX_ATTEMPTS` | Default `5`. Batas percobaan salah sebelum kode dianggap terkunci. |
| `OTP_RESEND_COOLDOWN_SECONDS` | Default `60`. Jarak minimum antar-request OTP untuk nomor yang sama — ini enforcement di server, melengkapi timer 59 detik yang sudah ada di UI (yang bisa dilewati kalau orang manggil endpoint langsung tanpa lewat app). |

Node Code di n8n butuh akses ke `firebase-admin`. Kalau base image n8n
membatasi module eksternal, set `NODE_FUNCTION_ALLOW_EXTERNAL=firebase-admin`
(nama env var persis tergantung versi n8n/base image yang dipakai, cek
dokumentasi image yang dipilih saat deploy).

**Gotcha penting:** `admin.initializeApp()` cuma boleh dipanggil sekali per
proses Node.js. Karena n8n bisa menjalankan banyak eksekusi workflow dalam
satu proses yang sama, inisialisasi Admin SDK di Code node harus dijaga:

```js
const admin = require('firebase-admin');
if (!admin.apps.length) {
  const serviceAccount = JSON.parse(
    Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT_B64, 'base64').toString('utf8')
  );
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
```

## Skema Firestore: `otp_verifications/{phone}`

`{phone}` = nomor tersanitasi (format `62...`), sama persis dengan document
ID yang dipakai di `stores/{storeId}`. Koleksi ini **hanya diakses n8n lewat
Admin SDK** — `firestore.rules` sudah memblokir total akses client
(`allow read, write: if false`), jadi tidak perlu circular dependency
apa pun ke rules client.

| Field | Tipe | Keterangan |
|---|---|---|
| `otp_hash` | string | Hash OTP, bukan plaintext (lihat bagian hashing di bawah) |
| `otp_salt` | string | Salt acak per-request, hex/base64 |
| `created_at` | timestamp | Waktu OTP dibuat |
| `expires_at` | timestamp | `created_at + OTP_EXPIRY_MINUTES` |
| `attempts` | number | Jumlah percobaan verifikasi salah, mulai dari `0` |
| `verified` | boolean | `false` sampai berhasil diverifikasi (dokumen dihapus setelah sukses, lihat langkah 7 workflow verify) |
| `last_requested_at` | timestamp | Buat enforcement `OTP_RESEND_COOLDOWN_SECONDS` |

**Hashing OTP:** SHA-256 dengan salt acak per-request (bukan bcrypt) —
OTP ini punya masa berlaku pendek dan sudah dibatasi jumlah percobaan, jadi
biaya komputasi ekstra dari bcrypt tidak sepadan dengan kompleksitas
tambahan (dependency baru). Salted SHA-256 pakai modul `crypto` bawaan
Node.js, tanpa dependency tambahan:

```js
const crypto = require('crypto');
const salt = crypto.randomBytes(16).toString('hex');
const hash = crypto.createHash('sha256').update(otp + salt).digest('hex');
```

Saat verifikasi, bandingkan hash pakai `crypto.timingSafeEqual` (bukan `===`
biasa) untuk menghindari timing attack pada perbandingan string.

---

## Workflow 1: `POST /webhook/otp/request`

**Request:** `{ "phone": "62812xxxx" }`

| # | Node | Detail |
|---|---|---|
| 1 | **Webhook** (trigger) | Method `POST`, path `/webhook/otp/request`, Response Mode = "Using 'Respond to Webhook' node" (supaya status code & body dikontrol manual, bukan auto-response default n8n). |
| 2 | **Validasi & sanitasi input** (Code) | Baca `$json.body.phone`. Validasi ulang format di server — **jangan percaya sanitasi dari client begitu saja**, karena endpoint ini bisa dipanggil langsung tanpa lewat app. Regex kira-kira `^62[0-9]{8,13}$`. Kalau invalid → lempar ke node respons error (400, `{success:false, message:"Nomor tidak valid"}`). |
| 3 | **Cek cooldown resend** (Firestore read + IF) | Baca `otp_verifications/{phone}`. Kalau dokumen ada dan `now - last_requested_at < OTP_RESEND_COOLDOWN_SECONDS` → respons error (429, `{success:false, message:"Tunggu sebentar sebelum minta kode baru"}`). |
| 4 | **Generate OTP** (Code) | `crypto.randomInt(100000, 1000000).toString()` — 6 digit, numeric, pakai `crypto` bawaan (bukan `Math.random()`). |
| 5 | **Hash OTP** (Code) | Sesuai skema hashing di atas. Simpan `otp` plaintext HANYA di memory node ini untuk dikirim ke Fonnte di langkah 7 — tidak pernah ditulis ke Firestore. |
| 6 | **Tulis ke Firestore** (Code, Admin SDK) | `otp_verifications/{phone}`.set({otp_hash, otp_salt, created_at: now, expires_at: now + expiry, attempts: 0, verified: false, last_requested_at: now}) — overwrite dokumen lama kalau ada, request baru selalu menggantikan yang lama. |
| 7 | **Kirim via Fonnte** (HTTP Request) | `POST https://api.fonnte.com/send`, header `Authorization: {{$env.FONNTE_API_KEY}}`, body `{target: phone, message: "Kode OTP TemanStok Anda: {otp}. Jangan berikan kode ini kepada siapa pun. Berlaku {OTP_EXPIRY_MINUTES} menit.", countryCode: "62"}`. |
| 8 | **Cek respons Fonnte** (IF) | Kalau gagal kirim → respons error (502, `{success:false, message:"Gagal mengirim WhatsApp"}`). Dokumen `otp_verifications` dibiarkan apa adanya — request berikutnya akan menimpanya. |
| 9 | **Respond to Webhook (sukses)** | Status 200, `{success: true}`. |

---

## Workflow 2: `POST /webhook/otp/verify`

**Request:** `{ "phone": "62812xxxx", "otp": "123456" }`

| # | Node | Detail |
|---|---|---|
| 1 | **Webhook** (trigger) | Method `POST`, path `/webhook/otp/verify`, Response Mode = "Using 'Respond to Webhook' node". |
| 2 | **Validasi input** (Code) | `phone` ada, `otp` persis 6 digit numerik. Invalid → error (400). |
| 3 | **Ambil `otp_verifications/{phone}`** (Code, Admin SDK) | Kalau dokumen **tidak ada** → langsung respons `{success:true, valid:false}` (200) — perlakukan sama seperti "kode salah", JANGAN bedakan pesannya, supaya endpoint ini gak bisa dipakai buat enumerasi nomor mana yang pernah minta OTP. |
| 4 | **Cek expiry** (IF) | `now > expires_at` → respons `{success:true, valid:false}` (200). Opsional: hapus dokumen di sini sekalian buat beres-beres. |
| 5 | **Cek batas percobaan** (IF) | `attempts >= OTP_MAX_ATTEMPTS` → respons `{success:true, valid:false, message:"Terlalu banyak percobaan, minta kode baru"}` (200). Field `message` di kasus ini aman ditambahkan karena gak membocorkan status registrasi nomor, cuma status attempt. |
| 6 | **Bandingkan hash** (Code) | Hash ulang `otp` yang dikirim pakai `otp_salt` tersimpan, bandingkan ke `otp_hash` pakai `crypto.timingSafeEqual`. |
| 6a | **Kalau salah** | Increment `attempts` (pakai `FieldValue.increment(1)`, bukan read-then-write manual, supaya aman dari race condition kalau ada percobaan paralel) → respons `{success:true, valid:false}` (200). |
| 6b | **Kalau benar** | Lanjut ke langkah 7. |
| 7 | **Hapus dokumen `otp_verifications/{phone}`** (Code, Admin SDK) | Bukan sekadar set `verified:true` — dihapus total supaya OTP ini benar-benar single-use, gak bisa dipakai ulang lagi sebelum expiry walau secara teori tahu hash-nya. |
| 8 | **Mint custom token** (Code, Admin SDK) | `const token = await admin.auth().createCustomToken(phone);` — `phone` di sini (uid hasil token) harus persis sama dengan `storeId` yang dipakai sebagai document ID di `stores/{storeId}`, karena `firestore.rules` membandingkan `request.auth.uid == storeId`. |
| 9 | **Respond to Webhook (sukses)** | Status 200, `{success: true, valid: true, token: "<jwt dari langkah 8>"}`. Field `token` **hanya** boleh muncul di respons ini — tidak pernah di respons `valid:false` manapun. |

### Ringkasan kondisi respons `otp/verify`

| Kondisi | HTTP Status | Body |
|---|---|---|
| Input tidak valid | 400 | `{success:false, message:"..."}` |
| Dokumen gak ada / kode salah / kedaluwarsa | 200 | `{success:true, valid:false}` |
| Kebanyakan percobaan | 200 | `{success:true, valid:false, message:"Terlalu banyak percobaan..."}` |
| Kode benar | 200 | `{success:true, valid:true, token:"<jwt>"}` |
| Error server (Firestore/Admin SDK gagal) | 500 | `{success:false, message:"..."}` |

## Yang sengaja TIDAK ditangani n8n

Pengecekan "nomor ini sudah terdaftar sebagai store atau belum" **sudah**
ditangani di client (`register_otp_screen.dart` cek doc *tidak* ada sebelum
minta OTP, `phone_login_screen.dart` cek doc *ada* sebelum minta OTP) lewat
baca langsung ke `stores/{storeId}`. n8n tidak perlu duplikasi logic ini —
kedua workflow di atas cuma peduli soal "apakah nomor ini benar-benar
memegang WhatsApp itu", tidak peduli status registrasinya. Jangan tambahkan
pengecekan status-terdaftar di sisi n8n; itu bakal jadi sumber kebenaran
ganda dengan client.
