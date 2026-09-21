# Spesifikasi Teknis & Business Logic Aplikasi Cashbook (Flutter Mobile)

Dokumen spesifikasi teknis, arsitektur, dan panduan implementasi komprehensif aplikasi mobile **Cashbook** berbasis **Flutter** sesuai dengan business logic dan kode implementasi produksi saat ini.

---

## 1. Ringkasan Proyek & Arsitektur

| Parameter | Spesifikasi |
|---|---|
| **Nama Aplikasi** | **Cashbook** (Aplikasi Catatan Keuangan & Kasir Digital Pribadi) |
| **Pengembang** | **TRHAH Tech** (v1.0.0 • 100% Free & Serverless) |
| **Sistem Pengelompokan** | **Multi-Buku Kas (Multi-Folder)**: Transaksi dikelompokkan per Buku Kas (misal: *Kas Pribadi*, *Kas Toko / Usaha*, *Kas Tabungan*). |
| **Pusat Pemilihan Buku Kas** | **Terpusat di Beranda (Home)**: Pemilihan buku kas aktif dilakukan di Beranda via `BookDropdownSelector`. Form transaksi (`/add-income` & `/add-expense`), riwayat transaksi, dan laporan otomatis menggunakan buku kas aktif tanpa perlu memilih buku lagi. |
| **Persistence Buku Kas** | ID buku kas aktif tersimpan secara otomatis dan persisten di `SharedPreferences` (`active_book_id`) dan file `data.cashbook` (`activeBookId`). Saat aplikasi dibuka kembali, buku aktif terakhir otomatis termuat. |
| **Kategori Transaksi** | **Global & Smart Suggestion**: Kategori bersifat global (dapat digunakan lintas pemasukan/pengeluaran), menggunakan input *combobox / semi-dropdown* (`CategorySuggestField`), otomatis kapitalisasi kata (*Title Case*), deduplikasi *case-insensitive*, dan mengingat kategori terakhir yang dipakai (`lastUsedCategoryId`). |
| **Keamanan Aplikasi** | **Kunci Aplikasi Native Android** (`local_auth`): Menggunakan autentikasi bawaan sistem (Biometrik / Sidik Jari / Face Unlock / PIN / Pola / Sandi perangkat). Custom in-app numeric keypad ditiadakan demi keamanan standar OS. Status tersimpan terenkripsi di `flutter_secure_storage`. |
| **Sistem Penghapusan** | **Soft-Delete & Tong Sampah (Trash)**: Buku kas dan transaksi yang dihapus tidak langsung hilang, melainkan ditandai `isDeleted = true` dan masuk ke Tong Sampah (`/trash`). Pengguna dapat melakukan **Restore** (Pulihkan) atau **Hapus Permanen (Purge)** dengan dialog konfirmasi ganda. Tersedia juga fitur **Kosongkan Sampah (Empty Trash)**. |
| **Penyimpanan Data** | **100% Offline-First (File `data.cashbook`)**: Seluruh data (pengaturan, buku, kategori, transaksi) disimpan dalam format JSON terstruktur di direktori dokumen internal perangkat (`getApplicationDocumentsDirectory()/data.cashbook`). |
| **Backup & Restore Lokal** | **Android Storage Access Framework (SAF) / Native File Sharing**: <br>• **Backup**: Ekspor berkas `data.cashbook` via `share_plus` (bisa disimpan ke Google Drive, WhatsApp, File Manager, SD Card). <br>• **Restore**: Impor berkas `data.cashbook` via `file_picker` dengan dialog konfirmasi validasi JSON. |
| **Sinkronisasi Cloud** | **Google Drive API v3**: Sinkronisasi opsional langsung ke Google Drive pengguna via tombol sinkronisasi di AppBar Beranda (`google_sign_in` & `googleapis` scope `drive.file` dan `drive.appdata`). |
| **Laporan & Grafik** | **Grafik Batang Perbandingan (`fl_chart`) & Breakdown Kategori**: Visualisasi perbandingan pemasukan vs pengeluaran, ringkasan saldo bersih, serta breakdown persentase pengeluaran & pemasukan per kategori. |
| **Periode Laporan** | **Semua, Bulan Ini, Bulan Lalu, Tahun Ini, & Kustom**: Pilihan rentang tanggal dinamis menggunakan `showDateRangePicker`. |
| **Ekspor Laporan** | **Ekspor PDF (`pdf` & `printing`)** format siap cetak/bagikan, dan **Ekspor Excel (.xlsx via `excel` & `share_plus`)** tabel mutasi lengkap. |
| **Multi-Bahasa (Localization)** | **5 Bahasa**: Bahasa Indonesia (`id` - default), English (`en`), Español (`es`), 简体中文 (`zh`), العربية (`ar` - RTL ready). Format mata uang, angka, dan tanggal menyesuaikan locale aktif. |
| **Dukungan Tema** | **Mode Terang (Light), Mode Gelap (Dark), & Ikuti Sistem (System)** via `ThemeCubit` & `AppTheme`. |
| **State Management** | `flutter_bloc` / Cubit (`ThemeCubit`, `LocaleCubit`, `BookCubit`, `TransactionCubit`). |
| **Routing** | `go_router` dengan arsitektur `StatefulShellRoute.indexedStack` untuk bottom navigation. |

