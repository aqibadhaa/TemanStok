# TemanStok

Sistem manajemen stok warung kelontong berbasis voice input dan agen cerdas
proaktif, dibuat untuk **GEMASTIK XIX** (kategori Pengembangan Perangkat
Lunak). Target pengguna: pemilik warung kelontong / UMKM retail kecil,
single-store, di area yang sudah diriset lewat wawancara (lihat dokumen
proposal untuk detail metodologi dan batasan riset).

Fitur inti: pencatatan stok lewat voice input berbahasa Indonesia, notifikasi
WhatsApp untuk stok kritis, rekomendasi restock, insight mingguan & rekap
harian.

## Stack

- **Flutter** — client mobile, state management pakai **Riverpod**
- **Firebase** — Authentication (custom token) & Cloud Firestore (database)
- **n8n** — orkestrasi backend: webhook OTP, webhook transaksi voice
- **Groq API** — NLP untuk parsing perintah suara (dijalankan di sisi n8n,
  bukan di client)
- **Fonnte** — WhatsApp gateway untuk OTP dan notifikasi

## Setup dari nol

1. Install Flutter SDK (channel stable; lihat `environment: sdk` di
   `pubspec.yaml` untuk versi Dart minimum yang dibutuhkan).
2. Clone repo, lalu jalankan:
   ```
   flutter pub get
   ```
3. **Firebase**: project ini butuh `android/app/google-services.json` yang
   terdaftar untuk package `com.example.temanstok` (lihat bagian "Status
   saat ini" soal rename package — file ini **tidak** disertakan di repo
   karena berisi konfigurasi spesifik project Firebase, minta ke pemegang
   akses Firebase Console). `lib/firebase_options.dart` sudah ter-generate
   dan ikut ter-commit; kalau project Firebase berubah, generate ulang
   lewat `flutterfire configure`.
4. Jalankan di device/emulator:
   ```
   flutter run
   ```
5. **Login/registrasi belum akan berfungsi end-to-end** sampai Track A
   (lihat di bawah) live — `ApiConfig.baseUrl` di
   `lib/config/api_config.dart` masih menunjuk ke tunnel ngrok sementara
   yang sudah tidak aktif.

## Struktur folder utama

```
lib/
  main.dart                  Entry point, routing table, pemasangan SessionGate
  config/
    app_theme.dart           Warna, tipografi, tema Material
    api_config.dart          Base URL + endpoint n8n (transaksi, OTP request/verify)
  src/config/
    secrets.dart             LEGACY — lihat catatan di bawah, sudah tidak dipakai
  providers/                 Riverpod providers
    session_provider.dart    State sesi (store_id) + sign-out Firebase Auth
    onboarding_provider.dart State alur registrasi/onboarding warung baru
    ai_provider.dart         Data Firestore: inventory, transaksi, AI insight
    voice_provider.dart      State voice input + panggilan webhook transaksi
  src/services/
    auth_service.dart        requestOtp/verifyOtp ke n8n + signInWithCustomToken
  screens/                   Layar dashboard aktif (dalam MainScreen, ter-gate sesi)
    main_screen.dart          Container 4 tab: Beranda, Stok, AI, Profil
    home_screen.dart, stok_screen.dart, ai_screen.dart, profil_screen.dart
    mic_screen.dart            Layar voice input (FAB mic)
  src/screens/                Layar alur auth & onboarding (TIDAK ter-gate sesi)
    landing_screen.dart, phone_login_screen.dart, register_otp_screen.dart,
    setup_profil_screen.dart, input_barang_screen.dart
  widgets/
    session_gate.dart        Guard rute yang butuh sesi aktif
    async_error_view.dart    Widget error standar untuk branch error: AsyncValue
    summary_card.dart, stok_item_card.dart, transaksi_item.dart, ai_insight_card.dart
  utils/
    phone_utils.dart         Normalisasi nomor telepon (satu sumber, dipakai semua layar)
    app_exceptions.dart      SessionExpiredException
test/
  widget_test.dart
firestore.rules              Aturan Firestore — SUDAH ditulis, BELUM di-deploy (lihat Status)
```

**Catatan struktur:** pemisahan `lib/screens/` vs `lib/src/screens/`, dan
`lib/config/` vs `lib/src/config/`, adalah peninggalan riwayat development
(bukan keputusan arsitektur yang disengaja). `lib/screens/` = layar dashboard
yang ter-gate sesi, `lib/src/screens/` = layar sebelum sesi ada (landing,
login, registrasi, onboarding). Kalau ke depan ada waktu refactor, kedua
folder ini layak digabung jadi satu struktur yang konsisten.

## Status saat ini

