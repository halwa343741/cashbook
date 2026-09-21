# Spesifikasi Teknis Aplikasi Cashbook (Flutter Mobile)

Dokumen spesifikasi teknis dan panduan implementasi aplikasi mobile **Cashbook** berbasis **Flutter** berdasarkan desain Figma [CashbookByGemini](https://www.figma.com/design/N9vywpatfKo4fDlDjrGzJW/CashbookByGemini?node-id=0-1).

---

## 1. Ringkasan Proyek

| Parameter | Spesifikasi |
|---|---|
| **Nama Aplikasi** | **Cashbook** (Aplikasi Catatan Keuangan & Kasir Digital Pribadi) |
| **Sistem Pengelompokan** | **Multi-Folder / Multi-Buku Kas (Parent-Child)**: Transaksi in/out dikelompokkan per Buku/Folder (misal: *Kas Pribadi*, *Kas Usaha*, *Kas Tabungan*) |
| **Sistem Buku Kas** | **Multi-Buku Kas Selalu Aktif**: Seluruh buku kas selalu aktif untuk pencatatan transaksi tanpa sistem tutup/kunci atau share artifisial |
| **Pusat Pemilihan Buku Kas** | **Hanya di Beranda (Home)**: Pemilihan buku kas aktif dipusatkan di layar Beranda. Saat mencatat transaksi (Pemasukan/Pengeluaran), riwayat transaksi, dan laporan, aplikasi langsung menggunakan buku aktif tanpa perlu memilih buku lagi |
| **Multi-Bahasa (Localization)** | **Bahasa Indonesia (`id`), English (`en`), Español (`es`)**: Format angka ribuan, mata uang, dan tanggal/jam dinamis mengikuti locale bahasa yang dipilih |
| **Keamanan Data** | **Kunci Aplikasi dengan PIN & Biometrik** (Fingerprint / Face ID via `local_auth`) |
| **Sistem Penghapusan** | **Soft-Delete & Tong Sampah (Trash)**: Mencegah kehilangan data buku kas & transaksi dengan fitur Restore |
| **Ekspor Laporan** | **Ekspor PDF & Excel (.xlsx / .csv)** untuk cetak dan rekap data |
| **Rentang Laporan** | Bulan ini, Tahun ini, dan **Custom Date Range Picker** (Bebas pilih tanggal mulai - selesai) |
| **Framework** | Flutter 3.x (Dart 3.x) |
| **Platform Target** | Android (API 24+) & iOS (iOS 13+) |
| **Tampilan Desain Acuan** | Mobile Portrait 390 x 844 dp |
| **Metode Autentikasi** | **Biometrik (Fingerprint / Face ID) + PIN** via `local_auth` (100% Offline, tanpa akun Google) |
| **Database & Cloud Sync** | **100% Offline-First dengan Sinkronisasi Google Drive** (file `data.cashbook`) |
| **Dukungan Tema** | **Mode Terang (Light) & Mode Gelap (Dark)** + Ikuti Sistem |
| **Prinsip Arsitektur** | Clean Architecture (Feature-First) |
| **Manajemen Status (State)** | `flutter_bloc` (atau `flutter_riverpod`) |
| **Font Utama** | *Plus Jakarta Sans* / *Inter* (via `google_fonts`) |

---

## 2. Design System & Tema (Light & Dark Mode)

Aplikasi mendukung perpindahan tema **Light**, **Dark**, dan **System Default**.

### 2.1. Color Palette Tokens

```dart
import 'package:flutter/material.dart';

class AppColors {
  // Brand Color (Konsisten di kedua tema)
  static const Color primary = Color(0xFF15803D);      // Hijau Emerald Utama
  static const Color primaryDark = Color(0xFF0F5B2C);  // Hijau Gelap (Splash)
  static const Color primaryLight = Color(0xFFDCFCE7); // Hijau Aksen Muda

  // Status Transaksi
  static const Color income = Color(0xFF16A34A);       // Hijau Pemasukan
  static const Color expense = Color(0xFFEF4444);      // Merah Pengeluaran
  static const Color transfer = Color(0xFF3B82F6);     // Biru Transfer

  // --- Palet Light Mode ---
  static const Color lightBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color lightSurface = Color(0xFFFFFFFF);    // Putih
  static const Color lightCardBorder = Color(0xFFF1F5F9); // Slate 100
  static const Color lightInputBorder = Color(0xFFE2E8F0);// Slate 200
  static const Color lightTextPrimary = Color(0xFF0F172A);// Slate 900
  static const Color lightTextSecondary = Color(0xFF475569); // Slate 600
  static const Color lightTextMuted = Color(0xFF94A3B8);  // Slate 400

  // --- Palet Dark Mode ---
  static const Color darkBackground = Color(0xFF0B1120);  // Deep Dark Slate
  static const Color darkSurface = Color(0xFF1E293B);     // Slate 800
  static const Color darkCardBorder = Color(0xFF334155);  // Slate 700
  static const Color darkInputBorder = Color(0xFF475569); // Slate 600
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color darkTextSecondary = Color(0xFFCBD5E1); // Slate 300
  static const Color darkTextMuted = Color(0xFF64748B);   // Slate 500
}
```

### 2.2. Theme Management

```dart
enum AppThemeMode { light, dark, system }

// ThemeData Builder untuk Light & Dark
class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackground,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
    ),
    fontFamily: 'PlusJakartaSans',
    useMaterial3: true,
  );

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
    ),
    fontFamily: 'PlusJakartaSans',
    useMaterial3: true,
  );
}
```

---

## 3. Arsitektur Database: 100% Offline-First & Google Drive Sync (`data.cashbook`)

Aplikasi dirancang agar **dapat beroperasi penuh 100% secara offline** tanpa memerlukan koneksi internet. Pengguna dapat membuka aplikasi, mencatat pemasukan/pengeluaran, melihat grafik, dan mengelola kategori secara instan. Ketika pengguna ingin menyinkronkan data atau saat koneksi internet tersedia, data dapat disinkronkan dengan Google Drive.

```text
┌────────────────────────────────────────────────────────┐
│               Aplikasi Cashbook Flutter                │
└──────────────────────────────────┬─────────────────────┘
                                   │
                                   ▼ (100% Instan & Bekerja Tanpa Internet)
┌────────────────────────────────────────────────────────┐
│       Database Lokal HP (File lokal data.cashbook)     │
│   - Catat Pemasukan / Pengeluaran                      │
│   - Riwayat, Filter, & Grafik Laporan                  │
│   - Status sinkronisasi: `isSynced: false`             │
└──────────────────────────────────┬─────────────────────┘
                                   │
                                   ▼ (Sync Dua Arah saat Online / Tap "Sync")
┌────────────────────────────────────────────────────────┐
│              Google Drive Pengguna                     │
│         (File Terisolasi: `data.cashbook`)             │
│   - Backup Cloud Aman di Drive Pribadi                 │
│   - Pulihkan data saat ganti perangkat baru            │
└────────────────────────────────────────────────────────┘
```

### 3.1. Spesifikasi File `data.cashbook`
* **Nama File**: `data.cashbook`
* **Format Isi**: SQLite Database File atau Encrypted/Structured JSON File yang menyimpan tabel:
  * `metadata`: Versi schema, timestamp `lastSyncedAt`, info perangkat.
  * `categories`: Kategori default & kustom.
  * `transactions`: Seluruh riwayat transaksi dengan metadata `updatedAt` dan `isDeleted` (soft delete).
* **Lokasi di Google Drive**:
  * Menggunakan **Google Drive AppData Folder** (`https://www.googleapis.com/auth/drive.appdata`) atau **Drive Files Scope** (`https://www.googleapis.com/auth/drive.file`).
  * File tersimpan aman dan terisolasi di cloud akun Google pengguna.

### 3.2. Fitur Offline Penuh (100% Offline Capability)
1. **Tidak Ada Blokir Jaringan**: Aplikasi tidak pernah menampilkan layar loading atau error jaringan saat mencatat transaksi baru.
2. **Penyimpanan Lokal Permanen**: Semua mutasi data ditulis langsung ke media penyimpanan internal perangkat (`getApplicationDocumentsDirectory()`).
3. **Pending Sync Flag**: Setiap record baru/edit yang dibuat secara offline otomatis ditandai `isSynced = false`.

### 3.3. Alur Kerja Sinkronisasi (Bidirectional Sync Flow)

Pengguna dapat menyinkronkan data melalui 2 cara:
* **Manual Sync**: Menekan tombol **"Sinkronkan Sekarang"** di halaman Pengaturan Akun (Screen 10).
* **Auto Sync (Latar Belakang)**: Sinkronisasi otomatis berjalan saat aplikasi mendeteksi koneksi internet setelah sebelumnya berada dalam mode offline.

#### Mekanisme Sinkronisasi:
1. **Langkah 1 (Cek File di Google Drive)**:
   * Query ke Google Drive: `name = 'data.cashbook' and trashed = false`.
   * Jika file **belum ada di Drive**: Aplikasi mengunggah file `data.cashbook` lokal saat ini ke Google Drive sebagai file master perdana.
2. **Langkah 2 (Penggabungan / Merge Data Tanpa Kehilangan Transaksi)**:
   * Jika file **sudah ada di Drive**: Aplikasi mengunduh versi Google Drive ke memori sementara.
   * **Smart Merge (Resolusi Konflik berbasis Timestamp)**:
     * Transaksi lokal yang dibuat saat offline (`isSynced = false`) digabungkan dengan transaksi di Google Drive berdasarkan `id` dan `updatedAt` terbaru.
     * Tidak ada transaksi yang tertimpa secara buta; data dari Google Drive dan data lokal digabungkan (*union with latest timestamp*).
3. **Langkah 3 (Commit & Update)**:
   * File `data.cashbook` hasil penggabungan disimpan kembali ke storage lokal HP.
   * File master di Google Drive diperbarui dengan snapshot terbaru (`drive.files.update`).
   * Semua status lokal diubah menjadi `isSynced = true`.
   * Notifikasi/Badge di UI diperbarui menjadi *"Tersinkronisasi"*.

### 3.4. Indikator Status Sinkronisasi di UI
* 🟢 **Tersinkronisasi**: Semua data lokal cocok dengan Google Drive.
* 🟡 **Offline (Belum Sync)**: Terdapat data transaksi offline yang belum diunggah ke Google Drive (contoh teks: *"3 transaksi belum disinkron"*).
* 🔄 **Sedang Sinkronisasi**: Indikator loading halus saat proses upload/download berlangsung.

### 3.5. Alur Pemilihan Buku Kas & Pencatatan Transaksi Terpusat

1. **Pemilihan Buku Kas HANYA di Beranda (Home Screen)**:
   * Dropdown switcher buku kas ditempatkan secara terpusat dan eksklusif di layar Beranda.
   * Pengguna mengganti dan memilih buku kas aktif langsung di Beranda, dan preferensi ini otomatis tersimpan secara permanen (`activeBookId`).
2. **Pencatatan Transaksi Langsung Tanpa Pilih Buku**:
   * Saat pengguna menekan tombol **Tambah Pemasukan** (`/add-income`) atau **Tambah Pengeluaran** (`/add-expense`), form input transaksi otomatis langsung terhubung ke buku kas yang sedang aktif.
   * **Tidak ada form/dropdown pemilihan buku kas** saat mencatat transaksi, sehingga pengalaman mencatat pengeluaran dan pemasukan menjadi sangat cepat, simpel, dan bebas hambatan.
3. **Layar Riwayat & Laporan**:
   * Layar Riwayat Transaksi dan Laporan Keuangan menampilkan mutasi dari buku kas yang sedang aktif terpilih di Beranda.
4. **Buku Kas Selalu Aktif**:
   * Tidak ada sistem penutupan buku (close/reopen) maupun mode read-only. Seluruh buku kas yang dibuat selalu aktif dan dapat dicatat serta diedit sewaktu-waktu oleh pengguna.

### 3.7. Sistem Multi-Bahasa & Format Dinamis (Localization)
1. **Pilihan Bahasa Tersedia**:
   * 🇮🇩 **Bahasa Indonesia (`id`)**: Bahasa default aplikasi.
   * 🇺🇸 **English (`en`)**: Bahasa internasional.
   * 🇪🇸 **Español (`es`)**: Bahasa Spanyol.
   * 🇨🇳 **简体中文 (`zh`)**: Bahasa Mandarin (Chinese Simplified).
   * 🇸🇦 **العربية (`ar`)**: Bahasa Arab dengan dukungan native Directionality RTL (Right-to-Left).
2. **Format Angka & Mata Uang Dinamis**:
   * Menyesuaikan secara otomatis berdasarkan bahasa/locale yang dipilih pengguna:
     * `id`: Format Rupiah `Rp 1.500.000` (titik sebagai pemisah ribuan).
     * `en`: Format Dollar `$ 1,500,000` (koma sebagai pemisah ribuan).
     * `es`: Format Euro `1.500.000 €`.
     * `zh`: Format Yuan `¥ 1,500,000`.
     * `ar`: Format Riyal `ر.س 1,500,000` / `1,500,000 ر.س`.
3. **Format Tanggal & Waktu Dinamis**:
   * Menyesuaikan standar lokal masing-masing negara:
     * `id`: `20 Sep 2026, 14:30` (format 24 jam).
     * `en`: `Sep 20, 2026, 02:30 PM` (format 12 jam dengan AM/PM).
     * `es`: `20 sep 2026, 14:30`.
     * `zh`: `2026年9月20日 14:30`.
     * `ar`: `20 سبتمبر 2026، 02:30 م` (format AM/PM dalam teks Arab).
4. **Penyimpanan Preferensi Bahasa**:
   * Bahasa pilihan disimpan di `SharedPreferences` (`app_language_code`) dan dapat diubah secara instan di menu Pengaturan Akun tanpa perlu me-restart aplikasi.
   * Perubahan bahasa langsung merefleksikan seluruh teks UI (Beranda, Riwayat, Laporan, Tong Sampah, Manajemen Buku, Kelola Kategori, Pengaturan Akun).

---

## 4. Struktur Direktori Proyek (Clean Feature-First)

```text
lib/
├── app/
│   ├── app.dart
│   ├── routes/
│   │   └── app_router.dart          // go_router
│   └── theme/
│       ├── app_theme.dart
│       └── theme_cubit.dart         // State Light/Dark/System
├── core/
│   ├── constants/
│   │   ├── colors.dart
│   │   └── strings.dart
│   ├── services/
│   │   ├── biometric_service.dart   // local_auth PIN & Biometric (autentikasi utama)
│   │   ├── drive_backup_service.dart// Backup/Restore data.cashbook via Android file picker
│   │   ├── google_drive_service.dart// Opsional: CRUD data.cashbook di Drive (tanpa OAuth)
│   │   ├── pdf_export_service.dart  // Export rekap PDF
│   │   └── excel_export_service.dart// Export rekap Excel (.xlsx / .csv)
│   ├── database/
│   │   ├── local_storage.dart       // Local file manager data.cashbook
│   │   └── db_helper.dart
│   └── utils/
│       ├── currency_formatter.dart  // Rupiah format
│       └── date_formatter.dart      // dd MMM yyyy format
└── features/
    ├── auth/                        // Screen 1 & 2 (Offline-First, tanpa Google Auth)
    │   ├── presentation/
    │   │   ├── splash_screen.dart
    │   │   └── login_screen.dart    // Welcome screen (first-time setup, tanpa Google button)
    │   └── cubit/
    │       └── auth_cubit.dart
    ├── security/                    // Screen 1.5: PIN / Biometric Lock
    │   └── presentation/
    │       └── lock_screen.dart
    ├── dashboard/                   // Screen 3
    │   └── presentation/
    │       ├── home_screen.dart
    │       └── widgets/
    ├── transaction/                 // Screen 4, 5, 6, 7
    │   ├── domain/models/transaction_model.dart
    │   └── presentation/
    │       ├── add_income_screen.dart
    │       ├── add_expense_screen.dart
    │       ├── transaction_list_screen.dart
    │       └── transaction_detail_screen.dart
    ├── report/                      // Screen 8 (Chart, Date Range, Export)
    │   └── presentation/
    │       ├── report_screen.dart
    │       └── widgets/
    │           ├── financial_bar_chart.dart
    │           └── custom_date_range_modal.dart
    ├── category/                    // Screen 9
    │   └── presentation/
    │       └── category_list_screen.dart
    ├── trash/                       // Screen 10b: Tong Sampah (Restore Books & Transaksi)
    │   └── presentation/
    │       └── trash_screen.dart
    └── account/                     // Screen 10
        └── presentation/
            ├── account_screen.dart
            └── widgets/
                ├── theme_selector_dialog.dart
                └── security_settings_tile.dart
```

---

## 5. Spesifikasi & Interaksi 10 Layar

### Screen 1: Splash Screen (`01-splash-screen`)
* **Route**: `/splash` (alias `/`)
* **Elemen UI**:
  * Background Gradient Hijau (`#15803D` ke `#0F5B2C`).
  * Logo Dompet Putih + Typography "Cashbook" + Subtitle.
  * Loading Indicator Bar.
* **Logika** (100% Offline-First, tanpa cek Google Sign-In):
  1. **Cek Kunci Aplikasi (PIN / Biometrik)**:
     * Jika **PIN atau Biometrik aktif** → Redirect ke **Screen 1b (`/lock`)** untuk verifikasi identitas.
     * Jika **tidak ada kunci aktif** → Lanjut ke langkah 2.
  2. **Cek Data Buku Kas Lokal**:
     * Jika `books.isNotEmpty` → Redirect ke `/home` (Dashboard).
     * Jika `books.isEmpty` (first-time) → Redirect ke `/login` (Welcome Screen).

---

### Screen 1b: Kunci Aplikasi - PIN & Biometrik (`/lock-screen`)
* **Route**: `/lock-screen`
* **Kapan Ditampilkan**: Setiap kali aplikasi dibuka atau kembali dari background jika fitur keamanan diaktifkan di Screen 10.
* **Elemen UI**:
  * Logo Cashbook kecil di atas.
  * Judul: *"Masukkan PIN Cashbook"* / *"Pindai Sidik Jari"*.
  * Indikator 4/6 Dot PIN.
  * Numeric Keypad (1–9, 0, Backspace).
  * Tombol Ikon Biometrik di pojok bawah keypad (untuk memicu Fingerprint / Face ID via `local_auth`).
* **Logika**:
  * Validasi PIN lokal (disimpan terenkripsi di `flutter_secure_storage`).
  * Prompt biometrik otomatis muncul saat layar pertama kali tampil.
  * Jika verifikasi sukses ➔ Lanjut ke `/home` (atau `/create-initial-book`).
  * Proteksi salah PIN: cooldown 30 detik jika salah 5 kali berturut-turut.

---

### Screen 2: Welcome Screen / First-Time Setup (`02-login-welcome`)
* **Route**: `/login`
* **Kapan Ditampilkan**: **Hanya pada first-time setup** (saat `books.isEmpty` dan tidak ada PIN/Biometrik aktif).
* **Elemen UI**:
  * Logo dompet hijau dengan judul "Cashbook" & slogan *"Kelola keuangan, capai tujuanmu"*.
  * Ilustrasi / animasi dompet & grafik keuangan.
  * **Tombol Utama**: **"Mulai Menggunakan Cashbook"** (Solid Hijau Emerald).
    * Langsung mengarah ke Screen 2b (`/create-initial-book`) tanpa login apapun.
  * **Tombol Sekunder**: **"Pulihkan dari Backup"** (Outlined, icon restore).
    * Memunculkan Android native file picker (SAF - Storage Access Framework) untuk memilih file backup `.cashbook` atau file backup lainnya.
    * Tidak membutuhkan akun Google atau OAuth — pengguna cukup pilih file dari lokasi mana saja (Drive, WhatsApp, dll).
  * Badge kecil di bawah: 🔒 *"100% Lokal & Aman di Perangkat Anda"*
* **Logika**:
  * Klik **"Mulai"** → Arahkan ke `/create-initial-book`.
  * Klik **"Pulihkan dari Backup"** → Buka `FilePicker` / Android SAF → Baca file backup → Restore data lokal → Arahkan ke `/home`.

---

### Screen 2b: Onboarding - Buat Buku Kas Pertama (`/create-initial-book`)
* **Route**: `/create-initial-book`
* **Kapan Ditampilkan**: **Hanya ketika pertama kali user membuka aplikasi dan belum memiliki Buku Kas sama sekali**.
* **Elemen UI**:
  * Header Sambutan:
    * Icon dompet/buku elegan.
    * Judul: *"Selamat Datang di Cashbook! 🎉"*
    * Subjudul: *"Mari buat Buku Kas pertama Anda untuk mulai mencatat keuangan (misal: Kas Pribadi atau Kas Usaha)."*
  * Form Pembuatan Buku Perdana:
    1. **Nama Buku Kas**: Input teks (contoh: *"Kas Pribadi"*).
    2. **Quick Chips (Saran Nama Cepat)**: `[💼 Kas Pribadi]` `[🏪 Kas Toko / Usaha]` `[🏠 Kas Rumah Tangga]` `[💰 Tabungan]`.
    3. **Pilihan Ikon**: Pilihan icon representatif (Dompet, Toko, Keranjang, Rumah, Mobil, Briefcase).
    4. **Pilihan Warna Tema**: Palette bulat pilihan warna (Hijau Emerald, Biru, Oranye, Ungu, Teal).
    5. **Saldo Awal (Opsional)**: Input nominal (default `Rp 0`).
  * Tombol Aksi: **"Mulai Menggunakan Cashbook"** (Solid Hijau Emerald `#15803D`).
* **Logika Eksekusi**:
  * Membuat record `BookModel` pertama.
  * Menetapkan ID buku tersebut sebagai `activeBookId`.
  * Men-generate kategori default pemasukan & pengeluaran.
  * Menyimpan file perdana `data.cashbook` secara lokal dan men-trigger pembuatan file di Google Drive.
  * Redirect ke `/home` (Dashboard) dengan buku kas baru tersebut aktif dan siap pakai.

---

### Screen 3: Home / Dashboard (`03-home-dashboard`)
* **Route**: `/home`
* **Elemen UI & Layout Header**:
  * **Area Logo & Dropdown Books (Top Header)**:
    1. **Logo & Nama Aplikasi**: Logo Cashbook di pojok kiri atas, lonceng notifikasi (dengan unread badge) di pojok kanan atas.
    2. **Dropdown Books (Tepat di Bawah Logo)**:
       * Berupa selector dropdown elegan: `[ 💼 Kas Pribadi ▾ ]` dengan icon buku/folder, nama buku aktif, dan icon panah chevron down.
       * Tap dropdown membuka **BottomSheet / Dialog Pilih Buku Kas**:
         * Menampilkan daftar seluruh Buku Kas (`books`) yang tersedia (misal: *Kas Pribadi*, *Kas Usaha / Toko*, *Kas Tabungan*).
         * Setiap item menampilkan nama buku, ikon, warna tema, dan saldo buku saat ini.
         * Tombol aksi di bagian bawah: **"+ Buat Buku Kas Baru"**.
  * **Logika Persistence Buku Aktif (Last Active Book)**:
    * **Setiap kali user membuka aplikasi**: Sistem otomatis langsung memuat dan mengarah ke **`books` terakhir yang aktif** (disimpan di `activeBookId` pada `shared_preferences` / `data.cashbook`).
    * Pengguna tidak perlu memilih ulang buku kas setiap kali membuka aplikasi.
  * **Penyajian Data Berdasarkan Buku Aktif**:
    * **Semua data Cash Out (Pengeluaran) & Cash In (Pemasukan) yang ditampilkan SELALU difilter ketat berdasarkan `books` yang sedang aktif (`bookId == activeBookId`)**.
    * Begitu pengguna mengganti buku di dropdown, seluruh komponen UI langsung me-refresh seketika untuk buku tersebut.
  * **Kartu Saldo**:
    * Menampilkan Saldo khusus untuk Buku Kas yang sedang aktif.
    * Tombol sembunyikan nominal (icon mata).
    * Saldo dihitung: `Total Pemasukan Buku Aktif - Total Pengeluaran Buku Aktif`.
  * **Quick Action Buttons**:
    * 🟢 Tambah Pemasukan (`/transaction/add-income`): Otomatis mengarah ke buku aktif.
    * 🔴 Tambah Pengeluaran (`/transaction/add-expense`): Otomatis memotong saldo buku aktif.
    * 🔵 **Transfer**: Memindahkan saldo dari buku kas aktif ke buku kas lainnya.
  * **Ringkasan Bulan Ini**: Total Pemasukan, Pengeluaran, dan Selisih untuk buku aktif pada bulan terpilih.
  * **Transaksi Terbaru**: Menampilkan 3-5 catatan riwayat cash in/out terbaru milik buku aktif + link "Lihat Semua".
  * **Bottom Navigation Bar**: Beranda, Transaksi, Laporan, Akun.

---

### Screen 4: Tambah Pemasukan (`04-tambah-pemasukan`)
* **Route**: `/add-income`
* **Elemen UI**:
  * Input Nominal (format otomatis ribuan Rupiah, misal `Rp 1.000.000`).
  * Quick Amount Pills (+10.000, +50.000, +100.000, dll).
  * Pemilihan Kategori Pemasukan (Gaji, Penjualan, Investasi, dll).
  * Pemilihan Tanggal (Date picker, default hari ini).
  * Catatan Transaksi (opsional).
  * Tombol **Simpan**.
* **Logika**:
  * Otomatis menyimpan transaksi ke **buku kas yang sedang aktif** (`activeBookId`) tanpa perlu memilih buku lagi.
  * Simpan ke penyimpanan lokal `data.cashbook`.

---

### Screen 5: Tambah Pengeluaran (`05-tambah-pengeluaran`)
* **Route**: `/add-expense`
* **Elemen UI**:
  * Input Nominal (`Rp 250.000`).
  * Quick Amount Pills (+10.000, +50.000, +100.000, dll).
  * Pemilihan Kategori Pengeluaran (Makan & Minum, dll).
  * Pemilihan Tanggal & Catatan.
  * Tombol **Simpan**.
* **Logika**:
  * Otomatis mengurangi saldo dari **buku kas yang sedang aktif** (`activeBookId`) tanpa perlu memilih buku lagi.
  * Simpan ke penyimpanan lokal `data.cashbook`.

---

### Screen 6: Daftar Transaksi (`06-daftar-transaksi`)
* **Route**: `/transactions`
* **Elemen UI**:
  * Search Bar & Filter Pills: `Semua` | `Pemasukan (Cash In)` | `Pengeluaran (Cash Out)`.
  * Grouping berdasarkan Tanggal (contoh: "12 Okt 2025").
  * **Data Transaksi**: Menampilkan riwayat transaksi milik **Buku Kas yang sedang aktif** (dipilih dari Beranda).
* **Interaksi**: Klik item membuka Screen 7 (Detail Transaksi).

---

### Screen 7: Detail Transaksi (`07-detail-transaksi`)
* **Route**: `/transaction/detail/:id`
* **Elemen UI**:
  * Hero Section: Icon kategori besar, judul transaksi, nominal besar.
  * List info: Kategori, Tanggal & Waktu, Catatan.
  * Tombol **Edit** & Tombol **Hapus** (dengan pop-up dialog konfirmasi).
* **Logika**:
  * Jika dihapus ➔ Hapus dari `data.cashbook` lokal dan sync ke Google Drive.

---

### Screen 8: Laporan Keuangan & Ekspor (`08-laporan`)
* **Route**: `/reports`
* **Elemen UI**:
  * **Header**: Judul "Laporan" + Indikator Buku Kas Aktif.
  * **Periode Selector Tabs**:
    * `Bulan ini`: Menampilkan data bulan kalender aktif.
    * `Tahun ini`: Menampilkan rekap tahun berjalan.
    * `Custom (Rentang Tanggal Khusus)`:
      * Tap membuka **DateRangePicker Modal** interaktif (pilih Tanggal Mulai dan Tanggal Selesai, misal: *25 Sep 2025 – 24 Okt 2025* untuk siklus gajian).
      * Menampilkan badge rentang tanggal terpilih di bawah tab.
  * **Kartu Ringkasan (Buku Aktif)**: Total Pemasukan, Total Pengeluaran, Selisih Bersih milik buku kas yang sedang aktif pada rentang waktu terpilih.
  * **Grafik Keuangan** (Bar Chart menggunakan library `fl_chart`):
    * Menampilkan tren perbandingan pemasukan vs pengeluaran.
    * Batang Hijau: Pemasukan (Cash In).
    * Batang Merah: Pengeluaran (Cash Out).
  * **Aksi Ekspor Laporan (Export Action Buttons)**:
    * **`[ 📄 Ekspor PDF ]`**:
      * Men-generate file PDF resmi yang siap dicetak atau dibagikan via WhatsApp.
      * Format: Kop Laporan Cashbook, Nama Buku Kas, Periode Tanggal, Tabel Ringkasan Keuangan, dan Rincian Seluruh Transaksi.
    * **`[ 📊 Ekspor Excel (.xlsx / .csv) ]`**:
      * Men-generate spreadsheet tabel lengkap dengan kolom: *No, Tanggal, Jam, Tipe (In/Out), Kategori, Keterangan, Nominal, dan Catatan*.

---

### Screen 9: Kategori (`09-kategori`)
* **Route**: `/categories`
* **Elemen UI**:
  * Switcher: Tab Pemasukan & Tab Pengeluaran.
  * List Kategori dengan icon dan background warna unik (Makan & Minum, Transportasi, Belanja, Kesehatan, Pendidikan, Hiburan, Tagihan, Lainnya).
  * Tombol tambah kategori custom.

---

### Screen 10: Pengaturan Akun (`10-pengaturan-akun`)
* **Route**: `/account`
* **Elemen UI**:
  * **Header Lokal** (tanpa avatar Google): Icon perangkat + teks *"Mode Lokal — Data Tersimpan di Perangkat"*.
  * Menu List Lengkap:
    1. **Kelola Buku Kas / Folder**:
       * Menampilkan jumlah buku kas (contoh: *"2 Buku Kas Aktif"*).
       * Tap membuka halaman manajemen Buku: tambah buku baru, edit nama, pilih warna & icon tema, atau pindahkan ke Tong Sampah.
    2. **Keamanan & Kunci Aplikasi**:
       * Status badge: *Aktif (PIN & Biometrik)* / *Nonaktif*.
       * Tap membuka sheet konfigurasi:
         * Toggle Kunci PIN (input & konfirmasi 4/6 digit PIN).
         * Toggle Kunci Biometrik (Sidik Jari / Face ID).
         * Menu "Ubah PIN".
    3. **Backup & Pemulihan Data** (via Android Native — 100% Gratis):
       * **"Backup ke Google Drive"** / **"Simpan Backup ke..."**:
         * Menggunakan Android SAF (`share_plus` atau `file_picker`) untuk menyimpan file `data.cashbook` ke lokasi pilihan pengguna (Drive, SD Card, dll).
         * Tidak memerlukan login Google / OAuth.
       * **"Pulihkan dari Backup"**:
         * Membuka file picker → pengguna pilih file backup `data.cashbook` → data di-restore ke perangkat.
       * Menampilkan info: *"Backup Terakhir: 12 Okt 2025, 09:10"*.
    4. **Tong Sampah / Trash**:
       * Menampilkan badge jumlah item terhapus (misal: *"1 Buku Kas di Sampah"*).
       * Tap membuka **Screen 10b (`/trash`)**.
    5. **Tema**: Toggle Mode Terang, Gelap, atau Ikuti Sistem.
    6. **Notifikasi**: Atur jadwal pengingat catat kasir harian.
    7. **Tentang Cashbook**: Versi aplikasi dan lisensi.

---

### Screen 10b: Tong Sampah / Trash (`/trash`)
* **Route**: `/trash`
* **Tujuan**: Mencegah kehilangan data buku kas dan transaksi akibat ketidaksengajaan pengguna melalui mekanisme **Soft-Delete**.
* **Elemen UI**:
  * Header: Tombol kembali + Title "Tong Sampah".
  * Switcher Tab: **`Buku Kas Terhapus`** & **`Transaksi Terhapus`**.
  * **Tab Buku Kas Terhapus**:
    * Daftar buku kas dengan status `isDeleted = true`.
    * Menampilkan nama buku, tanggal dihapus, dan total transaksi yang ada di dalamnya.
    * Tombol per item:
      * 🔄 **"Pulihkan (Restore)"**: Mengembalikan buku kas dan seluruh transaksinya ke status aktif (`isDeleted = false`).
      * 🗑️ **"Hapus Permanen"**: Menghapus total buku dan transaksinya dari database lokal & Google Drive (memerlukan konfirmasi PIN/dialog peringatan merah ganda).
  * **Tab Transaksi Terhapus**:
    * Menampilkan list transaksi yang dihapus secara individual.
    * Tombol: "Pulihkan" atau "Hapus Permanen".

---

## 6. Struktur Data File `data.cashbook` & Data Models

### 6.1. Skema JSON/Database di dalam file `data.cashbook`:

```json
{
  "version": 1,
  "lastSyncedAt": "2025-10-12T09:10:00Z",
  "activeBookId": "book_1",
  "deviceInfo": "Pixel 7 Pro",
  "user": {
    "email": "andi@example.com",
    "name": "Andi Pratama"
  },
  "settings": {
    "theme": "system",
    "currency": "IDR",
    "hideBalance": false,
    "security": {
      "pinEnabled": false,
      "biometricEnabled": false
    }
  },
  "books": [
    {
      "id": "book_1",
      "name": "Kas Pribadi",
      "icon": "wallet",
      "color": "#15803D",
      "description": "Pengeluaran harian dan gaji",
      "initialBalance": 0,
      "createdAt": "2025-10-01T00:00:00Z",
      "updatedAt": "2025-10-12T09:10:00Z",
      "isDeleted": false,
      "deletedAt": null
    },
    {
      "id": "book_2",
      "name": "Kas Toko / Usaha",
      "icon": "store",
      "color": "#3B82F6",
      "description": "Operasional penjualan toko",
      "initialBalance": 1000000,
      "createdAt": "2025-10-01T00:00:00Z",
      "updatedAt": "2025-10-12T09:10:00Z",
      "isDeleted": false,
      "deletedAt": null
    }
  ],
  "categories": [
    { "id": "cat_1", "name": "Gaji", "type": "income", "icon": "wallet", "color": "#16A34A" },
    { "id": "cat_2", "name": "Makan & Minum", "type": "expense", "icon": "utensils", "color": "#EF4444" },
    { "id": "cat_3", "name": "Transportasi", "type": "expense", "icon": "car", "color": "#F97316" }
  ],
  "transactions": [
    {
      "id": "tx_1001",
      "bookId": "book_1",
      "title": "Makan Siang",
      "amount": 45000,
      "type": "expense",
      "categoryId": "cat_2",
      "date": "2025-10-12T12:30:00Z",
      "note": "Makan siang di warung",
      "isSynced": true,
      "isDeleted": false,
      "deletedAt": null,
      "createdAt": "2025-10-12T12:30:00Z",
      "updatedAt": "2025-10-12T12:30:00Z"
    }
  ]
}
```

### 6.2. Dart Entity Models

#### Model `BookModel` (Parent Folder / Grup Buku Kas)
```dart
class BookModel {
  final String id;
  final String name;
  final String icon;        // Material / Lucide Icon Name
  final int colorValue;     // Hex ARGB
  final String? description;
  final double initialBalance;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final DateTime? deletedAt;

  BookModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
    this.description,
    this.initialBalance = 0.0,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.deletedAt,
  });
}
```

#### Model `TransactionModel` (Child Item di bawah Buku Kas)
```dart
enum TransactionType { income, expense, transfer }

class TransactionModel {
  final String id;
  final String bookId;            // Relasi ke Parent BookModel
  final String? targetBookId;     // Digunakan jika type == TransactionType.transfer
  final String title;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final DateTime date;
  final String? note;
  final bool isSynced;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionModel({
    required this.id,
    required this.bookId,
    this.targetBookId,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    this.note,
    this.isSynced = false,
    this.isDeleted = false,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });
}
```

---

## 7. Dependensi Paket Flutter (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Routing & Deep Linking
  go_router: ^14.0.0
  app_links: ^6.1.1

  # State Management
  flutter_bloc: ^8.1.5
  equatable: ^2.0.5

  # Google Auth & Google Drive API
  google_sign_in: ^6.2.1
  googleapis: ^13.2.0
  extension_google_sign_in_as_googleapis_auth: ^2.0.12
  http: ^1.2.1

  # Local Storage, File Management & Security
  path_provider: ^2.1.3
  shared_preferences: ^2.2.3
  flutter_secure_storage: ^9.2.2
  local_auth: ^2.2.0

  # Export & Sharing (PDF, Excel, WhatsApp/Sosmed Share)
  pdf: ^3.10.8
  printing: ^5.13.0
  excel: ^4.0.3
  share_plus: ^9.0.0

  # UI, Icons, Typography & Charts
  google_fonts: ^6.2.1
  flutter_svg: ^2.0.10+1
  fl_chart: ^0.68.0
  intl: ^0.19.0
  lucide_icons: ^0.250.0

  # Utilities
  uuid: ^4.4.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
```

---

## 8. Roadmap Implementasi

1. **Fase 1: Setup Theme (Light & Dark) & Offline-First Auth**
   * Konfigurasi `AppTheme` (Light/Dark tokens) & `ThemeCubit`.
   * Implementasi Screen 1 (Splash — cek PIN/biometrik lokal).
   * Implementasi Screen 2 (Welcome Screen — first-time setup, tanpa Google).
   * Setup `BiometricService` (PIN + Fingerprint/Face ID via `local_auth`).
2. **Fase 2: Local Storage (`data.cashbook`)**
   * Buat `LocalStorageService` untuk menyimpan & membaca file `data.cashbook` lokal.
   * Tidak ada cloud sync wajib — data tersimpan 100% di perangkat.
3. **Fase 3: Layar Dashboard & Input Transaksi**
   * Screen 3 (Dashboard & Saldo Card auto-calculate).
   * Screen 4 (Tambah Pemasukan) & Screen 5 (Tambah Pengeluaran).
4. **Fase 4: Riwayat, Laporan Grafik & Kategori**
   * Screen 6 (Daftar Transaksi grouped by date) & Screen 7 (Detail Transaksi).
   * Screen 8 (Laporan Bar Chart `fl_chart`).
   * Screen 9 (Kategori Pemasukan & Pengeluaran).
5. **Fase 5: Akun, Backup & Keamanan**
   * Screen 10 (Pengaturan Akun, Switcher Tema Light/Dark, Keamanan PIN/Biometrik).
   * Fitur **Backup & Restore** via Android SAF (file picker native — tanpa OAuth):
     * Backup: Simpan `data.cashbook` ke Drive/SD via `share_plus`.
     * Restore: Buka file backup via `file_picker`, restore data lokal.