---

## 2. Design System & Tema (Color Tokens & Typography)

Aplikasi mengimplementasikan palet warna modern berbasis Tailwind/Emerald dengan kontras tinggi di kedua tema.

### 2.1. Color Tokens (`lib/core/constants/colors.dart`)

```dart
class AppColors {
  // Brand Emerald
  static const Color primary500 = Color(0xFF10B981); // Emerald Utama
  static const Color primary600 = Color(0xFF059669);
  static const Color primary700 = Color(0xFF047857);

  // Status Finansial
  static const Color incomeGreen = Color(0xFF16A34A);  // Hijau Cash In
  static const Color expenseRed = Color(0xFFEF4444);   // Merah Cash Out
  static const Color blue500 = Color(0xFF3B82F6);      // Biru Info / Backup
  static const Color amber500 = Color(0xFFF59E0B);     // Oranye Kategori

  // Light Theme
  static const Color lightBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color lightSurface = Color(0xFFFFFFFF);    // Pure White
  static const Color lightCardBorder = Color(0xFFF1F5F9);
  static const Color lightDivider = Color(0xFFF1F5F9);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);

  // Dark Theme
  static const Color darkBackground = Color(0xFF0B1120);  // Deep Dark Slate
  static const Color darkSurface = Color(0xFF1E293B);     // Slate 800
  static const Color darkCardBorder = Color(0xFF334155);
  static const Color darkDivider = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);

  // Neutrals / Grayscale
  static const Color gray100 = Color(0xFFF1F5F9);
  static const Color gray200 = Color(0xFFE2E8F0);
  static const Color gray300 = Color(0xFFCBD5E1);
  static const Color gray400 = Color(0xFF94A3B8);
  static const Color gray500 = Color(0xFF64748B);
  static const Color gray600 = Color(0xFF475569);
  static const Color gray700 = Color(0xFF334155);
  static const Color gray800 = Color(0xFF1E293B);
  static const Color gray900 = Color(0xFF0F172A);
}
```

### 2.2. Font & Typography
* **Font Family**: Google Fonts *Plus Jakarta Sans* / *Inter* dengan fallback sistem.
* **Header Kartu Saldo**: Gradient Emerald linear `[Color(0xFF047857), Color(0xFF10B981)]` dengan rounded corner 24dp dan shadow elevasi lembut.

---

## 3. Struktur Direktori Proyek