**Track B (client Flutter) — sudah menutup di sisi app:**
- **C-1** (login tanpa verifikasi apa pun): ditutup — `phone_login_screen.dart`
  sekarang wajib lewat request + verifikasi OTP sebelum sesi dibuat, bukan
  cuma cek dokumen `stores/{id}` exist.
- **C-2** (OTP divalidasi di client): ditutup — `verifyOtp()` di
  `auth_service.dart` selalu manggil server (`otp/verify`), client tidak
  pernah menyimpan atau membandingkan kode OTP asli.
- **C-4** (sesi cuma nomor telepon tanpa proof of ownership): ditutup di sisi
  client — `verifyOtp()` yang sukses juga langsung `signInWithCustomToken`
  dari token yang dikirim server. **Tapi ini baru benar-benar berfungsi
  setelah Track A mint token beneran** (lihat di bawah).
- **C-3** (API key Fonnte plaintext di client): `secrets.dart` sudah tidak
  diimport dari mana pun di client — lihat bagian khusus di bawah.

**Track A (infra n8n) — belum berjalan:**
- n8n belum di-host permanen (rencana Railway/Render, masih nunggu akses
  tim + API key).
- Endpoint `POST /webhook/otp/request` dan `POST /webhook/otp/verify` belum
  ada. Spesifikasi lengkap node-demi-node (termasuk skema
  `otp_verifications` di Firestore dan langkah mint custom token) ada di
  `docs/n8n-otp-workflow.md`.
- `firestore.rules` sudah ditulis lengkap tapi **belum di-deploy**. Jangan
  deploy sebelum Track A live dan teruji — begitu aktif, semua akses ke
  `stores/*` yang tidak bawa token valid langsung ditolak, dan sampai
  n8n bisa mint token, tidak ada satu pun client yang punya token itu.
- **C-5** (belum ada Firestore Security Rules) karena itu masih terbuka
  sampai deploy di atas dilakukan.

## Environment variable / config yang dibutuhkan setelah Track A jalan

Di sisi n8n (Railway/Render), bukan di client:
- `FONNTE_API_KEY` — API key WhatsApp gateway. **Sebelumnya tersimpan di
  `lib/src/config/secrets.dart` dan ter-commit ke repo (plaintext) — kalau
  key itu masih aktif, rotate dulu lewat dashboard Fonnte sebelum dipakai
  di sini.** `secrets.dart` sendiri sudah tidak diimport oleh kode client
  mana pun; boleh dihapus dari repo setelah key lama dipastikan sudah
  di-rotate.
- Kredensial service account Firebase (buat `firebase-admin`, dipakai untuk
  `createCustomToken`) — simpan sebagai env var (idealnya JSON-nya
  di-base64 dulu), jangan di-commit sebagai file.

Di sisi client, setelah n8n live:
- `lib/config/api_config.dart` → `baseUrl` diganti dari domain ngrok
  sementara ke domain permanen n8n. Ini satu-satunya perubahan client yang
  dibutuhkan; `webhookUrl`, `otpRequestUrl`, `otpVerifyUrl` semua diturunkan
  dari `baseUrl` itu.
- `android/app/google-services.json` perlu diperbarui menyusul rename
  package ke `com.example.temanstok` (lihat commit rename package untuk
  detail: file ini harus diregenerasi dari Firebase Console setelah
  package Android baru didaftarkan di sana, bukan diedit manual).

## Dead code yang sudah dihapus

Supaya kontributor baru tidak buang waktu mencari atau mengira ada
implementasi tersembunyi:

- `lib/src/screens/home_screen.dart`, `login_screen.dart`,
  `register_screen.dart` — sisa alur auth berbasis password/email dari
  iterasi awal, sebelum tim pindah ke OTP WhatsApp. **Catatan penting:**
  `lib/screens/home_screen.dart` (tanpa `src/`) adalah file **aktif** yang
  berbeda, kebetulan nama sama — jangan tertukar kalau mencari lewat nama
  file saja.
- `lib/screens/voice_input_screen.dart` — digantikan `mic_screen.dart`.
- Method-method berikut dihapus dari `AuthService` karena hanya dipakai
  file-file di atas: `isPhoneRegistered()`, `completeRegistration()`,
  `loginWithPassword()`, `signOut()`, `checkLoginStatus()`,
  `sendWhatsAppOtp()` (diganti `requestOtp()` + `verifyOtp()`).

Kalau ada method atau file lain yang kelihatan tidak terpakai tapi belum
disebut di sini, cek dulu dengan grep referensi impor sebelum menghapus —
beberapa nama class bisa mirip antar file berbeda (lihat catatan
`home_screen.dart` di atas) sehingga pencarian berbasis nama saja bisa
menyesatkan.
