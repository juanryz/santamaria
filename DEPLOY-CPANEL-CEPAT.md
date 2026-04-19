# DEPLOYMENT CEPAT — cPanel PostgreSQL
## Santa Maria v1.40 → Online dalam 30-60 Menit

**Target**: Backend jalan di cPanel + APK Flutter install di HP.

**Asumsi**:
- cPanel 134 (Anda punya)
- PostgreSQL 40GB quota (Anda punya)
- Terminal access di cPanel (cek dulu — lihat STEP 0)

---

## STEP 0 — VERIFIKASI cPANEL (2 menit)

Login cPanel Anda, konfirmasi 3 hal:

### 0.1 — Terminal Access
- Scroll cPanel dashboard → section **"Advanced"**
- Cari icon **"Terminal"**
- Kalau **ADA**: ✅ deployment mudah, ikuti semua step
- Kalau **TIDAK ADA**: Anda perlu akses SSH (hubungi hosting support), atau kita pakai workaround Web Cron (saya bantu)

### 0.2 — PostgreSQL Aktif
- Section **"Databases"** → icon **"PostgreSQL Databases"**
- Kalau icon muncul: ✅ sudah aktif
- Kalau tidak: hubungi hosting support untuk aktifkan

### 0.3 — Domain Utama
- cPanel homepage → lihat bagian **"General Information"**
- Catat nilai **"Primary Domain"** → misal `yourname.com` atau `username.antillo.net`

---

## STEP 1 — BUAT SUBDOMAIN API (3 menit)

1. cPanel → **Domains** → **Subdomains**
2. Isi:
   - **Subdomain**: `api`
   - **Domain**: pilih domain utama Anda dari dropdown
   - **Document Root**: `public_html/api/public` ← PENTING, tambahkan `/public` di akhir
3. Klik **Create**
4. Catat URL final: `https://api.yourdomain.com`

> **Catatan**: Kita arahkan ke `/public` karena Laravel punya folder public sendiri yang jadi entry point (`index.php`). Tidak pakai `/public` = bisa tapi exposure file sensitif.

---

## STEP 2 — BUAT POSTGRESQL DATABASE (5 menit)

1. cPanel → **Databases** → **PostgreSQL Databases**

2. **Create New Database**:
   - Name: `santamaria_prod`
   - Click **Create Database**
   - → cPanel auto-prefix jadi `cpaneluser_santamaria_prod`
   - **CATAT** nama lengkapnya (termasuk prefix)

3. **Create New User**:
   - Username: `sm_user`
   - Password: klik **Password Generator** → copy password yang muncul
   - **SIMPAN password-nya di Notes** (tidak bisa dilihat lagi setelah ini!)
   - Click **Create User**
   - → cPanel auto-prefix username jadi `cpaneluser_sm_user`

4. **Add User to Database**:
   - Pilih user: `cpaneluser_sm_user`
   - Pilih database: `cpaneluser_santamaria_prod`
   - Privileges: **ALL**
   - Click **Make Changes**

5. Catat credentials:
   ```
   Host: localhost
   Port: 5432
   Database: cpaneluser_santamaria_prod
   Username: cpaneluser_sm_user
   Password: [yang tadi di-generate]
   ```

---

## STEP 3 — UPLOAD BACKEND KE cPANEL (10 menit)

### 3.1 — Zip Backend di Laptop

Buka Terminal Mac Anda:

```bash
cd /Users/juchr/Documents/GitHub/santamaria
zip -r santamaria-backend.zip backend \
  -x "backend/vendor/*" \
     "backend/node_modules/*" \
     "backend/storage/logs/*" \
     "backend/storage/framework/cache/*" \
     "backend/storage/framework/sessions/*" \
     "backend/storage/framework/views/*" \
     "backend/.env" \
     "backend/database/database.sqlite"
```

Hasil: file `santamaria-backend.zip` ~3-5 MB (tanpa vendor).

### 3.2 — Upload via cPanel File Manager

1. cPanel → **Files** → **File Manager**
2. Navigasi ke `public_html/api/` (folder subdomain yang kita buat tadi)
3. Klik **Upload** (atas) → pilih `santamaria-backend.zip`
4. Tunggu sampai 100%, kembali ke File Manager
5. Klik kanan file `santamaria-backend.zip` → **Extract**
6. Extract ke path yang sama (`public_html/api/`)
7. Setelah extract:
   - Isi folder `backend/` akan ada di `public_html/api/backend/`
   - Kita butuh file-file langsung di `public_html/api/`, bukan nested
8. Pindahkan: masuk ke folder `backend/` → Select All → Cut → naik 1 folder → Paste
9. Hapus folder `backend/` kosong yang tertinggal
10. Hapus `santamaria-backend.zip`

**Struktur akhir yang benar:**
```
public_html/api/
├── app/
├── bootstrap/
├── config/
├── database/
├── public/          ← Apache akan serve dari sini
├── resources/
├── routes/
├── storage/
├── composer.json
├── artisan
└── ... dll
```