```text
lib/
├── main.dart                                   // Entry point: init storage, services, cubits, multi-provider
├── app/
│   ├── presentation/
│   │   └── main_scaffold.dart                  // StatefulShellRoute BottomNavigationBar (Home, Transaksi, Laporan, Akun)
│   └── routes/
│       └── app_router.dart                     // GoRouter configuration, sub-routes, rootNavigatorKeys
├── core/
│   ├── constants/
│   │   └── colors.dart                         // Palet warna Light/Dark & tokens finansial
│   ├── database/
│   │   └── local_storage_service.dart          // LocalStorageService singleton (baca/tulis data.cashbook, cache memori)
│   ├── localization/
│   │   └── app_localizations.dart              // Kamus terjemahan (id, en, es, zh, ar) & AppLocalizationsDelegate
│   ├── services/
│   │   ├── biometric_service.dart              // local_auth wrapper (Android biometric & system lock)
│   │   ├── google_drive_service.dart           // Google Drive sync & file upload/download via OAuth
│   │   ├── pdf_export_service.dart             // Generator Laporan Keuangan format PDF (A4 table & header)
│   │   └── excel_export_service.dart           // Generator Laporan Keuangan format spreadsheet (.xlsx)
│   ├── theme/
│   │   └── app_theme.dart                      // ThemeData untuk Light Mode & Dark Mode
│   └── utils/
│       ├── currency_formatter.dart             // Formatter mata uang & parsing nominal ribuan (Rupiah/Dollar/Euro)
│       └── date_formatter.dart                 // Formatter tanggal kelompok riwayat, jam, dan kop cetak
└── features/
    ├── auth/presentation/
    │   ├── splash_screen.dart                  // Layar splash: verifikasi status kunci & cek ketersediaan buku
    │   └── login_screen.dart                   // Layar sambutan onboarding awal (jika belum ada buku kas sama sekali)
    ├── security/presentation/
    │   └── lock_screen.dart                    // Layar penguncian biometrik / PIN sistem native
    ├── book/
    │   ├── cubit/
    │   │   └── book_cubit.dart                 // State management buku kas (load, add, select, soft-delete, restore, purge)
    │   ├── domain/models/
    │   │   └── book_model.dart                 // Entity BookModel (id, name, icon, color, initialBalance, isDeleted, etc)
    │   └── presentation/
    │       ├── create_initial_book_screen.dart // Layar pembuatan buku kas perdana setelah welcome screen
    │       ├── manage_books_screen.dart        // Layar kelola buku kas (tambah, ubah nama/ikon/warna, hapus ke sampah)
    │       └── widgets/
    │           └── book_dropdown_selector.dart // Bottom sheet selector buku kas di layar Beranda
    ├── category/
    │   ├── domain/models/
    │   │   └── category_model.dart             // Entity CategoryModel & static icon resolver
    │   └── presentation/
    │       ├── category_list_screen.dart       // Layar kelola kategori global
    │       └── widgets/
    │           └── add_category_modal.dart     // Modal bottom sheet tambah kategori baru
    ├── dashboard/presentation/
    │   └── home_screen.dart                    // Layar Beranda: Dropdown buku, Kartu Saldo, Quick Action, Transaksi Terbaru
    ├── transaction/
    │   ├── cubit/
    │   │   └── transaction_cubit.dart          // State management transaksi & filter mutasi
    │   ├── domain/models/
    │   │   └── transaction_model.dart          // Entity TransactionModel (income, expense, transfer)
    │   └── presentation/
    │       ├── add_income_screen.dart          // Form catat pemasukan (nominal cepat, category suggestion, tanggal, simpan di AppBar)
    │       ├── add_expense_screen.dart         // Form catat pengeluaran (nominal cepat, category suggestion, tanggal, simpan di AppBar)
    │       ├── transaction_list_screen.dart    // Layar riwayat mutasi: search bar, quick add buttons, filter tab, grouped by date
    │       ├── transaction_detail_screen.dart  // Layar detail: info transaksi, tombol edit, tombol pindah ke sampah
    │       └── widgets/
    │           └── category_suggest_field.dart // Combobox input suggestion kategori dinamis
    ├── report/presentation/
    │   └── report_screen.dart                  // Layar Laporan: Filter periode, Bar Chart, Breakdown Kategori, Ekspor PDF/Excel
    ├── trash/presentation/
    │   └── trash_screen.dart                   // Layar Tong Sampah: Tab Buku Terhapus & Tab Transaksi Terhapus (Restore/Purge)
    ├── account/presentation/
    │   └── account_screen.dart                 // Layar Pengaturan Akun: Backup/Restore SAF, Navigasi Buku/Kategori/Trash, Bahasa, Tema, Kunci Aplikasi, Tentang
    ├── theme/cubit/
    │   └── theme_cubit.dart                    // State theme mode (light, dark, system)
    └── localization/cubit/
        └── locale_cubit.dart                   // State bahasa aktif (id, en, es, zh, ar)
```

---

## 4. Alur Autentikasi, Startup, & Navigasi

