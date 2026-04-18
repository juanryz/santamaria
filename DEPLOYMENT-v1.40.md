# DEPLOYMENT GUIDE v1.40
## Santa Maria Funeral Organizer — Backend + Frontend

**Tanggal**: 18 April 2026
**Versi Target**: v1.40

---

## ✅ Prerequisites

Anda sudah menyiapkan:
- [ ] Hosting cPanel dengan PostgreSQL support (✅ Anda sudah punya — 40GB disk, 2GB RAM)
- [ ] Domain + subdomain (misal `api.santamaria.id` untuk backend)
- [ ] Akun Cloudflare R2 (daftar gratis di cloudflare.com)
- [ ] Akun Firebase (gratis, untuk FCM push notification)
- [ ] Akun Supabase (gratis, untuk Realtime)
- [ ] Akun Resend (gratis, untuk email transaksional)
- [ ] Akun Sentry (gratis, untuk error monitoring)

---

## STEP 1 — Setup PostgreSQL di cPanel

### 1.1 Buat Database
1. Login ke cPanel Anda
2. Menu **PostgreSQL Databases**
3. Create database: `santamaria_prod` (atau nama lain)
4. Create user: `santamaria_user` + password kuat (simpan!)
5. Assign user ke database dengan **ALL PRIVILEGES**

### 1.2 Dapatkan Connection Info
Dari cPanel dashboard, catat:
```
Host: localhost (atau IP server)
Port: 5432
Database: cpaneluser_santamaria_prod  (biasanya ada prefix cpanel user)
Username: cpaneluser_santamaria_user
Password: [yang Anda set]
```

### 1.3 Enable Extension `pgcrypto`
Migration kita pakai `gen_random_uuid()` yang butuh extension ini.
Biasanya sudah enabled di cPanel Postgres. Kalau belum, hubungi admin hosting
atau jalankan via phpPgAdmin:
```sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;
```

---

## STEP 2 — Setup Laravel .env

### 2.1 Upload Backend
Upload folder `backend/` ke path cPanel Anda (biasanya `public_html/api/`
atau subdomain).

### 2.2 Configure .env
Copy `.env.example` ke `.env` lalu isi:

```bash
APP_NAME="Santa Maria"
APP_ENV=production
APP_KEY=                                    # isi via: php artisan key:generate
APP_DEBUG=false
APP_URL=https://api.santamaria.id           # ganti sesuai domain Anda

# PostgreSQL
DB_CONNECTION=pgsql
DB_HOST=localhost
DB_PORT=5432
DB_DATABASE=cpaneluser_santamaria_prod
DB_USERNAME=cpaneluser_santamaria_user
DB_PASSWORD=your_db_password

# Cloudflare R2 (step 3)
R2_ACCESS_KEY_ID=
R2_SECRET_ACCESS_KEY=
R2_BUCKET=santamaria-storage
R2_ENDPOINT=https://<account-id>.r2.cloudflarestorage.com
R2_PUBLIC_URL=https://<account-id>.r2.dev    # public URL bucket

# Firebase (step 4)
FCM_PROJECT_ID=
FCM_SERVICE_ACCOUNT_PATH=storage/app/firebase-service-account.json

# Supabase Realtime (step 5)
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=eyJ...
SUPABASE_REALTIME_URL=wss://xxx.supabase.co/realtime/v1

# Resend Email (step 6)
RESEND_API_KEY=re_xxx
MAIL_FROM_ADDRESS=noreply@santamaria.id
MAIL_FROM_NAME="Santa Maria"

# Sentry (step 7)
SENTRY_LARAVEL_DSN=https://xxx@sentry.io/xxx
SENTRY_TRACES_SAMPLE_RATE=0.1

# Queue (database driver karena cPanel no Redis)
QUEUE_CONNECTION=database
CACHE_STORE=database
SESSION_DRIVER=database

# Timezone
APP_TIMEZONE=Asia/Jakarta
```

### 2.3 Install Dependencies
Via SSH (kalau akses) atau cPanel Terminal:
```bash
cd /path/to/backend
composer install --no-dev --optimize-autoloader
php artisan key:generate
php artisan config:cache
php artisan route:cache
```

