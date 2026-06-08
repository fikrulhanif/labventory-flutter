# Labventory

Sistem peminjaman inventaris laboratorium kampus. Dibangun sebagai solusi mobile-first yang komprehensif dengan backend Laravel REST API dan frontend Flutter mobile.

## Gambaran Umum

Labventory menyederhanakan proses peminjaman peralatan laboratorium dengan menyediakan aplikasi mobile untuk mahasiswa mengajukan permintaan dan interface web serta mobile untuk administrator mengelola seluruh siklus peminjaman.

**Fitur Utama:**

- Aplikasi mobile mahasiswa untuk browsing dan mengajukan permintaan peralatan
- Dashboard web admin untuk manajemen inventaris komprehensif
- Interface mobile admin untuk workflow serah-terima peralatan berbasis QR
- Sistem notifikasi real-time
- Generasi laporan PDF
- Manajemen stok otomatis dengan transaction locking

## Arsitektur

### Tech Stack

**Backend (Laravel 13)**

- PHP 8.3
- Laravel Framework 13.7
- Laravel Sanctum (autentikasi API)
- MySQL database
- DomPDF (laporan PDF)
- Endroid QR Code (generasi QR)

**Frontend (Flutter)**

- Flutter SDK 3.11.4+
- Dart 3.11.4+
- Provider (state management)
- Dio (HTTP client)
- Google Fonts
- Mobile Scanner
- QR Flutter

### Struktur Project

```
Labventory/
├── backend/          # Laravel REST API + Web Dashboard
│   ├── app/
│   │   ├── Http/
│   │   │   ├── Controllers/Api/        # Endpoint API mobile
│   │   │   └── Controllers/Web/        # Dashboard web admin
│   │   ├── Models/
│   │   ├── Services/                   # Business logic layer
│   │   ├── Policies/                   # Aturan otorisasi
│   │   └── Exceptions/                 # Custom exceptions
│   ├── database/
│   │   ├── migrations/
│   │   └── factories/
│   └── routes/
│       ├── api.php                     # Route API
│       └── web.php                     # Route dashboard web
│
└── frontend/         # Aplikasi Mobile Flutter
    └── lib/
        ├── models/                     # Model data
        ├── services/                   # Service API
        ├── providers/                  # State management
        ├── screens/                    # Layar UI
        ├── widgets/                    # Komponen reusable
        ├── routes/                     # Navigasi
        ├── constants/                  # Konstanta aplikasi
        └── utils/                      # Utilitas
```

## Role Sistem

### Mahasiswa (Aplikasi Mobile)

- Register dan autentikasi menggunakan NIM
- Browse peralatan laboratorium yang tersedia
- Cari dan filter inventaris berdasarkan kategori
- Lihat informasi detail peralatan
- Ajukan permintaan peminjaman dengan upload foto KTM
- Tracking status peminjaman secara real-time
- Lihat riwayat peminjaman
- Terima notifikasi in-app
- Update informasi profil

### Administrator (Dashboard Web + Aplikasi Mobile)

**Dashboard Web:**

- Kelola inventaris (operasi CRUD)
- Kelola kategori
- Kelola akun user mahasiswa
- Lihat dan proses permintaan peminjaman
- Approve/reject permintaan peminjaman
- Lihat dokumen KTM yang diupload
- Generate laporan PDF
- Lihat statistik dan analitik sistem

**Aplikasi Mobile:**

- Scan QR code untuk identifikasi peralatan
- Proses serah terima peralatan (pickup)
- Proses pengembalian peralatan
- Lihat peminjaman aktif untuk peralatan tertentu
- Update status real-time

## Alur Peminjaman

Proses peminjaman mengikuti state machine terstruktur dengan manajemen stok yang proper:

```
1. pending    → Mahasiswa mengajukan permintaan peminjaman
2. approved   → Admin menyetujui permintaan (stok tidak berubah)
3. borrowed   → Mahasiswa mengambil peralatan (stok berkurang)
4. returned   → Mahasiswa mengembalikan peralatan (stok kembali)

Alternatif: rejected → Admin menolak permintaan
```

**Aturan Penting Manajemen Stok:**

- Stok TIDAK berkurang saat approval
- Stok hanya berkurang ketika peralatan benar-benar diserahkan (status borrowed)
- Stok kembali ketika peralatan dikembalikan secara fisik
- Semua operasi stok menggunakan database row-level locking untuk mencegah race condition
- Beberapa mahasiswa tidak dapat melebihi stok yang tersedia melalui pengajuan bersamaan