### 4.1. Alur Startup Aplikasi (`SplashScreen`)
```text
[Aplikasi Dibuka]
       │
       ▼
[SplashScreen (/)] ── (Delay 1000ms)
       │
       ├─► [Kunci Aplikasi Aktif?] ──► Ya ──► [/lock] ── (Autentikasi Berhasil) ──┐
       │                                                                         │
       └─► Tidak                                                                 │
           │                                                                     │
           ▼                                                                     ▼
       [Cek Data Buku Kas Lokal] ◄───────────────────────────────────────────────┘
           │
           ├─► books.isEmpty ────────► [/login] (Welcome Screen)
           │                                │
           │                                ▼
           │                         [/create-initial-book]
           │                                │
           │                                ▼
           └─► books.isNotEmpty ─────► [/home] (Dashboard Beranda)
```

### 4.2. Rute Aplikasi (`GoRouter`)

| Path | Nama Layar | Deskripsi & Parameter |
|---|---|---|
| `/` | `SplashScreen` | Layar splash & routing awal. |
| `/lock` | `LockScreen` | Layar penguncian biometrik / PIN native. |
| `/login` | `LoginScreen` | Layar sambutan first-time user (Mulai / Pulihkan Backup). |
| `/create-initial-book` | `CreateInitialBookScreen` | Form onboarding pembuatan buku kas pertama. |
| `/home` | `HomeScreen` | Shell Tab 0: Dashboard Beranda, Saldo, Quick Action. |
| `/transactions` | `TransactionListScreen` | Shell Tab 1: Riwayat Transaksi & Pencarian. |
| `/report` | `ReportScreen` | Shell Tab 2: Grafik, Ringkasan, Ekspor PDF/Excel. |
| `/account` | `AccountScreen` | Shell Tab 3: Pengaturan Akun, Backup, Bahasa, Tema. |
| `/add-income` | `AddIncomeScreen` | Form catat pemasukan. Menerima `extra: TransactionModel?` untuk mode edit. |
| `/add-expense` | `AddExpenseScreen` | Form catat pengeluaran. Menerima `extra: TransactionModel?` untuk mode edit. |
| `/transaction-detail/:id` | `TransactionDetailScreen` | Detail transaksi berdasarkan ID parameter. |
| `/manage-books` | `ManageBooksScreen` | Layar manajemen buku kas (CRUD & status). |
| `/categories` | `CategoryListScreen` | Layar kelola kategori global. |
| `/trash` | `TrashScreen` | Layar Tong Sampah (Buku & Transaksi terhapus). |

---

## 5. Business Logic Fitur Utama

### 5.1. Sistem Multi-Buku Kas (Multi-Folder)
1. **Pusat Penggantian Buku Hanya di Beranda**:
   * Switcher buku kas (`BookDropdownSelector`) ditempatkan tepat di bawah logo aplikasi pada layar Beranda.
   * Menampilkan nama buku aktif, ikon, warna tema, dan tombol chevron down.
   * Mengetuk selector akan membuka modal bottom sheet yang menampilkan seluruh buku kas aktif (`isDeleted == false`) beserta tombol pintas **"Kelola"** yang mengarah ke `/manage-books`.
2. **Keterikatan Transaksi ke Buku Aktif**:
   * Saat pengguna membuka form **Tambah Pemasukan** (`/add-income`) atau **Tambah Pengeluaran** (`/add-expense`), transaksi otomatis terikat pada `activeBookId` saat itu.
   * Form transaksi **tidak menampilkan dropdown pemilihan buku**, meminimalkan friksi pengguna saat mencatat keuangan harian.
3. **Penyaringan Riwayat & Laporan**:
   * Layar Transaksi dan Laporan otomatis menampilkan mutasi milik buku kas aktif (`t.bookId == activeBookId`).
   * Begitu buku aktif diganti di Beranda, `BookCubit` memperbarui state dan mentrigger `TransactionCubit.loadTransactions(newBookId)` sehingga seluruh tab sinkron seketika.
4. **Kalkulasi Saldo Buku**:
   $$\text{Saldo} = \text{Saldo Awal (initialBalance)} + \sum \text{Pemasukan} - \sum \text{Pengeluaran} \pm \sum \text{Transfer}$$
   * Jika transaksi transfer: memotong buku asal (`tx.bookId`) dan menambah buku tujuan (`tx.targetBookId`).
5. **Manajemen Buku Kas (`ManageBooksScreen`)**:
   * Menambah buku kas baru (nama, pilihan ikon, pilihan warna tema, saldo awal opsional).
   * Mengubah buku kas yang ada.
   * Menghapus buku kas: dilakukan secara *soft-delete* (masuk ke `/trash`). Jika buku yang dihapus adalah buku aktif, sistem otomatis memilih buku aktif lain yang tersisa.