---

## STEP 4 — SETUP .ENV VIA FILE MANAGER (5 menit)

1. File Manager → `public_html/api/`
2. Klik kanan `.env.example` → **Copy** → target name: `.env`
3. Klik kanan `.env` → **Edit**
4. Replace isinya dengan ini (ganti nilai `[XXX]` sesuai kepunyaan Anda):

```bash
APP_NAME="Santa Maria"
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=https://api.yourdomain.com          # GANTI dengan subdomain Anda
APP_TIMEZONE=Asia/Jakarta
APP_LOCALE=id

LOG_CHANNEL=stack
LOG_LEVEL=error

# ── DATABASE POSTGRESQL ──────────────────────────────────────
DB_CONNECTION=pgsql
DB_HOST=localhost
DB_PORT=5432
DB_DATABASE=cpaneluser_santamaria_prod      # GANTI sesuai Step 2
DB_USERNAME=cpaneluser_sm_user              # GANTI sesuai Step 2
DB_PASSWORD=[PASSWORD_YANG_TADI]            # GANTI sesuai Step 2

# ── FILESYSTEM (sementara pakai public, nanti ganti R2) ──────
FILESYSTEM_DISK=public

# ── SESSION & CACHE (pakai database driver karena no Redis) ──
SESSION_DRIVER=database
CACHE_STORE=database
QUEUE_CONNECTION=database

# ── MAIL (sementara kosong, setup Resend nanti) ──────────────
MAIL_MAILER=log

# ── CORS: izinkan APK Flutter akses ──────────────────────────
SANCTUM_STATEFUL_DOMAINS=api.yourdomain.com  # GANTI
```

5. Click **Save Changes**

---

## STEP 5 — INSTALL + MIGRATE VIA TERMINAL (10 menit)

### 5.1 — Buka Terminal cPanel

- cPanel → **Advanced** → **Terminal**
- Klik **Proceed** / **I understand**

### 5.2 — Install & Setup

Copy-paste command berikut **satu per satu**:

```bash
# 1. Navigate ke folder API
cd ~/public_html/api

# 2. Install PHP dependencies (5-10 menit, tunggu sampai selesai)
composer install --no-dev --optimize-autoloader

# 3. Generate APP_KEY
php artisan key:generate --force

# 4. Run migration (create semua table)
php artisan migrate --force

# 5. Seed test accounts
php artisan db:seed --force

# 6. Cache config untuk production
php artisan config:cache
php artisan route:cache
php artisan view:cache

# 7. Set permissions
chmod -R 755 storage bootstrap/cache
```

### 5.3 — Verifikasi

```bash
# Cek apakah migration sukses
php artisan migrate:status | head -20

# Cek apakah seed sukses (harus return 17)
php artisan tinker --execute="echo \App\Models\User::count();"
```

Kalau semua OK, lanjut STEP 6.

---

## STEP 6 — SETUP CRON SCHEDULER (2 menit)

cPanel → **Advanced** → **Cron Jobs**

Add cron:
- Schedule: `* * * * *` (every minute)
- Command (ganti `cpaneluser` dengan username cPanel Anda):
  ```
  cd /home/cpaneluser/public_html/api && php artisan schedule:run >> /dev/null 2>&1
  ```

Click **Add New Cron Job**.

Ini menjalankan semua scheduler (auto-complete order, reminder payment, check overdue, dll) setiap menit.

---

## STEP 7 — TEST DARI BROWSER (1 menit)

Buka browser HP atau laptop, akses:

```
https://api.yourdomain.com/api/v1/public/obituaries
```

**Expected response** (JSON):
```json
{"success":true,"data":[]}
```

**Kalau error**:
- `500 Server Error` → buka `storage/logs/laravel.log` via File Manager, kirim error ke saya
- `502/503` → PHP version mismatch, cPanel → PHP Selector → set ke **PHP 8.3**
- `404` → path subdomain salah, cek Document Root di STEP 1
- `Connection error` → `.env` DB credentials salah

---

## STEP 8 — BUILD FLUTTER APK (10 menit)

Di laptop Mac Anda:

```bash
cd /Users/juchr/Documents/GitHub/santamaria/frontend

# Clean build
flutter clean
flutter pub get

# Build APK dengan BASE_URL menuju cPanel online
flutter build apk --release \
  --dart-define=BASE_URL=https://api.yourdomain.com/api/v1

# APK final ada di:
# build/app/outputs/flutter-apk/app-release.apk
```

**Size APK**: ~50-80 MB.

---

## STEP 9 — INSTALL APK DI HP (3 menit)

### Opsi A — USB
1. Hubungkan HP ke laptop via USB
2. HP → Settings → **Developer Options** → USB Debugging ON
3. Di laptop:
   ```bash
   flutter install --release
   ```