## Skema Database

### Tabel Utama

**users**

- Autentikasi user dan informasi profil
- Role: `student`, `admin`, `laboran`
- Manajemen status akun

**categories**

- Kategorisasi peralatan
- Siap untuk organisasi hierarki

**inventories**

- Katalog peralatan
- Tracking stok
- Asosiasi QR code
- Penyimpanan gambar
- Status: `available`, `out_of_stock`

**loans**

- Record peminjaman
- State machine status
- Timestamp untuk pickup dan return
- Penyimpanan dokumen KTM
- Validasi rentang tanggal

**loan_status_history**

- Audit trail untuk semua transisi status
- Tracking aktor
- Catatan/alasan transisi

**app_notifications**

- Sistem notifikasi in-app
- Status read/unread
- Notifikasi spesifik per user

**failed_logins**

- Tracking keamanan
- Monitor percobaan login

## Arsitektur API

### Autentikasi

Semua route API kecuali registrasi dan login memerlukan autentikasi token Sanctum.

**Endpoint:**

- `POST /api/auth/register` - Registrasi mahasiswa
- `POST /api/auth/login` - Login berbasis token
- `POST /api/auth/logout` - Revoke token
- `GET /api/auth/me` - Profil user saat ini
- `PATCH /api/auth/profile` - Update profil (mahasiswa saja)

### Manajemen Inventaris

- `GET /api/inventories` - List dengan paginasi, search, dan filter
- `GET /api/inventories/{id}` - Informasi detail peralatan

### Manajemen Peminjaman

**Operasi Mahasiswa:**

- `GET /api/loans` - Riwayat peminjaman pribadi
- `POST /api/loans` - Ajukan permintaan baru
- `GET /api/loans/{id}` - Detail peminjaman
- `DELETE /api/loans/{id}` - Batalkan permintaan pending
- `GET /api/loans/{id}/document` - Stream dokumen KTM

**Operasi Admin:**

- `GET /api/admin/inventories/{code}` - Lookup peralatan via QR code
- `GET /api/admin/inventories/{code}/loans` - Peminjaman aktif untuk peralatan
- `POST /api/admin/loans/{id}/handover` - Proses pengambilan peralatan
- `POST /api/admin/loans/{id}/return` - Proses pengembalian peralatan

### Notifikasi

- `GET /api/notifications` - List notifikasi user
- `GET /api/notifications/unread-count` - Jumlah unread
- `POST /api/notifications/read-all` - Tandai semua sebagai dibaca
- `POST /api/notifications/{id}/read` - Tandai spesifik sebagai dibaca

## Fitur Keamanan

- Autentikasi berbasis token via Laravel Sanctum
- Role-based access control (RBAC) dengan custom middleware
- Verifikasi akun mahasiswa sebelum pengambilan peralatan
- Validasi dokumen KTM
- Isolasi transaksi database untuk operasi stok
- Row-level locking untuk mencegah konflik stok bersamaan
- Tracking percobaan login gagal
- Manajemen status akun (active/disabled)
- Penyimpanan file aman untuk dokumen KTM

## Instalasi

### Prasyarat

**Backend:**

- PHP 8.3 atau lebih tinggi
- Composer 2.x
- MySQL 8.0 atau lebih tinggi
- Node.js dan npm (untuk kompilasi asset)

**Frontend:**

- Flutter SDK 3.11.4+
- Android SDK (untuk deployment Android)
- Xcode (untuk deployment iOS, khusus macOS)

### Setup Backend

1. Navigasi ke direktori backend:

```bash
cd backend
```

2. Install dependensi:

```bash
composer install
```

3. Konfigurasi environment:

```bash
cp .env.example .env
```

4. Edit file `.env` dengan kredensial database Anda:

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_labventory
DB_USERNAME=root
DB_PASSWORD=your_password
```

5. Generate application key:

```bash
php artisan key:generate
```

6. Jalankan migrasi:

```bash
php artisan migrate
```

7. Seed data awal (opsional):

```bash
php artisan db:seed
```

8. Buat storage link:

```bash
php artisan storage:link
```

9. Jalankan development server:

```bash
php artisan serve
```

API akan tersedia di `http://localhost:8000`

### Setup Frontend

1. Navigasi ke direktori frontend:

```bash
cd frontend
```

2. Install dependensi:

```bash
flutter pub get
```

3. Konfigurasi endpoint API di `lib/constants/app_config.dart`:

```dart
static const String baseUrl = 'http://url-api-anda/api';
```

4. Jalankan aplikasi:

```bash
flutter run
```

Untuk production build:

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## Development

### Command Development Backend

```bash
# Jalankan development server dengan hot reload
composer dev

# Jalankan tes
composer test

# Format code (Laravel Pint)
./vendor/bin/pint

# Hapus cache
php artisan config:clear
php artisan cache:clear
php artisan route:clear
```

### Development Frontend

```bash
# Jalankan dengan hot reload
flutter run

# Jalankan tes
flutter test

# Generate launcher icons
flutter pub run flutter_launcher_icons

# Build untuk production
flutter build apk --release
```

## Format Response API

Semua response API mengikuti struktur JSON yang konsisten:

**Response Sukses:**

```json
{
  "success": true,
  "message": "Operasi berhasil",
  "data": { ... }
}
```

**Response Error:**

```json
{
  "success": false,
  "message": "Deskripsi error",
  "errors": { ... }
}
```

**Response dengan Paginasi:**

```json
{
  "success": true,
  "data": [ ... ],
  "meta": {
    "current_page": 1,
    "last_page": 5,
    "per_page": 15,
    "total": 73
  }
}
```

## Sistem QR Code

QR code digenerate untuk setiap item inventaris yang berisi kode peralatan (contoh: `INV-001`).

**Penggunaan:**

- Admin scan QR code untuk identifikasi peralatan dengan cepat
- Sistem mencari peminjaman aktif untuk peralatan tersebut
- Memfasilitasi proses serah terima dan pengembalian yang cepat
- QR code disimpan sebagai gambar PNG di public storage

**Catatan:** Fungsi QR code eksklusif untuk staff administratif. Mahasiswa tidak berinteraksi dengan QR code.

## Sistem Notifikasi

Notifikasi in-app menjaga user tetap terinformasi tentang perubahan status peminjaman:

**Notifikasi Mahasiswa:**

- Permintaan peminjaman diterima
- Peminjaman disetujui
- Peminjaman ditolak (dengan alasan)
- Peralatan siap diambil
- Pengingat pengembalian

**Notifikasi Admin:**

- Permintaan peminjaman baru
- Approval yang pending
- Pengembalian terlambat

Semua notifikasi disimpan di database dan dapat diakses via API.

## Testing

### Tes Backend

```bash
# Jalankan semua tes
php artisan test

# Jalankan test suite spesifik
php artisan test --testsuite=Feature

# Jalankan dengan coverage
php artisan test --coverage
```

### Tes Frontend

```bash
# Jalankan semua tes
flutter test

# Jalankan dengan coverage
flutter test --coverage
```

## Pertimbangan Deployment

### Checklist Production Backend

- [ ] Set `APP_ENV=production` di `.env`
- [ ] Set `APP_DEBUG=false` di `.env`
- [ ] Konfigurasi kredensial database yang proper
- [ ] Jalankan `php artisan config:cache`
- [ ] Jalankan `php artisan route:cache`
- [ ] Jalankan `php artisan view:cache`
- [ ] Setup file permissions yang proper untuk storage
- [ ] Konfigurasi web server (Apache/Nginx)
- [ ] Setup SSL certificate
- [ ] Konfigurasi strategi backup

### Checklist Production Frontend

- [ ] Update API base URL ke production server
- [ ] Build versi release
- [ ] Generate signed APK/AAB untuk Android
- [ ] Konfigurasi iOS certificate untuk App Store
- [ ] Tes di physical devices
- [ ] Optimasi gambar dan asset
- [ ] Enable ProGuard/R8 untuk Android

## Kontribusi

Ini adalah project universitas untuk tugas kuliah Mobile Development. Codebase memprioritaskan:

- Clean, maintainable code
- Pemodelan workflow kampus yang realistis
- Pattern production-ready tanpa over-engineering
- Separation of concerns yang proper
- Dokumentasi komprehensif

## Lisensi

Project ini dikembangkan sebagai tugas kuliah akademik dan tidak dilisensikan untuk penggunaan komersial.

## Dukungan

Untuk masalah teknis atau pertanyaan terkait project ini, silakan merujuk ke dokumentasi di direktori `/docs` atau hubungi tim development.

---

**Dikembangkan sebagai bagian dari tugas kuliah Mobile Development**