### 5.2. Sistem Kategori & Smart Suggestion (`CategorySuggestField`)
1. **Kategori Global**:
   * Kategori bersifat universal, dapat dipilih untuk transaksi pemasukan maupun pengeluaran.
2. **Combobox Suggestion Dinamis**:
   * Pengguna dapat memilih kategori dari daftar drop-down suggestion atau langsung mengetik nama kategori baru.
   * Input teks otomatis diformat menjadi huruf kapital setiap awal kata (*Title Case*) via helper `CategoryModel.capitalizeWords()`.
3. **Auto-Upsert & Anti-Duplikasi**:
   * Sebelum transaksi disimpan, sistem melakukan `storage.upsertCategory()`.
   * Jika kategori dengan nama yang sama (case-insensitive) sudah ada di database, sistem menggunakan ID kategori lama tanpa membuat duplikasi.
   * Jika belum ada, kategori baru otomatis dibuat dan disimpan ke database `data.cashbook`.
4. **Penyimpanan Kategori Terakhir Digunakan (`lastUsedCategoryId`)**:
   * Sistem mencatat ID kategori terakhir yang digunakan untuk pemasukan (`last_category_income`) dan pengeluaran (`last_category_expense`) di `settings`.
   * Saat form dibuka berikutnya, kategori terakhir otomatis diprioritaskan di urutan teratas suggestion.

### 5.3. Form Input Transaksi (`AddIncomeScreen` & `AddExpenseScreen`)
1. **Tombol Simpan di AppBar**:
   * Tombol aksi **Simpan** (atau **Perbarui** saat mode edit) ditempatkan secara ergonomis di kanan atas `AppBar` (`actions`).
2. **Pilihan Nominal Cepat (Quick Amount Pills)**:
   * Tersedia tombol chip nominal cepat: `+Rp 50.000`, `+Rp 100.000`, `+Rp 500.000`, `+Rp 1.000.000`, `+Rp 2.500.000`, `+Rp 5.000.000`.
   * Mengetuk chip langsung mengisi nilai pada kolom nominal.
3. **Format Angka Dinamis**:
   * Input nominal mendukung separator ribuan dinamis sesuai locale pengguna melalui `CurrencyFormatter`.
4. **Pemilihan Tanggal**:
   * Default tanggal transaksi adalah hari ini (`DateTime.now()`). Pengguna dapat memilih tanggal melalui kalender `showDatePicker`.
5. **Catatan Tambahan**:
   * Kolom input teks opsional untuk keterangan detail mutasi kasir.
6. **Mode Edit Transaksi**:
   * Form yang sama dapat menerima parameter `TransactionModel` via `state.extra`. Kolom nominal, tanggal, kategori, dan catatan otomatis terisi sesuai data transaksi lama.

### 5.4. Riwayat Transaksi (`TransactionListScreen`)
1. **Sticky Top Bar**:
   * **Pencarian Real-Time**: Kolom pencarian teks yang memfilter mutasi berdasarkan nama kategori dan catatan secara instan, dilengkapi tombol clear (`X`).
   * **Tombol Cepat Tambah Transaksi**: Tombol **+ Pemasukan** (hijau) dan **- Pengeluaran** (merah) tepat di bawah search bar untuk kemudahan pencatatan langsung dari tab riwayat.
   * **Filter Tab**: Filter mutasi `Semua`, `Masuk (Pemasukan)`, dan `Keluar (Pengeluaran)`.
2. **Pengelompokan Berdasarkan Tanggal**:
   * Transaksi dikelompokkan per tanggal kalender (contoh: *"Hari Ini"*, *"Kemarin"*, atau *"12 Okt 2026"*).
3. **Aksi Item Transaksi**:
   * Mengetuk item membuka detail transaksi (`/transaction-detail/:id`).

### 5.5. Detail & Soft-Delete Transaksi (`TransactionDetailScreen`)
1. **Tampilan Detail**:
   * Menampilkan ikon kategori besar, tipe transaksi, nominal besar dengan warna status, tanggal & jam mutasi, serta catatan.
2. **Ubah Transaksi**:
   * Tombol edit di AppBar mengarahkan ke form tambah dengan mode edit (`context.push(route, extra: tx)`).
