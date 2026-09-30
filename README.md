# TemanStok

**Voice AI dan Proactive Agents untuk Inventory Management Warung Kelontong dan UMKM Retail Indonesia**

TemanStok adalah aplikasi mobile Android untuk warung, toko kelontong, dan UMKM retail skala kecil. Aplikasi ini menggabungkan voice input, AI agents, dan notifikasi WhatsApp otomatis, sehingga owner bisa mencatat transaksi, memantau stok, dan mendapat rekomendasi bisnis hanya dengan berbicara.

---

## Table of Contents

1. [Problem Statement](#problem-statement)
2. [Key Features](#key-features)
3. [How It Works](#how-it-works)
4. [System Architecture](#system-architecture)
5. [Tech Stack](#tech-stack)
6. [Project Structure](#project-structure)
7. [Data Model](#data-model)
8. [Authentication](#authentication)
9. [Installation (End User)](#installation-end-user)
10. [Development Setup](#development-setup)
11. [Known Limitations](#known-limitations)

---

## Problem Statement

Mayoritas pemilik warung masih mencatat stok dan penjualan secara manual di buku tulis atau mengandalkan ingatan. Proses ini lambat, rawan human error, dan menyulitkan pengambilan keputusan, terutama untuk menentukan barang apa yang perlu di-restock (kulaan) dan kapan.

TemanStok dibangun dengan tiga prinsip:

- **Fast**: transaksi dicatat lewat ucapan natural dalam bahasa Indonesia, tanpa mengetik.
- **Familiar**: semua laporan dan reminder dikirim via WhatsApp, channel yang sudah dipakai sehari-hari oleh pelaku UMKM.
- **Proactive**: sistem tidak menunggu user membuka aplikasi. AI agents berjalan terjadwal dan mengirim informasi yang relevan secara otomatis.

---

## Key Features

### 1. Multi-Item Voice Transaction

User bisa mencatat hingga 3 produk sekaligus dalam satu ucapan natural.

```
"Pocari terjual 1, Kopi ABC terjual 1, Milo keluar 2"
```

Contoh utterance lain yang tersedia di UI:

```
"Kopi hitam terjual 3"
"Masuk Indomie 24 bungkus"
"Rokok Surya keluar 5"
```

Speech recognition memakai locale `id_ID` jika tersedia di device. Transcript kemudian dikirim ke backend untuk di-parse menjadi transaksi terstruktur.

### 2. New Item Detection

Jika barang yang disebutkan belum ada di inventory, aplikasi menampilkan dialog "Barang Baru Terdeteksi" dan meminta user mengisi stok awal. Transaksi kemudian diproses ulang menggunakan stok awal tersebut.

### 3. Empat Proactive AI Agents

Empat scheduled agents berjalan di backend dan mengirim hasilnya langsung ke WhatsApp owner, tanpa perlu membuka aplikasi.

| Agent | Fungsi |
| --- | --- |
| Daily Recap | Ringkasan penjualan harian, produk terlaris, dan daftar stok kritis |
| Weekly Insight | Analisis top products 7 hari terakhir dan jumlah item berstatus kritis |
| Restock Plan | Rekomendasi barang dan jumlah yang perlu di-restock |
| Expiry Reminder | Alert untuk barang yang mendekati tanggal kedaluwarsa |

### 4. Dashboard dan Inventory Management

- **Beranda**: ringkasan total jenis barang, stok kritis, jumlah transaksi, dan AI suggestion, ditambah daftar transaksi terakhir.
- **Stok**: list seluruh barang dengan filter berdasarkan status, plus fitur add item dan update stok manual.
- **AI**: checklist rencana kulaan mingguan, weekly insight, rekap hari ini, grafik tren penjualan 30 hari, dan riwayat rekap harian.
- **Profil**: info warung dan account management.

### 5. Automatic Stock Status

Setiap item diklasifikasikan otomatis berdasarkan `min_stock`.

| Status | Kondisi |
| --- | --- |
| Kritis | `stock <= min_stock` |
| Rendah | `stock <= 2 * min_stock` |
| Aman | `stock > 2 * min_stock` |

List selalu di-sort dari status paling urgent (kritis, rendah, aman).

### 6. Real-Time Sync

Data inventory dan transaksi di-consume lewat Cloud Firestore snapshot stream, sehingga perubahan dari backend maupun dari aplikasi langsung ter-reflect di UI tanpa manual reload.

### 7. WhatsApp Notification

Semua laporan agent dan kode verifikasi dikirim via WhatsApp, sehingga user tidak perlu belajar channel komunikasi baru.

---

## How It Works

1. Owner registrasi dengan nomor WhatsApp aktif dan verifikasi via OTP.
2. Owner setup profil warung dan mendaftarkan minimal 5 barang awal beserta stoknya.
3. Setiap transaksi diucapkan lewat tombol mic di tengah bottom navigation.
4. Aplikasi mengirim `POST` berisi transcript dan `store_id` ke webhook n8n.
5. Backend mem-parse utterance, meng-update stok dan riwayat transaksi di Firestore, lalu mengembalikan response ke aplikasi.
6. Scheduled agents membaca data yang sama dan mengirim rekap serta rekomendasi ke WhatsApp owner.

---

## System Architecture

```
+---------------------------+
|   Android App             |
|   (Flutter + Riverpod)    |
+-----+---------------+-----+
      |               |
      | Firestore     | HTTPS webhook
      | Auth          | (voice transcript)
      v               v
+-------------+   +------------------------------+
|  Firebase   |<--|  n8n Backend                 |
|  Auth &     |   |  Hostinger VPS (Jakarta)     |
|  Firestore  |-->|  Running 24/7                |
+-------------+   +---------------+--------------+
                                  |
                  Scheduled agents| WhatsApp gateway
                                  v
                       +----------------------+
                       |  Owner's WhatsApp    |
                       +----------------------+
```

Komponen utama:

- **Client app**: UI, on-device speech recognition, authentication, dan real-time data reads.
- **Firebase**: Firebase Authentication untuk user account, Cloud Firestore sebagai primary datastore.
- **n8n backend**: menerima voice transcript, mem-parse transaksi, dan menjalankan seluruh scheduled agents. Di-host di VPS Hostinger region Jakarta, jadi agents berjalan 24/7 tanpa bergantung pada mesin developer.
- **WhatsApp gateway**: layanan pengiriman pesan untuk OTP dan notifikasi.

---

## Tech Stack

| Kategori | Teknologi |
| --- | --- |
| Framework | Flutter (Dart SDK ^3.11.1) |
| State management | Riverpod (`flutter_riverpod`) |
| Authentication | Firebase Authentication |
| Database | Cloud Firestore |
| Speech recognition | `speech_to_text` |
| Networking | `dio`, `http` |
| Local storage | `shared_preferences` |
| Data visualization | `fl_chart` |
| Typography dan assets | `google_fonts` (Inter), `flutter_svg` |
| Backend automation | n8n |
| Infrastructure | Hostinger VPS, Jakarta |
| WhatsApp delivery | Fonnte |

---

## Project Structure

```
lib/
  main.dart                     Entry point, Firebase init, session check
  firebase_options.dart         Firebase configuration
  config/
    api_config.dart             Webhook endpoint dan request headers
    app_theme.dart              Color palette, typography, design tokens
  providers/
    ai_provider.dart            Inventory dan transaction streams, insight computation
    onboarding_provider.dart    State dan logic untuk store registration dan initial items
    session_provider.dart       Session management (store_id)
    voice_provider.dart         Speech recognition dan pengiriman transcript ke backend
  screens/
    main_screen.dart            Main navigation shell
    home_screen.dart            Dashboard
    stok_screen.dart            Inventory management
    ai_screen.dart              Insights dan restock plan
    profil_screen.dart          Store profile dan account
    mic_screen.dart             Voice recording screen
  widgets/                      Reusable UI components
  src/
    config/                     Local secrets
    services/auth_service.dart  Registration, login, dan pengiriman OTP
    screens/                    Flow landing, login, OTP registration, profile, initial items
assets/images/                  Logo dan icons
android/                        Android project
```

---

## Data Model

Data disimpan di Cloud Firestore. `store_id` berupa nomor WhatsApp yang sudah dinormalisasi ke format `62xxxxxxxxxx`.

```
users/{uid}
  name, phone, createdAt, isVerified

stores/{store_id}
  store_id, nama_warung, owner_phone

stores/{store_id}/inventory/{item_name}
  stock, min_stock, max_stock, last_updated

stores/{store_id}/transactions/{id}
  item, qty, type, timestamp
```

Aturan saat initial item setup:

- Minimal 5 dan maksimal 10 item.
- `min_stock` dihitung 20 persen dari stok awal (dibulatkan, minimum 1).
- `max_stock` di-set 2x stok awal.

---

## Authentication

Registrasi memakai nomor WhatsApp yang diverifikasi dengan OTP 6 digit.

- Kode OTP dikirim via WhatsApp ke nomor yang didaftarkan.
- Resend dibatasi cooldown 59 detik.
- Nomor yang sudah terdaftar dicek dulu di Firestore, sehingga OTP tidak dikirim untuk akun yang sudah ada.
- Akun dibuat di Firebase Authentication, sedangkan profil user disimpan di Firestore dengan flag `isVerified`.
- Session disimpan secara lokal, jadi user langsung masuk ke dashboard saat membuka aplikasi berikutnya.
- API key layanan WhatsApp dipisah dari source utama di file konfigurasi lokal `lib/src/config/secrets.dart`.

---

## Installation (End User)

### Requirements

- Device Android.
- Nomor WhatsApp aktif.
- Koneksi internet.

### Steps

1. Download file **TemanStok.apk**.
2. Di device Android, buka **Pengaturan**, pilih **Keamanan**, lalu aktifkan **Izinkan instalasi dari sumber tidak dikenal**.
3. Buka file APK yang sudah di-download dan tap **Install**. Jika file dibuka dari Google Drive, pilih **Install without scanning** atau **Install with scanning**.
4. Setelah instalasi selesai, tap **Buka** atau cari ikon TemanStok di home screen.
5. Berikan izin **mikrofon** saat diminta. Izin ini dibutuhkan untuk fitur voice input.
6. Daftar dengan nomor WhatsApp aktif, lalu ikuti proses onboarding.

> **Catatan:** Setelah berhasil masuk lewat **Daftar Baru**, lakukan pull to refresh (scroll ke bawah) di halaman Beranda agar data inventory tampil dengan benar.

---

## Development Setup

### Prerequisites

- Flutter SDK dengan Dart 3.11.1 atau lebih baru.
- Android Studio atau Android SDK yang sudah terkonfigurasi.
- Firebase project dengan Authentication (Email/Password) dan Cloud Firestore aktif.
- Akun layanan WhatsApp gateway (Fonnte) beserta API key.
- Instance n8n yang meng-expose webhook endpoint untuk transaksi.

### Run Locally

1. Clone repository dan install dependencies.

   ```bash
   git clone https://github.com/aqibadhaa/temanstok.git
   cd TemanStok
   flutter pub get
   ```

2. Hubungkan dengan Firebase project milik lu sendiri. Update `lib/firebase_options.dart` (misalnya lewat FlutterFire CLI) dan `android/app/google-services.json`.

3. Buat file `lib/src/config/secrets.dart` dan pastikan file ini tidak ikut ter-commit.

   ```dart
   class AppSecrets {
     static const String waApiKey = 'YOUR_API_KEY';
   }
   ```

4. Sesuaikan webhook URL di `lib/config/api_config.dart`. Endpoint transaksi menerima `POST` dengan JSON payload berikut.

   ```json
   {
     "store_id": "62812xxxxxxx",
     "transcript": "Kopi hitam terjual 3"
   }
   ```

   Untuk registrasi barang baru, payload ditambah field `initial_stock`.

5. Jalankan aplikasi di device atau emulator Android.

   ```bash
   flutter run
   ```

6. Build release APK.

   ```bash
   flutter build apk --release
   ```

---

**TemanStok**: teman setia pemilik warung untuk mengelola stok lebih cepat, akurat, dan cerdas.