### Opsi B — Transfer File
1. Copy `app-release.apk` ke Google Drive / WhatsApp / email
2. Download di HP
3. File Manager HP → tap APK → Install
4. Kalau muncul "Install Unknown Apps" → allow → install

---

## STEP 10 — TEST LOGIN MULTI-ROLE

Buka aplikasi di HP. Login pakai akun test:

| Role | Login | Password |
|------|-------|----------|
| Super Admin | `superadmin@santamaria.id` | `superadmin123` |
| Owner | `owner@santamaria.id` | `owner123` |
| SO Lapangan | `so@santamaria.id` | `so123456` |
| Gudang | `gudang@santamaria.id` | `gudang123` |
| Purchasing | `purchasing@santamaria.id` | `purchasing123` |
| Driver | `driver@santamaria.id` | `driver123` |
| Dekor | `dekor@santamaria.id` | `dekor123` |
| Tukang Foto | `foto@santamaria.id` | `foto1234` |
| HRD | `hrd@santamaria.id` | `hrd123456` |
| Consumer (HP login) | HP: `08199999999` | PIN: `1234` |

**Flow testing**:
1. Login SO → buat order baru → assign vendor → konfirmasi
2. Logout → login Gudang → lihat checklist
3. Logout → login Consumer → lihat order status
4. dst.

---

## TROUBLESHOOTING UMUM

### "Composer command not found"
cPanel Terminal kadang pakai PHP selector. Coba:
```bash
/opt/cpanel/ea-php83/root/usr/bin/php /usr/local/bin/composer install --no-dev
```

### Migration error: `gen_random_uuid() does not exist`
PostgreSQL extension `pgcrypto` belum aktif. Di Terminal:
```bash
psql -U cpaneluser_sm_user -d cpaneluser_santamaria_prod \
  -c "CREATE EXTENSION IF NOT EXISTS pgcrypto;"
```

Lalu jalankan `php artisan migrate:fresh --force --seed` ulang.

### APK tidak bisa konek ke backend
- Pastikan `APP_URL` di .env pakai **https://** bukan http
- cPanel → SSL/TLS → **Let's Encrypt** → pastikan SSL aktif untuk `api.yourdomain.com`
- Test lagi URL dari browser

### Android reject APK "untrusted"
Flutter APK release belum di-sign dengan keystore resmi. Untuk testing internal OK; untuk publish Play Store perlu setup keystore (nanti saja).

---

## EDITING KODE SETELAH DEPLOY

### Edit Backend (PHP)
1. Edit file di laptop (misal `app/Http/Controllers/...`)
2. Upload file yang berubah via File Manager (overwrite)
3. Kalau ada config berubah: Terminal → `php artisan config:clear && php artisan config:cache`
4. **APK tidak perlu dirubah**

### Edit Flutter (UI)
1. Edit file di laptop
2. Rebuild APK: `flutter build apk --release --dart-define=BASE_URL=https://api.yourdomain.com/api/v1`
3. Install APK baru di HP (uninstall lama dulu atau pakai `flutter install`)

### Tambah Migration Baru
1. Tulis migration file di laptop `database/migrations/`
2. Upload file ke cPanel
3. Terminal → `php artisan migrate --force`
4. **APK tidak perlu dirubah**

### Reset Database (kalau data testing jadi berantakan)
```bash
# HATI-HATI — hapus semua data!
php artisan migrate:fresh --force --seed
```

---

## NEXT STEPS (Setelah Test OK)

Setelah testing lancar, integrasikan:
1. **Cloudflare R2** — storage foto (lihat DEPLOYMENT-v1.40.md STEP 3)
2. **Firebase FCM** — push notification
3. **SSL certificate** — sudah auto kalau pakai Let's Encrypt cPanel
4. **Domain email** — Resend untuk email transaksional

Dokumen `DEPLOYMENT-v1.40.md` di root project ada panduan lengkap untuk setup integrasi ini.

---

## CHECKLIST CEPAT

Tandai yang sudah selesai:

- [ ] STEP 0 — cPanel terminal ada, PostgreSQL aktif, domain dicatat
- [ ] STEP 1 — Subdomain `api.yourdomain.com` dibuat
- [ ] STEP 2 — PostgreSQL database + user dibuat, credentials dicatat
- [ ] STEP 3 — Backend di-zip & upload ke cPanel
- [ ] STEP 4 — `.env` di-setup via File Manager
- [ ] STEP 5 — `composer install` + migrate + seed via Terminal sukses
- [ ] STEP 6 — Cron scheduler di-add
- [ ] STEP 7 — Browser test API → return JSON
- [ ] STEP 8 — APK build di laptop
- [ ] STEP 9 — APK install di HP
- [ ] STEP 10 — Login multi-role berhasil

---

*Kalau stuck di step manapun, screenshot error-nya, saya bantu debug.*