3. **Pindahkan ke Sampah**:
   * Tombol hapus memunculkan dialog konfirmasi soft-delete. Jika disetujui, mutasi ditandai `isDeleted = true` dan dipindahkan ke Tong Sampah.

### 5.6. Laporan Keuangan & Ekspor (`ReportScreen`)
1. **Pemilihan Rentang Waktu (Period Selector)**:
   * `Semua (All)`: Seluruh riwayat transaksi buku aktif.
   * `Bulan Ini (This Month)`: Tanggal 1 s.d. hari ini / akhir bulan kalender berjalan.
   * `Bulan Lalu (Last Month)`: Rekap bulan kalender sebelumnya.
   * `Tahun Ini (This Year)`: Dari 1 Januari s.d. hari ini pada tahun berjalan.
   * `Kustom (Custom Range)`: Menggunakan modal `showDateRangePicker` untuk memilih rentang tanggal bebas (misal: siklus gajian *25 Sep – 24 Okt*).
2. **Ringkasan Finansial**:
   * Menampilkan Total Pemasukan, Total Pengeluaran, dan Saldo Bersih (*Net Balance*).
3. **Grafik Aliran Kas (`BarChart` via `fl_chart`)**:
   * Batang Hijau: Total Pemasukan pada periode terpilih.
   * Batang Merah: Total Pengeluaran pada periode terpilih.
4. **Daftar Rincian Kategori (Breakdown List)**:
   * Daftar pengeluaran dan pemasukan per kategori beserta nominal dan bilah persentase proporsi.
5. **Ekspor Laporan Resmi**:
   * **PDF Export (`PdfExportService`)**: Men-generate berkas A4 resmi berisi kop judul buku kas, rentang periode, ringkasan saldo, dan tabel rincian mutasi (No, Tanggal, Jam, Kategori, Tipe, Catatan, Nominal). Membuka sheet preview/print/share native via library `printing`.
   * **Excel Export (`ExcelExportService`)**: Men-generate berkas spreadsheet `.xlsx` terstruktur dan langsung membuka Android Share Sheet via `share_plus`.

### 5.7. Tong Sampah & Pemulihan Data (`TrashScreen`)
1. **Tab Navigasi**:
   * **Buku Kas Terhapus**: Menampilkan buku-buku kas berstatus `isDeleted = true`.
   * **Transaksi Terhapus**: Menampilkan transaksi berstatus `isDeleted = true`.
2. **Aksi per Item**:
   * **Pulihkan (Restore)**: Mengembalikan buku atau transaksi ke daftar aktif (`isDeleted = false`).
   * **Hapus Permanen (Purge)**: Menghapus data secara permanen dari file `data.cashbook` dengan dialog konfirmasi merah.
3. **Kosongkan Sampah (Empty Trash)**:
   * Tombol di AppBar untuk membersihkan seluruh buku dan transaksi yang terhapus sekaligus secara permanen.

### 5.8. Keamanan & Kunci Aplikasi (`BiometricService` & `LockScreen`)
1. **Integrasi Keamanan Sistem Android (`local_auth`)**:
   * Aplikasi memanfaatkan dialog autentikasi native sistem Android (`biometricOnly: false`).
   * Mendukung Fingerprint, Face Unlock, PIN, Pola, atau Sandi yang telah dikonfigurasi di pengaturan keamanan perangkat pengguna.
2. **Aktivasi di Layar Pengaturan**:
   * Pengguna mengaktifkan/menonaktifkan kunci aplikasi via toggle switch di Pengaturan Akun.
   * Menyalakan atau mematikan toggle mewajibkan verifikasi autentikasi biometrik/PIN perangkat terlebih dahulu.
   * Status tersimpan di `flutter_secure_storage` (`app_lock_enabled`).
3. **Layar Penguncian (`LockScreen`)**:
   * Muncul saat aplikasi dibuka jika kunci aktif.
   * Memunculkan prompt keamanan native secara otomatis.
   * Jika gagal atau dibatalkan, terdapat tombol **"Buka Kunci"** untuk memicu ulang dialog autentikasi.
   * Setelah sukses, pengguna diarahkan ke `/home`.

### 5.9. Backup, Restore, & Google Drive Sync
1. **Penyimpanan Lokal (`LocalStorageService`)**:
   * File database: `getApplicationDocumentsDirectory()/data.cashbook`.
   * Format isi: JSON terstruktur yang memuat metadata, settings, books, categories, dan transactions.