Kalau cPanel tidak support composer, upload `vendor/` folder lokal Anda
(pastikan `composer install` di lokal environment PHP 8.3 dulu).

---

## STEP 3 — Setup Cloudflare R2

### 3.1 Buat R2 Bucket
1. Login [dash.cloudflare.com](https://dash.cloudflare.com)
2. Menu **R2 Object Storage** → **Create Bucket**
3. Name: `santamaria-storage`
4. Location: Automatic

### 3.2 Generate API Token
1. R2 → **Manage R2 API Tokens** → **Create API Token**
2. Permissions: **Object Read & Write**
3. Bucket: `santamaria-storage` only
4. Copy:
   - **Access Key ID**
   - **Secret Access Key**
   - **Endpoint URL** (format `https://<account-id>.r2.cloudflarestorage.com`)
5. Paste ke `.env` (step 2.2)

### 3.3 Install Laravel R2 Adapter
R2 pakai S3 protocol. Install flysystem S3:
```bash
composer require league/flysystem-aws-s3-v3 --with-all-dependencies
```

### 3.4 Configure `config/filesystems.php`
Tambahkan disk `r2`:
```php
'r2' => [
    'driver' => 's3',
    'key' => env('R2_ACCESS_KEY_ID'),
    'secret' => env('R2_SECRET_ACCESS_KEY'),
    'region' => 'auto',
    'bucket' => env('R2_BUCKET'),
    'endpoint' => env('R2_ENDPOINT'),
    'use_path_style_endpoint' => true,
    'url' => env('R2_PUBLIC_URL'),
    'throw' => true,
],
```

### 3.5 Test Upload
```bash
php artisan tinker
>>> Storage::disk('r2')->put('test.txt', 'hello');
>>> Storage::disk('r2')->exists('test.txt');
// harus true
>>> Storage::disk('r2')->delete('test.txt');
```

---

## STEP 4 — Jalankan Migration

### 4.1 Verifikasi Koneksi
```bash
php artisan migrate:status
```
Kalau muncul error `connection refused` → cek DB_HOST, DB_PORT, firewall cPanel.

### 4.2 Jalankan Migration
```bash
php artisan migrate --force
```

Expected output: ratusan migration dijalankan. Estimasi waktu: 30-60 detik.

**Jika error**:
- `SQLSTATE[42883]: Undefined function: gen_random_uuid()` → aktifkan extension `pgcrypto` (step 1.3)
- `SQLSTATE[42P07]: duplicate_table` → database sudah pernah di-migrate, pakai `php artisan migrate:fresh --force` (⚠️ hapus semua data!)
- `Foreign key constraint doesn't exist` → urutan migration salah. Jalankan `php artisan migrate:rollback` lalu `migrate` lagi.

### 4.3 Seed Data
```bash
php artisan db:seed --force
```
Ini buat:
- User test (semua role — **WAJIB ganti password di production!**)
- Package test (Silver, Gold, Platinum)
- Stock items + Add-ons
- System thresholds + master data
- v1.40 seeder: musician wage configs (placeholder rate), system thresholds

---

## STEP 5 — Setup Firebase FCM

### 5.1 Buat Firebase Project
1. [console.firebase.google.com](https://console.firebase.google.com) → **Add project**
2. Project name: `santamaria-app`
3. Disable Google Analytics (optional)

### 5.2 Download Service Account
1. Project Settings → **Service accounts** → **Generate new private key**
2. Download JSON file
3. Upload ke server: `storage/app/firebase-service-account.json`
4. Set permission: `chmod 640 storage/app/firebase-service-account.json`

### 5.3 Setup Android App
1. Firebase → Add App → Android
2. Package name: `com.santamaria.app` (atau sesuai `frontend/android/app/build.gradle`)
3. Download `google-services.json`
4. Simpan ke `frontend/android/app/google-services.json`

### 5.4 Install Firebase Admin SDK (Backend)
```bash
composer require kreait/firebase-php
```

### 5.5 Test
Login ke aplikasi, cek apakah FCM token tersimpan di `users.fcm_token`.

---

## STEP 6 — Setup Supabase Realtime

### 6.1 Buat Supabase Project
1. [supabase.com](https://supabase.com) → **New Project**
2. Name: `santamaria-realtime`
3. Region: **Southeast Asia (Singapore)** untuk latensi rendah ke Indonesia

### 6.2 Ambil Credentials
Project Settings → API:
- **URL**: `https://xxx.supabase.co`
- **anon public key**: `eyJhbGc...`

Paste ke `.env` (step 2.2).

### 6.3 Hanya Pakai Realtime, Tidak DB/Auth
Kita tidak pakai database Supabase. Cukup Realtime broadcast.

Di Flutter `pubspec.yaml`:
```yaml
supabase_flutter: ^2.5.0
```

Di `main.dart`:
```dart
await Supabase.initialize(
  url: 'https://xxx.supabase.co',
  anonKey: 'eyJhbGc...',
);
```

---

## STEP 7 — Setup Resend Email

### 7.1 Daftar Resend
1. [resend.com](https://resend.com) → Sign up
2. Verify domain Anda (misal `santamaria.id`) dengan DNS records
3. Generate API key di Dashboard → API Keys

### 7.2 Install
```bash
composer require resend/resend-laravel
```

### 7.3 Configure Mail
Di `config/mail.php`:
```php
'default' => env('MAIL_MAILER', 'resend'),
'mailers' => [
    'resend' => ['transport' => 'resend'],
],
```

### 7.4 Test
```bash
php artisan tinker
>>> Mail::raw('Test', fn($m) => $m->to('you@example.com')->subject('Test'));
```

---

## STEP 8 — Setup Sentry (Error Monitoring)

### 8.1 Daftar Sentry
1. [sentry.io](https://sentry.io) → Create project (PHP/Laravel)
2. Copy DSN

### 8.2 Install
```bash
composer require sentry/sentry-laravel
```

### 8.3 Configure
`config/logging.php`:
```php
'channels' => [
    'sentry' => [
        'driver' => 'sentry',
        'level' => 'error',
    ],
],
```

`.env`:
```
SENTRY_LARAVEL_DSN=https://xxx@sentry.io/xxx
```

### 8.4 Test
```bash
php artisan sentry:test
```

---

## STEP 9 — Setup Cron Scheduler

### 9.1 Via cPanel Cron Jobs
1. cPanel → **Cron Jobs**
2. Add cron:
   - Schedule: `* * * * *` (setiap menit)
   - Command: `cd /path/to/backend && php artisan schedule:run >> /dev/null 2>&1`

### 9.2 Verifikasi Scheduler
```bash
php artisan schedule:list
```
Harus muncul 20+ schedulers, termasuk v1.40:
- `consumer-payment:send-reminders` (daily 09:00)
- `death-cert:check-overdue` (daily 09:30)
- `stock:opname-reminder` (Jan/Jul 1)
- `membership:check-payment-status` (daily 06:00)
- `auto-complete-by-time` (every 5 min)
- `check-late-processing` (every 5 min)
- dan lainnya

### 9.3 Queue Worker (Database Driver)
Karena cPanel tidak support daemon, pakai cron untuk jalankan queue batch:
Add cron:
- Schedule: `* * * * *`
- Command: `cd /path/to/backend && php artisan queue:work --stop-when-empty --max-time=55 >> /dev/null 2>&1`

---

## STEP 10 — Build & Deploy Flutter

### 10.1 Build APK
```bash
cd frontend
flutter build apk --release
```

### 10.2 Test Di HP Kantor
Install APK ke HP kantor. Pastikan:
- Login bekerja (pakai akun seed)
- Navigation ke semua screen v1.40 bekerja:
  - Finance Dashboard → Reminder Pembayaran (v1.40)
  - SO Order Detail → Sesi Musisi (v1.40)
  - SO Order Detail → Tim Vendor (v1.40)
  - SO Order Detail → Transport Luar Kota (v1.39)
  - SO Order Detail → Layanan Custom (v1.40)

### 10.3 Distribusi ke Karyawan
Upload APK ke cloud storage (Google Drive / Firebase App Distribution)
atau pakai internal APK distribution tool.

---

## VERIFIKASI POST-DEPLOYMENT

### Test Checklist
- [ ] Login SO → buat order baru
- [ ] Order dikonfirmasi → stock deducted + SAL signed + shifts tukang_jaga auto-generated
- [ ] Checklist otomatis ke Gudang + Dekor (sesuai provider_role)
- [ ] Driver dapat assignment
- [ ] Consumer upload bukti bayar
- [ ] Finance verify → order status = paid
- [ ] Petugas Akta track progress akta
- [ ] Owner dashboard lihat semua real-time

### Monitor Storage Growth
```bash
# Cek size R2 bucket
aws s3 ls s3://santamaria-storage --endpoint=$R2_ENDPOINT --recursive --human-readable --summarize
```

---

## TROUBLESHOOTING UMUM

### Error: `gen_random_uuid() does not exist`
```sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;
```

### Error: `could not find driver (pgsql)`
Hosting Anda belum aktifkan php-pgsql extension. Hubungi support cPanel.

### Migration stuck / timeout
Naikkan max_execution_time di cPanel PHP Selector atau lewati migration besar:
```bash
php artisan migrate --step
```

### Queue tidak jalan
Cek log `storage/logs/laravel.log`. Pastikan cron queue berjalan (step 9.3).

### Foto tidak bisa upload
1. Cek credentials R2 (.env)
2. Test manual:
```bash
php artisan tinker
>>> Storage::disk('r2')->put('test.txt', 'hello');
```

### Push notification tidak sampai
1. Cek `firebase-service-account.json` ter-upload
2. Cek FCM token tersimpan di user: `SELECT fcm_token FROM users WHERE id = 'xxx'`
3. Test manual via Firebase Console → Cloud Messaging → Send test message

### Email tidak terkirim
1. Verify domain di Resend (DNS records: DKIM, SPF, DMARC)
2. Cek `storage/logs/laravel.log` untuk error message

---

## ROLLBACK PROCEDURE

Kalau v1.40 bermasalah di production:

### Rollback migration (hati-hati, akan hapus data v1.40)
```bash
# Rollback 8 migration terakhir (v1.40)
php artisan migrate:rollback --step=8 --force
```

### Full rollback ke versi sebelum v1.40
```bash
# Backup dulu!
pg_dump -U user -d santamaria_prod > backup.sql

# Rollback semua
php artisan migrate:rollback --force

# Restore jika perlu
psql -U user -d santamaria_prod < backup.sql
```

---

## STORAGE MONITORING

Setelah go-live, monitor R2 usage bulanan:
- Bulan 1: ~12 GB (free tier 10 GB → mulai bayar ~Rp 5.000)
- Bulan 6: ~72 GB (~Rp 25.000/bulan)
- Tahun 1: ~144 GB (~Rp 32.000/bulan)

Cek di Cloudflare Dashboard → R2 → Usage.

---

## KONTAK SUPPORT

- **Cloudflare**: [support.cloudflare.com](https://support.cloudflare.com)
- **Firebase**: [firebase.google.com/support](https://firebase.google.com/support)
- **Supabase**: [supabase.com/support](https://supabase.com/support)
- **Resend**: support@resend.com
- **Sentry**: [sentry.io/support](https://sentry.io/support)

---

## CHANGELOG v1.40

Sesi 18 April 2026:
- **Koreksi**: pemuka_agama internal dihapus, fee=0 enforcement
- **Baru**: photographer daily wages, stock opname 6-bulanan, layanan custom (multi rumah duka), musisi per sesi
- **Tabel baru**: 10 (photographer_daily_wages, stock_opname_sessions, stock_opname_items, order_location_phases, musician_wage_config, order_musician_sessions, stock_inter_location_transfers, consumer_payment_reminders, order_death_cert_progress, death_cert_stage_logs, coffin_size_master, location_presence_logs)
- **Migration count**: +8 files untuk v1.40
- **Controller baru**: 3 (PhotographerWage, ConsumerPaymentReminder, OrderVendorAssignment)
- **Flutter screen baru**: 3 (payment_reminder, musician_sessions, vendor_assignment)

---

*Dokumen ini akan diupdate saat ada perubahan deployment procedure.*