2. **Backup Lokal (Android SAF / Share Sheet)**:
   * Di menu Pengaturan Akun: tombol **"Cadangkan (Backup)"** memicu `_handleBackup()`.
   * File `data.cashbook` dibagikan via `share_plus` (bisa disimpan ke Google Drive pribadi, WhatsApp, File Manager lokal, SD Card, dll) tanpa memerlukan integrasi API rumit.
3. **Restore Lokal (File Picker)**:
   * Di menu Pengaturan Akun: tombol **"Pulihkan (Restore)"** membuka `file_picker`.
   * Pengguna memilih berkas `data.cashbook`.
   * Sistem memvalidasi integritas JSON, menimpa berkas lokal perangkat, dan memuat ulang `BookCubit` serta `TransactionCubit` secara reaktif.
4. **Sinkronisasi Google Drive Langsung (`GoogleDriveService`)**:
   * Ikon awan sinkronisasi (`cloud_sync_outlined`) di AppBar Beranda.
   * Melakukan sign-in Google via `google_sign_in` dengan scope `drive.file` dan `drive.appdata`.
   * Mencari berkas `data.cashbook` di Drive. Jika belum ada, file lokal diunggah. Jika sudah ada, file digabungkan/diperbarui.

### 5.10. Multi-Bahasa (Localization) & Tema
1. **5 Pilihan Bahasa**:
   * `id`: Bahasa Indonesia (Default)
   * `en`: English
   * `es`: Español
   * `zh`: 简体中文
   * `ar`: العربية (Dukungan RTL)
2. **Pergantian Instan**:
   * Pengguna memilih bahasa di Pengaturan Akun melalui modal dialog. Pilihan disimpan di `SharedPreferences` (`app_language_code`) dan langsung memperbarui seluruh antarmuka aplikasi via `LocaleCubit` tanpa restart.
3. **Pergantian Tema**:
   * Mode Terang, Mode Gelap, dan Ikuti Sistem dikelola via `ThemeCubit` dan tersimpan di `SharedPreferences`.

---

## 6. Spesifikasi Struktur Data (`data.cashbook`) & Data Models

### 6.1. Skema File `data.cashbook`

```json
{
  "version": 1,
  "lastSyncedAt": "2026-09-21T17:30:00.000Z",
  "activeBookId": "book_1726912345678",
  "settings": {
    "theme": "system",
    "currency": "IDR",
    "hideBalance": false,
    "last_category_income": "cat_salary",
    "last_category_expense": "cat_food",
    "security": {
      "pinEnabled": false,
      "biometricEnabled": false
    }
  },
  "books": [
    {
      "id": "book_1726912345678",
      "name": "Kas Pribadi",
      "icon": "briefcase",
      "color": "#10B981",
      "colorValue": 4279302529,
      "description": "Catatan keuangan pribadi harian",
      "initialBalance": 0.0,
      "isReadOnly": false,
      "sharedBy": null,
      "isClosed": false,
      "closedAt": null,
      "createdAt": "2026-09-21T08:00:00.000Z",
      "updatedAt": "2026-09-21T08:00:00.000Z",
      "isDeleted": false,
      "deletedAt": null
    }
  ],
  "categories": [
    {
      "id": "cat_salary",
      "name": "Gaji",
      "type": "income",
      "icon": "wallet",
      "color": "#16A34A",
      "colorValue": 4280145738
    },
    {
      "id": "cat_food",
      "name": "Makan & Minum",
      "type": "expense",
      "icon": "utensils",
      "color": "#EF4444",
      "colorValue": 4293862468
    }
  ],
  "transactions": [
    {
      "id": "tx_1726912399999",
      "bookId": "book_1726912345678",
      "targetBookId": null,
      "title": "Makan & Minum",
      "categoryName": "Makan & Minum",
      "amount": 25000.0,
      "type": "expense",
      "categoryId": "cat_food",
      "date": "2026-09-21T12:30:00.000Z",
      "transactionDate": "2026-09-21T12:30:00.000Z",
      "note": "Makan siang warteg",
      "isSynced": false,
      "isDeleted": false,
      "deletedAt": null,
      "createdAt": "2026-09-21T12:30:00.000Z",
      "updatedAt": "2026-09-21T12:30:00.000Z"
    }
  ]
}
```

### 6.2. Entity Models Dart

#### `BookModel` (`lib/features/book/domain/models/book_model.dart`)
```dart
class BookModel {
  final String id;
  final String name;
  final String icon;          // briefcase, store, home, savings, payments, restaurant
  final int colorValue;       // Hex ARGB int
  final String? description;
  final double initialBalance;
  final bool isReadOnly;
  final String? sharedBy;
  final bool isClosed;
  final DateTime? closedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final DateTime? deletedAt;

  String get color =>
      '#${(colorValue & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  // copyWith, toJson, fromJson
}
```

#### `CategoryModel` (`lib/features/category/domain/models/category_model.dart`)
```dart
enum CategoryType { income, expense }

class CategoryModel {
  final String id;
  final String name;          // Selalu terkapitalisasi rapi (Title Case)
  final CategoryType type;
  final String icon;          // wallet, store, utensils, car, shopping-cart, dll
  final int colorValue;

  String get color =>
      '#${(colorValue & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  static String capitalizeWords(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + (word.length > 1 ? word.substring(1) : '');
    }).join(' ');
  }

  static IconData getIconData(String iconName); // Resolver ke Material Icons
}
```

#### `TransactionModel` (`lib/features/transaction/domain/models/transaction_model.dart`)
```dart
enum TransactionType { income, expense, transfer }

class TransactionModel {
  final String id;
  final String bookId;
  final String? targetBookId; // Digunakan jika type == TransactionType.transfer
  final String title;         // Nama Kategori / Keterangan Transaksi
  final double amount;
  final TransactionType type;
  final String categoryId;
  final DateTime date;
  final String note;
  final bool isSynced;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;
  bool get isTransfer => type == TransactionType.transfer;
  DateTime get transactionDate => date;
  String get categoryName => title;

  // copyWith, toJson, fromJson
}
```

---

## 7. Dependensi Paket (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # Routing
  go_router: ^17.2.3

  # State Management
  flutter_bloc: ^9.1.1
  equatable: ^2.1.0

  # Typography & Charts
  google_fonts: ^8.1.0
  fl_chart: ^1.2.0

  # Formatting & Localization
  intl: ^0.20.2

  # File Management & Storage
  path_provider: ^2.1.5
  shared_preferences: ^2.5.5
  file_picker: ^9.0.1
  share_plus: ^12.0.2

  # Security & Biometrics
  flutter_secure_storage: ^10.3.4
  local_auth: ^3.0.1

  # Reporting & Export
  pdf: ^3.12.0
  printing: ^5.14.3
  excel: ^4.0.6

  # Google Sign-In & Drive Sync
  google_sign_in: 6.2.2
  googleapis: ^17.0.0
  extension_google_sign_in_as_googleapis_auth: 2.0.12
  http: ^1.6.0

  # Utilities & Icons
  uuid: ^4.6.0
  flutter_svg: ^2.3.0
  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

---

## 8. Panduan Verifikasi & Testing

Untuk memvalidasi keselarasan implementasi dengan spesifikasi ini:
1. **Verifikasi Sintaks & Linter**:
   ```bash
   flutter analyze
   ```
2. **Verifikasi Unit Test**:
   ```bash
   flutter test
   ```
3. **Uji Coba Alur Utama**:
   * Buka aplikasi pertama kali: pastikan Splash mengarahkan ke `/login`, tombol "Mulai" membuka `/create-initial-book`, dan setelah membuat buku langsung masuk `/home`.
   * Catat pemasukan dan pengeluaran: pastikan buku tidak perlu dipilih, tombol Simpan ada di AppBar, dan nominal terformat.
   * Cek Riwayat Transaksi: pastikan grouped by date, search berfungsi, dan quick add button bisa ditekan.
   * Cek Laporan: ganti tab periode (Bulan Ini, Bulan Lalu, Custom), amati grafik fl_chart, dan uji ekspor PDF/Excel.
   * Uji Tong Sampah: hapus transaksi dari detail, pastikan masuk ke `/trash`, pulihkan (restore), lalu uji hapus permanen.
   * Uji Keamanan: aktifkan kunci aplikasi di Akun, minimize aplikasi/tutup, buka kembali: pastikan `LockScreen` meminta sidik jari / PIN Android.
   * Uji Backup & Restore: lakukan backup via share sheet, lalu restore berkas backup via file picker.
