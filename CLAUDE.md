# SANTA MARIA FUNERAL ORGANIZER — MASTER VIBE CODING PROMPT
# Version 1.39 | Complete System Specification for AI-Assisted Development

---

## INSTRUKSI UNTUK AI CODING TOOL

Kamu adalah senior full-stack developer yang membangun aplikasi manajemen operasional untuk Santa Maria Funeral Organizer. Baca seluruh prompt ini sebelum menulis satu baris kode pun. Ikuti setiap spesifikasi secara eksak. Jangan mengasumsikan hal yang tidak tertulis — jika ada ambiguitas, tanyakan sebelum mengimplementasikan.

> Setiap kali melakukan perubahan kode, perbarui `readme.md` dengan ringkasan perubahan terbaru.
> 🚫 **ATURAN NO HARD CODE:** Sangat dilarang keras melakukan *hard code* nilai apapun (status order, toleransi waktu, limitasi, ID spesifik). Segala parameter batas waktu (timeout, deadline) harus merujuk ke parameter dinamis di tabel `system_thresholds`. Seluruh status harus bergantung pada Enum database, dan tidak ada business logic yang di-*hard code* di frontend tanpa landasan spesifikasi API database.

---

## 1. KONTEKS PROYEK

**Nama Produk:** Santa Maria — Aplikasi Manajemen Operasional Funeral Organizer
**Platform:** Android (Flutter), dengan backend Laravel REST API
**AI Engine:** OpenAI GPT-4o mini
**Database:** PostgreSQL 16
**Tujuan:** Menggantikan seluruh koordinasi manual berbasis WhatsApp dengan satu platform terpadu yang memiliki 12 role aktif + 1 Super Admin + 1 Supplier (eksternal) + 1 Consumer (eksternal), 14 titik integrasi AI, GPS tracking driver real-time, dan sistem e-Katalog Supplier.

**Prinsip Utama:**
- Satu Order Object = satu sumber kebenaran. Tidak ada data yang diinput dua kali.
- Human approval tetap ada di setiap step penting (owner requirement).
- AI bekerja di latar belakang sebagai asisten, bukan pengambil keputusan final.
- Driver selalu dapat dilacak sepanjang hari saat berstatus On Duty.
- Semua notifikasi order baru menggunakan alarm suara keras (bypass do-not-disturb).
- e-Katalog Supplier: sistem pengadaan terbuka seperti e-Katalog LKPP pemerintah — Gudang posting kebutuhan, semua supplier terdaftar berlomba ajukan penawaran, Gudang pilih terbaik.

---

## 2. TECH STACK LENGKAP

### Backend
- **Framework:** Laravel 11 (PHP 8.3)
- **Database:** PostgreSQL 16
- **Auth:** Laravel Sanctum (token-based)
- **Real-time:** Laravel Broadcasting + Pusher Channels
- **Queue:** Laravel Queue dengan Redis driver
- **Scheduler:** Laravel Task Scheduling (cron)
- **Storage:** Cloudflare R2 via AWS S3 SDK (S3-compatible)
- **AI:** OpenAI PHP SDK (openai-php/client)
- **HTTP Client:** Guzzle (sudah include di Laravel)
- **PDF Generation:** barryvdh/laravel-dompdf
- **Maps/Geocoding:** Google Maps Geocoding API (dari backend)

### Frontend (Flutter)
- **Flutter SDK:** 3.x (stable channel)
- **State Management:** Riverpod 2.x
- **HTTP Client:** Dio
- **Real-time:** pusher_channels_flutter
- **Maps:** google_maps_flutter
- **GPS:** geolocator + permission_handler
- **Geofence:** geofence_service
- **Push Notification:** firebase_messaging + flutter_local_notifications
- **Storage:** flutter_secure_storage (untuk token)
- **Audio:** audioplayers (untuk custom alarm sound)
- **Image:** image_picker + cached_network_image
- **Audio Record:** record (untuk voice note)
- **File:** dio + open_file

### External Services
- **Push Notification:** Firebase Cloud Messaging (FCM)
- **Maps:** Google Maps SDK (Android)
- **AI:** OpenAI API (GPT-4o mini + Web Search Tool)
- **Real-time:** Pusher Channels
- **Storage:** Cloudflare R2

---

# SANTA MARIA — PATCH v1.8
# Perubahan: Hilangkan Admin, Purchasing, Full Automation, Alarm Semua Pihak

---

## PERUBAHAN FUNDAMENTAL v1.8

### Prinsip Baru Owner
> "Setiap hal yang bisa diotomasi tanpa approval manusia, HARUS diotomasi."
> "Alarm bunyi keras dan memaksa ke SEMUA user yang perlu konfirmasi saat order masuk."

### Dampak Perubahan
1. **Admin dihapus** — seluruh tugasnya diotomasi sistem
2. **Purchasing** — fokus ke pengadaan & payment
3. **Alur order menjadi full-auto** — SO konfirmasi → sistem langsung distribute ke semua tanpa approval manusia
4. **Alarm simultaneous** — saat order dikonfirmasi SO, semua pihak (Gudang, Purchasing, Driver, Dekor, Konsumsi, Pemuka Agama) mendapat alarm keras bersamaan
5. **Driver assignment** — AI auto-assign driver terbaik, tanpa manual selection
6. **Order auto-complete** — saat semua pihak update "Selesai", order selesai otomatis

---

# SANTA MARIA — PATCH v1.10
# Purchasing, SO Multi-Channel, HRD kembali untuk pelanggaran

---

## 3. STRUKTUR ROLE FINAL v1.10

### 12 Role Aktif + 1 Super Admin + 1 Supplier (Eksternal) + 1 Consumer (Eksternal)

| Role ID | Nama Role | Tipe | Fungsi Utama |
|---------|-----------|------|-------------|
| super_admin | Super Admin | Sistem | Manajemen akun & konfigurasi sistem |
| consumer | Konsumen | Eksternal | Input order, tracking, upload bukti payment |
| service_officer | Service Officer | Internal | Sales lapangan & SO kantor (multi-channel) |
| gudang | Gudang | Internal | Stok, checklist, PO ke supplier |
| purchasing | Purchasing | Internal | Pengadaan, verifikasi payment, bayar supplier, upah tim lapangan |
| driver | Driver | Internal | Transport jenazah, GPS, bukti lapangan |
| dekor | Laviore / Dekor | Vendor | Dekorasi, konfirmasi, bukti foto |
| konsumsi | Konsumsi | Vendor | Katering, konfirmasi, bukti |
| pemuka_agama | Pemuka Agama | Vendor | Koordinasi layanan keagamaan, konfirmasi hadir |
| supplier | Supplier | Vendor | e-Katalog: lihat & ajukan penawaran |
| owner | Owner / Direktur | Eksekutif | Monitor semua, konfigurasi, laporan |
| hrd | HRD | Internal | Terima alarm pelanggaran, catat & tindak lanjut |
| security | Security | Internal | Monitoring keamanan, laporan kehadiran |
| viewer | Viewer | Eksternal | Read-only: lihat laporan & status order (tanpa aksi) |

### Perubahan dari v1.9

| Role | Status | Detail |
|------|--------|--------|
| Purchasing | **AKTIF** | Purchasing = verifikasi payment konsumen + bayar supplier + upah tim lapangan + pengadaan |
| HRD | **KEMBALI AKTIF** | HRD menerima ALARM jika ada yang melebihi ketentuan (terlambat, absen, pelanggaran) |
| Service Officer | **DIPERLUAS** | Tambah konsep SO Lapangan vs SO Kantor via `so_channel` field |

---

# SANTA MARIA — PATCH v1.12
# Manajemen Armada (Vehicle Management), Otomatisasi PO & Deep Link WA, Refinasi Status Payment

---

## PERUBAHAN & PENAMBAHAN FITUR v1.12

### 1. Sistem Manajemen Kendaraan (Vehicle Management System)
Sistem penugasan armada kini dibuat lebih robust:
- **Package-Based Vehicle Assignment:** Pemilihan kendaraan kini terikat pada paket pesanan yang dikonfirmasi oleh Service Officer.
- **Automated Fallback:** Jika kendaraan utama tidak tersedia (sedang bertugas/rusak), sistem secara otomatis mengalihkan ke kendaraan alternatif yang memiliki spesifikasi setara tanpa perlu intervensi manual.
- **Pengadaan Kendaraan Eksternal (Supplier):** Jika seluruh armada internal tidak tersedia, sistem mengizinkan proses "*request external vehicle*".
  - Proses ini akan **otomatis membuat permintaan persetujuan (approval) ke Purchasing**.
  - Setelah di-approve Purchasing, Supplier kendaraan akan mendapatkan **notifikasi otomatis** untuk penugasan.

### 2. Otomatisasi Gudang & Service Officer (SO)
- **Order Confirmation SO:** Logika konfirmasi pesanan oleh SO diperhalus. Saat operasi gagal, sistem sekarang memberikan umpan balik (feedback) error yang eksplisit sehingga SO selalu mengetahui status pastinya.
- **Auto-Generated Procurement (PO):** Saat memproses ketersediaan barang kebutuhan, *procurement request* (permintaan pengadaan e-Katalog) yang ter-generate otomatis oleh sistem kini **secara akurat diasosiasikan dengan user Gudang yang valid**. Hal ini mencegah error *constraint* pada database.
- **WhatsApp Deep Links:** Tombol-tombol kontak manual telah dihapus dan digantikan dengan *Automated Deep Links* ke WhatsApp. Hal ini meningkatkan kecepatan dan efisiensi komunikasi langsung antar tim maupun dengan vendor.

### 3. Pembaruan Skema Database — Payment Status
- Kolom enum `payment_status` pada struktur *orders* telah diperbarui. Nilai yang didukung sebelumnya kini ditambahkan status:
  - `proof_uploaded` : Otomatis terset ketika konsumen berhasil mengunggah bukti pembayaran via aplikasi (konsumen tidak perlu menunggu Purchasing merespons sebelum status terupdate di sisi konsumen).
  - `proof_rejected` : Digunakan ketika Purchasing menolak bukti pembayaran konsumen (tidak valid / blur), memungkinkan consumer app merespons dengan menampilkan form re-upload yang disertai alasan.
- Hal ini mengurangi bypass pengecekan manual dan mencegah *hardcoded values* dalam codebase.

### 4. Super Admin / Owner Workflow & Stabilitas Frontend
- **Hapus Redundansi:** Pemangkasan step persetujuan (approval) yang tidak perlu. Semakin banyak hal yang diotomasi.
- **Manajemen Pesanan Lama:** Peningkatan kapabilitas bagi Super Admin untuk mengelola dan memodifikasi *old orders* (pesanan lama) yang ada sebelum rilis fitur terbaru. Pengelolaan spesifikasi paket untuk pesanan lawas kini lebih aman dan tidak menyebabkan *exception*. (v1.26: Owner TIDAK bisa kelola paket — hanya Super Admin.)
- **Pemrosesan Mata Uang:** Standarisasi parsing data dan perlindungan ekstra di berbagai dashboard (Owner & Purchasing) untuk urusan penampilan angka mata uang — mengatasi isu *runtime formatting exceptions* dan *crashing*.

---

# SANTA MARIA — PATCH v1.11
# e-Katalog: Alur Transaksi Lengkap Pengadaan Supplier

---

## KONSEP ULANG e-KATALOG

```
Supplier    = EKSTERNAL. Hanya bisa akses e-Katalog.
              Tidak bisa lihat order, stok, atau apapun di operasional.

Semua Role  = SEMUA role internal (SO, Gudang, Driver, Dekor, Konsumsi, Pemuka Agama,
              HRD, Security) + Purchasing sendiri bisa membuat permintaan pengadaan.
              (v1.27: Owner TIDAK bisa — view only. Super Admin bisa.)
              Masing-masing mengajukan kebutuhan dari perspektif mereka.
Purchasing  = Yang mereview, approve pengeluaran/transaksi, dan bayar supplier.
Supplier    = Yang mendaftar dan bersaing mengajukan penawaran.
```

Alur e-Katalog mengikuti 7 fase. Setiap fase punya status yang jelas,
punya pihak yang bertanggung jawab, dan punya alarm yang dikirim.

---

## ALUR e-KATALOG — 7 FASE LENGKAP

```
╔══════════════════════════════════════════════════════════════════╗
║  e-KATALOG SANTA MARIA — ALUR TRANSAKSI DEFINITIF              ║
╚══════════════════════════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FASE 1 — SEMUA ROLE BISA BUAT PERMINTAAN PENGADAAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Pemicu: stok kurang (dari alert sistem), kebutuhan proaktif, atau kebutuhan operasional role manapun

Semua role internal bisa buka menu Pengadaan → buat permintaan baru:
  - Nama & spesifikasi barang
  - Jumlah & satuan
  - Kategori barang
  - Harga perkiraan (referensi, opsional)
  - Batas harga maksimum (max_price)
  - Tanggal barang dibutuhkan (needed_by)
  - Alamat pengiriman
  - Deadline pengajuan penawaran (quote_deadline)
  - Keterkaitan ke order tertentu (jika ada)

Simpan DRAFT → review → tekan "Publikasikan"
Status: draft → open
request_number: PRQ-YYYYMMDD-XXXX

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FASE 2 — SUPPLIER MELIHAT & MENGAJUKAN PENAWARAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Saat Gudang publikasi:
  → FCM ALARM ke SEMUA supplier yang is_verified_supplier = true
  → "Pengadaan baru tersedia: [nama barang] — Segera ajukan penawaran!"

Supplier buka app → tab e-Katalog → list semua request status 'open'
Supplier lihat detail: spesifikasi, jumlah, deadline, max_price, jumlah penawaran masuk

PENAWARAN BERSIFAT SEALED BID:
  → Supplier TIDAK bisa lihat harga penawaran supplier lain
  → Hanya bisa lihat: jumlah penawaran yang sudah masuk (count only)
  → Setiap supplier hanya boleh 1 penawaran per permintaan

Supplier ajukan penawaran (supplier_quotes):
  - Harga per unit
  - Total harga (dihitung otomatis: harga_unit × quantity)
  - Merek / brand
  - Deskripsi produk + foto (opsional, upload ke R2)
  - Estimasi hari pengiriman
  - Info garansi & syarat

Validasi saat submit:
  ✗ Jika harga > max_price → ditolak sistem, supplier harus revisi
  ✗ Jika melewati quote_deadline → tidak bisa submit
  ✗ Jika sudah punya 1 penawaran aktif untuk permintaan ini → tidak bisa submit lagi

Setelah submit:
  → Status quote: 'submitted'
  → AI segera validasi harga vs harga pasar real-time (background job)
  → Supplier lihat status "Menunggu Evaluasi" di riwayat penawaran
  → Supplier bisa batalkan sebelum deadline (status: 'cancelled')

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FASE 3 — GUDANG EVALUASI PENAWARAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Setelah quote_deadline terlewat:
  → Sistem otomatis set status permintaan: 'evaluating'
  → Gudang menerima notifikasi: "Deadline penawaran selesai. Silakan evaluasi."

Gudang buka permintaan → tab "Penawaran Masuk"
Tampil list SEMUA quote, per baris:
  - Nama supplier + rating bintang
  - Harga per unit + total
  - Estimasi pengiriman
  - Badge AI:
      🟢 "Harga Wajar" — ai_is_reasonable = true
      🟡 "Perlu Perhatian" — variance 10-20%
      🔴 "Anomali Harga" — variance > threshold
  - Tombol "Lihat Detail" (foto produk, spesifikasi, analisis AI)

Gudang bisa sort by: harga terendah / rating tertinggi / pengiriman tercepat
Gudang pilih 1 pemenang → tekan "Pilih Penawaran Ini"
Dialog konfirmasi: "Pilih CV Maju Jaya, Rp X.000 total?"

Jika OK:
  → Quote terpilih: status 'awarded'
  → Quote lain: status 'rejected' otomatis
  → Status permintaan: 'evaluating' → 'awarded'
  → Gudang tidak langsung dapat barang — menunggu Purchasing approve

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FASE 4 — PURCHASING APPROVE TRANSAKSI ← GATE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Saat Gudang pilih pemenang:
  → FCM ALARM ke Purchasing: "Pengadaan butuh approval!"
  → "Barang: [nama], Supplier: [nama supplier], Total: Rp X"

Purchasing buka app → review lengkap:
  - Detail barang yang dibutuhkan
  - Data supplier pemenang (nama, rating, NPWP)
  - Harga yang ditawarkan vs harga pasar (analisis AI)
  - Budget tersedia
  - Foto produk + spesifikasi

Purchasing punya 2 pilihan:

  [SETUJUI] → PUT /purchasing/procurement-requests/{id}/approve
    → Status permintaan: 'awarded' → 'purchasing_approved'
    → Sistem buat record supplier_transactions (transaksi resmi)
    → FCM ALARM ke supplier PEMENANG:
        "🎉 Penawaran Anda Disetujui!"
        "Silakan kirimkan [nama barang] sejumlah [X] ke [alamat]"
        "Batas pengiriman: [needed_by]"
    → FCM NORMAL ke supplier YANG KALAH:
        "Penawaran Anda tidak dipilih untuk permintaan [nomor]."
        "Terima kasih telah berpartisipasi."
    → Gudang menerima notif: "Purchasing menyetujui pengadaan. Tunggu barang dari supplier."

  [TOLAK] → PUT /purchasing/procurement-requests/{id}/reject
    → Status kembali ke 'evaluating'
    → Gudang menerima notif + alasan penolakan
    → Gudang bisa pilih supplier lain atau batalkan permintaan

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FASE 5 — PENGIRIMAN OLEH SUPPLIER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Supplier menerima kontrak (detail pesanan di app mereka)
Supplier memproses pengiriman barang

Di app Supplier:
  → Lihat detail: barang, jumlah, alamat pengiriman, deadline
  → Tekan "Tandai Sudah Dikirim" → PUT /supplier/quotes/{id}/mark-shipped
      - Input nomor resi pengiriman
      - Upload foto paket yang dikirim (opsional)
  → Status quote: 'shipped'
  → Gudang menerima notif: "Supplier sudah mengirim barang. Nomor resi: [resi]"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FASE 6 — GUDANG TERIMA BARANG → STOK MASUK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Barang tiba di gudang Santa Maria.

Gudang buka app → permintaan terkait → tekan "Barang Diterima"
PUT /gudang/procurement-requests/{id}/receive
  - Konfirmasi jumlah yang diterima (bisa berbeda dari pesanan)
  - Kondisi barang (baik / ada kerusakan)
  - Foto barang yang diterima
  - Catatan jika ada

Jika barang diterima LENGKAP & BAIK:
  → Status permintaan: 'purchasing_approved' → 'goods_received'
  → Sistem OTOMATIS buat stock_transaction type='in':
      stock_item_id = [item terkait], quantity = [jumlah diterima]
      notes = "Dari e-Katalog PRQ-[nomor], supplier: [nama]"
  → Stock item bertambah otomatis
  → Gudang bisa beri rating supplier: 1-5 bintang + ulasan
  → Purchasing menerima notif: "Barang sudah diterima. Segera proses pembayaran ke supplier."

Jika ada KEKURANGAN / KERUSAKAN:
  → Gudang input: barang yang diterima vs yang seharusnya
  → Status: 'partial_received'
  → Notif ke Purchasing + Supplier: ada ketidaksesuaian
  → Purchasing & Gudang koordinasi (di luar sistem, atau via catatan di app)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FASE 7 — PURCHASING BAYAR SUPPLIER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Setelah Gudang konfirmasi barang diterima:

Purchasing buka app → tab "Tagihan Supplier" → lihat permintaan yg perlu dibayar
Purchasing proses pembayaran ke supplier:
  - Metode: Transfer Bank
  - Jumlah: sesuai quote yang diapprove (atau sesuai barang yang diterima jika partial)
  - Purchasing upload bukti transfer (screenshot/foto)
  → PUT /purchasing/supplier-transactions/{id}/pay
      body: { method: 'transfer', amount, receipt_photo, transfer_date }

Status transaksi: 'goods_received' → 'paid'
Supplier menerima notif: "Pembayaran sudah dikirimkan. Cek rekening Anda."
Supplier konfirmasi terima pembayaran (opsional):
  → PUT /supplier/transactions/{id}/confirm-payment

Status final permintaan: 'completed'
Owner menerima ringkasan di laporan harian AI (total pengeluaran e-Katalog hari itu)
```

---

## DATABASE — TABEL BARU & PERUBAHAN

### Tabel `supplier_transactions` (Record Transaksi Resmi Post-Purchasing Approve)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
transaction_number VARCHAR(50) UNIQUE NOT NULL  -- TRX-YYYYMMDD-XXXX
procurement_request_id UUID REFERENCES procurement_requests(id)
supplier_quote_id UUID REFERENCES supplier_quotes(id)
supplier_id UUID REFERENCES users(id)
purchasing_user_id UUID REFERENCES users(id)       -- Purchasing yang approve

-- Nilai Transaksi
agreed_unit_price DECIMAL(15,2) NOT NULL         -- harga per unit yang disepakati
agreed_quantity INTEGER NOT NULL
agreed_total DECIMAL(15,2) NOT NULL              -- total yang disepakati

-- Pengiriman
shipment_status ENUM(
  'pending_shipment',   -- menunggu supplier kirim
  'shipped',            -- supplier tandai sudah dikirim
  'goods_received',     -- Gudang konfirmasi terima
  'partial_received'    -- diterima tapi tidak lengkap / ada kerusakan
) DEFAULT 'pending_shipment'
tracking_number VARCHAR(100) NULLABLE            -- nomor resi pengiriman
shipment_photo_path TEXT NULLABLE                -- foto paket dari supplier
shipped_at TIMESTAMP NULLABLE
received_at TIMESTAMP NULLABLE
received_quantity INTEGER NULLABLE               -- actual yang diterima Gudang
received_condition TEXT NULLABLE                 -- catatan kondisi barang
received_photo_path TEXT NULLABLE               -- foto barang yang diterima

-- Pembayaran ke Supplier
payment_status ENUM('unpaid','paid') DEFAULT 'unpaid'
payment_method ENUM('transfer','cash') NULLABLE
payment_amount DECIMAL(15,2) NULLABLE            -- aktual yang dibayar (bisa beda jika partial)
payment_receipt_path TEXT NULLABLE              -- bukti transfer dari Purchasing
payment_date DATE NULLABLE
payment_confirmed_by_supplier BOOLEAN DEFAULT FALSE
payment_confirmed_at TIMESTAMP NULLABLE

purchasing_approved_at TIMESTAMP NOT NULL
created_at TIMESTAMP
updated_at TIMESTAMP
```

### Tabel `procurement_requests` — Tambah Status Baru

```sql
-- Ganti status ENUM dengan urutan lengkap:
status ENUM(
  'draft',             -- role apapun buat, belum dipublikasi
  'open',              -- Dipublikasi, supplier bisa ajukan penawaran
  'evaluating',        -- Deadline lewat, Gudang sedang evaluasi penawaran
  'awarded',           -- Gudang pilih pemenang, menunggu Purchasing approve
  'purchasing_approved',  -- Purchasing approve, transaksi terbuat, menunggu pengiriman
  'goods_received',    -- Barang sudah diterima Gudang, menunggu pembayaran
  'completed',         -- Barang diterima + pembayaran ke supplier selesai
  'cancelled'          -- Dibatalkan (kapan saja sebelum purchasing_approved)
) DEFAULT 'draft'

-- Tambah field:
requested_by UUID REFERENCES users(id)       -- siapa yang membuat permintaan (role apapun)
supplier_transaction_id UUID NULLABLE REFERENCES supplier_transactions(id)
purchasing_rejection_reason TEXT NULLABLE   -- alasan Purchasing tolak
```

### Tabel `supplier_quotes` — Tambah Status Pengiriman

```sql
-- Tambah status:
status ENUM(
  'submitted',     -- sudah diajukan
  'under_review',  -- Gudang sedang review
  'awarded',       -- dipilih Gudang
  'rejected',      -- ditolak (oleh Gudang atau karena supplier lain dipilih)
  'cancelled',     -- supplier batalkan sebelum deadline
  'shipped',       -- supplier tandai sudah kirim (baru!)
  'completed'      -- barang diterima, pembayaran selesai (baru!)
) DEFAULT 'submitted'

-- Tambah field:
shipment_photo_path TEXT NULLABLE        -- foto paket yang dikirim supplier
tracking_number VARCHAR(100) NULLABLE
shipped_at TIMESTAMP NULLABLE
```

---

## API — ENDPOINT LENGKAP e-KATALOG

### Pengadaan (Semua Role Internal)
```
-- Buat & kelola permintaan — SEMUA role internal bisa akses
POST   /procurement-requests                      -- buat permintaan (otomatis catat requested_by)
GET    /procurement-requests                      -- list milik user ini (filter by status)
GET    /procurement-requests/{id}                 -- detail + semua quote + status transaksi
PUT    /procurement-requests/{id}/publish         -- draft → open
PUT    /procurement-requests/{id}/cancel

-- Evaluasi — dilakukan oleh Gudang (karena mereka yang terima barang fisik)
GET    /gudang/procurement-requests/{id}/quotes   -- semua quote untuk 1 permintaan (dengan AI badge)
PUT    /gudang/supplier-quotes/{quoteId}/award    -- pilih pemenang → status: awarded
PUT    /gudang/supplier-quotes/{quoteId}/reject   -- tolak satu quote

-- Konfirmasi terima barang — Gudang
PUT    /gudang/procurement-requests/{id}/receive  -- body: { received_qty, condition, notes, photo }

-- Rating supplier setelah terima barang
POST   /gudang/supplier-ratings                   -- { supplier_id, rating, review }
```

### Purchasing — e-Katalog
```
-- Review & approve
GET    /purchasing/procurement-requests              -- list yang status 'awarded'
GET    /purchasing/procurement-requests/{id}         -- detail: barang, supplier, harga, AI analysis
PUT    /purchasing/procurement-requests/{id}/approve -- approve → buat supplier_transaction
PUT    /purchasing/procurement-requests/{id}/reject  -- tolak + alasan

-- Bayar supplier
GET    /purchasing/supplier-transactions             -- list transaksi yang perlu dibayar (goods_received)
GET    /purchasing/supplier-transactions/{id}        -- detail transaksi
PUT    /purchasing/supplier-transactions/{id}/pay    -- bayar: { method, amount, receipt_photo }

-- Laporan
GET    /purchasing/supplier-transactions/summary     -- total pengeluaran e-Katalog per periode
```

### Supplier (Eksternal — HANYA e-Katalog)
```
-- Lihat pengadaan yang tersedia
GET    /supplier/procurement-requests             -- semua request status 'open'
GET    /supplier/procurement-requests/{id}        -- detail (spek, jumlah, deadline, max_price)

-- Kelola penawaran
POST   /supplier/quotes                           -- ajukan penawaran baru
GET    /supplier/quotes                           -- riwayat SEMUA penawaran milik supplier ini
GET    /supplier/quotes/{id}                      -- detail + status real-time
PUT    /supplier/quotes/{id}/cancel               -- batalkan (hanya sebelum deadline)
POST   /supplier/quotes/{id}/product-photo        -- upload foto produk

-- Setelah menang & diapprove Purchasing
PUT    /supplier/quotes/{id}/mark-shipped         -- tandai sudah dikirim: { tracking_number, photo }
GET    /supplier/transactions                     -- riwayat transaksi (yang menang + sudah diproses)
GET    /supplier/transactions/{id}                -- detail: status pengiriman + status pembayaran
PUT    /supplier/transactions/{id}/confirm-payment -- konfirmasi pembayaran sudah diterima

-- Profil & statistik
GET    /supplier/profile
PUT    /supplier/profile
GET    /supplier/ratings                          -- rating dari Gudang
GET    /supplier/stats                            -- win rate, total bid, total transaksi, avg rating
```

---

## FLUTTER — SCREEN SUPPLIER (REVISI LENGKAP)

```
lib/features/supplier/
  ├── data/supplier_repository.dart
  └── screens/
      ├── supplier_home.dart
      │     -- Home: stats singkat (total bid aktif, bid menang, rating)
      │     -- Shortcut ke e-Katalog + Riwayat Penawaran
      │     -- Badge merah jika ada yang perlu aksi (misal: barang harus dikirim)
      │
      ├── catalog_list_screen.dart
      │     -- List semua permintaan status 'open'
      │     -- Card: nama barang, jumlah, kategori, deadline, jumlah penawaran masuk
      │     -- Filter: kategori, deadline terdekat
      │     -- Sort: terbaru, deadline terdekat
      │     -- Search: nama barang
      │
      ├── catalog_detail_screen.dart
      │     -- Detail spesifikasi lengkap
      │     -- Jumlah penawaran masuk (count only, bukan nilai/nama)
      │     -- Tombol "Ajukan Penawaran" (jika belum pernah bid + belum deadline)
      │     -- Jika sudah bid: tampilkan status bid saat ini
      │
      ├── quote_form_screen.dart
      │     -- Form penawaran: harga per unit, merek, deskripsi, foto, estimasi pengiriman, garansi
      │     -- Total harga dihitung otomatis real-time saat user ketik harga
      │     -- Validasi: tidak boleh > max_price
      │     -- Tombol submit dengan konfirmasi dialog
      │
      ├── quote_history_screen.dart
      │     -- Semua penawaran supplier ini
      │     -- Badge status per penawaran:
      │         "Menunggu Review" (abu), "Sedang Dievaluasi" (biru),
      │         "Terpilih! 🎉" (hijau), "Tidak Dipilih" (merah), "Dibatalkan" (abu)
      │     -- Tap → QuoteDetailScreen
      │
      ├── quote_detail_screen.dart
      │     -- Detail penawaran yang diajukan
      │     -- Status real-time via Pusher (channel: quote.{quote_id})
      │     -- Jika status 'awarded' + Purchasing approved: tampilkan kontrak
      │         → Detail pesanan: barang, jumlah, alamat pengiriman, deadline kirim
      │         → Tombol "Tandai Sudah Dikirim" + input nomor resi + upload foto
      │
      ├── transaction_list_screen.dart
      │     -- List semua transaksi (yang menang + sudah diproses Purchasing)
      │     -- Status: Menunggu Pengiriman / Sudah Dikirim / Barang Diterima / Sudah Dibayar
      │
      ├── transaction_detail_screen.dart
      │     -- Detail transaksi lengkap
      │     -- Status pengiriman + status pembayaran
      │     -- Jika status 'paid': tampilkan bukti transfer dari Purchasing + tombol "Konfirmasi Terima"
      │
      └── supplier_profile_screen.dart
            -- Profil perusahaan: nama, alamat, NPWP, kategori, status verifikasi
            -- Rating rata-rata + riwayat ulasan dari Gudang
            -- Statistik: total bid, win rate, total nilai transaksi, avg rating
```

---

## FLUTTER — SCREEN PENGADAAN (SEMUA ROLE) & EVALUASI (GUDANG)

```
lib/features/procurement/screens/         -- shared, akses semua role internal
  ├── procurement_list_screen.dart
  │     -- List semua permintaan yang dibuat user ini
  │     -- Filter by status: draft / open / evaluating / awarded / completed
  │     -- FAB: Buat Permintaan Baru
  │
  ├── procurement_form_screen.dart
  │     -- Form buat permintaan baru (akses semua role internal)
  │     -- Validasi: needed_by harus setelah hari ini, deadline < needed_by
  │     -- Preview sebelum publikasi
  │     -- Tombol "Simpan Draft" + "Publikasikan Sekarang"
  │
  ├── procurement_detail_screen.dart
  │     -- Detail permintaan + timeline status
  │     -- Tab "Penawaran Masuk" (jika status evaluating ke atas, hanya Gudang yang bisa evaluasi)
  │     -- Jika status goods_received: tampilkan info transaksi + tombol "Beri Rating Supplier"
  │

lib/features/gudang/screens/              -- evaluasi quote tetap di Gudang
  ├── gudang_quote_list_screen.dart
  │     -- List semua quote untuk 1 permintaan
  │     -- Sort + AI badge per quote
  │     -- Tombol "Pilih Pemenang" per quote
  │
  ├── gudang_quote_detail_screen.dart
  │     -- Detail quote + foto produk + analisis AI
  │     -- Tombol "Pilih Penawaran Ini" (jika status evaluating)
  │
  └── gudang_receive_screen.dart
        -- Form konfirmasi terima barang
        -- Input: jumlah yang diterima, kondisi, catatan, foto
        -- Tombol "Konfirmasi Barang Diterima"
        -- Setelah confirm: form rating supplier langsung muncul
```

---

## RINGKASAN STATUS FLOW e-KATALOG

```
procurement_requests.status:
  draft → open → evaluating → awarded → purchasing_approved → goods_received → completed
                                    ↘ (Purchasing reject) → kembali ke evaluating
                         ↘ (cancelled kapan saja sebelum purchasing_approved)

supplier_quotes.status:
  submitted → [award] → awarded → shipped → completed
           → [reject] → rejected
           → [cancel] → cancelled

supplier_transactions (dibuat saat Purchasing approve):
  shipment_status: pending_shipment → shipped → goods_received / partial_received
  payment_status:  unpaid → paid

procurement_requests.status = 'completed' dicapai saat:
  goods_received = true AND payment_status = 'paid'
```

---

## ALARM e-KATALOG — RINGKASAN

| Momen | Pengaju | Gudang | Purchasing | Supplier (Pemenang) | Supplier (Kalah) | Owner |
|-------|--------|--------|---------|--------------------|--------------------|-------|
| Permintaan dipublikasi | — | — | — | ALARM (semua supplier) | ALARM (semua supplier) | — |
| Deadline penawaran habis | NORMAL (status update) | ALARM (evaluasi!) | — | — | — | — |
| Gudang pilih pemenang | NORMAL (status update) | — | ALARM | — | — | — |
| Purchasing approve | NORMAL (disetujui) | ALARM (tunggu barang) | — | ALARM (kirim barang!) | NORMAL (tidak dipilih) | NORMAL |
| Purchasing tolak | NORMAL (ditolak) | ALARM (pilih ulang) | — | — | — | — |
| Supplier kirim barang | NORMAL (status update) | ALARM (cek resi) | — | — | — | — |
| Gudang konfirmasi terima | NORMAL (diterima) | — | ALARM (proses payment!) | NORMAL (dikonfirmasi) | — | — |
| Purchasing bayar supplier | NORMAL (selesai) | — | — | ALARM (cek rekening!) | — | NORMAL |
| Transaksi selesai | NORMAL (selesai) | — | — | — | — | NORMAL (laporan) |

## 4. DATABASE — PERUBAHAN & TAMBAHAN

### 4.1 Tabel `users` — Tambahan Kolom SO

```sql
-- Tambah kolom untuk Service Officer:
so_channel ENUM('field', 'office') NULLABLE
-- 'field'  = SO lapangan (sales di luar kantor, ketemu klien langsung)
-- 'office' = SO kantor (melayani walk-in, input order atas nama konsumen)
-- NULL untuk role selain service_officer
```

### Tabel `order_field_team_payments` (Tim Lapangan per Order)

```sql
-- Tim lapangan (musisi, koordinator peti, dll) bukan user di app.
-- Purchasing input dan catat upah mereka per order.

id UUID PRIMARY KEY DEFAULT gen_random_uuid()
order_id UUID REFERENCES orders(id)
name VARCHAR(255) NOT NULL               -- nama anggota tim lapangan
role_description VARCHAR(255) NOT NULL   -- "Musisi", "Koordinator Peti", "Penggali Makam", dll
phone VARCHAR(20) NULLABLE               -- kontak (opsional)
amount DECIMAL(15,2) NOT NULL            -- upah yang dibayarkan
payment_method ENUM('cash','transfer') NOT NULL
payment_status ENUM('pending','paid') DEFAULT 'pending'
paid_at TIMESTAMP NULLABLE
paid_by UUID NULLABLE REFERENCES users(id)  -- Purchasing yang membayar
receipt_path TEXT NULLABLE               -- foto bukti bayar (R2)
notes TEXT NULLABLE
created_at TIMESTAMP
updated_at TIMESTAMP
```

### Tabel `hrd_violations` (Catatan Pelanggaran)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
violated_by UUID REFERENCES users(id)         -- siapa yang melanggar
order_id UUID NULLABLE REFERENCES orders(id)  -- order terkait (jika ada)
violation_type ENUM(
  'driver_overtime',            -- driver On Duty melebihi jam kerja
  'so_late_processing',         -- SO terlambat konfirmasi order
  'vendor_no_show',             -- vendor tidak hadir tanpa konfirmasi
  'vendor_repeated_reject',     -- vendor menolak assignment berulang kali
  'field_team_absent',          -- tim lapangan tidak hadir (dicatat Purchasing)
  'late_bukti_upload',          -- tidak upload bukti foto tepat waktu
  'late_payment_processing',    -- Purchasing terlambat verifikasi payment
  'other'
) NOT NULL
description TEXT NOT NULL                     -- detail pelanggaran
threshold_value DECIMAL(10,2) NULLABLE        -- nilai ketentuan (misal: 12 jam)
actual_value DECIMAL(10,2) NULLABLE           -- nilai aktual (misal: 14 jam)
severity ENUM('low','medium','high') NOT NULL
hrd_notes TEXT NULLABLE                       -- catatan HRD setelah review
status ENUM('new','acknowledged','resolved','escalated') DEFAULT 'new'
acknowledged_at TIMESTAMP NULLABLE
resolved_at TIMESTAMP NULLABLE
created_at TIMESTAMP
updated_at TIMESTAMP
```

### Tabel `system_thresholds` (Ketentuan yang Bisa Dikonfigurasi Owner/HRD)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
key VARCHAR(100) UNIQUE NOT NULL
value DECIMAL(10,2) NOT NULL
unit VARCHAR(50) NOT NULL          -- 'hours', 'minutes', 'count', 'percent'
description TEXT NOT NULL
updated_by UUID NULLABLE REFERENCES users(id)
updated_at TIMESTAMP

-- Default values:
-- driver_max_duty_hours = 12 (jam) — lebih dari ini: alarm HRD
-- so_max_processing_minutes = 30 (menit) — lebih dari ini: alarm HRD
-- vendor_max_reject_count_monthly = 3 (kali) — lebih dari ini: alarm HRD
-- bukti_upload_deadline_hours = 2 (jam) — setelah order selesai
-- payment_verify_deadline_hours = 24 (jam) — Purchasing harus verifikasi dalam X jam
-- field_team_payment_deadline_hours = 48 (jam) — upah tim lapangan dibayar dalam X jam
-- order_completion_tolerance_hours = 2 (jam) — toleransi lewat estimasi sebelum alarm Owner
-- consumer_payment_reminder_interval_hours = 24 (jam) — interval kirim reminder ke consumer
-- consumer_payment_reminder_max_count = 3 (kali) — maksimal reminder ke consumer
```

### Tabel `orders` — Kolom Tambahan SO Channel

```sql
-- Tambah di tabel orders:
created_by_so_channel ENUM('field','office','consumer_self') NOT NULL DEFAULT 'consumer_self'
-- 'consumer_self' = consumer buat order sendiri via app
-- 'field' = SO lapangan yang input order atas nama consumer
-- 'office' = SO kantor yang input order untuk walk-in client

-- Jika SO yang input, consumer_phone tetap diisi (untuk notifikasi)
-- consumer mungkin tidak punya akun app — SO bisa input tanpa pic_user_id
pic_user_id UUID NULLABLE REFERENCES users(id)  -- NULLABLE jika consumer belum punya akun
```

---

## 7. API — ENDPOINT BARU/BERUBAH

### Purchasing

```
-- Payment Consumer
GET    /purchasing/orders                        -- list order yang perlu diverifikasi payment-nya
GET    /purchasing/orders/{id}/payment-proof     -- lihat foto bukti payment dari consumer
PUT    /purchasing/orders/{id}/payment/verify    -- konfirmasi lunas
PUT    /purchasing/orders/{id}/payment/reject    -- tolak bukti, consumer harus upload ulang

-- Bayar Supplier (dari e-Katalog)
GET    /purchasing/procurement-requests          -- list yang awarded & approved
GET    /purchasing/procurement-requests/{id}
PUT    /purchasing/procurement-requests/{id}/approve  -- approve pengeluaran ke supplier
PUT    /purchasing/procurement-requests/{id}/reject

-- Bayar Tim Lapangan
GET    /purchasing/orders/{id}/field-team         -- list tim lapangan untuk 1 order
POST   /purchasing/orders/{id}/field-team         -- tambah anggota tim lapangan
PUT    /purchasing/field-team/{memberId}/pay      -- bayar: { method, amount, receipt foto }
DELETE /purchasing/field-team/{memberId}          -- hapus (jika salah input)
GET    /purchasing/field-team/pending             -- semua pembayaran tim lapangan yang pending

-- PO Langsung (v1.21: pakai procurement-requests dengan filter is_direct_po=true)
-- Lihat PATCH v1.21 untuk klarifikasi

-- Laporan
GET    /purchasing/reports/monthly               -- laporan pengeluaran bulanan
GET    /purchasing/reports/field-team            -- laporan upah tim lapangan
GET    /purchasing/reports/supplier-payments     -- laporan pembayaran supplier
```

### Service Officer — Order Walk-in (SO Kantor)

```
-- SO Kantor bisa buat order tanpa consumer punya akun
POST   /so/orders/walkin                    -- buat order walk-in
-- Body: sama seperti consumer buat order, tapi tanpa pic_user_id
-- SO input semua data konsumen dan almarhum
-- created_by_so_channel = 'office' atau 'field'

GET    /so/orders                           -- list order yang masuk ke SO ini
```

### HRD

```
GET    /hrd/violations                      -- semua pelanggaran (filter by status, severity)
GET    /hrd/violations/{id}
PUT    /hrd/violations/{id}/acknowledge     -- HRD acknowledge: "sudah dibaca"
PUT    /hrd/violations/{id}/resolve         -- HRD tandai selesai + tulis catatan
PUT    /hrd/violations/{id}/escalate        -- eskalasi ke Owner
GET    /hrd/violations/by-user/{userId}     -- histori pelanggaran per karyawan
GET    /hrd/thresholds                      -- lihat semua threshold ketentuan
PUT    /hrd/thresholds/{key}                -- update nilai threshold (bersama Owner)
GET    /hrd/reports/monthly                 -- laporan pelanggaran bulanan
```

### Owner — Tambahan

```
-- v1.27: PUT /owner/thresholds DIHAPUS — Owner view only, threshold dikelola Super Admin
GET    /owner/hrd/violations                -- Owner lihat semua pelanggaran (read-only)
```

---

## 9. ALUR — TAMBAHAN

### SO Multi-Channel: Field vs Kantor

```
CHANNEL A — SO Lapangan (so_channel = 'field')
  Consumer menghubungi SO via WA/telepon
  SO membuka app → buat order untuk consumer
  SO isi semua data (konsumen + almarhum)
  created_by_so_channel = 'field'
  Consumer mendapat WA/SMS dengan link tracking
  (atau consumer buat akun sendiri nanti jika mau)

CHANNEL B — SO Kantor (so_channel = 'office')
  Walk-in client datang ke kantor
  SO Kantor (akun khusus kantor) buka app
  SO isi data consumer dan almarhum secara langsung di depan klien
  created_by_so_channel = 'office'
  Jika klien mau tracking: SO bantu daftarkan nomor HP di tempat

CHANNEL C — Consumer Self (consumer_self)
  Consumer download app dan daftar sendiri
  Consumer input data sendiri via form atau chatbot AI

Ketiga channel menghasilkan Order Object yang sama.
Tidak ada perbedaan alur setelah order terbuat.
```

### Purchasing — Pembayaran Tim Lapangan

```
Setelah order selesai:
Purchasing membuka tab "Tim Lapangan" di detail order
Purchasing input nama, peran, dan nominal upah setiap anggota:
  - Musisi: [nama], Rp X
  - Koordinator Peti: [nama], Rp Y
  - Penggali Makam: [nama], Rp Z
  - [anggota lainnya sesuai kebutuhan per order]

Purchasing bayar:
  CASH → Purchasing tandai "Dibayar Cash" + foto bukti serah terima
  TRANSFER → Purchasing transfer → upload screenshot → tandai "Dibayar Transfer"

Sistem catat semua di order_field_team_payments
Laporan pengeluaran upah tim lapangan tersedia per order dan per bulan

Jika Purchasing tidak memproses upah dalam deadline:
  → Scheduler deteksi → alarm HRD + catatan pelanggaran
```

### HRD — Sistem Deteksi Pelanggaran

```
DRIVER OVERTIME:
  Scheduler setiap 30 menit cek:
  Jika driver On Duty > system_thresholds.driver_max_duty_hours:
    → Buat hrd_violations record (driver_overtime, severity: medium)
    → FCM ALARM ke HRD: "Driver [nama] On Duty sudah [X] jam (maks [threshold] jam)"
    → FCM HIGH ke Owner
    → HRD buka app, lihat detail, tulis catatan, resolve atau eskalasi

SO TERLAMBAT PROSES ORDER:
  Scheduler setiap 5 menit cek:
  Jika order.status = 'pending' dan sudah > so_max_processing_minutes sejak dibuat:
    → Buat hrd_violations (so_late_processing, severity: low→medium jika sudah 2x lipat)
    → FCM ALARM ke HRD
    → FCM HIGH ke Owner
    → HRD catat, eskalasi jika perlu

VENDOR BERULANG TOLAK:
  Scheduler harian cek:
  Jika vendor tolak assignment bulan ini >= vendor_max_reject_count_monthly:
    → Buat hrd_violations (vendor_repeated_reject, severity: high)
    → FCM ALARM ke HRD + Owner
    → HRD evaluasi apakah vendor perlu dievaluasi kontrak

TIM LAPANGAN TIDAK HADIR:
  Purchasing input "Tidak Hadir" saat input upah tim lapangan
  → Sistem buat hrd_violations (field_team_absent)
  → FCM ALARM ke HRD untuk tindak lanjut

PURCHASING TERLAMBAT VERIFIKASI PAYMENT:
  Jika consumer sudah upload bukti > payment_verify_deadline_hours:
    → hrd_violations (late_payment_processing)
    → ALARM ke HRD + Owner

LATE BUKTI LAPANGAN:
  Jika order completed tapi bukti foto driver/dekor/konsumsi belum upload
  dalam bukti_upload_deadline_hours:
    → hrd_violations (late_bukti_upload)
    → ALARM ke HRD
```

---

## 11. NOTIFIKASI — HRD ALARM

```php
// Tambahkan ke NotificationService:

public static function sendHrdViolationAlert(HrdViolation $violation): void {
  $user = User::find($violation->violated_by);
  $severityLabel = match($violation->severity) {
    'high'   => '🔴 URGENT',
    'medium' => '🟡 PERHATIAN',
    default  => '🔵 INFO',
  };

  // Alarm ke HRD
  self::sendToRole('hrd', $violation->severity === 'high' ? 'ALARM' : 'HIGH',
    "{$severityLabel} Pelanggaran Ketentuan",
    "{$user->name} ({$user->role}): {$violation->description}",
    ['violation_id' => $violation->id, 'action_required' => 'hrd_review']
  );

  // Notif ke Owner
  self::sendToRole('owner',
    $violation->severity === 'high' ? 'HIGH' : 'NORMAL',
    "Catatan HRD: {$user->name}",
    $violation->description,
    ['violation_id' => $violation->id]
  );
}
```

---

## 13. FLUTTER — PERUBAHAN STRUKTUR

```
lib/features/
  ├── purchasing/                       -- Purchasing (pengadaan, payment, upah)
  │   ├── data/purchasing_repository.dart
  │   └── screens/
  │       ├── purchasing_home.dart         -- dashboard: pending payment + pending upah
  │       ├── payment_verify_screen.dart-- lihat foto bukti consumer + approve/reject
  │       ├── field_team_screen.dart    -- input & bayar tim lapangan per order
  │       ├── field_team_member_form.dart-- form tambah anggota tim + input upah
  │       ├── supplier_payment_screen.dart-- list supplier yang perlu dibayar
  │       ├── po_review_screen.dart     -- approve PO (v1.21: = procurement approval is_direct_po=true)
  │       └── purchasing_report_screen.dart-- laporan pengeluaran
  │
  ├── hrd/                              -- BARU
  │   ├── data/hrd_repository.dart
  │   └── screens/
  │       ├── hrd_home.dart             -- dashboard: violation count per severity
  │       ├── violation_list_screen.dart-- list semua pelanggaran + filter
  │       ├── violation_detail_screen.dart-- detail + form catatan HRD + tombol resolve/eskalasi
  │       ├── employee_history_screen.dart-- histori pelanggaran per karyawan
  │       └── threshold_settings_screen.dart-- lihat & edit threshold ketentuan
  │
  ├── service_officer/
  │   └── screens/
  │       ├── so_home.dart
  │       ├── order_list_screen.dart
  │       ├── order_detail_screen.dart
  │       ├── order_confirm_screen.dart
  │       ├── addon_select_screen.dart
  │       ├── payment_record_screen.dart
  │       └── walkin_order_screen.dart  -- BARU: SO kantor input order walk-in
  │           -- form lengkap: data konsumen + almarhum dalam 1 screen
  │           -- tidak perlu consumer punya akun
  │           -- created_by_so_channel = 'office' atau 'field'
```

### Route Guard — Updated

```dart
switch (user.role) {
  case 'super_admin'     : → SuperAdminDashboard
  case 'consumer'        : → ConsumerHome
  case 'service_officer' : → SOHome
  case 'gudang'          : → GudangHome
  case 'purchasing'         : → PurchasingHome
  case 'driver'          : → DriverHome
  case 'supplier'        : → SupplierHome
  case 'dekor'           : → VendorHome          // accentColor: AppColors.roleDekor
  case 'konsumsi'        : → VendorHome          // accentColor: AppColors.roleKonsumsi
  case 'pemuka_agama'    : → VendorHome          // accentColor: AppColors.rolePemukaAgama
  case 'owner'           : → OwnerDashboard
  case 'hrd'             : → HrdHome
  case 'security'        : → SecurityHome
  case 'viewer'          : → ViewerDashboard     // read-only: laporan & status order
}
```

---

## AKUN TEST — UPDATED v1.12

### Personel & Vendor — POST /auth/login-internal

| Role | Nama | Email | Password | Keterangan |
|------|------|-------|----------|-----------|
| super_admin | Super Admin | superadmin@santamaria.id | superadmin123 | |
| owner | Owner Santa Maria | owner@santamaria.id | owner123 | |
| service_officer | Budi SO Lapangan | so@santamaria.id | so123456 | so_channel: field |
| service_officer | Kantor Santa Maria | sokantor@santamaria.id | sokantor123 | so_channel: office |
| gudang | Gerry Gudang | gudang@santamaria.id | gudang123 | |
| purchasing | Siti Purchasing | purchasing@santamaria.id | purchasing123 | |
| hrd | Hendra HRD | hrd@santamaria.id | hrd123456 | |
| driver | Anto Driver | driver@santamaria.id | driver123 | |
| supplier | CV Maju Jaya | supplier@santamaria.id | supplier123 | |
| supplier | UD Sinar Baru | supplier2@santamaria.id | supplier123 | |
| dekor | Laviore Dekor | dekor@santamaria.id | dekor123 | |
| konsumsi | Katering Konsumsi | konsumsi@santamaria.id | konsumsi123 | |
| pemuka_agama | Romo Petrus | pemuka@santamaria.id | pemuka123 | |
| security | Security Pos | security@santamaria.id | security123 | |
| viewer | Viewer Laporan | viewer@santamaria.id | viewer123 | read-only |

### Konsumen — POST /auth/login-consumer

| Nama | Nomor HP | PIN |
|------|----------|-----|
| Keluarga Bpk. Yohanes | 08199999999 | 1234 |

---

# SANTA MARIA — PATCH v1.13
# Revisi Alur Logistik: View Order Awal, Otomatisasi Stok & Armada, Flow Multi-Tugas Driver & Dekorasi

## PERUBAHAN FUNDAMENTAL v1.13
1. **Akses Order Baru:** Purchasing dan Gudang sekarang memiliki visibilitas penuh ke pesanan baru ('pending') secara real-time di dashboard mereka, tidak lagi harus buta menunggu konfirmasi SO.
2. **Otomatisasi Stok Gudang:** Begitu pesanan dikonfirmasi dan masuk ke Gudang, stok gudang otomatis dikurangi (auto-deduct) oleh sistem tanpa intervensi manual.
3. **Manajemen Armada & Penugasan Driver:** Paket yang dikonfirmasi otomatis mengurangi slot ketersediaan mobil di jam tersebut. Driver dapat memantau ketersediaan armada. Sistem *baru* akan melakukan auto-assign Driver dengan mobil spesifik dan instruksi keberangkatan *setelah* Gudang (dan Purchasing, jika ada pengadaan) menandai status "Siap Angkut" (Ready).
4. **Alur Dekorasi yang Diperbaiki (Gate Logistik):** Tim Dekorasi **TIDAK** diberitahu di awal saat SO konfirmasi. Dekorasi baru akan mendapatkan Notifikasi/Alarm untuk eksekusi lapangan *setelah* Driver berangkat dan tiba di tempat tujuan mengantarkan barang-barang logistik dari gudang.
5. **Dua (2) Pekerjaan Utama Driver:** Driver kini diberi flow 2 tahap pekerjaan dalam satu order:
   - **Tugas 1:** Mengantarkan barang perlengkapan dari Gudang turun ke Rumah Duka.
   - **Tugas 2:** Menjemput dan mengantarkan Jenazah ke Rumah Duka.

---

## TABEL ALARM FINAL — SIAPA DAPAT APA DAN KAPAN (v1.17 — Unified)

| Kejadian | SO | Gudang | Purchasing | Driver | Dekor | Konsumsi | Pemuka Agama | Tukang Foto | HRD | Owner | Consumer |
|----------|----|----|----|----|----|----|----|----|----|----|-----|
| Order masuk (Pending)| ALARM | NORMAL (View) | NORMAL (View)| — | — | — | — | — | — | — | — |
| SO konfirmasi Order | — | ALARM | ALARM | ❌ | ❌ (Tunggu) | ALARM | ALARM | ALARM | — | HIGH | HIGH |
| Gudang Siap Angkut | — | — | — | ALARM (Assign) | ❌ | — | — | — | — | — | — |
| Driver Tiba (Barang/Tugas 1)| — | — | — | — | ALARM KERAS | — | — | — | — | — | NORMAL |
| Driver Tiba (Jenazah/Tugas 2)| — | — | — | — | — | — | — | — | — | — | HIGH |
| Vendor/Foto check-in | HIGH | — | — | — | — | — | — | — | — | — | — |
| Vendor/Foto tidak hadir | HIGH | — | — | — | — | — | — | — | ALARM | HIGH | — |
| Order auto-selesai | — | — | ALARM | — | — | — | — | — | — | NORMAL | HIGH |
| Peralatan belum kembali H+1 | — | ALARM | — | — | — | — | — | — | — | NORMAL | — |
| Consumer upload bukti | — | — | ALARM | — | — | — | — | — | — | — | — |
| Payment dikonfirmasi | — | — | — | — | — | — | — | — | — | NORMAL | HIGH |
| Extra approval signed | HIGH | — | ALARM | — | — | — | — | — | — | HIGH | — |
| Akta kematian lengkap | HIGH | — | — | — | — | — | — | — | — | NORMAL | — |
| Coffin QC lolos | HIGH | — | — | — | — | — | — | — | — | — | — |
| Driver overtime | — | — | — | — | — | — | — | — | ALARM | HIGH | — |
| SO terlambat proses | — | — | — | — | — | — | — | — | ALARM | NORMAL | — |
| Vendor tolak berulang | — | — | — | — | — | — | — | — | ALARM | HIGH | — |
| Purchasing terlambat verify| — | — | — | — | — | — | — | — | ALARM | HIGH | — |
| Stok kurang (needs_restock)| — | ALARM | ALARM | — | — | — | — | — | — | — | — |
| Mock location terdeteksi | — | — | — | — | — | — | — | — | ALARM | HIGH | — |
| Karyawan absent (harian) | — | — | — | — | — | — | — | — | HIGH | — | — |
| KPI skor rendah | — | — | — | — | — | — | — | — | ALARM | HIGH | — |

---

## ALUR ORDER FINAL — EKSAK (Pengganti Section 9.1 Sebelumnya)

```
╔══════════════════════════════════════════════════════════════╗
║  SANTA MARIA — ALUR ORDER DEFINITIF v1.13                    ║
╚══════════════════════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 1 — ORDER MASUK & VIEW AWAL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Consumer atau SO menginput data pesanan awal.
Sistem generate order_number: SM-YYYYMMDD-XXXX
Status order: 'pending'

→ FCM ALARM ke semua Service Officer aktif.
→ GUDANG & PURCHASING: Mendapatkan hak akses penuh untuk melihat "Detail Order Aktif" yang baru masuk di dashboard mereka, meskipun statusnya masih 'pending' dan belum fix.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 2 — SERVICE OFFICER VALIDASI & KONFIRMASI
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SO buka order, verifikasi data, pilih paket (dari DB),
tambah add-on, tentukan scheduled_at, input estimated_duration_hours.
SO tekan "Konfirmasi Order".

Pengurangan Armada Automatis: Paket otomatis memakan kuota slot mobil
yang tersedia pada jam eksekusi tersebut.
Status order: 'confirmed'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 3 — DISTRIBUSI BERSAMAAN & DEDUCT STOK OTOMATIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Saat SO konfirmasi, sistem beroperasi seketika & paralel:

  [ GUDANG ]
  → FCM ALARM: "Order [nomor] Dikonfirmasi — Stok Telah Dikurangi!"
  → Sistem *otomatis mengurangi (auto-deduct)* stok inventory sesuai komponen paket & add-on.
  → Sistem auto-generate `order_equipment_items` dari `equipment_master` sesuai paket.
  → Sistem auto-generate `order_billing_items` dari `billing_item_master` sesuai paket + addons.
  → Jika stok tidak cukup → flag `needs_restock` → alarm Purchasing.

  [ PURCHASING ]
  → FCM ALARM: Order dikonfirmasi. Jika `needs_restock` aktif, siapkan PO/e-Katalog.

  [ KONSUMSI ]
  → FCM ALARM: Assignment katering untuk order ini.
  → Sistem buat `field_attendances` (status: 'scheduled') untuk vendor konsumsi.

  [ PEMUKA AGAMA ]
  → FCM ALARM: Assignment upacara keagamaan untuk order ini.
  → Sistem buat `field_attendances` (status: 'scheduled') untuk pemuka agama.

  [ TUKANG FOTO (jika di-assign) ]
  → FCM ALARM: "Kamu ditugaskan sebagai fotografer di Order [nomor]."
  → Sistem buat `field_attendances` (status: 'scheduled').

  [ DEKORASI ]
  → TIDAK MENDAPAT ALARM. Standby menunggu Driver tiba di lokasi (STEP 5).

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 4 — GATE GUDANG: PERSIAPAN SELESAI
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Gudang menyelesaikan pengemasan barang-barang fisik.
Jika perbekalan sudah di halaman dan tinggal diangkut, 
Gudang menekan "Stok Siap Angkut".
Status gudang: 'ready'

  [ DRIVER — AUTO ASSIGNMENT ]
  Baru setelah status 'ready', Driver (yg bisa lihat dashboard ketersediaan armada) 
  menerima Auto-Assign dari sistem.
  → FCM ALARM KE DRIVER: "Kamu ditugaskan ke Order [X]. Gunakan Kendaraan [Y]. Jam Berangkat: [Waktu_Tepat_Setelah_Ini]."

Status order berubah: 'confirmed' → 'in_progress'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 5 — DRIVER TUGAS 1: ANGKUT BARANG (LOGISTIK)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Driver membawa kendaraan [Y] yang ditetapkan.
1. Driver angkut barang dari Gudang.
2. Driver berangkat ke Rumah Duka (tujuan prosesi).
3. Driver tiba di Rumah Duka & menurunkan barang logistik.
4. Driver menekan update status di aplikasi: "Barang Tiba di Tujuan".

  [ GATE DEKORASI DIBUKA ]
  Saat Driver mengupdate "Barang Tiba di Tujuan":
  → FCM ALARM KE DEKORASI: "Barang logistik untuk Order [nomor] sudah tiba di lokasi! Segera meluncur untuk konfirmasi & pasang dekorasi saat eksekusi!"
  → Tim Dekorasi berangkat.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 6 — DRIVER TUGAS 2: ANTAR JENAZAH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Sembari Dekorasi berjalan, Driver melanjutkan alur:
1. Driver menuju lokasi jenazah (RS/Rumah Penjemputan).
   → orders.driver_status: 'logistics_arrived' → 'hearse_departed'
2. Tiba di lokasi penjemputan → upload bukti di app.
   → orders.driver_status: → 'hearse_pickup'
3. Membawa jenazah ke Rumah Duka / lokasi upacara.
4. Tiba di tujuan akhir dengan jenazah → upload bukti akhir.
   → orders.driver_status: → 'hearse_arrived' → 'all_done'
5. Keluarga / Consumer menerima notifikasi "Jenazah dan Tim telah tiba."

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 7 — EKSEKUSI & ORDER SELESAI (TIME-BASED)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Dekor, Konsumsi merampungkan layanan dan menekan "Selesai" di aplikasi.
Sistem secara periodik (setiap 5 menit) memantau jam.
Jika `waktu_sekarang > scheduled_at + estimated_duration_hours` DAN `driver_status` mengindikasikan selesai:
→ Order otomatis berubah jadi 'completed' (Time-Based Automatic Complete).
→ AI mengirimkan pesan dukacita.
→ Consumer diberikan akses untuk upload Bukti Pembayaran.

  [ POST-COMPLETE — OTOMATIS ]
  → Cek `order_equipment_items`: ada yang belum returned?
    → Jika ya: alarm Gudang "Peralatan Order [X] belum kembali"
  → Cek `field_attendances`: ada yang absent?
    → Jika ya: buat `hrd_violations` (vendor_no_show)
  → Generate `order_billing_items` final (jika belum lengkap) untuk Purchasing

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 8 — PAYMENT & PURCHASING VERIFIKASI
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Consumer Upload Bukti → Alarm ke Purchasing → Purchasing review → Status 'paid'.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 9 — POST-ORDER: TAGIHAN, UPAH, & AKTA KEMATIAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Setelah payment verified:
  → Purchasing finalisasi `order_billing_items` (26 item + tambahan + kembali)
  → Purchasing bayar tim lapangan via `order_field_team_payments`
  → SO buat checklist akta kematian (`order_death_certificate_docs` + items)
  → SO catat persetujuan tambahan (`order_extra_approvals` + lines) jika ada
  → Setelah semua berkas akta diterima keluarga → order benar-benar selesai

  [ SCHEDULER POST-ORDER ]
  → H+1: cek peralatan belum kembali → alarm Gudang
  → H+1: cek berkas akta belum dibuat → reminder SO
  → H+2: cek upah tim lapangan belum dibayar → alarm HRD
```

---

## DATABASE — PERUBAHAN SECTION 4.5

### Kolom Tambahan di Tabel `orders`

```sql
-- Tambahan untuk alur baru:
estimated_duration_hours DECIMAL(4,1) DEFAULT 3.0  -- estimasi durasi prosesi (jam)
-- Input oleh SO saat konfirmasi order

scheduled_at TIMESTAMP NULLABLE              -- tetap, jadwal eksekusi (input SO)

-- Status order — v1.26: 17 status granular (lihat PATCH v1.26 untuk detail lengkap)
-- pending → awaiting_signature → so_review → confirmed → preparing → ready_to_dispatch
-- → driver_assigned → delivering_equipment → equipment_arrived → picking_up_body
-- → body_arrived → in_ceremony → heading_to_burial → burial_completed
-- → returning_equipment → completed | cancelled
-- Label consumer-facing dikelola di tabel order_status_labels (dinamis)
status VARCHAR(50) NOT NULL DEFAULT 'pending'

-- Payment evidence dari consumer
payment_proof_path TEXT NULLABLE             -- path foto bukti di R2
payment_proof_uploaded_at TIMESTAMP NULLABLE -- waktu consumer upload bukti
payment_verified_by UUID NULLABLE REFERENCES users(id)   -- Purchasing yang verify

-- Auto-complete tracking
auto_completed_at TIMESTAMP NULLABLE         -- waktu sistem auto-complete
completion_method ENUM('auto_time','manual') NULLABLE DEFAULT 'auto_time'
```

### Tabel `order_bukti_lapangan` (Bukti Foto dari Lapangan)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
order_id UUID REFERENCES orders(id)
uploaded_by UUID REFERENCES users(id)
role VARCHAR(50) NOT NULL               -- 'driver', 'dekor', 'konsumsi'
bukti_type ENUM(
  'penjemputan',      -- driver foto saat jemput jenazah
  'tiba_tujuan',      -- driver foto saat tiba di pemakaman
  'dekorasi_selesai', -- dekor foto hasil dekorasi
  'konsumsi_selesai', -- konsumsi foto setup katering
  'lainnya'
) NOT NULL
file_path TEXT NOT NULL                 -- R2 path
file_size_bytes BIGINT NOT NULL
notes TEXT NULLABLE
created_at TIMESTAMP
```

---

## API — ENDPOINT BARU/BERUBAH

### Consumer — Payment Proof
```
POST   /consumer/orders/{id}/payment-proof     -- upload foto bukti cash/transfer
GET    /consumer/orders/{id}/payment-status    -- cek status payment
```

### SO — Dikonfirmasi Bisa Set Durasi
```
PUT    /so/orders/{id}/confirm                 -- body: { scheduled_at, estimated_duration_hours, package_id, addon_ids[] }
```

### Gudang — Gate Konfirmasi Stok
```
PUT    /gudang/orders/{id}/stock-ready         -- konfirmasi semua stok siap → trigger alarm driver
GET    /gudang/orders/{id}/checklist           -- list item yang harus disiapkan
PUT    /gudang/orders/{id}/checklist/{itemId}  -- centang item
```

### Driver — Upload Bukti
```
POST   /driver/orders/{id}/bukti               -- upload foto bukti lapangan
GET    /driver/orders/{id}/bukti               -- list bukti yang sudah diupload
```

### Vendor (Dekor, Konsumsi) — Upload Bukti
```
POST   /vendor/assignments/{id}/bukti          -- upload foto bukti hasil kerja
```

### Purchasing — Verifikasi Payment Consumer (v1.9, lihat juga section 7 untuk endpoint lengkap)
```
GET    /purchasing/orders                         -- list order dengan payment yang perlu diverifikasi
GET    /purchasing/orders/{id}/payment-proof      -- lihat foto bukti dari consumer (signed URL)
PUT    /purchasing/orders/{id}/payment/verify     -- body: { status: 'paid'|'rejected', notes }
PUT    /purchasing/orders/{id}/payment/reject     -- tolak bukti, consumer harus upload ulang
```

---

## FLUTTER — PERUBAHAN SCREEN

### Consumer — Payment Screen
```dart
// consumer/screens/payment_screen.dart — BARU
// Tampil setelah order status = 'completed'
// Tampilkan invoice (dari AI) + total yang harus dibayar
// 2 pilihan:
//   [CASH] → instruksi bayar ke SO/kasir → tombol "Upload Foto Struk"
//   [TRANSFER] → tampilkan no rekening + nama → tombol "Upload Bukti Transfer"
// Setelah upload:
//   → Loading "Mengirim bukti..."
//   → Success: "Bukti terkirim. Tim kami akan verifikasi segera."
//   → Status badge: "Menunggu Verifikasi" (abu) → "Lunas" (hijau)

// Image picker + compress sebelum upload (max 5MB, quality 85)
// Upload ke: POST /consumer/orders/{id}/payment-proof
// File disimpan di R2: payment_proofs/{order_id}/proof.{ext}
```

### Gudang — Stock Ready Gate Screen
```dart
// gudang/screens/stock_ready_screen.dart — BARU
// Tampil saat ada order baru dengan status 'confirmed'
// GlassCard besar dengan: nama order, scheduled_at, daftar item + jumlah
// Untuk setiap item: toggle "Tersedia" (hijau) / "Kurang" (merah)
// Jika semua hijau → tombol "Konfirmasi Stok Siap" aktif (GlassButton navy)
// Jika ada yang merah → tombol "Buat Permintaan Pengadaan" muncul
//   → langsung ke e-Katalog form atau PO form
// Setelah konfirmasi: "Stok siap! Driver akan segera mendapat notifikasi."
```

### Driver — Bukti Screen
```dart
// driver/screens/bukti_upload_screen.dart — BARU
// Dipanggil saat:
//   driver_status = 'hearse_pickup' → upload foto jenazah/penjemputan
//   driver_status = 'hearse_arrived' → upload foto tiba tujuan
// image_picker + compress → POST /driver/orders/{id}/bukti
// Simple: kamera langsung terbuka, foto, konfirmasi, upload
// Loading indicator + success message
```

### Purchasing — Verifikasi Payment Screen
```dart
// purchasing/screens/payment_verify_screen.dart — (sudah ada di features/purchasing/, lihat section 13)
// List order yang payment_status = 'proof_uploaded'
// Per order: tampilkan foto bukti (GlassCard + cached_network_image signed URL)
// Tombol "Konfirmasi Lunas" (GlassButton hijau) + "Tolak Bukti" (GlassButton merah)
// Jika tolak: input alasan → consumer mendapat notif untuk upload ulang
```

---

## SCHEDULERS — PERUBAHAN

```php
protected function schedule(Schedule $schedule): void {
  $schedule->command('report:daily')->dailyAt('21:00')->timezone('Asia/Jakarta');
  $schedule->command('pemuka-agama:check-timeout')->everyFiveMinutes();
  $schedule->command('vendor:monthly-score')->monthlyOn(1, '00:00');
  $schedule->command('stock:check-anomaly')->dailyAt('08:00')->timezone('Asia/Jakarta');
  $schedule->command('ai:demand-prediction')->weekly()->mondays()->at('07:00');
  $schedule->command('catalog:close-expired-quotes')->hourly();
  $schedule->command('notification:repeat-alarms')->everyThirtySeconds();

  // BARU: Auto-complete berdasarkan waktu (setiap 5 menit)
  $schedule->command('order:auto-complete-by-time')->everyFiveMinutes();
}
```

### Command: `order:auto-complete-by-time`

```php
// app/Console/Commands/AutoCompleteOrdersByTime.php

class AutoCompleteOrdersByTime extends Command {
  protected $signature = 'order:auto-complete-by-time';

  public function handle(): void {
    $now = now();

    Order::where('status', 'in_progress')
      ->whereNotNull('scheduled_at')
      ->whereNotNull('estimated_duration_hours')
      ->where('driver_overall_status', 'all_done')
      ->get()
      ->each(function (Order $order) use ($now) {
        $expectedEnd = Carbon::parse($order->scheduled_at)
          ->addHours($order->estimated_duration_hours);

        if ($now->greaterThan($expectedEnd)) {
          DB::transaction(function () use ($order) {
            $order->update([
              'status'           => 'completed',
              'completed_at'     => now(),
              'completion_method'=> 'auto_time',
            ]);

            OrderStatusLog::create([
              'order_id'   => $order->id,
              'user_id'    => null,
              'from_status'=> 'in_progress',
              'to_status'  => 'completed',
              'notes'      => "Auto-completed: jam eksekusi sudah terlewat ({$order->estimated_duration_hours} jam).",
            ]);

            dispatch(new GenerateDukaText($order));

            NotificationService::send($order->pic_user_id, 'HIGH',
              'Layanan Selesai',
              'Layanan pemakaman telah selesai. Silakan lakukan pembayaran melalui aplikasi.'
            );
            NotificationService::sendToRole('purchasing', 'ALARM',
              "Bukti Payment Belum Masuk — {$order->order_number}",
              "Order selesai. Tunggu bukti dari konsumen atau hubungi penanggung jawab."
            );
            NotificationService::sendToRole('owner', 'NORMAL',
              "Order {$order->order_number} Selesai",
              "Auto-completed. Estimasi durasi {$order->estimated_duration_hours} jam sudah terlewat."
            );
          });
        }
      });

    // Cek order yang MELEBIHI toleransi (dari system_thresholds.order_completion_tolerance_hours)
    $toleranceHours = SystemThreshold::getValue('order_completion_tolerance_hours', default: 2);

    Order::where('status', 'in_progress')
      ->whereNotNull('scheduled_at')
      ->whereNotNull('estimated_duration_hours')
      ->where('driver_overall_status', '!=', 'all_done')
      ->get()
      ->each(function (Order $order) use ($now, $toleranceHours) {
        $tolerance = Carbon::parse($order->scheduled_at)
          ->addHours($order->estimated_duration_hours + $toleranceHours);

        if ($now->greaterThan($tolerance)) {
          NotificationService::sendToRole('owner', 'ALARM',
            "⚠ Order Melebihi Estimasi — {$order->order_number}",
            "Driver belum tiba di tujuan. Sudah lewat " . ($order->estimated_duration_hours + $toleranceHours) . " jam dari jadwal."
          );
        }
      });
  }
}
```

---

## RINGKASAN SIAPA DAPAT ALARM & KAPAN

| Momen | Gudang | Purchasing | Driver | Dekor | Konsumsi | Pemuka Agama | Consumer | Owner |
|-------|--------|---------|--------|-------|----------|-------------|---------|-------|
| Order masuk | — | — | — | — | — | — | — | — |
| SO konfirmasi | ALARM | ALARM | ❌ tunggu | ALARM | ALARM | ALARM (kandidat #1) | HIGH (dikonfirmasi) | HIGH |
| Gudang siap stok | — | — | ALARM | — | — | — | — | — |
| Driver tiba pickup | — | — | — | — | — | — | HIGH | — |
| Driver tiba tujuan | — | — | — | — | — | — | HIGH | — |
| Order auto-selesai | — | ALARM (cek payment) | — | — | — | — | HIGH (bayar) | NORMAL |
| Consumer upload bukti | — | ALARM (verifikasi) | — | — | — | — | — | — |
| Payment dikonfirmasi | — | — | — | — | — | — | HIGH (lunas) | NORMAL |

---

## ATURAN BISNIS FINAL

```
1. DRIVER tidak pernah dapat alarm sebelum Gudang konfirmasi "Stok Siap"
2. ORDER dinyatakan selesai oleh SISTEM berdasarkan waktu (bukan manual semua tap selesai)
   Kondisi: jam sekarang > scheduled_at + estimated_duration_hours
             DAN driver sudah selesai semua leg (driver_overall_status = all_done)
3. PAYMENT: consumer yang upload bukti. Purchasing yang verifikasi.
   Tidak ada payment auto-confirmed — Purchasing harus lihat foto dan approve.
4. ALARM ke Gudang dan Purchasing berbunyi BERSAMAAN saat SO konfirmasi
   (bukan sequensial, bukan salah satu saja)
5. Gudang alarm: berisi daftar stok yang perlu disiapkan
   Purchasing alarm: berisi info payment tracking + notif jika ada needs_restock
6. Semua foto bukti lapangan (driver, dekor, konsumsi) tersimpan di R2
   dan bisa diakses Consumer, SO, Purchasing, dan Owner via signed URL
7. Consumer bisa upload bukti payment kapan saja setelah order 'completed'
   (tidak ada batas waktu, tapi Purchasing bisa ingatkan via notif manual)
8. Jika consumer tidak upload bukti dalam consumer_payment_reminder_interval_hours (default: 24 jam):
   → Scheduler kirim reminder HIGH ke consumer setiap interval (maks consumer_payment_reminder_max_count kali)
   → Setelah maks reminder: alert ke Purchasing untuk follow up manual
```

## 21. DESIGN SYSTEM — LIQUID GLASS + FLAT COLOR

### Filosofi Desain

Santa Maria menggunakan pendekatan **"Colorful Flat Base + Liquid Glass Surface"**:
- **Background:** Putih bersih (#FFFFFF) sebagai kanvas utama — tidak ada gradien di background
- **Warna:** Palet penuh warna-warni cerah sebagai flat color untuk konten dan aksen
- **Liquid Glass:** Diaplikasikan pada elemen UI "terapung" — card, modal, nav bar, bottom sheet, fab, notifikasi — memberikan efek kaca frosted yang refracts warna di belakangnya
- **Prinsip:** Putih = fondasi tenang. Warna = identitas per role. Glass = kedalaman dan modernitas.

---

### 21.1 Palet Warna (Wajib Diikuti)

```dart
// lib/core/constants/app_colors.dart

class AppColors {
  // ── Background ─────────────────────────────────────────
  static const Color background     = Color(0xFFFFFFFF); // putih murni
  static const Color backgroundSoft = Color(0xFFF8F9FF); // putih dengan hint biru sangat tipis
  static const Color surfaceWhite   = Color(0xFFFFFFFF);

  // ── Brand Utama Santa Maria ─────────────────────────────
  static const Color brandPrimary   = Color(0xFF6C5CE7); // ungu Santa Maria
  static const Color brandSecondary = Color(0xFF00B894); // hijau teal
  static const Color brandAccent    = Color(0xFFE84393); // pink cerah

  // ── Warna per Role (Flat, Saturated) ───────────────────
  static const Color roleConsumer     = Color(0xFF0984E3); // biru cerah
  static const Color roleSO           = Color(0xFF6C5CE7); // ungu
  static const Color roleGudang       = Color(0xFF00B894); // teal
  static const Color rolePurchasing      = Color(0xFF00CEC9); // cyan
  static const Color roleDriver       = Color(0xFF2D3436); // hitam charcoal
  static const Color roleSupplier     = Color(0xFFFDCB6E); // kuning madu
  static const Color roleDekor        = Color(0xFFE84393); // pink
  static const Color roleKonsumsi     = Color(0xFFFF7675); // salmon
  static const Color rolePemukaAgama  = Color(0xFF6D4C41); // cokelat tua
  static const Color roleOwner        = Color(0xFF6C5CE7); // ungu (sama brand)
  static const Color roleHrd          = Color(0xFFE17055); // oranye coral
  static const Color roleSecurity     = Color(0xFF636E72); // abu
  static const Color roleViewer       = Color(0xFFB2BEC3); // abu muda (read-only)

  // ── Status Colors ────────────────────────────────────────
  static const Color statusSuccess  = Color(0xFF00B894);
  static const Color statusWarning  = Color(0xFFFDCB6E);
  static const Color statusDanger   = Color(0xFFD63031);
  static const Color statusInfo     = Color(0xFF0984E3);
  static const Color statusPending  = Color(0xFFB2BEC3);

  // ── Liquid Glass Tints (semitransparent, dipakai dengan BackdropFilter) ──
  static const Color glassPrimary   = Color(0x1A6C5CE7); // ungu 10% opacity
  static const Color glassWhite     = Color(0xB3FFFFFF); // putih 70% opacity
  static const Color glassWhiteSoft = Color(0x80FFFFFF); // putih 50% opacity
  static const Color glassBorder    = Color(0x33FFFFFF); // border glass
  static const Color glassShadow    = Color(0x1A000000); // shadow tipis

  // ── Text ────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFF2D3436);
  static const Color textSecondary  = Color(0xFF636E72);
  static const Color textHint       = Color(0xFFB2BEC3);
  static const Color textOnColor    = Color(0xFFFFFFFF); // teks di atas warna solid
  static const Color textOnGlass    = Color(0xFF2D3436); // teks di atas glass
}
```

---

### 21.2 Liquid Glass — Implementasi Flutter

Gunakan package `liquid_glass_widgets` dari GitHub `sdegenaar/liquid_glass_widgets`
dan sebagai fallback / custom: `BackdropFilter` + `ImageFilter.blur` dari Flutter SDK.

#### Tambahkan ke pubspec.yaml:
```yaml
dependencies:
  liquid_glass_widgets:
    git:
      url: https://github.com/sdegenaar/liquid_glass_widgets.git
      ref: main
  # Alternatif yang sudah di pub.dev:
  glassmorphism: ^3.0.0    # fallback jika liquid_glass_widgets bermasalah
```

#### GlassWidget — Komponen Dasar (Custom, selalu tersedia tanpa package)
```dart
// lib/shared/widgets/glass_widget.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class GlassWidget extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final Color tint;
  final Color borderColor;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double elevation;
  final VoidCallback? onTap;

  const GlassWidget({
    super.key,
    required this.child,
    this.borderRadius = 20.0,
    this.blurSigma = 16.0,
    this.tint = AppColors.glassWhite,
    this.borderColor = AppColors.glassBorder,
    this.padding,
    this.margin,
    this.elevation = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Container(
              padding: padding ?? const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: borderColor, width: 1.0),
                boxShadow: elevation > 0 ? [
                  BoxShadow(
                    color: AppColors.glassShadow,
                    blurRadius: elevation * 4,
                    spreadRadius: elevation,
                    offset: Offset(0, elevation * 2),
                  )
                ] : null,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// Variant dengan warna tint per role
class GlassRoleWidget extends GlassWidget {
  GlassRoleWidget({
    super.key,
    required super.child,
    required Color roleColor,
    super.borderRadius = 20.0,
    super.blurSigma = 16.0,
    super.padding,
    super.margin,
    super.onTap,
  }) : super(
    tint: roleColor.withOpacity(0.12),
    borderColor: roleColor.withOpacity(0.25),
  );
}
```

#### GlassCard — Kartu dengan Efek Glass
```dart
// lib/shared/widgets/glass_card.dart

class GlassCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget? body;
  final Color accentColor;
  final VoidCallback? onTap;
  final EdgeInsets? margin;

  const GlassCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.body,
    this.accentColor = AppColors.brandPrimary,
    this.onTap,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return GlassWidget(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 20,
      blurSigma: 20,
      tint: AppColors.glassWhite,
      borderColor: accentColor.withOpacity(0.20),
      elevation: 4,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Accent bar atas (flat color stripe)
          Container(
            height: 4,
            width: 48,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                      style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      )),
                    if (subtitle != null)
                      Text(subtitle!,
                        style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (body != null) ...[const SizedBox(height: 12), body!],
        ],
      ),
    );
  }
}
```

#### GlassBottomNav — Navigasi Bawah Glass
```dart
// lib/shared/widgets/glass_bottom_nav.dart

class GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<GlassNavItem> items;
  final ValueChanged<int> onTap;
  final Color accentColor;

  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.accentColor = AppColors.brandPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 24,
      right: 24,
      child: GlassWidget(
        borderRadius: 28,
        blurSigma: 30,
        tint: AppColors.glassWhite,
        borderColor: AppColors.glassBorder,
        elevation: 8,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final isActive = currentIndex == i;
            return GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: isActive ? BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ) : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon,
                      color: isActive ? accentColor : AppColors.textSecondary,
                      size: 22),
                    if (isActive) ...[
                      const SizedBox(height: 2),
                      Text(item.label,
                        style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: accentColor)),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class GlassNavItem {
  final IconData icon;
  final String label;
  const GlassNavItem({required this.icon, required this.label});
}
```

#### GlassModal / BottomSheet
```dart
// lib/shared/widgets/glass_modal.dart

// Cara panggil:
// showGlassModal(context, child: YourWidget());

Future<T?> showGlassModal<T>(
  BuildContext context, {
  required Widget child,
  String? title,
  Color accentColor = AppColors.brandPrimary,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: GlassWidget(
          borderRadius: 28,
          blurSigma: 30,
          tint: AppColors.glassWhite,
          borderColor: accentColor.withOpacity(0.20),
          elevation: 12,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textHint,
                    borderRadius: BorderRadius.circular(2)),
                ),
              ),
              if (title != null) ...[
                const SizedBox(height: 16),
                Text(title, style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
              ],
              const SizedBox(height: 16),
              child,
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    ),
  );
}
```

#### GlassButton — Tombol dengan Glass
```dart
// lib/shared/widgets/glass_button.dart

class GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool isOutlined;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  const GlassButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = AppColors.brandPrimary,
    this.isOutlined = false,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  // Tombol solid (flat color — untuk CTA utama)
  const GlassButton.solid({...}) // color solid, teks putih

  // Tombol glass (untuk aksi sekunder)
  const GlassButton.glass({...}) // tint glass, border berwarna

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      // Glass style
      return GlassWidget(
        borderRadius: 14,
        blurSigma: 12,
        tint: color.withOpacity(0.10),
        borderColor: color.withOpacity(0.35),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        onTap: isLoading ? null : onTap,
        child: _buttonContent(color),
      );
    }
    // Solid style (flat color)
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: isFullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: color.withOpacity(0.30), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: _buttonContent(Colors.white),
        ),
      ),
    );
  }

  Widget _buttonContent(Color textColor) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
    children: [
      if (isLoading)
        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: textColor, strokeWidth: 2))
      else ...[
        if (icon != null) ...[Icon(icon, color: textColor, size: 18), const SizedBox(width: 8)],
        Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 15)),
      ],
    ],
  );
}
```

#### GlassAppBar — App Bar Glass
```dart
// lib/shared/widgets/glass_app_bar.dart

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color accentColor;
  final List<Widget>? actions;
  final bool showBack;

  const GlassAppBar({
    super.key,
    required this.title,
    this.accentColor = AppColors.brandPrimary,
    this.actions,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: AppColors.glassWhite,
          child: SafeArea(
            bottom: false,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: accentColor.withOpacity(0.10), width: 0.5)),
              ),
              child: Row(
                children: [
                  if (showBack)
                    GlassWidget(
                      borderRadius: 12, blurSigma: 10,
                      tint: accentColor.withOpacity(0.08),
                      borderColor: accentColor.withOpacity(0.20),
                      padding: const EdgeInsets.all(8),
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.arrow_back_ios_new, size: 16, color: accentColor),
                    ),
                  if (showBack) const SizedBox(width: 12),
                  Expanded(child: Text(title, style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);
}
```

#### GlassAlarmOverlay — Full Screen Alarm
```dart
// lib/shared/widgets/glass_alarm_overlay.dart
// Tampil saat ada order baru (level ALARM)

class GlassAlarmOverlay extends StatefulWidget {
  final String title;
  final String body;
  final Color accentColor;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;
  ...
}

// Implementasi: full screen dengan background blur + GlassWidget di tengah
// Background: warna accentColor dengan opacity 0.15 + BackdropFilter blur 40
// Center card: GlassWidget besar dengan pulsing animation
// Tombol "Buka" = GlassButton.solid (warna accentColor)
// Tombol "Tutup Suara" = GlassButton.glass
```

#### GlassStatusBadge — Badge Status
```dart
// lib/shared/widgets/glass_status_badge.dart

class GlassStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const GlassStatusBadge({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.30), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 4)],
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### 21.3 Tema Global (MaterialApp ThemeData)

```dart
// lib/app.dart

ThemeData buildTheme() => ThemeData(
  useMaterial3: true,
  fontFamily: 'Inter', // tambahkan Inter font ke pubspec.yaml (Google Fonts)
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.brandPrimary,
    brightness: Brightness.light,
    background: AppColors.background,
    surface: AppColors.surfaceWhite,
    primary: AppColors.brandPrimary,
    secondary: AppColors.brandSecondary,
  ),

  // AppBar — transparan, teks gelap, shadow minimal
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleTextStyle: TextStyle(
      fontFamily: 'Inter', fontSize: 18,
      fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    iconTheme: IconThemeData(color: AppColors.textPrimary),
  ),

  // Card — tidak pakai Material Card, pakai GlassCard kustom
  cardTheme: const CardThemeData(
    color: Colors.transparent, elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20)))),

  // BottomNav — transparan, pakai GlassBottomNav kustom
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.transparent, elevation: 0,
    selectedItemColor: AppColors.brandPrimary,
    unselectedItemColor: AppColors.textSecondary),

  // Input Field — clean, minimal
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.backgroundSoft,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.textHint, width: 1)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.textHint.withOpacity(0.5), width: 1)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.brandPrimary, width: 2)),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.statusDanger, width: 1)),
    hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
    labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),

  // ElevatedButton — flat color solid
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.brandPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),

  // Text styles global
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5),
    headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.5),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.5),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textHint, letterSpacing: 0.5)),
);
```

---

### 21.4 Struktur Layout Per Screen

Semua screen mengikuti template ini:

```dart
// Template screen dengan background putih + konten glass

Scaffold(
  backgroundColor: AppColors.background,   // PUTIH
  extendBodyBehindAppBar: true,
  appBar: GlassAppBar(title: '...', accentColor: roleColor),

  body: Stack(
    children: [
      // 1. Background color blobs (dekorasi flat color — bukan gradient)
      Positioned(top: -60, right: -60,
        child: Container(
          width: 200, height: 200,
          decoration: BoxDecoration(
            color: roleColor.withOpacity(0.08),  // flat color, soft
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(bottom: 100, left: -40,
        child: Container(
          width: 150, height: 150,
          decoration: BoxDecoration(
            color: AppColors.brandSecondary.withOpacity(0.06),
            shape: BoxShape.circle,
          ),
        ),
      ),

      // 2. Konten utama
      SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // 100 untuk nav
          children: [
            // GlassCard, GlassWidget, dll
          ],
        ),
      ),

      // 3. Glass Bottom Nav (floating)
      GlassBottomNav(
        currentIndex: _tab,
        accentColor: roleColor,
        items: [...],
        onTap: (i) => setState(() => _tab = i),
      ),
    ],
  ),
);
```

---

### 21.5 Warna Aksen per Role (Liquid Glass Tint)

Setiap role punya warna aksen sendiri. Glass card, nav, dan badge menggunakan warna ini sebagai tint:

| Role | Warna Aksen | Hex | Konstanta AppColors |
|------|-------------|-----|---------------------|
| Konsumen | Biru cerah | #0984E3 | `roleConsumer` |
| Service Officer | Ungu | #6C5CE7 | `roleSO` |
| Gudang | Teal | #00B894 | `roleGudang` |
| Purchasing | Cyan | #00CEC9 | `rolePurchasing` |
| Driver | Charcoal | #2D3436 | `roleDriver` |
| Supplier | Kuning madu | #FDCB6E | `roleSupplier` |
| Dekor | Pink magenta | #E84393 | `roleDekor` |
| Konsumsi | Salmon | #FF7675 | `roleKonsumsi` |
| Pemuka Agama | Cokelat tua | #6D4C41 | `rolePemukaAgama` |
| Owner | Ungu brand | #6C5CE7 | `roleOwner` |
| HRD | Oranye coral | #E17055 | `roleHrd` |
| Super Admin | Merah | #D63031 | `statusDanger` |
| Security | Abu | #636E72 | `roleSecurity` |
| Viewer | Abu muda | #B2BEC3 | `roleViewer` |

Contoh penggunaan di screen driver:
```dart
// Semua elemen glass di Driver screen menggunakan AppColors.roleDriver (#2D3436)
GlassAppBar(accentColor: AppColors.roleDriver)
GlassBottomNav(accentColor: AppColors.roleDriver)
GlassCard(accentColor: AppColors.roleDriver)
GlassStatusBadge(color: AppColors.roleDriver)
```

---

### 21.6 Aturan Desain — WAJIB DIIKUTI

```
DO:
✅ Background scaffold selalu Color(0xFFFFFFFF) — putih murni
✅ Warna saturated (cerah) untuk flat color elemen: ikon, badge, tombol utama, accent bar
✅ BackdropFilter.blur pada semua komponen "terapung": card, modal, nav, fab, notif
✅ borderRadius minimal 14 untuk semua komponen, 20-28 untuk card dan modal
✅ Shadow tipis dan soft: color.withOpacity(0.15-0.25), blurRadius 12-20
✅ Font 'Inter' untuk semua teks
✅ Animasi dengan duration 200-300ms, curve: Curves.easeInOut
✅ RepaintBoundary di sekeliling BackdropFilter yang berat untuk performa
✅ Fallback: jika device tidak support blur (very old Android), gunakan tint solid tanpa BackdropFilter

DON'T:
❌ Jangan pakai gradien di background utama (hanya warna solid/flat)
❌ Jangan pakai warna gelap sebagai background scaffold
❌ Jangan blur terlalu banyak (maks 3-4 BackdropFilter bertumpuk dalam satu screen)
❌ Jangan pakai shadow tebal atau border radius kecil (<8)
❌ Jangan pakai warna abu sebagai warna utama konten (hanya untuk teks secondary/hint)
❌ Jangan pakai Cupertino widgets bawaan Flutter — custom glass widgets lebih baik
❌ Jangan stack BackdropFilter di atas BackdropFilter (parah untuk performa)
```

---

### 21.7 Contoh Implementasi per Screen

#### Consumer Home (roleColor = #0984E3 biru)
- Background: putih (#FFFFFF)
- Decorative blob: biru 8% opacity, kanan atas
- App bar: GlassAppBar biru
- Header card: GlassWidget besar, tint biru 10%, sambutan + nama user
- List order: GlassCard per item, accent bar biru
- FAB chatbot: GlassButton.solid biru, ikon chat
- Bottom nav: GlassBottomNav biru floating

#### Driver Navigation (roleColor = #2D3436 charcoal)
- Background: putih (#FFFFFF)
- Map Google Maps di background (bukan scaffold color)
- Semua overlay: GlassWidget di atas peta — info order, ETA, tombol status
- Status chip: GlassStatusBadge
- Bottom panel: GlassModal dengan detail rute

#### Supplier Catalog (roleColor = #FDCB6E kuning madu)
- Background: putih
- Blob dekorasi: kuning madu 6% opacity
- List permintaan: GlassCard per item
- Harga badge: GlassStatusBadge hijau/kuning/merah berdasarkan AI result
- Tombol "Ajukan Penawaran": GlassButton.solid kuning
- Filter/sort: GlassWidget horizontal scroll chips

#### Owner Dashboard (roleColor = #6C5CE7 ungu)
- Background: putih
- Semua metric card: GlassCard dengan angka besar + flat color ikon
- Alert badge merah: GlassStatusBadge merah pulsing
- Map semua driver: peta di GlassWidget full width
- Laporan AI: GlassModal dengan narasi teks

---

### 21.8 Aksesibilitas — Fallback Blur

```dart
// Deteksi apakah device support BackdropFilter
// Tambahkan di main.dart

bool get shouldUseBlur {
  // Android < 8.0 (API 26) tidak support BackdropFilter dengan baik
  // Gunakan solid tint sebagai fallback
  if (Platform.isAndroid) {
    return androidVersion >= 26;
  }
  return true;
}

// Di GlassWidget, gunakan conditional:
Widget build(BuildContext context) {
  final useBlur = context.watch<AppSettingsProvider>().shouldUseBlur;
  
  final container = Container(
    decoration: BoxDecoration(
      color: useBlur ? tint : tint.withOpacity(0.95), // lebih opaque jika no blur
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: 1.0),
    ),
    child: child,
  );

  if (!useBlur) return ClipRRect(borderRadius: BorderRadius.circular(borderRadius), child: container);
  
  return ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
      child: container,
    ),
  );
}
```

---

### 21.9 Tambahan pubspec.yaml untuk Design System

```yaml
dependencies:
  # Font
  google_fonts: ^6.2.1       # untuk Inter font
  
  # Liquid Glass / Glass Effect
  liquid_glass_widgets:
    git:
      url: https://github.com/sdegenaar/liquid_glass_widgets.git
      ref: main
  
  # Animasi
  flutter_animate: ^4.5.0    # animasi masuk-keluar elemen yang fluid
  
  # Ikon yang lebih kaya
  hugeicons: ^0.0.7           # ikon modern yang cocok dengan desain flat+glass

# Fonts
flutter:
  fonts:
    - family: Inter
      fonts:
        - asset: fonts/Inter-Regular.ttf
          weight: 400
        - asset: fonts/Inter-Medium.ttf
          weight: 500
        - asset: fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: fonts/Inter-Bold.ttf
          weight: 700
        - asset: fonts/Inter-ExtraBold.ttf
          weight: 800
```


---


---

## 22. SISTEM STOK TERINTEGRASI DENGAN ORDER

### Konsep Utama
Setiap order yang masuk dengan paket tertentu **otomatis memengaruhi stok gudang**. Stok berkurang saat order diapprove. Jika stok di bawah minimum, Gudang dan Purchasing langsung dapat notifikasi. Tidak ada pengecekan manual.

### 22.1 Alur Stok per Order

```
Order dibuat (Consumer input paket) 
  ↓
SO konfirmasi paket (package_id final)
  ↓
SO tekan "Konfirmasi Order" (PUT /so/orders/{id}/confirm)
  ↓ [otomatis di background]
  ├── Sistem baca package_items dari paket yang dipilih
  ├── Cek stok setiap item di stock_items
  ├── Jika cukup → deduct stok (buat stock_transaction type='out')
  ├── Jika TIDAK cukup → order tetap dikonfirmasi TAPI:
  │     → Flag `needs_restock` = true pada order
  │     → Alert ke Gudang: "Stok [item] kurang untuk order [nomor]"
  │     → Gudang wajib buat PO atau e-Katalog request sebelum eksekusi
  └── Setelah deduct: cek apakah current_quantity < minimum_quantity
        → Jika ya: notifikasi LOW STOCK ke Gudang + Purchasing
```

### 22.2 Tambahan di Tabel `orders`

```sql
-- Tambahkan kolom berikut ke tabel orders:
needs_restock BOOLEAN DEFAULT FALSE          -- ada item stok kurang saat approve
restock_notes TEXT NULLABLE                  -- catatan item apa saja yang kurang
stock_deducted_at TIMESTAMP NULLABLE         -- waktu stok berhasil dikurangi
```

### 22.3 Tambahan di Tabel `package_items`

```sql
-- Tambahkan kolom berikut ke tabel package_items:
stock_item_id UUID NULLABLE REFERENCES stock_items(id)  
-- FK ke stock_items — jika NULL, item ini tidak menggunakan stok gudang
-- (misal: item non-fisik seperti "koordinasi pemuka agama")
deduct_quantity DECIMAL(10,2) NOT NULL DEFAULT 1
-- jumlah stok yang dikurangi per 1 unit paket (bisa desimal untuk bahan habis pakai)
```

### 22.4 Tabel `order_stock_deductions` (Audit Pengurangan Stok per Order)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
order_id UUID REFERENCES orders(id)
stock_item_id UUID REFERENCES stock_items(id)
package_item_id UUID REFERENCES package_items(id)
deducted_quantity DECIMAL(10,2) NOT NULL    -- jumlah yang dikurangi
stock_before DECIMAL(10,2) NOT NULL         -- stok sebelum dikurangi
stock_after DECIMAL(10,2) NOT NULL          -- stok sesudah dikurangi
is_sufficient BOOLEAN NOT NULL              -- apakah stok cukup saat deduct
deducted_by UUID REFERENCES users(id)       -- SO yang konfirmasi order
deducted_at TIMESTAMP NOT NULL DEFAULT NOW()
notes TEXT NULLABLE
created_at TIMESTAMP
```

### 22.5 Tabel `stock_alerts` (Notifikasi Stok)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
stock_item_id UUID REFERENCES stock_items(id)
order_id UUID NULLABLE REFERENCES orders(id)
alert_type ENUM('low_stock','out_of_stock','restock_needed') NOT NULL
current_quantity DECIMAL(10,2) NOT NULL
minimum_quantity DECIMAL(10,2) NOT NULL
message TEXT NOT NULL
is_resolved BOOLEAN DEFAULT FALSE
resolved_by UUID NULLABLE REFERENCES users(id)
resolved_at TIMESTAMP NULLABLE
created_at TIMESTAMP
```

### 22.6 Implementasi Backend — StockManagementService

```php
// app/Services/StockManagementService.php

class StockManagementService {

  /**
   * Dipanggil saat SO konfirmasi order (PUT /so/orders/{id}/confirm).
   * Cek stok, deduct jika cukup, flag jika tidak cukup.
   */
  public function processOrderConfirmation(Order $order): array {
    if (!$order->package_id) return ['success' => true, 'needs_restock' => false];

    $packageItems = PackageItem::where('package_id', $order->package_id)
                               ->whereNotNull('stock_item_id')
                               ->with('stockItem')
                               ->get();

    $insufficientItems = [];
    $deductions = [];

    DB::transaction(function () use ($packageItems, $order, &$insufficientItems, &$deductions) {
      foreach ($packageItems as $pkgItem) {
        $stockItem = $pkgItem->stockItem;
        $needed = $pkgItem->deduct_quantity;
        $before = $stockItem->current_quantity;
        $isSufficient = $before >= $needed;

        if ($isSufficient) {
          // Kurangi stok
          $stockItem->decrement('current_quantity', $needed);
          $after = $before - $needed;

          // Buat stock_transaction
          StockTransaction::create([
            'stock_item_id' => $stockItem->id,
            'order_id' => $order->id,
            'type' => 'out',
            'quantity' => $needed,
            'notes' => "Auto-deduct untuk order {$order->order_number}",
            'user_id' => $order->so_user_id,
          ]);

          // Audit deduction
          OrderStockDeduction::create([
            'order_id' => $order->id,
            'stock_item_id' => $stockItem->id,
            'package_item_id' => $pkgItem->id,
            'deducted_quantity' => $needed,
            'stock_before' => $before,
            'stock_after' => $after,
            'is_sufficient' => true,
            'deducted_by' => $order->so_user_id,
          ]);

          // Cek low stock setelah deduct
          $stockItem->refresh();
          if ($stockItem->current_quantity < $stockItem->minimum_quantity) {
            $this->createLowStockAlert($stockItem, $order->id);
          }
        } else {
          // Stok tidak cukup — catat tapi jangan batalkan order
          $insufficientItems[] = [
            'item_name' => $stockItem->item_name,
            'needed' => $needed,
            'available' => $before,
            'shortage' => $needed - $before,
          ];

          OrderStockDeduction::create([
            'order_id' => $order->id,
            'stock_item_id' => $stockItem->id,
            'package_item_id' => $pkgItem->id,
            'deducted_quantity' => 0,
            'stock_before' => $before,
            'stock_after' => $before,
            'is_sufficient' => false,
            'deducted_by' => $order->so_user_id,
            'notes' => "Stok tidak cukup. Dibutuhkan {$needed}, tersedia {$before}",
          ]);

          // Alert out of stock
          $this->createStockAlert($stockItem, $order->id, 'restock_needed',
            "Stok {$stockItem->item_name} tidak cukup untuk order {$order->order_number}. "
            . "Dibutuhkan {$needed} {$stockItem->unit}, tersedia {$before} {$stockItem->unit}."
          );
        }
      }

      // Update order jika ada item kurang
      if (!empty($insufficientItems)) {
        $notes = collect($insufficientItems)->map(fn($i) =>
          "• {$i['item_name']}: butuh {$i['needed']}, tersedia {$i['available']} (kurang {$i['shortage']})"
        )->join("\n");

        $order->update([
          'needs_restock' => true,
          'restock_notes' => $notes,
        ]);
      } else {
        $order->update([
          'stock_deducted_at' => now(),
        ]);
      }
    });

    // Kirim notifikasi jika ada stok kurang
    if (!empty($insufficientItems)) {
      $itemList = collect($insufficientItems)->pluck('item_name')->join(', ');
      NotificationService::sendToRole('gudang', 'HIGH',
        'Stok Kurang — Order ' . $order->order_number,
        "Item berikut stoknya tidak cukup: {$itemList}. Segera buat PO atau e-Katalog."
      );
      NotificationService::sendToRole('purchasing', 'HIGH',
        'Perlu Pengadaan Stok',
        "Order {$order->order_number} membutuhkan restock: {$itemList}"
      );
      NotificationService::sendToRole('owner', 'NORMAL',
        'Info Stok Order',
        "Order {$order->order_number} diapprove dengan catatan: stok {$itemList} perlu diisi ulang."
      );
    }

    return [
      'success' => true,
      'needs_restock' => !empty($insufficientItems),
      'insufficient_items' => $insufficientItems,
    ];
  }

  /**
   * Cek ketersediaan stok SEBELUM SO konfirmasi (preview untuk SO).
   * Tidak melakukan deduct — hanya cek dan tampilkan warning.
   */
  public function checkStockAvailability(Order $order): array {
    if (!$order->package_id) return ['all_sufficient' => true, 'items' => []];

    $packageItems = PackageItem::where('package_id', $order->package_id)
                               ->whereNotNull('stock_item_id')
                               ->with('stockItem')
                               ->get();

    $items = $packageItems->map(fn($pkgItem) => [
      'item_name' => $pkgItem->stockItem->item_name,
      'unit' => $pkgItem->stockItem->unit,
      'needed' => $pkgItem->deduct_quantity,
      'available' => $pkgItem->stockItem->current_quantity,
      'is_sufficient' => $pkgItem->stockItem->current_quantity >= $pkgItem->deduct_quantity,
      'shortage' => max(0, $pkgItem->deduct_quantity - $pkgItem->stockItem->current_quantity),
    ])->toArray();

    return [
      'all_sufficient' => collect($items)->every(fn($i) => $i['is_sufficient']),
      'items' => $items,
    ];
  }

  /**
   * Kembalikan stok saat order dibatalkan.
   */
  public function reverseOrderDeductions(Order $order): void {
    $deductions = OrderStockDeduction::where('order_id', $order->id)
                                     ->where('is_sufficient', true)
                                     ->get();
    DB::transaction(function () use ($deductions, $order) {
      foreach ($deductions as $deduction) {
        $stockItem = StockItem::find($deduction->stock_item_id);
        $stockItem->increment('current_quantity', $deduction->deducted_quantity);

        StockTransaction::create([
          'stock_item_id' => $stockItem->id,
          'order_id' => $order->id,
          'type' => 'in',
          'quantity' => $deduction->deducted_quantity,
          'notes' => "Pengembalian stok dari pembatalan order {$order->order_number}",
          'user_id' => auth()->id(),
        ]);
      }
    });
  }

  private function createLowStockAlert(StockItem $item, ?string $orderId): void {
    // Cek apakah alert low stock untuk item ini sudah ada dan belum resolved
    $exists = StockAlert::where('stock_item_id', $item->id)
                        ->where('alert_type', 'low_stock')
                        ->where('is_resolved', false)
                        ->exists();
    if ($exists) return; // Jangan duplikat alert

    StockAlert::create([
      'stock_item_id' => $item->id,
      'order_id' => $orderId,
      'alert_type' => 'low_stock',
      'current_quantity' => $item->current_quantity,
      'minimum_quantity' => $item->minimum_quantity,
      'message' => "Stok {$item->item_name} hampir habis: {$item->current_quantity} {$item->unit} (minimum: {$item->minimum_quantity} {$item->unit})",
    ]);

    NotificationService::sendToRole('gudang', 'HIGH',
      'Stok Hampir Habis',
      "{$item->item_name}: tersisa {$item->current_quantity} {$item->unit}"
    );
    NotificationService::sendToRole('purchasing', 'NORMAL',
      'Info Stok Rendah',
      "{$item->item_name} hampir habis. Pertimbangkan pengadaan."
    );
  }

  private function createStockAlert(StockItem $item, ?string $orderId, string $type, string $message): void {
    StockAlert::create([
      'stock_item_id' => $item->id,
      'order_id' => $orderId,
      'alert_type' => $type,
      'current_quantity' => $item->current_quantity,
      'minimum_quantity' => $item->minimum_quantity,
      'message' => $message,
    ]);
  }
}
```

### 22.7 Integrasi ke SO Konfirmasi Order

```php
// app/Http/Controllers/ServiceOfficer/OrderController.php
// Tambahkan di method confirm():

public function confirm(Request $request, Order $order) {
  // ... validasi, cek konflik jadwal driver/mobil ...

  DB::transaction(function () use ($request, $order) {
    $order->update([
      'status' => 'confirmed',
      'scheduled_at' => $request->scheduled_at,
      'estimated_duration_hours' => $request->estimated_duration_hours,
      'package_id' => $request->package_id,
      'so_user_id' => auth()->id(),
      'confirmed_at' => now(),
    ]);

    OrderStatusLog::create([...]);

    // PROSES STOK — otomatis saat SO konfirmasi
    $stockResult = app(StockManagementService::class)->processOrderConfirmation($order);

    // Distribusi task ke semua pihak (sudah ada sebelumnya)
    dispatch(new NotifyGudang($order));
    dispatch(new NotifyDriver($order));
    dispatch(new NotifyDekor($order));
    dispatch(new NotifyKonsumsi($order));
    dispatch(new ProcessPemukaAgamaAssignment($order));
    dispatch(new GenerateOrderInvoice($order));
    dispatch(new GenerateOrderChecklist($order));
  });

  return response()->json([
    'success' => true,
    'data' => $order->fresh(),
    'message' => 'Order dikonfirmasi. ' . 
      ($order->needs_restock ? 'PERHATIAN: Ada item stok yang perlu diisi ulang.' : 'Semua stok tersedia.')
  ]);
}
```

### 22.8 Preview Stok di Screen SO (Flutter)

```dart
// Di order_confirm_screen.dart, sebelum tombol "Konfirmasi" ditampilkan:
// Panggil GET /so/orders/{id}/stock-check untuk preview ketersediaan stok

// Endpoint: GET /so/orders/{id}/stock-check
// Response:
// {
//   "all_sufficient": false,
//   "items": [
//     { "item_name": "Kain Kafan", "needed": 3, "available": 5, "is_sufficient": true },
//     { "item_name": "Bunga Mawar", "needed": 10, "available": 2, "is_sufficient": false, "shortage": 8 },
//   ]
// }

// UI: Tampilkan GlassCard dengan daftar item dan status
// Item cukup: GlassStatusBadge hijau "Tersedia"
// Item kurang: GlassStatusBadge merah "Kurang X unit"
// Jika ada yang kurang: warning banner "⚠ Ada item stok kurang. Order tetap bisa dikonfirmasi,
//                        Gudang akan mendapat notif untuk restock."
// Tombol Konfirmasi tetap aktif — SO tidak diblokir
```

### 22.9 Dashboard Stok di Gudang (Flutter)

```dart
// gudang/screens/stock_screen.dart — tambahkan section:
// "Alert Stok" di bagian atas — GlassCard merah jika ada stock_alerts yang belum resolved
// Setiap alert: nama item, stok sekarang, stok minimum, order terkait
// Tombol "Buat PO" atau "Buat Permintaan e-Katalog" langsung dari alert card
// Setelah PO/e-Katalog dibuat, Gudang bisa mark alert sebagai "Resolved"

// Endpoint baru:
// GET  /gudang/stock-alerts            -- list alert yang belum resolved
// PUT  /gudang/stock-alerts/{id}/resolve -- tandai selesai
// GET  /gudang/orders/{id}/stock-deductions -- riwayat deductions untuk 1 order
```

### 22.10 Endpoint Baru untuk Stok Order

```
-- Service Officer
GET    /so/orders/{id}/stock-check         -- preview stok sebelum konfirmasi (no deduct)

-- Gudang  
GET    /gudang/stock-alerts                -- semua alert stok aktif
PUT    /gudang/stock-alerts/{id}/resolve   -- tandai alert selesai
GET    /gudang/orders/{id}/stock-deductions -- riwayat deductions per order
GET    /gudang/stock/low                   -- list item di bawah minimum_quantity

-- Owner
GET    /owner/stock/alerts                 -- semua alert stok (monitoring)
GET    /owner/stock/summary                -- ringkasan: total item, berapa di bawah minimum
```

### 22.11 Setting Stok di Master Data Paket

```
-- Super Admin bisa mengkonfigurasi (v1.27: Owner view only):
-- Setiap PackageItem di katalog paket memiliki:
--   stock_item_id → link ke item stok fisik di gudang
--   deduct_quantity → berapa yang dikurangi per 1 order dengan paket ini

-- Contoh Paket A:
-- PackageItem 1: "Kain Kafan" → stock_item_id: uuid_kain_kafan, deduct_quantity: 3
-- PackageItem 2: "Bunga Papan" → stock_item_id: uuid_bunga_papan, deduct_quantity: 1
-- PackageItem 3: "Koordinasi Pemuka Agama" → stock_item_id: NULL (tidak dari stok fisik)
-- PackageItem 4: "Dokumentasi Foto" → stock_item_id: NULL (service, bukan barang fisik)

-- Endpoint untuk manage:
PUT /super-admin/package-items/{id}    -- set stock_item_id dan deduct_quantity
GET /gudang/packages/{id}/stock-check  -- cek ketersediaan stok untuk paket tertentu
```

### 22.12 Aturan Bisnis Stok

```
1. Stok berkurang OTOMATIS saat SO konfirmasi order — tidak perlu input manual Gudang
2. Jika stok tidak cukup → order TETAP DIKONFIRMASI (tidak diblokir), tapi:
   → needs_restock = true di order
   → Alert otomatis ke Gudang dan Purchasing
   → Gudang wajib buat PO atau e-Katalog sebelum eksekusi lapangan
3. Jika order DIBATALKAN → stok dikembalikan (reverse deduction)
4. Low stock threshold = minimum_quantity di setiap stock_item (bisa diset berbeda per item)
5. Saat stok item melewati minimum setelah deduction → 1 alert per item per kondisi (tidak spam)
6. Gudang bisa manual adjust stok kapan saja (PUT /gudang/stock/{id}) — untuk input barang masuk dari PO
7. Add-On layanan juga bisa punya stock_item_id sendiri jika Add-On berbentuk barang fisik
8. Laporan harian AI (#14) sudah include ringkasan alert stok hari itu
```

---


---


---


---


---

# SANTA MARIA — PATCH v1.14
# Sinkronisasi Form Fisik: Workshop Peti, Peralatan, Presensi, Konsumabel Harian, Akta, Laporan Tagihan

---

## LATAR BELAKANG v1.14

Patch ini mendigitalisasi **19 form fisik** yang saat ini masih diisi manual di operasional Santa Maria. Semua form dianalisis dari dokumen asli dan dipetakan ke dalam sistem digital tanpa mengurangi integritas proses yang sudah berjalan.

---

## PERUBAHAN FUNDAMENTAL v1.14

1. **Modul Workshop Peti** — Produksi peti (busa, melamin, duco) kini terintegrasi sebagai sub-modul Gudang. Form Busa Eropa, Pengerjaan Melamin, dan Pengerjaan Duco masuk ke dalam alur `coffin_orders`.
2. **Role Baru: `tukang_foto`** — Fotografer mendapat akun app sendiri (vendor-like, mirip `dekor`) dengan sistem presensi digital.
3. **Sistem Presensi Digital** — Presensi tukang foto dan pekerja lapangan lainnya tercatat di tabel `field_attendances`, ditandatangani digital oleh PIC keluarga/SO.
4. **Manajemen Peralatan Diperkaya** — Tracking KIRIM/TERIMA/KEMBALI per item peralatan per order, termasuk `Pinjaman Peralatan Peringatan` untuk misa arwah/peringatan.
5. **Data Barang Harian (Shift P/K/M)** — Konsumabel harian dicatat per shift (Pagi/Kirim/Malam) per order, terintegrasi dengan stok gudang.
6. **Formulir Pengambilan & Pengembalian Barang** — Digitalisasi form gudang dengan kode SKU per item, terhubung ke `stock_transactions`.
7. **Laporan Tagihan 26 Item** — Seluruh 26 item tagihan standar tersinkronisasi dengan `order_billing_items` per order.
8. **Nota Pemakaian Mobil Jenazah** — Log KM per perjalanan terintegrasi ke vehicle management (v1.12).
9. **Formulir Isi Paket La Fiore** — Budget vs biaya aktual bunga/dekorasi dengan tracking multi-supplier.
10. **Tanda Terima Berkas Akta Kematian** — Checklist 20 dokumen legal, dua pihak (Santa Maria & Keluarga).
11. **Persetujuan Tambahan di Luar Paket** — Form approval biaya di luar paket dengan tanda tangan digital keluarga.

---

## ROLE BARU — `tukang_foto`

Ditambahkan ke tabel `users` sebagai role ke-15.

```
Role ID    : tukang_foto
Nama Role  : Tukang Foto / Dokumentasi
Tipe       : Vendor (Eksternal)
Fungsi     : Dokumentasi lapangan, konfirmasi hadir, upload hasil foto per order
Akses App  : Mirip dengan role `dekor` — menerima assignment, konfirmasi hadir, upload bukti
Warna Aksen: #6C5CE7 (ungu muda — berbeda dari SO yang deep ungu)
```

Tambahkan ke `AppColors`:
```dart
static const Color roleTukangFoto = Color(0xFF9B59B6); // ungu anggur
```

Tambahkan ke route guard:
```dart
case 'tukang_foto': → VendorHome  // accentColor: AppColors.roleTukangFoto
```

Tambahkan akun test:
| Role | Nama | Email | Password |
|------|------|-------|----------|
| tukang_foto | Benny Fotografer | foto@santamaria.id | foto1234 |

---

## DATABASE — TABEL BARU v1.14

### Tabel `coffin_orders` (Workshop Peti)

Form fisik: Form Busa Eropa, Surat Order Peti.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
coffin_order_number VARCHAR(50) UNIQUE NOT NULL  -- contoh: PTI-20241025-0001
order_id UUID NULLABLE REFERENCES orders(id)    -- jika terkait order konsumen
nama_pemesan VARCHAR(255) NULLABLE               -- nama keluarga / pemberi order
kode_peti VARCHAR(100) NOT NULL                  -- kode identifikasi fisik peti
ukuran VARCHAR(50) NULLABLE                      -- panjang × lebar × tinggi (cm)
warna VARCHAR(100) NULLABLE                      -- warna finishing yang diminta

finishing_type VARCHAR(50) NOT NULL DEFAULT 'melamin'  -- extensible: 'melamin','duco','natural', dll (sesuai coffin_stage_master)
status ENUM(
  'draft',         -- order baru dibuat
  'busa_process',  -- sedang pengerjaan busa
  'busa_done',     -- busa selesai, siap amplas
  'amplas_process',-- sedang proses amplas & finishing
  'amplas_done',   -- finishing selesai
  'qc_pending',    -- menunggu QC
  'qc_passed',     -- lolos QC, siap kirim/gunakan
  'qc_failed',     -- gagal QC, dikembalikan ke pengerjaan
  'delivered'      -- sudah dikirim/digunakan di order
) DEFAULT 'draft'

pemberi_order_id UUID NULLABLE REFERENCES users(id)   -- SO / Gudang yang buat order
tukang_busa_name VARCHAR(255) NULLABLE                -- nama (tidak perlu akun app)
tukang_amplas_name VARCHAR(255) NULLABLE
tukang_finishing_name VARCHAR(255) NULLABLE
qc_officer_id UUID NULLABLE REFERENCES users(id)      -- Gudang atau SO yang QC

mulai_busa DATE NULLABLE
selesai_busa DATE NULLABLE
mulai_finishing DATE NULLABLE
selesai_finishing DATE NULLABLE
qc_date DATE NULLABLE
qc_notes TEXT NULLABLE
-- QC criteria disimpan di coffin_qc_results (relasi ke coffin_qc_criteria_master)

notes TEXT NULLABLE
created_at TIMESTAMP
updated_at TIMESTAMP
```

### Tabel `coffin_stage_master` (Master Tahap Pengerjaan Peti)

Tahap pengerjaan TIDAK di-hardcode — dikelola sebagai master data. Saat coffin order dibuat, sistem menyalin tahap dari master sesuai `finishing_type`.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
finishing_type VARCHAR(50) NOT NULL           -- 'melamin', 'duco', 'natural', dsb (extensible)
stage_number SMALLINT NOT NULL
stage_name VARCHAR(100) NOT NULL
is_active BOOLEAN DEFAULT TRUE
created_at TIMESTAMP
updated_at TIMESTAMP

UNIQUE(finishing_type, stage_number)
```

Initial seed (dapat ditambah/diubah via UI):
```
melamin | 1: Amplas Tank | 2: Amplas 100 | 3: Amplas 240 | 4: Filler
melamin | 5: Amplas 240+service | 6: Sending | 7: Amplas 240 | 8: Sending+warna | 9: Amplas 360 | 10: Gloss

duco    | 1: Amplas Tank | 2: Epoxy | 3: Dempul | 4: Amplas 100 | 5: Amplas 240
duco    | 6: Epoxy | 7: Service + Amplas 360 | 8: Cat | 9: Amplas 1000 | 10: Gloss | 11: Compound
```

### Tabel `coffin_order_stages` (Tahap Pengerjaan Peti per Order)

Form fisik: Pengerjaan Melamin (10 tahap) & Pengerjaan Duco (11 tahap).
Di-generate otomatis dari `coffin_stage_master` saat coffin order dibuat.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
coffin_order_id UUID REFERENCES coffin_orders(id)
stage_master_id UUID REFERENCES coffin_stage_master(id)
stage_number SMALLINT NOT NULL               -- disalin dari master (memungkinkan re-order per order)
stage_name VARCHAR(100) NOT NULL             -- disalin dari master (memungkinkan rename per order)
is_completed BOOLEAN DEFAULT FALSE
completed_at TIMESTAMP NULLABLE
completed_by_name VARCHAR(255) NULLABLE      -- nama tukang yang menyelesaikan tahap ini
notes TEXT NULLABLE
created_at TIMESTAMP
```

### Tabel `coffin_qc_criteria_master` (Master Kriteria QC Peti)

Kriteria QC TIDAK di-hardcode — dikelola sebagai master data.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
criteria_code VARCHAR(50) UNIQUE NOT NULL     -- contoh: 'MENGKILAP', 'WARNA_RATA'
criteria_name VARCHAR(255) NOT NULL           -- contoh: 'Mengkilap', 'Warna Rata'
finishing_type VARCHAR(50) NULLABLE           -- NULL = berlaku semua, 'melamin'/'duco' = spesifik
sort_order INTEGER DEFAULT 0
is_active BOOLEAN DEFAULT TRUE
created_at TIMESTAMP
updated_at TIMESTAMP
```

Initial seed (dapat ditambah/diubah via UI):
```
MENGKILAP           | Mengkilap              | NULL (semua)
WARNA_RATA          | Warna Rata             | NULL
TIDAK_MELELEH       | Tidak Meleleh          | duco
SAMBUNGAN_RAPI      | Sambungan Rapi         | NULL
SERAT_TIDAK_BERLUBANG | Serat Tidak Berlubang | NULL
MODEL_LENGKUNG_RAPI | Model Lengkung Rapi    | NULL
```

### Tabel `coffin_qc_results` (Hasil QC per Coffin Order)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
coffin_order_id UUID REFERENCES coffin_orders(id) ON DELETE CASCADE
criteria_master_id UUID REFERENCES coffin_qc_criteria_master(id)
is_passed BOOLEAN DEFAULT FALSE
notes VARCHAR(255) NULLABLE
created_at TIMESTAMP

UNIQUE(coffin_order_id, criteria_master_id)
```

---

### Tabel `field_attendances` (Presensi Pekerja Lapangan)

Form fisik: Presensi Tukang Foto Santa Maria.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
order_id UUID REFERENCES orders(id)
user_id UUID REFERENCES users(id)             -- tukang_foto, dekor, konsumsi, pemuka_agama
role VARCHAR(50) NOT NULL                     -- snapshot role saat presensi dicatat

-- Detail kehadiran
attendance_date DATE NOT NULL
kegiatan VARCHAR(255) NOT NULL                -- nama kegiatan / sesi (misal: "Misa Pemberkatan", "Prosesi")
scheduled_jam TIME NULLABLE                  -- jam yang dijadwalkan
arrived_at TIMESTAMP NULLABLE                -- jam tiba aktual
departed_at TIMESTAMP NULLABLE               -- jam pulang aktual

status ENUM(
  'scheduled',    -- dijadwalkan hadir
  'present',      -- hadir, dikonfirmasi
  'absent',       -- tidak hadir
  'late'          -- hadir tapi terlambat (arrived_at > scheduled_jam + threshold)
) DEFAULT 'scheduled'

-- Tanda tangan digital
pic_confirmed BOOLEAN DEFAULT FALSE          -- PIC keluarga / SO sudah konfirmasi kehadiran
pic_confirmed_by UUID NULLABLE REFERENCES users(id)   -- SO atau user yang konfirmasi
pic_confirmed_at TIMESTAMP NULLABLE
pic_signature_path TEXT NULLABLE             -- path tanda tangan digital di R2 (opsional)

notes TEXT NULLABLE
created_at TIMESTAMP
updated_at TIMESTAMP
```

**Aturan Bisnis Presensi:**
```
1. Saat order dikonfirmasi → sistem auto-buat record `field_attendances` (status: 'scheduled')
   untuk setiap: tukang_foto (jika ada), dekor, konsumsi, pemuka_agama yang di-assign
2. Tukang foto / vendor hadir di lokasi → tekan "Saya Hadir" di app → status: 'present', arrived_at: now()
3. PIC SO di lapangan bisa konfirmasi kehadiran → pic_confirmed = true
4. Tukang foto pulang → tekan "Saya Pulang" → departed_at: now()
5. Jika tidak hadir → status: 'absent' → alarm HRD (vendor_no_show)
6. Laporan presensi per order tersedia di Owner Dashboard
```

---

### Tabel `order_equipment_items` (Detail Item Peralatan per Order)

Form fisik: Form Peralatan Pelayanan CV Santa Maria, Form Pinjaman Peralatan Peringatan.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
order_id UUID NULLABLE REFERENCES orders(id)
equipment_loan_id UUID NULLABLE REFERENCES equipment_loans(id)  -- jika untuk peringatan
equipment_item_id UUID REFERENCES equipment_master(id)          -- FK ke master peralatan

category VARCHAR(100) NOT NULL
-- contoh: 'KOPER_MISA', 'KOPER_ROMO', 'BOX', 'PEMBERKATAN', 'SOUND', 'MEJA_TAPLAK', 'LAIN'

item_code VARCHAR(50) NULLABLE             -- nomor koper/kotak (misal: "Koper Misa No. 3")
item_description TEXT NOT NULL             -- deskripsi detail item

-- Kuantitas
qty_sent INTEGER DEFAULT 0                 -- jumlah dikirim
qty_received INTEGER DEFAULT 0            -- jumlah yang diterima di lokasi (konfirmasi keluarga)
qty_returned INTEGER DEFAULT 0            -- jumlah yang dikembalikan

-- Status per item
status ENUM('prepared','sent','received','partial_return','returned','missing') DEFAULT 'prepared'

-- Tanda tangan per fase
sent_by UUID NULLABLE REFERENCES users(id)
sent_at TIMESTAMP NULLABLE
received_by_family_name VARCHAR(255) NULLABLE    -- nama penerima dari keluarga
received_by_family_at TIMESTAMP NULLABLE
received_by_pic_id UUID NULLABLE REFERENCES users(id)   -- PIC Santa Maria yang konfirmasi terima
returned_by_family_name VARCHAR(255) NULLABLE
returned_at TIMESTAMP NULLABLE
accepted_return_by UUID NULLABLE REFERENCES users(id)   -- Santa Maria yang terima kembali

notes TEXT NULLABLE
created_at TIMESTAMP
updated_at TIMESTAMP
```

### Tabel `equipment_master` (Master Data Peralatan)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
category VARCHAR(100) NOT NULL
-- contoh: 'KOPER_MISA', 'KOPER_ROMO', 'BOX', 'SOUND', 'MEJA', 'TAPLAK', 'LAIN'
sub_category VARCHAR(100) NULLABLE
-- contoh untuk KOPER_MISA: 'Piala_Sibori_Patena', 'Ampul_Mangkok', 'Purifikatorium'
item_name VARCHAR(255) NOT NULL
item_code VARCHAR(50) UNIQUE NULLABLE        -- kode internal
default_qty INTEGER DEFAULT 1
unit VARCHAR(50) DEFAULT 'pcs'
is_active BOOLEAN DEFAULT TRUE
notes TEXT NULLABLE
created_at TIMESTAMP
updated_at TIMESTAMP
```

Initial seed `equipment_master` (dapat ditambah/diubah Super Admin/Gudang via UI — daftar ini hanya data awal):
```
-- Daftar ini adalah seed awal. Super Admin/Gudang dapat menambah, mengubah, atau
-- menonaktifkan item kapan saja melalui screen Master Peralatan.
-- Setiap item memiliki category, sub_category, item_name, default_qty, unit.
-- Contoh seed awal mengikuti form fisik operasional saat ini.
-- Endpoint: GET/POST/PUT /gudang/equipment-master (CRUD lengkap)
```

### Tabel `equipment_loans` (Pinjaman Peralatan Peringatan)

Form fisik: Pinjaman Peralatan Peringatan Santa Maria.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
loan_number VARCHAR(50) UNIQUE NOT NULL      -- contoh: LOAN-20241025-001
order_id UUID NULLABLE REFERENCES orders(id) -- bisa terkait order atau standalone

nama_almarhum VARCHAR(255) NOT NULL
rumah_duka VARCHAR(255) NULLABLE
cp_almarhum VARCHAR(255) NULLABLE             -- nama kontak keluarga
tgl_peringatan DATE NOT NULL
tgl_kirim DATE NULLABLE
tgl_kembali DATE NULLABLE

status ENUM('draft','sent','active','returning','completed','overdue') DEFAULT 'draft'

-- Penanda tangan (bagian bawah form)
order_by_id UUID NULLABLE REFERENCES users(id)    -- SO / Admin yang order
bagian_peralatan_id UUID NULLABLE REFERENCES users(id)  -- Gudang yang proses
pengirim_id UUID NULLABLE REFERENCES users(id)    -- Driver / petugas pengirim
pengambil_id UUID NULLABLE REFERENCES users(id)   -- yang ambil kembali
penerima_name VARCHAR(255) NULLABLE               -- nama penerima di lokasi

notes TEXT NULLABLE
created_at TIMESTAMP
updated_at TIMESTAMP
```

---

### Tabel `consumable_master` (Master Data Item Konsumabel)

Item konsumabel TIDAK di-hardcode sebagai kolom — dikelola sebagai master data oleh Super Admin / Gudang. (v1.27: Owner view only)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
item_code VARCHAR(50) UNIQUE NOT NULL         -- contoh: 'CLN', 'LLN', 'AQU', 'PMN'
item_name VARCHAR(255) NOT NULL               -- contoh: 'Eau de Cologne', 'Lilin', 'Air Minum'
unit VARCHAR(50) NOT NULL DEFAULT 'pcs'       -- satuan: pcs, btl, dos, pak
category VARCHAR(100) NULLABLE                -- group: 'kosmetik', 'konsumsi', 'liturgi'
sort_order INTEGER DEFAULT 0                  -- urutan tampil di form
is_active BOOLEAN DEFAULT TRUE
created_at TIMESTAMP
updated_at TIMESTAMP
```

Initial seed (dapat ditambah/diubah Super Admin via UI):
```
CLN  | Eau de Cologne      | btl | kosmetik
LLN  | Lilin               | btl | liturgi
AQU  | Air Minum           | dos | konsumsi
PMN  | Permen              | pak | konsumsi
KCG  | Kacang              | pak | konsumsi
KWC  | Kwaci               | pak | konsumsi
SLB  | Salib Katholik      | pcs | liturgi
SPH  | Sepatu Hitam        | pcs | pakaian
SPP  | Sepatu Putih        | pcs | pakaian
LLP  | Lilin Putih (liturgi)| pcs | liturgi
LLM  | Lilin Merah (liturgi)| pcs | liturgi
KRU  | Kartu Ucapan        | pcs | perlengkapan
SMK  | Semangka            | pcs | konsumsi
ROT  | Roti                | pcs | konsumsi
HJS  | Happy Jus           | pcs | konsumsi
TSR  | Teh Sosro           | pcs | konsumsi
```

### Tabel `order_consumables_daily` (Data Barang Konsumabel Harian per Shift)

Form fisik: Data Barang (form pink) — tracking P/K/M per item per tanggal.
Header per shift — item detail di tabel `order_consumable_lines`.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
order_id UUID REFERENCES orders(id)
consumable_date DATE NOT NULL
shift ENUM('pagi','kirim','malam') NOT NULL   -- P = Pagi, K = Kirim, M = Malam
is_retur BOOLEAN DEFAULT FALSE                -- shift ini = data retur

input_by UUID NULLABLE REFERENCES users(id)   -- tukang jaga / Gudang yang input
tukang_jaga_1_name VARCHAR(255) NULLABLE
tukang_jaga_2_name VARCHAR(255) NULLABLE

notes TEXT NULLABLE
created_at TIMESTAMP
updated_at TIMESTAMP

UNIQUE(order_id, consumable_date, shift, is_retur)
```

### Tabel `order_consumable_lines` (Detail Item per Shift)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
consumable_daily_id UUID REFERENCES order_consumables_daily(id) ON DELETE CASCADE
consumable_master_id UUID REFERENCES consumable_master(id)
qty INTEGER DEFAULT 0
notes VARCHAR(255) NULLABLE
created_at TIMESTAMP
```

---

### Tabel `billing_item_master` (Master Item Tagihan)

Item tagihan TIDAK di-hardcode — dikelola sebagai master data oleh Super Admin. (v1.27: Owner view only)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
item_code VARCHAR(50) UNIQUE NOT NULL         -- contoh: 'EMB', 'NSN', 'BNG_SLB'
item_name VARCHAR(255) NOT NULL               -- contoh: 'Embalming', 'Nisan'
category VARCHAR(100) NULLABLE                -- group: 'layanan', 'konsumsi', 'transportasi'
default_unit VARCHAR(50) DEFAULT 'unit'
default_unit_price DECIMAL(15,2) DEFAULT 0    -- harga default (bisa di-override per order)
sort_order INTEGER DEFAULT 0
is_active BOOLEAN DEFAULT TRUE
created_at TIMESTAMP
updated_at TIMESTAMP
```

Initial seed (dapat ditambah/diubah via UI):
```
EMB     | Embalming              | layanan
NSN     | Nisan                  | layanan
BNG_SLB | Bunga Salib            | dekorasi
BNG_PTI | Bunga Atas Peti        | dekorasi
MND     | Memandikan Jenazah     | layanan
AQU     | AQUA/PRIMA/CLEO       | konsumsi
ROT     | Roti                   | konsumsi
KWC     | Kwaci                  | konsumsi
KCG     | Kacang                 | konsumsi
PMN     | Permen                 | konsumsi
KRT     | Kartu Ucapan           | perlengkapan
LLN     | Lilin                  | liturgi
TKG_JG  | Tukang Jaga            | layanan
RPR     | Repro                  | layanan
FTO     | Foto Dokumentasi       | layanan
BSL     | Bus Lelayu             | transportasi
SWA_TRK | Sewa Truck/Pick Up     | transportasi
PLR     | Pelarung               | layanan
TNH     | Tanah Makam            | layanan
BW      | Black & White          | layanan
SNT     | Saint Voice            | layanan
VDO     | Video Shooting         | layanan
MTR     | Mutiara                | layanan
IKL     | Iklan Dukacita         | layanan
MBL     | Sewa Mobil Jenazah     | transportasi
```

### Tabel `order_billing_items` (Laporan Tagihan per Order)

Form fisik: Laporan Tagihan.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
order_id UUID REFERENCES orders(id)
billing_master_id UUID REFERENCES billing_item_master(id)

-- Nilai (override dari master jika perlu)
qty DECIMAL(10,2) DEFAULT 1
unit VARCHAR(50) DEFAULT 'unit'
unit_price DECIMAL(15,2) DEFAULT 0
total_price DECIMAL(15,2) DEFAULT 0

-- Sumber: dari paket (auto) atau tambahan manual
source ENUM('package','addon','manual') NOT NULL DEFAULT 'package'

-- Untuk kolom Tambahan dan Kembali (dari form fisik)
tambahan DECIMAL(15,2) DEFAULT 0         -- biaya tambahan
kembali DECIMAL(15,2) DEFAULT 0          -- potongan / kembali

notes TEXT NULLABLE
created_at TIMESTAMP
updated_at TIMESTAMP
```

---

### Tabel `vehicle_trip_logs` (Nota Pemakaian Mobil Jenazah)

Form fisik: Nota Pemakaian Mobil Jenazah. Memperkaya vehicle management v1.12.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
nota_number VARCHAR(50) UNIQUE NOT NULL     -- contoh: NMJ-20241025-001
order_id UUID NULLABLE REFERENCES orders(id)
vehicle_id UUID REFERENCES vehicles(id)
driver_id UUID REFERENCES users(id)

atas_nama VARCHAR(255) NOT NULL             -- nama almarhum / konsumen
alamat_penjemputan TEXT NOT NULL
tujuan TEXT NOT NULL
tempat_pemberangkatan TEXT NULLABLE         -- lokasi berangkat (Gudang, RS, dll)
biaya_per_km DECIMAL(15,2) NULLABLE

-- Detail perjalanan
waktu_pemakaian TIMESTAMP NOT NULL          -- tanggal & jam mulai
hari INTEGER NULLABLE                       -- durasi (hari)
jam DECIMAL(4,1) NULLABLE                   -- durasi (jam)

km_berangkat DECIMAL(10,2) NULLABLE
km_tiba DECIMAL(10,2) NULLABLE
km_total DECIMAL(10,2) NULLABLE             -- generated: km_tiba - km_berangkat

-- Biaya
biaya_km DECIMAL(15,2) NULLABLE            -- km_total × biaya_per_km
biaya_administrasi DECIMAL(15,2) NULLABLE
total_biaya DECIMAL(15,2) NULLABLE         -- generated

-- Tanda tangan digital
penyewa_name VARCHAR(255) NULLABLE          -- nama penyewa (keluarga)
penyewa_signed_at TIMESTAMP NULLABLE
sm_officer_name VARCHAR(255) NULLABLE       -- nama petugas Santa Maria
sm_officer_signed_at TIMESTAMP NULLABLE

notes TEXT NULLABLE
created_at TIMESTAMP
updated_at TIMESTAMP
```

---

### Tabel `death_cert_doc_master` (Master Jenis Dokumen Akta Kematian)

Daftar dokumen TIDAK di-hardcode sebagai kolom — dikelola sebagai master data.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
doc_code VARCHAR(50) UNIQUE NOT NULL          -- contoh: 'KTP_MENINGGAL', 'KK_MENINGGAL'
doc_name VARCHAR(255) NOT NULL                -- contoh: 'KTP Almarhum'
sort_order INTEGER DEFAULT 0
is_required BOOLEAN DEFAULT TRUE              -- wajib ada atau opsional
is_active BOOLEAN DEFAULT TRUE
created_at TIMESTAMP
updated_at TIMESTAMP
```

Initial seed (dapat ditambah/diubah via UI):
```
SURAT_PENGANTAR_RT    | Surat Pengantar RT/RW
KTP_MENINGGAL         | KTP Almarhum
KK_MENINGGAL          | KK Almarhum
SURAT_KEMATIAN_RS     | Surat Kematian dari RS/Dokter
SURAT_KEMATIAN_KEL    | Surat Kematian dari Kelurahan
AKTE_LAHIR            | Akte Lahir Almarhum
SURAT_GANTI_NAMA      | Surat Ganti Nama Almarhum
SURAT_NIKAH           | Surat Nikah
AKTE_KEMATIAN_PASANGAN | Akte Kematian Pasangan
GANTI_NAMA_PASANGAN   | Surat Ganti Nama Pasangan
SBKRI                 | SBKRI
POA_STMD              | Surat POA / STMD
FC_KTP_KUASA          | Fotocopy KTP Kuasa
FC_KK_KUASA           | Fotocopy KK Kuasa
FC_AKTE_LAHIR_KUASA   | Fotocopy Akte Lahir Kuasa
FC_GANTI_NAMA_KUASA   | Fotocopy Ganti Nama Kuasa
FC_KTP_ANAK           | Fotocopy KTP Anak
SURAT_KUASA           | Surat Kuasa
AKTE_KEMATIAN_JADI    | Akte Kematian (Jadi)
KK_TERBARU            | KK Terbaru
KTP_TERBARU_PASANGAN  | KTP Terbaru Pasangan
```

### Tabel `order_death_certificate_docs` (Header Tanda Terima Berkas Akta Kematian)

Form fisik: Tanda Terima Berkas Pembuatan Akta Kematian.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
order_id UUID REFERENCES orders(id)
nama_almarhum VARCHAR(255) NOT NULL
catatan TEXT NULLABLE

-- Penyerahan ke Santa Maria
diterima_sm_tanggal DATE NULLABLE
yang_menyerahkan_name VARCHAR(255) NULLABLE
penerima_sm_id UUID NULLABLE REFERENCES users(id)
penerima_sm_signed_at TIMESTAMP NULLABLE

-- Penyerahan ke Keluarga
diterima_keluarga_tanggal DATE NULLABLE
penerima_keluarga_name VARCHAR(255) NULLABLE
penerima_keluarga_signed_at TIMESTAMP NULLABLE

created_at TIMESTAMP
updated_at TIMESTAMP
```

### Tabel `order_death_cert_doc_items` (Checklist per Dokumen)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
death_cert_id UUID REFERENCES order_death_certificate_docs(id) ON DELETE CASCADE
doc_master_id UUID REFERENCES death_cert_doc_master(id)
diterima_sm BOOLEAN DEFAULT FALSE             -- diterima oleh Santa Maria
diterima_keluarga BOOLEAN DEFAULT FALSE       -- dikembalikan ke keluarga
notes VARCHAR(255) NULLABLE
created_at TIMESTAMP
updated_at TIMESTAMP

UNIQUE(death_cert_id, doc_master_id)
```

---

### Tabel `order_extra_approvals` (Header Persetujuan Tambahan di Luar Paket)

Form fisik: Persetujuan Tambahan di Luar Paket.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
order_id UUID REFERENCES orders(id)
nama_almarhum VARCHAR(255) NOT NULL

total_biaya DECIMAL(15,2) DEFAULT 0          -- auto-sum dari extra_approval_lines

-- Penanggung Jawab (Keluarga)
pj_nama VARCHAR(255) NOT NULL
pj_alamat TEXT NULLABLE
pj_no_telp VARCHAR(30) NULLABLE
pj_hub_alm VARCHAR(100) NULLABLE            -- hubungan dengan almarhum
pj_signed_at TIMESTAMP NULLABLE
pj_signature_path TEXT NULLABLE             -- tanda tangan digital (R2)

-- Kota & Tanggal — kota diambil dari system_thresholds key 'default_city'
tanggal DATE NOT NULL

-- SO yang proses
so_id UUID NULLABLE REFERENCES users(id)

approved BOOLEAN DEFAULT FALSE
approved_at TIMESTAMP NULLABLE
notes TEXT NULLABLE
created_at TIMESTAMP
updated_at TIMESTAMP
```

### Tabel `extra_approval_lines` (Detail Item Tambahan)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
approval_id UUID REFERENCES order_extra_approvals(id) ON DELETE CASCADE
line_number SMALLINT NOT NULL                -- urutan item (1, 2, 3, ...)
keterangan VARCHAR(255) NOT NULL             -- deskripsi item tambahan
biaya DECIMAL(15,2) DEFAULT 0
notes VARCHAR(255) NULLABLE
created_at TIMESTAMP
```

Tambahkan ke `system_thresholds`:
```
default_city = 'Semarang'   -- kota default untuk form surat/approval (bisa diubah Owner)
```

---

### Tabel `dekor_item_master` (Master Item Dekorasi La Fiore)

Item dekorasi TIDAK di-hardcode — dikelola sebagai master data oleh Super Admin / Dekor. (v1.27: Owner view only)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
item_code VARCHAR(50) UNIQUE NOT NULL         -- contoh: 'CRS', 'BNG_PTI_STD'
item_name VARCHAR(255) NOT NULL               -- contoh: 'Corsase', 'Bunga Atas Peti Standar'
default_unit VARCHAR(50) DEFAULT 'set'
sort_order INTEGER DEFAULT 0
is_active BOOLEAN DEFAULT TRUE
created_at TIMESTAMP
updated_at TIMESTAMP
```

Initial seed (dapat ditambah/diubah via UI):
```
BDG     | Budget
CRS     | Corsase
BNG_PTI | Bunga Atas Peti Standar
BNG_MJ  | Bunga Hias Meja
BNG_MSA | Bunga Misa
BNG_SLB | Bunga Salib
BNG_SDM | Bunga Sedap Malam
BNG_TBR | Bunga Tabur
KRJ_HIS | Keranjang Hias
DKR     | Dekorasi
CVR_KRS | Cover Kursi
TMN     | Taman (Tanaman Pot)
HNB     | Hanbouquet
KY_PTI  | Kayu Bunga Atas Peti
KY_SLB  | Kayu Bunga Salib
MKP     | Mika Panjang 8×20
MKK     | Mika Kecil 8×10
GLS_VAS | Gelas/Vas
OAS     | Oasis
```

### Tabel `dekor_daily_package` (Header Formulir Isi Paket Layanan Harian La Fiore)

Form fisik: Formulir Isi Paket Layanan Harian La Fiore.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
order_id UUID REFERENCES orders(id)
form_date DATE NOT NULL
rumah_duka VARCHAR(255) NULLABLE

-- Supplier terpilih (max 3 supplier untuk perbandingan)
selected_supplier SMALLINT NULLABLE           -- 1, 2, atau 3
supplier_1_name VARCHAR(255) NULLABLE
supplier_2_name VARCHAR(255) NULLABLE
supplier_3_name VARCHAR(255) NULLABLE

total_anggaran DECIMAL(15,2) DEFAULT 0
total_biaya_aktual DECIMAL(15,2) DEFAULT 0
selisih DECIMAL(15,2) DEFAULT 0             -- generated: total_anggaran - total_biaya_aktual

-- Penanda tangan
div_dekorasi_id UUID NULLABLE REFERENCES users(id)
administrasi_id UUID NULLABLE REFERENCES users(id)
div_dekorasi_signed_at TIMESTAMP NULLABLE
administrasi_signed_at TIMESTAMP NULLABLE

notes TEXT NULLABLE
created_at TIMESTAMP
updated_at TIMESTAMP
```

### Tabel `dekor_daily_package_lines` (Detail Item per Paket Harian)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
package_id UUID REFERENCES dekor_daily_package(id) ON DELETE CASCADE
dekor_master_id UUID REFERENCES dekor_item_master(id)
anggaran_pendapatan DECIMAL(15,2) DEFAULT 0
qty DECIMAL(10,2) DEFAULT 1
biaya_supplier_1 DECIMAL(15,2) NULLABLE
biaya_supplier_2 DECIMAL(15,2) NULLABLE
biaya_supplier_3 DECIMAL(15,2) NULLABLE
notes VARCHAR(255) NULLABLE
created_at TIMESTAMP
```

---

## API — ENDPOINT BARU v1.14

### Master Data CRUD (Super Admin ONLY — v1.27: Owner view only)
```
-- Semua master table mengikuti pola CRUD yang sama:
GET    /admin/master/{entity}                    -- list (Super Admin + Owner read-only)
POST   /admin/master/{entity}                    -- create (Super Admin ONLY)
PUT    /admin/master/{entity}/{id}               -- update (Super Admin ONLY)
DELETE /admin/master/{entity}/{id}               -- soft-delete (Super Admin ONLY)

-- {entity} = salah satu dari:
--   packages           → packages + package_items
--   consumables        → consumable_master
--   billing-items      → billing_item_master
--   coffin-stages      → coffin_stage_master
--   coffin-qc-criteria → coffin_qc_criteria_master
--   death-cert-docs    → death_cert_doc_master
--   dekor-items        → dekor_item_master
--   equipment          → equipment_master
--   vendor-roles       → vendor_role_master
--   trip-legs          → trip_leg_master
--   wa-templates       → wa_message_templates
--   status-labels      → order_status_labels
--   terms              → terms_and_conditions

-- Akses write: Super Admin ONLY (POST/PUT/DELETE)
-- Akses read: Super Admin + Owner + role terkait (Gudang bisa GET equipment, dll)
-- v1.27: Owner TIDAK bisa POST/PUT/DELETE — backend enforce via middleware
```

### Workshop Peti (Gudang)
```
POST   /gudang/coffin-orders                     -- buat order peti baru (stages auto-generate dari master)
GET    /gudang/coffin-orders                     -- list semua order peti
GET    /gudang/coffin-orders/{id}                -- detail + stages + qc results
PUT    /gudang/coffin-orders/{id}/status         -- update status (busa_done, qc_passed, dll)
PUT    /gudang/coffin-orders/{id}/stages/{stageId} -- centang tahap selesai
POST   /gudang/coffin-orders/{id}/qc             -- input hasil QC (per criteria dari master)
```

### Presensi (SO / Tukang Foto / Vendor)
```
GET    /orders/{id}/attendances                  -- list semua presensi untuk 1 order
POST   /vendor/attendances/{id}/check-in         -- tukang foto / vendor: hadir
POST   /vendor/attendances/{id}/check-out        -- tukang foto / vendor: pulang
PUT    /so/attendances/{id}/confirm              -- SO konfirmasi kehadiran vendor
GET    /hrd/attendances                          -- HRD: semua presensi + filter absent
GET    /owner/attendances/summary                -- Owner: ringkasan presensi per order
```

### Peralatan (Gudang / Driver)
```
GET    /gudang/equipment-master                  -- list semua master peralatan
POST   /gudang/orders/{id}/equipment             -- siapkan checklist peralatan untuk order
GET    /gudang/orders/{id}/equipment             -- list item peralatan order ini
PUT    /gudang/orders/{id}/equipment/{itemId}/send   -- tandai dikirim + qty
PUT    /gudang/orders/{id}/equipment/{itemId}/return -- tandai dikembalikan + qty
GET    /gudang/equipment/missing                 -- list peralatan yang belum kembali

-- Pinjaman Peringatan
POST   /gudang/equipment-loans                   -- buat form pinjaman peringatan
GET    /gudang/equipment-loans                   -- list semua pinjaman
GET    /gudang/equipment-loans/{id}              -- detail + items
PUT    /gudang/equipment-loans/{id}/status       -- update status
```

### Konsumabel Harian (Tukang Jaga / Gudang)
```
POST   /orders/{id}/consumables                  -- input data barang shift
GET    /orders/{id}/consumables                  -- list semua shift entries
PUT    /orders/{id}/consumables/{id}             -- update entry
GET    /gudang/consumables/summary               -- ringkasan konsumabel harian semua order aktif
```

### Laporan Tagihan
```
GET    /orders/{id}/billing                      -- semua item tagihan order
POST   /so/orders/{id}/billing-items             -- SO tambah item manual
PUT    /purchasing/orders/{id}/billing-items/{itemId} -- Purchasing update nilai
GET    /purchasing/orders/{id}/billing/total        -- total tagihan + tambahan + kembali
GET    /purchasing/billing/export/{orderId}         -- export PDF laporan tagihan
```

### Nota Mobil Jenazah
```
POST   /driver/vehicle-trip-logs                 -- buat nota perjalanan
GET    /driver/vehicle-trip-logs                 -- list nota milik driver ini
PUT    /driver/vehicle-trip-logs/{id}            -- update KM + tandatangan
GET    /gudang/vehicle-trip-logs                 -- Gudang / Owner lihat semua
GET    /owner/vehicle-trip-logs/summary          -- laporan biaya armada per periode
```

### Akta Kematian
```
POST   /so/orders/{id}/death-cert-docs           -- buat checklist dokumen
GET    /so/orders/{id}/death-cert-docs           -- lihat status checklist
PUT    /so/orders/{id}/death-cert-docs           -- update centang per dokumen
```

### Persetujuan Tambahan
```
POST   /so/orders/{id}/extra-approvals           -- buat form persetujuan tambahan
GET    /so/orders/{id}/extra-approvals           -- list persetujuan untuk order ini
PUT    /so/orders/{id}/extra-approvals/{id}      -- update (tambah item, harga)
POST   /so/orders/{id}/extra-approvals/{id}/sign -- simpan tanda tangan digital keluarga
```

### La Fiore Daily Package (Dekor)
```
POST   /dekor/orders/{id}/daily-package          -- buat form paket harian
GET    /dekor/orders/{id}/daily-package          -- lihat form
PUT    /dekor/orders/{id}/daily-package/{id}     -- update item + pilih supplier
POST   /dekor/orders/{id}/daily-package/{id}/sign -- tanda tangan digital
```

---

## FLUTTER — SCREEN BARU v1.14

```
lib/features/
  │
  ├── gudang/screens/
  │   ├── coffin_order_list_screen.dart    -- list order peti + status badge per order
  │   ├── coffin_order_form_screen.dart    -- buat order peti baru: kode, ukuran, warna, finishing
  │   ├── coffin_order_detail_screen.dart  -- detail + progress tahap (timeline vertical)
  │   │     -- Setiap tahap: nama tahap, checkbox "Selesai", input nama tukang
  │   │     -- Progress bar keseluruhan
  │   │     -- Tab "QC": form kriteria QC dengan toggle pass/fail per kriteria
  │   │     -- Tombol "Lulus QC" / "Gagal QC" + notes
  │   │
  │   ├── equipment_checklist_screen.dart  -- checklist peralatan per order
  │   │     -- Group by category (Koper Misa, Koper Romo, Sound, dll)
  │   │     -- Per item: qty, checkbox kirim, checkbox kembali
  │   │     -- Summary: berapa item sudah kembali, berapa belum
  │   │
  │   └── equipment_loan_screen.dart       -- pinjaman peralatan peringatan
  │         -- Form: nama almarhum, CP, tanggal peringatan, tanggal kirim/kembali
  │         -- Checklist item sama seperti equipment_checklist_screen
  │
  ├── tukang_foto/screens/                 -- BARU (mirip vendor home)
  │   ├── foto_home.dart                  -- dashboard: order aktif hari ini + presensi status
  │   ├── foto_order_list.dart            -- list semua assignment
  │   ├── foto_order_detail.dart          -- detail order + tombol "Saya Hadir" / "Saya Pulang"
  │   └── foto_upload_screen.dart         -- upload hasil foto ke order
  │
  ├── service_officer/screens/
  │   ├── attendance_confirm_screen.dart  -- BARU: SO konfirmasi kehadiran vendor di lapangan
  │   │     -- List vendor yang di-assign untuk order ini
  │   │     -- Per vendor: status (Belum / Hadir / Tidak Hadir)
  │   │     -- Tombol konfirmasi + input waktu hadir
  │   │
  │   ├── extra_approval_screen.dart      -- BARU: form persetujuan tambahan
  │   │     -- Input item tambahan (maks 4, bisa extend)
  │   │     -- Hitung total otomatis
  │   │     -- Area tanda tangan digital (menggunakan flutter_signature_pad)
  │   │
  │   └── death_cert_checklist_screen.dart -- BARU: checklist 20 dokumen akta
  │         -- Dua kolom: "Diterima Santa Maria" | "Diterima Keluarga"
  │         -- Checkbox per dokumen
  │         -- Tombol "Selesai Terima" + tanda tangan digital
  │
  ├── dekor/screens/
  │   └── daily_package_form_screen.dart  -- BARU: form paket harian La Fiore
  │         -- Tabel: Keterangan | Anggaran | Qty | Biaya S1 | Biaya S2 | Biaya S3
  │         -- Row per item (19 item default + baris kosong untuk tambahan)
  │         -- Input harga inline, total dihitung otomatis
  │         -- Dropdown pilih supplier terbaik
  │         -- Tombol tanda tangan dua pihak
  │
  └── purchasing/screens/
      ├── billing_report_screen.dart      -- BARU: laporan tagihan 26 item per order
      │     -- Tabel: No | Item | Jumlah | Harga Satuan | Total | Tambahan | Kembali
      │     -- Footer: Grand Total
      │     -- Tombol Export PDF
      │
      └── extra_billing_screen.dart       -- BARU: lihat & approve persetujuan tambahan
```

---

## PUBSPEC.YAML — TAMBAHAN PACKAGE

```yaml
dependencies:
  # Tanda tangan digital (untuk extra approval & death cert)
  flutter_signature_pad: ^3.0.0     # atau: syncfusion_flutter_signaturepad
  
  # Export PDF (sudah ada di backend, ini untuk preview di Flutter)
  printing: ^5.12.0                 # preview + share PDF
  pdf: ^3.10.8                      # generate PDF di Flutter (jika offline needed)
```

---

## TABEL ALARM TAMBAHAN v1.14

| Momen | SO | Gudang | Purchasing | Tukang Foto | Dekor | HRD | Owner |
|-------|----|----|----|----|----|----|-----|
| Order dikonfirmasi → auto-buat presensi | — | — | — | ALARM (ada assignment) | ALARM | — | — |
| Tukang foto check-in | HIGH (info) | — | — | — | — | — | — |
| Tukang foto tidak hadir (jadwal terlewat) | HIGH | — | — | — | — | ALARM | HIGH |
| Item peralatan belum kembali (H+1) | — | ALARM | — | — | — | — | NORMAL |
| Coffin order lolos QC | HIGH (info) | — | — | — | — | — | — |
| Extra approval ditandatangani keluarga | HIGH | — | ALARM (biaya baru) | — | — | — | HIGH |
| Berkas akta kematian diterima lengkap | HIGH | — | — | — | — | — | NORMAL |

---

## SINKRONISASI KE ALUR ORDER

Integrasi v1.14 sudah di-merge langsung ke STEP 3, STEP 7, dan STEP 9 di Alur Order Definitif.
Lihat section "ALUR ORDER FINAL — EKSAK" di atas.

---

## ATURAN BISNIS BARU v1.14

```
WORKSHOP PETI:
1. Coffin order bisa berdiri sendiri (tanpa order konsumen) untuk stok cadangan
2. Coffin order terkait order konsumen: kode_peti otomatis terikat di orders.coffin_order_id
3. QC harus dilakukan Gudang atau SO — tidak bisa ditandai sendiri oleh tukang
4. Peti yang gagal QC harus kembali ke tahap yang gagal (bukan ulang dari awal)

PRESENSI:
1. Check-in hanya bisa dilakukan dalam radius 500m dari lokasi order (geofence)
   → toleransi geofence dikonfigurasi di system_thresholds: attendance_radius_meters = 500
2. Check-in tidak bisa lebih dari 2 jam sebelum scheduled_at
3. Jika tukang foto tidak check-in dalam 30 menit setelah scheduled_at → alarm HRD
4. Tanda tangan SO (pic_confirmed) wajib untuk finalkan presensi

PERALATAN:
1. Peralatan dikirim bersamaan dengan Driver Tugas 1 (angkut barang)
2. Setelah order selesai, H+1 belum ada konfirmasi kembali → alarm Gudang
3. Jika peralatan hilang (missing) → catat di equipment_items.status = 'missing'
   → Biaya penggantian dimasukkan ke order_extra_approvals

LAPORAN TAGIHAN:
1. order_billing_items di-generate otomatis saat SO konfirmasi (dari package + addons)
2. Purchasing bisa edit qty dan harga untuk koreksi
3. Export PDF menggunakan template laporan tagihan 26 item standar Santa Maria
4. Kolom "Tambahan" = biaya from order_extra_approvals
5. Kolom "Kembali" = potongan / refund (diisi Purchasing)

BERKAS AKTA KEMATIAN:
1. SO wajib membuat checklist sebelum order bisa di-close (setelah payment verified)
2. Dokumen yang diterima Santa Maria: SO yang centang (side: Santa Maria)
3. Dokumen yang dikembalikan ke keluarga: SO centang saat serah terima
4. Tidak ada blocking order — hanya reminder jika belum dibuat dalam 24 jam post-order-complete
```

---

## ROLE TABLE UPDATED — v1.14

| Role ID | Nama Role | Tipe | Fungsi Utama |
|---------|-----------|------|-------------|
| super_admin | Super Admin | Sistem | Manajemen akun & konfigurasi sistem |
| consumer | Konsumen | Eksternal | Input order, tracking, upload bukti payment |
| service_officer | Service Officer | Internal | Sales lapangan & SO kantor (multi-channel) |
| gudang | Gudang | Internal | Stok, checklist, peralatan, workshop peti, PO ke supplier |
| purchasing | Purchasing | Internal | Verifikasi payment, bayar supplier, laporan tagihan, upah tim |
| driver | Driver | Internal | Transport jenazah, GPS, bukti lapangan, nota mobil |
| dekor | Laviore / Dekor | Vendor | Dekorasi, form paket La Fiore, konfirmasi, bukti foto |
| konsumsi | Konsumsi | Vendor | Katering, konfirmasi, bukti |
| pemuka_agama | Pemuka Agama | Vendor | Koordinasi layanan keagamaan, konfirmasi hadir |
| tukang_foto | Tukang Foto | Vendor | Dokumentasi lapangan, presensi digital, upload hasil foto |
| supplier | Supplier | Vendor | e-Katalog: lihat & ajukan penawaran |
| owner | Owner / Direktur | Eksekutif | Monitor semua, konfigurasi, laporan |
| hrd | HRD | Internal | Terima alarm pelanggaran, presensi, catat & tindak lanjut |
| security | Security | Internal | Monitoring keamanan, laporan kehadiran |
| viewer | Viewer | Eksternal | Read-only: lihat laporan & status order (tanpa aksi) |

**Total Role: 12 aktif + 1 Super Admin + 1 Supplier (eksternal) + 1 Consumer (eksternal)**

---

---

## DATABASE — KOLOM TAMBAHAN DI TABEL EXISTING (v1.14)

### Tabel `orders` — Kolom Tambahan v1.14

```sql
-- Tambahkan ke tabel orders:

coffin_order_id UUID NULLABLE REFERENCES coffin_orders(id)
-- Peti yang dipakai untuk order ini (jika ada dari workshop)

tukang_foto_id UUID NULLABLE REFERENCES users(id)
-- Fotografer yang di-assign untuk order ini

death_cert_submitted BOOLEAN DEFAULT FALSE
-- Berkas akta kematian sudah diserahkan ke keluarga

extra_approval_total DECIMAL(15,2) DEFAULT 0
-- Total biaya tambahan dari order_extra_approvals (auto-updated)
```

### Tabel `system_thresholds` — Seed Data Tambahan v1.14

```
-- Tambahkan ke seed data system_thresholds:

attendance_radius_meters        = 500    (meter)  -- radius geofence check-in vendor/tukang_foto
attendance_checkin_early_minutes = 120   (menit)  -- boleh check-in maks X menit sebelum scheduled_at
attendance_late_threshold_minutes = 30   (menit)  -- jika belum check-in X menit setelah jadwal → alarm HRD
equipment_return_deadline_hours  = 24    (jam)    -- peralatan harus kembali dalam X jam setelah order selesai
coffin_qc_deadline_hours         = 48    (jam)    -- peti harus di-QC dalam X jam setelah finishing selesai
death_cert_deadline_hours        = 24    (jam)    -- berkas akta harus dibuat dalam X jam setelah order complete
```

### Tabel `hrd_violations` — Tambah Violation Type

```sql
-- Tambah ke ENUM violation_type:
'vendor_attendance_late',        -- tukang foto / vendor hadir terlambat (melebihi threshold)
'equipment_not_returned',        -- peralatan belum kembali setelah deadline
'coffin_qc_overdue',             -- peti melewati deadline QC
'death_cert_not_submitted',      -- berkas akta kematian belum dibuat setelah deadline
```

---

## FORMULIR CHECKER ALAT BANTU PELAYANAN (Multi-Hari)

Form fisik: Formulir Alat Bantu Checker Pelayanan — tracking per hari (Hari 1–5) untuk 1 order.

Diimplementasikan sebagai view agregasi dari tabel-tabel yang ada. Tidak membutuhkan tabel baru.

```
Checker = gabungan dari:
  - field_attendances          → siapa hadir hari ke-X
  - order_consumables_daily    → barang apa yang dipakai hari ke-X (shift P/K/M)
  - order_equipment_items      → status peralatan hari ke-X
  - order_billing_items        → item layanan yang ter-execute hari ke-X

Flutter screen: checker_screen.dart
  - Tab per hari: "Hari 1" | "Hari 2" | ... | "Hari 5"
  - Per tab: section Kehadiran, section Barang, section Peralatan
  - Readonly untuk Owner, editable untuk SO / Gudang
  - Export summary per hari ke PDF
```

Endpoint:
```
GET /orders/{id}/checker?day=1    -- ringkasan checker hari ke-N untuk 1 order
GET /orders/{id}/checker/summary  -- semua hari dalam 1 response
```

---

## FORMULIR PENGAMBILAN & PENGEMBALIAN BARANG — KODE SKU GUDANG

Form fisik: Formulir Pengambilan Barang + Formulir Pengembalian Barang (dengan kode item).

Kode-kode pada form fisik dipetakan ke kolom `item_code` di tabel `stock_items` (sudah ada).
Daftar SKU dikelola sebagai master data di `stock_items` — Super Admin/Gudang dapat menambah, mengubah,
atau menonaktifkan kode SKU kapan saja melalui screen Master Stok tanpa perlu mengubah kode program.

```
-- Seed awal item_code mengikuti kode fisik yang sudah tercetak di form operasional.
-- Setiap kode fisik = 1 record di stock_items (item_code, item_name, category).
-- Endpoint CRUD: GET/POST/PUT /gudang/stock-items (sudah ada dari v1.7)
-- Gudang mengelola mapping ini via UI, bukan hardcode di migration.
```

Formulir Pengambilan dan Pengembalian Barang → kedua form menggunakan endpoint yang sudah ada:
```
POST /gudang/stock-transactions          -- keluarkan barang (type: 'out', form: pengambilan)
POST /gudang/stock-transactions          -- masukkan barang (type: 'in',  form: pengembalian)
-- Tambahkan field: form_type ENUM('pengambilan','pengembalian') ke stock_transactions
-- Tambahkan field: no_form VARCHAR(50) NULLABLE ke stock_transactions
-- Tambahkan field: bag_pelayanan VARCHAR(100) NULLABLE (Bag. Pelayanan yang otorisasi)
-- Tambahkan field: bag_gudang VARCHAR(100) NULLABLE    (Bag. Gudang yang otorisasi)
-- Tambahkan field: pembawa VARCHAR(255) NULLABLE       (nama pembawa barang)
```

---

## SCHEDULERS — TAMBAHAN v1.14

```php
protected function schedule(Schedule $schedule): void {
  // ... (scheduler yang sudah ada) ...

  // BARU v1.14: Cek presensi vendor yang belum check-in
  $schedule->command('attendance:check-late')->everyFiveMinutes();

  // BARU v1.14: Cek peralatan yang belum kembali setelah deadline
  $schedule->command('equipment:check-return-deadline')->hourly();

  // BARU v1.14: Cek QC peti yang overdue
  $schedule->command('coffin:check-qc-deadline')->everyTwoHours();

  // BARU v1.14: Reminder berkas akta kematian yang belum dibuat
  $schedule->command('death-cert:check-pending')->dailyAt('09:00')->timezone('Asia/Jakarta');
}
```

### Command: `attendance:check-late`

```php
// Cek semua field_attendances status='scheduled' yang sudah melewati threshold
$threshold = SystemThreshold::getValue('attendance_late_threshold_minutes', 30);

FieldAttendance::where('status', 'scheduled')
  ->whereDate('attendance_date', today())
  ->whereNotNull('scheduled_jam')
  ->get()
  ->each(function ($att) use ($threshold) {
    $scheduledDt = Carbon::parse($att->attendance_date->format('Y-m-d') . ' ' . $att->scheduled_jam);
    if (now()->diffInMinutes($scheduledDt, false) < -$threshold) {
      // Sudah X menit lewat, belum check-in
      $att->update(['status' => 'absent']);

      HrdViolation::create([
        'violated_by'    => $att->user_id,
        'order_id'       => $att->order_id,
        'violation_type' => 'vendor_attendance_late',
        'description'    => "{$att->user->name} ({$att->role}) belum check-in. Jadwal: {$scheduledDt->format('H:i')}",
        'threshold_value'=> $threshold,
        'actual_value'   => now()->diffInMinutes($scheduledDt),
        'severity'       => 'medium',
      ]);

      NotificationService::sendToRole('hrd', 'ALARM',
        'Vendor Tidak Hadir',
        "{$att->user->name} belum hadir di Order {$att->order->order_number} (jadwal {$scheduledDt->format('H:i')})"
      );
      NotificationService::sendToRole('owner', 'HIGH',
        'Vendor Absen',
        "{$att->user->name} tidak hadir di {$att->order->order_number}"
      );
    }
  });
```

### Command: `equipment:check-return-deadline`

```php
$deadlineHours = SystemThreshold::getValue('equipment_return_deadline_hours', 24);

// Cari order yang sudah selesai tapi ada peralatan belum kembali
Order::where('status', 'completed')
  ->where('completed_at', '<=', now()->subHours($deadlineHours))
  ->whereHas('equipmentItems', fn($q) => $q->whereNotIn('status', ['returned', 'missing']))
  ->each(function ($order) {
    $items = $order->equipmentItems()
      ->whereNotIn('status', ['returned', 'missing'])
      ->get();

    NotificationService::sendToRole('gudang', 'ALARM',
      'Peralatan Belum Kembali — ' . $order->order_number,
      $items->count() . ' item peralatan belum dikembalikan dari order yang sudah selesai.'
    );

    HrdViolation::firstOrCreate(
      ['order_id' => $order->id, 'violation_type' => 'equipment_not_returned'],
      [
        'violated_by'  => $order->so_user_id,
        'description'  => "Peralatan order {$order->order_number} belum kembali setelah {$deadlineHours} jam",
        'severity'     => 'medium',
      ]
    );
  });
```

---

## LAPORAN PELAYANAN HARIAN — INTEGRASI

Form fisik: Formulir Laporan Pelayanan Harian (dua versi).

Form ini adalah rekap semua kegiatan layanan dalam 1 hari untuk 1 order. Tidak membutuhkan tabel baru — diimplementasikan sebagai laporan agregasi.

```
Laporan Pelayanan Harian = query dari:
  order_consumables_daily     → barang yang dikeluarkan hari ini
  field_attendances           → kehadiran tim hari ini
  order_equipment_items       → status peralatan hari ini
  order_billing_items         → item layanan yang aktif hari ini
  vehicle_trip_logs           → perjalanan mobil hari ini

Kolom "JUMLAH", "T/H/S/R" (Terima/Hadir/Selesai/Retur), "TANDA" → ditampilkan di screen
```

Endpoint:
```
GET /orders/{id}/daily-report?date=2024-10-25    -- laporan harian untuk tanggal tertentu
GET /so/daily-reports?date=2024-10-25             -- semua order aktif SO ini pada tanggal tersebut
GET /owner/daily-reports?date=2024-10-25          -- Owner: semua order aktif pada tanggal tersebut
```

Flutter screen: `daily_report_screen.dart`
```dart
// Tampilan mirip form fisik:
// Header: Nama, No, Tanggal, Rumah Duka
// Tabel dua kolom: Kegiatan Pelayanan | Jumlah | T/H/S/R | Tanda
// Group by kategori: Sewa Mobil, Sewa Tratak, Dekorasi, Konsumsi, dll
// Footer: Support + Administrasi (tanda tangan digital)
// Export PDF → laporan harian standar Santa Maria
```

---

## RINGKASAN TABEL DATABASE v1.14

### Tabel Master Baru (data-driven, dikelola Super Admin via UI — v1.27: Owner view only)
| Tabel Master | Fungsi | CRUD oleh | Read oleh |
|-------------|--------|-----------|-----------|
| `packages` | Paket layanan | Super Admin | Semua role |
| `consumable_master` | Master item konsumabel | Super Admin | Gudang, Owner |
| `billing_item_master` | Master item tagihan | Super Admin | Purchasing, Owner |
| `coffin_stage_master` | Master tahap pengerjaan peti | Super Admin | Gudang, Owner |
| `coffin_qc_criteria_master` | Master kriteria QC peti | Super Admin | Gudang, Owner |
| `death_cert_doc_master` | Master jenis dokumen akta | Super Admin | SO, Owner |
| `dekor_item_master` | Master item dekorasi La Fiore | Super Admin | Dekor, Owner |
| `equipment_master` | Master peralatan pelayanan | Super Admin | Gudang, Owner |

### Tabel Transaksional Baru
| Tabel | Dari Form | Relasi Utama |
|-------|-----------|-------------|
| `coffin_orders` | Form Busa Eropa, Surat Order Peti | `orders`, `users` |
| `coffin_order_stages` | Pengerjaan Melamin/Duco | `coffin_orders`, `coffin_stage_master` |
| `coffin_qc_results` | Hasil QC per peti | `coffin_orders`, `coffin_qc_criteria_master` |
| `field_attendances` | Presensi Tukang Foto | `orders`, `users` |
| `order_equipment_items` | Form Peralatan (per order) | `orders`, `equipment_master` |
| `equipment_loans` | Pinjaman Peralatan Peringatan | `orders` |
| `order_consumables_daily` | Header shift harian (form pink) | `orders`, `users` |
| `order_consumable_lines` | Detail item per shift | `order_consumables_daily`, `consumable_master` |
| `order_billing_items` | Tagihan per order | `orders`, `billing_item_master` |
| `vehicle_trip_logs` | Nota Pemakaian Mobil Jenazah | `orders`, `vehicles`, `users` |
| `dekor_daily_package` | Header paket harian La Fiore | `orders`, `users` |
| `dekor_daily_package_lines` | Detail item per paket | `dekor_daily_package`, `dekor_item_master` |
| `order_death_certificate_docs` | Header tanda terima akta | `orders`, `users` |
| `order_death_cert_doc_items` | Checklist per dokumen | `order_death_certificate_docs`, `death_cert_doc_master` |
| `order_extra_approvals` | Header persetujuan tambahan | `orders`, `users` |
| `extra_approval_lines` | Detail item tambahan | `order_extra_approvals` |

| Tabel Existing yang Diperkaya | Perubahan |
|-------------------------------|-----------|
| `orders` | + `coffin_order_id`, `tukang_foto_id`, `death_cert_submitted`, `extra_approval_total` |
| `stock_transactions` | + `form_type`, `no_form`, `bag_pelayanan`, `bag_gudang`, `pembawa` |
| `users` | + role `tukang_foto` |
| `system_thresholds` | + 7 threshold baru (attendance, equipment, coffin QC, death cert, default_city) |
| `hrd_violations.violation_type` | + 4 type baru (attendance_late, equipment_not_returned, coffin_qc_overdue, death_cert) |

---

## CHANGELOG v1.14

### v1.14 — Sinkronisasi 19 Form Fisik Operasional (Data-Driven, Tanpa Hardcode)

**Prinsip Arsitektur v1.14:**
- Semua item, tahap, kriteria, dan dokumen disimpan sebagai **master data** — bukan kolom/JSONB hardcode
- Super Admin dapat menambah, mengubah, atau menonaktifkan SEMUA master data via UI tanpa deploy ulang (v1.27: Owner = view only, tidak bisa CRUD)
- Pola master-detail: header + lines (bukan kolom per-item atau JSONB array)
- 7 tabel master baru untuk konfigurasi data operasional

**Modul Baru:**
- Workshop Peti (`coffin_orders`, `coffin_order_stages` ← `coffin_stage_master`) — tracking produksi peti dari busa hingga QC
- QC Peti (`coffin_qc_results` ← `coffin_qc_criteria_master`) — kriteria QC dinamis per finishing type
- Sistem Presensi Digital (`field_attendances`) — check-in/out dengan geofence + konfirmasi SO
- Manajemen Peralatan Diperkaya (`order_equipment_items`, `equipment_master`, `equipment_loans`)
- Data Konsumabel Harian per Shift (`order_consumables_daily` + `order_consumable_lines` ← `consumable_master`)
- Laporan Tagihan (`order_billing_items` ← `billing_item_master`) — jumlah item tidak dibatasi
- Nota Pemakaian Mobil Jenazah (`vehicle_trip_logs`)
- Paket Harian La Fiore (`dekor_daily_package` + `dekor_daily_package_lines` ← `dekor_item_master`)
- Berkas Akta Kematian (`order_death_certificate_docs` + `order_death_cert_doc_items` ← `death_cert_doc_master`)
- Persetujuan Tambahan (`order_extra_approvals` + `extra_approval_lines`) — tanda tangan digital keluarga

**Role Baru:**
- `tukang_foto` — vendor fotografer dengan presensi digital + upload bukti

**Integrasi:**
- Presensi otomatis dibuat saat SO konfirmasi order
- Checklist peralatan otomatis dari template paket
- Billing items otomatis dari package + addons (referensi ke master)
- Coffin stages auto-generate dari master sesuai finishing_type
- QC criteria auto-generate dari master sesuai finishing_type
- Alarm peralatan belum kembali H+1 setelah order selesai
- Tukang foto tidak hadir → HRD violation otomatis

---

# SANTA MARIA — PATCH v1.16
# Sistem KPI Karyawan — Auto-Calculated dari Data Operasional

---

## LATAR BELAKANG v1.16

HRD perlu mengatur dan menilai KPI setiap karyawan. Tantangannya: bagaimana menilai secara objektif?

**Solusi:** Sistem Santa Maria sudah menyimpan data operasional lengkap per karyawan — presensi, kecepatan proses, jumlah pelanggaran, tingkat kehadiran vendor, dll. KPI dihitung **otomatis** dari data ini. HRD hanya perlu:
1. Menentukan **metrik apa** yang diukur per role
2. Menentukan **target** per metrik
3. Menentukan **bobot** per metrik (total 100%)

Sistem yang menghitung skor aktual. Tidak ada input manual untuk penilaian.

---

## KONSEP KPI SANTA MARIA

```
HRD/Super Admin set:
  "SO harus proses order < 30 menit rata-rata (bobot 25%)"
  "SO harus punya 0 pelanggaran per bulan (bobot 15%)"
  "Driver harus on-time 95% (bobot 30%)"
  dll.

Sistem hitung:
  Tarik data dari tabel yang sudah ada →
  Bandingkan aktual vs target →
  Hitung skor per metrik (0-100) →
  Hitung skor total = Σ(skor × bobot)

HRD lihat:
  Dashboard KPI per karyawan per periode
  Ranking per role
  Trend bulanan (naik/turun)
  Alert otomatis jika skor < threshold
```

---

## DATABASE — TABEL KPI v1.16

### Tabel `kpi_metric_master` (Master Metrik KPI per Role)

Metrik KPI dikelola sebagai master data — HRD/Super Admin bisa tambah/ubah via UI. (v1.27: Owner view only)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
metric_code VARCHAR(50) UNIQUE NOT NULL       -- contoh: 'SO_PROCESS_SPEED'
metric_name VARCHAR(255) NOT NULL             -- contoh: 'Kecepatan Proses Order'
description TEXT NULLABLE                     -- penjelasan untuk HRD

-- Role yang dinilai metrik ini
applicable_role VARCHAR(50) NOT NULL          -- 'service_officer', 'gudang', 'driver', dll

-- Cara menghitung
data_source VARCHAR(100) NOT NULL             -- tabel sumber: 'orders', 'hrd_violations', dll
calculation_type ENUM(
  'average',           -- rata-rata nilai (misal: avg processing time)
  'percentage',        -- persentase (misal: % on-time)
  'count',             -- jumlah (misal: total order handled)
  'inverse_count',     -- semakin sedikit semakin bagus (misal: jumlah pelanggaran)
  'sum'                -- total (misal: total KM driven)
) NOT NULL
calculation_query TEXT NOT NULL               -- deskripsi query logic (untuk developer)
-- contoh: "AVG(EXTRACT(EPOCH FROM (confirmed_at - created_at))/60) FROM orders WHERE so_user_id = :user_id AND confirmed_at BETWEEN :start AND :end"

unit VARCHAR(50) NOT NULL                     -- 'menit', 'persen', 'kali', 'order', 'km'

-- Target & scoring
target_value DECIMAL(10,2) NOT NULL           -- nilai target (misal: 30 menit)
target_direction ENUM('lower_is_better','higher_is_better') NOT NULL
-- lower_is_better: aktual < target = bagus (waktu proses, pelanggaran)
-- higher_is_better: aktual > target = bagus (jumlah order, persentase kehadiran)

weight DECIMAL(5,2) NOT NULL DEFAULT 10       -- bobot persen (total per role harus = 100)
sort_order INTEGER DEFAULT 0
is_active BOOLEAN DEFAULT TRUE
created_at TIMESTAMP
updated_at TIMESTAMP
```

Initial seed metrik per role (dapat ditambah/diubah HRD via UI):

```
═══════════════════════════════════════════════════════════
SERVICE OFFICER (service_officer)
═══════════════════════════════════════════════════════════
SO_PROCESS_SPEED     | Kecepatan Proses Order
  data_source: orders
  calculation: AVG menit dari pending → confirmed
  target: ≤ 30 menit | direction: lower_is_better | bobot: 25%

SO_ORDER_COUNT       | Jumlah Order Dihandle
  data_source: orders
  calculation: COUNT orders yang di-confirm SO ini
  target: ≥ 20 per bulan | direction: higher_is_better | bobot: 20%

SO_VIOLATION_COUNT   | Jumlah Pelanggaran
  data_source: hrd_violations
  calculation: COUNT violations oleh user ini
  target: 0 | direction: lower_is_better | bobot: 20%

SO_ATTENDANCE_RATE   | Tingkat Kehadiran
  data_source: field_attendances
  calculation: % hari hadir vs hari kerja
  target: ≥ 95% | direction: higher_is_better | bobot: 20%

SO_EXTRA_APPROVAL    | Persetujuan Tambahan Closed
  data_source: order_extra_approvals
  calculation: COUNT approved per periode
  target: ≥ 5 | direction: higher_is_better | bobot: 15%

═══════════════════════════════════════════════════════════
GUDANG (gudang)
═══════════════════════════════════════════════════════════
GDG_STOCK_READY_SPEED | Kecepatan Siapkan Stok
  data_source: orders (confirmed_at → gudang_ready_at)
  calculation: AVG menit dari confirmed → stock_ready
  target: ≤ 60 menit | direction: lower_is_better | bobot: 25%

GDG_EQUIPMENT_RETURN | Tingkat Pengembalian Peralatan
  data_source: order_equipment_items
  calculation: % item returned vs total sent
  target: ≥ 98% | direction: higher_is_better | bobot: 20%

GDG_QC_PASS_RATE     | Tingkat Lolos QC Peti
  data_source: coffin_orders
  calculation: % qc_passed vs total QC
  target: ≥ 90% | direction: higher_is_better | bobot: 20%

GDG_VIOLATION_COUNT  | Jumlah Pelanggaran
  data_source: hrd_violations
  target: 0 | direction: lower_is_better | bobot: 15%

GDG_PROCUREMENT_SPEED | Kecepatan Evaluasi Quote
  data_source: procurement_requests
  calculation: AVG jam dari evaluating → awarded
  target: ≤ 24 jam | direction: lower_is_better | bobot: 20%

═══════════════════════════════════════════════════════════
PURCHASING (purchasing)
═══════════════════════════════════════════════════════════
PUR_PAYMENT_VERIFY_SPEED | Kecepatan Verifikasi Payment
  data_source: orders (proof_uploaded_at → payment_verified_at)
  calculation: AVG jam
  target: ≤ 24 jam | direction: lower_is_better | bobot: 25%

PUR_SUPPLIER_PAY_SPEED | Kecepatan Bayar Supplier
  data_source: supplier_transactions (received_at → payment_date)
  calculation: AVG jam
  target: ≤ 48 jam | direction: lower_is_better | bobot: 25%

PUR_FIELDTEAM_PAY_SPEED | Kecepatan Bayar Tim Lapangan
  data_source: order_field_team_payments
  calculation: AVG jam dari order completed → paid_at
  target: ≤ 48 jam | direction: lower_is_better | bobot: 20%

PUR_VIOLATION_COUNT  | Jumlah Pelanggaran
  data_source: hrd_violations
  target: 0 | direction: lower_is_better | bobot: 15%

PUR_APPROVAL_SPEED   | Kecepatan Approve Pengadaan
  data_source: procurement_requests (awarded → purchasing_approved)
  calculation: AVG jam
  target: ≤ 12 jam | direction: lower_is_better | bobot: 15%

═══════════════════════════════════════════════════════════
DRIVER (driver)
═══════════════════════════════════════════════════════════
DRV_ONTIME_RATE      | Tingkat Tepat Waktu
  data_source: orders (driver_assignments)
  calculation: % tiba tepat waktu vs total trip
  target: ≥ 95% | direction: higher_is_better | bobot: 30%

DRV_TRIP_COUNT       | Jumlah Trip
  data_source: vehicle_trip_logs
  calculation: COUNT trips
  target: ≥ 15 per bulan | direction: higher_is_better | bobot: 20%

DRV_OVERTIME_COUNT   | Jumlah Overtime
  data_source: hrd_violations (driver_overtime)
  target: 0 | direction: lower_is_better | bobot: 20%

DRV_BUKTI_UPLOAD     | Kelengkapan Upload Bukti
  data_source: order_bukti_lapangan
  calculation: % order dengan bukti lengkap
  target: 100% | direction: higher_is_better | bobot: 15%

DRV_VIOLATION_COUNT  | Jumlah Pelanggaran (Lain)
  data_source: hrd_violations
  target: 0 | direction: lower_is_better | bobot: 15%

═══════════════════════════════════════════════════════════
VENDOR: DEKOR, KONSUMSI, PEMUKA AGAMA, TUKANG FOTO
═══════════════════════════════════════════════════════════
VND_ATTENDANCE_RATE  | Tingkat Kehadiran
  data_source: field_attendances
  calculation: % present vs scheduled
  target: ≥ 95% | direction: higher_is_better | bobot: 35%

VND_ONTIME_RATE      | Tingkat Tepat Waktu
  data_source: field_attendances
  calculation: % arrived_at ≤ scheduled_jam + threshold
  target: ≥ 90% | direction: higher_is_better | bobot: 25%

VND_REJECT_COUNT     | Jumlah Tolak Assignment
  data_source: hrd_violations (vendor_repeated_reject)
  target: 0 | direction: lower_is_better | bobot: 20%

VND_BUKTI_UPLOAD     | Kelengkapan Upload Bukti
  data_source: order_bukti_lapangan
  calculation: % order dengan bukti lengkap
  target: 100% | direction: higher_is_better | bobot: 20%

═══════════════════════════════════════════════════════════
HRD (hrd)
═══════════════════════════════════════════════════════════
HRD_RESOLVE_SPEED    | Kecepatan Resolve Pelanggaran
  data_source: hrd_violations
  calculation: AVG jam dari created_at → resolved_at
  target: ≤ 48 jam | direction: lower_is_better | bobot: 40%

HRD_RESOLVE_RATE     | Tingkat Resolve
  data_source: hrd_violations
  calculation: % resolved vs total
  target: ≥ 90% | direction: higher_is_better | bobot: 35%

HRD_ESCALATION_RATE  | Tingkat Eskalasi (semakin rendah semakin bagus)
  data_source: hrd_violations
  calculation: % escalated vs total
  target: ≤ 10% | direction: lower_is_better | bobot: 25%

═══════════════════════════════════════════════════════════
SECURITY (security)
═══════════════════════════════════════════════════════════
SEC_ATTENDANCE_RATE  | Tingkat Kehadiran
  data_source: field_attendances
  target: ≥ 98% | direction: higher_is_better | bobot: 50%

SEC_VIOLATION_COUNT  | Jumlah Pelanggaran
  data_source: hrd_violations
  target: 0 | direction: lower_is_better | bobot: 50%
```

---

### Tabel `kpi_periods` (Periode Evaluasi)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
period_name VARCHAR(100) NOT NULL             -- contoh: 'April 2026', 'Q1 2026'
period_type ENUM('monthly','quarterly','yearly') NOT NULL DEFAULT 'monthly'
start_date DATE NOT NULL
end_date DATE NOT NULL
status ENUM('open','calculating','closed') DEFAULT 'open'
-- open: periode berjalan, data terus terupdate
-- calculating: sedang proses hitung akhir
-- closed: skor final, tidak berubah lagi
closed_by UUID NULLABLE REFERENCES users(id)
closed_at TIMESTAMP NULLABLE
created_at TIMESTAMP
updated_at TIMESTAMP

UNIQUE(period_type, start_date)
```

---

### Tabel `kpi_scores` (Skor KPI per Karyawan per Periode)

Auto-calculated oleh scheduler. HRD tidak input manual.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
period_id UUID REFERENCES kpi_periods(id)
user_id UUID REFERENCES users(id)
metric_id UUID REFERENCES kpi_metric_master(id)

-- Hasil kalkulasi
actual_value DECIMAL(10,2) NOT NULL           -- nilai aktual dari data
target_value DECIMAL(10,2) NOT NULL           -- target (snapshot dari master saat hitung)
score DECIMAL(5,2) NOT NULL                   -- skor 0-100 per metrik
weighted_score DECIMAL(5,2) NOT NULL          -- score × weight / 100
weight DECIMAL(5,2) NOT NULL                  -- bobot (snapshot)

-- Detail kalkulasi (untuk transparansi)
calculation_detail JSONB NULLABLE
-- contoh: { "total_orders": 25, "avg_minutes": 22.5, "sample_count": 25 }

calculated_at TIMESTAMP NOT NULL
created_at TIMESTAMP
updated_at TIMESTAMP

UNIQUE(period_id, user_id, metric_id)
```

---

### Tabel `kpi_user_summary` (Ringkasan Total Skor per Karyawan per Periode)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
period_id UUID REFERENCES kpi_periods(id)
user_id UUID REFERENCES users(id)

total_score DECIMAL(5,2) NOT NULL             -- Σ weighted_score (0-100)
grade VARCHAR(10) NOT NULL                    -- A/B/C/D/E (dari system_thresholds)
rank_in_role SMALLINT NULLABLE                -- ranking dalam role yang sama
total_in_role SMALLINT NULLABLE               -- total orang dalam role yang sama

-- Trend vs periode sebelumnya
prev_total_score DECIMAL(5,2) NULLABLE
trend ENUM('up','down','stable') NULLABLE

calculated_at TIMESTAMP NOT NULL
created_at TIMESTAMP
updated_at TIMESTAMP

UNIQUE(period_id, user_id)
```

---

## FORMULA SCORING

```
Per metrik:

  if target_direction = 'lower_is_better':
    -- Semakin kecil aktual, semakin bagus
    if actual <= target:
      score = 100
    else:
      score = MAX(0, 100 - ((actual - target) / target × 100))

  if target_direction = 'higher_is_better':
    -- Semakin besar aktual, semakin bagus
    if actual >= target:
      score = 100
    else:
      score = MAX(0, (actual / target) × 100)

  weighted_score = score × weight / 100

Total skor user = Σ weighted_score dari semua metrik aktif untuk role user
Grade = berdasarkan system_thresholds:
  kpi_grade_a_min = 90
  kpi_grade_b_min = 75
  kpi_grade_c_min = 60
  kpi_grade_d_min = 40
  Di bawah 40 = E
```

---

## SYSTEM_THRESHOLDS — TAMBAHAN v1.16

```
kpi_grade_a_min = 90        -- skor ≥ 90 = Grade A
kpi_grade_b_min = 75        -- skor ≥ 75 = Grade B
kpi_grade_c_min = 60        -- skor ≥ 60 = Grade C
kpi_grade_d_min = 40        -- skor ≥ 40 = Grade D
                            -- skor < 40 = Grade E
kpi_low_score_alert = 60    -- skor di bawah ini → alarm ke HRD + Owner
kpi_auto_calculate_day = 1  -- tanggal berapa setiap bulan auto-hitung (1 = tanggal 1)
```

---

## SCHEDULER — KPI v1.16

```php
// Jalankan tanggal 1 setiap bulan jam 02:00 WIB
$schedule->command('kpi:calculate-monthly')
  ->monthlyOn(SystemThreshold::getValue('kpi_auto_calculate_day', 1), '02:00')
  ->timezone('Asia/Jakarta');

// Real-time update untuk periode berjalan (setiap 6 jam)
$schedule->command('kpi:refresh-current-period')->everySixHours();
```

### Command: `kpi:calculate-monthly`

```php
// 1. Tutup periode bulan lalu (jika belum)
// 2. Buka periode bulan baru (jika belum ada)
// 3. Untuk setiap user aktif:
//    a. Ambil semua kpi_metric_master yang applicable_role = user.role
//    b. Jalankan query kalkulasi per metrik
//    c. Hitung score per formula
//    d. Simpan ke kpi_scores
//    e. Hitung total → kpi_user_summary
// 4. Jika total_score < kpi_low_score_alert:
//    → Alarm ke HRD + Owner

$period = KpiPeriod::firstOrCreate([...], [...]);

User::where('is_active', true)
  ->whereNotIn('role', ['super_admin', 'consumer', 'supplier', 'viewer'])
  ->each(function ($user) use ($period) {
    $metrics = KpiMetricMaster::where('applicable_role', $user->role)
      ->where('is_active', true)->get();

    $totalWeighted = 0;

    foreach ($metrics as $metric) {
      $actual = KpiCalculator::calculate($metric, $user, $period);
      $score = KpiCalculator::score($actual, $metric->target_value, $metric->target_direction);
      $weighted = $score * $metric->weight / 100;

      KpiScore::updateOrCreate(
        ['period_id' => $period->id, 'user_id' => $user->id, 'metric_id' => $metric->id],
        [
          'actual_value' => $actual,
          'target_value' => $metric->target_value,
          'score' => $score,
          'weighted_score' => $weighted,
          'weight' => $metric->weight,
          'calculated_at' => now(),
        ]
      );

      $totalWeighted += $weighted;
    }

    $grade = KpiCalculator::grade($totalWeighted);

    KpiUserSummary::updateOrCreate(
      ['period_id' => $period->id, 'user_id' => $user->id],
      [
        'total_score' => $totalWeighted,
        'grade' => $grade,
        'calculated_at' => now(),
      ]
    );

    if ($totalWeighted < SystemThreshold::getValue('kpi_low_score_alert', 60)) {
      NotificationService::sendToRole('hrd', 'HIGH',
        "KPI Rendah: {$user->name}",
        "Skor KPI {$user->name} ({$user->role}): {$totalWeighted} (Grade {$grade})"
      );
    }
  });

// Hitung rank per role
KpiCalculator::calculateRankings($period);
```

### Class: `KpiCalculator`

```php
class KpiCalculator
{
  public static function calculate(KpiMetricMaster $metric, User $user, KpiPeriod $period): float
  {
    return match($metric->metric_code) {
      // SO
      'SO_PROCESS_SPEED' => Order::where('so_user_id', $user->id)
        ->whereBetween('confirmed_at', [$period->start_date, $period->end_date])
        ->whereNotNull('confirmed_at')
        ->avg(DB::raw('EXTRACT(EPOCH FROM (confirmed_at - created_at))/60')) ?? 0,

      'SO_ORDER_COUNT' => Order::where('so_user_id', $user->id)
        ->whereBetween('confirmed_at', [$period->start_date, $period->end_date])
        ->count(),

      // GUDANG
      'GDG_EQUIPMENT_RETURN' => self::percentageQuery(
        OrderEquipmentItem::whereHas('order', fn($q) => $q->whereBetween('completed_at', [$period->start_date, $period->end_date])),
        fn($q) => $q->where('status', 'returned'),
      ),

      // DRIVER
      'DRV_TRIP_COUNT' => VehicleTripLog::where('driver_id', $user->id)
        ->whereBetween('waktu_pemakaian', [$period->start_date, $period->end_date])
        ->count(),

      // VENDOR (generic attendance)
      'VND_ATTENDANCE_RATE' => self::percentageQuery(
        FieldAttendance::where('user_id', $user->id)
          ->whereBetween('attendance_date', [$period->start_date, $period->end_date]),
        fn($q) => $q->whereIn('status', ['present', 'late']),
      ),

      // VIOLATIONS (generic, semua role)
      default => str_contains($metric->metric_code, 'VIOLATION_COUNT')
        ? HrdViolation::where('violated_by', $user->id)
            ->whereBetween('created_at', [$period->start_date, $period->end_date])
            ->count()
        : 0,
    };
  }

  public static function score(float $actual, float $target, string $direction): float
  {
    if ($target == 0) return $actual == 0 ? 100 : 0;

    return match($direction) {
      'lower_is_better' => $actual <= $target ? 100 : max(0, 100 - (($actual - $target) / $target * 100)),
      'higher_is_better' => $actual >= $target ? 100 : max(0, ($actual / $target) * 100),
    };
  }

  public static function grade(float $totalScore): string
  {
    $a = SystemThreshold::getValue('kpi_grade_a_min', 90);
    $b = SystemThreshold::getValue('kpi_grade_b_min', 75);
    $c = SystemThreshold::getValue('kpi_grade_c_min', 60);
    $d = SystemThreshold::getValue('kpi_grade_d_min', 40);

    return match(true) {
      $totalScore >= $a => 'A',
      $totalScore >= $b => 'B',
      $totalScore >= $c => 'C',
      $totalScore >= $d => 'D',
      default => 'E',
    };
  }
}
```

---

## API — ENDPOINT KPI v1.16

### HRD — Kelola KPI
```
-- Master Metrik (CRUD via admin master yang sudah ada)
GET    /admin/master/kpi-metrics                  -- list semua metrik per role
POST   /admin/master/kpi-metrics                  -- tambah metrik baru
PUT    /admin/master/kpi-metrics/{id}             -- ubah target, bobot, dll
DELETE /admin/master/kpi-metrics/{id}             -- soft-delete

-- Periode
GET    /hrd/kpi/periods                           -- list semua periode
POST   /hrd/kpi/periods                           -- buat periode baru (jika tidak auto)
PUT    /hrd/kpi/periods/{id}/close                -- tutup periode (finalisasi skor)
POST   /hrd/kpi/periods/{id}/recalculate          -- hitung ulang semua skor

-- Skor & Dashboard
GET    /hrd/kpi/scores?period_id=X&role=Y         -- skor semua user (filter role, periode)
GET    /hrd/kpi/scores/user/{userId}              -- skor 1 user semua periode (trend)
GET    /hrd/kpi/scores/user/{userId}?period_id=X  -- detail per metrik untuk 1 user 1 periode
GET    /hrd/kpi/rankings?period_id=X&role=Y       -- ranking per role per periode
GET    /hrd/kpi/summary?period_id=X               -- ringkasan: distribusi grade A/B/C/D/E
```

### Owner — Lihat KPI
```
GET    /owner/kpi/summary?period_id=X             -- ringkasan semua karyawan
GET    /owner/kpi/scores/user/{userId}            -- detail per user
GET    /owner/kpi/rankings?role=Y&period_id=X     -- ranking per role
```

### Self — Karyawan Lihat KPI Sendiri
```
GET    /me/kpi                                    -- skor periode berjalan (diri sendiri)
GET    /me/kpi/history                            -- histori semua periode
GET    /me/kpi/{periodId}                         -- detail per metrik untuk 1 periode
```

---

## FLUTTER — SCREEN KPI v1.16

```
lib/features/
  ├── hrd/screens/
  │   ├── kpi_dashboard_screen.dart           -- BARU: ringkasan KPI semua karyawan
  │   │     -- Dropdown pilih periode (default: bulan ini)
  │   │     -- Distribusi grade: A=X orang, B=Y orang, C=Z orang (pie chart)
  │   │     -- List karyawan dengan skor terendah (alert)
  │   │     -- Tombol "Hitung Ulang" + "Tutup Periode"
  │   │
  │   ├── kpi_role_ranking_screen.dart        -- BARU: ranking per role
  │   │     -- Tab per role: SO | Gudang | Purchasing | Driver | ...
  │   │     -- Per tab: list karyawan diurutkan skor tertinggi
  │   │     -- Badge grade (A=hijau, B=biru, C=kuning, D=oranye, E=merah)
  │   │     -- Trend arrow: ↑ naik, ↓ turun, → stabil
  │   │
  │   ├── kpi_user_detail_screen.dart         -- BARU: detail KPI 1 karyawan
  │   │     -- Header: nama, role, grade, total skor, rank
  │   │     -- Radar chart: visualisasi skor per metrik
  │   │     -- Tabel metrik: nama | target | aktual | skor | bobot | weighted
  │   │     -- Trend line chart: skor per bulan (6 bulan terakhir)
  │   │
  │   └── kpi_metric_manage_screen.dart       -- BARU: kelola metrik per role
  │         -- List metrik per role (tab per role)
  │         -- Per metrik: target, bobot, toggle aktif/nonaktif
  │         -- Validasi: total bobot per role harus = 100%
  │         -- Tombol tambah metrik baru
  │
  ├── shared/screens/
  │   └── my_kpi_screen.dart                  -- BARU: karyawan lihat KPI sendiri
  │         -- Skor periode berjalan (real-time, refresh setiap 6 jam)
  │         -- Grade badge besar
  │         -- Per metrik: progress bar (aktual vs target)
  │         -- Histori: trend skor per bulan
  │         -- Accessible dari menu profil semua role
```

---

## TABEL ALARM KPI v1.16

| Momen | User | HRD | Owner |
|-------|------|-----|-------|
| Periode baru dibuka (auto) | NORMAL (KPI direset) | HIGH (periode baru) | NORMAL |
| Skor dihitung (bulanan) | HIGH (lihat skor kamu) | ALARM (review semua skor) | HIGH (ringkasan) |
| Skor user < threshold | — | ALARM (perlu perhatian) | HIGH |
| User naik grade | HIGH (selamat!) | NORMAL | — |
| User turun grade | HIGH (perhatian) | HIGH | NORMAL |

---

## ATURAN BISNIS KPI v1.16

```
1. Total bobot semua metrik aktif per role HARUS = 100%
   → Validasi di backend saat simpan/ubah metrik
   → Jika tidak 100%, tampilkan warning di UI dan blokir kalkulasi

2. Skor dihitung otomatis — HRD TIDAK bisa input skor manual
   → Menjamin objektivitas, tidak ada bias

3. Karyawan bisa lihat KPI sendiri (transparansi)
   → Tapi TIDAK bisa lihat KPI orang lain (kecuali HRD & Owner)

4. Periode yang sudah ditutup (closed) tidak bisa dihitung ulang
   → Kecuali Owner eksplisit membuka kembali

5. KPI hanya untuk role internal + vendor (bukan consumer, supplier, super_admin, viewer)

6. Metrik baru yang ditambahkan HRD berlaku mulai periode berikutnya
   → Tidak retroaktif ke periode yang sudah berjalan

7. Jika user baru bergabung di tengah periode:
   → Skor dihitung proporsional (berdasarkan hari aktif / total hari periode)
```

---

## CHANGELOG v1.16

### v1.16 — Sistem KPI Karyawan Auto-Calculated

**Prinsip:**
- HRD set metrik + target + bobot per role
- Sistem hitung skor otomatis dari data operasional yang sudah ada
- Tidak ada penilaian manual — 100% data-driven

**Tabel Baru:**
- `kpi_metric_master` — master metrik KPI per role (data-driven, CRUD via UI)
- `kpi_periods` — periode evaluasi (monthly/quarterly/yearly)
- `kpi_scores` — skor per metrik per karyawan per periode (auto-calculated)
- `kpi_user_summary` — ringkasan total skor + grade + ranking

**Fitur:**
- Auto-calculate bulanan via scheduler
- Real-time refresh setiap 6 jam untuk periode berjalan
- Grade A/B/C/D/E dengan threshold yang bisa dikonfigurasi Owner
- Ranking per role per periode
- Trend tracking (naik/turun/stabil)
- Alert otomatis jika skor rendah
- Karyawan bisa lihat KPI sendiri (transparan)
- Radar chart + trend line chart di Flutter UI

---

# SANTA MARIA — PATCH v1.17
# Sistem Presensi Universal Anti-Mock Location

---

## LATAR BELAKANG v1.17

Presensi sebelumnya (v1.14 `field_attendances`) hanya mencakup vendor per order. Patch ini memperluas presensi ke **semua karyawan dan orang lapangan** dengan perlindungan anti-mock location berlapis.

**Yang termasuk:**
- Semua role internal: SO, Gudang, Purchasing, Driver, HRD, Security, Owner
- Semua role vendor: Dekor, Konsumsi, Pemuka Agama, Tukang Foto

**Yang TIDAK termasuk:**
- Supplier (eksternal, hanya stok barang via e-Katalog)
- Consumer (eksternal)
- Super Admin (sistem)
- Viewer (read-only)

**Dua jenis presensi:**
1. **Presensi Harian** — clock in/out kerja harian (kantor, gudang, pos)
2. **Presensi Order** — hadir di lokasi order (`field_attendances`, sudah ada, diperkaya anti-mock)

---

## ANTI-MOCK LOCATION — ARSITEKTUR 6 LAPIS

Setiap check-in (harian maupun order) melewati 6 lapisan validasi. Jika SATU saja gagal, check-in **ditolak** dan dicatat sebagai `mock_attempt`.

```
╔══════════════════════════════════════════════════════════════════════════╗
║  ANTI-MOCK LOCATION — 6 LAPIS VALIDASI                                 ║
╚══════════════════════════════════════════════════════════════════════════╝

┌─────────────────────────────────────────────────────────────────────────┐
│ LAPIS 1 — FLUTTER: DETEKSI MOCK PROVIDER                              │
│                                                                         │
│ Android: Location.isFromMockProvider() / isMock flag                    │
│ → Jika true: TOLAK langsung, tidak kirim ke server                     │
│ → Cek juga: Settings.Secure.ALLOW_MOCK_LOCATION                        │
│                                                                         │
│ Implementasi:                                                           │
│   Position position = await Geolocator.getCurrentPosition();            │
│   if (position.isMocked) {                                              │
│     throw MockLocationDetectedException();                              │
│   }                                                                     │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ LAPIS 2 — FLUTTER: GOOGLE PLAY INTEGRITY API                           │
│                                                                         │
│ Verifikasi device belum di-root/tamper.                                 │
│ Request integrity token → kirim ke backend → backend verify ke Google.  │
│                                                                         │
│ Jika verdict TIDAK meets_device_integrity:                              │
│   → TOLAK check-in                                                      │
│   → Tampilkan: "Perangkat tidak memenuhi syarat keamanan"               │
│                                                                         │
│ Package: play_integrity (pub.dev)                                       │
│ Backend: Google Play Integrity API verify endpoint                      │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ LAPIS 3 — FLUTTER: DETEKSI APP MOCK LOCATION                           │
│                                                                         │
│ Scan apakah ada app fake GPS terinstall:                                │
│   - Fake GPS, Mock Locations, GPS Emulator, Location Changer, dll       │
│   - Cek via installed_apps atau package_info                            │
│                                                                         │
│ Maintain daftar package name di system_thresholds:                      │
│   mock_location_app_packages = [                                        │
│     "com.lexa.fakegps",                                                 │
│     "com.incorporateapps.fakegps.fre",                                  │
│     "com.fakegps.mock",                                                 │
│     ... (diupdate berkala via API, bukan hardcode)                       │
│   ]                                                                     │
│                                                                         │
│ Endpoint: GET /system/mock-app-blacklist                                │
│ → Flutter ambil list saat startup, cache lokal, refresh harian          │
│                                                                         │
│ Jika ditemukan: TOLAK + tampilkan "Hapus aplikasi [nama] untuk check-in"│
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ LAPIS 4 — FLUTTER: FOTO SELFIE WAJIB                                   │
│                                                                         │
│ Setiap check-in WAJIB ambil foto selfie via kamera depan.              │
│ Foto diambil langsung oleh app (bukan dari galeri).                     │
│ Metadata EXIF disertakan: timestamp, device info.                       │
│                                                                         │
│ Foto dikirim ke backend bersama data lokasi.                            │
│ Disimpan di R2: attendance_selfies/{user_id}/{date}/{type}.jpg          │
│                                                                         │
│ Tujuan: bukti visual bahwa orang tersebut benar-benar di lokasi.        │
│ HRD/Owner bisa review foto kapan saja dari dashboard.                   │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ LAPIS 5 — BACKEND: VALIDASI LOKASI & VELOCITY CHECK                    │
│                                                                         │
│ 5a. Geofence validation:                                                │
│   → Hitung jarak (Haversine) antara lokasi user vs lokasi target        │
│   → Jika jarak > radius yang dikonfigurasi: TOLAK                       │
│                                                                         │
│ 5b. Velocity check (anti-teleportasi):                                  │
│   → Ambil lokasi check-in terakhir user (dari tabel manapun)            │
│   → Hitung kecepatan: jarak / waktu sejak lokasi terakhir              │
│   → Jika kecepatan > max_human_speed (system_thresholds, default 200    │
│     km/jam — pesawat dikecualikan, tapi mock biasanya > 1000 km/jam):   │
│     → FLAG sebagai suspicious, catat di attendance_flags                 │
│     → Jika > 500 km/jam: TOLAK otomatis                                 │
│                                                                         │
│ 5c. isMocked flag dari client:                                          │
│   → Backend JUGA cek field is_mocked dari payload                       │
│   → Defense in depth: client bisa di-bypass, backend double-check       │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ LAPIS 6 — BACKEND: DEVICE FINGERPRINT & ANOMALY DETECTION              │
│                                                                         │
│ Setiap request check-in menyertakan device_fingerprint:                 │
│   { device_id, model, os_version, app_version, ip_address }            │
│                                                                         │
│ Validasi:                                                               │
│   → 1 user = 1 device aktif (konfigurasi di system_thresholds)          │
│   → Jika user check-in dari device berbeda dari biasanya:               │
│     → FLAG sebagai suspicious (tidak tolak, tapi catat)                 │
│   → Jika 2 user check-in dari device_id yang sama:                     │
│     → TOLAK user kedua + alarm HRD "Kemungkinan titip absen"            │
│                                                                         │
│ Log semua attempt (berhasil maupun gagal) di attendance_logs            │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## DATABASE — TABEL PRESENSI v1.17

### Tabel `attendance_locations` (Master Lokasi Presensi)

Titik-titik geofence untuk presensi harian. Dikelola Super Admin/HRD via UI. (v1.27: Owner view only)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
location_code VARCHAR(50) UNIQUE NOT NULL     -- contoh: 'KANTOR_UTAMA', 'GUDANG', 'POS_SECURITY'
location_name VARCHAR(255) NOT NULL           -- contoh: 'Kantor Santa Maria'
address TEXT NULLABLE

-- Koordinat geofence
latitude DECIMAL(10,7) NOT NULL
longitude DECIMAL(10,7) NOT NULL
radius_meters INTEGER NOT NULL DEFAULT 100    -- radius geofence (meter)

-- Role yang boleh check-in di lokasi ini
applicable_roles JSONB NOT NULL DEFAULT '[]'
-- contoh: ["service_officer","gudang","purchasing","hrd","security","owner"]
-- kosong [] = semua role boleh

-- WiFi verification (opsional, lapis tambahan)
wifi_bssid VARCHAR(50) NULLABLE              -- MAC address WiFi kantor (jika ada)
wifi_ssid VARCHAR(100) NULLABLE              -- nama WiFi (untuk display)

is_active BOOLEAN DEFAULT TRUE
created_at TIMESTAMP
updated_at TIMESTAMP
```

Initial seed (disesuaikan dengan lokasi aktual saat deploy):
```
KANTOR_UTAMA  | Kantor Santa Maria        | lat/lng: [isi saat deploy] | radius: 100m
GUDANG        | Gudang Santa Maria        | lat/lng: [isi saat deploy] | radius: 150m
POS_SECURITY  | Pos Security              | lat/lng: [isi saat deploy] | radius: 50m
```

---

### Tabel `work_shifts` (Master Shift Kerja)

Shift kerja dikelola sebagai master data — HRD bisa atur via UI.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
shift_code VARCHAR(50) UNIQUE NOT NULL        -- contoh: 'PAGI', 'SIANG', 'MALAM', 'FULL'
shift_name VARCHAR(100) NOT NULL
start_time TIME NOT NULL                      -- contoh: 08:00
end_time TIME NOT NULL                        -- contoh: 17:00
is_overnight BOOLEAN DEFAULT FALSE            -- shift malam (end_time < start_time)
applicable_roles JSONB NOT NULL DEFAULT '[]'  -- role yang pakai shift ini
is_active BOOLEAN DEFAULT TRUE
created_at TIMESTAMP
updated_at TIMESTAMP
```

Initial seed:
```
PAGI   | Shift Pagi   | 08:00 - 16:00 | ["gudang","purchasing","hrd"]
SIANG  | Shift Siang  | 10:00 - 18:00 | ["service_officer"]
MALAM  | Shift Malam  | 20:00 - 06:00 | ["security"] | is_overnight: true
FULL   | Full Day     | 08:00 - 17:00 | ["owner"]
FLEXI  | Fleksibel    | 07:00 - 22:00 | ["driver"] -- driver jam kerja fleksibel
```

---

### Tabel `user_shift_assignments` (Jadwal Shift per Karyawan)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id UUID REFERENCES users(id)
shift_id UUID REFERENCES work_shifts(id)
location_id UUID REFERENCES attendance_locations(id)
effective_date DATE NOT NULL                  -- berlaku mulai tanggal ini
end_date DATE NULLABLE                        -- NULL = masih berlaku
day_of_week SMALLINT NULLABLE                 -- 0=Minggu..6=Sabtu, NULL=setiap hari
is_active BOOLEAN DEFAULT TRUE
assigned_by UUID REFERENCES users(id)         -- HRD/Owner yang assign
created_at TIMESTAMP
updated_at TIMESTAMP
```

---

### Tabel `daily_attendances` (Presensi Harian — Clock In/Out)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id UUID REFERENCES users(id)
attendance_date DATE NOT NULL
shift_id UUID NULLABLE REFERENCES work_shifts(id)
location_id UUID REFERENCES attendance_locations(id)

-- Clock In
clock_in_at TIMESTAMP NULLABLE
clock_in_lat DECIMAL(10,7) NULLABLE
clock_in_lng DECIMAL(10,7) NULLABLE
clock_in_distance_meters DECIMAL(10,2) NULLABLE  -- jarak dari titik lokasi
clock_in_selfie_path TEXT NULLABLE               -- R2 path foto selfie
clock_in_device_id VARCHAR(255) NULLABLE

-- Clock Out
clock_out_at TIMESTAMP NULLABLE
clock_out_lat DECIMAL(10,7) NULLABLE
clock_out_lng DECIMAL(10,7) NULLABLE
clock_out_distance_meters DECIMAL(10,2) NULLABLE
clock_out_selfie_path TEXT NULLABLE
clock_out_device_id VARCHAR(255) NULLABLE

-- Status
status ENUM(
  'scheduled',       -- dijadwalkan (auto-generate dari shift assignment)
  'present',         -- hadir tepat waktu
  'late',            -- hadir terlambat
  'early_leave',     -- pulang lebih awal
  'absent',          -- tidak hadir (auto-set oleh scheduler)
  'leave',           -- izin/cuti (diinput HRD)
  'holiday'          -- libur (auto dari kalender)
) DEFAULT 'scheduled'

late_minutes INTEGER DEFAULT 0               -- berapa menit terlambat
early_leave_minutes INTEGER DEFAULT 0        -- berapa menit pulang awal
overtime_minutes INTEGER DEFAULT 0           -- berapa menit lembur
work_duration_minutes INTEGER DEFAULT 0      -- total durasi kerja (clock_out - clock_in)

-- Anti-mock flags
is_mock_detected BOOLEAN DEFAULT FALSE       -- terdeteksi mock di salah satu lapis
mock_detection_detail JSONB NULLABLE         -- detail: lapis mana yang detect
-- contoh: { "layer": 5, "reason": "velocity_exceeded", "speed_kmh": 1200 }

-- Approval (untuk kasus khusus)
approved_by UUID NULLABLE REFERENCES users(id)  -- HRD approve manual (misal: izin, koreksi)
approval_notes TEXT NULLABLE

notes TEXT NULLABLE
created_at TIMESTAMP
updated_at TIMESTAMP

UNIQUE(user_id, attendance_date)
```

---

### Perkaya Tabel `field_attendances` — Tambah Kolom Anti-Mock

```sql
-- Tambahkan ke tabel field_attendances (v1.14):

-- Lokasi check-in
check_in_lat DECIMAL(10,7) NULLABLE
check_in_lng DECIMAL(10,7) NULLABLE
check_in_distance_meters DECIMAL(10,2) NULLABLE  -- jarak dari lokasi order
check_in_selfie_path TEXT NULLABLE               -- foto selfie saat check-in

-- Lokasi check-out
check_out_lat DECIMAL(10,7) NULLABLE
check_out_lng DECIMAL(10,7) NULLABLE
check_out_selfie_path TEXT NULLABLE

-- Anti-mock
check_in_device_id VARCHAR(255) NULLABLE
is_mock_detected BOOLEAN DEFAULT FALSE
mock_detection_detail JSONB NULLABLE
```

---

### Tabel `attendance_logs` (Log Semua Attempt — Berhasil & Gagal)

Untuk audit trail dan analisis pola kecurangan.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id UUID REFERENCES users(id)
attempt_type ENUM('daily_clock_in','daily_clock_out','field_check_in','field_check_out') NOT NULL
attendance_id UUID NULLABLE                   -- FK ke daily_attendances atau field_attendances

-- Lokasi yang dikirim
submitted_lat DECIMAL(10,7) NOT NULL
submitted_lng DECIMAL(10,7) NOT NULL
target_lat DECIMAL(10,7) NOT NULL             -- lokasi target (kantor/order)
target_lng DECIMAL(10,7) NOT NULL
distance_meters DECIMAL(10,2) NOT NULL

-- Device info
device_id VARCHAR(255) NOT NULL
device_model VARCHAR(255) NULLABLE
os_version VARCHAR(50) NULLABLE
app_version VARCHAR(50) NULLABLE
ip_address VARCHAR(50) NULLABLE

-- Hasil validasi per lapis
layer_1_mock_provider BOOLEAN DEFAULT FALSE   -- isFromMockProvider
layer_2_play_integrity BOOLEAN DEFAULT TRUE   -- lulus Play Integrity
layer_3_mock_app_found VARCHAR(255) NULLABLE  -- nama app mock yang ditemukan (NULL = bersih)
layer_4_selfie_taken BOOLEAN DEFAULT FALSE
layer_5_geofence_pass BOOLEAN DEFAULT FALSE
layer_5_velocity_kmh DECIMAL(10,2) NULLABLE   -- kecepatan dari lokasi terakhir
layer_6_device_consistent BOOLEAN DEFAULT TRUE -- device sama dengan biasa

-- Hasil akhir
is_accepted BOOLEAN NOT NULL                  -- diterima atau ditolak
rejection_reason TEXT NULLABLE                -- alasan tolak (jika ditolak)

created_at TIMESTAMP
```

---

### Tabel `mock_app_blacklist` (Daftar App Mock Location)

Dikelola admin, di-sync ke Flutter.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
package_name VARCHAR(255) UNIQUE NOT NULL     -- contoh: 'com.lexa.fakegps'
app_name VARCHAR(255) NOT NULL                -- contoh: 'Fake GPS Location'
is_active BOOLEAN DEFAULT TRUE
added_by UUID NULLABLE REFERENCES users(id)
created_at TIMESTAMP
```

---

## SYSTEM_THRESHOLDS — TAMBAHAN v1.17

```
-- Presensi Harian
daily_attendance_late_minutes = 15         -- lebih dari ini = terlambat
daily_attendance_early_leave_minutes = 30  -- pulang lebih awal dari ini = early_leave
daily_attendance_absent_deadline = '10:00' -- jika belum clock-in jam segini = absent

-- Anti-Mock
mock_max_velocity_kmh = 200                -- kecepatan > ini = suspicious
mock_reject_velocity_kmh = 500             -- kecepatan > ini = TOLAK otomatis
mock_max_devices_per_user = 1              -- jumlah device aktif per user
mock_alert_on_attempt = true               -- kirim alarm HRD saat mock terdeteksi

-- Geofence
daily_attendance_radius_meters = 100       -- radius default presensi harian (override per lokasi)
field_attendance_radius_meters = 500       -- radius presensi order (sudah ada, renamed)
```

---

## FLUTTER — ANTI-MOCK SERVICE

```dart
// lib/core/services/anti_mock_service.dart

class AntiMockService {
  /// Validasi lengkap sebelum kirim check-in ke backend.
  /// Throw exception jika gagal di lapis manapun.
  static Future<AttendancePayload> validateAndCollect({
    required LatLng targetLocation,
    required double radiusMeters,
  }) async {
    // ── LAPIS 1: Mock Provider ──
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    if (position.isMocked) {
      throw AntiMockException('Mock location terdeteksi', layer: 1);
    }

    // ── LAPIS 2: Play Integrity ──
    final integrityResult = await PlayIntegrity.requestIntegrityToken();
    // Token dikirim ke backend untuk verifikasi

    // ── LAPIS 3: Cek app mock terinstall ──
    final blacklist = await _getBlacklist(); // cached, refresh harian
    final installedApps = await InstalledApps.getInstalledApps();
    for (final app in installedApps) {
      if (blacklist.contains(app.packageName)) {
        throw AntiMockException(
          'Aplikasi ${app.name} harus dihapus untuk check-in',
          layer: 3, detail: app.packageName,
        );
      }
    }

    // ── LAPIS 4: Foto selfie ──
    final selfieFile = await _takeSelfie(); // kamera depan, langsung capture
    if (selfieFile == null) {
      throw AntiMockException('Foto selfie wajib untuk check-in', layer: 4);
    }

    // ── LAPIS 5 (client-side): Geofence check ──
    final distance = Geolocator.distanceBetween(
      position.latitude, position.longitude,
      targetLocation.latitude, targetLocation.longitude,
    );
    if (distance > radiusMeters) {
      throw AntiMockException(
        'Anda di luar jangkauan (${distance.toInt()}m dari lokasi)',
        layer: 5,
      );
    }

    // ── Return payload untuk dikirim ke backend ──
    return AttendancePayload(
      latitude: position.latitude,
      longitude: position.longitude,
      isMocked: position.isMocked,
      distanceMeters: distance,
      integrityToken: integrityResult.token,
      selfieFile: selfieFile,
      deviceId: await _getDeviceId(),
      deviceModel: await _getDeviceModel(),
      osVersion: await _getOsVersion(),
      appVersion: await _getAppVersion(),
    );
  }

  static Future<File?> _takeSelfie() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 640,
      maxHeight: 640,
      imageQuality: 70,
    );
    return photo != null ? File(photo.path) : null;
  }
}
```

---

## BACKEND — VALIDASI CHECK-IN

```php
// app/Services/AttendanceValidationService.php

class AttendanceValidationService
{
  public function validate(User $user, AttendanceRequest $request): ValidationResult
  {
    $log = new AttendanceLog([
      'user_id' => $user->id,
      'submitted_lat' => $request->latitude,
      'submitted_lng' => $request->longitude,
      'device_id' => $request->device_id,
      // ... fill semua field
    ]);

    // ── LAPIS 2: Verify Play Integrity Token ──
    $integrityOk = PlayIntegrityVerifier::verify($request->integrity_token);
    $log->layer_2_play_integrity = $integrityOk;
    if (!$integrityOk) {
      return $this->reject($log, 'Device integrity check gagal');
    }

    // ── LAPIS 5a: Geofence ──
    $distance = $this->haversine(
      $request->latitude, $request->longitude,
      $request->target_lat, $request->target_lng
    );
    $log->distance_meters = $distance;
    $log->layer_5_geofence_pass = $distance <= $request->radius_meters;
    if (!$log->layer_5_geofence_pass) {
      return $this->reject($log, "Di luar radius ({$distance}m)");
    }

    // ── LAPIS 5b: Velocity check ──
    $lastLog = AttendanceLog::where('user_id', $user->id)
      ->where('is_accepted', true)
      ->latest('created_at')
      ->first();

    if ($lastLog) {
      $timeDiffHours = now()->diffInSeconds($lastLog->created_at) / 3600;
      if ($timeDiffHours > 0) {
        $distFromLast = $this->haversine(
          $request->latitude, $request->longitude,
          $lastLog->submitted_lat, $lastLog->submitted_lng
        );
        $velocity = ($distFromLast / 1000) / $timeDiffHours; // km/h
        $log->layer_5_velocity_kmh = $velocity;

        $rejectThreshold = SystemThreshold::getValue('mock_reject_velocity_kmh', 500);
        if ($velocity > $rejectThreshold) {
          return $this->reject($log, "Kecepatan tidak wajar: {$velocity} km/jam");
        }
      }
    }

    // ── LAPIS 6: Device consistency ──
    $knownDevice = UserDevice::where('user_id', $user->id)
      ->where('is_active', true)->first();

    if ($knownDevice && $knownDevice->device_id !== $request->device_id) {
      // Device berbeda — cek apakah sudah dipakai user lain hari ini
      $otherUser = AttendanceLog::where('device_id', $request->device_id)
        ->where('user_id', '!=', $user->id)
        ->whereDate('created_at', today())
        ->where('is_accepted', true)
        ->exists();

      if ($otherUser) {
        return $this->reject($log, 'Device sudah digunakan user lain — kemungkinan titip absen');
      }

      $log->layer_6_device_consistent = false;
      // Tidak tolak, tapi flag + notif HRD
      NotificationService::sendToRole('hrd', 'HIGH',
        'Device Berbeda',
        "{$user->name} check-in dari device baru: {$request->device_model}"
      );
    }

    // ── LULUS SEMUA ──
    $log->is_accepted = true;
    $log->save();

    return ValidationResult::accepted($log);
  }
}
```

---

## API — ENDPOINT PRESENSI v1.17

### Presensi Harian (Semua Karyawan)
```
-- Clock in/out
POST   /attendance/clock-in                       -- clock in harian
  body: { latitude, longitude, integrity_token, device_id, device_model,
          os_version, app_version, selfie: file }
  response: { attendance_id, status, clock_in_at, distance_meters, location_name }

POST   /attendance/clock-out                      -- clock out harian
  body: { latitude, longitude, integrity_token, device_id, selfie: file }
  response: { attendance_id, status, clock_out_at, work_duration_minutes }

-- Riwayat
GET    /attendance/me                             -- riwayat presensi sendiri (paginated)
GET    /attendance/me/today                       -- status hari ini
GET    /attendance/me/summary?month=2026-04       -- ringkasan bulanan (hadir/terlambat/absen)

-- HRD Dashboard
GET    /hrd/attendance                            -- semua presensi hari ini (filter role, status)
GET    /hrd/attendance/summary?month=2026-04      -- ringkasan bulanan semua karyawan
GET    /hrd/attendance/user/{userId}              -- riwayat 1 karyawan
GET    /hrd/attendance/anomalies                  -- list mock attempts + suspicious flags
PUT    /hrd/attendance/{id}/override              -- koreksi manual (izin, sakit, dll)
  body: { status: 'leave', notes: 'Izin sakit - surat dokter' }

-- Owner
GET    /owner/attendance/summary?month=2026-04    -- ringkasan semua
GET    /owner/attendance/realtime                 -- siapa yang sudah/belum clock-in hari ini
```

### Presensi Order (Perkaya v1.14)
```
-- Endpoint yang sudah ada, diperkaya dengan anti-mock payload:
POST   /vendor/attendances/{id}/check-in
  body: { latitude, longitude, integrity_token, device_id, device_model,
          os_version, app_version, selfie: file }
  -- Backend validasi via AttendanceValidationService yang sama

POST   /vendor/attendances/{id}/check-out
  body: { latitude, longitude, selfie: file }
```

### Master Data
```
-- Lokasi presensi (Owner/HRD)
GET    /admin/master/attendance-locations
POST   /admin/master/attendance-locations
PUT    /admin/master/attendance-locations/{id}

-- Shift kerja (HRD)
GET    /admin/master/work-shifts
POST   /admin/master/work-shifts
PUT    /admin/master/work-shifts/{id}

-- Jadwal shift per karyawan (HRD)
GET    /hrd/shift-assignments?user_id=X
POST   /hrd/shift-assignments
PUT    /hrd/shift-assignments/{id}

-- Mock app blacklist (Super Admin)
GET    /system/mock-app-blacklist                 -- Flutter ambil ini saat startup
POST   /admin/mock-app-blacklist
DELETE /admin/mock-app-blacklist/{id}

-- Audit log
GET    /hrd/attendance-logs                       -- semua attempt (filter: rejected, mock)
GET    /hrd/attendance-logs/user/{userId}         -- log 1 user
```

---

## FLUTTER — SCREEN PRESENSI v1.17

```
lib/features/
  ├── attendance/                              -- BARU: shared module presensi
  │   ├── data/attendance_repository.dart
  │   ├── services/anti_mock_service.dart      -- validasi 6 lapis (client-side)
  │   └── screens/
  │       ├── clock_in_screen.dart             -- screen utama clock in
  │       │     -- Tampilkan: peta lokasi user + radius geofence lokasi terdekat
  │       │     -- Status: "Dalam jangkauan" (hijau) / "Di luar jangkauan" (merah)
  │       │     -- Tombol besar "CLOCK IN" (aktif hanya jika dalam radius)
  │       │     -- Tekan → kamera selfie langsung terbuka → ambil foto
  │       │     -- Loading validasi 6 lapis → sukses/gagal
  │       │     -- Jika gagal: pesan jelas per lapis yang gagal
  │       │
  │       ├── clock_out_screen.dart            -- sama seperti clock_in tapi untuk pulang
  │       │
  │       ├── my_attendance_screen.dart        -- riwayat presensi sendiri
  │       │     -- Kalender bulan: warna per hari (hijau=hadir, merah=absen, kuning=terlambat)
  │       │     -- Tap hari → detail: jam masuk, jam pulang, durasi, status
  │       │     -- Summary: total hadir, terlambat, absen, izin
  │       │
  │       └── attendance_home_widget.dart      -- widget kecil untuk home screen semua role
  │             -- Menampilkan: "Belum clock in" / "Sudah clock in jam 08:02"
  │             -- Quick action button: Clock In / Clock Out
  │
  ├── hrd/screens/
  │   ├── attendance_dashboard_screen.dart     -- BARU: dashboard presensi semua karyawan
  │   │     -- Realtime: siapa sudah masuk, siapa belum
  │   │     -- Filter: per role, per lokasi, per status
  │   │     -- Alert: mock attempts hari ini (merah, paling atas)
  │   │     -- Summary: total hadir / total karyawan
  │   │
  │   ├── attendance_anomaly_screen.dart       -- BARU: list kecurangan terdeteksi
  │   │     -- Per anomali: nama, waktu, lapis yang gagal, detail
  │   │     -- Foto selfie (jika ada) untuk verifikasi visual
  │   │     -- Tombol: "Buat Pelanggaran" → otomatis isi hrd_violations
  │   │
  │   ├── shift_management_screen.dart         -- BARU: kelola shift + assign ke karyawan
  │   │     -- Tab "Master Shift": CRUD shift kerja
  │   │     -- Tab "Assignment": tabel karyawan × shift × lokasi
  │   │
  │   └── attendance_location_screen.dart      -- BARU: kelola lokasi geofence
  │         -- Peta dengan marker per lokasi + radius circle
  │         -- CRUD lokasi: nama, koordinat, radius, role yang boleh
  │         -- Tap marker → edit detail
```

---

## SCHEDULER — PRESENSI v1.17

```php
// Jalankan setiap hari kerja pagi — generate record presensi harian
$schedule->command('attendance:generate-daily')
  ->dailyAt('00:01')->timezone('Asia/Jakarta');

// Cek karyawan yang belum clock-in — tandai absent
$schedule->command('attendance:check-absent')
  ->dailyAt(SystemThreshold::getValue('daily_attendance_absent_deadline', '10:00'))
  ->timezone('Asia/Jakarta');

// Cek karyawan yang lupa clock-out — auto clock-out di akhir shift
$schedule->command('attendance:auto-clock-out')
  ->dailyAt('23:55')->timezone('Asia/Jakarta');
```

### Command: `attendance:generate-daily`

```php
// Untuk setiap user aktif yang punya shift assignment hari ini:
//   → Buat record daily_attendances (status: 'scheduled')
//   → Skip jika sudah ada record untuk hari ini
//   → Skip jika hari ini = hari libur (dari kalender libur)

$today = today();
$dayOfWeek = $today->dayOfWeek; // 0=Minggu..6=Sabtu

UserShiftAssignment::where('is_active', true)
  ->where('effective_date', '<=', $today)
  ->where(fn($q) => $q->whereNull('end_date')->orWhere('end_date', '>=', $today))
  ->where(fn($q) => $q->whereNull('day_of_week')->orWhere('day_of_week', $dayOfWeek))
  ->each(function ($assignment) use ($today) {
    DailyAttendance::firstOrCreate(
      ['user_id' => $assignment->user_id, 'attendance_date' => $today],
      [
        'shift_id' => $assignment->shift_id,
        'location_id' => $assignment->location_id,
        'status' => 'scheduled',
      ]
    );
  });
```

### Command: `attendance:check-absent`

```php
// Tandai semua yang masih 'scheduled' sebagai 'absent'
DailyAttendance::where('attendance_date', today())
  ->where('status', 'scheduled')
  ->update(['status' => 'absent']);

// Buat pelanggaran HRD untuk setiap absent
DailyAttendance::where('attendance_date', today())
  ->where('status', 'absent')
  ->each(function ($att) {
    HrdViolation::create([
      'violated_by' => $att->user_id,
      'violation_type' => 'daily_attendance_absent',
      'description' => "{$att->user->name} tidak hadir tanpa keterangan",
      'severity' => 'medium',
    ]);

    NotificationService::sendToRole('hrd', 'HIGH',
      'Karyawan Tidak Hadir',
      "{$att->user->name} ({$att->user->role}) tidak clock-in hari ini"
    );
  });
```

---

## INTEGRASI KE KPI (v1.16)

Tambahkan metrik KPI baru yang menghitung dari `daily_attendances`:

```
(Semua role internal)
ATT_DAILY_RATE       | Tingkat Kehadiran Harian
  data_source: daily_attendances
  calculation: % (present + late) vs total scheduled
  target: ≥ 95% | direction: higher_is_better | bobot: disesuaikan per role

ATT_PUNCTUALITY      | Ketepatan Waktu
  data_source: daily_attendances
  calculation: % present (tepat waktu) vs total hadir
  target: ≥ 90% | direction: higher_is_better | bobot: disesuaikan per role

ATT_MOCK_ATTEMPTS    | Percobaan Mock Location
  data_source: attendance_logs
  calculation: COUNT where is_accepted=false AND mock detected
  target: 0 | direction: lower_is_better | bobot: disesuaikan per role
```

---

## TABEL hrd_violations — TAMBAH VIOLATION TYPE v1.17

```sql
-- Tambah ke ENUM violation_type:
'daily_attendance_absent',          -- tidak hadir tanpa keterangan
'daily_attendance_late',            -- terlambat clock-in (melebihi threshold)
'daily_attendance_early_leave',     -- pulang lebih awal
'mock_location_attempt',            -- mencoba pakai fake GPS
'device_sharing_detected',          -- 2 user dari 1 device (titip absen)
```

---

## TABEL ALARM PRESENSI v1.17

| Momen | User | HRD | Owner |
|-------|------|-----|-------|
| Clock-in sukses | — | — | — |
| Clock-in terlambat | NORMAL (info) | HIGH | — |
| Belum clock-in (deadline) | HIGH (reminder!) | ALARM | NORMAL |
| Mock location terdeteksi | TOLAK + pesan | ALARM (kecurangan!) | HIGH |
| Titip absen terdeteksi | TOLAK | ALARM (kecurangan!) | HIGH |
| Device baru terdeteksi | — | HIGH (review) | — |
| Clock-out lupa (auto) | NORMAL | — | — |

---

## ATURAN BISNIS PRESENSI v1.17

```
1. Clock-in WAJIB dalam radius geofence lokasi yang di-assign
   → Radius per lokasi bisa berbeda (kantor: 100m, gudang: 150m, order: 500m)

2. Foto selfie WAJIB setiap clock-in dan clock-out
   → Kamera depan, langsung capture (bukan galeri)
   → Disimpan di R2 untuk audit

3. SATU user = SATU device aktif
   → Jika user ganti HP, HRD harus reset device di admin panel
   → Jika 2 user check-in dari 1 HP = TOLAK user kedua + alarm HRD

4. Mock location = pelanggaran berat
   → Langsung catat di hrd_violations (severity: high)
   → HRD dapat alarm + semua attempt tersimpan di attendance_logs

5. Driver tetap pakai presensi harian (clock-in di gudang/kantor)
   → PLUS field_attendances per order (check-in di lokasi order)

6. Karyawan yang belum clock-in sampai batas waktu → otomatis absent
   → Batas waktu dikonfigurasi di system_thresholds

7. HRD bisa override status (izin, sakit, dinas luar)
   → Harus isi catatan + approval notes

8. Owner bisa lihat realtime siapa yang sudah/belum masuk
   → Widget di Owner Dashboard

9. Semua attempt (sukses/gagal) tersimpan di attendance_logs
   → Tidak bisa dihapus — untuk audit trail
```

---

## PUBSPEC.YAML — TAMBAHAN PACKAGE v1.17

```yaml
dependencies:
  # Play Integrity (anti-root/tamper)
  play_integrity: ^2.0.0

  # Cek installed apps (anti mock app)
  installed_apps: ^1.5.0

  # Device info
  device_info_plus: ^10.0.0

  # Image picker sudah ada, tapi pastikan versi terbaru
  image_picker: ^1.0.0
```

---

## RINGKASAN TABEL v1.17

### Tabel Master Baru
| Tabel | Fungsi | Dikelola oleh |
|-------|--------|--------------|
| `attendance_locations` | Titik geofence presensi | Owner / HRD |
| `work_shifts` | Master shift kerja | HRD |
| `mock_app_blacklist` | Daftar app fake GPS | Super Admin |

### Tabel Transaksional Baru
| Tabel | Fungsi | Relasi |
|-------|--------|--------|
| `user_shift_assignments` | Jadwal shift per karyawan | `users`, `work_shifts`, `attendance_locations` |
| `daily_attendances` | Presensi harian clock in/out | `users`, `work_shifts`, `attendance_locations` |
| `attendance_logs` | Audit trail semua attempt | `users` |

### Tabel Existing yang Diperkaya
| Tabel | Perubahan |
|-------|-----------|
| `field_attendances` | + koordinat, selfie, device_id, is_mock_detected, mock_detail |
| `hrd_violations` | + 5 violation type baru (absent, late, early_leave, mock, device_sharing) |
| `system_thresholds` | + 7 threshold baru (attendance + anti-mock) |
| `kpi_metric_master` | + 3 metrik baru (daily_rate, punctuality, mock_attempts) |

---

# SANTA MARIA — PATCH v1.18
# Sifat Item Gudang: Sewa, Pakai Habis, Pakai Bisa Kembali + Auto-Adjust Tagihan

---

## LATAR BELAKANG v1.18

Item gudang memiliki 3 sifat berbeda yang menentukan alur pengembalian dan tagihan:

```
╔═════════════════════════════════════════════════════════════════════════╗
║  3 SIFAT ITEM GUDANG                                                    ║
╠════════════════╦════════════════════╦════════════════════════════════════╣
║ SEWA           ║ PAKAI HABIS        ║ PAKAI BISA KEMBALI                ║
║ (rental)       ║ (consumed)         ║ (returnable)                      ║
╠════════════════╬════════════════════╬════════════════════════════════════╣
║ Keluar → WAJIB ║ Keluar → tidak     ║ Keluar sesuai paket →             ║
║ kembali utuh   ║ kembali            ║ sisa bisa kembali                 ║
╠════════════════╬════════════════════╬════════════════════════════════════╣
║ Tidak dihitung ║ Dihitung penuh     ║ Dihitung sesuai paket,            ║
║ per unit di    ║ di tagihan         ║ DIPOTONG jika ada yang kembali    ║
║ tagihan (sudah ║                    ║                                    ║
║ termasuk paket)║                    ║ Contoh: Air 10 dos, kembali 2     ║
║                ║                    ║ → tagihan = 8 dos                  ║
╠════════════════╬════════════════════╬════════════════════════════════════╣
║ Hilang/rusak → ║ —                  ║ —                                  ║
║ biaya ganti    ║                    ║                                    ║
╠════════════════╬════════════════════╬════════════════════════════════════╣
║ CONTOH:        ║ CONTOH:            ║ CONTOH:                            ║
║ Sound system   ║ Cologne            ║ Air Putih (kardus)                 ║
║ Meja + Taplak  ║ Kapur              ║ Kwaci, Permen, Kacang              ║
║ LED + Stand    ║ Minyak Rambak      ║ Lilin                              ║
║ Kulkas         ║ Embalming fluid    ║ Roti                               ║
║ Stand Jubah    ║ Kapuk              ║ Teh Sosro, Happy Jus               ║
║ Koper Misa/Romo║ Paku, Sekrup       ║ Kartu Ucapan                       ║
║ Box perlengkap.║ Arang              ║ Semangka                           ║
║ Bejana, Hisop  ║ Pertak             ║ Sepatu (jika dikembalikan)         ║
╚════════════════╩════════════════════╩════════════════════════════════════╝
```

---

## DATABASE — PERUBAHAN v1.18

### Tabel `stock_items` — Tambah Kolom `item_nature`

```sql
-- Tambahkan ke tabel stock_items:

item_nature ENUM('sewa','pakai_habis','pakai_kembali') NOT NULL DEFAULT 'pakai_habis'
-- 'sewa'          : keluar wajib kembali, tidak dihitung per unit di tagihan
-- 'pakai_habis'   : terpakai habis, tidak bisa kembali, dihitung penuh
-- 'pakai_kembali' : dikirim sesuai paket, sisa bisa kembali, tagihan dipotong
```

### Tabel `package_items` — Tambah Kolom

```sql
-- Tambahkan ke tabel package_items:

item_nature ENUM('sewa','pakai_habis','pakai_kembali') NULLABLE
-- Override sifat item di level paket. Jika NULL → ambil dari stock_items.item_nature
-- Contoh: Sepatu di paket Premium = 'pakai_kembali', di paket Basic = 'pakai_habis'

is_billable BOOLEAN DEFAULT TRUE
-- false = item sewa yang sudah termasuk harga paket (Sound, Meja, dll)
-- true = item yang dihitung di tagihan (Air, Kwaci, dll)
```

### Tabel `order_billing_items` — Tambah Kolom Return

```sql
-- Tambahkan ke tabel order_billing_items:

sent_qty DECIMAL(10,2) DEFAULT 0             -- jumlah yang dikirim (dari paket)
returned_qty DECIMAL(10,2) DEFAULT 0         -- jumlah yang kembali (input Gudang)
billed_qty DECIMAL(10,2) DEFAULT 0           -- jumlah yang ditagihkan = sent_qty - returned_qty
-- billed_qty ini yang dipakai untuk hitung total_price

kembali_reason TEXT NULLABLE                 -- catatan: "sisa tidak terpakai"
returned_at TIMESTAMP NULLABLE               -- kapan dikembalikan
returned_verified_by UUID NULLABLE REFERENCES users(id)  -- Gudang yang verifikasi
```

### Tabel `order_item_returns` (Log Pengembalian Item per Order)

Mencatat setiap pengembalian item dari order — baik sewa maupun pakai_kembali.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
order_id UUID REFERENCES orders(id)
stock_item_id UUID REFERENCES stock_items(id)

item_nature ENUM('sewa','pakai_kembali') NOT NULL
qty_sent DECIMAL(10,2) NOT NULL              -- yang dikirim
qty_returned DECIMAL(10,2) NOT NULL          -- yang dikembalikan kali ini
qty_damaged DECIMAL(10,2) DEFAULT 0          -- rusak/hilang (tidak masuk stok)
condition ENUM('good','damaged','partial') DEFAULT 'good'

-- Dampak ke stok
stock_restored BOOLEAN DEFAULT FALSE         -- stok sudah di-restore?
stock_transaction_id UUID NULLABLE REFERENCES stock_transactions(id)

-- Dampak ke tagihan (hanya untuk pakai_kembali)
billing_adjusted BOOLEAN DEFAULT FALSE       -- billing sudah di-adjust?
billing_item_id UUID NULLABLE REFERENCES order_billing_items(id)
adjustment_amount DECIMAL(15,2) DEFAULT 0    -- nominal potongan tagihan

-- Verifikasi
returned_by_name VARCHAR(255) NULLABLE       -- nama yang mengembalikan (keluarga/driver)
verified_by UUID REFERENCES users(id)        -- Gudang yang verifikasi
verified_at TIMESTAMP NULLABLE
selfie_path TEXT NULLABLE                    -- foto bukti kondisi barang kembali

notes TEXT NULLABLE
created_at TIMESTAMP
updated_at TIMESTAMP
```

---

## ALUR PENGEMBALIAN ITEM

### Flow 1: Item Sewa Kembali (Sound, Meja, Koper, dll)

```
Order selesai → Keluarga/Driver kembalikan item sewa ke Gudang
  ↓
Gudang buka app → screen "Pengembalian Barang" untuk order ini
  ↓
Gudang centang per item sewa:
  Sound: kembali ✓ (kondisi: baik)
  Meja: kembali ✓ (kondisi: baik)
  LED: kembali ✓ (kondisi: rusak → qty_damaged: 1)
  ↓
POST /gudang/orders/{id}/returns
  ↓
Sistem per item:
  ├─ Buat record order_item_returns
  ├─ Update order_equipment_items.status → 'returned' (atau 'missing'/'damaged')
  ├─ Restore stok: stock_transaction type='in' (hanya yang kondisi baik)
  └─ Jika rusak/hilang:
       → Biaya penggantian otomatis masuk ke order_extra_approvals
       → Alarm Purchasing + SO
```

### Flow 2: Item Pakai Bisa Kembali (Air Putih, Kwaci, dll)

```
Contoh: Paket Premium → Air Putih 10 kardus dikirim

Selama acara, terpakai 8 kardus → sisa 2 kardus
  ↓
Order selesai → Gudang/Driver bawa kembali 2 kardus ke gudang
  ↓
Gudang buka app → screen "Pengembalian Barang" → tab "Konsumabel Kembali"
  Input: Air Putih → qty_returned: 2
  ↓
POST /gudang/orders/{id}/returns
  ↓
Sistem otomatis:
  ├─ Buat record order_item_returns (item_nature: 'pakai_kembali')
  ├─ Restore stok: stock_transaction type='in', qty=2
  │     notes: "Retur dari order SM-20260414-0001 — sisa tidak terpakai"
  │
  ├─ AUTO-ADJUST TAGIHAN:
  │     Cari order_billing_items dimana billing_master → stock_item = Air Putih
  │     Update:
  │       returned_qty: 0 → 2
  │       billed_qty: 10 → 8
  │       total_price: 10 × Rp50.000 = 500.000 → 8 × Rp50.000 = 400.000
  │       kembali: 0 → 100.000  (2 × Rp50.000)
  │
  └─ Notifikasi:
       → Purchasing: HIGH "Tagihan order SM-20260414-0001 disesuaikan.
                      Air Putih: 10 → 8 dos (2 kembali). Potongan Rp 100.000"
       → Owner: NORMAL "Retur barang order SM-20260414-0001"
```

### Flow 3: Item Pakai Habis (Cologne, Embalming, dll)

```
Tidak ada flow pengembalian — terpakai habis di lapangan.
Tagihan sesuai qty yang dikirim (= qty paket).
Stok tidak di-restore.
```

---

## BACKEND — OrderItemReturnService

```php
class OrderItemReturnService
{
  public function processReturn(Order $order, array $items): void
  {
    DB::transaction(function () use ($order, $items) {
      foreach ($items as $item) {
        $stockItem = StockItem::findOrFail($item['stock_item_id']);
        $nature = $item['item_nature']; // 'sewa' atau 'pakai_kembali'
        $qtyReturned = $item['qty_returned'];
        $qtyDamaged = $item['qty_damaged'] ?? 0;
        $qtyGood = $qtyReturned - $qtyDamaged;

        // 1. Buat log pengembalian
        $return = OrderItemReturn::create([
          'order_id' => $order->id,
          'stock_item_id' => $stockItem->id,
          'item_nature' => $nature,
          'qty_sent' => $item['qty_sent'],
          'qty_returned' => $qtyReturned,
          'qty_damaged' => $qtyDamaged,
          'condition' => $qtyDamaged > 0 ? 'partial' : 'good',
          'returned_by_name' => $item['returned_by_name'] ?? null,
          'verified_by' => auth()->id(),
          'verified_at' => now(),
        ]);

        // 2. Restore stok (hanya yang kondisi baik)
        if ($qtyGood > 0) {
          $txn = StockTransaction::create([
            'stock_item_id' => $stockItem->id,
            'order_id' => $order->id,
            'type' => 'in',
            'quantity' => $qtyGood,
            'form_type' => 'pengembalian',
            'notes' => "Retur dari order {$order->order_number}",
            'user_id' => auth()->id(),
          ]);
          $stockItem->increment('current_quantity', $qtyGood);
          $return->update([
            'stock_restored' => true,
            'stock_transaction_id' => $txn->id,
          ]);
        }

        // 3. Auto-adjust tagihan (hanya pakai_kembali)
        if ($nature === 'pakai_kembali' && $qtyReturned > 0) {
          $this->adjustBilling($order, $stockItem, $return, $qtyReturned);
        }

        // 4. Item sewa rusak/hilang → biaya ganti
        if ($nature === 'sewa' && $qtyDamaged > 0) {
          $this->createDamageCharge($order, $stockItem, $qtyDamaged);
        }

        // 5. Update equipment items status (jika sewa)
        if ($nature === 'sewa') {
          OrderEquipmentItem::where('order_id', $order->id)
            ->whereHas('equipmentMaster', fn($q) =>
              $q->where('item_name', 'LIKE', "%{$stockItem->item_name}%")
            )
            ->update([
              'status' => $qtyDamaged > 0 ? 'missing' : 'returned',
              'qty_returned' => $qtyReturned,
              'returned_at' => now(),
            ]);
        }
      }
    });

    // Notifikasi
    NotificationService::sendToRole('purchasing', 'HIGH',
      "Retur Barang — {$order->order_number}",
      count($items) . " item dikembalikan. Tagihan mungkin berubah."
    );
  }

  private function adjustBilling(Order $order, StockItem $stockItem, OrderItemReturn $return, float $qtyReturned): void
  {
    // Cari billing item yang terkait stock_item ini
    $billingItem = OrderBillingItem::where('order_id', $order->id)
      ->whereHas('billingMaster', function ($q) use ($stockItem) {
        // Mapping: billing_item_master ↔ stock_items via item_code
        $q->where('item_code', $stockItem->item_code);
      })
      ->first();

    if (!$billingItem) return;

    $billingItem->update([
      'returned_qty' => $billingItem->returned_qty + $qtyReturned,
      'billed_qty' => $billingItem->sent_qty - ($billingItem->returned_qty + $qtyReturned),
      'total_price' => ($billingItem->sent_qty - ($billingItem->returned_qty + $qtyReturned))
                       * $billingItem->unit_price,
      'kembali' => ($billingItem->returned_qty + $qtyReturned) * $billingItem->unit_price,
      'kembali_reason' => 'Sisa tidak terpakai — dikembalikan ke gudang',
      'returned_at' => now(),
      'returned_verified_by' => auth()->id(),
    ]);

    $adjustmentAmount = $qtyReturned * $billingItem->unit_price;
    $return->update([
      'billing_adjusted' => true,
      'billing_item_id' => $billingItem->id,
      'adjustment_amount' => $adjustmentAmount,
    ]);
  }

  private function createDamageCharge(Order $order, StockItem $stockItem, float $qtyDamaged): void
  {
    // Buat extra approval otomatis untuk biaya penggantian
    $approval = OrderExtraApproval::firstOrCreate(
      ['order_id' => $order->id, 'notes' => 'Biaya penggantian peralatan rusak/hilang'],
      ['nama_almarhum' => $order->nama_almarhum, 'pj_nama' => '-', 'tanggal' => today()]
    );

    ExtraApprovalLine::create([
      'approval_id' => $approval->id,
      'line_number' => $approval->lines()->count() + 1,
      'keterangan' => "Ganti {$stockItem->item_name} (rusak/hilang × {$qtyDamaged})",
      'biaya' => 0, // diisi Purchasing manual (harga penggantian)
    ]);

    NotificationService::sendToRole('purchasing', 'ALARM',
      "Peralatan Rusak — {$order->order_number}",
      "{$stockItem->item_name} × {$qtyDamaged} rusak/hilang. Tentukan biaya penggantian."
    );
  }
}
```

---

## API — ENDPOINT PENGEMBALIAN v1.18

```
-- Pengembalian item (Gudang)
GET    /gudang/orders/{id}/returnable-items        -- list item yang bisa dikembalikan
  -- Response: items grouped by nature (sewa + pakai_kembali)
  -- Per item: stock_item, qty_sent, qty_already_returned, qty_remaining

POST   /gudang/orders/{id}/returns                 -- proses pengembalian
  body: {
    items: [
      { stock_item_id: "X", item_nature: "pakai_kembali",
        qty_sent: 10, qty_returned: 2, qty_damaged: 0,
        returned_by_name: "Keluarga Bpk. Yohanes" },
      { stock_item_id: "Y", item_nature: "sewa",
        qty_sent: 1, qty_returned: 1, qty_damaged: 0 },
      { stock_item_id: "Z", item_nature: "sewa",
        qty_sent: 1, qty_returned: 1, qty_damaged: 1,
        notes: "LED pecah" }
    ]
  }

GET    /gudang/orders/{id}/returns                 -- list pengembalian yang sudah diproses
GET    /gudang/returns/pending                     -- semua order yang masih ada item belum kembali
```

---

## FLUTTER — SCREEN PENGEMBALIAN v1.18

```
lib/features/gudang/screens/
  └── item_return_screen.dart                 -- BARU
        -- Header: nama order, tanggal selesai, nama almarhum
        --
        -- Section 1: "Peralatan Sewa" (item_nature = sewa)
        --   Per item: nama, qty kirim, toggle "Kembali" / "Rusak" / "Hilang"
        --   Jika rusak → input catatan kerusakan
        --   Badge: ✅ Kembali | ⚠️ Rusak | ❌ Hilang
        --
        -- Section 2: "Barang Bisa Kembali" (item_nature = pakai_kembali)
        --   Per item: nama, qty kirim (dari paket), input qty kembali
        --   Contoh: "Air Putih — Kirim: 10 dos — Kembali: [__] dos"
        --   Preview otomatis: "Tagihan dipotong: 2 × Rp50.000 = Rp100.000"
        --
        -- Section 3: "Barang Habis Pakai" (item_nature = pakai_habis)
        --   Readonly, informasi saja: "Cologne 2 btl — terpakai"
        --
        -- Footer: tombol "Proses Pengembalian"
        --   → Konfirmasi dialog: "2 item sewa kembali, 3 item konsumabel kembali.
        --      Potongan tagihan: Rp 150.000. Lanjutkan?"
        --   → Loading → sukses
```

---

## INTEGRASI KE FLOW ORDER

### Update STEP 7 Post-Complete & STEP 9:

```
STEP 7 Post-Complete:
  → Scheduler equipment:check-return-deadline H+1:
    Sekarang cek SEMUA item (sewa + pakai_kembali) yang belum dikembalikan,
    bukan hanya equipment. Alarm Gudang per item nature:
      "Order SM-20260414-0001 — 5 item sewa + 3 item pakai_kembali belum kembali"

STEP 9 Post-Order (diperkaya):
  → Gudang proses pengembalian via item_return_screen
  → Sistem auto-adjust billing:
      sent_qty → billed_qty (dikurangi returned_qty)
      kembali = returned_qty × unit_price
  → Purchasing lihat tagihan final yang sudah di-adjust
  → Export PDF laporan tagihan → sudah reflect potongan
```

### Update Simulasi — Tambahan di H+1:

```
09:00  Gudang proses pengembalian order SM-20260414-0001:
       
       POST /gudang/orders/{id}/returns
       
       Item Sewa:
       ├─ Sound (1) → kembali ✓ kondisi baik → stok +1
       ├─ Meja+Taplak (1) → kembali ✓ → stok +1
       ├─ LED+Stand (1) → rusak → biaya ganti → extra_approval
       ├─ Koper Misa (1) → kembali ✓ → stok +1
       └─ Box (1) → kembali ✓ → stok +1

       Item Pakai Bisa Kembali:
       ├─ Air Putih: kirim 10 dos, kembali 2 dos
       │    → stok +2
       │    → billing: qty 10→8, kembali Rp 100.000
       ├─ Kwaci: kirim 5 pak, kembali 1 pak
       │    → stok +1
       │    → billing: qty 5→4, kembali Rp 15.000
       ├─ Permen: kirim 5 pak, kembali 0 → habis terpakai
       └─ Lilin: kirim 4 btl, kembali 1 btl
            → stok +1
            → billing: qty 4→3, kembali Rp 25.000

       Item Pakai Habis:
       └─ Cologne (2 btl), Kapur, dll → tidak ada pengembalian

       TOTAL POTONGAN TAGIHAN: Rp 140.000
       → order_billing_items updated
       → Purchasing: HIGH "Tagihan SM-20260414-0001 dipotong Rp 140.000 (retur barang)"
```

---

## ATURAN BISNIS PENGEMBALIAN v1.18

```
1. Hanya item dengan nature 'sewa' dan 'pakai_kembali' yang bisa dikembalikan
   → 'pakai_habis' tidak muncul di form pengembalian

2. Pengembalian hanya bisa dilakukan oleh Gudang
   → Gudang yang verifikasi fisik barang kembali

3. Saat item pakai_kembali dikembalikan:
   → Stok otomatis di-restore (stock_transaction type='in')
   → Tagihan otomatis di-adjust (billed_qty = sent_qty - returned_qty)
   → Kolom 'kembali' di billing = returned_qty × unit_price

4. Saat item sewa rusak/hilang:
   → Stok TIDAK di-restore untuk qty yang rusak
   → Biaya penggantian masuk ke order_extra_approvals
   → Purchasing dapat alarm untuk tentukan nominal penggantian

5. Pengembalian bisa dilakukan bertahap (partial return)
   → Item yang sudah kembali tidak bisa dikembalikan lagi
   → qty_remaining = qty_sent - qty_already_returned

6. Tagihan final baru bisa di-export PDF setelah semua item kembali
   → Atau setelah Purchasing manual mark "tagihan final" meskipun ada item belum kembali

7. Mapping billing_item_master ↔ stock_items via item_code
   → Contoh: AQU (billing) = AO (stock) = Air Putih
   → Mapping ini dikelola di billing_item_master:
     Tambah kolom: stock_item_code VARCHAR(50) NULLABLE REFERENCES stock_items(item_code)
```

---

## DATABASE — KOLOM TAMBAHAN v1.18

### Tabel `billing_item_master` — Link ke Stock

```sql
-- Tambahkan:
stock_item_code VARCHAR(50) NULLABLE
-- Mapping ke stock_items.item_code untuk auto-adjust billing saat retur
-- Contoh: billing 'AQU' → stock 'AO' (Air Putih)
-- NULL = item layanan tanpa stok fisik (Embalming, Foto, dll)
```

### Tabel `order_stock_deductions` — Tambah item_nature

```sql
-- Tambahkan:
item_nature ENUM('sewa','pakai_habis','pakai_kembali') NULLABLE
-- Diisi dari stock_items.item_nature atau package_items.item_nature
```

---

---

# SANTA MARIA — PATCH v1.19
# Sinkronisasi Driver & Manajemen Kendaraan + Purchasing Reminder & Urgency

---

## LATAR BELAKANG v1.19

**Masalah 1 — Driver & Kendaraan tidak sinkron:**
- Tabel `vehicles` direferensikan tapi tidak pernah didefinisikan
- `driver_status` dipakai di auto-complete logic tapi tidak ada kolom eksplisit di `orders`
- Tidak ada tabel penugasan driver-kendaraan per order
- Flow 2-tugas driver (Tugas 1: antar barang, Tugas 2: antar jenazah) tidak punya status tracking granular
- Driver assignment (AI auto-assign) tidak punya mekanisme database

**Masalah 2 — Purchasing tanpa reminder & urgency:**
- Tidak ada field urgency/priority di `procurement_requests`
- Purchasing dapat 1 alarm saat awarded → tidak ada follow-up jika diabaikan
- Tidak ada deadline approval
- Tidak ada deadline bayar supplier setelah goods_received
- `requested_by` tersimpan di DB tapi tidak tampil di UI Purchasing
- Tidak ada eskalasi jika approval terlambat

---

## BAGIAN A: DRIVER & MANAJEMEN KENDARAAN

### Tabel `vehicles` (Master Data Kendaraan)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
vehicle_code VARCHAR(50) UNIQUE NOT NULL     -- contoh: 'MBL-01', 'MBL-02'
plate_number VARCHAR(20) UNIQUE NOT NULL     -- contoh: 'H-1234-AB'
vehicle_name VARCHAR(255) NOT NULL           -- contoh: 'Mobil Jenazah 1'
vehicle_type ENUM('hearse','van','pickup','bus','external') NOT NULL DEFAULT 'hearse'
-- hearse   : mobil jenazah utama
-- van      : van serbaguna (logistik)
-- pickup   : pickup untuk barang berat
-- bus      : bus lelayu
-- external : kendaraan dari supplier eksternal

brand VARCHAR(100) NULLABLE                  -- contoh: 'Toyota HiAce'
year SMALLINT NULLABLE
color VARCHAR(50) NULLABLE
capacity_persons SMALLINT NULLABLE           -- kapasitas orang (untuk bus)
capacity_kg DECIMAL(10,2) NULLABLE           -- kapasitas muatan (kg)

-- Status operasional
status ENUM('available','in_use','maintenance','retired') DEFAULT 'available'
current_driver_id UUID NULLABLE REFERENCES users(id)  -- driver yang sedang pakai
current_order_id UUID NULLABLE REFERENCES orders(id)  -- order yang sedang dilayani

-- Odometer
last_km DECIMAL(10,2) DEFAULT 0              -- KM terakhir tercatat

-- Maintenance
last_maintenance_date DATE NULLABLE
next_maintenance_km DECIMAL(10,2) NULLABLE   -- KM selanjutnya servis
maintenance_notes TEXT NULLABLE

-- Foto
photo_path TEXT NULLABLE                     -- foto kendaraan (R2)

is_active BOOLEAN DEFAULT TRUE
created_at TIMESTAMP
updated_at TIMESTAMP
```

Initial seed:
```
MBL-01 | H-1234-AB | Mobil Jenazah 1   | hearse  | Toyota HiAce | available
MBL-02 | H-5678-CD | Mobil Jenazah 2   | hearse  | Toyota HiAce | available
VAN-01 | H-9012-EF | Van Logistik 1    | van     | Suzuki APV   | available
PKP-01 | H-3456-GH | Pickup            | pickup  | Mitsubishi L300 | available
BUS-01 | H-7890-IJ | Bus Lelayu        | bus     | Isuzu Elf    | available
```

---

### Tabel `trip_leg_master` (Master Jenis Leg Perjalanan)

Jenis leg perjalanan TIDAK di-hardcode — dikelola sebagai master data.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
leg_code VARCHAR(50) UNIQUE NOT NULL         -- contoh: 'ANTAR_BARANG', 'JEMPUT_JENAZAH'
leg_name VARCHAR(255) NOT NULL               -- contoh: 'Antar Barang ke Rumah Duka'
description TEXT NULLABLE
category ENUM('logistics','transport_jenazah','return','other') NOT NULL
-- logistics          : angkut barang/perlengkapan
-- transport_jenazah  : segala sesuatu yang melibatkan jenazah
-- return             : angkut barang kembali ke gudang
-- other              : keperluan lain

requires_proof_photo BOOLEAN DEFAULT TRUE    -- wajib upload foto bukti saat tiba?
triggers_gate VARCHAR(100) NULLABLE          -- event yang di-trigger saat leg ini selesai
-- contoh: 'dekor_gate' = buka alarm dekorasi, 'consumer_notify' = notif consumer, NULL = tidak trigger apa-apa

icon VARCHAR(50) NULLABLE                    -- icon di Flutter: 'local_shipping', 'airline_seat_flat', 'church'
sort_order INTEGER DEFAULT 0
is_active BOOLEAN DEFAULT TRUE
created_at TIMESTAMP
updated_at TIMESTAMP
```

Initial seed (dapat ditambah/diubah Super Admin via UI):
```
ANTAR_BARANG       | Antar Barang/Perlengkapan     | logistics          | triggers: dekor_gate
JEMPUT_JENAZAH     | Jemput Jenazah                | transport_jenazah  | triggers: NULL
ANTAR_JENAZAH_RD   | Antar Jenazah ke Rumah Duka   | transport_jenazah  | triggers: consumer_notify
ANTAR_JENAZAH_PMK  | Antar Jenazah ke Pemakaman    | transport_jenazah  | triggers: consumer_notify
ANTAR_JENAZAH_KRM  | Antar Jenazah ke Krematorium  | transport_jenazah  | triggers: consumer_notify
ANGKUT_KEMBALI     | Angkut Barang Kembali ke Gudang| return            | triggers: NULL
ANTAR_PERALATAN    | Antar Peralatan Peringatan    | logistics          | triggers: NULL
JEMPUT_JENAZAH_LUAR| Jemput Jenazah Luar Kota      | transport_jenazah  | triggers: consumer_notify
ANTAR_PETI         | Antar Peti dari Workshop      | logistics          | triggers: NULL
```

---

### Tabel `order_trip_template` (Template Rute per Paket)

Setiap paket layanan punya template default leg perjalanan. SO bisa override per order.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
package_id UUID REFERENCES packages(id)
leg_master_id UUID REFERENCES trip_leg_master(id)
leg_sequence SMALLINT NOT NULL               -- urutan: 1, 2, 3, ...
default_origin_label VARCHAR(255) NOT NULL   -- contoh: 'Gudang Santa Maria'
default_destination_label VARCHAR(255) NOT NULL -- contoh: 'Rumah Duka'
is_optional BOOLEAN DEFAULT FALSE            -- leg ini bisa di-skip SO?
notes TEXT NULLABLE
created_at TIMESTAMP

UNIQUE(package_id, leg_sequence)
```

Contoh template untuk Paket "Premium":
```
Seq 1: ANTAR_BARANG       | Gudang SM → Rumah Duka      | wajib
Seq 2: JEMPUT_JENAZAH     | RS/Rumah → [input SO]       | wajib
Seq 3: ANTAR_JENAZAH_RD   | [RS/Rumah] → Rumah Duka     | wajib
Seq 4: ANTAR_JENAZAH_PMK  | Rumah Duka → Pemakaman      | wajib
Seq 5: ANGKUT_KEMBALI     | Rumah Duka → Gudang SM      | opsional
```

Contoh template untuk Paket "Kremasi":
```
Seq 1: ANTAR_BARANG       | Gudang SM → Rumah Duka
Seq 2: JEMPUT_JENAZAH     | RS → Rumah Duka
Seq 3: ANTAR_JENAZAH_KRM  | Rumah Duka → Krematorium
Seq 4: ANGKUT_KEMBALI     | Rumah Duka → Gudang SM      | opsional
```

Contoh template untuk "Peringatan" (tanpa jenazah):
```
Seq 1: ANTAR_PERALATAN    | Gudang SM → Gereja/Lokasi
Seq 2: ANGKUT_KEMBALI     | Gereja → Gudang SM          | opsional
```

---

### Tabel `order_driver_assignments` (Penugasan Driver per Order — DINAMIS)

Tidak lagi hardcode 2 tugas — bisa N leg sesuai kebutuhan order.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
order_id UUID REFERENCES orders(id)
driver_id UUID REFERENCES users(id)
vehicle_id UUID REFERENCES vehicles(id)

-- Leg perjalanan (dari master)
leg_master_id UUID REFERENCES trip_leg_master(id)
leg_sequence SMALLINT NOT NULL               -- urutan dalam order ini (1, 2, 3, ...)

-- Status tracking granular (sama untuk semua jenis leg)
status ENUM(
  'pending',               -- belum waktunya (leg sebelumnya belum selesai)
  'assigned',              -- siap dikerjakan, driver sudah di-assign
  'accepted',              -- driver terima
  'departed',              -- berangkat dari origin
  'arrived',               -- tiba di destination
  'completed',             -- tugas leg ini selesai (barang diturunkan / jenazah diserahkan)
  'skipped',               -- di-skip (leg opsional yang tidak diperlukan)
  'cancelled'              -- dibatalkan
) DEFAULT 'pending'

-- Timestamps
assigned_at TIMESTAMP NULLABLE
accepted_at TIMESTAMP NULLABLE
departed_at TIMESTAMP NULLABLE
arrived_at TIMESTAMP NULLABLE
completed_at TIMESTAMP NULLABLE

-- Lokasi
origin_label VARCHAR(255) NOT NULL           -- label: "Gudang Santa Maria"
origin_address TEXT NOT NULL
origin_lat DECIMAL(10,7) NULLABLE
origin_lng DECIMAL(10,7) NULLABLE
destination_label VARCHAR(255) NOT NULL      -- label: "Rumah Duka Bethesda"
destination_address TEXT NOT NULL
destination_lat DECIMAL(10,7) NULLABLE
destination_lng DECIMAL(10,7) NULLABLE

-- Muatan
cargo_description TEXT NULLABLE              -- apa yang diangkut: "Perlengkapan prosesi" / "Jenazah Bpk. Yohanes"
is_carrying_body BOOLEAN DEFAULT FALSE       -- apakah leg ini mengangkut jenazah?

-- Bukti foto (setiap tiba)
arrival_photo_path TEXT NULLABLE             -- foto bukti tiba (R2)
departure_photo_path TEXT NULLABLE           -- foto bukti berangkat (R2, opsional)

-- KM Tracking
km_start DECIMAL(10,2) NULLABLE             -- KM speedometer saat berangkat
km_end DECIMAL(10,2) NULLABLE               -- KM speedometer saat tiba
km_distance DECIMAL(10,2) NULLABLE          -- auto: km_end - km_start
trip_log_id UUID NULLABLE REFERENCES vehicle_trip_logs(id)

-- Fallback
is_fallback BOOLEAN DEFAULT FALSE
original_vehicle_id UUID NULLABLE REFERENCES vehicles(id)
fallback_reason TEXT NULLABLE

-- Gate trigger (dari master, snapshot)
triggers_gate VARCHAR(100) NULLABLE

notes TEXT NULLABLE
created_at TIMESTAMP
updated_at TIMESTAMP

UNIQUE(order_id, leg_sequence)
```

---

### Tabel `orders` — Driver Status Dinamis v1.20

```sql
-- GANTI driver_status dari ENUM hardcode ke tracking berbasis leg:

-- Hapus ENUM lama (8 status hardcode)
-- Ganti dengan:

driver_total_legs SMALLINT DEFAULT 0               -- total leg dalam order ini
driver_completed_legs SMALLINT DEFAULT 0           -- leg yang sudah selesai
driver_current_leg_id UUID NULLABLE REFERENCES order_driver_assignments(id)
  -- leg yang sedang dikerjakan sekarang

driver_overall_status ENUM(
  'unassigned',        -- belum ada driver
  'assigned',          -- driver di-assign, belum mulai leg pertama
  'in_progress',       -- sedang mengerjakan salah satu leg
  'all_done'           -- semua leg selesai
) DEFAULT 'unassigned'

assigned_driver_id UUID NULLABLE REFERENCES users(id)
assigned_vehicle_id UUID NULLABLE REFERENCES vehicles(id)
```

**Cara baca status detail:** Lihat `driver_current_leg_id` → join ke `order_driver_assignments` → lihat `leg_master_id` + `status`. Ini menggantikan 8 ENUM hardcode dengan kombinasi dinamis:

```
Sebelum (hardcode):                    Sesudah (dinamis):
driver_status = 'logistics_departed'   → current_leg.leg_code='ANTAR_BARANG', status='departed'
driver_status = 'hearse_pickup'        → current_leg.leg_code='JEMPUT_JENAZAH', status='arrived'
driver_status = 'hearse_arrived'       → current_leg.leg_code='ANTAR_JENAZAH_RD', status='completed'
```

---

## FLOW: SO KONFIGURASI RUTE SAAT KONFIRMASI ORDER

```
STEP 2 — SO KONFIRMASI ORDER (DIPERKAYA)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SO buka order → pilih paket → sistem auto-load template rute dari order_trip_template

Tampilan di app SO:
┌─────────────────────────────────────────────────────────────┐
│ RUTE PERJALANAN — Paket Premium                             │
│                                                             │
│  ① Antar Barang          Gudang SM → [Rumah Duka Bethesda]  │
│  ② Jemput Jenazah        [RS Telogorejo] → [input alamat]   │
│  ③ Antar Jenazah ke RD   [RS Telogorejo] → [Rumah Duka]     │
│  ④ Antar ke Pemakaman    [Rumah Duka] → [Pemakaman Bergota] │
│  ⑤ Angkut Kembali        [Rumah Duka] → Gudang SM  [SKIP?] │
│                                                             │
│  [+ Tambah Leg]  [Ubah Urutan]                              │
│                                                             │
│  Alamat asal/tujuan bisa di-edit per leg.                   │
│  Leg opsional bisa di-skip.                                 │
│  SO bisa tambah leg custom (misal: "Singgah ambil bunga")   │
└─────────────────────────────────────────────────────────────┘

SO bisa:
  ✓ Edit alamat origin/destination per leg
  ✓ Skip leg opsional (contoh: angkut kembali besok saja)
  ✓ Tambah leg baru (pilih dari trip_leg_master atau input custom)
  ✓ Ubah urutan leg
  ✓ Input cargo_description per leg ("Perlengkapan misa", "Jenazah Bpk. Yohanes")
  ✓ Tandai leg mana yang bawa jenazah (is_carrying_body)

Saat SO tekan "Konfirmasi":
  → Sistem buat record order_driver_assignments per leg (status: 'pending')
  → orders.driver_total_legs = jumlah leg aktif (yang tidak di-skip)
```

---

## FLOW: DRIVER EKSEKUSI MULTI-LEG

```
Driver menerima assignment → lihat semua leg di timeline

┌──────────────────────────────────────────────────────────────┐
│ ORDER SM-20260414-0001 — Kendaraan H-1234-AB                 │
│                                                              │
│  ① ✅ Antar Barang      Gudang → Rumah Duka    [SELESAI]     │
│  ② 🔵 Jemput Jenazah    RS Telogorejo          [SEDANG]      │
│       Status: Berangkat — 09:15                              │
│       [📍 Saya Sudah Tiba] [📷 Upload Bukti]                │
│  ③ ⏳ Antar ke RD        RS → Rumah Duka        [MENUNGGU]    │
│  ④ ⏳ Antar ke Pemakaman Rumah Duka → Bergota   [MENUNGGU]    │
│  ⑤ ⏳ Angkut Kembali     Rumah Duka → Gudang    [MENUNGGU]    │
│                                                              │
│  Progress: 1/5 leg selesai                                   │
└──────────────────────────────────────────────────────────────┘

Per leg, driver lakukan:
  1. [Terima] → status: pending → assigned → accepted
  2. [Berangkat] → departed (+ foto KM + auto vehicle_km_logs)
  3. [Saya Tiba] → arrived (+ foto bukti + KM tiba)
  4. [Selesai] → completed
     → Cek: ada trigger_gate?
       → 'dekor_gate' → alarm Dekor
       → 'consumer_notify' → notif Consumer
     → Auto-advance ke leg berikutnya (status: pending → assigned)

Saat semua leg completed:
  → orders.driver_overall_status: 'in_progress' → 'all_done'
  → orders.driver_completed_legs = driver_total_legs
```

---

## GATE TRIGGER — DINAMIS

```
Sebelumnya gate dekorasi hardcode di "STEP 5 selesai".
Sekarang gate dikelola via trip_leg_master.triggers_gate:

triggers_gate = 'dekor_gate'
  → Saat leg ini completed → alarm Dekor

triggers_gate = 'consumer_notify'
  → Saat leg ini completed → notif Consumer "Jenazah telah tiba"

triggers_gate = 'gudang_return_received'
  → Saat leg ini completed → notif Gudang "Barang kembali dari order [X]"

triggers_gate = NULL
  → Tidak trigger apa-apa, lanjut ke leg berikutnya

Super Admin bisa tambah trigger baru via trip_leg_master tanpa ubah kode. (v1.27: Owner view only)
```

---

## UPDATE AUTO-COMPLETE LOGIC

```php
// SEBELUM (hardcode):
->where('driver_overall_status', 'all_done')

// SESUDAH (dinamis):
->where('driver_overall_status', 'all_done')
// ATAU: driver_completed_legs >= driver_total_legs
```

---

## CONTOH SKENARIO DINAMIS

### Skenario 1: Pemakaman Standar (5 leg)
```
① Gudang → Rumah Duka Bethesda         [barang]          → trigger: dekor_gate
② RS Telogorejo → (ambil jenazah)       [jemput jenazah]
③ RS Telogorejo → Rumah Duka Bethesda   [jenazah]         → trigger: consumer_notify
④ Rumah Duka → Pemakaman Bergota        [jenazah]         → trigger: consumer_notify
⑤ Rumah Duka → Gudang SM               [barang kembali]
```

### Skenario 2: Kremasi (4 leg)
```
① Gudang → Rumah Duka                   [barang]          → trigger: dekor_gate
② RS → Rumah Duka                       [jenazah]         → trigger: consumer_notify
③ Rumah Duka → Krematorium Semarang     [jenazah]         → trigger: consumer_notify
④ Rumah Duka → Gudang                   [barang kembali]
```

### Skenario 3: Jenazah Luar Kota (3 leg, tanpa barang)
```
① Bandara A. Yani → Rumah Duka          [jenazah]         → trigger: consumer_notify
② Rumah Duka → Pemakaman                [jenazah]         → trigger: consumer_notify
③ Rumah Duka → Gudang                   [barang kembali]
```

### Skenario 4: Peringatan / Misa Arwah (2 leg, tanpa jenazah)
```
① Gudang → Gereja St. Yoseph           [peralatan]       → trigger: NULL
② Gereja → Gudang                      [peralatan kembali]
```

### Skenario 5: Custom — SO tambah leg "Singgah ambil bunga"
```
① Gudang → Toko Bunga La Fiore         [ambil bunga]
② Toko Bunga → Rumah Duka              [barang + bunga]   → trigger: dekor_gate
③ RS → Rumah Duka                      [jenazah]          → trigger: consumer_notify
④ Rumah Duka → Pemakaman               [jenazah]          → trigger: consumer_notify
```

---

## API — ENDPOINT TRIP LEG v1.20

```
### Master Leg (Owner)
GET    /admin/master/trip-legs                     -- list semua jenis leg
POST   /admin/master/trip-legs                     -- tambah jenis leg baru
PUT    /admin/master/trip-legs/{id}                -- edit

### Template Rute per Paket (Super Admin ONLY — terkait paket)
GET    /admin/packages/{id}/trip-template          -- template rute paket ini
POST   /admin/packages/{id}/trip-template          -- set template
PUT    /admin/packages/{id}/trip-template/{legId}  -- edit leg di template

### SO — Konfigurasi Rute saat Konfirmasi Order
GET    /so/orders/{id}/trip-legs                   -- auto-load dari template paket
POST   /so/orders/{id}/trip-legs                   -- tambah leg custom
PUT    /so/orders/{id}/trip-legs/{id}              -- edit alamat/urutan
DELETE /so/orders/{id}/trip-legs/{id}              -- hapus/skip leg
PUT    /so/orders/{id}/trip-legs/reorder           -- ubah urutan

### Driver — Eksekusi Leg
GET    /driver/orders/{id}/trip-legs               -- list semua leg untuk order ini
PUT    /driver/trip-legs/{id}/accept               -- terima leg
PUT    /driver/trip-legs/{id}/depart               -- berangkat (+ foto KM)
PUT    /driver/trip-legs/{id}/arrive               -- tiba (+ foto bukti + KM)
PUT    /driver/trip-legs/{id}/complete             -- selesai leg ini
PUT    /driver/trip-legs/{id}/skip                 -- skip leg opsional
```

---

## FLUTTER — SCREEN TAMBAHAN v1.20

```
lib/features/
  ├── service_officer/screens/
  │   └── trip_route_screen.dart              -- BARU: konfigurasi rute saat konfirmasi
  │         -- Auto-load template dari paket
  │         -- Drag-and-drop reorder legs
  │         -- Per leg: edit origin/destination (Google Places autocomplete)
  │         -- Toggle "Skip" untuk leg opsional
  │         -- [+ Tambah Leg] → pilih dari master atau input custom
  │         -- Preview di peta: polyline multi-stop
  │
  ├── driver/screens/
  │   └── trip_timeline_screen.dart           -- BARU (ganti driver_assignment_screen)
  │         -- Vertical timeline semua leg
  │         -- Per leg: icon (dari master), status badge, waktu
  │         -- Leg aktif di-highlight + tombol aksi
  │         -- Progress bar: X/N leg selesai
  │         -- Peta di atas: route keseluruhan + posisi driver saat ini
```

---

### Tabel `vehicle_slot_bookings` (Booking Slot Kendaraan per Jam)

Untuk mencegah double-booking kendaraan.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
vehicle_id UUID REFERENCES vehicles(id)
order_id UUID REFERENCES orders(id)
booking_date DATE NOT NULL
start_hour TIME NOT NULL
end_hour TIME NOT NULL
status ENUM('booked','in_use','completed','cancelled') DEFAULT 'booked'
created_at TIMESTAMP
updated_at TIMESTAMP

-- Constraint: tidak boleh overlap per vehicle
```

---

### Sinkronisasi Flow Driver ke Alur Order

```
STEP 4 — GUDANG SIAP → DRIVER AUTO-ASSIGN (DIPERKAYA)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Gudang tekan "Stok Siap Angkut" →

1. Sistem cek vehicle_slot_bookings:
   → Kendaraan mana yang available di jam scheduled_at?
   → Filter by vehicle_type sesuai paket (hearse / van / bus)

2. AI Auto-Assign Driver:
   → Pilih driver: terdekat (GPS), tidak sedang tugas, shift aktif
   → Pilih kendaraan: available, tipe sesuai, KM terendah (maintenance)
   → Jika kendaraan utama tidak ada → fallback otomatis ke alternatif
   → Jika SEMUA kendaraan internal tidak ada:
     → Auto-create procurement_request (kendaraan eksternal)
     → priority: 'critical', kategori: 'kendaraan'
     → Alarm Purchasing: "Semua armada penuh — butuh kendaraan eksternal!"

3. Buat records:
   → order_driver_assignments: { task_type: 'logistics', status: 'assigned' }
   → order_driver_assignments: { task_type: 'hearse', status: 'assigned' }
   → vehicle_slot_bookings: { booked untuk durasi order }
   → vehicles.status: 'available' → 'in_use'
   → vehicles.current_driver_id, current_order_id di-update
   → orders.driver_status: 'unassigned' → 'assigned'
   → orders.assigned_driver_id, assigned_vehicle_id di-update

4. Alarm:
   → Driver: 🔔 ALARM "Kamu ditugaskan ke Order [X]. Kendaraan: [plate_number].
              Tugas 1: Antar barang dari Gudang ke [alamat].
              Tugas 2: Jemput jenazah di [RS] ke [Rumah Duka]."

STEP 5 — DRIVER TUGAS 1 (DIPERKAYA)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Driver accept assignment:
   → PUT /driver/assignments/{id}/accept
   → order_driver_assignments (logistics): 'assigned' → 'accepted'

2. Driver berangkat dari Gudang:
   → PUT /driver/assignments/{id}/depart
   → status: 'accepted' → 'departed_origin'
   → orders.driver_status: 'assigned' → 'logistics_departed'
   → vehicle_trip_logs: buat record, catat km_berangkat

3. Driver tiba di lokasi + turunkan barang:
   → PUT /driver/assignments/{id}/arrive
   → Upload bukti foto: POST /driver/orders/{id}/bukti (type: 'tiba_tujuan')
   → status: 'departed_origin' → 'arrived_destination'
   → orders.driver_status: 'logistics_departed' → 'logistics_arrived'
   → GATE DEKORASI DIBUKA → alarm Dekor

4. Driver selesai turunkan barang:
   → PUT /driver/assignments/{id}/complete
   → status: 'arrived_destination' → 'task_completed'

STEP 6 — DRIVER TUGAS 2 (DIPERKAYA)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Driver berangkat ke RS/lokasi jenazah:
   → PUT /driver/assignments/{id}/depart (task: hearse)
   → order_driver_assignments (hearse): 'assigned' → 'departed_origin'
   → orders.driver_status: 'logistics_arrived' → 'hearse_departed'

2. Driver tiba di RS, ambil jenazah:
   → PUT /driver/assignments/{id}/arrive
   → Upload bukti: type='penjemputan'
   → status: 'departed_origin' → 'arrived_destination'
   → orders.driver_status: 'hearse_departed' → 'hearse_pickup'

3. Driver antar jenazah ke Rumah Duka:
   → PUT /driver/assignments/{id}/complete
   → Upload bukti: type='tiba_tujuan'
   → status: 'arrived_destination' → 'task_completed'
   → orders.driver_status: 'hearse_pickup' → 'hearse_arrived'
   → vehicle_trip_logs: update km_tiba, hitung km_total
   → Consumer: HIGH "Jenazah telah tiba"

4. Semua tugas selesai:
   → orders.driver_status: → 'all_done'
   → vehicles.status: 'in_use' → 'available'
   → vehicles.current_driver_id: NULL
   → vehicle_slot_bookings.status: → 'completed'
```

---

### API — ENDPOINT DRIVER & VEHICLE v1.19

```
### Driver — Assignment & Status
POST   /driver/assignments/{id}/accept           -- terima assignment
PUT    /driver/assignments/{id}/depart            -- berangkat dari origin
PUT    /driver/assignments/{id}/arrive            -- tiba di destination
PUT    /driver/assignments/{id}/complete          -- tugas selesai
GET    /driver/assignments                        -- list assignment aktif driver ini
GET    /driver/assignments/{id}                   -- detail assignment + vehicle info

### Driver — Trip Log (sudah ada, diperkaya)
POST   /driver/vehicle-trip-logs                  -- buat/update nota perjalanan
GET    /driver/vehicle-trip-logs                  -- list nota milik driver
PUT    /driver/vehicle-trip-logs/{id}             -- update KM + tandatangan

### Vehicle Management (Gudang / Owner)
GET    /admin/master/vehicles                     -- list semua kendaraan
POST   /admin/master/vehicles                     -- tambah kendaraan baru
PUT    /admin/master/vehicles/{id}                -- update status/info
GET    /gudang/vehicles/availability?date=X&hour=Y -- cek ketersediaan per jam
GET    /owner/vehicles/summary                    -- dashboard armada: status semua kendaraan
GET    /owner/vehicles/{id}/history               -- riwayat penggunaan 1 kendaraan
```

---

### Update Auto-Complete Logic

```php
// SEBELUM (v1.13) — tidak sinkron:
->where('driver_overall_status', 'all_done')

// SESUDAH (v1.19) — sinkron dengan ENUM baru:
->where('driver_overall_status', 'all_done')
```

---

### Flutter — Screen Driver v1.19

```
lib/features/driver/screens/
  ├── driver_home.dart                     -- PERKAYA: status aktif + vehicle info
  │     -- Card besar: "Order SM-20260414-0001"
  │     -- Kendaraan: "H-1234-AB — Toyota HiAce"
  │     -- Status: "Tugas 1: Antar Barang" / "Tugas 2: Antar Jenazah"
  │     -- Timeline progress: assigned → departed → arrived → done
  │     -- Tombol aksi sesuai status (Accept / Berangkat / Tiba / Selesai)
  │
  ├── driver_assignment_screen.dart        -- BARU: detail assignment
  │     -- Map route: origin → destination
  │     -- Info kendaraan: foto, nopol, tipe
  │     -- Info order: alamat, nama almarhum, scheduled_at
  │     -- Checklist barang (Tugas 1) / Info jenazah (Tugas 2)
  │     -- Tombol status progression
  │
  ├── vehicle_dashboard_screen.dart        -- BARU: lihat armada (read-only)
  │     -- List semua kendaraan + status (available/in_use/maintenance)
  │     -- Siapa yang sedang pakai + untuk order apa
  │
  └── trip_log_screen.dart                 -- PERKAYA: auto-fill dari assignment
        -- KM berangkat/tiba auto-fill saat depart/arrive
        -- Tanda tangan digital
```

---

## BAGIAN B: PURCHASING — REMINDER, URGENCY, REQUESTER

### Tabel `procurement_requests` — Kolom Tambahan v1.19

```sql
-- Tambahkan ke procurement_requests:

priority ENUM('normal','high','critical') NOT NULL DEFAULT 'normal'
-- normal   : kebutuhan rutin, tidak mendesak
-- high     : dibutuhkan dalam beberapa hari
-- critical : mendesak, menghambat order yang sedang berjalan

category VARCHAR(100) NULLABLE
-- Contoh: 'stok_gudang', 'perlengkapan', 'kendaraan', 'konsumabel', 'peralatan',
--          'dekorasi', 'liturgi', 'administrasi', 'lain-lain'
-- Dikelola sebagai data di system (bukan hardcode ENUM) → bisa tambah via UI

-- Requester info (snapshot, agar tetap terlihat meski user di-nonaktifkan)
requester_role VARCHAR(50) NOT NULL          -- snapshot role saat buat permintaan
requester_name VARCHAR(255) NOT NULL         -- snapshot nama user

-- Approval tracking
awarded_at TIMESTAMP NULLABLE                -- kapan Gudang pilih pemenang
approval_deadline TIMESTAMP NULLABLE         -- auto: awarded_at + threshold
approved_at TIMESTAMP NULLABLE               -- kapan Purchasing approve
approval_duration_hours DECIMAL(6,2) NULLABLE -- approved_at - awarded_at (untuk KPI)

-- Payment tracking
payment_deadline TIMESTAMP NULLABLE          -- auto: goods_received_at + threshold
paid_at TIMESTAMP NULLABLE

-- Reminder tracking
reminder_count_approval SMALLINT DEFAULT 0   -- berapa kali reminder approval terkirim
reminder_count_payment SMALLINT DEFAULT 0    -- berapa kali reminder payment terkirim
last_reminder_at TIMESTAMP NULLABLE
```

---

### System Thresholds — Tambahan Purchasing v1.19

```
-- Approval
purchasing_approval_deadline_hours = 12       -- Purchasing harus approve dalam X jam setelah awarded
purchasing_approval_reminder_interval_hours = 4 -- reminder setiap X jam jika belum approve
purchasing_approval_max_reminders = 3         -- maks reminder sebelum eskalasi ke Owner

-- Pembayaran Supplier
supplier_payment_deadline_hours = 48          -- Purchasing harus bayar dalam X jam setelah goods_received
supplier_payment_reminder_interval_hours = 12 -- reminder setiap X jam
supplier_payment_max_reminders = 3

-- Priority auto-set
procurement_critical_if_blocking_order = true -- otomatis set 'critical' jika terkait order aktif yang needs_restock
procurement_high_if_needed_within_days = 3    -- otomatis set 'high' jika needed_by < 3 hari dari sekarang
```

---

### Scheduler — Purchasing Reminders v1.19

```php
// Setiap 30 menit: cek approval yang pending
$schedule->command('purchasing:remind-pending-approval')->everyThirtyMinutes();

// Setiap 1 jam: cek payment supplier yang pending
$schedule->command('purchasing:remind-pending-payment')->hourly();

// Setiap 6 jam: auto-set priority berdasarkan needed_by
$schedule->command('procurement:auto-priority')->everySixHours();
```

### Command: `purchasing:remind-pending-approval`

```php
$deadlineHours = SystemThreshold::getValue('purchasing_approval_deadline_hours', 12);
$reminderInterval = SystemThreshold::getValue('purchasing_approval_reminder_interval_hours', 4);
$maxReminders = SystemThreshold::getValue('purchasing_approval_max_reminders', 3);

ProcurementRequest::where('status', 'awarded')
  ->whereNotNull('awarded_at')
  ->get()
  ->each(function ($pr) use ($deadlineHours, $reminderInterval, $maxReminders) {
    $hoursSinceAwarded = now()->diffInHours($pr->awarded_at);

    // Set deadline jika belum
    if (!$pr->approval_deadline) {
      $pr->update(['approval_deadline' => $pr->awarded_at->addHours($deadlineHours)]);
    }

    // Cek apakah perlu reminder
    $shouldRemind = $pr->reminder_count_approval < $maxReminders
      && ($pr->last_reminder_at === null
          || now()->diffInHours($pr->last_reminder_at) >= $reminderInterval);

    if ($shouldRemind) {
      $pr->increment('reminder_count_approval');
      $pr->update(['last_reminder_at' => now()]);

      $urgencyLabel = match($pr->priority) {
        'critical' => '🔴 CRITICAL',
        'high'     => '🟡 HIGH',
        default    => '🔵 NORMAL',
      };

      NotificationService::sendToRole('purchasing',
        $pr->priority === 'critical' ? 'ALARM' : 'HIGH',
        "{$urgencyLabel} Butuh Approval — {$pr->request_number}",
        "Dari: {$pr->requester_name} ({$pr->requester_role})\n"
        . "Barang: {$pr->item_name}\n"
        . "Sudah {$hoursSinceAwarded} jam menunggu approval.\n"
        . "Deadline: {$pr->approval_deadline->format('d/m H:i')}"
      );
    }

    // Eskalasi ke Owner jika melebihi max reminders
    if ($pr->reminder_count_approval >= $maxReminders && $hoursSinceAwarded > $deadlineHours) {
      NotificationService::sendToRole('owner', 'ALARM',
        "⚠ Eskalasi: Approval Tertunda {$hoursSinceAwarded} jam",
        "Pengadaan {$pr->request_number} dari {$pr->requester_name} ({$pr->requester_role})"
        . " belum di-approve setelah {$maxReminders}× reminder. Priority: {$pr->priority}"
      );

      HrdViolation::firstOrCreate(
        ['order_id' => $pr->order_id, 'violation_type' => 'purchasing_late_approval'],
        [
          'violated_by' => null, // role-level, bukan personal
          'description' => "Pengadaan {$pr->request_number} belum di-approve setelah {$hoursSinceAwarded} jam",
          'severity' => $pr->priority === 'critical' ? 'high' : 'medium',
        ]
      );
    }
  });
```

### Command: `purchasing:remind-pending-payment`

```php
// Sama logic-nya tapi untuk status 'goods_received' + payment belum
$deadlineHours = SystemThreshold::getValue('supplier_payment_deadline_hours', 48);
// ...pattern sama: reminder berkala, eskalasi ke Owner, hrd_violation jika lewat deadline
```

### Command: `procurement:auto-priority`

```php
ProcurementRequest::whereIn('status', ['draft','open','evaluating','awarded'])
  ->get()
  ->each(function ($pr) {
    $newPriority = $pr->priority;

    // Critical jika blocking order aktif
    if ($pr->order_id && SystemThreshold::getValue('procurement_critical_if_blocking_order', true)) {
      $order = Order::find($pr->order_id);
      if ($order && $order->needs_restock && in_array($order->status, ['confirmed','in_progress'])) {
        $newPriority = 'critical';
      }
    }

    // High jika needed_by < X hari dari sekarang
    $daysThreshold = SystemThreshold::getValue('procurement_high_if_needed_within_days', 3);
    if ($pr->needed_by && now()->diffInDays($pr->needed_by, false) <= $daysThreshold) {
      $newPriority = $newPriority === 'critical' ? 'critical' : 'high';
    }

    if ($newPriority !== $pr->priority) {
      $pr->update(['priority' => $newPriority]);
    }
  });
```

---

### API — Endpoint Purchasing Diperkaya v1.19

```
### Purchasing — Approval (diperkaya)
GET    /purchasing/procurement-requests              -- list yang status 'awarded'
  -- Query params: ?priority=critical&sort=deadline_asc&requester_role=gudang
  -- Response includes: requester_name, requester_role, priority, hours_pending,
  --                    approval_deadline, needed_by, days_until_needed

GET    /purchasing/procurement-requests/{id}         -- detail lengkap
  -- Includes: requester info, priority badge, time elapsed, AI analysis,
  --           needed_by countdown, approval deadline countdown

PUT    /purchasing/procurement-requests/{id}/approve
PUT    /purchasing/procurement-requests/{id}/reject

### Purchasing — Payment Supplier (diperkaya)
GET    /purchasing/supplier-transactions              -- list yang perlu dibayar
  -- Query params: ?overdue=true&sort=deadline_asc
  -- Response includes: payment_deadline, days_overdue, priority

### Purchasing — Dashboard
GET    /purchasing/dashboard                          -- BARU: ringkasan lengkap
  -- Response:
  -- { pending_approvals: { total, critical, high, normal, oldest_hours },
  --   pending_payments: { total, overdue, total_amount },
  --   pending_consumer_verify: { total, oldest_hours },
  --   pending_field_team_pay: { total, overdue } }
```

---

### Tabel `hrd_violations` — Tambah Violation Type v1.19

```sql
-- Tambah ke violation_type:
'purchasing_late_approval',       -- Purchasing terlambat approve pengadaan
'purchasing_late_supplier_pay',   -- Purchasing terlambat bayar supplier
```

---

### Flutter — Screen Purchasing Diperkaya v1.19

```
lib/features/purchasing/screens/
  ├── purchasing_home.dart                 -- PERKAYA: dashboard lengkap
  │     -- 4 card utama:
  │     -- [1] Pending Approval: X (🔴 critical: Y, 🟡 high: Z)
  │     -- [2] Pending Payment Supplier: X (⚠ overdue: Y)
  │     -- [3] Pending Verify Consumer: X
  │     -- [4] Pending Bayar Tim Lapangan: X
  │     -- Tombol "Lihat Detail" per card
  │
  ├── approval_list_screen.dart            -- BARU: list pengadaan butuh approval
  │     -- Sort: deadline terdekat (default), priority tertinggi
  │     -- Filter: priority (critical/high/normal), requester_role, category
  │     -- Per item card:
  │     │   🔴 CRITICAL | "Air Putih 50 dos"
  │     │   Dari: Gerry (Gudang) → Untuk: Order SM-20260414-0001
  │     │   Dibutuhkan: 16 Apr 2026 (2 hari lagi)
  │     │   Menunggu: 8 jam | Deadline: 4 jam lagi
  │     │   Supplier: CV Maju Jaya — Rp 2.500.000
  │     │   [APPROVE] [TOLAK]
  │     │
  │     └── Tap → approval_detail_screen (sudah ada, diperkaya requester info)
  │
  ├── supplier_payment_list_screen.dart    -- PERKAYA: tambah deadline indicator
  │     -- Badge: "OVERDUE 2 hari" (merah) / "Deadline: 12 jam lagi" (kuning)
  │     -- Sort: overdue first, then deadline terdekat
  │
  └── procurement_category_screen.dart     -- BARU: kelola kategori pengadaan
        -- CRUD kategori (via admin/master)
```

---

### Tabel Alarm — Tambahan v1.19

| Momen | Purchasing | HRD | Owner | Pengaju |
|-------|-----------|-----|-------|---------|
| Pengadaan submitted & published | — | — | — | NORMAL (status update) |
| Gudang pilih pemenang → butuh approval | ALARM (+ priority badge) | — | — | NORMAL |
| Reminder approval (setiap 4 jam) | HIGH / ALARM (jika critical) | — | — | — |
| Eskalasi approval (lewat max reminders) | — | HIGH | ALARM | HIGH (eskalasi) |
| Purchasing approve | — | — | NORMAL | HIGH (disetujui!) |
| Purchasing tolak | — | — | — | HIGH (ditolak + alasan) |
| Goods received → butuh bayar | ALARM | — | — | NORMAL |
| Reminder payment (setiap 12 jam) | HIGH | — | — | — |
| Payment overdue (lewat deadline) | — | ALARM | HIGH | NORMAL |
| Priority auto-upgrade ke critical | ALARM "Priority naik!" | — | NORMAL | — |

---

---

# SANTA MARIA — PATCH v1.20
# Operasional Harian Driver & Perawatan Kendaraan Lengkap

---

## LATAR BELAKANG v1.20

Driver bukan hanya mengantar — mereka juga bertanggung jawab atas kondisi kendaraan. Patch ini menggambarkan **seluruh siklus harian driver** dan **perawatan kendaraan** sebagai satu kesatuan.

---

## SIKLUS HARIAN DRIVER — GAMBARAN LENGKAP

```
╔═══════════════════════════════════════════════════════════════════════╗
║  SIKLUS HARIAN DRIVER SANTA MARIA                                     ║
╠═══════════════════════════════════════════════════════════════════════╣
║                                                                       ║
║  ┌─── MULAI HARI ───────────────────────────────────────────────┐    ║
║  │                                                               │    ║
║  │  1. Clock-in (presensi harian, anti-mock)                     │    ║
║  │  2. Ambil kunci kendaraan yang ditugaskan                     │    ║
║  │  3. 📷 FOTO SPEEDOMETER KM AWAL HARI                         │    ║
║  │  4. Pre-trip inspection (checklist kondisi kendaraan)          │    ║
║  │     └─ Jika ada masalah → lapor → maintenance request         │    ║
║  │                                                               │    ║
║  └───────────────────────────────────────────────────────────────┘    ║
║                           ↓                                           ║
║  ┌─── SELAMA BERTUGAS ──────────────────────────────────────────┐    ║
║  │                                                               │    ║
║  │  5. Tugas order (Tugas 1: barang, Tugas 2: jenazah)          │    ║
║  │     └─ Per trip: KM berangkat/tiba dicatat otomatis          │    ║
║  │                                                               │    ║
║  │  6. ISI BENSIN (kapan saja, bisa >1x sehari)                 │    ║
║  │     └─ 📷 Foto nota SPBU                                     │    ║
║  │     └─ 📷 Foto speedometer saat isi                           │    ║
║  │     └─ Input: liter, harga, nama SPBU                        │    ║
║  │                                                               │    ║
║  │  7. Lapor masalah kendaraan (kapan saja)                     │    ║
║  │     └─ Kategori: mesin, ban, AC, lampu, body, dll            │    ║
║  │     └─ 📷 Foto kerusakan                                     │    ║
║  │     └─ Severity: bisa lanjut / harus berhenti                │    ║
║  │                                                               │    ║
║  └───────────────────────────────────────────────────────────────┘    ║
║                           ↓                                           ║
║  ┌─── AKHIR HARI ───────────────────────────────────────────────┐    ║
║  │                                                               │    ║
║  │  8. Parkir kendaraan di Gudang                                │    ║
║  │  9. 📷 FOTO SPEEDOMETER KM AKHIR HARI                        │    ║
║  │  10. Post-trip report (kondisi kendaraan akhir hari)          │    ║
║  │  11. Serahkan kunci → Clock-out                               │    ║
║  │                                                               │    ║
║  └───────────────────────────────────────────────────────────────┘    ║
║                                                                       ║
║  📊 SISTEM OTOMATIS:                                                   ║
║  • KM harian = KM akhir − KM awal (diverifikasi dari foto)           ║
║  • Fuel efficiency = KM harian / total liter isi hari ini             ║
║  • Alert jika efisiensi turun drastis (kemungkinan kebocoran/korupsi) ║
║  • Reminder maintenance jika KM mendekati next_maintenance_km         ║
║  • Semua foto tersimpan di R2 sebagai bukti audit                     ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝
```

---

## DATABASE — TABEL BARU v1.20

### Tabel `vehicle_km_logs` (Log KM Harian + Foto Speedometer)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
vehicle_id UUID REFERENCES vehicles(id)
driver_id UUID REFERENCES users(id)
log_date DATE NOT NULL
log_type ENUM('start_day','end_day','fuel_fill','trip_start','trip_end') NOT NULL
-- start_day  : foto KM pagi saat ambil kendaraan
-- end_day    : foto KM sore saat parkir
-- fuel_fill  : foto KM saat isi bensin
-- trip_start : KM berangkat per trip (auto dari assignment)
-- trip_end   : KM tiba per trip (auto dari assignment)

km_reading DECIMAL(10,2) NOT NULL            -- angka KM yang terbaca
speedometer_photo_path TEXT NOT NULL          -- foto speedometer (R2) — WAJIB

-- Referensi (opsional, tergantung log_type)
order_id UUID NULLABLE REFERENCES orders(id)
trip_log_id UUID NULLABLE REFERENCES vehicle_trip_logs(id)
fuel_log_id UUID NULLABLE REFERENCES vehicle_fuel_logs(id)

-- Validasi
is_validated BOOLEAN DEFAULT FALSE           -- backend: KM masuk akal vs log sebelumnya?
validation_notes TEXT NULLABLE               -- "KM turun — kemungkinan reset/error"

notes TEXT NULLABLE
created_at TIMESTAMP
```

---

### Tabel `vehicle_fuel_logs` (Log Pengisian BBM + Foto Nota)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
vehicle_id UUID REFERENCES vehicles(id)
driver_id UUID REFERENCES users(id)
fill_date DATE NOT NULL
fill_time TIME NOT NULL

-- Detail pengisian
fuel_type ENUM('pertalite','pertamax','pertamax_turbo','solar','dexlite') NOT NULL
liters DECIMAL(8,2) NOT NULL                 -- jumlah liter
price_per_liter DECIMAL(10,2) NOT NULL       -- harga per liter
total_price DECIMAL(15,2) NOT NULL           -- total bayar
station_name VARCHAR(255) NULLABLE           -- nama SPBU (contoh: "SPBU 44.501.12 Jl. Pandanaran")

-- KM saat isi (cross-reference ke vehicle_km_logs)
km_at_fill DECIMAL(10,2) NOT NULL            -- KM speedometer saat isi bensin
km_log_id UUID NULLABLE REFERENCES vehicle_km_logs(id)

-- Foto bukti — WAJIB
receipt_photo_path TEXT NOT NULL              -- foto nota/struk SPBU (R2)
speedometer_photo_path TEXT NOT NULL          -- foto speedometer saat isi (R2)

-- Efisiensi (dihitung otomatis dari fill sebelumnya)
km_since_last_fill DECIMAL(10,2) NULLABLE    -- KM sejak isi terakhir
liters_since_last_fill DECIMAL(8,2) NULLABLE
fuel_efficiency_km_per_liter DECIMAL(6,2) NULLABLE  -- km/liter

-- Validasi
is_validated BOOLEAN DEFAULT FALSE
validated_by UUID NULLABLE REFERENCES users(id)  -- Gudang/Owner yang verifikasi
validation_notes TEXT NULLABLE

-- Status
status ENUM('submitted','validated','flagged','rejected') DEFAULT 'submitted'
-- flagged: efisiensi anomali → perlu review manual

notes TEXT NULLABLE
created_at TIMESTAMP
updated_at TIMESTAMP
```

---

### Tabel `vehicle_inspection_master` (Master Checklist Inspeksi)

Item checklist inspeksi dikelola sebagai master data.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
item_code VARCHAR(50) UNIQUE NOT NULL        -- contoh: 'BAN_DEPAN', 'OLI_MESIN'
item_name VARCHAR(255) NOT NULL              -- contoh: 'Kondisi Ban Depan'
category VARCHAR(100) NOT NULL               -- 'ban', 'mesin', 'kelistrikan', 'body', 'interior', 'kelengkapan'
check_type ENUM('ok_notok','level','reading') NOT NULL DEFAULT 'ok_notok'
-- ok_notok : cek kondisi baik/tidak
-- level    : cek level (penuh/sedang/kurang) — contoh: oli, air radiator
-- reading  : cek angka — contoh: tekanan ban
sort_order INTEGER DEFAULT 0
is_active BOOLEAN DEFAULT TRUE
created_at TIMESTAMP
updated_at TIMESTAMP
```

Initial seed:
```
═══ BAN ═══
BAN_DEPAN_KIRI   | Kondisi Ban Depan Kiri    | ban          | ok_notok
BAN_DEPAN_KANAN  | Kondisi Ban Depan Kanan   | ban          | ok_notok
BAN_BELAKANG_KIRI | Kondisi Ban Belakang Kiri | ban         | ok_notok
BAN_BELAKANG_KANAN| Kondisi Ban Belakang Kanan| ban         | ok_notok
BAN_SEREP        | Ketersediaan Ban Serep     | ban          | ok_notok
TEKANAN_BAN      | Tekanan Ban (psi)          | ban          | reading

═══ MESIN ═══
OLI_MESIN        | Level Oli Mesin            | mesin        | level
AIR_RADIATOR     | Level Air Radiator         | mesin        | level
AIR_WIPER        | Level Air Wiper            | mesin        | level
MINYAK_REM       | Level Minyak Rem           | mesin        | level
ACCU             | Kondisi Accu/Aki           | mesin        | ok_notok
BELT_FAN         | Kondisi Belt/Fan Belt      | mesin        | ok_notok
SUARA_MESIN      | Suara Mesin Normal         | mesin        | ok_notok

═══ KELISTRIKAN ═══
LAMPU_DEPAN      | Lampu Depan                | kelistrikan  | ok_notok
LAMPU_BELAKANG   | Lampu Belakang             | kelistrikan  | ok_notok
LAMPU_SEN        | Lampu Sen Kiri/Kanan       | kelistrikan  | ok_notok
LAMPU_REM        | Lampu Rem                  | kelistrikan  | ok_notok
KLAKSON          | Klakson                    | kelistrikan  | ok_notok
AC               | AC Berfungsi               | kelistrikan  | ok_notok
WIPER            | Wiper Berfungsi            | kelistrikan  | ok_notok

═══ BODY & INTERIOR ═══
BODY_EXTERIOR    | Kondisi Body Luar          | body         | ok_notok
KACA_DEPAN       | Kaca Depan                 | body         | ok_notok
KACA_SPION       | Kaca Spion Kiri/Kanan      | body         | ok_notok
INTERIOR_BERSIH  | Kebersihan Interior        | interior     | ok_notok
JEMPUT_JENAZAH   | Kompartemen Jenazah Bersih | interior     | ok_notok

═══ KELENGKAPAN ═══
STNK_AKTIF       | STNK Masih Aktif           | kelengkapan  | ok_notok
DONGKRAK         | Dongkrak Tersedia          | kelengkapan  | ok_notok
KUNCI_RODA       | Kunci Roda Tersedia        | kelengkapan  | ok_notok
SEGITIGA_PENGAMAN| Segitiga Pengaman          | kelengkapan  | ok_notok
KOTAK_P3K        | Kotak P3K                  | kelengkapan  | ok_notok
APAR             | APAR (Pemadam Kecil)       | kelengkapan  | ok_notok
```

---

### Tabel `vehicle_inspections` (Inspeksi Harian per Kendaraan)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
vehicle_id UUID REFERENCES vehicles(id)
driver_id UUID REFERENCES users(id)
inspection_date DATE NOT NULL
inspection_type ENUM('pre_trip','post_trip') NOT NULL DEFAULT 'pre_trip'

-- KM saat inspeksi
km_reading DECIMAL(10,2) NOT NULL
km_photo_path TEXT NOT NULL                  -- foto speedometer

-- Summary
total_items INTEGER NOT NULL                 -- jumlah item yang dicek
passed_items INTEGER NOT NULL                -- jumlah yang OK
failed_items INTEGER NOT NULL                -- jumlah yang bermasalah
overall_status ENUM('pass','fail_minor','fail_major') NOT NULL
-- pass       : semua OK, kendaraan layak jalan
-- fail_minor : ada masalah kecil, masih bisa jalan tapi perlu perhatian
-- fail_major : ada masalah besar, kendaraan TIDAK boleh jalan

-- Approval (jika fail_major)
approved_to_drive BOOLEAN DEFAULT TRUE       -- Gudang/Super Admin bisa override (v1.27: Owner view only)
approved_by UUID NULLABLE REFERENCES users(id)
approval_notes TEXT NULLABLE

notes TEXT NULLABLE
created_at TIMESTAMP
updated_at TIMESTAMP

UNIQUE(vehicle_id, inspection_date, inspection_type)
```

---

### Tabel `vehicle_inspection_items` (Detail Checklist per Inspeksi)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
inspection_id UUID REFERENCES vehicle_inspections(id) ON DELETE CASCADE
master_item_id UUID REFERENCES vehicle_inspection_master(id)

-- Hasil cek
result ENUM('ok','not_ok','na') NOT NULL DEFAULT 'ok'
-- ok     : kondisi baik
-- not_ok : ada masalah
-- na     : tidak applicable (misal: kompartemen jenazah di van logistik)

level_value VARCHAR(50) NULLABLE             -- untuk check_type='level': 'penuh','sedang','kurang','kosong'
reading_value DECIMAL(10,2) NULLABLE         -- untuk check_type='reading': angka (misal: tekanan ban 32 psi)

-- Foto kerusakan (jika not_ok)
photo_path TEXT NULLABLE                     -- foto masalah (R2)
notes VARCHAR(500) NULLABLE                  -- catatan: "Ban depan kiri aus, perlu ganti"

severity ENUM('info','warning','critical') DEFAULT 'info'
-- info     : catatan saja (sedikit kotor, dll)
-- warning  : perlu perhatian segera (oli mulai kurang)
-- critical : tidak boleh jalan (ban bocor, rem blong)

created_at TIMESTAMP
```

---

### Tabel `vehicle_maintenance_requests` (Permintaan Perawatan dari Driver)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
request_number VARCHAR(50) UNIQUE NOT NULL   -- contoh: MTC-20260414-001
vehicle_id UUID REFERENCES vehicles(id)
reported_by UUID REFERENCES users(id)        -- driver yang lapor

-- Sumber laporan
source ENUM('inspection','during_trip','end_of_day','scheduled') NOT NULL
-- inspection   : dari pre-trip/post-trip inspection (link ke inspection_id)
-- during_trip  : lapor masalah saat sedang bertugas
-- end_of_day   : lapor saat akhir hari
-- scheduled    : maintenance terjadwal (dari sistem)
inspection_id UUID NULLABLE REFERENCES vehicle_inspections(id)
order_id UUID NULLABLE REFERENCES orders(id)  -- jika masalah terjadi saat order

-- Detail masalah
category VARCHAR(100) NOT NULL               -- 'ban', 'mesin', 'kelistrikan', 'body', 'ac', 'lain'
description TEXT NOT NULL
severity ENUM('low','medium','high','critical') NOT NULL
-- low      : cosmetic, bisa ditunda (cat lecet)
-- medium   : perlu segera tapi tidak urgent (wiper aus)
-- high     : harus ditangani hari ini (AC mati, lampu mati)
-- critical : kendaraan tidak boleh jalan (rem blong, ban pecah)

-- Foto bukti
photo_paths JSONB DEFAULT '[]'               -- array path foto kerusakan di R2

-- Status
status ENUM(
  'reported',              -- driver sudah lapor
  'acknowledged',          -- Gudang sudah lihat
  'parts_needed',          -- perlu beli spare part → link ke procurement
  'in_progress',           -- sedang diperbaiki
  'completed',             -- selesai diperbaiki
  'deferred'               -- ditunda (masalah kecil, dijadwalkan nanti)
) DEFAULT 'reported'

-- Link ke pengadaan (jika perlu beli part)
procurement_request_id UUID NULLABLE REFERENCES procurement_requests(id)

-- Penanganan
handled_by UUID NULLABLE REFERENCES users(id)  -- Gudang / teknisi yang handle
handled_at TIMESTAMP NULLABLE
completion_notes TEXT NULLABLE
completion_photo_path TEXT NULLABLE           -- foto setelah diperbaiki

-- Biaya
estimated_cost DECIMAL(15,2) DEFAULT 0
actual_cost DECIMAL(15,2) DEFAULT 0

created_at TIMESTAMP
updated_at TIMESTAMP
```

---

### Tabel `vehicle_maintenance_schedule` (Jadwal Perawatan Berkala)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
vehicle_id UUID REFERENCES vehicles(id)
maintenance_type VARCHAR(100) NOT NULL       -- 'ganti_oli', 'tune_up', 'ganti_ban', 'servis_besar'
description TEXT NULLABLE

-- Interval (salah satu atau keduanya)
interval_km DECIMAL(10,2) NULLABLE           -- setiap X KM
interval_months SMALLINT NULLABLE            -- setiap X bulan

-- Tracking
last_done_at DATE NULLABLE
last_done_km DECIMAL(10,2) NULLABLE
next_due_date DATE NULLABLE                  -- auto: last_done + interval_months
next_due_km DECIMAL(10,2) NULLABLE           -- auto: last_done_km + interval_km

-- Status
status ENUM('upcoming','due','overdue','completed') DEFAULT 'upcoming'

is_active BOOLEAN DEFAULT TRUE
created_at TIMESTAMP
updated_at TIMESTAMP
```

Initial seed per kendaraan:
```
ganti_oli     | Ganti Oli Mesin       | interval_km: 5000  | interval_months: 3
tune_up       | Tune Up / Servis Rutin | interval_km: 10000 | interval_months: 6
ganti_ban     | Ganti Ban             | interval_km: 40000 | interval_months: 24
servis_besar  | Servis Besar          | interval_km: 20000 | interval_months: 12
ganti_aki     | Ganti Accu/Aki        | interval_km: null   | interval_months: 18
cek_rem       | Cek & Ganti Rem       | interval_km: 15000 | interval_months: 12
ganti_filter  | Ganti Filter Udara+Oli| interval_km: 10000 | interval_months: 6
```

---

## SYSTEM THRESHOLDS — TAMBAHAN v1.20

```
-- Fuel
fuel_efficiency_alert_drop_percent = 20   -- alert jika efisiensi turun > 20% dari rata-rata
fuel_max_fill_per_day = 3                 -- maks isi bensin per hari (anomali jika lebih)

-- KM Validation
km_max_daily = 500                        -- maks KM per hari (anomali jika lebih)
km_tolerance_percent = 5                  -- toleransi perbedaan KM foto vs input manual

-- Maintenance
maintenance_reminder_days_before = 7      -- reminder X hari sebelum jadwal servis
maintenance_reminder_km_before = 500      -- reminder sisa X KM sebelum servis
maintenance_critical_auto_block = true    -- jika severity critical → kendaraan otomatis diblokir

-- Inspection
inspection_required_before_trip = true    -- wajib inspeksi sebelum berangkat
inspection_max_failed_to_drive = 0        -- maks item critical gagal untuk tetap boleh jalan (0 = tidak boleh)
```

---

## SCHEDULER — KENDARAAN v1.20

```php
// Cek jadwal maintenance yang mendekati due date / KM
$schedule->command('vehicle:check-maintenance-schedule')->dailyAt('07:00')
  ->timezone('Asia/Jakarta');

// Validasi fuel efficiency anomali
$schedule->command('vehicle:check-fuel-anomaly')->dailyAt('22:00')
  ->timezone('Asia/Jakarta');

// Cek driver yang belum foto KM akhir hari
$schedule->command('vehicle:check-end-of-day-km')->dailyAt('20:00')
  ->timezone('Asia/Jakarta');
```

### Command: `vehicle:check-maintenance-schedule`

```php
$daysBefore = SystemThreshold::getValue('maintenance_reminder_days_before', 7);
$kmBefore = SystemThreshold::getValue('maintenance_reminder_km_before', 500);

VehicleMaintenanceSchedule::where('is_active', true)
  ->where('status', '!=', 'completed')
  ->each(function ($schedule) use ($daysBefore, $kmBefore) {
    $vehicle = $schedule->vehicle;
    $isDue = false;
    $reason = '';

    // Cek berdasarkan tanggal
    if ($schedule->next_due_date && $schedule->next_due_date <= now()->addDays($daysBefore)) {
      $isDue = true;
      $reason = "Jadwal {$schedule->maintenance_type}: "
        . ($schedule->next_due_date <= today() ? 'SUDAH LEWAT' : $schedule->next_due_date->diffInDays(today()) . ' hari lagi');
      $schedule->update(['status' => $schedule->next_due_date <= today() ? 'overdue' : 'due']);
    }

    // Cek berdasarkan KM
    if ($schedule->next_due_km && $vehicle->last_km >= ($schedule->next_due_km - $kmBefore)) {
      $isDue = true;
      $sisaKm = $schedule->next_due_km - $vehicle->last_km;
      $reason .= ($reason ? ' | ' : '') . "Sisa {$sisaKm} KM untuk {$schedule->maintenance_type}";
      $schedule->update(['status' => $sisaKm <= 0 ? 'overdue' : 'due']);
    }

    if ($isDue) {
      NotificationService::sendToRole('gudang', 'HIGH',
        "🔧 Maintenance {$vehicle->plate_number}",
        $reason
      );
      NotificationService::sendToUser($vehicle->current_driver_id, 'HIGH',
        "Kendaraanmu Perlu Servis",
        $reason
      );
    }
  });
```

### Command: `vehicle:check-fuel-anomaly`

```php
$dropThreshold = SystemThreshold::getValue('fuel_efficiency_alert_drop_percent', 20);

// Per kendaraan: bandingkan efisiensi isi terakhir vs rata-rata 30 hari
Vehicle::where('is_active', true)->each(function ($vehicle) use ($dropThreshold) {
  $avgEfficiency = VehicleFuelLog::where('vehicle_id', $vehicle->id)
    ->where('fill_date', '>=', now()->subDays(30))
    ->whereNotNull('fuel_efficiency_km_per_liter')
    ->avg('fuel_efficiency_km_per_liter');

  $lastFill = VehicleFuelLog::where('vehicle_id', $vehicle->id)
    ->latest('fill_date')->first();

  if ($avgEfficiency && $lastFill && $lastFill->fuel_efficiency_km_per_liter) {
    $dropPercent = (($avgEfficiency - $lastFill->fuel_efficiency_km_per_liter) / $avgEfficiency) * 100;

    if ($dropPercent > $dropThreshold) {
      $lastFill->update(['status' => 'flagged']);

      NotificationService::sendToRole('gudang', 'ALARM',
        "⛽ Anomali BBM — {$vehicle->plate_number}",
        "Efisiensi turun {$dropPercent}%: {$lastFill->fuel_efficiency_km_per_liter} km/l "
        . "(rata-rata: {$avgEfficiency} km/l). Kemungkinan: kebocoran / pemakaian pribadi."
      );
      NotificationService::sendToRole('owner', 'HIGH',
        "Anomali BBM {$vehicle->plate_number}",
        "Efisiensi turun drastis. Review diperlukan."
      );
    }
  }
});
```

---

## API — ENDPOINT KENDARAAN & DRIVER v1.20

```
### Driver — KM Harian (Foto Speedometer)
POST   /driver/vehicles/{vehicleId}/km-log        -- foto KM + angka
  body: { log_type: 'start_day'|'end_day', km_reading: 45230,
          speedometer_photo: file }
GET    /driver/vehicles/{vehicleId}/km-logs        -- riwayat KM hari ini
GET    /driver/vehicles/{vehicleId}/km-summary     -- ringkasan: KM awal, KM akhir, total hari ini

### Driver — Isi Bensin (Foto Nota + Speedometer)
POST   /driver/vehicles/{vehicleId}/fuel-logs      -- catat isi bensin
  body: { fuel_type: 'pertalite', liters: 35.5, price_per_liter: 10000,
          total_price: 355000, station_name: 'SPBU Pandanaran',
          km_at_fill: 45280, receipt_photo: file, speedometer_photo: file }
GET    /driver/vehicles/{vehicleId}/fuel-logs       -- riwayat isi bensin
GET    /driver/vehicles/{vehicleId}/fuel-efficiency  -- grafik efisiensi per isi

### Driver — Inspeksi Harian
POST   /driver/vehicles/{vehicleId}/inspections     -- submit inspeksi
  body: { inspection_type: 'pre_trip', km_reading: 45230, km_photo: file,
          items: [
            { master_item_id: 'X', result: 'ok' },
            { master_item_id: 'Y', result: 'not_ok', severity: 'critical',
              notes: 'Ban depan kiri bocor', photo: file }
          ] }
GET    /driver/vehicles/{vehicleId}/inspections     -- riwayat inspeksi

### Driver — Lapor Masalah Kendaraan
POST   /driver/vehicles/{vehicleId}/maintenance-requests
  body: { source: 'during_trip', category: 'ban', severity: 'high',
          description: 'Ban depan kiri pecah', photos: [file, file],
          order_id: 'X' }
GET    /driver/maintenance-requests                -- list laporan saya

### Gudang — Kelola Maintenance
GET    /gudang/maintenance-requests                 -- list semua laporan (filter status/severity)
GET    /gudang/maintenance-requests/{id}
PUT    /gudang/maintenance-requests/{id}/acknowledge -- sudah dilihat
PUT    /gudang/maintenance-requests/{id}/start      -- mulai perbaikan
PUT    /gudang/maintenance-requests/{id}/complete   -- selesai perbaikan
  body: { completion_notes, actual_cost, completion_photo: file }
PUT    /gudang/maintenance-requests/{id}/defer      -- tunda
POST   /gudang/maintenance-requests/{id}/procurement -- buat PO untuk beli part

### Gudang — Validasi BBM
GET    /gudang/fuel-logs                            -- list semua (filter: flagged, unvalidated)
PUT    /gudang/fuel-logs/{id}/validate              -- validasi OK
PUT    /gudang/fuel-logs/{id}/reject                -- tolak (nota palsu, dll)

### Gudang/Owner — Jadwal Maintenance
GET    /gudang/maintenance-schedules                -- semua jadwal per kendaraan
GET    /gudang/maintenance-schedules/due            -- yang sudah jatuh tempo / segera
POST   /gudang/maintenance-schedules                -- tambah jadwal baru
PUT    /gudang/maintenance-schedules/{id}/complete  -- tandai selesai servis

### Owner — Dashboard Armada
GET    /owner/vehicles/fuel-report?month=2026-04    -- laporan BBM per kendaraan per bulan
GET    /owner/vehicles/maintenance-report           -- laporan biaya maintenance
GET    /owner/vehicles/{id}/complete-history        -- semua: KM, BBM, inspeksi, maintenance
```

---

## FLUTTER — SCREEN DRIVER v1.20

```
lib/features/driver/screens/
  ├── driver_home.dart                         -- PERKAYA: tambah section kendaraan
  │     -- Card 1: Order Aktif (sudah ada)
  │     -- Card 2: Kendaraan Hari Ini
  │     │   "H-1234-AB — Toyota HiAce"
  │     │   KM Awal: 45.230 | KM Sekarang: - | BBM Hari Ini: 1x
  │     │   Tombol: [📷 Foto KM] [⛽ Isi BBM] [🔧 Lapor Masalah]
  │     -- Card 3: Inspeksi
  │     │   Status: "Belum inspeksi hari ini" (merah) / "Inspeksi OK ✓" (hijau)
  │     │   Tombol: [Mulai Inspeksi]
  │
  ├── km_log_screen.dart                       -- BARU: foto KM
  │     -- Kamera langsung terbuka (seperti selfie di presensi)
  │     -- Preview foto → input angka KM manual (untuk cross-check)
  │     -- "Foto ini menunjukkan KM: [___]"
  │     -- Submit → backend validasi (KM harus > KM terakhir)
  │
  ├── fuel_log_screen.dart                     -- BARU: catat isi bensin
  │     -- Step 1: Foto nota SPBU (kamera)
  │     -- Step 2: Foto speedometer (kamera)
  │     -- Step 3: Input form:
  │     │   Jenis BBM: [dropdown: Pertalite/Pertamax/...]
  │     │   Liter: [___] | Harga/liter: [___] | Total: [auto]
  │     │   Nama SPBU: [___]
  │     -- Submit → efisiensi dihitung otomatis
  │     -- "Efisiensi: 9.5 km/l (rata-rata: 10.2 km/l)" — warning jika drop
  │
  ├── inspection_screen.dart                   -- BARU: checklist inspeksi
  │     -- Header: kendaraan, tanggal, tipe (pre-trip/post-trip)
  │     -- Step 1: Foto speedometer (KM)
  │     -- Step 2: Checklist per category (accordion):
  │     │   ▼ Ban (6 item)
  │     │     Ban Depan Kiri: [✓ OK] [✗ Bermasalah]
  │     │     jika ✗ → input severity + foto + catatan
  │     │   ▼ Mesin (7 item)
  │     │   ▼ Kelistrikan (7 item)
  │     │   ▼ Body & Interior (5 item)
  │     │   ▼ Kelengkapan (6 item)
  │     -- Summary: "28/30 item OK — 2 bermasalah (1 critical)"
  │     -- Jika ada critical → warning besar merah:
  │     │   "⚠ KENDARAAN TIDAK LAYAK JALAN — Hubungi Gudang"
  │     -- Submit → notif Gudang jika ada masalah
  │
  ├── maintenance_report_screen.dart           -- BARU: lapor masalah kendaraan
  │     -- Kategori: [dropdown: ban/mesin/ac/kelistrikan/body/lain]
  │     -- Severity: [low/medium/high/critical] — dengan penjelasan per level
  │     -- Deskripsi: [textarea]
  │     -- Foto: [ambil foto kerusakan] (multi-foto)
  │     -- "Apakah kendaraan masih bisa digunakan?" [Ya/Tidak]
  │     -- Submit → alarm Gudang
  │
  └── driver_vehicle_history_screen.dart       -- BARU: riwayat kendaraan yang dipakai
        -- Tab: KM Harian | BBM | Inspeksi | Maintenance
        -- Per tab: list + grafik trend
```

### Flutter — Screen Gudang Kendaraan v1.20

```
lib/features/gudang/screens/
  ├── vehicle_maintenance_screen.dart          -- BARU: kelola maintenance
  │     -- Tab "Laporan Masuk": list per severity, sort terbaru
  │     -- Tab "Sedang Diperbaiki": progress
  │     -- Tab "Jadwal Servis": timeline maintenance terjadwal
  │     -- Per laporan: foto, deskripsi, tombol [Proses] [Beli Part] [Tunda]
  │
  ├── fuel_validation_screen.dart              -- BARU: validasi nota BBM
  │     -- List nota yang belum divalidasi
  │     -- Per nota: foto nota, foto speedometer, detail, efisiensi
  │     -- Badge: "Normal" (hijau) / "Anomali" (merah)
  │     -- Tombol: [Validasi ✓] [Tolak ✗]
  │
  └── vehicle_overview_screen.dart             -- BARU: overview armada
        -- Per kendaraan: status, KM terakhir, efisiensi rata-rata, servis berikutnya
        -- Badge warna: hijau (OK) / kuning (servis segera) / merah (masalah aktif)
```

---

## TABEL ALARM KENDARAAN v1.20

| Momen | Driver | Gudang | HRD | Owner |
|-------|--------|--------|-----|-------|
| Pre-trip inspection: semua OK | — | — | — | — |
| Pre-trip inspection: ada masalah minor | — | HIGH | — | — |
| Pre-trip inspection: ada CRITICAL | TOLAK jalan | ALARM | HIGH | HIGH |
| Isi BBM normal | — | — | — | — |
| BBM efisiensi anomali | NORMAL | ALARM | — | HIGH |
| Lapor masalah kendaraan | — | ALARM (+ severity) | — | HIGH jika critical |
| Maintenance request selesai | HIGH (kendaraan OK) | — | — | — |
| Jadwal servis mendekat (7 hari) | HIGH | HIGH | — | — |
| Jadwal servis terlewat (overdue) | — | ALARM | HIGH | HIGH |
| Driver belum foto KM akhir hari | HIGH (reminder) | — | — | — |
| KM harian anomali (> 500 km) | — | HIGH | — | NORMAL |

---

## ATURAN BISNIS v1.20

```
1. FOTO SPEEDOMETER wajib saat:
   - Awal hari (start_day) — sebelum boleh terima assignment
   - Akhir hari (end_day) — sebelum clock-out
   - Setiap isi bensin — bukti KM saat isi
   → Foto disimpan di R2, tidak bisa dihapus

2. FOTO NOTA BENSIN wajib setiap isi BBM
   → Nota harus jelas (tanggal, liter, harga)
   → Gudang validasi → jika ditolak → driver harus jelaskan

3. PRE-TRIP INSPECTION wajib sebelum berangkat
   → Jika ada item CRITICAL gagal → kendaraan otomatis diblokir
   → Driver tidak bisa accept assignment sampai Gudang approve override
   → Atau kendaraan diganti (fallback)

4. EFISIENSI BBM dihitung otomatis per isi
   → km_since_last_fill / liters = km/liter
   → Dibandingkan dengan rata-rata 30 hari kendaraan tersebut
   → Drop > 20% → flagged + alarm Gudang (kemungkinan bocor / pemakaian pribadi)

5. MAINTENANCE REQUEST dari driver:
   → severity critical: kendaraan otomatis status='maintenance', tidak bisa di-assign
   → Gudang bisa link ke procurement_request jika perlu beli part
   → Biaya dicatat: estimated_cost (sebelum) vs actual_cost (sesudah)

6. JADWAL PERAWATAN BERKALA:
   → Ditrack per KM dan per bulan (mana yang duluan tercapai)
   → 7 hari / 500 KM sebelum due → reminder Gudang + Driver
   → Jika overdue → alarm HRD + Owner

7. KM VALIDATION:
   → Backend cek: KM baru harus > KM terakhir (tidak boleh mundur)
   → Toleransi perbedaan foto vs input manual: 5%
   → KM harian > 500 km → flag anomali

8. Semua foto (speedometer, nota, inspeksi, kerusakan) adalah bukti audit
   → Tidak bisa dihapus oleh siapapun kecuali Super Admin
   → Retention policy: simpan minimal 2 tahun
```

---

## INTEGRASI KE KPI (v1.16)

Tambahkan metrik KPI driver baru:

```
DRV_INSPECTION_RATE  | Tingkat Inspeksi Harian
  data_source: vehicle_inspections
  calculation: % hari dengan pre_trip inspection vs hari kerja
  target: 100% | direction: higher_is_better | bobot: disesuaikan

DRV_FUEL_EFFICIENCY  | Efisiensi BBM Rata-rata
  data_source: vehicle_fuel_logs
  calculation: AVG fuel_efficiency_km_per_liter
  target: ≥ 8 km/l (tergantung kendaraan) | direction: higher_is_better

DRV_KM_LOG_COMPLIANCE | Kelengkapan Foto KM
  data_source: vehicle_km_logs
  calculation: % hari dengan start_day + end_day foto vs hari kerja
  target: 100% | direction: higher_is_better
```

---

---

# SANTA MARIA — PATCH v1.21
# Purchasing: Fix Gap PO, Billing Status, Supplier Account, Payment Audit Trail

---

## TEMUAN AUDIT PURCHASING

| # | Temuan | Severity |
|---|--------|----------|
| 1 | `purchase_orders` — endpoint ada tapi tabel TIDAK ADA | 🔴 Blocker |
| 2 | `order_billing_items` tidak punya `billing_status` — Purchasing tidak bisa tutup billing | 🔴 Blocker |
| 3 | Supplier bank account tidak disimpan di mana-mana | 🔴 Blocker |
| 4 | Tidak ada payment audit trail (siapa ubah apa kapan) | 🔴 Blocker |
| 5 | Consumer payment: tidak ada `rejection_reason`, `retry_count` | 🟡 Gap |
| 6 | Field team: tidak ada bulk payment | 🟡 Gap |
| 7 | Tidak ada billing_number / nomor tagihan | 🟡 Gap |
| 8 | Report endpoint tidak ada parameter filter | 🟡 Gap |
| 9 | Tidak ada kas / budget visibility | 🟡 Nice-to-have |

---

## FIX 1: Purchase Orders = Procurement Requests (KLARIFIKASI)

**Keputusan:** PO (Purchase Order) dan Procurement Request adalah **hal yang sama**. Endpoint `/purchasing/purchase-orders` adalah alias dari `/purchasing/procurement-requests`. Tidak perlu tabel terpisah.

Alasan:
- Alur e-Katalog sudah menangani siklus lengkap: request → quote → award → approve → bayar
- PO langsung (tanpa bidding) ditangani sebagai procurement_request tanpa fase bidding:
  status langsung `draft` → `awarded` (Gudang langsung pilih supplier) → `purchasing_approved`

```sql
-- Tambahkan ke procurement_requests:

is_direct_po BOOLEAN DEFAULT FALSE
-- true  = PO langsung tanpa bidding (Gudang sudah tahu supplier-nya)
-- false = e-Katalog normal dengan bidding terbuka

-- Jika is_direct_po = true:
-- → Tidak perlu fase 'open' dan 'evaluating'
-- → Gudang langsung assign supplier + harga → status: 'awarded'
-- → Purchasing approve → done
```

**Endpoint update — hapus redundansi:**
```
-- HAPUS endpoint terpisah:
-- GET    /purchasing/purchase-orders          ← HAPUS, pakai procurement-requests
-- GET    /purchasing/purchase-orders/{id}     ← HAPUS
-- PUT    /purchasing/purchase-orders/{id}/approve  ← HAPUS
-- PUT    /purchasing/purchase-orders/{id}/reject   ← HAPUS

-- GANTI dengan filter di procurement-requests:
GET    /purchasing/procurement-requests?is_direct_po=true   -- list PO langsung
GET    /purchasing/procurement-requests?is_direct_po=false  -- list e-Katalog
GET    /purchasing/procurement-requests                     -- list semua (default)
```

---

## FIX 2: Tabel `order_billings` (Header Tagihan per Order)

Menambahkan header tagihan dengan status lifecycle. `order_billing_items` menjadi detail-nya.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
order_id UUID REFERENCES orders(id)
billing_number VARCHAR(50) UNIQUE NOT NULL    -- contoh: INV-20260414-0001

-- Status
status ENUM(
  'draft',              -- auto-generated saat SO konfirmasi, item bisa berubah
  'adjustment',         -- ada retur barang, billing sedang di-adjust
  'finalized',          -- Purchasing sudah finalisasi (tidak bisa edit lagi)
  'exported',           -- sudah di-export PDF
  'paid',               -- consumer sudah bayar (link ke orders.payment_status)
  'closed'              -- arsip final — semua selesai
) DEFAULT 'draft'

-- Ringkasan nilai (auto-calculated dari order_billing_items)
subtotal DECIMAL(15,2) DEFAULT 0             -- Σ total_price semua items
total_tambahan DECIMAL(15,2) DEFAULT 0       -- Σ tambahan (dari extra_approvals)
total_kembali DECIMAL(15,2) DEFAULT 0        -- Σ kembali (dari retur)
grand_total DECIMAL(15,2) DEFAULT 0          -- subtotal + tambahan - kembali

-- Finalisasi
finalized_by UUID NULLABLE REFERENCES users(id)
finalized_at TIMESTAMP NULLABLE
finalization_notes TEXT NULLABLE

-- Export tracking
last_exported_at TIMESTAMP NULLABLE
export_count SMALLINT DEFAULT 0

-- Timestamps
created_at TIMESTAMP
updated_at TIMESTAMP
```

**Update `order_billing_items` — tambah FK ke header:**
```sql
-- Tambahkan:
billing_id UUID REFERENCES order_billings(id) ON DELETE CASCADE
```

**Flow billing lengkap:**
```
SO konfirmasi → order_billings dibuat (status: draft)
                order_billing_items auto-generate dari paket + addons

Selama order berlangsung:
  → SO tambah extra_approval → billing tetap draft, tambahan terupdate
  → Retur barang → billing status: adjustment, kembali terupdate

Order selesai + payment masuk:
  → Purchasing finalisasi billing: review semua item, koreksi jika perlu
  → PUT /purchasing/orders/{id}/billing/finalize
  → status: draft/adjustment → finalized

Export:
  → GET /purchasing/billing/export/{orderId} → PDF
  → status: finalized → exported, export_count++

Payment verified:
  → status: → paid

Arsip:
  → Setelah semua pos-order selesai (peralatan kembali, upah dibayar, akta serah terima)
  → PUT /purchasing/orders/{id}/billing/close
  → status: → closed
```

---

## FIX 3: Tabel `supplier_accounts` (Rekening Supplier)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
supplier_id UUID REFERENCES users(id)        -- FK ke user role 'supplier'
bank_name VARCHAR(255) NOT NULL              -- contoh: 'BCA', 'Mandiri', 'BNI'
account_number VARCHAR(50) NOT NULL          -- nomor rekening
account_holder_name VARCHAR(255) NOT NULL    -- nama pemilik rekening
branch VARCHAR(255) NULLABLE                 -- cabang (opsional)
is_primary BOOLEAN DEFAULT TRUE              -- rekening utama
is_active BOOLEAN DEFAULT TRUE
created_at TIMESTAMP
updated_at TIMESTAMP

UNIQUE(supplier_id, account_number)
```

**Update `supplier_transactions` — link ke rekening:**
```sql
-- Tambahkan:
supplier_account_id UUID NULLABLE REFERENCES supplier_accounts(id)
-- Rekening tujuan pembayaran — otomatis terisi dari supplier_accounts.is_primary
```

**Update Supplier profile endpoint:**
```
-- Supplier kelola rekening sendiri:
GET    /supplier/accounts                     -- list rekening saya
POST   /supplier/accounts                     -- tambah rekening
PUT    /supplier/accounts/{id}                -- edit
PUT    /supplier/accounts/{id}/set-primary    -- jadikan utama
```

---

## FIX 4: Tabel `payment_audit_logs` (Audit Trail Pembayaran)

Mencatat SETIAP perubahan status pembayaran di semua konteks.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
context ENUM(
  'consumer_payment',         -- verifikasi pembayaran consumer
  'supplier_payment',         -- pembayaran ke supplier
  'field_team_payment',       -- pembayaran upah tim lapangan
  'billing_status_change'     -- perubahan status billing
) NOT NULL

-- Referensi (salah satu terisi sesuai context)
order_id UUID NULLABLE REFERENCES orders(id)
supplier_transaction_id UUID NULLABLE REFERENCES supplier_transactions(id)
field_team_payment_id UUID NULLABLE REFERENCES order_field_team_payments(id)
billing_id UUID NULLABLE REFERENCES order_billings(id)

-- Perubahan
action VARCHAR(100) NOT NULL                 -- 'verify', 'reject', 'pay', 'finalize', 'close', dll
from_status VARCHAR(50) NULLABLE             -- status sebelum
to_status VARCHAR(50) NOT NULL               -- status sesudah
amount DECIMAL(15,2) NULLABLE                -- nominal terkait (jika ada)

-- Siapa & kapan
performed_by UUID REFERENCES users(id)
performed_at TIMESTAMP NOT NULL DEFAULT NOW()
ip_address VARCHAR(50) NULLABLE

-- Detail
notes TEXT NULLABLE                          -- catatan / alasan
receipt_path TEXT NULLABLE                   -- bukti yang di-upload (jika ada)

created_at TIMESTAMP
```

**Integrasi:** Setiap endpoint pembayaran otomatis insert ke `payment_audit_logs`:
```php
// Contoh: saat Purchasing verify consumer payment
PaymentAuditLog::create([
  'context' => 'consumer_payment',
  'order_id' => $order->id,
  'action' => 'verify',
  'from_status' => 'proof_uploaded',
  'to_status' => 'paid',
  'amount' => $order->grand_total,
  'performed_by' => auth()->id(),
  'notes' => $request->notes,
]);
```

---

## FIX 5: Tabel `orders` — Kolom Payment Tambahan

```sql
-- Tambahkan ke tabel orders:

payment_rejection_reason TEXT NULLABLE       -- alasan Purchasing tolak bukti
payment_retry_count SMALLINT DEFAULT 0       -- berapa kali consumer upload ulang
payment_verify_deadline_at TIMESTAMP NULLABLE -- auto: proof_uploaded_at + threshold
billing_id UUID NULLABLE REFERENCES order_billings(id) -- link ke billing header
```

---

## FIX 6: Tabel `order_field_team_payments` — Kolom Tambahan

```sql
-- Tambahkan:
attendance_status ENUM('attended','absent','partial') DEFAULT 'attended'
-- attended : hadir penuh
-- absent   : tidak hadir → upah tidak dibayar (atau potongan)
-- partial  : hadir sebagian

payment_deadline_at TIMESTAMP NULLABLE       -- auto: order.completed_at + threshold
```

---

## FIX 7: Endpoint Purchasing — Diperkaya Filter & Reporting

```
### Purchasing — Reporting (diperkaya filter)
GET    /purchasing/reports/monthly?year=2026&month=4
  -- Response: { total_consumer_payments, total_supplier_payments,
  --             total_field_team_payments, total_procurement,
  --             breakdown_by_category, top_suppliers, top_orders }

GET    /purchasing/reports/field-team?month=2026-04&order_id=X
  -- Response: per order: list tim + status bayar + total

GET    /purchasing/reports/supplier-payments?month=2026-04&supplier_id=X
  -- Response: per supplier: list transaksi + total + avg lead time

GET    /purchasing/reports/billing?month=2026-04&status=finalized
  -- Response: list billing per order + grand total

GET    /purchasing/reports/audit-trail?from=2026-04-01&to=2026-04-30&context=consumer_payment
  -- Response: list payment_audit_logs dengan filter

### Purchasing — Billing Lifecycle
GET    /purchasing/orders/{id}/billing                -- header + items
PUT    /purchasing/orders/{id}/billing/finalize        -- finalisasi
PUT    /purchasing/orders/{id}/billing/close           -- arsip/tutup
GET    /purchasing/billing/export/{orderId}            -- PDF (sudah ada)
GET    /purchasing/billing/pending-finalization        -- BARU: list billing yang masih draft

### Purchasing — Bulk Operations
POST   /purchasing/field-team/bulk-pay                -- bayar banyak sekaligus
  body: { payments: [
    { member_id: 'X', method: 'transfer', amount: 500000, receipt: file },
    { member_id: 'Y', method: 'cash', amount: 300000, receipt: file }
  ] }
```

---

## Flutter — Screen Purchasing Tambahan v1.21

```
lib/features/purchasing/screens/
  ├── billing_detail_screen.dart              -- BARU: detail tagihan per order
  │     -- Header: billing_number, status badge, grand_total
  │     -- Tabel items: kode | nama | qty kirim | qty kembali | qty tagih | harga | total
  │     -- Section: Tambahan (dari extra_approvals)
  │     -- Section: Potongan (dari retur)
  │     -- Footer: Subtotal, Tambahan, Potongan, Grand Total
  │     -- Tombol: [Finalisasi] [Export PDF] [Tutup Billing]
  │     -- Jika status=draft: item bisa di-edit inline
  │     -- Jika status=finalized+: read-only
  │
  ├── payment_audit_screen.dart               -- BARU: audit trail pembayaran
  │     -- Timeline semua perubahan status payment
  │     -- Filter: context (consumer/supplier/field_team/billing)
  │     -- Per entry: siapa, kapan, action, dari→ke, nominal, bukti
  │
  ├── supplier_account_screen.dart            -- BARU: lihat rekening supplier
  │     -- Saat bayar supplier → tampilkan bank + no rek + atas nama
  │     -- Copy to clipboard untuk transfer manual
  │
  ├── bulk_pay_screen.dart                    -- BARU: bayar tim lapangan bulk
  │     -- Checklist: centang member yang mau dibayar
  │     -- Per member: nominal, metode, upload bukti
  │     -- Total: Rp X.XXX.XXX — [Proses Semua]
  │
  └── purchasing_home.dart                    -- PERKAYA: tambah section
        -- Card 5: Billing Belum Final (draft/adjustment)
        -- Card 6: Audit Trail Hari Ini (jumlah transaksi)
```

---

## ATURAN BISNIS PURCHASING v1.21

```
1. BILLING LIFECYCLE:
   - Auto-create saat SO konfirmasi (status: draft, billing_number auto-generate)
   - Retur barang → status: adjustment (otomatis jika ada retur)
   - Purchasing finalisasi → status: finalized (items locked, tidak bisa edit)
   - Export PDF → status: exported
   - Consumer bayar + verified → status: paid
   - Semua post-order selesai → status: closed

2. PO LANGSUNG vs e-KATALOG:
   - is_direct_po=false: bidding terbuka (7 fase e-Katalog)
   - is_direct_po=true: Gudang langsung pilih supplier + harga
     → Skip fase open & evaluating
     → Status: draft → awarded → purchasing_approved → dst
   - Kedua alur pakai tabel procurement_requests (BUKAN tabel terpisah)

3. CONSUMER PAYMENT REJECTION:
   - Purchasing tolak → wajib isi rejection_reason
   - Consumer mendapat notif + alasan → tampilkan di app consumer
   - retry_count++ setiap kali tolak
   - Jika retry_count >= 3 → alarm Owner "Consumer gagal upload 3x"

4. SUPPLIER PAYMENT:
   - Saat bayar → sistem auto-lookup supplier_accounts (is_primary=true)
   - Purchasing lihat: bank, no rek, atas nama → transfer manual
   - Upload bukti transfer → supplier mendapat notif "Cek rekening"
   - Supplier konfirmasi terima → transaksi selesai

5. FIELD TEAM BULK PAYMENT:
   - Purchasing bisa bayar 1-per-1 atau bulk (centang banyak + proses semua)
   - attendance_status harus diisi sebelum bayar:
     absent → tidak bisa bayar (atau bayar Rp 0)

6. AUDIT TRAIL:
   - Setiap perubahan status pembayaran otomatis tercatat
   - Tidak bisa dihapus — untuk keperluan audit keuangan
   - Owner + HRD bisa LIHAT audit trail (read-only, v1.27)
```

---

## RINGKASAN TABEL v1.21

| Tabel Baru | Fungsi |
|-----------|--------|
| `order_billings` | Header tagihan per order + status lifecycle |
| `supplier_accounts` | Rekening bank supplier |
| `payment_audit_logs` | Audit trail semua pembayaran |

| Tabel Diperkaya | Perubahan |
|----------------|-----------|
| `procurement_requests` | + `is_direct_po` (PO langsung vs e-Katalog) |
| `supplier_transactions` | + `supplier_account_id` (link ke rekening) |
| `orders` | + `payment_rejection_reason`, `payment_retry_count`, `payment_verify_deadline_at`, `billing_id` |
| `order_field_team_payments` | + `attendance_status`, `payment_deadline_at` |
| `order_billing_items` | + `billing_id` FK ke header |

| Endpoint Dihapus | Alasan |
|------------------|--------|
| `/purchasing/purchase-orders/*` | Redundan — pakai `procurement_requests?is_direct_po=true` |

---

---

# SANTA MARIA — PATCH v1.22
# Order Amendment: Layanan Tambahan di Tengah Prosesi

---

## LATAR BELAKANG v1.22

Order sedang `in_progress` di rumah duka. Tamu lebih banyak dari perkiraan. Keluarga minta tambahan. Ini PASTI terjadi dan harus ditangani secara sistematis.

**Yang sudah ada tapi TIDAK CUKUP:**
- `order_extra_approvals` — hanya catat biaya + tanda tangan, TIDAK trigger operasional
- Add-on saat konfirmasi — hanya bisa di STEP 2 (sebelum order berjalan)
- Tidak ada mekanisme "pesan tambahan saat acara sedang berjalan"

**Yang dibutuhkan:**
Satu request tambahan harus otomatis trigger: persetujuan biaya → deduct stok → siapkan barang → kirim → update vendor → update billing. Semuanya dalam satu flow terintegrasi.

---

## SKENARIO NYATA

```
╔════════════════════════════════════════════════════════════════════════╗
║  CONTOH KASUS                                                          ║
╠════════════════════════════════════════════════════════════════════════╣
║                                                                        ║
║  Order SM-20260414-0001 sedang berjalan di Rumah Duka Bethesda.        ║
║  Prosesi hari ke-2 dari 3 hari.                                        ║
║                                                                        ║
║  Keluarga menghubungi SO Budi:                                         ║
║  "Mas, tamu hari ini lebih banyak. Tolong tambah:                      ║
║   - 5 karangan bunga salib                                             ║
║   - Catering 50 porsi                                                  ║
║   - 1 tenda tambahan                                                   ║
║   - Upgrade sound system ke yang lebih besar"                          ║
║                                                                        ║
║  ATAU keluarga langsung dari app Consumer:                             ║
║  "Request tambahan → pilih item → submit"                              ║
║                                                                        ║
╠════════════════════════════════════════════════════════════════════════╣
║  YANG HARUS TERJADI:                                                    ║
║                                                                        ║
║  1. Request masuk ke SO → SO review + estimasi biaya                   ║
║  2. Keluarga setuju + tanda tangan digital                             ║
║  3. Gudang: stok bunga -5, tenda -1, swap sound                       ║
║  4. Driver: trip leg baru "Gudang → Rumah Duka (barang tambahan)"     ║
║  5. Dekor: notif "5 karangan bunga baru datang, tolong pasang"         ║
║  6. Konsumsi: notif "Tambah 50 porsi catering"                        ║
║  7. Billing: auto-add item baru ke tagihan                             ║
║                                                                        ║
║  Semua ini terjadi SAAT ACARA SEDANG BERJALAN.                         ║
╚════════════════════════════════════════════════════════════════════════╝
```

---

## DATABASE — TABEL BARU v1.22

### Tabel `order_amendments` (Request Perubahan/Tambahan Order)

Orchestrator utama — menghubungkan persetujuan ↔ stok ↔ pengiriman ↔ vendor ↔ billing.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
amendment_number VARCHAR(50) UNIQUE NOT NULL  -- contoh: AMD-20260415-0001
order_id UUID REFERENCES orders(id)

-- Siapa yang request
requested_by UUID REFERENCES users(id)       -- consumer atau SO
requested_via ENUM('consumer_app','so_input','so_on_behalf') NOT NULL
-- consumer_app   : keluarga request langsung dari app
-- so_input       : SO input atas inisiatif sendiri (lihat kebutuhan di lapangan)
-- so_on_behalf   : SO input atas permintaan keluarga (via WA/telepon)

-- Status lifecycle
status ENUM(
  'requested',           -- baru masuk, menunggu SO review
  'so_reviewed',         -- SO sudah review + estimasi biaya
  'family_approved',     -- keluarga setuju + tanda tangan digital
  'preparing',           -- Gudang sedang siapkan barang
  'dispatched',          -- Driver sudah berangkat kirim barang tambahan
  'delivered',           -- Barang tiba di lokasi
  'executing',           -- Vendor sedang eksekusi (pasang bunga, masak, dll)
  'completed',           -- semua item amendment sudah selesai
  'rejected',            -- ditolak oleh SO atau keluarga
  'cancelled'            -- dibatalkan
) DEFAULT 'requested'

-- Persetujuan biaya (gabung fungsi order_extra_approvals)
total_estimated_cost DECIMAL(15,2) DEFAULT 0 -- estimasi SO
total_final_cost DECIMAL(15,2) DEFAULT 0     -- biaya aktual setelah selesai

-- Tanda tangan keluarga
pj_nama VARCHAR(255) NULLABLE                -- penanggung jawab keluarga
pj_hub_alm VARCHAR(100) NULLABLE
pj_signed_at TIMESTAMP NULLABLE
pj_signature_path TEXT NULLABLE              -- tanda tangan digital (R2)

-- SO yang handle
so_id UUID NULLABLE REFERENCES users(id)
so_reviewed_at TIMESTAMP NULLABLE
so_notes TEXT NULLABLE

-- Urgency
urgency ENUM('normal','urgent','critical') DEFAULT 'normal'
-- normal   : bisa dikirim dalam beberapa jam
-- urgent   : dibutuhkan dalam 1 jam
-- critical : dibutuhkan sekarang juga (misal: peti rusak, harus ganti)

-- Tracking
needs_delivery BOOLEAN DEFAULT FALSE         -- apakah perlu kirim barang fisik?
needs_vendor_update BOOLEAN DEFAULT FALSE    -- apakah vendor perlu notif/action?
delivery_trip_leg_id UUID NULLABLE REFERENCES order_driver_assignments(id)

-- Timestamps
requested_at TIMESTAMP NOT NULL DEFAULT NOW()
preparing_at TIMESTAMP NULLABLE
dispatched_at TIMESTAMP NULLABLE
delivered_at TIMESTAMP NULLABLE
completed_at TIMESTAMP NULLABLE

notes TEXT NULLABLE
created_at TIMESTAMP
updated_at TIMESTAMP
```

---

### Tabel `order_amendment_items` (Detail Item per Amendment)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
amendment_id UUID REFERENCES order_amendments(id) ON DELETE CASCADE
line_number SMALLINT NOT NULL

-- Jenis item
item_type ENUM(
  'add_item',            -- tambah item baru (bunga, catering, tenda)
  'upgrade_item',        -- upgrade item existing (peti → peti lebih bagus)
  'extend_duration',     -- perpanjang durasi layanan
  'add_vendor',          -- tambah vendor baru (misal: tambah musisi)
  'swap_item',           -- tukar item (sound kecil → sound besar)
  'add_quantity',        -- tambah qty item yang sudah ada (air putih +5 dos)
  'custom'               -- lain-lain
) NOT NULL

-- Detail item
description TEXT NOT NULL                    -- "Karangan Bunga Salib × 5"
category VARCHAR(100) NULLABLE              -- 'dekorasi', 'konsumsi', 'peralatan', 'layanan'

-- Link ke master (opsional — jika item ada di master)
stock_item_id UUID NULLABLE REFERENCES stock_items(id)
billing_master_id UUID NULLABLE REFERENCES billing_item_master(id)
equipment_master_id UUID NULLABLE REFERENCES equipment_master(id)

-- Kuantitas
qty DECIMAL(10,2) DEFAULT 1
unit VARCHAR(50) DEFAULT 'pcs'

-- Biaya
unit_price DECIMAL(15,2) DEFAULT 0
total_price DECIMAL(15,2) DEFAULT 0          -- qty × unit_price

-- Untuk upgrade/swap: item lama yang diganti
replaces_item_description TEXT NULLABLE      -- "Sound Kecil → Sound Besar"
price_difference DECIMAL(15,2) DEFAULT 0     -- selisih harga upgrade

-- Status per item
item_status ENUM(
  'pending',             -- menunggu approval
  'approved',            -- disetujui, menunggu disiapkan
  'preparing',           -- Gudang sedang siapkan
  'ready',               -- siap kirim
  'delivered',           -- sudah sampai di lokasi
  'installed',           -- sudah dipasang/dieksekusi vendor
  'completed'            -- selesai
) DEFAULT 'pending'

-- Dampak stok (diisi otomatis saat approved)
stock_deducted BOOLEAN DEFAULT FALSE
stock_transaction_id UUID NULLABLE REFERENCES stock_transactions(id)

-- Dampak billing (diisi otomatis saat approved)
billing_item_created BOOLEAN DEFAULT FALSE
billing_item_id UUID NULLABLE REFERENCES order_billing_items(id)

-- Vendor yang execute (jika perlu vendor action)
assigned_vendor_role VARCHAR(50) NULLABLE    -- 'dekor', 'konsumsi', dll
vendor_notified BOOLEAN DEFAULT FALSE

notes TEXT NULLABLE
created_at TIMESTAMP
updated_at TIMESTAMP
```

---

## FLOW LENGKAP: ORDER AMENDMENT

```
╔═══════════════════════════════════════════════════════════════════════╗
║  FLOW ORDER AMENDMENT — LAYANAN TAMBAHAN DI TENGAH PROSESI           ║
╚═══════════════════════════════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FASE 1 — REQUEST MASUK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Sumber A: Consumer dari app
  → Consumer buka order aktif → tab "Tambahan" → pilih item dari katalog
  → Submit → status: 'requested'
  → SO mendapat ALARM: "Keluarga request tambahan di Order [X]!"

Sumber B: SO input sendiri (melihat kebutuhan di lapangan)
  → SO buka order → "Tambah Layanan" → input item + estimasi biaya
  → requested_via: 'so_input'
  → Langsung ke FASE 2 (SO sekaligus review)

Sumber C: SO input atas nama keluarga (via WA/telepon)
  → SO buka order → "Tambah Layanan (atas permintaan keluarga)"
  → requested_via: 'so_on_behalf'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FASE 2 — SO REVIEW & ESTIMASI BIAYA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SO buka amendment request → lihat item yang diminta

Per item, SO:
  ✓ Verifikasi ketersediaan (sistem cek stok real-time)
  ✓ Set harga per item (dari master atau custom)
  ✓ Tandai apakah perlu kirim barang (needs_delivery)
  ✓ Tandai apakah vendor perlu action (needs_vendor_update)
  ✓ Set urgency: normal / urgent / critical

SO tekan "Kirim Estimasi ke Keluarga"
  → status: 'requested' → 'so_reviewed'
  → Consumer mendapat ALARM: "Estimasi biaya tambahan Rp X. Mohon persetujuan."
  → Tampil di app consumer: detail item + harga + tombol approve

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FASE 3 — KELUARGA APPROVE + TANDA TANGAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Consumer buka app → lihat detail amendment:
  "Tambahan 5 karangan bunga: Rp 750.000
   Catering 50 porsi: Rp 1.500.000
   Tenda 1 unit: Rp 500.000
   TOTAL TAMBAHAN: Rp 2.750.000"

Consumer pilih:
  [SETUJU] → tanda tangan digital di layar → signed!
    → status: 'so_reviewed' → 'family_approved'
    → TRIGGER OTOMATIS: FASE 4, 5, 6 berjalan PARALEL

  [TOLAK] → input alasan → status: 'rejected'
    → SO mendapat notif "Keluarga menolak tambahan"

ALTERNATIF — SO di lapangan:
  Jika keluarga di depan SO → SO bisa capture tanda tangan langsung di tablet
  → Tidak perlu menunggu consumer approve dari app

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FASE 4 — GUDANG: SIAPKAN BARANG (jika needs_delivery)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Saat family_approved → sistem otomatis:

  PER ITEM yang punya stock_item_id:
    → Auto-deduct stok (stock_transaction type='out')
    → Jika stok kurang → flag + alarm Purchasing
    → item_status: 'pending' → 'approved' → 'preparing'

  Gudang mendapat ALARM:
    "⚡ Amendment AMD-20260415-0001 disetujui!
     Order: SM-20260414-0001 (sedang berlangsung)
     Urgency: URGENT
     Item: 5× Karangan Bunga, 1× Tenda, 1× Sound Besar
     Segera siapkan!"

  Gudang buka app → checklist item amendment → siapkan fisik
  Semua siap → Gudang tekan "Barang Siap"
    → item_status: 'preparing' → 'ready'
    → amendment status: 'preparing' → siap dispatch

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FASE 5 — DRIVER: KIRIM BARANG TAMBAHAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Saat Gudang "Barang Siap" → sistem:

  Opsi A: Driver order yang sama masih di lokasi
    → Notif Driver: "Ada barang tambahan. Ambil di Gudang saat kembali"
    → ATAU: assign driver lain yang available

  Opsi B: Perlu kirim sekarang (urgency: urgent/critical)
    → Sistem auto-assign driver available terdekat
    → Buat trip leg BARU di order_driver_assignments:
        { leg_code: 'KIRIM_AMENDMENT', leg_sequence: next,
          origin: 'Gudang SM', destination: 'Rumah Duka Bethesda',
          cargo: 'Amendment AMD-20260415-0001: 5 bunga, 1 tenda, 1 sound',
          triggers_gate: 'amendment_delivered' }
    → Driver mendapat ALARM: "Kirim barang tambahan ke Order [X]!"

  Driver eksekusi:
    → Ambil barang di Gudang → berangkat → tiba di lokasi
    → Upload bukti foto barang tiba
    → item_status: 'ready' → 'delivered'
    → amendment status: 'dispatched' → 'delivered'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FASE 6 — VENDOR: EKSEKUSI TAMBAHAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Saat barang delivered (atau saat family_approved untuk item jasa) → notif vendor:

  [ DEKOR — jika ada item kategori 'dekorasi' ]
  → ALARM: "Tambahan Order SM-20260414-0001:
            5 karangan bunga salib sudah tiba. Segera pasang!"
  → Dekor eksekusi → item_status: 'delivered' → 'installed'

  [ KONSUMSI — jika ada item kategori 'konsumsi' ]
  → ALARM: "Tambahan catering 50 porsi untuk Order SM-20260414-0001.
            Siapkan dan kirim ke Rumah Duka Bethesda."
  → Konsumsi eksekusi (bisa kirim sendiri, tidak perlu driver SM)
  → item_status: 'approved' → 'completed'

  [ SWAP/UPGRADE — jika ada item swap ]
  → Gudang siapkan item baru + Driver kirim
  → Di lokasi: tukar item lama ↔ baru
  → Item lama dikembalikan ke Gudang (stok restore)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FASE 7 — BILLING AUTO-UPDATE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Saat amendment approved → sistem otomatis:

  PER ITEM:
    → Jika ada billing_master_id:
        Buat order_billing_items baru (source: 'amendment')
        → billing_item.amendment_id = amendment.id
    → Jika tidak ada master (custom item):
        Buat order_billing_items (source: 'manual')

  order_billings (header):
    → total_tambahan di-recalculate
    → grand_total di-recalculate
    → status kembali ke 'draft' jika sudah 'finalized' (re-open)

  UNTUK UPGRADE/SWAP:
    → Item lama: billed_qty = 0, kembali = full price (potongan)
    → Item baru: billed_qty = qty, total = harga baru
    → Selisih = harga baru - harga lama → yang ditagihkan ke keluarga

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FASE 8 — SEMUA SELESAI
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Saat semua item_status = 'completed' atau 'installed':
  → amendment status: → 'completed'
  → amendment.total_final_cost dihitung dari aktual
  → SO mendapat notif: "Amendment AMD-20260415-0001 selesai"
  → Consumer mendapat notif: "Layanan tambahan sudah selesai"
```

---

## INTEGRASI KE ORDER — STEP BARU: AMENDMENT BISA KAPAN SAJA

```
Amendment bisa di-request kapan saja selama order.status IN
('confirmed', 'in_progress') — yaitu SETELAH SO konfirmasi
dan SEBELUM order auto-complete.

Tidak perlu step khusus — amendment berjalan PARALEL dengan
flow utama (STEP 3-7). Amendment tidak mengganggu flow utama.

┌────────────────────────────────────────────────────────┐
│  FLOW UTAMA (STEP 1-9)                                 │
│  ════════════════════                                   │
│  1. Order masuk                                         │
│  2. SO konfirmasi ◄───── mulai bisa amendment           │
│  3. Distribusi paralel                                  │
│  4. Gudang siap                                         │
│  5. Driver Tugas 1  ←── amendment bisa trigger          │
│  6. Driver Tugas 2      trip leg tambahan di sini       │
│  7. Auto-complete  ◄───── batas akhir amendment         │
│  8. Payment                                             │
│  9. Post-order                                          │
│                                                         │
│  AMENDMENT (PARALEL, KAPAN SAJA DI STEP 2-7)           │
│  ═════════════════════════════════════════               │
│  A1. Request masuk                                      │
│  A2. SO review + estimasi                               │
│  A3. Keluarga approve + tanda tangan                    │
│  A4. Gudang siapkan (paralel)                           │
│  A5. Driver kirim (trip leg baru)                       │
│  A6. Vendor eksekusi                                    │
│  A7. Billing auto-update                                │
│  A8. Selesai                                            │
│                                                         │
│  Bisa terjadi BERKALI-KALI per order.                   │
│  Setiap amendment punya lifecycle sendiri.               │
└────────────────────────────────────────────────────────┘
```

---

## API — ENDPOINT AMENDMENT v1.22

```
### Consumer — Request Tambahan
POST   /consumer/orders/{id}/amendments              -- request tambahan
  body: { items: [
    { description: "Karangan Bunga Salib", qty: 5, category: "dekorasi" },
    { description: "Catering 50 porsi", qty: 1, category: "konsumsi" }
  ] }
GET    /consumer/orders/{id}/amendments              -- list amendment order ini
GET    /consumer/orders/{id}/amendments/{amdId}      -- detail + estimasi biaya
PUT    /consumer/orders/{id}/amendments/{amdId}/approve  -- setuju + tanda tangan
  body: { pj_nama, pj_hub_alm, signature: file }
PUT    /consumer/orders/{id}/amendments/{amdId}/reject   -- tolak + alasan

### SO — Review & Manage Amendment
GET    /so/orders/{id}/amendments                    -- list semua amendment order ini
POST   /so/orders/{id}/amendments                    -- SO buat amendment
  body: { requested_via: 'so_input'|'so_on_behalf', urgency: 'normal'|'urgent'|'critical',
          items: [
            { item_type: 'add_item', description: '...', qty: 5,
              stock_item_id: 'X', billing_master_id: 'Y',
              unit_price: 150000, category: 'dekorasi' },
            { item_type: 'upgrade_item', description: 'Upgrade Sound',
              replaces_item_description: 'Sound Kecil → Sound Besar',
              price_difference: 200000 },
            { item_type: 'add_vendor', description: 'Tambah musisi 2 orang',
              assigned_vendor_role: null, unit_price: 500000 }
          ] }
PUT    /so/orders/{id}/amendments/{amdId}/review     -- SO review + set harga
PUT    /so/orders/{id}/amendments/{amdId}/capture-signature -- SO capture tanda tangan keluarga di tempat

### Gudang — Siapkan Barang Amendment
GET    /gudang/amendments/pending                    -- list amendment yang perlu disiapkan
GET    /gudang/amendments/{amdId}/items              -- detail item untuk disiapkan
PUT    /gudang/amendments/{amdId}/items/{itemId}/ready -- item siap
PUT    /gudang/amendments/{amdId}/all-ready          -- semua siap → trigger dispatch

### Driver — Kirim Barang Amendment
-- Menggunakan trip leg yang sudah ada:
-- Sistem auto-create order_driver_assignments leg baru saat Gudang "all-ready"
-- Driver eksekusi via endpoint trip leg standar (PUT /driver/trip-legs/{id}/depart, /arrive, /complete)
```

---

## FLUTTER — SCREEN AMENDMENT v1.22

```
lib/features/
  ├── consumer/screens/
  │   └── amendment_request_screen.dart        -- BARU
  │         -- List item yang bisa ditambahkan (dari katalog/master)
  │         -- Per item: nama, qty, estimasi harga
  │         -- Tombol "Request Tambahan" → submit ke SO
  │         -- Tracking: status amendment (requested → completed)
  │         -- Approval screen: detail biaya + area tanda tangan digital
  │
  ├── service_officer/screens/
  │   └── amendment_manage_screen.dart          -- BARU
  │         -- Tab "Request Masuk": dari consumer, perlu review
  │         -- Tab "Buat Baru": SO input amendment (on-behalf / inisiatif)
  │         -- Per amendment:
  │         │   Header: order, urgency badge, status
  │         │   Items: list + edit harga + cek stok real-time
  │         │   Tombol: [Kirim Estimasi] [Capture Tanda Tangan]
  │         -- Progress timeline: request → review → approve → prepare → deliver → done
  │
  ├── gudang/screens/
  │   └── amendment_prepare_screen.dart         -- BARU
  │         -- List amendment yang butuh persiapan
  │         -- Badge urgency: 🔴 CRITICAL | 🟡 URGENT | 🔵 NORMAL
  │         -- Per item: checklist siapkan + centang ready
  │         -- Tombol "Semua Siap → Kirim" → trigger driver
  │
  └── shared/widgets/
      └── amendment_timeline_widget.dart        -- BARU
            -- Reusable widget: timeline 8 fase amendment
            -- Dipakai di consumer, SO, gudang, owner dashboard
```

---

## TABEL ALARM AMENDMENT v1.22

| Momen | Consumer | SO | Gudang | Driver | Dekor | Konsumsi | Purchasing | Owner |
|-------|----------|----|----|----|----|----|----|-----|
| Consumer request amendment | — | ALARM | — | — | — | — | — | — |
| SO kirim estimasi ke keluarga | ALARM (approve!) | — | — | — | — | — | — | — |
| Keluarga approve | — | HIGH | ALARM (siapkan!) | — | — | — | HIGH (biaya baru) | HIGH |
| Keluarga tolak | — | HIGH | — | — | — | — | — | — |
| Gudang siap | — | — | — | ALARM (kirim!) | — | — | — | — |
| Barang tiba di lokasi | HIGH | — | — | — | ALARM (pasang!) | ALARM (siapkan!) | — | — |
| Amendment selesai | HIGH | HIGH | — | — | — | — | — | NORMAL |
| Stok kurang untuk amendment | — | HIGH | ALARM | — | — | — | ALARM (PO!) | HIGH |
| Amendment CRITICAL masuk | — | ALARM | ALARM | — | — | — | — | ALARM |

---

## ATURAN BISNIS AMENDMENT v1.22

```
1. Amendment hanya bisa dibuat saat order.status IN ('confirmed', 'in_progress')
   → Tidak bisa setelah 'completed' (gunakan order baru)
   → Tidak bisa saat 'pending' (order belum dikonfirmasi)

2. Bisa BANYAK amendment per order — setiap amendment punya lifecycle sendiri
   → Amendment ke-2 bisa masuk saat amendment ke-1 masih in-progress

3. Urgency menentukan kecepatan response:
   → normal  : Gudang siapkan dalam jam kerja, kirim saat ada driver available
   → urgent  : Gudang siapkan dalam 1 jam, assign driver segera
   → critical: Gudang + Driver langsung dapat ALARM, response maks 30 menit
   → Threshold configurable di system_thresholds

4. Persetujuan biaya WAJIB sebelum eksekusi:
   → Consumer harus tanda tangan digital (via app atau SO capture di tempat)
   → KECUALI jika SO yang inisiasi DAN total < threshold auto-approve
   → Threshold: amendment_auto_approve_max (default: Rp 500.000)

5. Stok dicek REAL-TIME saat SO review:
   → Jika stok cukup → deduct saat approved
   → Jika stok kurang → auto-create procurement_request (priority: sesuai urgency)
   → Amendment tetap bisa approved — barang dikirim setelah stok ada

6. Billing otomatis ter-update:
   → Item amendment masuk ke order_billing_items (source: 'amendment')
   → Jika billing sudah 'finalized' → auto re-open ke 'draft'
   → Purchasing mendapat notif "Billing order [X] berubah karena amendment"

7. Upgrade/Swap:
   → Item lama: di-credit (potongan di billing)
   → Item baru: di-debit (tambahan di billing)
   → Selisih = yang ditagihkan ke keluarga
   → Item lama dikembalikan ke Gudang (stok restore)

8. Vendor assignment:
   → Jika item kategori 'dekorasi' → notif Dekor
   → Jika item kategori 'konsumsi' → notif Konsumsi
   → Jika item 'add_vendor' → SO harus assign vendor + create field_attendance
   → Vendor bisa jadi vendor yang sudah ada di order ATAU vendor baru

9. Trip leg amendment:
   → Sistem auto-buat trip leg baru: leg_code='KIRIM_AMENDMENT'
   → Masuk ke timeline driver yang sama (jika masih di lokasi)
   → Atau assign driver lain jika driver utama sedang tugas
```

---

## SYSTEM THRESHOLDS — TAMBAHAN v1.22

```
amendment_auto_approve_max = 500000          -- Rp, di bawah ini SO bisa approve sendiri
amendment_urgent_prepare_minutes = 60        -- maks waktu Gudang siapkan untuk urgent
amendment_critical_prepare_minutes = 30      -- maks waktu untuk critical
amendment_max_per_order = 10                 -- maks amendment per order (safety limit)
```

---

## CONTOH SIMULASI AMENDMENT

```
════════════════════════════════════════════════════════════════
14 April 2026, 14:00 — Order SM-20260414-0001 sedang berjalan
Prosesi di Rumah Duka Bethesda, hari ke-1 dari 3 hari
════════════════════════════════════════════════════════════════

14:00  Keluarga WA ke SO Budi: "Mas, tolong tambah 5 karangan bunga
       dan catering 50 porsi. Tamu lebih banyak dari perkiraan."

14:02  Budi SO buka app → Order SM-20260414-0001 → "Tambah Layanan"
       → POST /so/orders/{id}/amendments
         requested_via: 'so_on_behalf', urgency: 'urgent'
         items:
           [1] add_item: "Karangan Bunga Salib" × 5, Rp 150.000/pcs = Rp 750.000
               stock_item_id: [bunga_salib], billing_master_id: [BNG_SLB]
               category: 'dekorasi', assigned_vendor_role: 'dekor'
           [2] add_item: "Catering Tambahan 50 porsi" × 1, Rp 1.500.000
               category: 'konsumsi', assigned_vendor_role: 'konsumsi'
         total_estimated_cost: Rp 2.250.000

14:03  Budi kirim estimasi → Consumer ALARM "Estimasi tambahan Rp 2.250.000"
       → amendment status: 'so_reviewed'

14:05  Keluarga buka app → lihat detail → "SETUJU" → tanda tangan di layar
       → amendment status: 'family_approved'
       → TRIGGER PARALEL:

       [ GUDANG ]
       → ALARM: "⚡ URGENT — Amendment AMD-20260415-0001"
       → Auto-deduct stok: bunga salib -5
       → Gerry buka app → centang: bunga siap ✓
       → Tekan "Semua Siap" pada 14:15

       [ BILLING ]
       → Auto-create order_billing_items:
         BNG_SLB: qty=5, unit_price=150.000, total=750.000, source='amendment'
         CATERING_TAMBAHAN: qty=1, total=1.500.000, source='amendment'
       → order_billings.grand_total += 2.250.000

       [ PURCHASING ]
       → HIGH: "Biaya tambahan Rp 2.250.000 di order SM-20260414-0001"

14:15  Gudang siap → Sistem assign driver:
       → Anto (driver order ini) sedang di Rumah Duka
       → Assign driver lain: Dedi Driver (available)
       → Trip leg baru: Gudang SM → Rumah Duka Bethesda
         cargo: "5 karangan bunga salib"
       → Dedi ALARM: "Kirim barang tambahan ke SM-20260414-0001!"

14:20  Dedi berangkat dari Gudang

14:40  Dedi tiba di Rumah Duka → upload foto bukti
       → item [1] status: 'delivered'
       → Dekor ALARM: "5 karangan bunga baru tiba! Segera pasang!"
       → Consumer HIGH: "Barang tambahan sudah tiba"

14:45  Dekor pasang 5 karangan bunga
       → item [1] status: 'installed' → 'completed'

14:30  (Paralel) Konsumsi terima notif → siapkan 50 porsi tambahan
       → Konsumsi kirim sendiri ke Rumah Duka (bukan via driver SM)
       → item [2] status: 'approved' → 'completed'

15:00  Semua item completed
       → amendment status: 'completed'
       → SO: HIGH "Amendment selesai"
       → Consumer: HIGH "Semua layanan tambahan sudah selesai"
```

---

---

# SANTA MARIA — PATCH v1.23
# Audit Fix: Security, Viewer, Super Admin, Consumer + Konsolidasi Alarm

---

## TEMUAN AUDIT ROLE

| Role | Status Sebelum | Masalah |
|------|---------------|---------|
| **Security** | 🔴 KOSONG | Hanya 1 baris definisi, TIDAK ada screen/endpoint/tabel |
| **Viewer** | 🟡 VAGUE | "Read-only" tapi tidak jelas read APA |
| **Super Admin** | 🟡 PARTIAL | Screen tidak terstruktur |
| **Consumer** | 🟡 PARTIAL | Screen order list/detail tidak eksplisit |
| **Pemuka Agama** | 🟡 MINIMAL | Screen kurang detail dibanding vendor lain |
| **HRD** | 🟡 GAP | KPI config screen belum di-list |
| **Alarm Tables** | 🟡 TERSEBAR | 5 tabel alarm terpisah (v1.17, v1.14, v1.16, v1.20, v1.22) |

---

## FIX 1: SECURITY — Definisi Lengkap

### Fungsi Security Santa Maria

```
Security bertugas:
1. MONITORING KEHADIRAN — siapa yang masuk/keluar area Gudang & Kantor
2. LOG KEJADIAN — catat insiden (kerusakan, kehilangan, tamu mencurigakan)
3. SERAH TERIMA KUNCI — kunci kendaraan, kunci gudang, kunci kantor
4. PATROLI — checklist patroli berkala (pos, gudang, parkiran)
5. VISITOR LOG — catat tamu yang datang ke kantor/gudang

Security BUKAN penjaga di rumah duka (itu tim lapangan dari luar).
Security menjaga aset internal Santa Maria: kantor, gudang, kendaraan.
```

### Tabel `security_incident_logs` (Log Kejadian / Insiden)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
log_number VARCHAR(50) UNIQUE NOT NULL       -- contoh: SEC-20260414-001
reported_by UUID REFERENCES users(id)        -- security yang lapor

incident_type ENUM(
  'visitor',               -- tamu datang
  'property_damage',       -- kerusakan properti/aset
  'theft_attempt',         -- percobaan pencurian
  'unauthorized_access',   -- akses tidak sah
  'vehicle_incident',      -- insiden kendaraan (lecet, senggol parkir)
  'fire_hazard',           -- bahaya kebakaran
  'other'                  -- lain-lain
) NOT NULL

severity ENUM('info','warning','critical') DEFAULT 'info'
title VARCHAR(255) NOT NULL
description TEXT NOT NULL
location VARCHAR(255) NULLABLE               -- lokasi: 'Gudang', 'Parkiran', 'Kantor Lantai 2'
photo_paths JSONB DEFAULT '[]'               -- foto bukti (R2)

-- Tamu (jika incident_type = 'visitor')
visitor_name VARCHAR(255) NULLABLE
visitor_phone VARCHAR(30) NULLABLE
visitor_purpose TEXT NULLABLE
visitor_meet_with VARCHAR(255) NULLABLE      -- bertemu siapa

-- Status
status ENUM('reported','acknowledged','resolved','escalated') DEFAULT 'reported'
acknowledged_by UUID NULLABLE REFERENCES users(id)  -- HRD/Owner
resolved_by UUID NULLABLE REFERENCES users(id)
resolution_notes TEXT NULLABLE

created_at TIMESTAMP
updated_at TIMESTAMP
```

### Tabel `security_key_handovers` (Serah Terima Kunci)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
key_type ENUM('vehicle','gudang','kantor','ruangan','other') NOT NULL
key_label VARCHAR(255) NOT NULL              -- contoh: 'Kunci Mobil H-1234-AB', 'Kunci Gudang Utama'
vehicle_id UUID NULLABLE REFERENCES vehicles(id)

-- Serah terima
handed_to UUID REFERENCES users(id)          -- siapa yang ambil kunci
handed_by UUID REFERENCES users(id)          -- security yang serahkan
handed_at TIMESTAMP NOT NULL

-- Pengembalian
returned_at TIMESTAMP NULLABLE
returned_to UUID NULLABLE REFERENCES users(id)  -- security yang terima kembali

-- Status
status ENUM('out','returned','overdue') DEFAULT 'out'
expected_return_at TIMESTAMP NULLABLE        -- kapan harusnya dikembalikan
notes TEXT NULLABLE
created_at TIMESTAMP
updated_at TIMESTAMP
```

### Tabel `security_patrol_master` (Master Checklist Patroli)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
checkpoint_code VARCHAR(50) UNIQUE NOT NULL   -- contoh: 'POS_DEPAN', 'GUDANG_BELAKANG'
checkpoint_name VARCHAR(255) NOT NULL
location_description TEXT NULLABLE
sort_order INTEGER DEFAULT 0
is_active BOOLEAN DEFAULT TRUE
created_at TIMESTAMP
updated_at TIMESTAMP
```

### Tabel `security_patrols` (Log Patroli)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
patrol_by UUID REFERENCES users(id)          -- security yang patroli
patrol_date DATE NOT NULL
shift VARCHAR(50) NOT NULL                   -- shift security (dari work_shifts)

-- Waktu
started_at TIMESTAMP NOT NULL
completed_at TIMESTAMP NULLABLE

-- Detail checkpoint
checkpoints JSONB NOT NULL
-- format: [
--   { "checkpoint_id": "X", "checked_at": "2026-04-14T20:15:00", "status": "ok",
--     "notes": null, "photo": null },
--   { "checkpoint_id": "Y", "checked_at": "2026-04-14T20:25:00", "status": "issue",
--     "notes": "Lampu gudang belakang mati", "photo": "path/to/photo.jpg" }
-- ]

all_clear BOOLEAN DEFAULT TRUE               -- semua checkpoint OK?
notes TEXT NULLABLE
created_at TIMESTAMP
updated_at TIMESTAMP
```

### API — Endpoint Security

```
### Security — Insiden
POST   /security/incidents                        -- lapor insiden/catat tamu
GET    /security/incidents                        -- list insiden (filter: type, severity, date)
GET    /security/incidents/{id}
PUT    /security/incidents/{id}                   -- update status/resolusi

### Security — Kunci
POST   /security/keys/handover                    -- serahkan kunci ke seseorang
PUT    /security/keys/{id}/return                 -- kunci dikembalikan
GET    /security/keys                             -- list semua kunci yang sedang di luar
GET    /security/keys/overdue                     -- kunci yang belum kembali melebihi waktu

### Security — Patroli
POST   /security/patrols                          -- mulai patroli
PUT    /security/patrols/{id}/checkpoint           -- centang checkpoint
PUT    /security/patrols/{id}/complete             -- selesai patroli
GET    /security/patrols                          -- riwayat patroli
GET    /security/patrols/schedule                 -- jadwal patroli hari ini

### Security — Dashboard
GET    /security/dashboard                        -- ringkasan: kunci di luar, insiden hari ini, jadwal patroli
```

### Flutter — Screen Security

```
lib/features/security/screens/
  ├── security_home.dart                       -- Dashboard utama
  │     -- Card 1: Kunci Keluar (X kunci belum kembali)
  │     -- Card 2: Insiden Hari Ini (X laporan)
  │     -- Card 3: Patroli (Berikutnya jam XX:XX / Sudah selesai ✓)
  │     -- Card 4: Clock-in/out status
  │
  ├── incident_form_screen.dart                -- Lapor insiden / catat tamu
  │     -- Type selector (visitor/damage/theft/dll)
  │     -- Form: judul, deskripsi, lokasi, severity
  │     -- Jika visitor: nama, telepon, tujuan, bertemu siapa
  │     -- Foto: multi-foto bukti
  │
  ├── incident_list_screen.dart                -- Riwayat insiden
  │
  ├── key_handover_screen.dart                 -- Serah terima kunci
  │     -- List kunci: yang keluar + yang tersedia
  │     -- Tombol: [Serahkan Kunci] → pilih kunci + pilih penerima
  │     -- Tombol: [Terima Kembali] → scan / pilih kunci
  │     -- Badge: overdue (merah)
  │
  ├── patrol_screen.dart                       -- Eksekusi patroli
  │     -- List checkpoint dengan urutan
  │     -- Per checkpoint: [Centang OK] atau [Laporkan Masalah + foto]
  │     -- Progress: X/Y checkpoint selesai
  │     -- Timer: mulai → selesai
  │
  └── patrol_history_screen.dart               -- Riwayat patroli
```

### KPI Security

```
SEC_ATTENDANCE_RATE    | Tingkat Kehadiran Harian
  data_source: daily_attendances
  target: ≥ 98% | bobot: 25%

SEC_PATROL_COMPLETION  | Kelengkapan Patroli
  data_source: security_patrols
  calculation: % patroli selesai (all checkpoints) vs jadwal
  target: 100% | bobot: 25%

SEC_INCIDENT_RESPONSE  | Kecepatan Lapor Insiden
  data_source: security_incident_logs
  calculation: AVG menit dari insiden terjadi → reported
  target: ≤ 15 menit | bobot: 20%

SEC_KEY_COMPLIANCE     | Ketepatan Serah Terima Kunci
  data_source: security_key_handovers
  calculation: % kunci kembali tepat waktu vs total handover
  target: ≥ 95% | bobot: 15%

SEC_VIOLATION_COUNT    | Jumlah Pelanggaran
  data_source: hrd_violations
  target: 0 | bobot: 15%
```

### Integrasi Security ke Sistem

```
KUNCI KENDARAAN ↔ DRIVER:
  Driver mau ambil mobil → Security serahkan kunci → key_handover
  Driver selesai → kembalikan kunci ke Security
  Jika overdue → alarm Security + HRD

INSIDEN ↔ HRD:
  Security lapor insiden severity=critical → alarm HRD + Owner
  HRD bisa acknowledge + resolve dari dashboard HRD

PATROLI ↔ OWNER:
  Owner bisa lihat laporan patroli (semua clear / ada masalah)
  Patroli tidak selesai → alarm HRD

VISITOR ↔ ORDER:
  Tamu yang datang terkait order → Security bisa link ke order_id
  SO/Owner bisa lihat log tamu per order
```

---

## FIX 2: VIEWER — Definisi Akses

```
Viewer = role read-only untuk stakeholder yang perlu monitor tanpa aksi.
Contoh: investor, dewan pengawas, konsultan, auditor.

VIEWER BISA LIHAT (read-only):
  ✓ Dashboard ringkasan: total order aktif, order selesai, pendapatan bulan ini
  ✓ List order (semua status) + detail order (tanpa data sensitif)
  ✓ Laporan bulanan: pendapatan, pengeluaran, jumlah order
  ✓ KPI summary (tanpa detail per karyawan)
  ✓ Status armada (jumlah available/in_use)
  ✓ Grafik trend: order per bulan, pendapatan per bulan

VIEWER TIDAK BISA:
  ✗ Tidak bisa lihat data karyawan individual (nama, gaji, KPI detail)
  ✗ Tidak bisa lihat pelanggaran HRD
  ✗ Tidak bisa lihat supplier detail (harga, rekening)
  ✗ Tidak bisa aksi apapun (create, update, delete)
  ✗ Tidak bisa lihat foto bukti pembayaran consumer
  ✗ Tidak bisa lihat data consumer (alamat, telepon)
```

### API — Endpoint Viewer

```
GET    /viewer/dashboard                         -- ringkasan aggregat
  Response: { active_orders, completed_this_month, revenue_this_month,
              total_vehicles, vehicles_available, avg_order_duration }

GET    /viewer/orders                            -- list order (sanitized, tanpa data pribadi)
GET    /viewer/orders/{id}                       -- detail order (tanpa consumer contact)
GET    /viewer/reports/monthly?year=2026&month=4 -- laporan bulanan aggregat
GET    /viewer/reports/trend                     -- grafik trend 12 bulan terakhir
GET    /viewer/kpi/summary                       -- distribusi grade A/B/C/D/E (tanpa nama)
```

### Flutter — Screen Viewer

```
lib/features/viewer/screens/
  ├── viewer_dashboard.dart                    -- Dashboard read-only
  │     -- KPI angka besar: Total Order | Revenue | Avg Duration
  │     -- Grafik: Order per bulan (bar chart)
  │     -- Grafik: Revenue per bulan (line chart)
  │     -- Status armada: pie chart (available/in_use/maintenance)
  │
  ├── viewer_order_list_screen.dart            -- List order (sanitized)
  │     -- Tanpa nama consumer, tanpa alamat detail
  │     -- Hanya: nomor order, paket, tanggal, status, total tagihan
  │
  └── viewer_report_screen.dart                -- Laporan bulanan
        -- Tabel: bulan | jumlah order | pendapatan | pengeluaran | margin
        -- Export: tidak bisa (read-only di app saja)
```

---

## FIX 3: SUPER ADMIN — Screen Structure

```
lib/features/admin/screens/
  ├── admin_dashboard.dart                     -- Overview sistem
  │     -- User count per role
  │     -- System health: queue, scheduler, storage usage
  │     -- Recent logins
  │
  ├── user_management_screen.dart              -- CRUD user semua role
  │     -- List users + filter role + search
  │     -- Create: nama, email, password, role, so_channel (jika SO)
  │     -- Edit: ubah role, reset password, aktif/nonaktif
  │     -- Tidak bisa hapus (soft delete via is_active)
  │
  ├── master_data_screen.dart                  -- Hub ke semua master data
  │     -- ⛔ SUPER ADMIN ONLY:
  │     -- [Paket Layanan] [Template Rute per Paket]
  │     --
  │     -- SUPER ADMIN + OWNER:
  │     -- [Item Stok] [Item Billing] [Peralatan]
  │     -- [Item Dekorasi] [Item Konsumabel] [Tahap Peti] [Kriteria QC]
  │     -- [Dokumen Akta] [Leg Perjalanan] [Shift Kerja] [Lokasi Presensi]
  │     -- [Metrik KPI] [Kategori Pengadaan] [Checklist Inspeksi]
  │     -- [Kendaraan] [Checkpoint Patroli] [Mock App Blacklist]
  │     -- [Jenis Vendor] [Template WA] [Syarat & Ketentuan] [Label Status]
  │     --
  │     -- Catatan: Owner TIDAK melihat [Paket Layanan] dan [Template Rute]
  │     -- Backend enforce: role check di middleware untuk /admin/packages
  │
  ├── system_threshold_screen.dart             -- Kelola semua threshold
  │     -- Group by kategori: Order, Stok, Payment, Attendance, KPI, Vehicle, dll
  │     -- Per threshold: key, value, unit, deskripsi
  │     -- Edit inline
  │
  └── system_log_screen.dart                   -- Audit log sistem
        -- Login history, API errors, scheduler runs
```

---

## FIX 4: CONSUMER — Screen Eksplisit

```
lib/features/consumer/screens/
  ├── consumer_home.dart                       -- Dashboard
  │     -- Order aktif (jika ada): card dengan status + progress
  │     -- Tombol: [Pesan Layanan Baru]
  │     -- Riwayat order
  │
  ├── order_form_screen.dart                   -- Form pesan layanan
  │     -- Step 1: Data almarhum (nama, tanggal lahir/meninggal, agama)
  │     -- Step 2: Data keluarga PJ (nama, alamat, telepon, hubungan)
  │     -- Step 3: Pilih paket (list paket + harga)
  │     -- Step 4: Pilih add-on (opsional)
  │     -- Step 5: Alamat rumah duka / lokasi
  │     -- Step 6: Review + submit
  │     -- ATAU: chatbot AI (voice/text) → auto-fill form
  │
  ├── order_list_screen.dart                   -- Riwayat semua order
  │
  ├── order_detail_screen.dart                 -- Detail order + tracking
  │     -- Status timeline: pending → confirmed → in_progress → completed → paid
  │     -- Info paket + add-on
  │     -- Driver tracking (real-time map jika in_progress)
  │     -- Bukti lapangan (foto dari driver, dekor, konsumsi)
  │
  ├── order_tracking_screen.dart               -- Real-time tracking
  │     -- Peta: posisi driver (jika sedang antar)
  │     -- Status per vendor: hadir/belum
  │
  ├── payment_screen.dart                      -- Upload bukti bayar
  │     -- Total tagihan + breakdown
  │     -- Pilih metode: Cash / Transfer
  │     -- Upload foto bukti → status: proof_uploaded
  │     -- Jika ditolak: tampilkan alasan + form re-upload
  │
  ├── amendment_request_screen.dart            -- Request tambahan (v1.22)
  │     -- List item yang bisa ditambahkan
  │     -- Submit → tracking status amendment
  │     -- Approval: detail biaya + tanda tangan digital
  │
  └── consumer_profile_screen.dart             -- Profil
        -- Nama, nomor HP, alamat
        -- Riwayat order
```

---

## FIX 5: KONSOLIDASI ALARM — MASTER TABLE TUNGGAL

Semua alarm dari v1.17 unified + v1.14 + v1.16 + v1.20 + v1.22 di-merge menjadi satu referensi.

### Tabel `alarm_config_master` (Konfigurasi Alarm Dinamis)

Tidak perlu tabel baru di database — alarm rules dikelola sebagai **konfigurasi di kode** yang mereferensi `system_thresholds`. Tapi untuk dokumentasi, semua alarm dikonsolidasi:

```
════════════════════════════════════════════════════════════════════════════
MASTER ALARM — SIAPA DAPAT APA DAN KAPAN (v1.23 FINAL)
════════════════════════════════════════════════════════════════════════════

CATATAN: ALARM = suara keras bypass DND | HIGH = notifikasi prioritas | NORMAL = notif biasa

── ORDER LIFECYCLE ──────────────────────────────────────────────────────
Order masuk (pending)         | SO: ALARM | Gudang: NORMAL(view) | Purchasing: NORMAL(view)
SO konfirmasi                 | Gudang: ALARM | Purchasing: ALARM | Konsumsi: ALARM
                              | Pemuka Agama: ALARM | Tukang Foto: ALARM | Owner: HIGH
                              | Consumer: HIGH | Dekor: ❌(standby)
Gudang siap angkut            | Driver: ALARM(assign)
Driver barang tiba (leg done) | Dekor: ALARM(gate!) | Consumer: NORMAL
                              | (hanya jika leg.triggers_gate = 'dekor_gate')
Driver jenazah tiba           | Consumer: HIGH
                              | (hanya jika leg.triggers_gate = 'consumer_notify')
Order auto-complete           | Purchasing: ALARM | Consumer: HIGH | Owner: NORMAL
Consumer upload bukti         | Purchasing: ALARM
Payment verified              | Consumer: HIGH | Owner: NORMAL

── PERALATAN & STOK ─────────────────────────────────────────────────────
Peralatan belum kembali H+1   | Gudang: ALARM | Owner: NORMAL
Stok kurang (needs_restock)    | Gudang: ALARM | Purchasing: ALARM

── PRESENSI & KEHADIRAN ─────────────────────────────────────────────────
Vendor/Foto check-in           | SO: HIGH
Vendor/Foto tidak hadir        | SO: HIGH | HRD: ALARM | Owner: HIGH
Karyawan absent (harian)       | HRD: HIGH
Mock location terdeteksi       | HRD: ALARM | Owner: HIGH
Titip absen terdeteksi         | HRD: ALARM | Owner: HIGH

── AMENDMENT ─────────────────────────────────────────────────────────────
Consumer request amendment     | SO: ALARM
SO kirim estimasi              | Consumer: ALARM
Keluarga approve amendment     | Gudang: ALARM | Purchasing: HIGH | Owner: HIGH
Keluarga tolak                 | SO: HIGH
Barang amendment tiba          | Consumer: HIGH | Dekor: ALARM(jika dekor) | Konsumsi: ALARM(jika konsumsi)
Amendment selesai              | Consumer: HIGH | SO: HIGH
Amendment CRITICAL             | SO: ALARM | Gudang: ALARM | Owner: ALARM

── PENGADAAN (e-Katalog) ────────────────────────────────────────────────
Permintaan dipublikasi         | Supplier(semua): ALARM
Deadline quote habis           | Pengaju: NORMAL | Gudang: ALARM(evaluasi)
Gudang pilih pemenang          | Pengaju: NORMAL | Purchasing: ALARM(approve!)
Purchasing approve             | Pengaju: HIGH | Gudang: ALARM(tunggu barang) | Supplier(menang): ALARM
Purchasing tolak               | Pengaju: HIGH | Gudang: ALARM(pilih ulang)
Supplier kirim barang          | Pengaju: NORMAL | Gudang: ALARM(cek resi)
Gudang terima barang           | Pengaju: NORMAL | Purchasing: ALARM(bayar!)
Purchasing bayar supplier      | Pengaju: NORMAL | Supplier: ALARM(cek rekening)
Reminder approval (4 jam)      | Purchasing: HIGH/ALARM(jika critical)
Eskalasi approval              | Owner: ALARM | HRD: HIGH
Priority auto-upgrade          | Purchasing: ALARM

── KPI ──────────────────────────────────────────────────────────────────
Skor dihitung (bulanan)        | User: HIGH | HRD: ALARM | Owner: HIGH
Skor rendah (< threshold)      | HRD: ALARM | Owner: HIGH
User naik grade                | User: HIGH
User turun grade               | User: HIGH | HRD: HIGH

── KENDARAAN ────────────────────────────────────────────────────────────
Inspeksi: ada CRITICAL          | Gudang: ALARM | HRD: HIGH | Owner: HIGH
BBM anomali (efisiensi drop)    | Gudang: ALARM | Owner: HIGH
Maintenance jadwal mendekat     | Driver: HIGH | Gudang: HIGH
Maintenance overdue             | Gudang: ALARM | HRD: HIGH | Owner: HIGH
Driver belum foto KM akhir      | Driver: HIGH

── SECURITY ─────────────────────────────────────────────────────────────
Insiden critical                | HRD: ALARM | Owner: ALARM
Kunci overdue                   | Security: HIGH | HRD: HIGH
Patroli tidak selesai           | HRD: HIGH

── HRD VIOLATION ────────────────────────────────────────────────────────
Driver overtime                 | HRD: ALARM | Owner: HIGH
SO terlambat proses             | HRD: ALARM | Owner: NORMAL
Vendor tolak berulang           | HRD: ALARM | Owner: HIGH
Purchasing terlambat verify     | HRD: ALARM | Owner: HIGH
Purchasing terlambat approve    | HRD: HIGH | Owner: ALARM
```

---

## FIX 6: PEMUKA AGAMA — Screen Detail

```
lib/features/pemuka_agama/screens/           -- Pakai VendorHome tapi dengan screen khusus
  ├── (via VendorHome dengan accentColor: rolePemukaAgama)
  │
  ├── order_assignment_screen.dart             -- List assignment upacara
  │     -- Per assignment: nama order, jenis upacara, tanggal, jam, lokasi
  │     -- Status: scheduled / hadir / selesai
  │
  ├── ceremony_detail_screen.dart              -- Detail upacara
  │     -- Jenis: Misa Requiem, Pemberkatan, Doa Bersama, dll
  │     -- Jadwal: tanggal, jam mulai, estimasi durasi
  │     -- Lokasi + peta
  │     -- Checklist persiapan (dari paket): buku misa, hosti, anggur, dll
  │     -- Tombol: [Check-in] [Check-out]
  │
  └── schedule_screen.dart                     -- Jadwal mingguan/bulanan
        -- Calendar view: semua assignment
        -- Warna per status (scheduled=biru, present=hijau, done=abu)
```

---

## FIX 7: HRD — KPI Config Screen Eksplisit

Tambahkan ke daftar screen HRD yang sudah ada:

```
lib/features/hrd/screens/
  ├── kpi_metric_manage_screen.dart            -- SUDAH ADA tapi belum di-list secara eksplisit
  │     -- Tab per role: SO | Gudang | Purchasing | Driver | Vendor | HRD | Security
  │     -- Per tab: list metrik + target + bobot
  │     -- Validasi: total bobot per role = 100%
  │     -- Tombol: [Tambah Metrik] [Edit] [Nonaktifkan]
  │
  ├── kpi_period_screen.dart                   -- Kelola periode evaluasi
  │     -- List periode: open/closed
  │     -- Tombol: [Tutup Periode] [Hitung Ulang]
  │
  ├── attendance_shift_screen.dart             -- Kelola shift + assignment karyawan
  │     -- Tab "Master Shift": CRUD shift kerja
  │     -- Tab "Assignment": tabel karyawan × shift × lokasi × hari
  │     -- Drag-drop untuk assign
  │
  └── attendance_location_screen.dart          -- Kelola lokasi geofence (sudah ada)
```

---

## FIX 8: VEHICLE MAINTENANCE → PURCHASING APPROVAL

Gap: Driver lapor masalah → Gudang handle → tapi jika perlu biaya, Purchasing belum terhubung.

```
Flow maintenance yang LENGKAP:

Driver lapor masalah kendaraan (vehicle_maintenance_requests)
  ↓
Gudang review:
  ├─ Bisa diperbaiki sendiri (gratis/minor) → langsung in_progress → completed
  │
  ├─ Perlu beli part/jasa bengkel:
  │    → Gudang buat procurement_request (is_direct_po=true, category='maintenance')
  │    → Link: maintenance_request.procurement_request_id = PR.id
  │    → Priority auto-set sesuai severity maintenance:
  │        maintenance severity critical → procurement priority critical
  │        maintenance severity high → procurement priority high
  │    → Purchasing approve → Gudang beli/servis → maintenance completed
  │
  └─ Kendaraan tidak boleh jalan (critical):
       → vehicles.status = 'maintenance' (otomatis)
       → Semua booking kendaraan ini di-cancel
       → Sistem fallback ke kendaraan lain untuk order yang terdampak
```

---

---

# SANTA MARIA — PATCH v1.24
# Vendor Assignment Dinamis: Internal SM + External Milik Consumer

---

## LATAR BELAKANG v1.24

**Kenyataan lapangan:**
- Consumer sering punya pemuka agama sendiri (Romo paroki mereka)
- Consumer kadang punya fotografer langganan sendiri
- Consumer bisa minta musisi / paduan suara dari gereja mereka sendiri
- Consumer mungkin punya dekorator sendiri dari kenalan

**Masalah sebelumnya:**
- Vendor di-assign via kolom hardcode di `orders` (misal `tukang_foto_id UUID REFERENCES users(id)`)
- Hanya bisa assign user yang TERDAFTAR di sistem
- Tidak bisa handle vendor external yang bukan user app
- Tidak ada tempat menyimpan kontak WA vendor external
- SO harus koordinasi manual via WA tanpa tracking di sistem

**Solusi:**
Tabel `order_vendor_assignments` yang menggantikan SEMUA vendor assignment hardcode. Mendukung internal (user app) DAN external (bukan user, kontak WA saja). Berlaku untuk SEMUA jenis vendor.

---

## TABEL SEBELUM vs SESUDAH

```
SEBELUM (hardcode di orders):
  orders.tukang_foto_id → hanya 1 fotografer, harus user app
  (dekor, konsumsi, pemuka_agama di-assign secara implisit via alarm, tanpa kolom)

SESUDAH (dinamis via order_vendor_assignments):
  1 order bisa punya N vendor (berapa pun, role apapun)
  Setiap vendor bisa internal (user app) ATAU external (nama + WA)
  Bisa mix: pemuka agama external + fotografer internal + dekor internal
```

---

## DATABASE — TABEL BARU v1.24

### Tabel `vendor_role_master` (Master Jenis Vendor/Peran)

Jenis vendor/peran TIDAK di-hardcode ke role app. Bisa ditambah Owner.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
role_code VARCHAR(50) UNIQUE NOT NULL        -- contoh: 'pemuka_agama', 'fotografer', 'dekorator'
role_name VARCHAR(255) NOT NULL              -- contoh: 'Pemuka Agama / Romo'
description TEXT NULLABLE
category ENUM('religious','documentation','decoration','catering','music','other') NOT NULL

-- Mapping ke role app (jika ada pasangannya)
app_role VARCHAR(50) NULLABLE                -- 'pemuka_agama', 'tukang_foto', 'dekor', 'konsumsi', NULL
-- NULL = jenis vendor yang tidak punya role app (misal: musisi, paduan suara, penggali makam)

-- Default per paket (opsional)
is_default_in_package BOOLEAN DEFAULT FALSE  -- apakah biasanya termasuk di paket?
max_per_order SMALLINT NULLABLE              -- maks berapa vendor jenis ini per order (NULL = unlimited)

-- Konfigurasi
requires_attendance BOOLEAN DEFAULT TRUE     -- wajib presensi (field_attendances)?
requires_bukti_foto BOOLEAN DEFAULT FALSE    -- wajib upload bukti foto hasil kerja?

icon VARCHAR(50) NULLABLE                    -- icon Flutter
sort_order INTEGER DEFAULT 0
is_active BOOLEAN DEFAULT TRUE
created_at TIMESTAMP
updated_at TIMESTAMP
```

Initial seed (dapat ditambah Owner):
```
pemuka_agama   | Pemuka Agama / Romo        | religious      | app_role: pemuka_agama  | attendance: ✓
fotografer     | Fotografer / Dokumentasi   | documentation  | app_role: tukang_foto   | attendance: ✓ | bukti: ✓
videografer    | Videografer                | documentation  | app_role: NULL          | attendance: ✓ | bukti: ✓
dekorator      | Dekorator / Bunga          | decoration     | app_role: dekor         | attendance: ✓ | bukti: ✓
katering       | Katering / Konsumsi        | catering       | app_role: konsumsi      | attendance: ✓ | bukti: ✓
musisi         | Musisi / Organis           | music          | app_role: NULL          | attendance: ✓
paduan_suara   | Paduan Suara / Koor        | music          | app_role: NULL          | attendance: ✓
penggali_makam | Penggali Makam             | other          | app_role: NULL          | attendance: ✗
mc             | MC / Pembawa Acara         | other          | app_role: NULL          | attendance: ✓
doa_malam      | Pemimpin Doa Malam         | religious      | app_role: NULL          | attendance: ✓
```

---

### Tabel `order_vendor_assignments` (Assignment Vendor per Order — Unified)

Menggantikan semua assignment vendor yang sebelumnya hardcode/implisit.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
order_id UUID REFERENCES orders(id)
vendor_role_id UUID REFERENCES vendor_role_master(id)

-- Sumber vendor
source ENUM('internal','external_consumer','external_so') NOT NULL
-- internal          : vendor dari pool Santa Maria (user app terdaftar)
-- external_consumer : vendor milik consumer (consumer berikan kontak)
-- external_so       : vendor external yang direkomendasikan SO

-- Internal vendor (jika source = internal)
user_id UUID NULLABLE REFERENCES users(id)   -- FK ke users (role app)

-- External vendor (jika source = external_*)
ext_name VARCHAR(255) NULLABLE               -- nama vendor external
ext_phone VARCHAR(30) NULLABLE               -- nomor HP / WhatsApp
ext_whatsapp VARCHAR(30) NULLABLE            -- nomor WA (jika beda dari HP)
ext_email VARCHAR(255) NULLABLE
ext_organization VARCHAR(255) NULLABLE       -- contoh: "Paroki St. Yoseph Semarang"
ext_notes TEXT NULLABLE                      -- catatan: "Romo paroki keluarga, sudah biasa handle"

-- Assignment detail
assigned_at TIMESTAMP NOT NULL DEFAULT NOW()
assigned_by UUID REFERENCES users(id)        -- SO yang assign (atau sistem)
requested_by_consumer BOOLEAN DEFAULT FALSE  -- apakah consumer yang minta vendor ini?

-- Schedule
scheduled_date DATE NULLABLE
scheduled_time TIME NULLABLE
estimated_duration_hours DECIMAL(4,1) NULLABLE

-- Kegiatan
activity_description TEXT NULLABLE           -- "Misa Requiem", "Dokumentasi Prosesi", "Katering 100 porsi"

-- Status
status ENUM(
  'assigned',            -- sudah di-assign, menunggu konfirmasi vendor
  'confirmed',           -- vendor konfirmasi bisa hadir
  'declined',            -- vendor menolak
  'present',             -- vendor hadir di lokasi
  'completed',           -- tugas selesai
  'no_show',             -- tidak hadir tanpa kabar
  'cancelled'            -- dibatalkan
) DEFAULT 'assigned'

confirmed_at TIMESTAMP NULLABLE
declined_reason TEXT NULLABLE

-- Koordinasi (untuk external vendor)
wa_contacted BOOLEAN DEFAULT FALSE           -- sudah dihubungi via WA?
wa_contacted_at TIMESTAMP NULLABLE
wa_contacted_by UUID NULLABLE REFERENCES users(id)

-- Link ke presensi (auto-create jika requires_attendance = true)
field_attendance_id UUID NULLABLE REFERENCES field_attendances(id)

-- Biaya
fee DECIMAL(15,2) DEFAULT 0                  -- biaya jasa vendor (untuk billing)
fee_source ENUM('package','addon','amendment','manual') DEFAULT 'package'
billing_item_id UUID NULLABLE REFERENCES order_billing_items(id)

-- Bukti
bukti_photo_paths JSONB DEFAULT '[]'         -- foto hasil kerja (jika requires_bukti_foto)

notes TEXT NULLABLE
created_at TIMESTAMP
updated_at TIMESTAMP
```

---

## FLOW: CONSUMER REQUEST VENDOR SENDIRI

```
╔═══════════════════════════════════════════════════════════════════════╗
║  SKENARIO: Consumer minta Romo sendiri                                ║
╠═══════════════════════════════════════════════════════════════════════╣
║                                                                       ║
║  Consumer (via app atau WA ke SO):                                    ║
║  "Mas, untuk Romo saya mau pakai Romo Petrus dari Paroki St. Yoseph. ║
║   Ini nomor WA beliau: 0812-XXXX-XXXX"                               ║
║                                                                       ║
║  ┌─── STEP 1: SO INPUT VENDOR EXTERNAL ───────────────────────────┐  ║
║  │                                                                 │  ║
║  │  SO buka order → tab "Tim Vendor" → [+ Tambah Vendor]          │  ║
║  │  Pilih jenis: "Pemuka Agama / Romo"                            │  ║
║  │  Sumber: ○ Internal SM  ● External (milik consumer)            │  ║
║  │                                                                 │  ║
║  │  Nama: [Romo Petrus Karyadi                    ]                │  ║
║  │  WhatsApp: [0812-3456-7890                     ]                │  ║
║  │  Organisasi: [Paroki St. Yoseph Semarang       ]                │  ║
║  │  Kegiatan: [Misa Requiem + Pemberkatan         ]                │  ║
║  │  Jadwal: [14 Apr 2026, 10:00                   ]                │  ║
║  │  Catatan: [Romo paroki keluarga, kenal baik    ]                │  ║
║  │                                                                 │  ║
║  │  [Simpan & Hubungi via WhatsApp]                                │  ║
║  │                                                                 │  ║
║  └─────────────────────────────────────────────────────────────────┘  ║
║                                                                       ║
║  ┌─── STEP 2: SO HUBUNGI VIA WHATSAPP ────────────────────────────┐  ║
║  │                                                                 │  ║
║  │  Sistem auto-generate WA deep link:                             │  ║
║  │  wa.me/62812345678?text=Selamat%20pagi%20Romo%20Petrus...       │  ║
║  │                                                                 │  ║
║  │  Template pesan (dari system_thresholds, bisa diubah Owner):    │  ║
║  │  "Selamat pagi Romo Petrus,                                    │  ║
║  │   Saya Budi dari Santa Maria Funeral Organizer.                 │  ║
║  │   Keluarga Bpk. Yohanes meminta Romo untuk memimpin             │  ║
║  │   Misa Requiem + Pemberkatan pada:                              │  ║
║  │   📅 14 April 2026, pukul 10:00 WIB                            │  ║
║  │   📍 Rumah Duka Bethesda, Jl. Ahmad Yani No. 5, Semarang       │  ║
║  │   Mohon konfirmasi ketersediaan Romo. Terima kasih."            │  ║
║  │                                                                 │  ║
║  │  SO tekan → WhatsApp terbuka → kirim pesan                     │  ║
║  │  Kembali ke app → centang "Sudah dihubungi via WA"             │  ║
║  │  wa_contacted: true, wa_contacted_at: now()                     │  ║
║  │                                                                 │  ║
║  └─────────────────────────────────────────────────────────────────┘  ║
║                                                                       ║
║  ┌─── STEP 3: KONFIRMASI VENDOR ──────────────────────────────────┐  ║
║  │                                                                 │  ║
║  │  Romo balas WA: "Baik, saya bisa hadir."                       │  ║
║  │  SO buka app → vendor assignment → update status:               │  ║
║  │    'assigned' → 'confirmed'                                     │  ║
║  │                                                                 │  ║
║  │  ATAU Romo tolak: "Maaf, saya ada acara lain."                 │  ║
║  │  SO update: 'assigned' → 'declined'                             │  ║
║  │  → SO tanya consumer: mau ganti Romo atau pakai Romo SM?       │  ║
║  │  → Jika pakai Romo SM: SO assign internal vendor               │  ║
║  │                                                                 │  ║
║  └─────────────────────────────────────────────────────────────────┘  ║
║                                                                       ║
║  ┌─── STEP 4: HARI H — PRESENSI ─────────────────────────────────┐  ║
║  │                                                                 │  ║
║  │  INTERNAL VENDOR: check-in sendiri via app (anti-mock 6 lapis) │  ║
║  │  EXTERNAL VENDOR: SO check-in ATAS NAMA vendor                 │  ║
║  │    → SO tekan "Romo sudah hadir" → proxy check-in              │  ║
║  │    → field_attendances: status='present',                       │  ║
║  │      pic_confirmed=true, pic_confirmed_by=SO                   │  ║
║  │    → TANPA anti-mock (vendor external tidak punya app)          │  ║
║  │                                                                 │  ║
║  └─────────────────────────────────────────────────────────────────┘  ║
║                                                                       ║
║  ┌─── STEP 5: BILLING ───────────────────────────────────────────┐   ║
║  │                                                                 │  ║
║  │  INTERNAL VENDOR: biaya sudah termasuk paket (atau fee SM)     │  ║
║  │  EXTERNAL VENDOR: biaya bisa:                                   │  ║
║  │    a) Rp 0 — vendor gratis (Romo paroki sendiri)               │  ║
║  │    b) Fee tertentu — ditagihkan ke consumer via billing         │  ║
║  │    c) Dibayar langsung oleh consumer ke vendor (di luar sistem) │  ║
║  │  → SO input fee saat assign (bisa Rp 0)                        │  ║
║  │  → Jika fee > 0: auto-create order_billing_items               │  ║
║  │                                                                 │  ║
║  └─────────────────────────────────────────────────────────────────┘  ║
╚═══════════════════════════════════════════════════════════════════════╝
```

---

## FLOW: CONSUMER INPUT DARI APP

```
Consumer buka order form (STEP 2, sebelum SO konfirmasi):

┌─────────────────────────────────────────────────────────┐
│ TIM LAYANAN                                             │
│                                                         │
│ Pemuka Agama:                                           │
│   ○ Dari Santa Maria (kami assign)                      │
│   ● Saya punya sendiri                                  │
│     Nama: [Romo Petrus Karyadi        ]                 │
│     WhatsApp: [0812-3456-7890          ]                 │
│     Organisasi: [Paroki St. Yoseph     ] (opsional)     │
│                                                         │
│ Fotografer:                                             │
│   ● Dari Santa Maria                                    │
│   ○ Saya punya sendiri                                  │
│                                                         │
│ Musisi / Organis:                                       │
│   ○ Dari Santa Maria                                    │
│   ○ Saya punya sendiri                                  │
│   ● Tidak perlu                                         │
│                                                         │
│ [+ Tambah vendor lain]                                  │
│   → Pilih dari vendor_role_master                       │
│   → contoh: Paduan Suara, MC, Videografer               │
│                                                         │
└─────────────────────────────────────────────────────────┘

Saat consumer submit order:
  → Data vendor external tersimpan di order (pending, belum di-assign)
  → SO lihat saat review: "Consumer minta Romo sendiri: Romo Petrus (0812-XXX)"
  → SO konfirmasi → sistem buat order_vendor_assignments per vendor
```

---

## SINKRONISASI KE STEP 3

```
Saat SO konfirmasi order → SELAIN alarm yang sudah ada:

PER vendor di order_vendor_assignments:

  [ INTERNAL VENDOR (source = 'internal', user_id NOT NULL) ]
  → FCM ALARM ke user: "Kamu ditugaskan di Order [X]"
  → Sistem auto-buat field_attendances (status: 'scheduled')

  [ EXTERNAL VENDOR (source = 'external_*', user_id NULL) ]
  → TIDAK ada FCM (vendor tidak punya app)
  → SO mendapat reminder: "Hubungi vendor external via WhatsApp"
  → Sistem auto-buat field_attendances TANPA user_id:
      { order_id, user_id: NULL, ext_vendor_name: 'Romo Petrus',
        status: 'scheduled', kegiatan: 'Misa Requiem' }
  → SO harus proxy check-in saat vendor hadir

  [ VENDOR TIDAK DIMINTA (contoh: consumer tidak perlu musisi) ]
  → Tidak ada record → tidak ada alarm → tidak ada presensi
```

---

## DATABASE — PERUBAHAN EXISTING v1.24

### Tabel `field_attendances` — Tambah Kolom External Vendor

```sql
-- Tambahkan:

vendor_assignment_id UUID NULLABLE REFERENCES order_vendor_assignments(id)
-- Link ke assignment (menggantikan dependensi ke user_id saja)

ext_vendor_name VARCHAR(255) NULLABLE
-- Nama vendor external (jika user_id NULL)

is_proxy_checkin BOOLEAN DEFAULT FALSE
-- true = SO check-in atas nama vendor external
-- false = vendor check-in sendiri via app

proxy_checked_by UUID NULLABLE REFERENCES users(id)
-- SO yang proxy check-in
```

### Tabel `orders` — Hapus Kolom Hardcode Vendor

```sql
-- DEPRECATED (v1.24):
-- tukang_foto_id UUID → HAPUS, diganti order_vendor_assignments
-- (vendor assignment sekarang via tabel relasi, bukan kolom di orders)

-- TAMBAHKAN:
has_external_vendor BOOLEAN DEFAULT FALSE
-- Flag cepat: apakah order ini punya vendor external? (untuk filter/dashboard)
```

### Tabel `order_form_vendor_requests` (Request Vendor dari Consumer saat Input Order)

Menyimpan preferensi vendor consumer SEBELUM SO konfirmasi.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
order_id UUID REFERENCES orders(id)
vendor_role_id UUID REFERENCES vendor_role_master(id)

preference ENUM('internal','external','not_needed') NOT NULL
-- internal    : minta dari SM
-- external    : punya sendiri (isi kontak di bawah)
-- not_needed  : tidak perlu vendor jenis ini

-- Detail external (jika preference = 'external')
ext_name VARCHAR(255) NULLABLE
ext_phone VARCHAR(30) NULLABLE
ext_whatsapp VARCHAR(30) NULLABLE
ext_organization VARCHAR(255) NULLABLE
ext_notes TEXT NULLABLE

created_at TIMESTAMP
updated_at TIMESTAMP
```

---

## TEMPLATE PESAN WA — KONFIGURASI DINAMIS

### Sistem Template WhatsApp Dinamis

Template WA TIDAK di-hardcode di kode — disimpan di tabel `wa_message_templates` agar Owner bisa edit kapan saja via UI tanpa deploy.

### Tabel `wa_message_templates` (Master Template Pesan WA)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
template_code VARCHAR(50) UNIQUE NOT NULL     -- contoh: 'ORDER_CONFIRMED_CONSUMER'
template_name VARCHAR(255) NOT NULL           -- contoh: 'Konfirmasi Order ke Consumer'
target_audience ENUM('consumer','vendor_external','vendor_internal','supplier','other') NOT NULL
trigger_moment VARCHAR(100) NOT NULL          -- kapan pesan ini dikirim

message_template TEXT NOT NULL               -- isi pesan dengan placeholder {xxx}
-- Placeholder yang tersedia tergantung context, lihat daftar di bawah

is_active BOOLEAN DEFAULT TRUE
updated_by UUID NULLABLE REFERENCES users(id)
created_at TIMESTAMP
updated_at TIMESTAMP
```

### Tabel `wa_message_logs` (Log Pesan WA yang Dikirim)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
template_id UUID REFERENCES wa_message_templates(id)
order_id UUID NULLABLE REFERENCES orders(id)
sent_by UUID REFERENCES users(id)            -- SO yang kirim
recipient_phone VARCHAR(30) NOT NULL
recipient_name VARCHAR(255) NOT NULL
message_content TEXT NOT NULL                -- pesan final (placeholder sudah di-replace)
sent_at TIMESTAMP NOT NULL DEFAULT NOW()
created_at TIMESTAMP
```

### Seed: Semua Template WA

```
════════════════════════════════════════════════════════════════
TEMPLATE 1 — ORDER CONFIRMED: SO → CONSUMER
Trigger: SO konfirmasi order (STEP 2)
Target: consumer (keluarga)
════════════════════════════════════════════════════════════════

Code: ORDER_CONFIRMED_CONSUMER

"Kepada Yth. {consumer_name},

Terima kasih telah mempercayakan layanan pemakaman kepada Santa Maria Funeral Organizer.

Kami turut berduka cita yang sedalam-dalamnya atas berpulangnya {almarhum_name} yang terkasih. Semoga arwah beliau diterima di sisi-Nya dan keluarga yang ditinggalkan diberikan ketabahan.

Detail Layanan:
📋 No. Order: {order_number}
📦 Paket: {package_name}
📅 Jadwal: {scheduled_date}, pukul {scheduled_time} WIB
📍 Lokasi: {location}

Tim kami akan segera berkoordinasi untuk memastikan semua berjalan lancar.

Silakan download aplikasi kami untuk memantau status layanan:
▶️ Play Store: {playstore_url}
🍎 App Store: {appstore_url}

Jika sudah memiliki aplikasi, gunakan nomor HP ini untuk login.

Hormat kami,
{so_name}
Santa Maria Funeral Organizer
☎️ {office_phone}"

════════════════════════════════════════════════════════════════
TEMPLATE 2 — ORDER WALKIN: SO → CONSUMER (Walk-in / order via SO)
Trigger: SO buat order untuk walk-in client
Target: consumer
════════════════════════════════════════════════════════════════

Code: ORDER_WALKIN_CONSUMER

"Kepada Yth. {consumer_name},

Terima kasih telah datang ke kantor Santa Maria Funeral Organizer.

Kami turut berduka cita atas berpulangnya {almarhum_name}. Kami akan memastikan layanan pemakaman berjalan dengan penuh kehormatan.

Pesanan Anda telah kami catat:
📋 No. Order: {order_number}
📦 Paket: {package_name}
📅 Jadwal: {scheduled_date}, pukul {scheduled_time} WIB
📍 Lokasi: {location}

Anda dapat memantau status layanan melalui aplikasi kami:
▶️ Play Store: {playstore_url}
🍎 App Store: {appstore_url}

Login dengan nomor HP: {consumer_phone}

Salam,
{so_name}
Santa Maria Funeral Organizer"

════════════════════════════════════════════════════════════════
TEMPLATE 3 — VENDOR ASSIGNMENT: SO → EXTERNAL VENDOR
Trigger: SO assign vendor external
Target: vendor_external
════════════════════════════════════════════════════════════════

Code: VENDOR_ASSIGNMENT_EXTERNAL

"Selamat {greeting} {vendor_name},

Saya {so_name} dari Santa Maria Funeral Organizer Semarang.

{consumer_relation} meminta {honorific} untuk {activity} pada:
📅 {date}, pukul {time} WIB
📍 {location}
🏠 {location_detail}

Mohon konfirmasi ketersediaan {honorific}. Balas pesan ini dengan:
✅ "Bisa" jika bersedia hadir
❌ "Tidak bisa" jika berhalangan

Terima kasih atas kesediaan {honorific}.

Hormat kami,
{so_name} — Santa Maria Funeral Organizer
☎️ {office_phone}"

════════════════════════════════════════════════════════════════
TEMPLATE 4 — PAYMENT REMINDER: SO → CONSUMER
Trigger: Order selesai, consumer belum bayar
Target: consumer
════════════════════════════════════════════════════════════════

Code: PAYMENT_REMINDER_CONSUMER

"Kepada Yth. {consumer_name},

Layanan pemakaman untuk {almarhum_name} telah selesai dilaksanakan.

Total tagihan: Rp {grand_total}
📋 No. Order: {order_number}

Mohon untuk segera melakukan pembayaran melalui aplikasi Santa Maria:
▶️ Play Store: {playstore_url}
🍎 App Store: {appstore_url}

Atau transfer ke:
🏦 {bank_name}
💳 {account_number}
👤 a.n. {account_holder}

Setelah transfer, mohon upload bukti pembayaran melalui aplikasi.

Terima kasih,
{so_name}
Santa Maria Funeral Organizer"

════════════════════════════════════════════════════════════════
TEMPLATE 5 — ORDER UPDATE: SO → CONSUMER
Trigger: Status order berubah (in_progress, driver tiba, dll)
Target: consumer
════════════════════════════════════════════════════════════════

Code: ORDER_STATUS_UPDATE_CONSUMER

"Kepada {consumer_name},

Update layanan {almarhum_name}:
📋 Order: {order_number}
📌 Status: {status_label}
{status_detail}

Pantau detail melalui aplikasi Santa Maria.

{so_name} — Santa Maria"

════════════════════════════════════════════════════════════════
TEMPLATE 6 — AMENDMENT ESTIMATE: SO → CONSUMER
Trigger: SO kirim estimasi biaya amendment
Target: consumer
════════════════════════════════════════════════════════════════

Code: AMENDMENT_ESTIMATE_CONSUMER

"Kepada {consumer_name},

Kami telah menerima permintaan tambahan layanan untuk {almarhum_name}:

{amendment_items}

Estimasi biaya tambahan: Rp {amendment_total}

Mohon buka aplikasi Santa Maria untuk review detail dan memberikan persetujuan.
▶️ Play Store: {playstore_url}
🍎 App Store: {appstore_url}

{so_name} — Santa Maria"

════════════════════════════════════════════════════════════════
TEMPLATE 7 — DOCUMENT HANDOVER: SO → CONSUMER
Trigger: Berkas akta kematian siap diserahkan
Target: consumer
════════════════════════════════════════════════════════════════

Code: DEATH_CERT_HANDOVER_CONSUMER

"Kepada {consumer_name},

Berkas akta kematian untuk {almarhum_name} sudah selesai diproses.

Dokumen yang siap diserahkan:
{document_list}

Mohon untuk mengambil berkas di kantor kami:
📍 {office_address}
🕐 Jam kerja: {office_hours}

Atau hubungi kami untuk pengantaran:
☎️ {office_phone}

{so_name} — Santa Maria Funeral Organizer"

════════════════════════════════════════════════════════════════
TEMPLATE 8 — CONDOLENCE (AI-GENERATED): SYSTEM → CONSUMER
Trigger: Order auto-complete (STEP 7)
Target: consumer
════════════════════════════════════════════════════════════════

Code: CONDOLENCE_AUTO_CONSUMER

"{ai_condolence_message}"

-- Pesan duka cita di-generate oleh AI (GPT-4o mini) berdasarkan:
-- agama almarhum, nama almarhum, nama keluarga
-- Template ini hanya fallback jika AI gagal:
-- "Kami turut berduka cita atas berpulangnya {almarhum_name}.
--  Semoga {almarhum_name} mendapat tempat terbaik di sisi-Nya
--  dan keluarga diberikan ketabahan. — Santa Maria Funeral Organizer"
```

### Placeholder Reference — Semua Variabel yang Tersedia

```
── ORDER CONTEXT ──────────────────────────────────────────
{order_number}       : SM-20260414-0001
{package_name}       : Paket Premium
{scheduled_date}     : 14 April 2026
{scheduled_time}     : 10:00
{location}           : Rumah Duka Bethesda, Jl. Ahmad Yani No. 5
{location_detail}    : Detail lokasi tambahan
{grand_total}        : 15.500.000 (formatted)
{status_label}       : "Sedang Dalam Proses" / "Selesai" / dll
{status_detail}      : Penjelasan status saat ini

── CONSUMER CONTEXT ───────────────────────────────────────
{consumer_name}      : Keluarga Bpk. Yohanes
{consumer_phone}     : 08199999999
{almarhum_name}      : Bpk. Yohanes Surya
{consumer_relation}  : Keluarga Bpk. Yohanes

── SO CONTEXT ─────────────────────────────────────────────
{so_name}            : Budi SO
{office_phone}       : (024) 1234567    — dari system_thresholds
{office_address}     : Jl. xxx          — dari system_thresholds
{office_hours}       : 08:00 - 17:00   — dari system_thresholds

── APP LINKS ──────────────────────────────────────────────
{playstore_url}      : https://play.google.com/store/apps/details?id=xxx
{appstore_url}       : https://apps.apple.com/app/xxx
-- Disimpan di system_thresholds: app_playstore_url, app_appstore_url

── PAYMENT CONTEXT ────────────────────────────────────────
{bank_name}          : BCA              — dari system_thresholds
{account_number}     : 1234567890       — dari system_thresholds
{account_holder}     : CV Santa Maria   — dari system_thresholds

── VENDOR CONTEXT ─────────────────────────────────────────
{vendor_name}        : Romo Petrus
{vendor_role}        : Pemuka Agama
{honorific}          : Romo / Bapak / Ibu
{activity}           : Misa Requiem + Pemberkatan
{date}               : 14 April 2026
{time}               : 10:00
{greeting}           : pagi / siang / sore (auto dari jam)

── AMENDMENT CONTEXT ──────────────────────────────────────
{amendment_items}    : "- Karangan Bunga ×5: Rp 750.000\n- Catering: Rp 1.500.000"
{amendment_total}    : 2.250.000 (formatted)

── DOCUMENT CONTEXT ───────────────────────────────────────
{document_list}      : "✅ KTP Almarhum\n✅ Surat Kematian RS\n..."

── AI CONTEXT ─────────────────────────────────────────────
{ai_condolence_message} : pesan duka dari AI GPT-4o mini
```

### System Thresholds — Tambahan App & Office Info

```
-- App links
app_playstore_url = 'https://play.google.com/store/apps/details?id=com.santamaria.app'
app_appstore_url = 'https://apps.apple.com/app/santa-maria/idXXXXXXXXX'

-- Office info (untuk template WA)
office_phone = '(024) 1234567'
office_address = 'Jl. Pandanaran No. XX, Semarang'
office_hours = 'Senin-Sabtu 08:00-17:00 WIB'

-- Payment info (untuk template WA)
company_bank_name = 'BCA'
company_account_number = '1234567890'
company_account_holder = 'CV Santa Maria Funeral Organizer'
```

### API — Endpoint WA Template

```
### Owner/Admin — Kelola Template
GET    /admin/wa-templates                        -- list semua template
GET    /admin/wa-templates/{id}                   -- detail + preview
PUT    /admin/wa-templates/{id}                   -- edit template
  body: { message_template: "..." }
POST   /admin/wa-templates/{id}/preview           -- preview dengan data sample
  Response: { preview_message: "Kepada Yth. John Doe, ..." }

### SO — Kirim WA
POST   /so/orders/{id}/send-wa                    -- kirim WA ke consumer/vendor
  body: { template_code: 'ORDER_CONFIRMED_CONSUMER',
          recipient_phone: '08199999999',
          extra_data: {} }
  Response: { wa_url: "https://wa.me/6281...?text=...",
              message_preview: "Kepada Yth...",
              log_id: "xxx" }
  -- SO klik wa_url → WhatsApp terbuka → pesan sudah terisi

### SO — WA Quick Actions (tombol di order detail)
GET    /so/orders/{id}/wa-actions                 -- list tombol WA yang tersedia
  Response: [
    { template_code: 'ORDER_CONFIRMED_CONSUMER', label: '📱 WA Konfirmasi ke Keluarga',
      recipient: { name: 'Keluarga Bpk. Yohanes', phone: '08199999999' } },
    { template_code: 'PAYMENT_REMINDER_CONSUMER', label: '💰 WA Reminder Bayar',
      recipient: { name: 'Keluarga Bpk. Yohanes', phone: '08199999999' } },
    { template_code: 'VENDOR_ASSIGNMENT_EXTERNAL', label: '🕯️ WA ke Romo Petrus',
      recipient: { name: 'Romo Petrus', phone: '08123456789' } }
  ]
```

### Flutter — WA Integration

```
lib/features/service_officer/screens/
  └── order_detail_screen.dart                -- PERKAYA: tambah tombol WA

  -- Di bagian bawah order detail, tambahkan section:
  ┌─────────────────────────────────────────────────────┐
  │ 💬 KIRIM WHATSAPP                                   │
  │                                                     │
  │ [📱 WA Konfirmasi ke Keluarga          ]            │
  │ [💰 WA Reminder Pembayaran             ]            │
  │ [📋 WA Update Status                   ]            │
  │ [📄 WA Berkas Akta Siap                ]            │
  │ [🕯️ WA ke Romo Petrus (External)       ]            │
  │ [📸 WA ke Fotografer (jika external)    ]            │
  │                                                     │
  │ Tombol muncul dinamis sesuai context order.         │
  │ Tap → preview pesan → "Buka WhatsApp" → WA terbuka │
  └─────────────────────────────────────────────────────┘

lib/features/shared/widgets/
  └── wa_button_widget.dart                   -- BARU: reusable WA button
        -- Props: template_code, order_id, recipient_name, recipient_phone
        -- Tap → GET /so/orders/{id}/send-wa → preview → launch URL
        -- Log tercatat otomatis di wa_message_logs
```

### Aturan Bisnis WA Template

```
1. Template disimpan di database (wa_message_templates), BUKAN hardcode
   → Super Admin bisa edit isi pesan kapan saja tanpa deploy (v1.27: Owner view only)

2. Placeholder di-replace otomatis oleh backend
   → SO tidak perlu ketik manual — tinggal klik tombol

3. Setiap pengiriman WA tercatat di wa_message_logs
   → Audit trail: siapa kirim, kapan, ke siapa, isi pesan apa

4. Tombol WA di order detail muncul DINAMIS sesuai context:
   → Order baru dikonfirmasi → tampilkan "WA Konfirmasi"
   → Order selesai, belum bayar → tampilkan "WA Reminder Bayar"
   → Ada vendor external → tampilkan "WA ke [nama vendor]"
   → Berkas akta siap → tampilkan "WA Berkas Siap"

5. Play Store / App Store URL disimpan di system_thresholds
   → Bisa diubah jika link berubah

6. Info rekening bank untuk payment juga di system_thresholds
   → Konsisten di semua template yang butuh info rekening

7. AI condolence message di-generate per order (GPT-4o mini)
   → Disesuaikan dengan agama dan budaya almarhum
   → Fallback ke template standar jika AI gagal
```

---

## API — ENDPOINT VENDOR ASSIGNMENT v1.24

```
### SO — Kelola Vendor per Order
GET    /so/orders/{id}/vendors                    -- list semua vendor (internal + external)
POST   /so/orders/{id}/vendors                    -- assign vendor baru
  body: { vendor_role_id, source: 'internal'|'external_consumer'|'external_so',
          user_id: (if internal), ext_name, ext_phone, ext_whatsapp,
          ext_organization, activity_description, scheduled_date, scheduled_time,
          fee: 0 }
PUT    /so/orders/{id}/vendors/{id}               -- update assignment
PUT    /so/orders/{id}/vendors/{id}/confirm        -- vendor konfirmasi bisa hadir
PUT    /so/orders/{id}/vendors/{id}/decline        -- vendor tolak
PUT    /so/orders/{id}/vendors/{id}/proxy-checkin   -- SO proxy check-in untuk external
PUT    /so/orders/{id}/vendors/{id}/proxy-checkout  -- SO proxy check-out untuk external
DELETE /so/orders/{id}/vendors/{id}                -- hapus assignment (jika salah)

### SO — WA Deep Link
GET    /so/orders/{id}/vendors/{id}/wa-link       -- generate WA deep link + template pesan
  Response: { wa_url: "https://wa.me/62812...?text=...", message_preview: "..." }

### Consumer — Request Vendor saat Input Order
POST   /consumer/orders/{id}/vendor-requests       -- simpan preferensi vendor
  body: { requests: [
    { vendor_role_id: 'X', preference: 'external',
      ext_name: 'Romo Petrus', ext_whatsapp: '08123456789' },
    { vendor_role_id: 'Y', preference: 'internal' },
    { vendor_role_id: 'Z', preference: 'not_needed' }
  ] }

### Owner — Master Vendor Role
GET    /admin/master/vendor-roles                  -- list semua jenis vendor
POST   /admin/master/vendor-roles                  -- tambah jenis baru
PUT    /admin/master/vendor-roles/{id}             -- edit
```

---

## FLUTTER — SCREEN v1.24

```
lib/features/
  ├── consumer/screens/
  │   └── vendor_preference_screen.dart        -- BARU: pilih preferensi vendor saat order
  │         -- List dari vendor_role_master (yang is_default_in_package + tambahan)
  │         -- Per jenis: ○ Dari SM | ○ Saya punya | ○ Tidak perlu
  │         -- Jika "Saya punya": form nama + WA + organisasi
  │         -- Di-embed di order_form step (sebelum review)
  │
  ├── service_officer/screens/
  │   ├── vendor_team_screen.dart              -- BARU: kelola semua vendor per order
  │   │     -- List card per vendor assignment:
  │   │     │
  │   │     │  ┌──────────────────────────────────┐
  │   │     │  │ 🕯️ Pemuka Agama                   │
  │   │     │  │ Romo Petrus Karyadi              │
  │   │     │  │ 📍 External (diminta consumer)   │
  │   │     │  │ 🏛️ Paroki St. Yoseph Semarang    │
  │   │     │  │ Status: ✅ Confirmed              │
  │   │     │  │ [📱 WA] [📋 Detail] [🔄 Ganti]  │
  │   │     │  └──────────────────────────────────┘
  │   │     │
  │   │     │  ┌──────────────────────────────────┐
  │   │     │  │ 📸 Fotografer                     │
  │   │     │  │ Benny (Santa Maria)              │
  │   │     │  │ 📍 Internal                      │
  │   │     │  │ Status: 📍 Hadir (check-in 09:45)│
  │   │     │  │ [📋 Detail]                      │
  │   │     │  └──────────────────────────────────┘
  │   │     │
  │   │     -- Badge: Internal (biru) | External (oranye)
  │   │     -- Tombol: [+ Tambah Vendor]
  │   │     -- Filter: Semua | Internal | External | Belum Konfirmasi
  │   │
  │   └── vendor_assign_form_screen.dart       -- BARU: form assign vendor
  │         -- Step 1: Pilih jenis vendor (dari master)
  │         -- Step 2: Internal atau External?
  │         │   Internal → dropdown user yang role-nya cocok
  │         │   External → form: nama, WA, organisasi, catatan
  │         -- Step 3: Jadwal, kegiatan, estimasi durasi, fee
  │         -- Tombol: [Simpan] atau [Simpan & Hubungi WA]
  │
  └── shared/widgets/
      └── vendor_status_widget.dart            -- BARU: reusable badge status vendor
            -- Warna per status: assigned(abu), confirmed(biru), present(hijau),
            --                   declined(merah), no_show(merah gelap)
            -- Badge source: Internal(biru) / External(oranye)
```

---

## INTEGRASI KE AMENDMENT (v1.22)

```
Amendment item_type = 'add_vendor':
  → SO bisa tambah vendor (internal atau external) via amendment
  → Sama flow-nya: pilih jenis → internal/external → jadwal → fee
  → Jika external: SO hubungi via WA → konfirmasi → proxy check-in
  → Fee masuk ke billing amendment
```

---

## INTEGRASI KE KPI

```
Untuk INTERNAL vendor → KPI tetap dihitung dari field_attendances + order_vendor_assignments
Untuk EXTERNAL vendor → TIDAK masuk KPI (bukan karyawan/vendor SM)

VND_ASSIGNMENT_ACCEPT_RATE | Tingkat Konfirmasi Assignment
  data_source: order_vendor_assignments (internal only)
  calculation: % confirmed vs total assigned
  target: ≥ 90%
```

---

## ATURAN BISNIS v1.24

```
1. SETIAP ORDER bisa punya N vendor dari jenis apapun
   → Tidak dibatasi 1 per jenis (bisa 2 pemuka agama, 3 musisi)
   → max_per_order di vendor_role_master sebagai soft limit (warning, bukan block)

2. CONSUMER bisa request vendor external SAAT input order
   → Tersimpan di order_form_vendor_requests
   → SO review saat konfirmasi → buat order_vendor_assignments

3. INTERNAL VENDOR:
   → Wajib user app terdaftar
   → Check-in sendiri via app (anti-mock 6 lapis)
   → Masuk KPI
   → Bisa tolak assignment (tracked di hrd_violations)

4. EXTERNAL VENDOR:
   → TIDAK perlu install app
   → Koordinasi via WhatsApp (deep link + template pesan)
   → Check-in di-proxy oleh SO di lapangan
   → TIDAK masuk KPI
   → TIDAK bisa terima alarm/notif dari sistem
   → Biaya bisa Rp 0 (jika vendor gratis / dibayar consumer langsung)

5. WHATSAPP TEMPLATE:
   → Pesan template bisa diubah Owner di system_thresholds
   → Placeholder di-replace otomatis
   → SO tinggal tekan → WA terbuka → kirim

6. VENDOR MENOLAK:
   → Internal: status='declined' → SO assign pengganti → declined_count++ → KPI
   → External: status='declined' → SO tanya consumer → ganti atau pakai SM?

7. PRESENSI EXTERNAL VENDOR:
   → field_attendances dibuat TANPA user_id
   → SO proxy check-in: is_proxy_checkin=true
   → Tetap tercatat di laporan presensi order (sebagai "hadir via SO")

8. BILLING:
   → Internal vendor: fee biasanya Rp 0 (termasuk paket) atau sudah di-set di package
   → External vendor: fee diinput SO → auto-create billing item jika fee > 0
   → Fee = 0: vendor gratis (Romo paroki sendiri, musisi gereja sendiri)
```

---

---

# SANTA MARIA — PATCH v1.25
# Paket Stock-Aware + Surat Penerimaan Layanan Kematian (Tanda Tangan Wajib)

---

## LATAR BELAKANG v1.25

**Masalah 1 — Paket tampil meskipun stok habis:**
Saat ini paket ditampilkan ke Consumer dan SO tanpa cek stok. Stok baru dicek saat SO konfirmasi (STEP 3). Akibatnya, consumer bisa pilih paket yang ternyata stoknya kosong → pengalaman buruk.

**Masalah 2 — Tidak ada surat penerimaan layanan:**
Consumer langsung order → SO langsung konfirmasi → tidak ada dokumen resmi yang ditandatangani. Secara hukum dan bisnis, harus ada surat persetujuan layanan yang ditandatangani consumer/keluarga SEBELUM order berjalan.

**Solusi:**
1. Paket yang stok-nya tidak memenuhi → tidak muncul / ditandai "Stok Habis"
2. Surat Penerimaan Layanan Kematian → wajib ditandatangani sebelum order bisa dikonfirmasi
3. Bisa diisi & ditandatangani di app Consumer ATAU di app SO (tablet, di depan keluarga)
4. Setelah signed → bisa download PDF

---

## BAGIAN A: PAKET STOCK-AWARE

### Konsep

```
SEBELUM:
  Consumer/SO lihat daftar paket → semua tampil → pilih → konfirmasi
  → OH TIDAK, stok cologne habis → flag needs_restock → delay

SESUDAH:
  Consumer/SO lihat daftar paket → sistem cek stok per paket REAL-TIME
  → Paket dengan stok lengkap: tampil normal ✅
  → Paket dengan stok partial: tampil + warning "Beberapa item perlu pengadaan" ⚠️
  → Paket dengan item kritis habis: TIDAK bisa dipilih ❌ (atau tampil abu-abu)
```

### Tabel `package_items` — Tambah Kolom

```sql
-- Tambahkan ke package_items:

is_critical BOOLEAN DEFAULT FALSE
-- true  = item ini WAJIB ada stoknya agar paket bisa dipilih (contoh: peti, kain)
-- false = item ini nice-to-have, paket tetap bisa dipilih meski stok habis (contoh: permen)

minimum_required_qty DECIMAL(10,2) DEFAULT 1
-- minimum stok yang harus tersedia agar item dianggap "ada"
-- contoh: peti = 1, lilin = 4 (perlu 4 per order)
```

### API — Package Listing Diperkaya

```
### Consumer & SO — List Paket (DIPERKAYA)
GET    /packages                                  -- list semua paket
GET    /packages?check_stock=true                 -- list paket + info ketersediaan stok

  Response per paket:
  {
    "id": "xxx",
    "name": "Paket Premium",
    "price": 15000000,
    "stock_status": "available",           -- available | partial | unavailable
    "stock_detail": {
      "total_items": 15,
      "available_items": 13,
      "partial_items": 1,                  -- stok ada tapi kurang dari kebutuhan
      "unavailable_items": 1,              -- stok = 0
      "critical_unavailable": []           -- item critical yang habis → paket tidak bisa dipilih
      "warning_items": [
        { "item_name": "Eau de Cologne", "needed": 2, "available": 0, "is_critical": false }
      ]
    },
    "can_select": true                     -- false jika ada critical_unavailable
  }

-- Aturan:
-- stock_status = 'available'    → semua item stok cukup
-- stock_status = 'partial'      → ada item non-critical yang kurang (paket masih bisa dipilih)
-- stock_status = 'unavailable'  → ada item CRITICAL yang stok 0 (paket TIDAK bisa dipilih)
-- can_select = false            → tombol "Pilih Paket" disabled
```

### Implementasi Backend

```php
class PackageStockService
{
  public function checkAvailability(Package $package): array
  {
    $items = $package->items()->whereNotNull('stock_item_id')->with('stockItem')->get();

    $result = [
      'total_items' => $items->count(),
      'available_items' => 0,
      'partial_items' => 0,
      'unavailable_items' => 0,
      'critical_unavailable' => [],
      'warning_items' => [],
    ];

    foreach ($items as $item) {
      $stock = $item->stockItem;
      $needed = $item->minimum_required_qty ?? $item->deduct_quantity;
      $available = $stock->current_quantity;

      if ($available >= $needed) {
        $result['available_items']++;
      } elseif ($available > 0) {
        $result['partial_items']++;
        $result['warning_items'][] = [
          'item_name' => $stock->item_name,
          'needed' => $needed,
          'available' => $available,
          'is_critical' => $item->is_critical,
        ];
      } else {
        $result['unavailable_items']++;
        if ($item->is_critical) {
          $result['critical_unavailable'][] = [
            'item_name' => $stock->item_name,
            'needed' => $needed,
          ];
        }
        $result['warning_items'][] = [
          'item_name' => $stock->item_name,
          'needed' => $needed,
          'available' => 0,
          'is_critical' => $item->is_critical,
        ];
      }
    }

    $result['stock_status'] = match(true) {
      count($result['critical_unavailable']) > 0 => 'unavailable',
      $result['unavailable_items'] > 0 || $result['partial_items'] > 0 => 'partial',
      default => 'available',
    };

    $result['can_select'] = count($result['critical_unavailable']) === 0;

    return $result;
  }
}
```

### Flutter — Package Selection Diperkaya

```
lib/features/shared/screens/
  └── package_select_screen.dart              -- PERKAYA (Consumer & SO pakai screen ini)

  Per paket card:
  ┌─────────────────────────────────────────────────────┐
  │ 📦 Paket Premium                      Rp 15.000.000│
  │ ───────────────────────────────────────────────────  │
  │ Peti Melamin, Dekorasi Lengkap, Mobil Jenazah,      │
  │ Katering 100 porsi, Dokumentasi Foto, ...            │
  │                                                     │
  │ ✅ Stok Tersedia                         [PILIH]    │
  └─────────────────────────────────────────────────────┘

  ┌─────────────────────────────────────────────────────┐
  │ 📦 Paket Gold                          Rp 25.000.000│
  │ ───────────────────────────────────────────────────  │
  │ Peti Duco, Dekorasi Premium, 2 Mobil, ...            │
  │                                                     │
  │ ⚠️ Tersedia (1 item perlu pengadaan: Cologne)  [PILIH] │
  │ └─ Item non-kritis — tidak menghambat layanan       │
  └─────────────────────────────────────────────────────┘

  ┌─────────────────────────────────────────────────────┐
  │ 📦 Paket Diamond                       Rp 50.000.000│
  │ ───────────────────────────────────────────────────  │
  │ Peti Duco Premium, Dekorasi Eksklusif, ...           │
  │                                                     │
  │ ❌ Tidak Tersedia — Peti Duco Premium habis          │
  │ └─ Hubungi Santa Maria untuk info restock     [—]   │
  └─────────────────────────────────────────────────────┘
```

---

## BAGIAN B: SURAT PENERIMAAN LAYANAN KEMATIAN

### Konsep Dokumen

```
Surat Penerimaan Layanan Kematian = dokumen resmi yang berisi:
1. Identitas pemesan (penanggung jawab / keluarga)
2. Data almarhum
3. Detail layanan yang dipilih (paket + add-on)
4. Total estimasi biaya
5. Syarat & ketentuan layanan
6. Persetujuan & tanda tangan digital

WAJIB ditandatangani SEBELUM SO bisa konfirmasi order.
Bisa diisi di:
  - App Consumer (keluarga isi sendiri)
  - App SO (SO isi di depan keluarga, keluarga tanda tangan di tablet SO)
```

### Tabel `service_acceptance_letters` (Surat Penerimaan Layanan Kematian)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
letter_number VARCHAR(50) UNIQUE NOT NULL     -- contoh: SPL-20260414-0001
order_id UUID REFERENCES orders(id)

-- ═══ BAGIAN 1: IDENTITAS PEMESAN ═══
pj_nama_lengkap VARCHAR(255) NOT NULL        -- nama lengkap penanggung jawab
pj_nik VARCHAR(20) NULLABLE                  -- NIK KTP (opsional)
pj_alamat TEXT NOT NULL
pj_rt_rw VARCHAR(20) NULLABLE               -- RT/RW
pj_kelurahan VARCHAR(100) NULLABLE
pj_kecamatan VARCHAR(100) NULLABLE
pj_kota VARCHAR(100) NULLABLE
pj_provinsi VARCHAR(100) NULLABLE
pj_kode_pos VARCHAR(10) NULLABLE
pj_no_telp VARCHAR(30) NOT NULL
pj_no_wa VARCHAR(30) NULLABLE                -- jika berbeda dari telp
pj_email VARCHAR(255) NULLABLE
pj_hubungan_almarhum VARCHAR(100) NOT NULL   -- "Anak Kandung", "Istri", "Suami", dll

-- ═══ BAGIAN 2: DATA ALMARHUM ═══
alm_nama_lengkap VARCHAR(255) NOT NULL
alm_tempat_lahir VARCHAR(100) NULLABLE
alm_tanggal_lahir DATE NULLABLE
alm_tanggal_meninggal DATE NOT NULL
alm_waktu_meninggal TIME NULLABLE
alm_tempat_meninggal VARCHAR(255) NULLABLE   -- RS/Rumah/dll
alm_alamat_terakhir TEXT NULLABLE
alm_agama VARCHAR(50) NULLABLE
alm_jenis_kelamin ENUM('laki-laki','perempuan') NULLABLE
alm_usia_tahun SMALLINT NULLABLE             -- auto-calculate dari lahir & meninggal

-- ═══ BAGIAN 3: DETAIL LAYANAN ═══
package_id UUID NULLABLE REFERENCES packages(id)
package_name VARCHAR(255) NOT NULL           -- snapshot nama paket
package_price DECIMAL(15,2) NOT NULL         -- snapshot harga paket

-- Add-on (snapshot)
addons JSONB DEFAULT '[]'
-- format: [{ "name": "Embalming", "price": 500000 }, ...]

-- Vendor preferences (snapshot dari order_form_vendor_requests)
vendor_preferences JSONB DEFAULT '[]'
-- format: [{ "role": "Pemuka Agama", "preference": "external", "name": "Romo Petrus" }, ...]

-- Estimasi biaya
subtotal_paket DECIMAL(15,2) NOT NULL
subtotal_addon DECIMAL(15,2) DEFAULT 0
estimasi_total DECIMAL(15,2) NOT NULL

-- ═══ BAGIAN 4: LOKASI & JADWAL ═══
rumah_duka VARCHAR(255) NULLABLE
alamat_rumah_duka TEXT NULLABLE
rencana_tanggal_prosesi DATE NULLABLE
rencana_durasi_hari SMALLINT NULLABLE        -- berapa hari prosesi
tempat_pemakaman VARCHAR(255) NULLABLE       -- pemakaman / krematorium
jenis_prosesi ENUM('pemakaman','kremasi','pemakaman_dan_kremasi','lainnya') NULLABLE

-- ═══ BAGIAN 5: SYARAT & KETENTUAN ═══
terms_version VARCHAR(20) NOT NULL           -- versi S&K yang berlaku (dari system)
terms_accepted BOOLEAN DEFAULT FALSE         -- consumer centang "Saya setuju"
terms_accepted_at TIMESTAMP NULLABLE

-- Isi S&K disimpan terpisah di terms_and_conditions table (bisa diubah Owner)

-- ═══ BAGIAN 6: TANDA TANGAN ═══
-- Penanggung Jawab (Keluarga)
pj_signed BOOLEAN DEFAULT FALSE
pj_signed_at TIMESTAMP NULLABLE
pj_signature_path TEXT NULLABLE              -- tanda tangan digital (R2)

-- Saksi (opsional, jika ada keluarga lain yang ikut tanda tangan)
saksi_nama VARCHAR(255) NULLABLE
saksi_hubungan VARCHAR(100) NULLABLE
saksi_signed BOOLEAN DEFAULT FALSE
saksi_signed_at TIMESTAMP NULLABLE
saksi_signature_path TEXT NULLABLE

-- Pihak Santa Maria (SO yang handle)
sm_officer_id UUID NULLABLE REFERENCES users(id)
sm_officer_signed BOOLEAN DEFAULT FALSE
sm_officer_signed_at TIMESTAMP NULLABLE
sm_officer_signature_path TEXT NULLABLE

-- ═══ STATUS DOKUMEN ═══
status ENUM(
  'draft',               -- sedang diisi
  'pending_signature',   -- data lengkap, menunggu tanda tangan
  'signed',              -- sudah ditandatangani semua pihak
  'confirmed'            -- order sudah dikonfirmasi berdasarkan surat ini
) DEFAULT 'draft'

-- Siapa yang input
filled_by UUID REFERENCES users(id)          -- consumer atau SO
filled_via ENUM('consumer_app','so_app') NOT NULL

-- PDF
pdf_generated BOOLEAN DEFAULT FALSE
pdf_path TEXT NULLABLE                       -- path PDF di R2
pdf_generated_at TIMESTAMP NULLABLE

-- Meta
kota_surat VARCHAR(100) NULLABLE             -- auto dari system_thresholds.default_city
tanggal_surat DATE NOT NULL DEFAULT CURRENT_DATE

notes TEXT NULLABLE
created_at TIMESTAMP
updated_at TIMESTAMP
```

### Tabel `terms_and_conditions` (Syarat & Ketentuan — Dinamis)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
version VARCHAR(20) UNIQUE NOT NULL          -- contoh: '1.0', '1.1', '2.0'
title VARCHAR(255) NOT NULL                  -- "Syarat & Ketentuan Layanan Kematian"
content TEXT NOT NULL                        -- isi S&K dalam format markdown/plain text
effective_date DATE NOT NULL                 -- berlaku mulai tanggal ini
is_current BOOLEAN DEFAULT FALSE             -- versi yang sedang berlaku
created_by UUID REFERENCES users(id)
created_at TIMESTAMP
updated_at TIMESTAMP
```

Seed S&K awal:

```
Version: 1.0
Title: Syarat & Ketentuan Layanan Pemakaman Santa Maria

Isi:

SURAT PENERIMAAN LAYANAN KEMATIAN

Yang bertanda tangan di bawah ini ("Pihak Pertama" / Penanggung Jawab),
dengan ini menyatakan menerima dan menyetujui layanan pemakaman yang
diselenggarakan oleh CV Santa Maria Funeral Organizer ("Pihak Kedua")
dengan ketentuan sebagai berikut:

1. LINGKUP LAYANAN
   Pihak Kedua akan menyediakan layanan pemakaman sesuai paket yang dipilih,
   meliputi namun tidak terbatas pada: penyediaan peti, dekorasi, transportasi
   jenazah, koordinasi prosesi, dan layanan pendukung lainnya sebagaimana
   tercantum dalam detail paket.

2. BIAYA LAYANAN
   a. Biaya layanan sesuai dengan paket dan add-on yang dipilih.
   b. Biaya tambahan di luar paket akan diinformasikan dan memerlukan
      persetujuan tertulis Pihak Pertama sebelum dilaksanakan.
   c. Pembayaran dilakukan setelah layanan selesai, melalui transfer bank
      atau tunai, dengan batas waktu sesuai ketentuan yang berlaku.

3. PEMBATALAN & PERUBAHAN
   a. Pembatalan layanan setelah konfirmasi dikenakan biaya administrasi.
   b. Perubahan paket atau add-on dimungkinkan selama layanan belum dimulai.
   c. Penambahan layanan saat prosesi berlangsung dimungkinkan dengan
      persetujuan tambahan (Amendment).

4. TANGGUNG JAWAB
   a. Pihak Kedua bertanggung jawab atas kualitas layanan sesuai paket.
   b. Pihak Kedua tidak bertanggung jawab atas keterlambatan yang disebabkan
      oleh force majeure (bencana alam, huru-hara, pandemi).
   c. Pihak Pertama bertanggung jawab atas kebenaran data yang diberikan.
   d. Kerusakan/kehilangan peralatan yang dipinjamkan menjadi tanggung jawab
      Pihak Pertama.

5. PERALATAN PINJAMAN
   a. Peralatan yang dipinjamkan wajib dikembalikan dalam kondisi baik
      maksimal 1×24 jam setelah prosesi selesai.
   b. Kerusakan atau kehilangan akan dikenakan biaya penggantian.

6. DOKUMENTASI & PRIVASI
   a. Dokumentasi foto/video dilakukan untuk keperluan internal dan
      diserahkan kepada keluarga setelah prosesi.
   b. Santa Maria menjaga kerahasiaan data pribadi keluarga.

7. PENYELESAIAN SENGKETA
   Segala sengketa diselesaikan secara musyawarah. Jika tidak tercapai
   kesepakatan, akan diselesaikan melalui jalur hukum sesuai peraturan
   yang berlaku di wilayah Kota Semarang.

Dengan menandatangani dokumen ini, Pihak Pertama menyatakan telah membaca,
memahami, dan menyetujui seluruh ketentuan di atas.
```

---

## FLOW BARU: ORDER DENGAN TANDA TANGAN WAJIB

```
╔═══════════════════════════════════════════════════════════════════════╗
║  ALUR ORDER BARU — DENGAN SURAT PENERIMAAN LAYANAN                  ║
╠═══════════════════════════════════════════════════════════════════════╣
║                                                                       ║
║  STEP 1 — ORDER MASUK (tidak berubah)                                ║
║  Consumer/SO input data awal → status: 'pending'                     ║
║                                                                       ║
║  STEP 1.5 — SURAT PENERIMAAN LAYANAN ← BARU (GATE)                  ║
║  ─────────────────────────────────────────────────────                ║
║                                                                       ║
║  Setelah paket dipilih, SEBELUM SO bisa konfirmasi:                  ║
║                                                                       ║
║  A. CONSUMER ISI SENDIRI (via app):                                  ║
║     1. Consumer pilih paket (hanya yang stock-aware ✅)               ║
║     2. Form surat penerimaan muncul (auto-fill dari data order)      ║
║     3. Consumer lengkapi: data PJ, data almarhum, cek S&K            ║
║     4. Consumer tanda tangan digital di layar                        ║
║     5. Save → PDF auto-generate → bisa download                     ║
║     6. Status surat: 'signed' → SO bisa konfirmasi                  ║
║                                                                       ║
║  B. SO ISI DI DEPAN KELUARGA (via tablet SO):                        ║
║     1. SO buka order → "Isi Surat Penerimaan"                       ║
║     2. SO input data (dibantu keluarga / dari KTP)                   ║
║     3. SO bacakan S&K → keluarga centang "Setuju"                    ║
║     4. Keluarga tanda tangan di tablet SO                            ║
║     5. SO juga tanda tangan (pihak Santa Maria)                      ║
║     6. Save → PDF auto-generate → bisa download / kirim WA          ║
║     7. Status surat: 'signed' → SO bisa konfirmasi                  ║
║                                                                       ║
║  C. WALK-IN (SO Kantor):                                             ║
║     1. Keluarga datang ke kantor                                     ║
║     2. SO input semua data di tempat                                 ║
║     3. Keluarga tanda tangan di tablet                               ║
║     4. Print PDF jika perlu (atau email/WA)                          ║
║                                                                       ║
║  ⛔ GATE: SO TIDAK BISA tekan "Konfirmasi Order" jika               ║
║     surat penerimaan belum status 'signed'                           ║
║                                                                       ║
║  STEP 2 — SO KONFIRMASI (tidak berubah, tapi ada gate baru)         ║
║  Validasi: service_acceptance_letters.status = 'signed'              ║
║  Jika belum signed → tombol "Konfirmasi" disabled + pesan:          ║
║  "Surat Penerimaan Layanan belum ditandatangani"                     ║
║                                                                       ║
║  STEP 3-9 — sama seperti sebelumnya                                  ║
╚═══════════════════════════════════════════════════════════════════════╝
```

### Update Tabel `orders` — Link ke Surat

```sql
-- Tambahkan ke tabel orders:

acceptance_letter_id UUID NULLABLE REFERENCES service_acceptance_letters(id)
-- Link ke surat penerimaan layanan
-- WAJIB terisi + status='signed' sebelum order bisa dikonfirmasi
```

### Update Order Status ENUM

```sql
-- Tambah status baru antara 'pending' dan 'confirmed':
status ENUM(
  'pending',             -- baru masuk dari consumer
  'awaiting_signature',  -- BARU: paket dipilih, menunggu tanda tangan surat
  'so_review',           -- SO sedang verifikasi (surat sudah signed)
  'confirmed',           -- SO konfirmasi
  'in_progress',         -- driver di-assign
  'completed',           -- auto-complete
  'cancelled'
) DEFAULT 'pending'
```

---

## API — ENDPOINT SURAT PENERIMAAN v1.25

```
### Consumer — Isi & Tanda Tangan Surat
POST   /consumer/orders/{id}/acceptance-letter     -- buat draft surat
  body: { pj_nama_lengkap, pj_alamat, pj_no_telp, pj_hubungan_almarhum,
          alm_nama_lengkap, alm_tanggal_meninggal, alm_agama, ... }

GET    /consumer/orders/{id}/acceptance-letter      -- lihat surat (draft / signed)
PUT    /consumer/orders/{id}/acceptance-letter      -- update data surat
POST   /consumer/orders/{id}/acceptance-letter/sign -- tanda tangan consumer
  body: { signature: file, terms_accepted: true }

GET    /consumer/orders/{id}/acceptance-letter/pdf  -- download PDF

### SO — Isi & Capture Tanda Tangan Keluarga
POST   /so/orders/{id}/acceptance-letter           -- SO buat draft
PUT    /so/orders/{id}/acceptance-letter            -- SO update data
POST   /so/orders/{id}/acceptance-letter/sign-pj    -- capture tanda tangan keluarga
  body: { signature: file, terms_accepted: true }
POST   /so/orders/{id}/acceptance-letter/sign-sm    -- SO tanda tangan pihak SM
  body: { signature: file }
POST   /so/orders/{id}/acceptance-letter/sign-saksi -- tanda tangan saksi (opsional)
  body: { saksi_nama, saksi_hubungan, signature: file }

GET    /so/orders/{id}/acceptance-letter/pdf        -- download PDF
POST   /so/orders/{id}/acceptance-letter/send-wa    -- kirim PDF via WA ke consumer
  → menggunakan wa_message_templates code: 'ACCEPTANCE_LETTER_CONSUMER'

### Owner — Kelola S&K
GET    /admin/terms-and-conditions                  -- list semua versi
POST   /admin/terms-and-conditions                  -- buat versi baru
PUT    /admin/terms-and-conditions/{id}/activate    -- set sebagai versi berlaku
```

---

## FLUTTER — SCREEN v1.25

```
lib/features/
  ├── shared/screens/
  │   └── acceptance_letter_screen.dart        -- BARU: form surat penerimaan
  │         -- Dipakai oleh Consumer DAN SO (shared screen)
  │         -- Mode: 'consumer' (isi sendiri) atau 'so' (SO isi untuk keluarga)
  │         --
  │         -- Layout: form panjang dengan section collapsible
  │         --
  │         -- Section 1: Data Penanggung Jawab
  │         │   Nama Lengkap: [_______________]
  │         │   NIK: [_______________] (opsional)
  │         │   Alamat: [_______________]
  │         │   No. Telp: [_______________]
  │         │   Hubungan: [dropdown: Anak/Istri/Suami/Saudara/Lainnya]
  │         │
  │         -- Section 2: Data Almarhum
  │         │   Nama Lengkap: [_______________]
  │         │   Tempat/Tanggal Lahir: [___] / [date picker]
  │         │   Tanggal Meninggal: [date picker]
  │         │   Tempat Meninggal: [_______________]
  │         │   Agama: [dropdown]
  │         │
  │         -- Section 3: Detail Layanan (auto-fill dari order)
  │         │   Paket: Paket Premium — Rp 15.000.000
  │         │   Add-on: Embalming, Foto — Rp 1.500.000
  │         │   Vendor: Romo Petrus (external) ← dari vendor preferences
  │         │   Total Estimasi: Rp 16.500.000
  │         │   (read-only, diambil dari data order)
  │         │
  │         -- Section 4: Lokasi & Jadwal
  │         │   Rumah Duka: [_______________]
  │         │   Tanggal Prosesi: [date picker]
  │         │   Durasi: [___] hari
  │         │   Tempat Pemakaman: [_______________]
  │         │
  │         -- Section 5: Syarat & Ketentuan
  │         │   [Baca Syarat & Ketentuan ▼]  ← expandable
  │         │   (isi S&K dari terms_and_conditions yang is_current)
  │         │   ☑ Saya telah membaca dan menyetujui syarat & ketentuan
  │         │
  │         -- Section 6: Tanda Tangan
  │         │   ┌─────────────────────────────────┐
  │         │   │                                 │
  │         │   │    (area tanda tangan digital)  │
  │         │   │    flutter_signature_pad         │
  │         │   │                                 │
  │         │   └─────────────────────────────────┘
  │         │   Nama: [auto-fill dari PJ]
  │         │   Tanggal: [auto: hari ini]
  │         │
  │         │   [Saksi (opsional)]  ← toggle expand
  │         │   Nama Saksi: [___]  Hubungan: [___]
  │         │   [area tanda tangan saksi]
  │         │
  │         │   [Pihak Santa Maria]  ← hanya di mode SO
  │         │   Nama: [auto: nama SO]
  │         │   [area tanda tangan SO]
  │         │
  │         -- Footer:
  │         │   [Simpan Draft]  [Tanda Tangan & Simpan]
  │         │   Setelah signed:
  │         │   [📄 Download PDF]  [📱 Kirim via WA]
  │
  ├── consumer/screens/
  │   └── order_form_screen.dart               -- PERKAYA: tambah step surat
  │         -- Step 1: Data almarhum
  │         -- Step 2: Data keluarga PJ
  │         -- Step 3: Pilih paket (STOCK-AWARE ✅❌⚠️)
  │         -- Step 4: Pilih add-on
  │         -- Step 5: Pilih vendor (internal/external)
  │         -- Step 6: Surat Penerimaan Layanan ← BARU
  │         -- Step 7: Review + Tanda Tangan + Submit
  │
  ├── service_officer/screens/
  │   └── order_confirm_screen.dart            -- PERKAYA: gate tanda tangan
  │         -- Jika surat belum signed:
  │         │   ┌──────────────────────────────────┐
  │         │   │ ⚠️ Surat Penerimaan Layanan      │
  │         │   │    belum ditandatangani           │
  │         │   │                                  │
  │         │   │ [📝 Isi Surat Sekarang]          │
  │         │   │ [⏳ Menunggu Consumer Tanda Tangan]│
  │         │   │                                  │
  │         │   │ Tombol "Konfirmasi" DISABLED     │
  │         │   └──────────────────────────────────┘
  │         │
  │         -- Jika surat sudah signed:
  │         │   ✅ Surat Penerimaan Layanan sudah ditandatangani
  │         │   📄 [Lihat Surat] [Download PDF]
  │         │   Tombol "Konfirmasi" ENABLED ✓
```

---

## PDF GENERATION — TEMPLATE SURAT

```
Backend generate PDF via barryvdh/laravel-dompdf (sudah ada di tech stack).

Layout PDF:
┌──────────────────────────────────────────────────┐
│           SANTA MARIA FUNERAL ORGANIZER           │
│         Jl. Pandanaran No. XX, Semarang          │
│           Telp: (024) 1234567                    │
│                                                  │
│       SURAT PENERIMAAN LAYANAN KEMATIAN          │
│          No: SPL-20260414-0001                   │
│                                                  │
│ Yang bertanda tangan di bawah ini:               │
│                                                  │
│ Nama        : Antonius Yohanes                   │
│ Alamat      : Jl. Pemuda No. 10, Semarang       │
│ No. Telp    : 0819-9999-999                      │
│ Hubungan    : Anak Kandung                       │
│                                                  │
│ Selanjutnya disebut "Pihak Pertama", dengan ini  │
│ menyatakan menerima layanan pemakaman untuk:     │
│                                                  │
│ Nama Almarhum : Bpk. Yohanes Surya              │
│ Tempat/Tgl Lahir : Semarang, 15 Maret 1945      │
│ Tanggal Meninggal : 14 April 2026               │
│ Agama           : Katolik                        │
│                                                  │
│ ═══ DETAIL LAYANAN ═══                           │
│ Paket       : Premium              Rp 15.000.000│
│ Add-on:                                          │
│   - Embalming                      Rp    500.000│
│   - Foto Dokumentasi               Rp    500.000│
│ Total Estimasi                     Rp 16.000.000│
│                                                  │
│ ═══ LOKASI & JADWAL ═══                          │
│ Rumah Duka  : Bethesda, Jl. Ahmad Yani No. 5     │
│ Tgl Prosesi : 14-16 April 2026 (3 hari)         │
│ Pemakaman   : Pemakaman Bergota                  │
│                                                  │
│ ═══ SYARAT & KETENTUAN ═══                       │
│ (isi S&K versi 1.0)                             │
│                                                  │
│ ═══ TANDA TANGAN ═══                             │
│                                                  │
│ Semarang, 14 April 2026                          │
│                                                  │
│ Pihak Pertama        Pihak Kedua                 │
│ (Penanggung Jawab)   (Santa Maria)               │
│                                                  │
│ [ttd digital]        [ttd digital]               │
│ Antonius Yohanes     Budi SO                     │
│                                                  │
│ Saksi:                                           │
│ [ttd digital]                                    │
│ Maria Yohanes (Istri)                            │
│                                                  │
└──────────────────────────────────────────────────┘
```

---

## WA TEMPLATE BARU — SURAT PENERIMAAN

```
Code: ACCEPTANCE_LETTER_CONSUMER

"Kepada Yth. {consumer_name},

Surat Penerimaan Layanan Kematian untuk {almarhum_name} telah selesai ditandatangani.

📋 No. Surat: {letter_number}
📦 Paket: {package_name}
💰 Estimasi: Rp {estimasi_total}

Anda dapat mengunduh dokumen melalui aplikasi Santa Maria:
▶️ Play Store: {playstore_url}
🍎 App Store: {appstore_url}

Atau hubungi kami untuk salinan cetak.

{so_name} — Santa Maria Funeral Organizer"
```

---

## ATURAN BISNIS v1.25

```
1. PAKET STOCK-AWARE:
   → Paket dengan item CRITICAL stok = 0: TIDAK bisa dipilih (tombol disabled)
   → Paket dengan item non-critical stok kurang: bisa dipilih + warning
   → Stok dicek real-time saat consumer/SO buka halaman pilih paket
   → Item ditandai critical/non-critical di package_items.is_critical

2. SURAT PENERIMAAN LAYANAN:
   → WAJIB ada dan WAJIB ditandatangani sebelum order bisa dikonfirmasi
   → Gate: orders.acceptance_letter_id harus terisi + status 'signed'
   → SO tidak bisa bypass (tombol Konfirmasi disabled jika belum signed)

3. SIAPA YANG ISI:
   → Consumer bisa isi sendiri dari app (data auto-fill dari order)
   → SO bisa isi di depan keluarga (mode SO, lebih lengkap)
   → Walk-in: SO isi + keluarga tanda tangan di tempat

4. TANDA TANGAN:
   → PJ (penanggung jawab keluarga): WAJIB
   → Saksi: OPSIONAL (jika ada anggota keluarga lain)
   → Pihak Santa Maria (SO): WAJIB jika diisi oleh SO
   → Tanda tangan digital via flutter_signature_pad

5. PDF:
   → Auto-generate setelah semua tanda tangan selesai
   → Bisa di-download dari app Consumer dan SO
   → Bisa dikirim via WA (template WA baru)
   → Tersimpan di R2 sebagai arsip permanen

6. S&K (Syarat & Ketentuan):
   → Disimpan di tabel terms_and_conditions (versioning)
   → Super Admin bisa buat versi baru kapan saja (v1.27: Owner view only)
   → Consumer/SO lihat versi yang is_current saat mengisi surat
   → Versi yang disetujui consumer tersimpan di surat (terms_version)

7. PERUBAHAN SETELAH SIGNED:
   → Jika paket berubah setelah surat ditandatangani → surat harus dibuat ulang
   → Status surat kembali ke 'draft' → perlu tanda tangan ulang
   → Perubahan add-on/amendment setelah konfirmasi: tidak perlu surat ulang
     (sudah di-cover oleh order_amendments + extra_approvals)
```

---

---

# SANTA MARIA — PATCH v1.26
# Owner: Hapus Kelola Paket, Armada Real-time Map | Status Order Granular untuk Consumer

---

## FIX 1: OWNER TIDAK BISA KELOLA PAKET

Manajemen paket (CRUD) hanya boleh dilakukan oleh **Super Admin**. Owner bisa **lihat** paket tapi **tidak bisa** tambah/edit/hapus.

### Perubahan di Super Admin Screen

```
lib/features/admin/screens/
  └── master_data_screen.dart
        -- [Paket Layanan] ← HANYA Super Admin
        -- [Template Rute per Paket] ← HANYA Super Admin
        -- Semua master data lain: Owner + Super Admin
```

### Perubahan Akses API

```
-- PAKET — Super Admin ONLY:
POST   /admin/packages                            -- buat paket baru
PUT    /admin/packages/{id}                       -- edit paket
DELETE /admin/packages/{id}                       -- soft-delete

-- PAKET — Read (semua role boleh):
GET    /packages                                  -- list paket (Consumer, SO, Owner, dll)
GET    /packages/{id}                             -- detail paket
GET    /packages?check_stock=true                 -- stock-aware listing

-- Owner TIDAK bisa akses POST/PUT/DELETE /admin/packages
-- Backend: middleware cek role === 'super_admin' untuk mutasi paket
```

### Perubahan di Owner Dashboard

Owner tetap bisa **lihat** paket yang tersedia (read-only) tapi TIDAK ada tombol tambah/edit.

```
lib/features/owner/screens/
  └── owner_packages_view_screen.dart          -- BARU: read-only view paket
        -- List semua paket + harga + stock_status
        -- TANPA tombol: [Tambah] [Edit] [Hapus]
        -- Hanya informasi: "Paket apa saja yang tersedia saat ini"
```

---

## FIX 2: OWNER ARMADA REAL-TIME MAP

Owner bisa lihat SEMUA kendaraan di peta secara real-time — posisi GPS, status, driver, order.

### Konsep

```
Owner buka "Armada" → MAP PENUH layar

┌──────────────────────────────────────────────────────────────┐
│  🗺️ PETA REAL-TIME ARMADA                                    │
│                                                              │
│  [Map Google Maps - Full Screen]                             │
│                                                              │
│    📍 MBL-01 (H-1234-AB)          ← marker hijau (available)│
│       Di: Gudang SM                                          │
│                                                              │
│    🚗 MBL-02 (H-5678-CD)          ← marker biru (in_use)    │
│       Driver: Anto — Order SM-20260414-0001                  │
│       Status: Menuju Rumah Duka (Leg 2/5)                    │
│       Speed: 45 km/h                                         │
│                                                              │
│    🔧 VAN-01 (H-9012-EF)          ← marker merah (maintenance)│
│       Status: Servis di Bengkel                              │
│                                                              │
│    🚗 BUS-01 (H-7890-IJ)          ← marker biru (in_use)    │
│       Driver: Dedi — Order SM-20260415-0002                  │
│       Status: Antar Jenazah ke Pemakaman (Leg 4/4)           │
│                                                              │
│  ──────────────────────────────────────────────────────────  │
│  Filter: [Semua ▼] [Available ▼] [In Use ▼] [Maintenance ▼]│
│  Kendaraan: 5 total | 2 tersedia | 2 bertugas | 1 servis    │
└──────────────────────────────────────────────────────────────┘

Tap marker kendaraan → bottom sheet detail:
┌──────────────────────────────────────────────────────────────┐
│  🚗 MBL-02 — Toyota HiAce (H-5678-CD)                       │
│  ─────────────────────────────────────────────────────────── │
│  Driver    : Anto Driver                                     │
│  Order     : SM-20260414-0001 (Keluarga Bpk. Yohanes)       │
│  Tugas     : Leg 2/5 — Jemput Jenazah                       │
│  Status    : Menuju RS Telogorejo                            │
│  Kecepatan : 45 km/h                                         │
│  KM Hari Ini: 23 km                                          │
│  BBM Terakhir: 35 liter (10.2 km/l)                          │
│  ─────────────────────────────────────────────────────────── │
│  [📋 Lihat Order] [📱 WA Driver] [📍 Rute Lengkap]          │
└──────────────────────────────────────────────────────────────┘
```

### Tabel `driver_location_logs` (GPS Log Driver Real-time)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
driver_id UUID REFERENCES users(id)
vehicle_id UUID NULLABLE REFERENCES vehicles(id)
order_id UUID NULLABLE REFERENCES orders(id)

latitude DECIMAL(10,7) NOT NULL
longitude DECIMAL(10,7) NOT NULL
speed_kmh DECIMAL(6,2) NULLABLE              -- kecepatan saat ini
heading DECIMAL(5,2) NULLABLE                -- arah (0-360 derajat)
accuracy_meters DECIMAL(8,2) NULLABLE

recorded_at TIMESTAMP NOT NULL DEFAULT NOW()
created_at TIMESTAMP

-- Index untuk query cepat:
-- CREATE INDEX idx_driver_location_latest ON driver_location_logs (driver_id, recorded_at DESC)
```

### Backend: Driver Kirim Lokasi Berkala

```php
// Driver app kirim lokasi setiap 30 detik saat status On Duty
// Via Pusher channel (real-time) + batch save ke DB setiap 5 menit

// Channel: private-driver.{driver_id}
// Event: location-update
// Payload: { lat, lng, speed, heading, accuracy, vehicle_id, order_id }

// Owner subscribe ke: private-fleet
// → Terima semua driver location updates di satu channel
```

### API — Owner Armada Real-time

```
### Owner — Real-time Fleet Map
GET    /owner/fleet/live                          -- posisi terkini semua kendaraan in_use
  Response: [
    { vehicle_id, plate_number, vehicle_name, status,
      driver: { id, name, phone },
      order: { id, order_number, almarhum_name },
      current_leg: { sequence, leg_name, status, origin, destination },
      location: { lat, lng, speed_kmh, heading, updated_at },
      km_today, fuel_efficiency_avg }
  ]

GET    /owner/fleet/live/{vehicleId}              -- detail 1 kendaraan + riwayat rute hari ini
GET    /owner/fleet/live/{vehicleId}/route        -- polyline rute yang sudah ditempuh hari ini

### Pusher — Real-time Channel
-- Owner subscribe: private-fleet
-- Events: driver-location-update, driver-status-change, vehicle-status-change
```

### Flutter — Screen Owner Armada

```
lib/features/owner/screens/
  ├── fleet_map_screen.dart                    -- BARU: peta real-time armada
  │     -- Google Maps full screen
  │     -- Marker per kendaraan (warna sesuai status)
  │     -- Pusher listener: update marker posisi real-time
  │     -- Filter: status kendaraan
  │     -- Tap marker → bottom sheet detail
  │     -- Polyline rute yang sudah ditempuh (jika in_use)
  │
  └── fleet_detail_bottom_sheet.dart           -- BARU: detail kendaraan (tap marker)
        -- Info kendaraan + driver + order + leg saat ini
        -- Tombol: lihat order, WA driver, lihat rute lengkap

lib/features/driver/services/
  └── location_tracking_service.dart           -- PERKAYA: kirim lokasi berkala
        -- Geolocator stream setiap 30 detik
        -- Kirim via Pusher channel
        -- Batch save ke API setiap 5 menit
        -- Hanya aktif saat driver On Duty (clock-in + ada assignment)
```

---

## FIX 3: STATUS ORDER GRANULAR — CONSUMER TAHU SETIAP LANGKAH

### Masalah Sebelumnya

```
Consumer lihat status: "Dalam Proses" ← dari 'confirmed' sampai 'completed' = SATU status
Consumer tidak tahu:
  - Apakah barang sudah dikirim?
  - Apakah driver sudah berangkat jemput jenazah?
  - Apakah dekorasi sudah dipasang?
  - Apakah jenazah sudah tiba?
```

### Status Order ENUM — Diperkaya (Menggantikan v1.13)

```sql
-- GANTI ENUM status di tabel orders:
status ENUM(
  'pending',              -- 1. Baru masuk dari consumer/SO
  'awaiting_signature',   -- 2. Menunggu tanda tangan surat penerimaan (v1.25)
  'so_review',            -- 3. SO sedang verifikasi data & pilih paket
  'confirmed',            -- 4. SO konfirmasi — Gudang, Purchasing, Vendor dinotif
  'preparing',            -- 5. Gudang sedang siapkan barang & peralatan
  'ready_to_dispatch',    -- 6. Gudang siap — menunggu driver di-assign
  'driver_assigned',      -- 7. Driver sudah di-assign + kendaraan
  'delivering_equipment', -- 8. Driver sedang antar barang ke lokasi
  'equipment_arrived',    -- 9. Barang tiba — dekorasi dimulai
  'picking_up_body',      -- 10. Driver sedang jemput jenazah
  'body_arrived',         -- 11. Jenazah tiba di lokasi prosesi
  'in_ceremony',          -- 12. Prosesi sedang berlangsung
  'heading_to_burial',    -- 13. Menuju pemakaman/krematorium
  'burial_completed',     -- 14. Pemakaman/kremasi selesai
  'returning_equipment',  -- 15. Barang sedang dikembalikan ke gudang
  'completed',            -- 16. Order selesai — menunggu payment
  'cancelled'
) DEFAULT 'pending'
```

### Mapping Status ↔ Trigger (Kapan Status Berubah)

```
pending              → Consumer/SO submit order
awaiting_signature   → Paket dipilih, surat penerimaan dibuat (v1.25)
so_review            → Surat ditandatangani, SO mulai review
confirmed            → SO tekan "Konfirmasi" (STEP 2)
preparing            → Gudang mulai proses checklist peralatan (STEP 3)
ready_to_dispatch    → Gudang tekan "Stok Siap Angkut" (STEP 4)
driver_assigned      → Sistem auto-assign driver + kendaraan
delivering_equipment → Driver berangkat dari Gudang (leg ANTAR_BARANG departed)
equipment_arrived    → Driver tiba di lokasi + barang diturunkan (gate Dekor)
picking_up_body      → Driver berangkat jemput jenazah (leg JEMPUT_JENAZAH departed)
body_arrived         → Jenazah tiba di lokasi prosesi
in_ceremony          → Prosesi dimulai (scheduled_at tercapai ATAU SO manual trigger)
heading_to_burial    → Driver berangkat ke pemakaman (leg ANTAR_JENAZAH_PMK departed)
burial_completed     → Pemakaman/kremasi selesai (leg completed)
returning_equipment  → Driver berangkat angkut barang kembali (leg ANGKUT_KEMBALI departed)
completed            → Semua leg selesai + auto-complete (time-based)
```

### Consumer Tracking — Label & Icon per Status

```
┌──────────────────────────────────────────────────────────┐
│ ORDER SM-20260414-0001                                   │
│ Almarhum: Bpk. Yohanes Surya                            │
│                                                          │
│ ✅ 1. Order Diterima                         14 Apr 07:30│
│ ✅ 2. Surat Layanan Ditandatangani           14 Apr 07:32│
│ ✅ 3. Dikonfirmasi SO                        14 Apr 07:35│
│ ✅ 4. Tim Menyiapkan Perlengkapan            14 Apr 07:36│
│ ✅ 5. Perlengkapan Siap Dikirim              14 Apr 08:30│
│ ✅ 6. Driver Ditugaskan (H-1234-AB)          14 Apr 08:31│
│ ✅ 7. Perlengkapan Dalam Perjalanan          14 Apr 08:35│
│ ✅ 8. Perlengkapan Tiba di Lokasi            14 Apr 09:00│
│ 🔵 9. Driver Menjemput Jenazah              14 Apr 09:05│
│ ⏳ 10. Jenazah Tiba                                      │
│ ⏳ 11. Prosesi Berlangsung                               │
│ ⏳ 12. Menuju Pemakaman                                  │
│ ⏳ 13. Pemakaman Selesai                                 │
│ ⏳ 14. Pengembalian Peralatan                            │
│ ⏳ 15. Layanan Selesai                                   │
│                                                          │
│ 📍 [Lacak Driver Real-time]                              │
└──────────────────────────────────────────────────────────┘
```

### Tabel `order_status_labels` (Label Status — Dinamis)

Label status TIDAK di-hardcode di Flutter — dikelola sebagai master data.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
status_code VARCHAR(50) UNIQUE NOT NULL       -- sama dengan ENUM status di orders
consumer_label VARCHAR(255) NOT NULL          -- label yang dilihat consumer
consumer_description TEXT NULLABLE            -- penjelasan detail untuk consumer
internal_label VARCHAR(255) NOT NULL          -- label untuk internal (SO, Owner, dll)
icon VARCHAR(50) NOT NULL                     -- icon Flutter: 'check_circle', 'local_shipping', dll
color VARCHAR(20) NOT NULL                    -- hex color: '#00B894', '#0984E3'
sort_order SMALLINT NOT NULL
show_to_consumer BOOLEAN DEFAULT TRUE         -- apakah ditampilkan ke consumer?
show_map_tracking BOOLEAN DEFAULT FALSE       -- apakah tampilkan peta tracking di status ini?
is_active BOOLEAN DEFAULT TRUE
created_at TIMESTAMP
updated_at TIMESTAMP
```

Seed:
```
pending             | "Order Diterima"                | "Pesanan Anda telah kami terima dan sedang menunggu konfirmasi"         | 📋 | #B2BEC3 | show_map: false
awaiting_signature  | "Menunggu Tanda Tangan"          | "Silakan tanda tangani Surat Penerimaan Layanan di aplikasi"           | ✍️ | #FDCB6E | show_map: false
so_review           | "Sedang Direview"                | "Tim kami sedang memverifikasi data dan mempersiapkan layanan"         | 🔍 | #0984E3 | show_map: false
confirmed           | "Dikonfirmasi"                   | "Layanan telah dikonfirmasi. Tim kami mulai berkoordinasi"             | ✅ | #00B894 | show_map: false
preparing           | "Menyiapkan Perlengkapan"        | "Tim gudang sedang menyiapkan seluruh perlengkapan prosesi"           | 📦 | #6C5CE7 | show_map: false
ready_to_dispatch   | "Siap Dikirim"                   | "Perlengkapan siap. Menunggu driver berangkat"                        | 🚛 | #00CEC9 | show_map: false
driver_assigned     | "Driver Ditugaskan"              | "Driver {driver_name} dengan kendaraan {plate_number} siap berangkat" | 🚗 | #2D3436 | show_map: true
delivering_equipment| "Perlengkapan Dalam Perjalanan"  | "Perlengkapan prosesi sedang dalam perjalanan ke lokasi"              | 🚚 | #0984E3 | show_map: true
equipment_arrived   | "Perlengkapan Tiba"              | "Perlengkapan telah tiba. Tim dekorasi sedang mempersiapkan lokasi"   | 📍 | #00B894 | show_map: false
picking_up_body     | "Menjemput Jenazah"              | "Driver sedang menuju lokasi untuk menjemput jenazah"                 | 🚗 | #E84393 | show_map: true
body_arrived        | "Jenazah Tiba"                   | "Jenazah telah tiba di lokasi prosesi"                                | 🙏 | #6D4C41 | show_map: false
in_ceremony         | "Prosesi Berlangsung"            | "Prosesi pemakaman sedang berlangsung"                                | ⛪ | #6C5CE7 | show_map: false
heading_to_burial   | "Menuju Pemakaman"               | "Rombongan sedang menuju tempat pemakaman"                            | 🚗 | #2D3436 | show_map: true
burial_completed    | "Pemakaman Selesai"              | "Prosesi pemakaman telah selesai dilaksanakan"                        | 🕊️ | #636E72 | show_map: false
returning_equipment | "Pengembalian Peralatan"         | "Peralatan sedang dikembalikan ke gudang"                             | 🔄 | #B2BEC3 | show_map: false | show_to_consumer: false
completed           | "Layanan Selesai"                | "Seluruh layanan telah selesai. Silakan lakukan pembayaran"           | ✨ | #00B894 | show_map: false
cancelled           | "Dibatalkan"                     | "Pesanan telah dibatalkan"                                            | ❌ | #D63031 | show_map: false
```

### Sinkronisasi: Trip Leg → Order Status

```php
// Setiap kali status trip leg berubah → auto-update orders.status

class OrderStatusSyncService
{
  public function syncFromTripLeg(OrderDriverAssignment $leg): void
  {
    $order = $leg->order;
    $legMaster = $leg->legMaster;

    // Mapping: leg status + leg category → order status
    $newStatus = match(true) {
      // Leg departed
      $leg->status === 'departed' && $legMaster->category === 'logistics'
        => 'delivering_equipment',

      $leg->status === 'departed' && $legMaster->leg_code === 'JEMPUT_JENAZAH'
        => 'picking_up_body',

      $leg->status === 'departed' && in_array($legMaster->leg_code, ['ANTAR_JENAZAH_PMK','ANTAR_JENAZAH_KRM'])
        => 'heading_to_burial',

      $leg->status === 'departed' && $legMaster->leg_code === 'ANGKUT_KEMBALI'
        => 'returning_equipment',

      // Leg arrived/completed
      $leg->status === 'completed' && $legMaster->leg_code === 'ANTAR_BARANG'
        => 'equipment_arrived',

      $leg->status === 'completed' && $legMaster->leg_code === 'JEMPUT_JENAZAH'
        => 'body_arrived', // ATAU 'picking_up_body' tergantung apakah ada leg antar ke RD

      $leg->status === 'completed' && str_starts_with($legMaster->leg_code, 'ANTAR_JENAZAH')
        => $this->isLastBodyLeg($order, $leg) ? 'body_arrived' : $order->status,

      $leg->status === 'completed' && in_array($legMaster->leg_code, ['ANTAR_JENAZAH_PMK','ANTAR_JENAZAH_KRM'])
        => 'burial_completed',

      default => $order->status, // tidak berubah
    };

    if ($newStatus !== $order->status) {
      $order->update(['status' => $newStatus]);

      OrderStatusLog::create([
        'order_id' => $order->id,
        'from_status' => $order->status,
        'to_status' => $newStatus,
        'notes' => "Auto-sync dari trip leg: {$legMaster->leg_name} ({$leg->status})",
      ]);

      // Kirim notif ke consumer sesuai label
      $label = OrderStatusLabel::where('status_code', $newStatus)->first();
      if ($label && $label->show_to_consumer) {
        NotificationService::send($order->pic_user_id, 'HIGH',
          $label->consumer_label,
          $label->consumer_description
        );
      }
    }
  }
}
```

### Update `in_ceremony` — SO Manual Trigger

```
Status 'in_ceremony' tidak otomatis dari trip leg — karena prosesi dimulai
bukan saat driver tiba, tapi saat acara benar-benar mulai.

Dua cara trigger:
  A. OTOMATIS: scheduled_at tercapai DAN body_arrived sudah → in_ceremony
  B. MANUAL: SO tekan "Prosesi Dimulai" di app

Endpoint:
  PUT /so/orders/{id}/ceremony-start
```

### Update Auto-Complete Logic

```php
// SEBELUM:
->where('driver_overall_status', 'all_done')

// SESUDAH:
// Auto-complete lebih cerdas:
// Cek: semua leg completed + waktu lewat + status sudah burial_completed
->whereIn('status', ['burial_completed', 'returning_equipment'])
->where('driver_overall_status', 'all_done')
// ATAU: waktu lewat scheduled_at + estimated_duration_hours + semua leg done
```

### Flutter — Consumer Tracking Screen Diperkaya

```
lib/features/consumer/screens/
  └── order_detail_screen.dart                 -- PERKAYA
        -- Vertical stepper / timeline:
        -- Setiap status dari order_status_labels yang show_to_consumer=true
        -- Status selesai: ✅ hijau + timestamp
        -- Status aktif: 🔵 biru + animasi pulse
        -- Status pending: ⏳ abu-abu
        --
        -- Jika status punya show_map_tracking=true:
        --   Tampilkan mini-map di bawah status tersebut
        --   Peta real-time posisi driver (Pusher)
        --   Consumer subscribe: private-order.{order_id}
        --
        -- Consumer description muncul di bawah setiap label
        -- Placeholder {driver_name}, {plate_number} di-replace real-time
```

---

## ATURAN BISNIS v1.26

```
1. OWNER TIDAK BISA KELOLA PAKET:
   → POST/PUT/DELETE /admin/packages → 403 Forbidden untuk role owner
   → Hanya Super Admin yang bisa CRUD paket
   → Owner bisa lihat (GET) semua paket + stok status (read-only)

2. ARMADA REAL-TIME MAP:
   → Driver kirim GPS setiap 30 detik saat On Duty (clock-in + ada assignment)
   → Data disimpan di driver_location_logs (batch setiap 5 menit)
   → Owner lihat semua kendaraan di 1 peta via Pusher real-time
   → Consumer lihat 1 driver yang assigned ke order mereka

3. STATUS ORDER GRANULAR (17 status):
   → Label per status dikelola di order_status_labels (bisa diubah Owner)
   → Setiap perubahan status → auto-notif consumer dengan label yang tepat
   → Consumer lihat timeline step-by-step di app
   → Status otomatis berubah berdasarkan trip leg + Gudang action + SO trigger
   → 'in_ceremony' bisa auto (scheduled_at) atau manual (SO trigger)

4. SHOW MAP TRACKING:
   → Consumer hanya lihat peta di status tertentu: driver_assigned,
     delivering_equipment, picking_up_body, heading_to_burial
   → Di status lain: peta tidak tampil (tidak relevan)

5. STATUS RETURNING_EQUIPMENT:
   → show_to_consumer=false → consumer TIDAK perlu tahu proses internal ini
   → Dari sisi consumer: setelah burial_completed langsung ke completed
```

---

---

# SANTA MARIA — PATCH v1.27
# Klarifikasi: Owner = View Only, Super Admin = Bisa Semuanya

---

## PRINSIP FUNDAMENTAL v1.27

```
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║  OWNER = MONITOR / VIEW ONLY                                      ║
║  ─────────────────────────────                                    ║
║  Owner HANYA bisa MELIHAT dan MEMANTAU.                           ║
║  TIDAK bisa: create, edit, delete, approve, reject, konfigurasi.  ║
║  Semua endpoint Owner = GET only (read-only).                     ║
║  Fungsi: dashboard monitoring, laporan, tracking real-time.       ║
║                                                                   ║
║  SUPER ADMIN = BISA SEMUANYA                                      ║
║  ────────────────────────────                                     ║
║  Super Admin bisa melakukan SEMUA yang bisa dilakukan role lain.  ║
║  Termasuk: semua endpoint SO, Gudang, Purchasing, HRD, Driver,    ║
║  Owner, + administrasi sistem (user management, master data,      ║
║  threshold, konfigurasi).                                         ║
║  Super Admin = GOD MODE.                                          ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
```

---

## PERUBAHAN: OWNER → VIEW ONLY

### Endpoint Owner — SEMUA Harus GET (Read-Only)

```
-- ⛔ HAPUS — Owner TIDAK boleh punya endpoint PUT/POST/DELETE:
-- PUT    /owner/thresholds/{key}    ← HAPUS (pindah ke Super Admin only)

-- ✅ TETAP — Semua endpoint GET Owner:
GET    /owner/hrd/violations                       -- lihat pelanggaran
GET    /owner/stock/alerts                         -- alert stok
GET    /owner/stock/summary                        -- ringkasan stok
GET    /owner/attendances/summary                  -- ringkasan presensi
GET    /owner/daily-reports                        -- laporan harian
GET    /owner/kpi/summary                          -- ringkasan KPI
GET    /owner/kpi/scores/user/{userId}             -- KPI per user
GET    /owner/kpi/rankings                         -- ranking KPI
GET    /owner/vehicles/summary                     -- dashboard armada
GET    /owner/vehicles/{id}/history                -- riwayat kendaraan
GET    /owner/vehicles/fuel-report                 -- laporan BBM
GET    /owner/vehicles/maintenance-report          -- laporan maintenance
GET    /owner/fleet/live                           -- peta armada real-time
GET    /owner/fleet/live/{vehicleId}               -- detail kendaraan live
GET    /owner/attendance/summary                   -- presensi summary
GET    /owner/attendance/realtime                  -- siapa sudah clock-in
GET    /owner/vehicle-trip-logs/summary            -- laporan biaya armada
GET    /owner/orders                               -- semua order (read-only)
GET    /owner/orders/{id}                          -- detail order
GET    /owner/billing/summary                      -- ringkasan billing
GET    /owner/procurement/summary                  -- ringkasan pengadaan
GET    /owner/reports/monthly                      -- laporan bulanan
GET    /owner/reports/trend                        -- trend tahunan

-- Owner TIDAK bisa akses /admin/* endpoint (itu Super Admin only)
-- Owner TIDAK bisa submit apapun
```

### Hal yang Dipindah dari Owner → Super Admin

| Sebelumnya Owner Bisa | Sekarang | Yang Handle |
|----------------------|----------|-------------|
| Edit threshold (`PUT /owner/thresholds/{key}`) | ⛔ Hapus | Super Admin only |
| Kelola master data (CRUD via `/admin/master/*`) | ⛔ Hapus akses Owner | Super Admin only |
| Kelola metrik KPI | ⛔ Hapus | HRD + Super Admin |
| Edit template WA | ⛔ Hapus | Super Admin only |
| Edit S&K (terms) | ⛔ Hapus | Super Admin only |
| Edit label status order | ⛔ Hapus | Super Admin only |
| Buat versi S&K baru | ⛔ Hapus | Super Admin only |
| Override inspeksi kendaraan | ⛔ Hapus | Gudang + Super Admin |
| Buat procurement request | ⛔ Hapus | Role lain tetap bisa |

---

## PERUBAHAN: SUPER ADMIN = GOD MODE

### Konsep

```
Super Admin memiliki akses UNION dari SEMUA role:

Super Admin can access:
  ├── /admin/*              (sistem: user management, master data, threshold, dll)
  ├── /so/*                 (semua yang SO bisa)
  ├── /gudang/*             (semua yang Gudang bisa)
  ├── /purchasing/*         (semua yang Purchasing bisa)
  ├── /driver/*             (semua yang Driver bisa — kecuali GPS tracking pribadi)
  ├── /hrd/*                (semua yang HRD bisa)
  ├── /security/*           (semua yang Security bisa)
  ├── /owner/*              (semua dashboard monitoring)
  ├── /vendor/*             (semua yang vendor bisa)
  ├── /consumer/*           (semua yang consumer bisa — debug/support)
  ├── /supplier/*           (semua yang supplier bisa — debug/support)
  └── /procurement-requests (buat pengadaan)

Implementasi backend:
  → Middleware: jika role = 'super_admin' → skip semua role check → akses granted
  → Super Admin bisa "impersonate" role lain untuk debugging
```

### API — Super Admin Tambahan

```
### Super Admin — Impersonate (untuk debugging/support)
POST   /admin/impersonate/{userId}                -- login sebagai user lain (sementara)
DELETE /admin/impersonate                          -- kembali ke akun Super Admin
-- Semua aksi saat impersonate tercatat di audit log dengan flag impersonated_by

### Super Admin — Semua Master Data (sudah ada, dipertegas)
GET/POST/PUT/DELETE /admin/master/{entity}        -- CRUD semua master data
GET/POST/PUT/DELETE /admin/packages               -- CRUD paket
GET/POST/PUT/DELETE /admin/packages/{id}/trip-template -- template rute
PUT    /admin/thresholds/{key}                    -- ubah threshold
POST   /admin/terms-and-conditions                -- buat S&K baru
PUT    /admin/terms-and-conditions/{id}/activate   -- aktifkan S&K
PUT    /admin/wa-templates/{id}                   -- edit template WA
PUT    /admin/order-status-labels/{id}            -- edit label status

### Super Admin — Sistem
GET    /admin/system/health                        -- cek kesehatan sistem
GET    /admin/system/queues                        -- status queue/job
GET    /admin/system/scheduler-runs                -- log scheduler
POST   /admin/system/cache-clear                   -- clear cache
```

---

## FIX: SEMUA REFERENSI OWNER WRITE → SUPER ADMIN

Berikut daftar semua tempat yang diubah:

```
1. "Owner bisa ubah threshold"
   → SEBELUM: PUT /owner/thresholds/{key}
   → SESUDAH: PUT /admin/thresholds/{key} (Super Admin only)

2. "HRD/Owner set KPI metrik"
   → SESUDAH: HRD + Super Admin set KPI metrik. Owner hanya lihat.

3. "dikelola Owner/Gudang via UI"
   → SESUDAH: dikelola Super Admin/Gudang via UI. Owner lihat saja.

4. "Owner bisa edit template WA"
   → SESUDAH: Super Admin bisa edit. Owner lihat saja.

5. "Owner bisa buat versi S&K baru"
   → SESUDAH: Super Admin bisa buat. Owner lihat saja.

6. "Label status dikelola Owner"
   → SESUDAH: Super Admin kelola. Owner lihat saja.

7. "Gudang/Owner bisa override inspeksi"
   → SESUDAH: Gudang/Super Admin bisa override.

8. "Owner bisa buat procurement request"
   → SESUDAH: Owner TIDAK bisa. Role lain tetap bisa.

9. "Owner + HRD bisa LIHAT audit trail (read-only, v1.27)"
   → SESUDAH: Owner bisa LIHAT audit trail (GET). Tidak bisa ubah.

10. Semua "Owner/SO bisa tambah..."
    → SESUDAH: SO + Super Admin bisa tambah. Owner view only.
```

---

## Flutter — Owner Screen (View Only)

```
lib/features/owner/screens/
  ├── owner_dashboard.dart                     -- Dashboard monitoring utama
  │     -- Card: Order Hari Ini (aktif / selesai / pending)
  │     -- Card: Pendapatan Bulan Ini (total, avg per order)
  │     -- Card: Armada (available / in_use / maintenance)
  │     -- Card: Karyawan (hadir / belum / absent hari ini)
  │     -- Card: KPI Summary (distribusi grade A/B/C/D/E)
  │     -- Card: Pengadaan (pending approval, overdue)
  │     -- SEMUA card = read-only, tap untuk detail
  │     -- TIDAK ADA tombol action (create, edit, approve, dll)
  │
  ├── owner_order_list_screen.dart             -- List semua order (read-only)
  │     -- Filter: status, tanggal, SO
  │     -- Tap → detail order (view only, tanpa tombol aksi)
  │
  ├── owner_order_detail_screen.dart           -- Detail order (read-only)
  │     -- Semua info: data almarhum, paket, vendor, billing, presensi
  │     -- Timeline status granular (17 status)
  │     -- TIDAK ADA: tombol konfirmasi, edit, approve, dll
  │
  ├── fleet_map_screen.dart                    -- Peta armada real-time (v1.26)
  │     -- View only, tap marker untuk info
  │
  ├── owner_kpi_screen.dart                    -- KPI summary (view only)
  │     -- Distribusi grade, ranking, trend
  │     -- TIDAK ADA: tombol edit metrik, ubah bobot
  │
  ├── owner_attendance_screen.dart             -- Presensi hari ini (view only)
  │     -- Siapa hadir, siapa belum, siapa absent
  │     -- TIDAK ADA: tombol override, edit status
  │
  ├── owner_violations_screen.dart             -- Pelanggaran (view only)
  │     -- List violations, filter severity
  │     -- TIDAK ADA: tombol resolve, acknowledge, eskalasi
  │
  ├── owner_billing_screen.dart                -- Ringkasan billing (view only)
  │     -- Total pendapatan, per order, per bulan
  │     -- TIDAK ADA: tombol edit, finalize, export
  │
  ├── owner_procurement_screen.dart            -- Status pengadaan (view only)
  │     -- List procurement requests + status
  │     -- TIDAK ADA: tombol approve, reject
  │
  ├── owner_reports_screen.dart                -- Laporan (view only)
  │     -- Monthly, trend, per-supplier, per-karyawan
  │     -- Grafik + tabel
  │
  └── owner_packages_view_screen.dart          -- Paket tersedia (view only, v1.26)
```

---

## Flutter — Super Admin Screen (God Mode)

```
lib/features/admin/screens/
  ├── admin_dashboard.dart                     -- Overview sistem + akses ke semua
  │     -- SEMUA yang ada di Owner Dashboard
  │     -- PLUS: system health, queue status, scheduler runs
  │     -- PLUS: tombol navigasi ke SETIAP fitur role lain
  │
  ├── impersonate_screen.dart                  -- BARU: login sebagai user lain
  │     -- List user → tap → "Login sebagai [nama]"
  │     -- Banner merah di atas: "Anda sedang login sebagai [nama] ([role])"
  │     -- Tombol: "Kembali ke Super Admin"
  │     -- Semua aksi tercatat di audit log
  │
  ├── user_management_screen.dart              -- CRUD user (sudah ada)
  ├── master_data_screen.dart                  -- Hub master data (sudah ada, dipertegas)
  │     -- SEMUA master data termasuk Paket, Template Rute
  │     -- Super Admin lihat SEMUA tombol
  │
  ├── system_threshold_screen.dart             -- Kelola threshold (dipindah dari Owner)
  ├── system_log_screen.dart                   -- Audit log
  │
  ├── role_switcher_widget.dart                -- BARU: quick-switch ke fitur role lain
  │     -- Dropdown: "Akses sebagai: [SO ▼]"
  │     -- Pilih role → navigasi ke home screen role tersebut
  │     -- Super Admin bisa akses SEMUA screen role lain
  │
  └── system_health_screen.dart                -- BARU: kesehatan sistem
        -- Queue: pending jobs, failed jobs
        -- Scheduler: last run per command
        -- Storage: R2 usage
        -- Database: connection pool, slow queries
        -- Cache: hit rate, memory usage
```

---

## Route Guard — Updated v1.27

```dart
switch (user.role) {
  case 'super_admin'     : → AdminDashboard      // GOD MODE — akses semua
  case 'consumer'        : → ConsumerHome
  case 'service_officer' : → SOHome
  case 'gudang'          : → GudangHome
  case 'purchasing'      : → PurchasingHome
  case 'driver'          : → DriverHome
  case 'supplier'        : → SupplierHome
  case 'dekor'           : → VendorHome
  case 'konsumsi'        : → VendorHome
  case 'pemuka_agama'    : → VendorHome
  case 'tukang_foto'     : → VendorHome
  case 'owner'           : → OwnerDashboard       // VIEW ONLY — monitoring
  case 'hrd'             : → HrdHome
  case 'security'        : → SecurityHome
  case 'viewer'          : → ViewerDashboard       // READ ONLY — reports
}

// Middleware backend:
// if (user.role === 'super_admin') → bypass ALL role checks → access granted
// if (user.role === 'owner') → only allow GET methods → reject POST/PUT/DELETE
```

---

## ATURAN BISNIS v1.27

```
1. OWNER:
   → HANYA bisa HTTP GET (read-only)
   → TIDAK bisa POST, PUT, DELETE apapun
   → Semua screen Owner = view only, tanpa tombol aksi
   → Owner menerima notifikasi (ALARM/HIGH/NORMAL) untuk monitoring
   → Owner TIDAK bisa membuat procurement request
   → Owner TIDAK bisa mengubah threshold, master data, template, S&K
   → Owner TIDAK bisa approve/reject apapun
   → Owner = mata dan telinga perusahaan, bukan tangan

2. SUPER ADMIN:
   → Bisa akses SEMUA endpoint dari SEMUA role
   → Backend: role check di-bypass untuk super_admin
   → Bisa impersonate (login sebagai user lain) untuk debugging
   → Impersonate tercatat di audit log (tidak bisa disembunyikan)
   → Super Admin = satu-satunya yang bisa:
     - CRUD paket layanan
     - CRUD template rute per paket
     - Ubah threshold
     - Edit template WA
     - Edit label status order
     - Buat/aktifkan S&K baru
     - Manage mock app blacklist
     - Clear cache, monitor system health
     - User management (create, edit, deactivate)

3. PERBEDAAN OWNER vs VIEWER:
   → Owner: bisa lihat SEMUA data (termasuk per karyawan, per supplier, detail)
   → Viewer: hanya lihat AGGREGAT (tanpa nama karyawan, tanpa detail supplier)
   → Owner: terima alarm/notifikasi
   → Viewer: TIDAK terima alarm
```

---

## CHANGELOG v1.27

### v1.27 — Klarifikasi Owner = View Only, Super Admin = God Mode

**Owner:**
- SEMUA akses write dihapus — Owner hanya GET (read-only)
- Hapus: `PUT /owner/thresholds/{key}`, akses master data CRUD, kelola KPI, edit template
- Semua screen Owner = view only, TIDAK ada tombol aksi (create, edit, approve, dll)
- Owner tetap terima alarm/notifikasi untuk monitoring

**Super Admin:**
- God mode: bisa akses SEMUA endpoint dari SEMUA role
- Backend: `if role === 'super_admin' → bypass role check`
- Fitur impersonate: login sebagai user lain untuk debugging/support
- Satu-satunya yang bisa: CRUD paket, threshold, template WA, S&K, label status, user management
- Tambah: `impersonate_screen`, `role_switcher_widget`, `system_health_screen`

**Perbedaan Owner vs Viewer:**
- Owner: lihat SEMUA detail + terima alarm
- Viewer: lihat aggregat saja + TIDAK terima alarm

---

## CHANGELOG v1.26

### v1.26 — Owner Paket Read-only, Armada Real-time Map, Status Order Granular

**Owner:**
- Hapus akses CRUD paket → hanya Super Admin
- Owner tetap bisa lihat paket (read-only)
- Armada real-time map: full map semua kendaraan + GPS driver + detail order
- `driver_location_logs` table untuk tracking GPS

**Status Order Granular (6 → 17 status):**
- Consumer bisa lihat setiap langkah: order diterima → perlengkapan disiapkan → driver berangkat → barang tiba → jemput jenazah → jenazah tiba → prosesi → pemakaman → selesai
- `order_status_labels` table: label, deskripsi, icon, warna per status (dinamis, Super Admin bisa edit)
- Auto-sync dari trip leg → order status
- Consumer tracking: timeline visual + peta real-time saat driver di jalan
- `show_to_consumer` flag: beberapa status internal tidak perlu ditampilkan ke consumer
- `show_map_tracking` flag: peta hanya tampil di status yang relevan

---

## CHANGELOG v1.25

### v1.25 — Paket Stock-Aware + Surat Penerimaan Layanan Kematian

**Paket Stock-Aware:**
- Paket dengan stok item critical = 0 tidak bisa dipilih (disabled)
- Paket partial stok: tampil dengan warning
- `package_items.is_critical` + `minimum_required_qty` menentukan ketersediaan
- Real-time stock check di endpoint GET /packages?check_stock=true

**Surat Penerimaan Layanan Kematian:**
- Dokumen resmi WAJIB ditandatangani sebelum order bisa dikonfirmasi (GATE)
- Bisa diisi via Consumer app ATAU SO app
- 6 section: identitas PJ, data almarhum, detail layanan, lokasi, S&K, tanda tangan
- Tanda tangan digital: PJ (wajib), saksi (opsional), pihak SM (wajib jika SO isi)
- PDF auto-generate + download + kirim via WA
- S&K versioning: Super Admin bisa update kapan saja di tabel terms_and_conditions

**Tabel Baru:**
- `service_acceptance_letters` — surat penerimaan layanan kematian
- `terms_and_conditions` — syarat & ketentuan (versioning)

**Order Status ENUM baru:**
- Tambah `awaiting_signature` antara `pending` dan `so_review`

**Tabel Diperkaya:**
- `orders` + `acceptance_letter_id` (link ke surat)
- `package_items` + `is_critical`, `minimum_required_qty`

---

## CHANGELOG v1.24

### v1.24 — Vendor Assignment Dinamis + Sistem Template WhatsApp

**Vendor Assignment Dinamis:**
- Vendor di-assign via `order_vendor_assignments` (bukan kolom hardcode di orders)
- Setiap vendor bisa Internal (user app) ATAU External (consumer punya sendiri)
- Consumer bisa request vendor sendiri + berikan nomor WA saat pesan layanan
- Presensi external vendor: SO proxy check-in

**Tabel Baru (Vendor):**
- `vendor_role_master` — master jenis vendor/peran (10 jenis default, bisa ditambah)
- `order_vendor_assignments` — assignment vendor per order (internal + external)
- `order_form_vendor_requests` — preferensi vendor dari consumer saat input order

**Sistem Template WhatsApp (8 template):**
- `wa_message_templates` — master template pesan WA (Super Admin bisa edit tanpa deploy)
- `wa_message_logs` — audit trail setiap pesan WA yang dikirim
- 8 template: konfirmasi order, walk-in, vendor external, payment reminder, status update, amendment estimate, berkas akta, duka cita AI
- Tombol WA di order detail muncul dinamis sesuai context
- Placeholder auto-replace: nama, order, alamat, link app, rekening bank
- Play Store + App Store URL dari system_thresholds

**Tabel Diperkaya:**
- `field_attendances` + `vendor_assignment_id`, `ext_vendor_name`, `is_proxy_checkin`
- `orders` — hapus `tukang_foto_id` (deprecated), tambah `has_external_vendor` flag
- `system_thresholds` + app_playstore_url, app_appstore_url, office_phone, company_bank_*

---

## CHANGELOG v1.23

### v1.23 — Audit Fix: Security, Viewer, Super Admin, Consumer, Konsolidasi Alarm

**Security (dari kosong → lengkap):**
- 4 tabel baru: `security_incident_logs`, `security_key_handovers`, `security_patrol_master`, `security_patrols`
- 5 fungsi: monitoring kehadiran, log insiden/visitor, serah terima kunci, patroli checklist
- 6 screen Flutter: dashboard, incident form/list, key handover, patrol, history
- 5 KPI metrik: attendance, patrol completion, incident response, key compliance, violations
- Integrasi: kunci ↔ driver (kendaraan), insiden ↔ HRD, patroli ↔ owner

**Viewer (dari vague → jelas):**
- Definisi eksplisit: apa yang BISA dan TIDAK BISA dilihat
- 5 endpoint read-only (dashboard, orders sanitized, reports, trend, KPI summary)
- 3 screen Flutter (dashboard, order list, report)

**Super Admin (screen structure):**
- 5 screen: dashboard, user management, master data hub, threshold config, system log

**Consumer (screen eksplisit):**
- 8 screen: home, order form (6 step), order list, detail, tracking, payment, amendment, profile

**Pemuka Agama (screen detail):**
- 3 screen: assignment list, ceremony detail + checklist, schedule calendar

**HRD (KPI screen eksplisit):**
- 4 screen tambahan: metric manage, period manage, shift assignment, location manage

**Konsolidasi Alarm:**
- 1 master alarm reference table menggantikan 5 tabel terpisah
- ~50 alarm rules terkonsolidasi per kategori

**Vehicle Maintenance → Purchasing:**
- Flow lengkap: driver lapor → gudang review → procurement jika perlu biaya → purchasing approve

---

## CHANGELOG v1.22

### v1.22 — Order Amendment: Layanan Tambahan di Tengah Prosesi

**Konsep:**
- Request tambahan bisa kapan saja selama order berlangsung (STEP 2-7)
- Bisa dari Consumer app, SO input, atau SO atas nama keluarga
- Satu request otomatis trigger: persetujuan biaya → deduct stok → kirim barang → notif vendor → update billing
- Bisa banyak amendment per order, setiap punya lifecycle sendiri

**Tabel Baru:**
- `order_amendments` — orchestrator: status lifecycle 10 fase, urgency, tanda tangan keluarga
- `order_amendment_items` — detail per item: 7 jenis (add, upgrade, swap, extend, add_vendor, add_qty, custom)

**Jenis Item Amendment:**
- `add_item` — tambah item baru (bunga, catering, tenda)
- `upgrade_item` — upgrade ke yang lebih baik (peti, sound)
- `swap_item` — tukar item (sound kecil → besar)
- `add_quantity` — tambah qty existing (air putih +5)
- `extend_duration` — perpanjang durasi
- `add_vendor` — tambah vendor baru (musisi)
- `custom` — lain-lain

**Integrasi otomatis:**
- Stok: auto-deduct saat approved
- Billing: auto-add ke order_billing_items (source: 'amendment')
- Driver: auto-create trip leg baru untuk kirim barang tambahan
- Vendor: auto-notif Dekor/Konsumsi/dll sesuai kategori
- Purchasing: auto-notif biaya baru

---

## CHANGELOG v1.21

### v1.21 — Purchasing Fix: PO, Billing, Supplier Account, Payment Audit

**Fix Blocker:**
- PO = procurement_request (bukan tabel terpisah). `is_direct_po` membedakan PO langsung vs e-Katalog bidding
- `order_billings` header baru: status lifecycle draft→adjustment→finalized→exported→paid→closed
- `supplier_accounts`: rekening supplier tersimpan, auto-lookup saat bayar
- `payment_audit_logs`: setiap perubahan status pembayaran tercatat permanen

**Fix Gap:**
- Consumer payment: `rejection_reason`, `retry_count`, `verify_deadline_at`
- Field team: `attendance_status`, `payment_deadline_at`, bulk payment
- Billing: nomor tagihan, finalisasi, export tracking
- Report: filter parameter lengkap per endpoint

---

## CHANGELOG v1.20

### v1.20 — Operasional Harian Driver & Perawatan Kendaraan

**Siklus Harian Driver:**
- Clock-in → Foto KM awal → Pre-trip inspection → Tugas order → Isi BBM → Foto KM akhir → Clock-out
- Setiap titik ada bukti foto yang tersimpan sebagai audit trail

**Foto Wajib:**
- Speedometer: awal hari, akhir hari, setiap isi BBM
- Nota SPBU: setiap isi BBM
- Kerusakan: saat lapor masalah

**BBM Management:**
- Log per pengisian: liter, harga, SPBU, foto nota + foto speedometer
- Efisiensi otomatis: km/liter per isi, dibanding rata-rata 30 hari
- Anomali (drop >20%) → alarm Gudang + Owner

**Inspeksi Kendaraan:**
- 30+ item checklist per kategori (ban, mesin, kelistrikan, body, kelengkapan)
- Pre-trip wajib sebelum boleh berangkat
- Item critical gagal → kendaraan diblokir otomatis

**Maintenance:**
- Driver lapor masalah → Gudang handle → bisa link ke procurement untuk beli part
- Jadwal perawatan berkala per KM + per bulan
- Reminder 7 hari / 500 KM sebelum due

**Tabel Baru:** 6 tabel (perawatan & BBM)
- `vehicle_km_logs`, `vehicle_fuel_logs`
- `vehicle_inspection_master`, `vehicle_inspections`, `vehicle_inspection_items`
- `vehicle_maintenance_requests`, `vehicle_maintenance_schedule`

**Multi-Leg Trip Dinamis (menggantikan hardcode logistics/hearse):**
- `trip_leg_master` — master jenis leg perjalanan (data-driven, bisa ditambah Owner)
- `order_trip_template` — template rute default per paket layanan
- `order_driver_assignments` — direfaktor: N leg per order, bukan 2 hardcode
- `orders.driver_overall_status` — simplified: unassigned/assigned/in_progress/all_done
- SO konfigurasi rute saat konfirmasi (edit alamat, tambah/skip/reorder leg)
- Gate trigger dinamis: setiap leg bisa trigger event berbeda (alarm Dekor, notif Consumer, dll)
- 9 jenis leg default: antar barang, jemput jenazah, antar ke RD/pemakaman/krematorium, angkut kembali, dll
- Mendukung semua skenario: pemakaman standar, kremasi, luar kota, peringatan, custom

---

## CHANGELOG v1.19

### v1.19 — Sinkronisasi Driver & Vehicle + Purchasing Reminder & Urgency

**Driver & Vehicle:**
- Definisi tabel `vehicles` (master armada) — sebelumnya hanya direferensikan
- Tabel `order_driver_assignments` — penugasan driver per order per task (logistics/hearse)
- Tabel `vehicle_slot_bookings` — anti double-booking kendaraan
- Kolom `driver_status` eksplisit di `orders` — 8 status granular
- Kolom `assigned_driver_id`, `assigned_vehicle_id` di `orders`
- Status progression: assigned → departed → arrived → completed per task
- Auto-complete logic disinkronkan ke ENUM baru (`hearse_arrived`, `all_done`)
- Fallback kendaraan + auto procurement jika armada penuh
- Flutter: driver assignment screen + vehicle dashboard

**Purchasing Reminder & Urgency:**
- Kolom `priority` (normal/high/critical) di `procurement_requests`
- Kolom `category` — jenis pengadaan (bisa ditambah via UI)
- Kolom `requester_name`, `requester_role` — snapshot pengaju, tampil di UI
- Kolom `approval_deadline`, `payment_deadline` — auto-set dari threshold
- Kolom `reminder_count`, `last_reminder_at` — tracking eskalasi
- Scheduler: reminder approval setiap 4 jam, payment setiap 12 jam
- Auto-priority: critical jika blocking order, high jika needed_by dekat
- Eskalasi ke Owner + hrd_violation jika lewat max reminders
- Dashboard Purchasing: 4 card ringkasan (approval, payment, consumer, field team)
- Approval list: sort by deadline, filter by priority/role/category
- Notifikasi ke pengaju (semua role) di setiap perubahan status

---

## CHANGELOG v1.18

### v1.18 — Sifat Item Gudang: Sewa, Pakai Habis, Pakai Bisa Kembali

**Konsep:**
- 3 sifat item: `sewa` (rental, wajib kembali), `pakai_habis` (consumed), `pakai_kembali` (returnable, tagihan dipotong)
- Pengembalian item pakai_kembali otomatis adjust tagihan + restore stok
- Item sewa rusak/hilang → biaya penggantian otomatis ke extra approval

**Tabel Baru:**
- `order_item_returns` — log pengembalian item per order

**Tabel Diperkaya:**
- `stock_items` + `item_nature` ENUM
- `package_items` + `item_nature` (override per paket), `is_billable`
- `order_billing_items` + `sent_qty`, `returned_qty`, `billed_qty`, `returned_at`, `returned_verified_by`
- `billing_item_master` + `stock_item_code` (link ke stok untuk auto-adjust)
- `order_stock_deductions` + `item_nature`

**Flow:**
- Gudang input pengembalian → sistem auto: restore stok + adjust billing + notif Purchasing
- Tagihan final = sent_qty - returned_qty per item
- Export PDF tagihan sudah reflect potongan

---

## CHANGELOG v1.17

### v1.17 — Sistem Presensi Universal Anti-Mock Location

**Cakupan:** Semua karyawan internal + vendor lapangan (kecuali Supplier, Consumer, Super Admin, Viewer)

**Dua jenis presensi:**
- Presensi Harian (`daily_attendances`) — clock in/out kerja harian di kantor/gudang/pos
- Presensi Order (`field_attendances`, diperkaya) — hadir di lokasi order

**Anti-Mock Location 6 Lapis:**
1. Flutter: `isFromMockProvider()` detection
2. Flutter: Google Play Integrity API (anti-root/tamper)
3. Flutter: Scan app fake GPS terinstall (blacklist dinamis)
4. Flutter: Foto selfie wajib via kamera depan
5. Backend: Geofence validation + velocity check (anti-teleportasi)
6. Backend: Device fingerprint + anti-titip-absen (1 device = 1 user)

**Tabel Baru:** 6 tabel (3 master + 3 transaksional)

**Integrasi:** KPI (v1.16), HRD violations, scheduler auto-absent, Owner realtime dashboard

---

## CHANGELOG

### v1.15 — Finance → Purchasing, Pengadaan Terbuka Semua Role
**Perubahan:**
- Role `finance` diganti menjadi `purchasing` — seluruh endpoint, folder, variabel, alarm, dan referensi diperbarui
- Semua role internal (SO, Gudang, Driver, Dekor, Konsumsi, Pemuka Agama, HRD, Security, Purchasing) kini bisa membuat permintaan pengadaan (v1.27: Owner view only, tidak bisa buat procurement)
- Endpoint pengadaan dipindah dari `/gudang/procurement-requests` ke `/procurement-requests` (shared, otomatis catat `requested_by`)
- Evaluasi quote dan penerimaan barang tetap di Gudang (karena fisik barang masuk ke gudang)
- Pengaju permintaan mendapat notifikasi status update di setiap fase
- Kolom `requested_by` ditambahkan ke `procurement_requests`
- Flutter: folder `features/purchasing/` (ganti dari `features/finance/`), `features/procurement/` (shared pengadaan)

### v1.12 — Manajemen Armada (Vehicle Management), Otomatisasi PO & Deep Link WA, Refinasi Status Payment
**Konsep & Stabilitas:**
- Opsi `proof_uploaded` dan `proof_rejected` di payment_status.
- Package-based vehicle assignment, automated fallback, Purchasing approval untuk eksternal supplier vehicle.
- Otomatisasi automasi koneksi WhatsApp via deep-link.
- Refinasi error constraint & SO confirmation, serta auto-generated PO terkait Gudang.
- Pembenahan parsing data mata uang di Owner/Purchasing UI dan stabilisasi pengelolaan pesanan/paket lama.

### v1.11 — e-Katalog: Alur Transaksi Lengkap 7 Fase
**Konsep:**
- Supplier = eksternal, HANYA untuk e-Katalog
- Semua role internal = bisa buat permintaan pengadaan
- Gudang = evaluasi quote + terima barang
- Purchasing = approve transaksi + bayar supplier
- Banyak supplier bersaing (sealed bid) per permintaan

**7 Fase Alur e-Katalog:**
1. Semua role buat permintaan → Publikasi
2. Supplier terima ALARM → Submit penawaran (sealed bid, validasi AI per quote)
3. Gudang evaluasi semua quote → Pilih pemenang
4. Purchasing approve → Transaksi resmi terbuat → Supplier pemenang dapat ALARM
5. Supplier kirim barang → Input resi + foto
6. Gudang terima barang → Stok otomatis bertambah → Purchasing dapat notif bayar
7. Purchasing bayar supplier → Supplier konfirmasi → Selesai

**Tabel baru:**
- `supplier_transactions`: record resmi transaksi post-Purchasing approve (tracking pengiriman + pembayaran)
- `procurement_requests.status`: ditambah 'purchasing_approved', 'goods_received'
- `supplier_quotes.status`: ditambah 'shipped', 'completed'

**Endpoint baru:**
- Supplier: `PUT /supplier/quotes/{id}/mark-shipped`, `GET /supplier/transactions`, `PUT /supplier/transactions/{id}/confirm-payment`
- Gudang: `PUT /gudang/procurement-requests/{id}/receive`
- Purchasing: `GET /purchasing/supplier-transactions`, `PUT /purchasing/supplier-transactions/{id}/pay`

**Flutter - screen baru:**
- Supplier: 8 screen lengkap (catalog, quote form, riwayat, transaksi, profil)
- Gudang: 6 screen e-Katalog (catalog list, form, detail, quote list, quote detail, receive)

**Tabel alarm e-Katalog**: lengkap siapa dapat alarm di setiap dari 7 fase

### v1.10 — Purchasing, SO Multi-Channel, HRD Aktif
### v1.9 — Alur Order Definitif (Gate Gudang, Time-Based, Payment Bukti)
### v1.8 — Full Automation + Hapus Admin
### v1.7 — Sistem Stok Terintegrasi
### v1.6 — Design System Liquid Glass

---

## SIMULASI ORDER END-TO-END — VERIFIKASI FLOW v1.17

Berikut simulasi lengkap satu order dari awal hingga selesai, menunjukkan semua sistem yang terlibat.

```
═══════════════════════════════════════════════════════════════════════════
SKENARIO: Keluarga Bpk. Yohanes memesan layanan pemakaman paket "Premium"
Tanggal: 14 April 2026, pukul 07:30 WIB
═══════════════════════════════════════════════════════════════════════════

──── PAGI HARI: PRESENSI HARIAN ────────────────────────────────────────

06:00  Scheduler `attendance:generate-daily` → buat record daily_attendances
       untuk semua karyawan yang punya shift hari ini (status: 'scheduled')

07:45  Gerry Gudang clock-in di Gudang Santa Maria
       → AntiMockService.validateAndCollect() → 6 lapis OK
       → POST /attendance/clock-in → selfie + lokasi disimpan
       → daily_attendances: status='present', clock_in_at=07:45

07:50  Siti Purchasing clock-in di Kantor
07:55  Budi SO clock-in di Kantor
08:00  Anto Driver clock-in di Gudang
08:05  Security clock-in di Pos Security

10:00  Scheduler `attendance:check-absent` → siapa belum clock-in?
       → Jika ada yang belum → status='absent' → hrd_violations + alarm HRD

──── STEP 1: ORDER MASUK ───────────────────────────────────────────────

07:30  Consumer (Keluarga Bpk. Yohanes) input order via app
       → Sistem generate: SM-20260414-0001
       → Status: 'pending'
       
       ALARM & NOTIFIKASI:
       ├─ SO (Budi)      : 🔔 ALARM "Order Baru SM-20260414-0001!"
       ├─ Gudang (Gerry)  : 📋 NORMAL (View) — bisa lihat detail di dashboard
       └─ Purchasing (Siti): 📋 NORMAL (View) — bisa lihat detail di dashboard

       DATABASE:
       └─ orders: { id: X, order_number: 'SM-20260414-0001', status: 'pending',
                    pic_user_id: [consumer_id] }

──── STEP 2: SO VALIDASI & KONFIRMASI ─────────────────────────────────

07:35  Budi SO buka order, verifikasi data almarhum + keluarga
       → Pilih paket "Premium" (dari packages table)
       → Tambah add-on: "Embalming", "Foto Dokumentasi", "Bus Lelayu"
       → Set scheduled_at: 2026-04-14 10:00
       → Set estimated_duration_hours: 5
       → Assign tukang_foto_id: [Benny Fotografer]
       → Tekan "Konfirmasi Order"

       DATABASE:
       ├─ orders.status: 'pending' → 'confirmed'
       ├─ orders.scheduled_at: 2026-04-14 10:00
       ├─ orders.estimated_duration_hours: 5
       ├─ orders.tukang_foto_id: [benny_id]
       └─ orders.coffin_order_id: [peti dari stok workshop, jika ada]

──── STEP 3: DISTRIBUSI PARALEL (OTOMATIS, SEKETIKA) ──────────────────

07:35  Sistem beroperasi paralel:

  [ GUDANG ]
  → 🔔 ALARM: "Order SM-20260414-0001 Dikonfirmasi — Stok Dikurangi!"
  → Auto-deduct stock_transactions (type: 'out'):
      peti (1), kertas coklat (1), cologne (2), lilin (4), sepatu (1), dll
  → Auto-generate order_equipment_items dari equipment_master:
      Koper Misa (1), Koper Romo (1), Box (1), Sound (1), Meja+Taplak (1)
  → Auto-generate order_billing_items dari billing_item_master:
      EMB, NSN, BNG_SLB, BNG_PTI, FTO, BSL, dll (sesuai paket + addon)
  → Jika cologne stok=0 → flag needs_restock → alarm Purchasing

  DATABASE:
  ├─ stock_transactions: [~15 records type='out']
  ├─ order_equipment_items: [~7 records status='prepared']
  └─ order_billing_items: [~12 records source='package'/'addon']

  [ PURCHASING ]
  → 🔔 ALARM: "Order dikonfirmasi. needs_restock aktif — perlu PO cologne"
  → Siti bisa langsung buat procurement_request untuk cologne
    → POST /procurement-requests (requested_by: siti_id)

  [ KONSUMSI ]
  → 🔔 ALARM: "Assignment katering Order SM-20260414-0001"
  → Sistem buat field_attendances:
      { user_id: konsumsi_id, order_id: X, attendance_date: 2026-04-14,
        kegiatan: 'Katering Pemakaman', scheduled_jam: '10:00',
        status: 'scheduled' }

  [ PEMUKA AGAMA ]
  → 🔔 ALARM: "Assignment upacara Order SM-20260414-0001"
  → Sistem buat field_attendances:
      { user_id: pemuka_id, order_id: X, kegiatan: 'Misa Pemberkatan',
        scheduled_jam: '10:00', status: 'scheduled' }

  [ TUKANG FOTO ]
  → 🔔 ALARM: "Kamu ditugaskan di Order SM-20260414-0001. Tanggal: 14/04/2026"
  → Sistem buat field_attendances:
      { user_id: benny_id, order_id: X, kegiatan: 'Dokumentasi',
        scheduled_jam: '10:00', status: 'scheduled' }

  [ DEKORASI ]
  → ❌ TIDAK DAPAT ALARM — standby menunggu barang tiba di lokasi

──── STEP 4: GUDANG SIAPKAN & KONFIRMASI SIAP ─────────────────────────

08:00  Gerry Gudang buka app → lihat checklist peralatan
       → Fisik: pack Koper Misa, Koper Romo, Box, Sound, Meja
       → Centang tiap item: PUT /gudang/orders/{id}/checklist/{itemId}
       
08:30  Semua item siap → Gerry tekan "Stok Siap Angkut"
       → PUT /gudang/orders/{id}/stock-ready

       DATABASE:
       ├─ orders.status: 'confirmed' → 'in_progress'
       └─ order_equipment_items: semua status='prepared' → 'sent'

  [ DRIVER — AUTO ASSIGNMENT ]
  → AI pilih Anto Driver (terdekat, tidak sedang tugas, kendaraan tersedia)
  → 🔔 ALARM: "Kamu ditugaskan ke SM-20260414-0001. Kendaraan: Nopol AB-1234.
              Jam berangkat: SEKARANG."

──── STEP 5: DRIVER TUGAS 1 — ANTAR BARANG ────────────────────────────

08:35  Anto Driver angkut barang dari Gudang
       → vehicle_trip_logs: { nota_number: 'NMJ-20260414-001',
           km_berangkat: 45230, alamat_penjemputan: 'Gudang SM',
           tujuan: 'Rumah Duka Bethesda' }

09:00  Anto tiba di Rumah Duka, turunkan barang
       → Tekan "Barang Tiba di Tujuan" di app
       → Upload bukti foto: POST /driver/orders/{id}/bukti
         (bukti_type: 'tiba_tujuan')

  [ GATE DEKORASI DIBUKA ]
  → 🔔 ALARM KERAS KE DEKORASI: "Barang Order SM-20260414-0001 sudah tiba!
     Segera ke lokasi untuk pasang dekorasi!"
  → Sistem buat field_attendances untuk dekor:
      { user_id: dekor_id, kegiatan: 'Pasang Dekorasi', status: 'scheduled' }
  → Consumer: NORMAL "Perlengkapan sudah tiba di lokasi"

──── STEP 6: DRIVER TUGAS 2 — ANTAR JENAZAH ───────────────────────────

09:05  Anto menuju RS (lokasi jenazah)
09:30  Tiba di RS → upload bukti penjemputan
       → bukti_type: 'penjemputan'
       
09:45  Anto tiba di Rumah Duka dengan jenazah
       → order_driver_assignments (hearse): 'arrived_destination' → 'task_completed'
       → orders.driver_status: 'hearse_pickup' → 'hearse_arrived' → 'all_done'
       → vehicles.status: 'in_use' → 'available'
       → Upload bukti akhir
       → Consumer: HIGH "Jenazah dan tim telah tiba"

──── EKSEKUSI PARALEL DI LOKASI ────────────────────────────────────────

09:30  Dekor (Laviore) tiba di lokasi
       → POST /vendor/attendances/{id}/check-in
       → AntiMockService → 6 lapis OK → selfie + lokasi
       → field_attendances: status='present', arrived_at=09:30
       → check_in_distance_meters: 85m (dalam radius 500m ✓)
       → SO mendapat HIGH "Dekor sudah check-in"

09:35  Konsumsi tiba di lokasi → check-in
       → field_attendances: status='present'

09:40  Pemuka Agama (Romo Petrus) tiba → check-in
       → field_attendances: status='present'

09:45  Tukang Foto (Benny) tiba → check-in
       → field_attendances: status='present'
       → Benny mulai dokumentasi

10:00  Prosesi dimulai — scheduled_at tercapai

       SELAMA PROSESI:
       ├─ Gudang input order_consumables_daily:
       │    shift='pagi': cologne 2 btl, lilin 4 btl, air minum 2 dos
       │    → POST /orders/{id}/consumables → header + lines dari consumable_master
       │
       ├─ SO bisa input order_extra_approvals jika ada biaya tambahan:
       │    → "Sewa tenda tambahan Rp 500.000"
       │    → POST /so/orders/{id}/extra-approvals → header + extra_approval_lines
       │    → Keluarga tanda tangan digital di app SO → pj_signed_at
       │    → Purchasing dapat ALARM "Biaya baru!"
       │
       ├─ Dekor isi form paket harian La Fiore:
       │    → POST /dekor/orders/{id}/daily-package → header
       │    → dekor_daily_package_lines dari dekor_item_master:
       │      Budget, Corsase, Bunga Atas Peti, Bunga Salib, dll
       │    → Bandingkan 3 supplier → pilih termurah
       │
       └─ Tukang Foto upload hasil foto:
            → POST ke foto_upload_screen

──── STEP 7: ORDER AUTO-COMPLETE ───────────────────────────────────────

15:05  Scheduler `order:auto-complete-by-time` cek setiap 5 menit:
       → scheduled_at (10:00) + estimated_duration_hours (5) = 15:00
       → Sekarang 15:05 > 15:00 ✓
       → driver_status = 'all_done' ✓
       → AUTO-COMPLETE!

       DATABASE:
       ├─ orders.status: 'in_progress' → 'completed'
       ├─ orders.auto_completed_at: 2026-04-14 15:05
       ├─ orders.completion_method: 'auto_time'
       └─ order_status_logs: { from: 'in_progress', to: 'completed' }

       POST-COMPLETE OTOMATIS:
       ├─ Cek order_equipment_items → ada yang belum returned?
       │    → Semua masih status='sent' → BELUM kembali (wajar, baru selesai)
       │    → Scheduler equipment:check-return-deadline H+1 akan cek
       │
       ├─ Cek field_attendances → ada yang absent?
       │    → Semua 'present' ✓ → tidak ada pelanggaran
       │
       ├─ Generate order_billing_items final
       │    → Tambahkan item dari order_extra_approvals ke billing
       │
       └─ AI generate pesan dukacita → kirim ke consumer

       NOTIFIKASI:
       ├─ Consumer     : HIGH "Layanan selesai. Silakan upload bukti pembayaran."
       ├─ Purchasing   : 🔔 ALARM "Order SM-20260414-0001 selesai. Tunggu bukti payment."
       └─ Owner        : NORMAL "Order SM-20260414-0001 auto-completed."

──── SETELAH SELESAI: VENDOR CHECK-OUT ─────────────────────────────────

15:10  Benny Tukang Foto check-out
       → POST /vendor/attendances/{id}/check-out → selfie + lokasi
       → field_attendances.departed_at = 15:10
       → SO konfirmasi: pic_confirmed = true

15:15  Dekor check-out, Konsumsi check-out, Pemuka Agama check-out
15:20  Anto Driver catat KM kembali:
       → vehicle_trip_logs: km_tiba=45290, km_total=60, biaya_km dihitung

──── STEP 8: PAYMENT ───────────────────────────────────────────────────

16:00  Consumer upload bukti transfer via app
       → POST /consumer/orders/{id}/payment-proof
       → orders.payment_proof_path: 'payment_proofs/SM-20260414-0001/proof.jpg'
       → orders.payment_status: 'proof_uploaded'
       → Purchasing: 🔔 ALARM "Bukti payment masuk!"

16:30  Siti Purchasing review bukti → foto jelas, nominal cocok
       → PUT /purchasing/orders/{id}/payment/verify
       → orders.payment_status: 'paid'
       → Consumer: HIGH "Pembayaran dikonfirmasi. Terima kasih."
       → Owner: NORMAL "Payment SM-20260414-0001 verified."

──── STEP 9: POST-ORDER ────────────────────────────────────────────────

16:35  Purchasing finalisasi laporan tagihan:
       → GET /orders/{id}/billing → 26 item + extra
       → Koreksi qty/harga jika perlu
       → Export PDF: GET /purchasing/billing/export/{orderId}

16:45  Purchasing bayar tim lapangan:
       → POST /purchasing/orders/{id}/field-team
         { name: "Musisi Gereja", role_description: "Musisi", amount: 500000 }
         { name: "Penggali Makam", role_description: "Penggali", amount: 300000 }
       → PUT /purchasing/field-team/{id}/pay → upload bukti bayar

17:00  Budi SO buat checklist akta kematian:
       → POST /so/orders/{id}/death-cert-docs
       → Sistem auto-generate items dari death_cert_doc_master (21 dokumen)
       → SO centang dokumen yang diterima dari keluarga:
         KTP Almarhum ✓, KK ✓, Surat Kematian RS ✓, Akte Lahir ✓, ...
       → orders.death_cert_submitted = true (setelah semua lengkap)

──── H+1: PENGEMBALIAN BARANG (SEWA + PAKAI KEMBALI) ───────────────────

Keesokan hari (15 April 2026):

08:00  Scheduler equipment:check-return-deadline cek:
       → Order SM-20260414-0001 completed >24 jam
       → Item sewa + pakai_kembali belum returned → ALARM Gudang!

09:00  Keluarga/Driver kembalikan barang ke Gudang Santa Maria
       → Gerry buka item_return_screen → POST /gudang/orders/{id}/returns

       ITEM SEWA (rental):
       ├─ Sound (1)      → kembali ✓ kondisi baik → stok +1
       ├─ Meja+Taplak (1)→ kembali ✓ → stok +1
       ├─ LED+Stand (1)  → RUSAK → qty_damaged:1 → biaya ganti ke extra_approval
       ├─ Koper Misa (1) → kembali ✓ → stok +1
       └─ Box (1)        → kembali ✓ → stok +1

       ITEM PAKAI BISA KEMBALI (returnable):
       ├─ Air Putih: kirim 10 dos, kembali 2 → stok +2
       │    → billing AQU: sent_qty=10, returned_qty=2, billed_qty=8
       │    → kembali = 2 × Rp50.000 = Rp 100.000
       ├─ Kwaci: kirim 5, kembali 1 → stok +1
       │    → billing KWC: billed_qty 5→4, kembali Rp 15.000
       ├─ Lilin: kirim 4, kembali 1 → stok +1
       │    → billing LLN: billed_qty 4→3, kembali Rp 25.000
       └─ Permen: kirim 5, kembali 0 → habis, tidak ada potongan

       TOTAL POTONGAN TAGIHAN: Rp 140.000 (otomatis)
       → Purchasing: HIGH "Tagihan dipotong Rp 140.000 (retur barang)"
       → Tagihan PDF final sudah reflect potongan

──── PRESENSI HARIAN: CLOCK-OUT ────────────────────────────────────────

17:00  Semua karyawan clock-out:
       → POST /attendance/clock-out → selfie + lokasi
       → daily_attendances: clock_out_at, work_duration_minutes dihitung
       → Anto Driver: clock_out_at=17:00, work_duration=540 menit (9 jam)
         → Tidak overtime (< 12 jam threshold) ✓

23:55  Scheduler attendance:auto-clock-out:
       → Siapa yang lupa clock-out? → Auto close + flag

──── KPI UPDATE (BACKGROUND) ───────────────────────────────────────────

Setiap 6 jam, scheduler kpi:refresh-current-period menghitung:

  Budi SO:
  ├─ SO_PROCESS_SPEED: 5 menit (pending→confirmed) → target ≤30 → score: 100
  ├─ SO_ORDER_COUNT: +1 → running total
  ├─ SO_VIOLATION_COUNT: 0 → score: 100
  └─ ATT_DAILY_RATE: hadir → 100%

  Anto Driver:
  ├─ DRV_ONTIME_RATE: tiba tepat waktu → 100%
  ├─ DRV_TRIP_COUNT: +1 → running total
  └─ DRV_BUKTI_UPLOAD: 2/2 bukti → 100%

  Benny Tukang Foto:
  ├─ VND_ATTENDANCE_RATE: hadir → 100%
  ├─ VND_ONTIME_RATE: arrived_at ≤ scheduled_jam → 100%
  └─ ATT_MOCK_ATTEMPTS: 0 → 100%

═══════════════════════════════════════════════════════════════════════════
RINGKASAN: SEMUA TABEL YANG TERSENTUH DALAM 1 ORDER
═══════════════════════════════════════════════════════════════════════════

  orders                        — status lifecycle: pending→confirmed→in_progress→completed
  order_status_logs             — log setiap perubahan status
  stock_transactions            — auto-deduct stok saat SO konfirmasi
  order_equipment_items         — checklist peralatan: prepared→sent→returned/missing
  order_billing_items           — 26+ item tagihan auto-generate + manual
  order_consumables_daily       — header per shift
  order_consumable_lines        — detail item per shift
  field_attendances             — presensi vendor: scheduled→present→(departed)
  vehicle_trip_logs             — nota KM driver
  order_bukti_lapangan          — foto bukti dari driver, dekor, konsumsi
  dekor_daily_package           — header paket La Fiore
  dekor_daily_package_lines     — detail item dekor
  order_extra_approvals         — header biaya tambahan
  extra_approval_lines          — detail item tambahan
  order_death_certificate_docs  — header akta kematian
  order_death_cert_doc_items    — checklist per dokumen
  order_field_team_payments     — upah tim lapangan
  order_item_returns            — log pengembalian (sewa + pakai_kembali)
  daily_attendances             — presensi harian semua karyawan
  attendance_logs               — audit trail anti-mock
  hrd_violations                — pelanggaran (jika ada)
  kpi_scores                    — skor KPI auto-update
  kpi_user_summary              — ringkasan KPI

  Total: 23 tabel tersentuh per 1 order lifecycle
```

---

## TEMUAN & PERBAIKAN DARI SIMULASI

Berikut inkonsistensi yang ditemukan dan sudah diperbaiki:

1. ~~Header version masih v1.15~~ → **Fixed**: v1.17
2. ~~Role count "10 Role Aktif" di v1.10~~ → **Fixed**: 12 Role Aktif
3. ~~Tabel alarm v1.13 tidak include Tukang Foto & Pemuka Agama~~ → **Fixed**: tabel alarm unified v1.17
4. ~~STEP 3 tidak sebut Tukang Foto, Pemuka Agama, auto-generate equipment & billing~~ → **Fixed**: semua tercantum
5. ~~STEP 7 tidak sebut post-complete checks~~ → **Fixed**: peralatan, presensi, billing
6. ~~Tidak ada STEP 9 (post-order: tagihan, upah, akta)~~ → **Fixed**: ditambahkan
7. ~~v1.14 SINKRONISASI redundan dengan flow utama~~ → **Fixed**: di-merge ke flow utama
8. ~~Dekor tidak dibuat field_attendances di STEP 3~~ → **Fixed**: dibuat di STEP 5 saat gate dibuka

---

## PENUTUP

Ini adalah spesifikasi lengkap dan final Santa Maria Funeral Organizer v1.27.
Tidak ada fitur yang boleh dikurangi tanpa konfirmasi owner proyek.

**Total Role: 12 aktif (SO, Gudang, Purchasing, Driver, Dekor, Konsumsi, Pemuka Agama, Tukang Foto, HRD, Security, Owner, Viewer) + 1 Super Admin + 1 Supplier (eksternal) + 1 Consumer (eksternal)**
**Total Fitur AI: 14 + Auto-Assign + Auto-Complete + AI Validasi Quote**
**Platform: Android (Flutter) + Laravel REST API**
**Database: PostgreSQL 16 | AI: OpenAI GPT-4o mini**

**ALUR ORDER (9 STEP):**
1. Order masuk (3 channel) → SO + Gudang + Purchasing dapat view
2. SO validasi, pilih paket, konfirmasi
3. Distribusi paralel: Gudang (stok+peralatan) + Purchasing + Konsumsi + Pemuka Agama + Tukang Foto → Dekor STANDBY
4. Gudang siap angkut → Driver auto-assign
5. Driver Tugas 1: antar barang → Gate Dekorasi dibuka
6. Driver Tugas 2: antar jenazah
7. Auto-complete (time-based) → cek peralatan + presensi + billing
8. Consumer upload bukti → Purchasing verifikasi → paid
9. Post-order: tagihan final + bayar tim lapangan + berkas akta kematian

**ALUR e-KATALOG (7 FASE):** Semua role bisa posting pengadaan → Supplier ALARM & bid → Gudang evaluasi
→ Purchasing approve → Supplier kirim → Gudang terima (stok masuk) → Purchasing bayar supplier

**ALUR WORKSHOP PETI:** Order peti masuk → Busa → Amplas → Finishing → QC → Terima/Gagal → Delivery

**FORM FISIK YANG TERDIGITALISASI (19 form):**
- Form Busa Eropa, Pengerjaan Melamin, Pengerjaan Duco, Surat Order Peti → `coffin_orders` + `coffin_order_stages`
- Form Peralatan Pelayanan (2 versi) + Pinjaman Peralatan Peringatan → `order_equipment_items` + `equipment_loans`
- Presensi Tukang Foto → `field_attendances` (berlaku untuk semua vendor)
- Data Barang Harian (pink) → `order_consumables_daily`
- Formulir Pengambilan Barang + Formulir Pengembalian Barang → `stock_transactions` (sudah ada, diperkaya)
- Laporan Tagihan 26 item → `order_billing_items`
- Kuitansi → `orders.payment_status` + Purchasing workflow (sudah ada)
- Nota Pemakaian Mobil Jenazah → `vehicle_trip_logs`
- Formulir Isi Paket La Fiore → `dekor_daily_package`
- Tanda Terima Berkas Akta Kematian → `order_death_certificate_docs`
- Persetujuan Tambahan di Luar Paket → `order_extra_approvals`
- Surat Order (form QC + kriteria) → `coffin_qc_results` + `coffin_qc_criteria_master`
- Formulir Laporan Pelayanan Harian + Checker → `field_attendances` + `order_billing_items`

---

# SANTA MARIA — PATCH v1.28
# Landing Page Publik, Blog/Artikel CMS, CRUD Berita Duka (Obituari)

---

## PERUBAHAN & PENAMBAHAN FITUR v1.28

### 1. Landing Page Publik (Website Informasi)

Website landing page yang dapat diakses tanpa login oleh publik umum.
Disajikan via Laravel Blade (`resources/views/landing.blade.php`) di route `/`.

**Konten Statis:**
- Hero section dengan informasi layanan Santa Maria
- 6 layanan utama: Transportasi Jenazah, Dekorasi & Bunga, Konsumsi & Katering, Pemuka Agama, Perlengkapan, Monitoring via Aplikasi
- 6 keunggulan: Respons 24/7, GPS Tracking, Koordinasi Terpadu, Terpercaya, Pembayaran Transparan, Dokumentasi
- 5 langkah alur layanan
- 3 paket layanan (Dasar, Premium, Eksklusif)
- Testimoni, FAQ (accordion)
- CTA dengan nomor kontak asli: Telp. 024-3560444, WA 081.128.8286
- Alamat: Jl. Citarum Tengah E-1, Semarang 50126

**Konten Dinamis (dari API):**
- Section **Berita Duka** — menampilkan obituari terbaru dari tabel `obituaries`
- Section **Blog / Artikel** — menampilkan artikel terbaru dari tabel `articles`
- Data di-fetch via JS dari public API (no auth)

**Design System:**
- Warna sesuai logo asli Santa Maria: navy (#1E3A5F), steel blue (#4A7BA7), gold (#C5A55A), cream (#FAF8F5)
- Font: Playfair Display (heading/serif), Inter (body/sans-serif)
- Responsive (mobile + desktop)
- Floating WhatsApp button

---

### 2. Blog / Artikel CMS

Sistem artikel/blog untuk konten informatif seputar layanan pemakaman, panduan tradisi, tips, dsb.

#### Tabel `articles`

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
title VARCHAR(255) NOT NULL
slug VARCHAR(255) UNIQUE NOT NULL                 -- auto-generated dari title + random suffix
excerpt TEXT NULLABLE                             -- ringkasan singkat (max 500 char)
body LONGTEXT NOT NULL                            -- konten HTML (rich text)
cover_image_path VARCHAR(255) NULLABLE            -- path di R2
category VARCHAR(100) DEFAULT 'umum'              -- kategori: umum, panduan, tradisi, tips, dll
tags JSON NULLABLE                                -- array string tag
status ENUM('draft', 'published', 'archived') DEFAULT 'draft'
published_at TIMESTAMP NULLABLE                   -- waktu dipublikasikan
author_id UUID REFERENCES users(id) ON DELETE CASCADE
is_featured BOOLEAN DEFAULT FALSE                 -- tampil di highlight landing page
view_count INTEGER DEFAULT 0                      -- counter views
meta_title VARCHAR(255) NULLABLE                  -- SEO
meta_description VARCHAR(500) NULLABLE            -- SEO
deleted_at TIMESTAMP NULLABLE                     -- soft delete
created_at TIMESTAMP
updated_at TIMESTAMP

INDEX: (status, published_at), (category), (is_featured)
```

#### API Endpoints — Artikel

```
-- Public (No Auth)
GET    /v1/public/articles                        -- list published, paginated, filter: category, featured, search
GET    /v1/public/articles/categories             -- list kategori yang ada
GET    /v1/public/articles/{slug}                 -- detail artikel (increment view_count)

-- Admin CRUD (role: admin, owner — via middleware)
GET    /v1/admin/articles                         -- list semua (termasuk draft), filter: status, category, search
POST   /v1/admin/articles                         -- buat artikel baru (body: title, body, category, tags, status, dll)
GET    /v1/admin/articles/{id}                    -- detail by ID
PUT    /v1/admin/articles/{id}                    -- update artikel
POST   /v1/admin/articles/{id}/cover              -- upload cover image (max 5MB)
DELETE /v1/admin/articles/{id}                    -- soft delete
```

**Logika Penting:**
- `slug` auto-generated: `Str::slug(title) + '-' + Str::random(6)` untuk mencegah duplikat
- `published_at` otomatis diisi saat status pertama kali diubah ke `published`
- Public endpoint hanya return artikel dengan `status = 'published'` DAN `published_at <= now()`
- Cover image disimpan di R2 path: `articles/{article_id}/cover/`
- Cover lama otomatis dihapus saat upload baru

---

### 3. Berita Duka / Obituari (CRUD)

Sistem pengumuman kematian publik. Bisa standalone atau terkait dengan order.
Keluarga dan relasi bisa melihat & share berita duka via link publik.

#### Tabel `obituaries`

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
slug VARCHAR(255) UNIQUE NOT NULL                 -- auto: slug(nama-dod) + random

-- Data Almarhum/Almarhumah
deceased_name VARCHAR(255) NOT NULL
deceased_nickname VARCHAR(100) NULLABLE
deceased_dob DATE NULLABLE                        -- tanggal lahir
deceased_dod DATE NOT NULL                        -- tanggal wafat
deceased_place_of_birth VARCHAR(255) NULLABLE
deceased_religion VARCHAR(50) NULLABLE
deceased_photo_path TEXT NULLABLE                  -- foto almarhum di R2
deceased_age INTEGER NULLABLE                     -- otomatis dihitung dari DOB & DOD

-- Info Keluarga
family_contact_name VARCHAR(255) NULLABLE
family_contact_phone VARCHAR(20) NULLABLE
family_message TEXT NULLABLE                      -- pesan duka dari keluarga (max 2000 char)
survived_by TEXT NULLABLE                         -- "Meninggalkan istri: ..., anak: ..., cucu: ..."

-- Info Pemakaman
funeral_location VARCHAR(255) NULLABLE
funeral_datetime TIMESTAMP NULLABLE
funeral_address VARCHAR(500) NULLABLE
cemetery_name VARCHAR(255) NULLABLE

-- Info Doa / Upacara
prayer_location VARCHAR(255) NULLABLE
prayer_datetime TIMESTAMP NULLABLE
prayer_notes TEXT NULLABLE

-- Relasi ke Order (opsional)
order_id UUID NULLABLE REFERENCES orders(id) ON DELETE SET NULL

-- Admin
created_by UUID REFERENCES users(id) ON DELETE CASCADE
status ENUM('draft', 'published', 'archived') DEFAULT 'draft'
published_at TIMESTAMP NULLABLE
is_featured BOOLEAN DEFAULT FALSE
view_count INTEGER DEFAULT 0

-- SEO
meta_title VARCHAR(255) NULLABLE
meta_description VARCHAR(500) NULLABLE
deleted_at TIMESTAMP NULLABLE
created_at TIMESTAMP
updated_at TIMESTAMP

INDEX: (status, published_at), (deceased_dod), (is_featured)
```

#### API Endpoints — Berita Duka

```
-- Public (No Auth)
GET    /v1/public/obituaries                      -- list published, paginated, filter: featured, search
GET    /v1/public/obituaries/{slug}               -- detail (increment view_count)

-- Admin CRUD (role: admin, owner)
GET    /v1/admin/obituaries                       -- list semua, filter: status, search
POST   /v1/admin/obituaries                       -- buat berita duka baru
GET    /v1/admin/obituaries/{id}                  -- detail by ID
PUT    /v1/admin/obituaries/{id}                  -- update
POST   /v1/admin/obituaries/{id}/photo            -- upload foto almarhum (max 5MB)
POST   /v1/admin/obituaries/from-order/{orderId}  -- buat otomatis dari data order
DELETE /v1/admin/obituaries/{id}                  -- soft delete
```

**Logika Penting:**
- `deceased_age` otomatis dihitung dari `deceased_dob` dan `deceased_dod`
- `POST /admin/obituaries/from-order/{orderId}` otomatis isi data dari order (deceased_name, DOB, DOD, religion, foto almarhum, alamat, PIC) — draft, perlu review sebelum publish
- Jika sudah ada obituary untuk order tersebut → return 409 Conflict
- Foto almarhum disimpan di R2 path: `obituaries/{obituary_id}/photo/`
- Public endpoint hanya return `status = 'published'`

#### Web Routes (SEO-Friendly Detail Pages)

```
GET /                              -- Landing page (Blade)
GET /berita-duka/{slug}            -- Detail berita duka (Blade, SSR untuk SEO & sharing WA/sosmed)
GET /blog/{slug}                   -- Detail artikel (Blade, SSR untuk SEO)
```

Detail page di-render server-side (Blade) agar Open Graph meta tags terisi untuk preview saat share di WhatsApp/Facebook.

---

### 4. FLUTTER — Screen Baru (Berita Duka & Artikel CMS)

```
lib/modules/admin/screens/
  ├── admin_articles_screen.dart
  │     -- List semua artikel (draft + published)
  │     -- FAB: Buat Artikel Baru
  │     -- Filter: status, kategori
  │     -- Swipe to archive/delete
  │
  ├── admin_article_form_screen.dart
  │     -- Form buat/edit artikel
  │     -- Rich text editor untuk body (gunakan package flutter_quill)
  │     -- Upload cover image
  │     -- Input: title, excerpt, category, tags, status
  │     -- Preview mode sebelum publish
  │
  ├── admin_obituaries_screen.dart
  │     -- List semua berita duka
  │     -- FAB: Buat Berita Duka / Buat dari Order
  │     -- Filter: status
  │
  ├── admin_obituary_form_screen.dart
  │     -- Form buat/edit berita duka
  │     -- Upload foto almarhum
  │     -- Autocomplete dari order (jika dari-order)
  │     -- Input: data almarhum, keluarga, pemakaman, doa
  │     -- Preview card sebelum publish
  │
  └── admin_obituary_preview_screen.dart
        -- Preview tampilan berita duka seperti di web
        -- Tombol "Publish" + "Share via WA"
```

### 5. Notifikasi & Integrasi

| Momen | Penerima | Tipe |
|-------|----------|------|
| Obituary dipublish | - | Tidak ada notif otomatis (admin share manual via WA link) |
| Artikel dipublish | - | Tidak ada notif otomatis (konten informatif, bukan urgent) |

---

### 6. Ringkasan File Baru

```
-- Backend
database/migrations/2026_04_14_700001_create_articles_and_obituaries_tables.php
app/Models/Article.php
app/Models/Obituary.php
app/Http/Controllers/Public/PublicArticleController.php
app/Http/Controllers/Public/PublicObituaryController.php
app/Http/Controllers/Admin/ArticleController.php
app/Http/Controllers/Admin/ObituaryController.php
resources/views/landing.blade.php          -- Landing page publik
resources/views/obituary-detail.blade.php  -- Detail berita duka (SSR/Blade)
resources/views/article-detail.blade.php   -- Detail artikel (SSR/Blade)
routes/web.php                             -- Route: /, /berita-duka/{slug}, /blog/{slug}
routes/api.php                             -- Ditambah: /v1/public/*, /v1/admin/articles/*, /v1/admin/obituaries/*

-- Frontend (Landing Page)
landing-page.html                          -- Standalone HTML (development/preview)
```

*Dilarang mengurangi atau memodifikasi prompt ini tanpa persetujuan owner proyek*

---

# SANTA MARIA — PATCH v1.29
# Dynamic Roles, Provider Role per Item, Tukang Jaga Shift System, SAL Gate, Payment Bifurcation

---

## PERUBAHAN & PENAMBAHAN FITUR v1.29

### 1. Dynamic Roles System

Roles tidak lagi hardcoded sebagai PostgreSQL ENUM. Digantikan dengan tabel `roles` di database yang dapat dikelola oleh Super Admin secara dinamis.

#### Tabel `roles`
```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
slug VARCHAR(100) UNIQUE NOT NULL              -- snake_case, immutable untuk system roles
label VARCHAR(100) NOT NULL                    -- nama tampil (bisa diubah)
description TEXT NULLABLE
is_system BOOLEAN DEFAULT FALSE               -- TRUE = tidak bisa dihapus
is_active BOOLEAN DEFAULT TRUE
-- Flags Kapabilitas
can_have_inventory BOOLEAN DEFAULT FALSE      -- bisa kelola stok sendiri
is_vendor BOOLEAN DEFAULT FALSE               -- role vendor eksternal
is_viewer_only BOOLEAN DEFAULT FALSE          -- read-only access
can_manage_orders BOOLEAN DEFAULT FALSE       -- bisa handle order
receives_order_alarm BOOLEAN DEFAULT FALSE    -- terima alarm order baru
-- Kustomisasi UI
permissions JSONB DEFAULT '{}'               -- granular permissions
color_hex VARCHAR(10) NULLABLE
icon_name VARCHAR(50) NULLABLE
sort_order INTEGER DEFAULT 0
created_at TIMESTAMP
updated_at TIMESTAMP
```

**18+ system roles** di-seed otomatis dengan `is_system = true`:
`super_admin, consumer, service_officer, admin, gudang, finance, driver, dekor, konsumsi, supplier, owner, pemuka_agama, hrd, purchasing, viewer, tukang_foto, tukang_angkat_peti, tukang_jaga`

`users.role` diubah dari PostgreSQL ENUM → `VARCHAR(100)` via migration.

#### API Endpoints — Role Management (Super Admin)
```
GET    /v1/super-admin/roles              -- list semua role + user_count
POST   /v1/super-admin/roles             -- buat custom role (is_system=false otomatis)
PUT    /v1/super-admin/roles/{slug}      -- update (slug immutable untuk system role)
DELETE /v1/super-admin/roles/{slug}      -- hapus custom role (block jika ada user aktif)
GET    /v1/super-admin/roles/{slug}/users -- list user per role, paginated
```

**Aturan:**
- Slug hanya boleh `^[a-z0-9_]+$`
- System role tidak bisa dihapus, slug immutable
- Custom role dengan user aktif tidak bisa dihapus
- `users.is_viewer` di-sync dari `roles.is_viewer_only` saat create/update user

#### File Baru
```
backend/app/Models/Role.php
backend/app/Http/Controllers/SuperAdmin/RoleController.php
database/migrations/2026_04_16_000002_create_roles_table_and_convert_users_role.php
frontend/lib/modules/super_admin/screens/super_admin_role_management_screen.dart
frontend/lib/shared/constants/role_constants.dart  -- RoleConstants class (single source of truth Flutter)
```

---

### 2. Dynamic Provider Role per Package Item & Role-Agnostic Stock

Setiap item dalam paket (`package_items`) kini memiliki `provider_role` — role mana yang menyediakan/mengelola item tersebut. Stock items juga memiliki `owner_role`.

#### Perubahan Skema
```sql
-- package_items
ALTER TABLE package_items ADD COLUMN provider_role VARCHAR(50);
ALTER TABLE package_items ADD COLUMN fulfillment_notes TEXT;

-- stock_items
ALTER TABLE stock_items ADD COLUMN owner_role VARCHAR(50) DEFAULT 'gudang';

-- order_checklists
ALTER TABLE order_checklists ADD COLUMN provider_role VARCHAR(50);
```

#### API Endpoints — Role-Agnostic Stock (`/role-stock`)
```
GET    /v1/role-stock/items                          -- stok milik role user yang login
POST   /v1/role-stock/items                          -- tambah item stok (cek can_have_inventory)
PUT    /v1/role-stock/items/{id}                     -- update stok
DELETE /v1/role-stock/items/{id}                     -- hapus
GET    /v1/role-stock/orders/{orderId}/checklist     -- checklist item untuk role ini
PUT    /v1/role-stock/checklist/{id}/check           -- centang selesai + auto-deduct stok
PUT    /v1/role-stock/checklist/{id}/uncheck         -- batalkan
```

```
GET    /v1/admin/provider-roles   -- list role yang bisa menjadi provider (can_have_inventory OR is_vendor OR gudang/purchasing)
```

**Checklist generation saat order dikonfirmasi:** grouping by `provider_role`, alarm dikirim per-role ke semua user role tersebut.

#### File Baru
```
backend/app/Http/Controllers/RoleStock/RoleStockController.php
database/migrations/2026_04_16_000001_add_provider_role_to_package_items.php
frontend/lib/shared/screens/role_inventory_screen.dart    -- reusable stok per role
frontend/lib/shared/screens/role_fulfillment_screen.dart  -- reusable checklist per role
```

---

### 3. Form Persetujuan Layanan — Mandatory Gate Sebelum Konfirmasi Order

SO tidak dapat mengkonfirmasi order tanpa ServiceAcceptanceLetter yang sudah ditandatangani penuh (PJ + SM Officer).

**Perubahan `OrderController::confirm()`:**
- Cek `ServiceAcceptanceLetter` dengan `isFullySigned()` → return 422 + `error_code: ACCEPTANCE_LETTER_REQUIRED` jika belum
- `payment_method` wajib diisi (`cash` atau `transfer`)
- SAL draft otomatis dibuat saat order dibuat (`OrderController::store()`)

---

### 4. Tukang Jaga Shift System

Role baru `tukang_jaga` dengan sistem shift, check-in/checkout, upah dinamis, dan rantai konfirmasi penerimaan barang.

#### Tabel Baru
```sql
-- Konfigurasi upah dinamis per shift type
tukang_jaga_wage_configs: id, label, shift_type (pagi/siang/malam/full_day), rate, currency, is_active

-- Shift per order
tukang_jaga_shifts: id, order_id, shift_number, shift_type, scheduled_start, scheduled_end,
  assigned_to UUID, checkin_at, checkout_at, checkin_verified_by, status (scheduled/active/completed/missed),
  wage_config_id, wage_amount, wage_paid, notes

-- Pengiriman barang ke tukang jaga
tukang_jaga_item_deliveries: id, order_id, shift_id, delivered_by, delivered_by_role,
  received_by, family_confirmed_by, status (delivered/received_by_jaga/confirmed_by_family),
  delivered_at, received_at, family_confirmed_at, photos JSONB, notes

-- Line items per pengiriman
tukang_jaga_delivery_items: id, delivery_id, item_name, quantity, unit, notes
```

#### API Endpoints — Tukang Jaga
```
-- Tukang Jaga (role: tukang_jaga)
GET    /v1/tukang-jaga/shifts                       -- shift saya
GET    /v1/tukang-jaga/shifts/{id}                  -- detail shift
POST   /v1/tukang-jaga/shifts/{id}/checkin          -- check-in (boleh 15 menit lebih awal)
POST   /v1/tukang-jaga/shifts/{id}/checkout         -- checkout + hitung upah
GET    /v1/tukang-jaga/orders/{orderId}/deliveries  -- pengiriman masuk ke saya
POST   /v1/tukang-jaga/deliveries/{id}/receive      -- konfirmasi terima barang

-- Driver (kirim ke tukang jaga)
POST   /v1/driver/orders/{orderId}/deliver-to-jaga  -- buat delivery ke tukang jaga aktif

-- Consumer (konfirmasi keluarga)
GET    /v1/consumer/orders/{orderId}/deliveries     -- list pengiriman dari tukang jaga
POST   /v1/consumer/deliveries/{id}/confirm         -- konfirmasi keluarga terima

-- Admin (management)
GET    /v1/admin/tukang-jaga/wage-configs           -- list konfigurasi upah
POST   /v1/admin/tukang-jaga/wage-configs           -- buat konfigurasi upah baru
PUT    /v1/admin/tukang-jaga/wage-configs/{id}      -- update
GET    /v1/admin/orders/{orderId}/shifts             -- semua shift per order
POST   /v1/admin/orders/{orderId}/shifts/generate   -- generate otomatis: {days, shifts_per_day, shift_types[], wage_config_id}
PUT    /v1/admin/shifts/{id}/assign                 -- assign tukang jaga + alarm FCM
```

**Rantai konfirmasi barang:**
`Driver kirim → Tukang Jaga konfirmasi terima (requires active checkin) → Keluarga konfirmasi`

**Upah:**
- Dihitung otomatis saat checkout berdasarkan `wage_config.rate` sesuai `shift_type`
- Upah dikirim alarm ke Purchasing untuk proses pembayaran

#### File Baru
```
backend/app/Models/TukangJagaShift.php
backend/app/Models/TukangJagaWageConfig.php
backend/app/Models/TukangJagaItemDelivery.php
backend/app/Models/TukangJagaDeliveryItem.php
backend/app/Http/Controllers/TukangJaga/ShiftController.php
backend/app/Http/Controllers/TukangJaga/DeliveryController.php
backend/app/Http/Controllers/Driver/TukangJagaDeliveryController.php
backend/app/Http/Controllers/Consumer/FamilyDeliveryController.php
backend/app/Http/Controllers/Admin/TukangJagaManagementController.php
database/migrations/2026_04_16_000003_create_tukang_jaga_tables.php
```

**Flutter screens pending (belum diimplementasikan):**
- `frontend/lib/modules/tukang_jaga/screens/tukang_jaga_shift_list_screen.dart`
- `frontend/lib/modules/tukang_jaga/screens/tukang_jaga_checkin_screen.dart`
- `frontend/lib/modules/tukang_jaga/screens/tukang_jaga_receive_delivery_screen.dart`
- `frontend/lib/modules/consumer/screens/consumer_delivery_confirmation_screen.dart`
- `frontend/lib/modules/driver/screens/driver_deliver_to_jaga_screen.dart`
- `frontend/lib/modules/admin/screens/admin_shift_management_screen.dart`
- `frontend/lib/modules/admin/screens/admin_wage_config_screen.dart`

---

### 5. Payment Method Bifurcation (Cash vs Transfer)

```sql
-- orders table tambahan
ALTER TABLE orders ADD COLUMN cash_received_at TIMESTAMP;
ALTER TABLE orders ADD COLUMN cash_received_by UUID REFERENCES users(id);
```

**Aturan:**
- `payment_method = 'cash'` → Finance cukup mark `POST /finance/orders/{id}/cash-paid`, tidak perlu upload bukti
- `payment_method = 'transfer'` → alur bukti transfer tetap seperti biasa
- `payment_method` wajib diisi saat SO konfirmasi order

```
POST /v1/finance/orders/{id}/cash-paid   -- mark cash paid (hanya untuk cash order)
```

---

### 6. Ringkasan File Baru / Diubah v1.29

```
-- Backend (Baru)
database/migrations/2026_04_16_000001_add_provider_role_to_package_items.php
database/migrations/2026_04_16_000002_create_roles_table_and_convert_users_role.php
database/migrations/2026_04_16_000003_create_tukang_jaga_tables.php
database/migrations/2026_04_16_000004_add_payment_method_gate_to_orders.php
app/Models/Role.php
app/Models/TukangJagaShift.php
app/Models/TukangJagaWageConfig.php
app/Models/TukangJagaItemDelivery.php
app/Models/TukangJagaDeliveryItem.php
app/Http/Controllers/SuperAdmin/RoleController.php
app/Http/Controllers/RoleStock/RoleStockController.php
app/Http/Controllers/TukangJaga/ShiftController.php
app/Http/Controllers/TukangJaga/DeliveryController.php
app/Http/Controllers/Driver/TukangJagaDeliveryController.php
app/Http/Controllers/Consumer/FamilyDeliveryController.php
app/Http/Controllers/Admin/TukangJagaManagementController.php

-- Backend (Diubah)
app/Enums/UserRole.php                   -- tambah TUKANG_JAGA case
app/Models/PackageItem.php               -- tambah provider_role, fulfillment_notes
app/Models/StockItem.php                 -- tambah owner_role
app/Http/Controllers/SuperAdmin/UserController.php  -- role validation via DB
app/Http/Controllers/ServiceOfficer/OrderController.php  -- SAL gate, payment_method
app/Http/Controllers/Finance/ConsumerPaymentController.php  -- cash-paid endpoint
app/Services/NotificationService.php    -- fix hardcoded role strings
app/Services/OrderAutoGenerateService.php -- fix hardcoded role strings
app/Http/Controllers/Admin/PackageController.php -- provider_role support
routes/api.php                           -- semua route baru

-- Frontend (Baru)
lib/shared/constants/role_constants.dart
lib/shared/screens/role_inventory_screen.dart
lib/shared/screens/role_fulfillment_screen.dart
lib/modules/super_admin/screens/super_admin_role_management_screen.dart
```

---

# SANTA MARIA — PATCH v1.30
# Laporan Keuangan Otomatis, Koreksi Manual, Export PDF/Excel

---

## LATAR BELAKANG

Santa Maria adalah perusahaan yang sudah besar dan kompleks. Seluruh transaksi keuangan — pembayaran consumer, pengadaan (procurement), upah tukang jaga, pengeluaran vendor — sudah tercatat di database. Sistem laporan keuangan harus **otomatis mengagregasi data yang sudah ada**, tanpa input manual, namun Finance/Owner dapat **mengoreksi** dengan audit trail.

**Prinsip:**
- Tidak ada input ulang data — semua dari transaksi yang sudah ada
- Laporan real-time, selalu up-to-date
- Koreksi manual harus meninggalkan jejak audit (siapa, kapan, alasan)
- Export ke PDF dan Excel
- Dinamis: filter periode, kategori layanan, role vendor, dll

---

## SKEMA DATABASE

### Tabel `financial_transactions`

Tabel pusat agregasi keuangan. Di-populate otomatis oleh event: order confirmed, payment verified, procurement approved, wage paid, dll.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
transaction_type VARCHAR(50) NOT NULL
  -- INCOME: order_payment
  -- EXPENSE: procurement, tukang_jaga_wage, vendor_payment, operational
  -- ADJUSTMENT: manual_correction

reference_type VARCHAR(50) NULLABLE    -- 'order', 'procurement', 'shift', 'vendor', dll
reference_id UUID NULLABLE            -- FK ke tabel sumber
order_id UUID NULLABLE REFERENCES orders(id) ON DELETE SET NULL

amount DECIMAL(15,2) NOT NULL         -- selalu positif
direction ENUM('in','out') NOT NULL   -- in = pendapatan, out = pengeluaran
currency VARCHAR(10) DEFAULT 'IDR'

category VARCHAR(100) NOT NULL
  -- Kategori pendapatan: 'jasa_funeral', 'paket_dasar', 'paket_premium', 'paket_eksklusif', 'add_on'
  -- Kategori pengeluaran: 'pengadaan', 'upah_tukang_jaga', 'vendor_dekor', 'vendor_konsumsi',
  --                       'vendor_pemuka_agama', 'vendor_foto', 'vendor_angkat_peti', 'operasional'

description TEXT NULLABLE
transaction_date DATE NOT NULL        -- tanggal transaksi terjadi
recorded_at TIMESTAMP DEFAULT now()  -- kapan dicatat di sistem
recorded_by UUID REFERENCES users(id) ON DELETE SET NULL

-- Untuk koreksi manual
is_correction BOOLEAN DEFAULT FALSE
original_transaction_id UUID NULLABLE REFERENCES financial_transactions(id)
correction_reason TEXT NULLABLE
corrected_at TIMESTAMP NULLABLE
corrected_by UUID NULLABLE REFERENCES users(id)

-- Metadata
metadata JSONB DEFAULT '{}'          -- data tambahan (nama almarhum, SO, dll)
is_void BOOLEAN DEFAULT FALSE        -- dibatalkan
voided_at TIMESTAMP NULLABLE
voided_by UUID NULLABLE REFERENCES users(id)
void_reason TEXT NULLABLE

created_at TIMESTAMP
updated_at TIMESTAMP

INDEX: (transaction_date), (transaction_type), (category), (order_id), (direction), (is_void)
```

### Tabel `financial_reports`

Cache laporan yang di-generate. Dihitung ulang otomatis setiap jam via scheduler.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
report_type VARCHAR(50) NOT NULL      -- 'monthly_summary', 'annual_summary', 'order_summary'
period_year INTEGER NOT NULL
period_month INTEGER NULLABLE         -- NULL untuk annual
generated_at TIMESTAMP DEFAULT now()
data JSONB NOT NULL                  -- hasil agregasi lengkap

-- Koreksi manual pada ringkasan
manual_notes TEXT NULLABLE
reviewed_by UUID NULLABLE REFERENCES users(id)
reviewed_at TIMESTAMP NULLABLE

created_at TIMESTAMP
updated_at TIMESTAMP

UNIQUE: (report_type, period_year, period_month)
```

---

## OTOMASI — Event Triggers ke `financial_transactions`

| Event | transaction_type | direction | category | Dipicu oleh |
|-------|-----------------|-----------|----------|-------------|
| Order payment verified (transfer) | `order_payment` | `in` | `jasa_funeral` / sesuai paket | `ConsumerPaymentController::verify()` |
| Order payment cash confirmed | `order_payment` | `in` | `jasa_funeral` / sesuai paket | `ConsumerPaymentController::markCashPaid()` |
| Procurement PO approved | `procurement` | `out` | `pengadaan` | `ProcurementController::approve()` |
| Tukang jaga checkout | `tukang_jaga_wage` | `out` | `upah_tukang_jaga` | `ShiftController::checkout()` |
| Vendor payment approved | `vendor_payment` | `out` | `vendor_[role]` | `VendorPaymentController::approve()` |
| Manual correction | `manual_correction` | `in`/`out` | bebas | Finance/Owner via API |

**Implementasi:** Buat `FinancialTransactionService::record(array $data)` — dipanggil dari masing-masing controller. Bukan event listener untuk menghindari silent failure.

---

## API ENDPOINTS — Laporan Keuangan

```
-- Semua endpoint ini role: finance, owner

-- Dashboard ringkasan
GET /v1/finance/dashboard
  Response: {
    this_month: { income, expense, profit, order_count },
    last_month: { income, expense, profit, order_count },
    this_year: { income, expense, profit },
    pending_payments: [{ order_id, consumer_name, amount, due_date }],
    unpaid_wages: [{ shift_id, tukang_jaga_name, amount }]
  }

-- Laporan per periode
GET /v1/finance/reports/summary
  Query: ?year=2026&month=4         -- month opsional (kosong = annual)
  Response: {
    period, income_total, expense_total, profit,
    income_by_category: [{category, total}],
    expense_by_category: [{category, total}],
    order_count, avg_order_value
  }

-- Laporan per order
GET /v1/finance/reports/orders
  Query: ?from=2026-01-01&to=2026-12-31&status=paid
  Response: paginated list [{
    order_id, order_code, consumer_name, deceased_name,
    package_name, total_amount, paid_at, payment_method,
    expense_total, profit
  }]

-- Laporan piutang (belum lunas)
GET /v1/finance/reports/receivables
  Response: [{
    order_id, order_code, consumer_name, total_amount,
    payment_method, order_date, days_outstanding
  }]

-- Laporan pengeluaran
GET /v1/finance/reports/expenses
  Query: ?from=&to=&category=
  Response: paginated [{
    date, transaction_type, category, description, amount, reference
  }]

-- Raw transactions (untuk audit)
GET /v1/finance/transactions
  Query: ?from=&to=&type=&category=&direction=&search=&page=
  Response: paginated financial_transactions

-- Koreksi manual (Finance/Owner only)
POST /v1/finance/transactions/correction
  Body: { direction, amount, category, description, transaction_date,
          original_transaction_id (nullable), correction_reason }

-- Void transaksi
PUT /v1/finance/transactions/{id}/void
  Body: { void_reason }

-- Export
GET /v1/finance/reports/export
  Query: ?type=monthly_summary&year=2026&month=4&format=pdf
  Query: ?type=order_list&from=&to=&format=xlsx
  Response: file download (PDF via DomPDF, Excel via Laravel Excel / maatwebsite/excel)
```

---

## FLUTTER — Screens Laporan Keuangan

```
lib/modules/finance/screens/
  ├── finance_dashboard_screen.dart
  │     -- Card: Pendapatan bulan ini vs bulan lalu (% change)
  │     -- Card: Pengeluaran bulan ini
  │     -- Card: Laba bersih
  │     -- Chart: Bar chart pendapatan 6 bulan terakhir (fl_chart)
  │     -- List: Piutang belum lunas
  │     -- List: Upah tukang jaga belum dibayar
  │
  ├── finance_report_screen.dart
  │     -- Dropdown: pilih tahun + bulan (atau annual)
  │     -- Tabel summary: pendapatan/pengeluaran per kategori
  │     -- Pie chart: komposisi pendapatan
  │     -- Tombol Export PDF / Export Excel
  │
  ├── finance_order_report_screen.dart
  │     -- Filter: date range, payment status
  │     -- Tabel: per order (order code, consumer, amount, profit)
  │     -- Tap order → detail transaksi order
  │
  ├── finance_transaction_list_screen.dart
  │     -- Filter: type, category, direction, date range
  │     -- List semua transaksi
  │     -- FAB: Tambah koreksi manual
  │     -- Long-press → void transaksi (dengan alasan)
  │
  └── finance_correction_form_screen.dart
        -- Form koreksi manual
        -- Input: arah (in/out), nominal, kategori, tanggal, deskripsi, alasan
        -- Link ke transaksi asal (opsional)
```

---

## BACKEND — Service & File Baru

```
-- Service
app/Services/FinancialTransactionService.php
  - record(array $data): FinancialTransaction
  - voidTransaction(string $id, string $reason, User $by): void
  - generateMonthlySummary(int $year, int $month): array
  - generateAnnualSummary(int $year): array
  - exportPdf(string $type, array $params): BinaryFileResponse
  - exportExcel(string $type, array $params): BinaryFileResponse

-- Controllers
app/Http/Controllers/Finance/FinanceDashboardController.php
app/Http/Controllers/Finance/FinanceReportController.php
app/Http/Controllers/Finance/FinanceTransactionController.php

-- Models
app/Models/FinancialTransaction.php
app/Models/FinancialReport.php

-- Migrations
database/migrations/2026_04_16_000005_create_financial_transactions_table.php
database/migrations/2026_04_16_000006_create_financial_reports_table.php

-- Exports (maatwebsite/excel)
app/Exports/OrderReportExport.php
app/Exports/TransactionExport.php

-- PDF Views
resources/views/reports/monthly_summary.blade.php
resources/views/reports/order_list.blade.php

-- Scheduler (app/Console/Kernel.php)
$schedule->call(fn() => FinancialReport::regenerateAll())->hourly();
```

---

## EVALUASI FLOW KESELURUHAN (Gap Analysis)

### Alur Order — Status Lengkap

| Step | Actor | Status | Implementasi |
|------|-------|--------|-------------|
| 1. Buat order | SO | `draft` | ✅ |
| 2. Isi Form Persetujuan (SAL) + TTD digital | SO + PJ + SM | `draft` | ✅ |
| 3. Konfirmasi order (SAL gate + payment_method) | SO | `confirmed` | ✅ |
| 4. Auto-distribute alarm ke semua role | Sistem | - | ✅ |
| 5. Masing-masing role fulfill checklist | Per role | per-item | ✅ (role-agnostic) |
| 6. Driver assign + GPS tracking | AI/Sistem | - | ✅ |
| 7. Vendor (dekor, konsumsi, dll) upload bukti | Vendor | - | ✅ |
| 8. Tukang jaga check-in shift | Tukang Jaga | - | ✅ Backend, ⬜ Flutter |
| 9. Driver/gudang kirim barang ke tukang jaga | Driver | - | ✅ Backend, ⬜ Flutter |
| 10. Tukang jaga konfirmasi terima | Tukang Jaga | - | ✅ Backend, ⬜ Flutter |
| 11. Keluarga konfirmasi terima | Consumer | - | ✅ Backend, ⬜ Flutter |
| 12. Consumer bayar (cash/transfer) | Consumer | - | ✅ |
| 13. Finance verifikasi/mark cash paid | Finance | `paid` | ✅ |
| 14. Transaksi keuangan dicatat otomatis | Sistem | - | ⬜ v1.30 |
| 15. Order auto-complete | Sistem | `completed` | ✅ |
| 16. Laporan keuangan ter-update | Sistem | - | ⬜ v1.30 |

### Gap Lain yang Perlu Diperhatikan

**A. Laporan Keuangan** — ⬜ Belum ada, perlu patch v1.30

**B. Flutter Screens Pending (v1.29)**
- Tukang Jaga: shift list, check-in/out, receive delivery
- Consumer: konfirmasi penerimaan barang
- Driver: deliver to tukang jaga
- Admin: shift management, wage config

**C. HRD Violation Flutter Screen** — backend ada, Flutter screen belum pernah dikonfirmasi

**D. Supplier e-Katalog** — ada di spec v1.x, perlu audit apakah sudah full-implemented

**E. Owner Dashboard** — sudah ada controller, perlu audit kelengkapan data finansial

**F. Tukang Angkat Peti** — ada sebagai role tapi belum ada workflow spesifik

---

# SANTA MARIA — PATCH v1.31
# Klarifikasi Operasional dari Owner — Koreksi Spec vs Kenyataan Lapangan

---

## FAKTA OPERASIONAL YANG DIKONFIRMASI OWNER

### 1. LOKASI FISIK — 3 Pusat Inventaris Terpisah

```
Santa Maria BUKAN punya rumah duka. SM = jasa funeral organizer murni.

3 LOKASI INVENTARIS TERPISAH (masing-masing punya stok & driver sendiri):
  ┌─────────────┐   ┌─────────────┐   ┌──────────────┐
  │   KANTOR    │   │   GUDANG    │   │  LAFIORE     │
  │  (stok A)   │   │  (stok B)   │   │  (stok C)    │
  │  driver(s)  │   │  driver(s)  │   │  driver(s)   │
  └──────┬──────┘   └──────┬──────┘   └──────┬───────┘
         │                 │                  │
         └────────┬────────┘──────────────────┘
                  ▼
          RUMAH DUKA (milik pihak ketiga)
                  │
                  ▼
             PEMAKAMAN (banyak, database per kota)
```

**KOREKSI BESAR dari spec sebelumnya:**
- Spec lama: hanya Gudang yang punya stok. Kantor & Lafiore tidak disebut.
- **Kenyataan:** Kantor menyimpan barang sendiri. Lafiore menyimpan barang sendiri.
- **Dampak:** `stock_items.owner_role` (dari v1.29) WAJIB digunakan.
  - Gudang: `owner_role = 'gudang'`
  - Kantor: `owner_role = 'service_officer'` atau `owner_role = 'kantor'` (role baru?)
  - Lafiore: `owner_role = 'dekor'`
- **Saat order dikonfirmasi:** KETIGA lokasi harus konfirmasi ketersediaan masing-masing.
  Alarm dikirim ke: Gudang, Kantor (SO), DAN Lafiore secara paralel.

### 2. BARANG — Pinjam vs Keluar

```
Setiap barang yang keluar dari inventaris punya 2 sifat:

PINJAMAN (returnable):
  → Ada form keluar: siapa kirim, siapa terima, tanggal
  → Ada form kembali: siapa kembalikan, siapa terima, tanggal, kondisi
  → Tagihan consumer DIKURANGI jika barang dikembalikan
  → Contoh: sound system, meja, taplak, koper misa, kardus air

BARANG KELUAR (consumed):
  → Keluar = habis, tidak kembali
  → Dihitung penuh di tagihan
  → Contoh: cologne, lilin, embalming fluid, kapur

(Sudah ada di v1.18 sebagai 'sewa' & 'pakai_habis' & 'pakai_kembali' — SUDAH BENAR)
```

### 3. RUMAH DUKA — Bukan Milik SM

```
- Santa Maria TIDAK memiliki rumah duka
- Rumah duka selalu milik pihak ketiga (Bethesda, Sion, dll)
- SM datang ke rumah duka untuk melayani
- Perlu tabel/database rumah duka yang pernah dipakai (sortir per kota)
```

### 4. PEMAKAMAN — Database Dinamis per Kota

```
- Banyak pemakaman yang dipakai
- Perlu tabel master `cemeteries`:
  id, name, city, address, lat, lng, contact_phone, notes, is_active
- Saat SO input order → autocomplete dari database pemakaman
- Pemakaman baru bisa ditambahkan saat pertama kali dipakai
```

### 5. DRIVER — Multi-Driver, Multi-Sumber, Masalah Barang Nyangkut

```
KENYATAAN:
- Ada BANYAK driver (bukan 1 per order)
- Gudang, Kantor, dan Lafiore masing-masing punya driver sendiri
- Saat order: ketiga lokasi kirim barang ke rumah duka MASING-MASING

ALUR DRIVER (typical):
  1. Ambil barang di gudang/kantor/lafiore
  2. Antar ke rumah duka → serah terima ke tukang jaga
  3. Dari rumah duka → jemput jenazah di RS/rumah
  4. Antar jenazah ke rumah duka
  5. (Saat prosesi selesai) Antar jenazah ke pemakaman
  6. Kembali ke rumah duka → ambil barang dari tukang jaga (serah terima)
  7. Kembalikan barang ke gudang/kantor/lafiore

MASALAH NYATA (butuh solusi AI):
  Driver malas kembali ke gudang karena jauh → barang STUCK di kantor.
  Solusi yang dibutuhkan:
  - AI deteksi barang yang belum kembali ke lokasi asal
  - Alert ke gudang/kantor/lafiore: "Barang order X masih di [lokasi]"
  - AI suggest: "Driver Y sedang di dekat kantor, bisa sekalian bawa ke gudang"
  - Tracking status barang: di gudang / di perjalanan / di rumah duka / di kantor (stuck) / kembali
```

### 6. LAFIORE — Tim Internal dengan Stok Sendiri

```
- Lafiore = divisi dekorasi internal SM (BUKAN vendor luar)
- Digaji bulanan oleh SM
- Punya stok bunga & dekorasi sendiri
- Bahan baku di-request ke Purchasing → Purchasing pilih supplier
- Punya kendaraan sendiri untuk kirim ke rumah duka
- Saat order: Lafiore konfirmasi ketersediaan stok dekorasi sendiri
```

### 7. KONSUMSI — Dari Supplier, Bukan SM

```
- SM TIDAK menyediakan konsumsi/katering sendiri
- Konsumsi diorder dari supplier luar
- Purchasing yang handle pemesanan ke supplier konsumsi
- Supplier kirim langsung ke rumah duka (bukan via driver SM)
```

### 8. TUKANG JAGA — Pekerja Lepas per Order

```
- Tukang jaga = orang LUAR, direkrut per order
- Bukan karyawan tetap SM
- Shift: PAGI dan MALAM (2 shift per hari)
- Durasi: tergantung berapa hari keluarga mau di rumah duka
- Upah: per shift, sudah ditentukan rate-nya
- Tugas utama:
  → Jaga rumah duka (barang SM & keluarga)
  → Terima serah terima barang dari driver
  → Serahkan barang kembali ke driver saat prosesi selesai
  → Jaga keamanan & kenyamanan
```

### 9. PEMBAYARAN CONSUMER — Setelah Prosesi, Dikurangi Retur

```
- Keluarga bayar SETELAH prosesi selesai
- Deadline: maksimal 3 hari setelah selesai
- Total tagihan DIKURANGI barang yang dikembalikan
  Contoh: pesan 10 kardus air, kembali 3 → bayar 7 kardus saja
- Metode: cash atau transfer
- Yang menagih: Purchasing/Finance
```

### 10. PURCHASING/FINANCE — Pusat Semua Pembayaran

```
Purchasing/Finance handle SEMUA transaksi keluar:
  ├── Bayar supplier (konsumsi, bahan dekorasi, dll)
  ├── Bayar pekerja lepas (tukang jaga, tukang angkat peti, musisi)
  ├── Bayar request barang dari SEMUA role (termasuk Owner)
  ├── Verifikasi pembayaran masuk dari consumer
  └── Bayar pemuka agama
```

### 11. OWNER — Monitor Only, Intervensi saat Anomali

```
- Owner hanya monitor dashboard
- Owner TIDAK operasional sehari-hari
- Owner intervensi (marah/perintah) hanya saat ada anomali
- Fitur Owner Command (v1.29) sudah tepat untuk ini
```

### 12. SECURITY — Jaga Kantor, Lapor Tamu

```
- Security hanya jaga kantor fisik
- Tugas: awasi kantor, laporkan tamu/pihak luar yang datang
- BUKAN jaga rumah duka (itu tugas tukang jaga)
```

### 13. HRD — Termasuk Sistem Gaji Berbasis Performa

```
BARU — BELUM ADA DI SPEC SEBELUMNYA:

HRD mengelola gaji berbasis performa (performance-based pay).

Formula:
  gaji_aktual = gaji_pokok × (tasks_completed / tasks_assigned)

Contoh:
  Purchasing gaji pokok Rp 3.000.000
  Bulan ini: 100 tugas masuk, hanya selesaikan 60
  Gaji = Rp 3.000.000 × 60% = Rp 1.800.000

Ini berarti perlu:
  - Tabel konfigurasi gaji pokok per role/user
  - Tracking otomatis: berapa tugas masuk, berapa yang diselesaikan
  - Perhitungan otomatis gaji per bulan
  - Integrasi dengan KPI (v1.16) — KPI score bisa jadi multiplier
  - Dashboard HRD: slip gaji per karyawan per bulan
```

---

## DATABASE — TABEL BARU v1.31

### Tabel `funeral_homes` (Database Rumah Duka)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
name VARCHAR(255) NOT NULL                   -- "Rumah Duka Bethesda"
city VARCHAR(100) NOT NULL                   -- "Semarang"
address TEXT NULLABLE
lat DECIMAL(10,7) NULLABLE
lng DECIMAL(10,7) NULLABLE
contact_phone VARCHAR(30) NULLABLE
contact_person VARCHAR(255) NULLABLE
notes TEXT NULLABLE
usage_count INTEGER DEFAULT 0               -- berapa kali dipakai (auto-increment)
is_active BOOLEAN DEFAULT TRUE
created_at TIMESTAMP
updated_at TIMESTAMP

INDEX: (city), (name), (usage_count DESC)
```

### Tabel `cemeteries` (Database Pemakaman per Kota)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
name VARCHAR(255) NOT NULL                   -- "Pemakaman Bergota"
city VARCHAR(100) NOT NULL                   -- "Semarang"
address TEXT NULLABLE
lat DECIMAL(10,7) NULLABLE
lng DECIMAL(10,7) NULLABLE
cemetery_type ENUM('umum','khusus_agama','krematorium','taman_makam') DEFAULT 'umum'
contact_phone VARCHAR(30) NULLABLE
notes TEXT NULLABLE
usage_count INTEGER DEFAULT 0
is_active BOOLEAN DEFAULT TRUE
created_at TIMESTAMP
updated_at TIMESTAMP

INDEX: (city), (name), (cemetery_type)
```

### Tabel `employee_salaries` (Gaji Pokok & Performa)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id UUID REFERENCES users(id)
base_salary DECIMAL(15,2) NOT NULL           -- gaji pokok
effective_date DATE NOT NULL                 -- berlaku mulai
end_date DATE NULLABLE                       -- NULL = masih berlaku
salary_type ENUM('fixed','performance_based') DEFAULT 'performance_based'
-- fixed: gaji tetap (misal: owner, super_admin)
-- performance_based: gaji × (completed/assigned)
notes TEXT NULLABLE
created_by UUID REFERENCES users(id)
created_at TIMESTAMP
updated_at TIMESTAMP
```

### Tabel `monthly_payroll` (Slip Gaji Bulanan — Auto-Generated)

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id UUID REFERENCES users(id)
period_year INTEGER NOT NULL
period_month INTEGER NOT NULL
base_salary DECIMAL(15,2) NOT NULL           -- snapshot gaji pokok
tasks_assigned INTEGER DEFAULT 0             -- total tugas yang masuk
tasks_completed INTEGER DEFAULT 0            -- total tugas yang diselesaikan
completion_rate DECIMAL(5,2) DEFAULT 0       -- tasks_completed / tasks_assigned × 100
kpi_score DECIMAL(5,2) NULLABLE              -- dari kpi_user_summary (opsional multiplier)
calculated_salary DECIMAL(15,2) NOT NULL     -- base × completion_rate
adjustments DECIMAL(15,2) DEFAULT 0          -- bonus/potongan manual
final_salary DECIMAL(15,2) NOT NULL          -- calculated + adjustments
adjustment_notes TEXT NULLABLE
status ENUM('draft','reviewed','approved','paid') DEFAULT 'draft'
reviewed_by UUID NULLABLE REFERENCES users(id)
approved_by UUID NULLABLE REFERENCES users(id)
paid_at TIMESTAMP NULLABLE
created_at TIMESTAMP
updated_at TIMESTAMP

UNIQUE(user_id, period_year, period_month)
```

### Tabel `item_location_tracking` (Tracking Lokasi Barang Antar Lokasi)

Solusi untuk masalah "barang stuck di kantor".

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
order_id UUID REFERENCES orders(id)
stock_item_id UUID NULLABLE REFERENCES stock_items(id)
equipment_item_id UUID NULLABLE REFERENCES order_equipment_items(id)
item_description VARCHAR(255) NOT NULL

-- Asal & tujuan
origin_type ENUM('gudang','kantor','lafiore','rumah_duka','pemakaman','other') NOT NULL
origin_label VARCHAR(255) NOT NULL
destination_type ENUM('gudang','kantor','lafiore','rumah_duka','pemakaman','other') NOT NULL
destination_label VARCHAR(255) NOT NULL

-- Status
current_location_type ENUM('gudang','kantor','lafiore','rumah_duka','pemakaman','in_transit','other') NOT NULL
current_location_label VARCHAR(255) NOT NULL
status ENUM(
  'at_origin',           -- masih di lokasi asal
  'in_transit',          -- sedang diantar
  'at_destination',      -- sudah tiba di tujuan
  'returning',           -- sedang dikembalikan
  'returned',            -- sudah kembali ke asal
  'stuck',               -- stuck di lokasi lain (AI flag)
  'lost'                 -- hilang
) DEFAULT 'at_origin'

-- Serah terima
sent_by UUID NULLABLE REFERENCES users(id)
sent_at TIMESTAMP NULLABLE
received_by UUID NULLABLE REFERENCES users(id)
received_at TIMESTAMP NULLABLE
return_sent_by UUID NULLABLE REFERENCES users(id)
return_sent_at TIMESTAMP NULLABLE
return_received_by UUID NULLABLE REFERENCES users(id)
return_received_at TIMESTAMP NULLABLE

-- AI flag
is_stuck BOOLEAN DEFAULT FALSE               -- AI deteksi: barang > threshold di lokasi salah
stuck_since TIMESTAMP NULLABLE
stuck_alert_sent BOOLEAN DEFAULT FALSE
ai_suggestion TEXT NULLABLE                  -- "Driver Y dekat kantor, bisa sekalian bawa"

notes TEXT NULLABLE
created_at TIMESTAMP
updated_at TIMESTAMP

INDEX: (order_id), (status), (is_stuck), (current_location_type)
```

---

## KOREKSI ALUR ORDER — VERSI OPERASIONAL NYATA

```
╔══════════════════════════════════════════════════════════════════════╗
║  ALUR ORDER SANTA MARIA — KENYATAAN LAPANGAN v1.31                  ║
╚══════════════════════════════════════════════════════════════════════╝

STEP 1 — ORDER MASUK (3 channel: SO lapangan, Kantor/SO, Consumer app)
  → Status: pending

STEP 1.5 — SURAT PENERIMAAN LAYANAN + TANDA TANGAN (gate)
  → Status: awaiting_signature → signed

STEP 2 — SO KONFIRMASI (pilih paket, set jadwal, assign vendor)
  → Status: confirmed
  → PARALEL alarm ke 3 LOKASI INVENTARIS:
    ├── GUDANG: "Siapkan barang gudang untuk order X"
    ├── KANTOR: "Siapkan barang kantor untuk order X"
    └── LAFIORE: "Siapkan dekorasi untuk order X"
  → PARALEL alarm ke vendor:
    ├── Konsumsi supplier (via Purchasing)
    ├── Pemuka Agama
    └── Tukang Foto

STEP 3 — TIGA LOKASI SIAPKAN BARANG (PARALEL)
  Gudang centang checklist → "Stok Gudang Siap"
  Kantor centang checklist → "Stok Kantor Siap"
  Lafiore centang checklist → "Dekorasi Siap"
  → SEMUA harus siap sebelum driver berangkat

STEP 4 — DRIVER(S) KIRIM BARANG KE RUMAH DUKA
  Bisa >1 driver dari lokasi berbeda:
    Driver Gudang → bawa barang gudang ke rumah duka
    Driver Kantor → bawa barang kantor ke rumah duka
    Driver Lafiore → bawa dekorasi ke rumah duka
  → Serah terima ke TUKANG JAGA yang sedang shift
  → Form serah terima: pengirim, penerima, daftar barang, tanda tangan

STEP 5 — DRIVER JEMPUT JENAZAH
  Driver → RS/rumah → ambil jenazah → antar ke rumah duka
  → Consumer notif: "Jenazah telah tiba"

STEP 6 — PROSESI BERLANGSUNG (1-N hari)
  Tukang jaga shift pagi & malam bergantian
  Vendor (dekor, konsumsi, pemuka agama) bertugas
  Consumer bisa request amendment (tambahan)

STEP 7 — PROSESI SELESAI → PEMAKAMAN
  Driver antar jenazah ke pemakaman
  → Status: burial_completed

STEP 8 — PENGEMBALIAN BARANG
  Driver kembali ke rumah duka → serah terima dari tukang jaga
  → Form serah terima: barang keluar vs kembali, kondisi
  → Driver HARUS kembalikan ke lokasi ASAL:
    Barang gudang → gudang
    Barang kantor → kantor
    Barang lafiore → lafiore
  → AI MONITOR: jika barang tidak kembali ke asal dalam threshold:
    → Flag 'stuck' → alert ke lokasi asal + suggest driver terdekat

STEP 9 — TAGIHAN & PEMBAYARAN
  Purchasing hitung: total paket + addon - barang yang dikembalikan
  Consumer bayar (maks 3 hari setelah prosesi)
  Purchasing bayar: supplier, tukang jaga, pemuka agama, pekerja lepas

STEP 10 — POST-ORDER
  Akta kematian, laporan keuangan, KPI update, gaji update
```

---

## SCHEDULER BARU v1.31

```php
// Deteksi barang stuck di lokasi salah (setiap 2 jam)
$schedule->command('items:detect-stuck')->everyTwoHours();

// Generate payroll bulanan (tanggal 1 setiap bulan)
$schedule->command('payroll:generate-monthly')->monthlyOn(1, '03:00')
  ->timezone('Asia/Jakarta');

// AI suggest driver untuk ambil barang stuck (setiap 4 jam)
$schedule->command('items:suggest-return-driver')->everySixHours();
```

---

## ATURAN BISNIS v1.31

```
1. TIGA LOKASI INVENTARIS: Gudang, Kantor, Lafiore masing-masing
   punya stok dan driver sendiri. Saat order, KETIGA nya harus konfirmasi.

2. RUMAH DUKA bukan milik SM — selalu pihak ketiga. Perlu database
   rumah duka yang pernah dipakai (autocomplete saat input order).

3. PEMAKAMAN — database per kota, bisa ditambah saat pertama kali dipakai.

4. BARANG HARUS KEMBALI KE LOKASI ASAL — bukan sembarangan.
   Barang gudang → gudang. Barang kantor → kantor. Barang lafiore → lafiore.
   AI deteksi & alert jika barang stuck di lokasi salah.

5. LAFIORE = tim internal, bukan vendor. Digaji. Punya stok sendiri.

6. KONSUMSI = dari supplier luar, bukan SM. Supplier kirim langsung.

7. TUKANG JAGA = pekerja lepas per order. 2 shift: pagi & malam.
   Durasi sesuai permintaan keluarga.

8. PEMBAYARAN CONSUMER = setelah prosesi, maks 3 hari.
   Total dikurangi barang yang dikembalikan.

9. GAJI KARYAWAN = berbasis performa.
   gaji_aktual = gaji_pokok × (tasks_completed / tasks_assigned)

10. SECURITY = hanya jaga kantor, lapor tamu. Bukan jaga rumah duka.
```

---

# SANTA MARIA — PATCH v1.32
# Klarifikasi Operasional Lanjutan — Peti, Driver, Supplier, Tukang Angkat Peti, Serah Terima

---

## FAKTA OPERASIONAL LANJUTAN (DIKONFIRMASI OWNER)

### 1. PETI MATI — Hybrid: Beli Jadi ATAU Beli Kayu + Finishing di Gudang

```
Dua alur pengadaan peti:
  A. Beli peti jadi dari supplier → langsung pakai
  B. Beli kayu mentah dari supplier → finishing/percantik di gudang SM

Kedua alur melewati Purchasing (procurement).
Modul coffin_orders (workshop peti) di v1.14 TETAP RELEVAN untuk alur B.
```

### 2. DRIVER — Selalu Aktif, Auto-Assign Setelah Stok Clear

```
KOREKSI dari spec lama:
- HAPUS fitur "driver aktif/tidak aktif" — driver HARUS SELALU aktif
- Driver yang TIDAK sedang mengerjakan order → otomatis available
- Auto-assign driver: HANYA setelah SEMUA pihak (gudang, kantor, lafiore)
  konfirmasi stok tidak ada masalah
- Sistem pilih driver yang sedang tidak bertugas (bukan manual SO assign)
```

### 3. TUKANG ANGKAT PETI — Pekerja Lepas + Koordinator

```
- Tukang angkat peti = pekerja lepas per order
- Jumlah tergantung jenis/ukuran peti (dari master data peti)
- Ada KOORDINATOR tukang angkat peti:
  → Koordinator yang mengatur siapa yang kerja
  → Koordinator yang MENAGIH upah ke kantor (bukan per-orang)
  → Purchasing/Finance bayar ke koordinator (1 transaksi)
  → Koordinator distribusi ke anak buahnya sendiri (di luar sistem)
```

### 4. SERAH TERIMA BARANG — Rantai 3 Konfirmasi

```
KIRIM:
  Driver (gudang/kantor/lafiore) → Tukang Jaga → Consumer (via app)
  
  1. Driver antar barang ke rumah duka
  2. Tukang Jaga terima + tanda tangan di app
  3. Tukang Jaga taruh barang di rumah duka
  4. Consumer cek di app: "Barang yang diterima sudah sesuai?" + checklist
     → Consumer centang per item + confirm

KEMBALI:
  Tukang Jaga → Driver → Gudang/Kantor/Lafiore (masing-masing konfirmasi)
  
  1. Prosesi selesai
  2. Tukang Jaga serah terima barang ke Driver + tanda tangan
  3. Driver bawa ke lokasi ASAL masing-masing
  4. Penerima di lokasi asal (gudang/kantor/lafiore) WAJIB konfirmasi terima
     → Cek kondisi + qty → tanda tangan di app
```

### 5. BARANG STUCK — Detail Masalah

```
Masalah spesifik:
  - Barang GUDANG sering nyangkut di KANTOR
  - Alasan: gudang jauh dari rumah duka, kantor lebih dekat
  - Driver ambil jalan pintas: antar barang gudang ke kantor dulu, bukan langsung ke gudang

Solusi AI yang dibutuhkan:
  - Deteksi: barang asal gudang tapi current_location = kantor > threshold jam
  - Alert ke gudang: "X item dari order Y masih di kantor sejak Z jam lalu"
  - Suggest: "Driver A sedang di area kantor, bisa sekalian bawa ke gudang"
  - Eskalasi: jika stuck > 24 jam → alarm HRD + Owner
```

### 6. SUPPLIER — 2 Jenis

```
SUPPLIER TETAP:
  - Terdaftar di sistem, punya akun app
  - WAJIB install aplikasi
  - Ikut sistem bidding e-Katalog
  - Contoh: supplier peti, supplier bunga rutin, supplier air minum

SUPPLIER SEMENTARA:
  - Tidak terdaftar, tidak install app
  - Untuk kebutuhan one-time / darurat
  - Purchasing hubungi manual via WA
  - Transaksi tetap dicatat di sistem oleh Purchasing

Tambah kolom di users (supplier):
  supplier_type ENUM('permanent','temporary') DEFAULT 'permanent'
  -- permanent = terdaftar, app, bidding
  -- temporary = manual, WA, dicatat Purchasing
```

### 7. BIDDING e-KATALOG — Mekanisme Harga

```
Contoh alur bidding:
  1. Purchasing buat sayembara: "Butuh Air Minum 10 kardus, budget Rp 10.000/kardus"
  2. Supplier A tawar: Rp 10.000
  3. Supplier B tawar: Rp 11.500
  4. Supplier C tawar: Rp 11.700
  5. Yang TERMURAH dipilih (kewenangan Purchasing)
  6. AI bantu: tampilkan harga pasaran real-time sebagai referensi

CATATAN: Supplier boleh tawar DI ATAS budget (misal budget 10.000, tawar 11.500)
  → Purchasing yang putuskan apakah masih wajar
  → AI flag jika harga > X% di atas pasaran
```

### 8. WHATSAPP — Scope Terbatas

```
WA hanya dipakai untuk:
  1. SO → Consumer: "Install app ini untuk track order"
  2. Purchasing → Supplier sementara: koordinasi manual
  
WA BUKAN alat koordinasi internal lagi — semua via app.
```

---

## ITEM YANG BELUM DIKONFIRMASI (PENDING OWNER)

```
⏳ Detail paket layanan (nama, harga, isi per lokasi) — OWNER AKAN KASIH
⏳ Detail add-on yang tersedia — OWNER AKAN KASIH
⏳ Barang apa saja di Kantor vs Gudang — OWNER AKAN KONFIRMASI
⏳ Detail barang Lafiore — OWNER AKAN KONFIRMASI
⏳ Siapa yang assign driver dari mana — OWNER AKAN KONFIRMASI
   (sementara: sistem otomatis, setelah semua stok clear)

🔔 REMINDER: Setiap kali membahas PAKET LAYANAN, tanyakan ulang ke owner
   apakah detail paket sudah siap dikonfirmasi.
```

---

# SANTA MARIA — PATCH v1.33
# Klarifikasi Operasional Lanjutan 2 — Prosesi, Kendaraan, Keuangan, Consumer

---

## FAKTA OPERASIONAL LANJUTAN 2 (DIKONFIRMASI OWNER)

### 1. SO = Komandan Lapangan

```
- SO HADIR FISIK di rumah duka saat pelaksanaan prosesi
- SO = komandan lapangan, mengkoordinasi semua pihak di lokasi
- SO adalah orang internal SM
```

### 2. Pemuka Agama — Selalu 1, Selalu dari Keagamaan

```
- 1 pemuka agama per order
- Bukan dari SM — dari lembaga keagamaan
- SM yang assign (internal DB) atau consumer yang request (external vendor v1.24)
```

### 3. Tukang Foto — Sistem Upah, Upload Google Drive Link

```
ALUR TUKANG FOTO:
  1. Tukang foto = pekerja lepas sistem upah (bukan karyawan tetap)
  2. Ambil order → dokumentasi foto/video di rumah duka
  3. Setelah selesai → upload ke Google Drive
  4. Di app: tautkan link Google Drive ke order
  5. Setelah link ditautkan → pekerjaan dianggap SELESAI
  6. Upah dihitung setelah melewati waktu prosesi + link sudah di-submit

Consumer bisa akses link Google Drive SETELAH pembayaran lunas.
```

### 4. Kendaraan — Fully Dynamic, Admin Input Manual

```
KOREKSI dari spec lama:
- TIDAK ada asumsi fixed jumlah kendaraan
- Semua kendaraan di-input manual oleh Admin/Super Admin
- Setiap kendaraan punya atribut:
  → Milik unit mana: gudang / kantor / lafiore
  → Tipe: mobil jenazah / van / pickup / bus / dll
  → Peruntukan paket: "Khusus Paket Premium" atau "Semua paket"
  → Status: available / in_use / maintenance
- FALLBACK: jika mobil jenazah paket A habis → otomatis alihkan ke mobil paket B
- Sistem harus DINAMIS — jangan hardcode jumlah atau tipe
```

### 5. Tukang Jaga — Switch Shift Wajib Konfirmasi

```
KOREKSI/TAMBAHAN:
- Tukang jaga lapor langsung ke APP (bukan ke SO/koordinator)
- Saat mau off shift: WAJIB switch dengan tukang jaga shift berikutnya
- Ada KONFIRMASI antar tukang jaga saat peralihan shift:
  → Tukang jaga shift 1: "Saya serah terima ke [nama]" → tandatangan
  → Tukang jaga shift 2: "Saya terima shift dari [nama]" → tandatangan
  → Baru shift 1 bisa checkout
- Tukang jaga HARUS datang — tidak ada mekanisme cadangan
- Makan/minum dari SM: opsional (diatur per order oleh SO)
```

### 6. Tagihan Consumer — Invoice PDF + In-App

```
- Invoice PDF bisa di-download oleh consumer
- Invoice juga bisa dilihat langsung di app (in-app view)
- Tidak ada DP/uang muka — FULL bayar setelah prosesi selesai
- Deadline bayar: 3 hari (SOP keterlambatan belum ditentukan → ⏳ PENDING)
- Gaji karyawan: setiap tanggal 10 per bulan
```

### 7. Consumer Access — Gated by Payment

```
SEBELUM BAYAR:
  ✓ Track order real-time
  ✓ Lihat status prosesi
  ✓ Konfirmasi barang diterima
  ✓ Request amendment
  ✓ Lihat invoice / tagihan

SETELAH BAYAR (LUNAS):
  ✓ Semua di atas
  ✓ Download foto dokumentasi (link Google Drive)
  ✓ Download berkas akta kematian
  ✓ Akses semua dokumen terkait

BELUM LUNAS → TIDAK bisa akses foto & dokumen → motivasi bayar cepat
```

### 8. Rating — App Store + Google Maps

```
- Rating di dalam app SM: TIDAK ADA
- Consumer diarahkan ke:
  → Rating di Google Play Store / App Store
  → Rating di Google Maps (lokasi kantor SM)
- Bisa tampilkan prompt/link setelah order selesai + lunas
```

### 9. Order — Tidak Ada Pembatalan

```
- TIDAK ADA pembatalan order
- Sekali order dibuat dan dikonfirmasi → harus jalan sampai selesai
- Tidak perlu fitur cancel/refund
- Status 'cancelled' di ENUM bisa dihapus atau reserved untuk kasus luar biasa
```

### 10. Multi-Order — Dinamis, Fallback Kendaraan

```
- Banyak order bisa jalan bersamaan (rumah duka banyak)
- Resource dibagi dinamis: driver, kendaraan, tukang jaga, dekorasi
- Kendaraan: jika paket A habis → fallback ke paket B
- Sistem harus pintar alokasi resource tanpa manual intervention
```

### 11. Kremasi & Pemakaman — DI LUAR Tanggung Jawab SM

```
KOREKSI BESAR:
- Biaya kremasi / pemakaman BUKAN ditanggung SM
- Keluarga bayar LANGSUNG ke tempat kremasi / pemakaman
- SM hanya antar jenazah ke lokasi, SELESAI
- Tagihan SM TIDAK termasuk biaya kremasi/pemakaman
- Di app: info lokasi kremasi/pemakaman hanya sebagai referensi
```

### 12. Jenazah Luar Kota — Alur Berbeda (PENDING)

```
⏳ Alur jenazah dari luar kota belum didiskusikan
🔔 REMINDER: Tanyakan ke owner saat membahas fitur terkait transport jarak jauh
```

---

## ITEM PENDING KUMULATIF (BELUM DIKONFIRMASI OWNER)

```
⏳ Detail paket layanan (nama, harga, isi per lokasi)
⏳ Detail add-on yang tersedia
⏳ Barang apa saja di Kantor vs Gudang vs Lafiore
⏳ Detail mekanisme assign driver (sementara: auto setelah stok clear)
⏳ SOP keterlambatan bayar consumer (denda? eskalasi?)
⏳ Alur jenazah luar kota
⏳ Jadwal kegiatan per hari di rumah duka (misa, doa malam, dll)

🔔 REMINDER AKTIF:
  - Setiap bahas PAKET LAYANAN → tanyakan owner konfirmasi
  - Setiap bahas TRANSPORT LUAR KOTA → tanyakan owner diskusi
  - Setiap bahas JADWAL PROSESI → tanyakan owner apakah perlu di-track
```

---

# SANTA MARIA — PATCH v1.34
# Klarifikasi Operasional Lanjutan 3 — Skala, Alarm, Role Detail, Tukang Foto

---

## SKALA OPERASI — DIKONFIRMASI

```
╔═══════════════════════════════════════════════════════════════╗
║  SKALA SANTA MARIA                                            ║
╠═══════════════════════════════════════════════════════════════╣
║  Order per bulan     : 800+ (±27 order per hari)              ║
║  Total karyawan      : 40+                                    ║
║  Supplier tetap      : dinamis (diatur per role)              ║
║  Jam kerja kantor    : 08:00 - 17:00 WIB                     ║
║  Layanan             : 24 JAM (termasuk alarm)                ║
║  Device              : HP disediakan kantor (bukan pribadi)   ║
║  Internet            : flexible (perlu offline mode?)         ║
╚═══════════════════════════════════════════════════════════════╝

IMPLIKASI ARSITEKTUR:
  - 800 order/bulan = HIGH VOLUME → perlu optimasi query, caching, queue
  - 27 order/hari = kemungkinan besar 5-10 order BERSAMAAN
  - 40+ karyawan = semua pakai app setiap hari
  - HP kantor = bisa pre-install app, pre-configure
  - Perlu: pagination, lazy loading, efficient real-time updates
```

## FAKTA OPERASIONAL LANJUTAN 3

### 1. SO — Tugas Harian Lengkap

```
SO bukan hanya handle order. Tugas harian SO:
  ├── Handle order baru (input, konfirmasi, koordinasi)
  ├── Follow up consumer LAMA (post-order, relasi)
  ├── Prospek keluarga baru (sales/marketing)
  ├── Laporan harian ke owner/kantor
  ├── Input order (dari WA/telepon/walk-in)
  ├── Target visit (kunjungan ke rumah duka, RS, gereja)
  └── Komandan lapangan saat prosesi

Perlu fitur di app SO:
  - CRM sederhana: daftar prospek, follow-up reminder
  - Log visit: tanggal, lokasi, catatan
  - Laporan harian: auto-generate dari aktivitas hari itu
  - Target tracking: berapa visit/order per bulan vs target
```

### 2. Gudang — Tugas Harian

```
  ├── Siapkan barang per order (utama)
  ├── Bersih-bersih area gudang
  └── Cek stok barang (rutinitas)
```

### 3. Tukang Foto — Many-to-One, Google Drive Pribadi

```
- Bisa BANYAK tukang foto per 1 order (many to 1)
- Masing-masing upload ke Google Drive PRIBADI mereka
- Tautkan link di app per order
- Deadline upload: 3 JAM setelah prosesi selesai
- Setelah link ditautkan + waktu prosesi lewat → upah dihitung
- Jika lewat 3 jam belum upload → alarm HRD? (⏳ belum dikonfirmasi)

Perlu di app:
  - Input field: "Link Google Drive" per tukang foto per order
  - Validasi: link harus format Google Drive URL
  - Timer: countdown 3 jam setelah prosesi selesai
  - Status: belum_upload / sudah_upload / terlambat
```

### 4. Tukang Angkat Peti — Detail

```
- Pekerja lepas, ada di rumah duka (flexible kapan)
- Koordinator: bisa ikut angkat atau hanya koordinasi (flexible)
- Upah: Rp 75.000/hari/orang (LUMP SUM ke koordinator)
- Upah role lain: DINAMIS — bisa diatur di system config
- Koordinator yang tagih ke kantor (Purchasing bayar)

Tabel upah pekerja lepas harus DINAMIS:
  - Per role: tukang_angkat_peti, tukang_jaga, tukang_foto, musisi, dll
  - Per unit: per hari, per shift, per order, per jam
  - Bisa diubah Super Admin kapan saja
```

### 5. Alarm — SEMUA Keras, 24 Jam, Bypass Silent

```
KOREKSI BESAR:
- Spec lama: ada level ALARM / HIGH / NORMAL
- Kenyataan: SEMUA notifikasi harus ALARM KERAS
  → Bunyi benar-benar dari HP
  → Bypass silent mode / do not disturb
  → 24 jam (tidak ada jam tenang — layanan kematian 24/7)
  
IMPLIKASI:
  - flutter_local_notifications dengan full-screen intent
  - Android: IMPORTANCE_HIGH + sound + vibration + bypass DND
  - Semua push notification = alarm priority
  - Tidak perlu bedakan ALARM vs HIGH vs NORMAL di UX
    (di backend tetap bisa bedakan untuk logging/prioritas tampilan)
```

### 6. Device — HP Kantor (Bukan Pribadi)

```
- SM akan sediakan HP untuk setiap karyawan
- App bisa di-pre-install sebelum diserahkan
- Consent lokasi bisa di-setup saat provisioning HP
- MDM (Mobile Device Management) mungkin perlu ke depannya
```

---

## ITEM PENDING KUMULATIF

```
⏳ Detail paket layanan (nama, harga, isi per lokasi)
⏳ Detail add-on yang tersedia
⏳ Barang apa saja di Kantor vs Gudang vs Lafiore
⏳ Detail mekanisme assign driver
⏳ SOP keterlambatan bayar consumer
⏳ Alur jenazah luar kota
⏳ Jadwal kegiatan per hari di rumah duka
⏳ Jadwal stock opname
⏳ Prosedur barang rusak/hilang
⏳ Siapa yang tentukan minimum stok
⏳ Deadline tukang foto: alarm HRD jika terlambat?

🔔 REMINDER AKTIF:
  - PAKET LAYANAN → tanyakan owner
  - TRANSPORT LUAR KOTA → tanyakan owner
  - JADWAL PROSESI → tanyakan owner
  - STOCK OPNAME & BARANG RUSAK → tanyakan owner
```

---

# SANTA MARIA — PATCH v1.35
# Klarifikasi Operasional Lanjutan 4 — Flow Kritis, Foto Wajib, Order Mendadak

---

## FAKTA KRITIS — GAME CHANGERS

### 1. 100% ORDER = MENDADAK

```
╔═══════════════════════════════════════════════════════════════════╗
║  SEMUA ORDER ADALAH DARURAT                                       ║
║  Orang baru meninggal → keluarga langsung order → butuh HARI INI  ║
║  Tidak ada order yang "dijadwalkan minggu depan"                  ║
║  SLA: order harus diproses DIBAWAH 30 MENIT                      ║
╚═══════════════════════════════════════════════════════════════════╝

IMPLIKASI:
  - Tidak ada waktu untuk "review besok" — semua real-time
  - Stok harus SELALU siap (jangan sampai habis)
  - Driver harus SELALU standby
  - Alarm WAJIB segera direspons
  - Auto-assign > manual assign (lebih cepat)
  - 30 menit = dari order masuk → semua pihak konfirmasi stok → driver berangkat
```

### 2. SETIAP LANGKAH = BUKTI FOTO + GEOFENCING + TIMESTAMP

```
╔═══════════════════════════════════════════════════════════════════╗
║  SEMUA AKSI DI APP YANG MELIBATKAN FISIK → WAJIB FOTO + LOKASI   ║
╚═══════════════════════════════════════════════════════════════════╝

Setiap foto yang diambil via app WAJIB menyertakan:
  - File foto (dari kamera, BUKAN galeri)
  - Latitude + Longitude saat pengambilan (geofencing)
  - Timestamp saat pengambilan (dari server, bukan device)
  - Device ID (anti-manipulasi)

MOMEN YANG BUTUH FOTO:
  ├── Driver ambil barang di gudang/kantor/lafiore → foto barang di kendaraan
  ├── Driver tiba di rumah duka → foto barang diturunkan
  ├── Tukang jaga terima barang → foto barang diterima
  ├── Driver jemput jenazah → foto di RS/rumah
  ├── Driver tiba di rumah duka dengan jenazah → foto
  ├── Dekorasi selesai dipasang → foto hasil
  ├── Driver antar jenazah ke pemakaman → foto
  ├── Tukang jaga serah terima barang ke driver (kembali) → foto
  ├── Driver tiba di gudang/kantor/lafiore → foto barang dikembalikan
  ├── Penerima di gudang/kantor/lafiore → foto konfirmasi terima
  ├── Tukang jaga check-in shift → foto selfie + lokasi
  ├── Tukang jaga switch shift → foto berdua
  ├── Presensi harian (clock-in/out) → foto selfie + lokasi
  ├── Inspeksi kendaraan → foto per item bermasalah
  ├── Isi BBM → foto nota + speedometer
  └── Barang rusak/hilang → foto bukti

IMPLEMENTASI:
  Buat reusable service: GeoPhotoService
  - Buka kamera (BUKAN galeri)
  - Ambil foto
  - Auto-attach: lat, lng, accuracy, timestamp, device_id
  - Compress (max 2MB)
  - Return: { file, lat, lng, timestamp, device_id }
  - Semua endpoint yang butuh foto → pakai service ini
```

### 3. ORDER INPUT — Data Wajib dari Consumer

```
Data WAJIB saat buat order:
  ├── Foto KTP penanggung jawab (consumer)
  ├── Foto Kartu Keluarga
  ├── Nama almarhum
  ├── Tanggal meninggal
  ├── Pilih rumah duka (dari database funeral_homes)
  ├── Pilih paket layanan
  └── Data penanggung jawab (nama, alamat, telepon, hubungan)

Data OPSIONAL:
  ├── Add-on
  ├── Preferensi vendor (pemuka agama sendiri, dll)
  ├── Pilih pemakaman (dari database cemeteries)
  └── Catatan khusus
```

### 4. ORDER FLOW — SLA 30 Menit

```
TIMELINE KETAT:
  Menit 0    : Order masuk
  Menit 0-5  : SO terima alarm → review data → konfirmasi
  Menit 5-10 : Sistem auto-distribute ke gudang + kantor + lafiore
               Ketiga lokasi cek stok (sudah otomatis dari paket)
  Menit 10-20: Ketiga lokasi konfirmasi stok siap
  Menit 20-25: Sistem auto-assign driver(s)
  Menit 25-30: Driver berangkat

  PARALEL: Mobil jenazah assigned → jemput jenazah di RS/rumah

  Jika stok ada masalah → alert Purchasing → procurement darurat
  Jika driver tidak available → fallback ke kendaraan paket lain
```

### 5. BARANG ANTAR LOKASI — Fleksibel

```
KOREKSI:
- Tidak ada transfer stok antar lokasi (gudang↔kantor↔lafiore)
- TAPI: jika barang di lokasi asal habis dan di lokasi lain ada → BOLEH pakai
- Paket menentukan barang dari mana, TAPI jika habis → fallback ke lokasi lain
- Sistem harus: cek lokasi utama → jika habis → cek lokasi lain → auto-switch
```

### 6. SAL (Surat Penerimaan Layanan)

```
Dua skenario:
  A. SO ketemu fisik consumer → SO bantu isi → consumer tanda tangan di tablet
  B. Consumer isi sendiri di app → consumer tanda tangan sendiri

Tanda tangan:
  - Dari SO (atas nama SM) → valid
  - Dari consumer sendiri → valid
  - Salah satu cukup (tidak harus dua-duanya)
```

### 7. TUKANG JAGA — Database Langganan, Auto-Assign

```
- Ada DATABASE tukang jaga (langganan, bukan cari baru setiap order)
- Tukang jaga PUNYA APP SM (wajib untuk konfirmasi shift)
- Assign ke order: OTOMATIS oleh sistem (bukan manual SO)
- Sistem pilih berdasarkan: availability, jarak, riwayat kerja
```

### 8. SUPPLIER — Tagih Fisik ke Kantor

```
- Supplier datang FISIK ke kantor untuk tagih uang
- Bukan via app atau invoice digital
- Purchasing yang handle pembayaran di kantor
- Tetap dicatat di sistem oleh Purchasing (input manual)
```

### 9. PURCHASING — Bisa Approve Sendiri

```
- Purchasing BISA langsung bayar tanpa approval owner
- Tidak ada batas nominal yang butuh approval owner
- Owner hanya MONITOR (sesuai v1.27)
- Semua pengeluaran ter-log otomatis untuk audit
```

### 10. PROSESI MULTI RUMAH DUKA — Pernah Terjadi

```
- Pernah: hari 1-2 di rumah duka A, hari 3 pindah ke rumah duka B
- Perlu support di order: multiple funeral_home_id per order
- Atau: order bisa punya "phase" dengan lokasi berbeda per phase
  ⏳ Detail implementasi perlu didiskusikan lebih lanjut
```

### 11. AMENDMENT (Barang Tambahan Tengah Prosesi)

```
Alur dikonfirmasi:
  1. Consumer request via app ATAU WA ke SO
  2. SO input di app (jika dari WA)
  3. Barang dikirim ke rumah duka
  4. Tukang jaga WAJIB konfirmasi terima di app
  5. Tukang jaga minta consumer APPROVAL di app
  6. Consumer approve di app → barang resmi diterima → masuk tagihan
```

### 12. OWNER DASHBOARD — 3 Angka Utama

```
Yang owner mau lihat SETIAP HARI:
  1. ANOMALI — apa yang salah/terlambat/bermasalah hari ini
  2. PENDAPATAN — uang masuk hari ini / bulan ini
  3. JUMLAH ORDER — berapa order aktif hari ini

PLUS: log aktivitas SEMUA karyawan di app (siapa buka apa, kapan)
```

### 13. EXPORT & DATA RETENTION

```
- SEMUA laporan bisa di-export PDF dan Excel
- Untuk SEMUA role (bukan hanya owner/purchasing)
- Data disimpan SELAMANYA (tidak ada auto-purge/arsip)
- Implikasi: perlu strategi partitioning untuk tabel besar
  (800 order/bulan × 12 bulan × N tahun = jutaan records)
```

---

## DATABASE BARU v1.35

### Tabel `photo_evidences` (Bukti Foto Universal + Geofencing)

Tabel tunggal untuk SEMUA bukti foto di semua konteks.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
context VARCHAR(100) NOT NULL
  -- 'driver_pickup_goods', 'driver_arrive_rumah_duka', 'driver_pickup_body',
  -- 'driver_arrive_cemetery', 'driver_return_goods', 'tukang_jaga_receive',
  -- 'tukang_jaga_shift_checkin', 'tukang_jaga_shift_switch', 'dekor_complete',
  -- 'attendance_clock_in', 'attendance_clock_out', 'vehicle_inspection',
  -- 'fuel_receipt', 'item_damaged', 'goods_return_confirmed', dll

-- Relasi (salah satu terisi sesuai context)
order_id UUID NULLABLE REFERENCES orders(id)
user_id UUID REFERENCES users(id)              -- siapa yang ambil foto
reference_type VARCHAR(50) NULLABLE            -- 'order_driver_assignment', 'daily_attendance', dll
reference_id UUID NULLABLE                     -- FK ke tabel terkait

-- File
file_path TEXT NOT NULL                        -- R2 path
file_size_bytes BIGINT NULLABLE
thumbnail_path TEXT NULLABLE                   -- thumbnail untuk list view

-- Geofencing (WAJIB)
latitude DECIMAL(10,7) NOT NULL
longitude DECIMAL(10,7) NOT NULL
accuracy_meters DECIMAL(8,2) NULLABLE
altitude DECIMAL(10,2) NULLABLE

-- Timestamp (WAJIB, dari server)
taken_at TIMESTAMP NOT NULL                    -- waktu foto diambil
server_received_at TIMESTAMP DEFAULT now()     -- waktu diterima server

-- Device info
device_id VARCHAR(255) NOT NULL
device_model VARCHAR(255) NULLABLE

-- Validasi
is_validated BOOLEAN DEFAULT FALSE
validated_by UUID NULLABLE REFERENCES users(id)
validation_notes TEXT NULLABLE

notes TEXT NULLABLE
created_at TIMESTAMP

INDEX: (context), (order_id), (user_id), (taken_at), (reference_type, reference_id)
```

### Tabel `activity_logs` (Log Aktivitas Semua Karyawan)

Owner mau lihat SEMUA aktivitas karyawan di app.

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id UUID REFERENCES users(id)
action VARCHAR(255) NOT NULL                   -- 'open_screen', 'confirm_order', 'upload_photo', dll
screen VARCHAR(255) NULLABLE                   -- 'so_dashboard', 'order_detail', dll
metadata JSONB DEFAULT '{}'                    -- detail tambahan
ip_address VARCHAR(50) NULLABLE
device_id VARCHAR(255) NULLABLE
created_at TIMESTAMP DEFAULT now()

INDEX: (user_id, created_at), (action), (created_at)
-- Partitioning by month recommended untuk volume tinggi
```

---

## ITEM PENDING KUMULATIF

```
⏳ Detail paket layanan (nama, harga, isi per lokasi)
⏳ Detail add-on yang tersedia
⏳ Barang apa saja di Kantor vs Gudang vs Lafiore
⏳ SOP keterlambatan bayar consumer
⏳ Alur jenazah luar kota
⏳ Jadwal kegiatan per hari di rumah duka
⏳ Stock opname, barang rusak, minimum stok
⏳ Detail prosesi multi rumah duka

🔔 REMINDER AKTIF:
  - PAKET LAYANAN → tanyakan owner
  - TRANSPORT LUAR KOTA → tanyakan owner
  - JADWAL PROSESI → tanyakan owner
  - MULTI RUMAH DUKA → tanyakan owner detail
```

---

# SANTA MARIA — PATCH v1.36
# Klarifikasi Final — Role Baru, Consumer Journey, Target Go-Live

---

## TARGET GO-LIVE: MINGGU INI (April 2026)

```
PRIORITAS ABSOLUT — fitur yang HARUS jalan minggu ini:
  1. Order masuk (consumer app + SO app) → confirmed → proses
  2. Stok checklist per lokasi (gudang/kantor/lafiore) → konfirmasi
  3. Driver auto-assign → antar barang + jemput jenazah
  4. Tukang jaga shift + serah terima barang + consumer confirm
  5. Tagihan → consumer bayar → Purchasing verifikasi
  6. Foto + geofencing setiap langkah
  7. Alarm keras semua notifikasi
  8. Owner dashboard (anomali, pendapatan, jumlah order)

BISA DITUNDA (post go-live):
  - e-Katalog bidding supplier
  - KPI & payroll otomatis
  - AI features (demand prediction, price check, dll)
  - CRM SO (prospek, visit log, target)
  - Workshop peti
  - Laporan keuangan detail (export PDF/Excel)
  - Vehicle inspection & maintenance
```

## FAKTA OPERASIONAL FINAL

### 1. ROLE BARU: Petugas Akta Kematian

```
Belum ada di spec sebelumnya.

Role: petugas_akta
Fungsi: Mengurus akta kematian untuk consumer
  - Kumpulkan dokumen dari keluarga (KTP, KK, surat kematian RS, dll)
  - Urus ke catatan sipil / kelurahan / kecamatan
  - Track progress: tahap mana, sudah sampai di instansi mana
  - Upload bukti progress (foto dokumen + geofencing)
  - Serahkan akta kematian jadi ke keluarga (setelah consumer lunas)

Status tracking akta:
  draft → collecting_docs → submitted_to_civil → processing → completed → handed_to_family

Perlu fitur:
  - Checklist dokumen yang dibutuhkan (dari master, sudah ada death_cert_doc_master)
  - Progress per instansi yang dikunjungi
  - Foto bukti setiap kunjungan (geofencing)
  - Timeline: kapan submit, kapan selesai, kapan serahkan
  - Alert jika proses > threshold hari → alarm ke petugas + owner
```

### 2. KOORDINATOR TUKANG ANGKAT PETI — Punya App

```
- Koordinator PUNYA APP SM
- Fungsi di app:
  → Lihat order yang perlu tukang angkat peti
  → Input jumlah orang yang bekerja per order
  → Submit tagihan ke Purchasing via app
  → Track status pembayaran
- Purchasing lihat tagihan dari app → approve → bayar
```

### 3. MUSISI — Many-to-Many, Auto-Notify, Include MC

```
- Musisi sering dipakai (include MC/pembawa acara)
- Many-to-many: 1 order bisa banyak musisi, 1 musisi bisa banyak order
- PUNYA APP SM
- Saat order confirmed → OTOMATIS semua musisi available dapat notifikasi
- Musisi pilih "Saya ambil order ini" → assigned
- Sistem upah per order (dinamis, bisa diatur)
```

### 4. CONSUMER JOURNEY — Lengkap

```
CHANNEL AWAL:
  - Mulut ke mulut → keluarga hubungi SM
  - Sales SO lapangan → visit RS/rumah
  - Digital marketing → landing page → install app

SETELAH ORDER:
  - Jika order via app sendiri → dapat kontak WA Customer Service SM
    (CS bukan role di app — hanya nomor WA kantor)
  - Jika order via SO → komunikasi dengan SO tersebut
  - Consumer TIDAK chat di dalam app — via WA saja

TRACKING DI APP CONSUMER:
  - Status text + progress bar (BUKAN peta real-time driver)
  - Konfirmasi barang diterima (checklist)
  - Approval amendment
  - Lihat invoice / tagihan
  - Upload bukti bayar

SETELAH LUNAS:
  - Akses foto dokumentasi (link Google Drive)
  - Akses dokumen akta kematian
  - Prompt: "Rate kami di Google Play" + "Rate di Google Maps"

KOMPLAIN:
  - Via SO (jika order melalui SO)
  - Via WA Customer Service
  - TIDAK ada fitur komplain di app
```

### 5. AGAMA — Semua Agama, Alur Sama

```
- SM melayani SEMUA agama
- Prosesi beda agama: ALUR SAMA (tidak ada branching di sistem)
- Perbedaan hanya di: pemuka agama yang di-assign (sesuai agama)
- Paket TIDAK dibedakan per agama (akan dikonfirmasi saat detail paket)
```

### 6. AKTA KEMATIAN — SM Yang Urus, Perlu Progress Tracking

```
- SM yang urus akta kematian (bukan keluarga sendiri)
- Dikerjakan oleh role baru: petugas_akta
- Harus DETAIL progress sampai di mana
- Consumer bisa lihat progress di app (setelah lunas)
- Dokumen akta diserahkan ke keluarga setelah selesai
```

### 7. PENGGALI MAKAM — Di Luar SM

```
- Penggali makam BUKAN urusan SM
- Pihak pemakaman yang urus
- Tidak perlu di-track di app SM
```

### 8. KOMPETITOR & MARKET

```
- Kompetitor: Budi Cipto dll — belum digitalisasi
- SM keunggulan: Cepat, Mudah, Hemat, Sejak 2004
- Target: Semarang dan sekitarnya (belum ekspansi jauh)
- Diferensiasi utama = APP INI (digitalisasi pertama di industri)
```

---

## ROLE TABLE FINAL v1.36

| # | Role | Tipe | Punya App | Fungsi |
|---|------|------|-----------|--------|
| 1 | super_admin | Sistem | Ya | God mode |
| 2 | owner | Eksekutif | Ya | Monitor only, command |
| 3 | service_officer | Internal | Ya | Komandan lapangan, input order, CRM |
| 4 | gudang | Internal | Ya | Stok gudang, checklist, serah terima |
| 5 | purchasing | Internal | Ya | Keuangan, bayar supplier/pekerja, verifikasi |
| 6 | driver | Internal | Ya | Antar barang/jenazah, GPS, foto bukti |
| 7 | dekor (Lafiore) | Internal | Ya | Stok dekorasi, pasang, foto bukti |
| 8 | konsumsi | - | Tidak | Dari supplier, bukan role app |
| 9 | pemuka_agama | Vendor | Opsional | Assignment per order, presensi |
| 10 | tukang_foto | Freelance | Ya | Dokumentasi, upload GDrive link, upah |
| 11 | tukang_jaga | Freelance | Ya | Jaga rumah duka, serah terima, shift |
| 12 | tukang_angkat_peti | Freelance | Ya | Koordinator punya app, tagih via app |
| 13 | musisi | Freelance | Ya | Include MC, many-to-many, auto-notify |
| 14 | petugas_akta | Internal | Ya | Urus akta kematian, progress tracking |
| 15 | hrd | Internal | Ya | KPI, gaji, pelanggaran |
| 16 | security | Internal | Ya | Jaga kantor, lapor tamu |
| 17 | supplier | Eksternal | Ya (tetap) | e-Katalog bidding |
| 18 | consumer | Eksternal | Ya | Order, track, bayar |
| 19 | viewer | Eksternal | Ya | Read-only dashboard |

KOREKSI: konsumsi BUKAN role app — konsumsi = supplier luar yang kirim langsung.
```

---

## ITEM PENDING KUMULATIF FINAL

```
⏳ Detail paket layanan (nama, harga, isi per lokasi)
⏳ Detail add-on yang tersedia
⏳ Barang apa saja di Kantor vs Gudang vs Lafiore
⏳ SOP keterlambatan bayar consumer
⏳ Alur jenazah luar kota
⏳ Jadwal kegiatan per hari di rumah duka
⏳ Stock opname, barang rusak, minimum stok
⏳ Detail prosesi multi rumah duka
⏳ Workflow petugas akta kematian detail

🔔 REMINDER AKTIF:
  - PAKET LAYANAN → tanyakan owner
  - TRANSPORT LUAR KOTA → tanyakan owner
  - JADWAL PROSESI → tanyakan owner
  - MULTI RUMAH DUKA → tanyakan owner
```

---

# SANTA MARIA — PATCH v1.37
# Nomor WA CS, Form Design Micro-Interactions, UX Error Handling

---

## INFORMASI KONTAK RESMI

```
WhatsApp Customer Service Santa Maria: 08112714440
Format internasional: 6281127144440

Digunakan untuk:
  - Consumer yang order via app → dapat kontak CS ini
  - Landing page → tombol WA floating
  - Template WA → footer kontak
```

### System Thresholds Update
```
cs_whatsapp_number = '08112714440'
cs_whatsapp_international = '6281127144440'
```

---

## FORM DESIGN & MICRO-INTERACTIONS — WAJIB DIIKUTI

### Prinsip UX Error Handling

```
SETIAP form di SELURUH app WAJIB memiliki:

1. VALIDASI REAL-TIME (per field)
   - Saat user ketik → validasi langsung (debounce 300ms)
   - Border merah + pesan error di bawah field jika invalid
   - Border hijau + centang jika valid
   - Contoh: email format salah → "Format email tidak valid"

2. ERROR STATE YANG JELAS
   - Password salah → SnackBar merah: "Email atau password salah"
   - Network error → SnackBar merah: "Tidak ada koneksi internet"
   - Server error (500) → SnackBar merah: "Terjadi kesalahan server. Coba lagi."
   - Timeout → SnackBar merah: "Koneksi timeout. Periksa jaringan Anda."
   - 422 Validation → tampilkan error per field dari response
   - 401 Unauthorized → redirect ke login
   - 403 Forbidden → SnackBar: "Anda tidak memiliki akses"
   - 404 Not Found → SnackBar: "Data tidak ditemukan"
   - 429 Rate Limited → SnackBar: "Terlalu banyak percobaan. Coba lagi nanti."

3. LOADING STATE
   - Tombol submit → loading spinner di dalam tombol + disable
   - JANGAN: spinner di tengah layar tanpa konteks
   - Teks tombol berubah: "Simpan" → "Menyimpan..." → kembali "Simpan"

4. SUCCESS STATE
   - SnackBar hijau: "Data berhasil disimpan"
   - Atau dialog sukses dengan ikon centang + auto-dismiss 2 detik
   - Navigate back atau refresh data setelah sukses

5. EMPTY STATE
   - List kosong → tampilkan ilustrasi + teks: "Belum ada data"
   - JANGAN: layar putih kosong tanpa penjelasan

6. PULL TO REFRESH
   - Semua list screen WAJIB support pull-to-refresh

7. CONFIRMATION DIALOG
   - Aksi destruktif (hapus, batalkan, tolak) → dialog konfirmasi dulu
   - "Apakah Anda yakin?" + tombol "Ya" (merah) dan "Batal" (abu)

8. FORM FIELD DESIGN
   - Label di atas field (bukan floating label)
   - Hint text di dalam field (abu-abu)
   - Required field: label + tanda * merah
   - Disabled field: background abu-abu muda
   - Error: border merah + teks error merah di bawah
   - Focus: border warna aksen role
```

### Implementasi Flutter — Error Handler Global

```dart
// Di ApiClient interceptor, handle semua HTTP errors secara konsisten:

// 401 → redirect ke login
// 403 → show "Tidak memiliki akses"
// 404 → show "Data tidak ditemukan"
// 422 → return errors per field ke form
// 429 → show "Terlalu banyak percobaan" + retry-after
// 500 → show "Kesalahan server"
// Network error → show "Tidak ada koneksi internet"
// Timeout → show "Koneksi timeout"
```

### Login Screen — Specific Error Messages

```
Email tidak terdaftar     → "Akun tidak ditemukan"
Password salah            → "Password salah. Coba lagi."
Akun nonaktif             → "Akun Anda dinonaktifkan. Hubungi admin."
Terlalu banyak percobaan  → "Terlalu banyak percobaan. Coba lagi dalam X detik."
Belum verifikasi          → "Akun belum diverifikasi."
```

---

# SANTA MARIA — PATCH v1.38
# SO-Mandatory Order Input, Visit Deadline 30+30 min, Service Type Anggota/Non-Anggota, SO Rotation, Critical Bug Consolidation

---

## PERUBAHAN FUNDAMENTAL v1.38

### A. INPUT ORDER — WAJIB MELALUI SO (DEPRECATE CONSUMER SELF-ORDER)

```
╔═══════════════════════════════════════════════════════════════════════╗
║  SEMUA ORDER WAJIB DIINPUT OLEH SO                                    ║
║                                                                       ║
║  Consumer TIDAK bisa lagi input order sendiri via app.                ║
║  Channel order hanya 3:                                               ║
║    - SO Lapangan (field)                                              ║
║    - SO Kantor (office)                                               ║
║    - SO via telepon/WA (masih diinput SO ke app)                      ║
║                                                                       ║
║  Consumer app tetap ada untuk:                                        ║
║    ✓ Terima link tracking order                                       ║
║    ✓ Tanda tangan Surat Penerimaan Layanan (SAL)                      ║
║    ✓ Approve amendment                                                ║
║    ✓ Konfirmasi barang diterima                                       ║
║    ✓ Lihat & bayar invoice                                            ║
║    ✓ Akses dokumen setelah lunas                                      ║
║    ✗ TIDAK bisa buat order baru                                       ║
╚═══════════════════════════════════════════════════════════════════════╝
```

**Perubahan schema:**
```sql
-- orders.created_by_so_channel: HAPUS nilai 'consumer_self'
ALTER TABLE orders
  ALTER COLUMN created_by_so_channel TYPE VARCHAR(20),
  ALTER COLUMN created_by_so_channel SET DEFAULT 'field';
-- Nilai valid sekarang: 'field', 'office', 'phone_wa'
-- Data lama dengan 'consumer_self' → migrate ke 'phone_wa' atau SO terkait

-- Tambah kolom:
ALTER TABLE orders ADD COLUMN input_source ENUM(
  'so_field_visit',      -- SO datang langsung ke keluarga
  'so_office_walkin',    -- keluarga datang ke kantor
  'so_phone',            -- keluarga telepon → SO input
  'so_whatsapp'          -- keluarga via WA → SO input
) NOT NULL DEFAULT 'so_phone';
```

**Endpoint deprecated:**
```
❌ DEPRECATED (v1.38):
POST /consumer/orders                              -- hapus/disable
POST /consumer/orders/walkin                       -- tidak pernah ada
POST /consumer/orders/{id}/acceptance-letter       -- KEEP (consumer masih isi SAL)

✅ TETAP DIPAKAI:
POST /so/orders                                    -- SO buat order
POST /so/orders/walkin                             -- SO kantor walk-in
```

**Consumer app adjustment:**
```dart
// lib/features/consumer/screens/consumer_home.dart — PERKAYA
// Hapus tombol "Pesan Layanan Baru"
// Ganti dengan tombol "Hubungi Customer Service"
//   → wa.me/628112714440 dengan template:
//     "Halo Santa Maria, saya ingin memesan layanan pemakaman.
//      Nama almarhum: [___]
//      Lokasi: [___]
//      Saya bisa dihubungi di nomor ini."
// Consumer yang sudah punya order aktif tetap lihat tracking + bayar seperti biasa
```

---

### B. SO WAJIB HADIR FISIK KE KELUARGA — DEADLINE 30 + 30 MENIT

```
╔═══════════════════════════════════════════════════════════════════════╗
║  SLA VISIT SO                                                         ║
║                                                                       ║
║  Order masuk (di-input SO) → SO WAJIB sampai di lokasi keluarga      ║
║  dalam 30 MENIT.                                                      ║
║                                                                       ║
║  Jika tidak bisa:                                                     ║
║    → Request PERPANJANGAN 30 menit lagi (maksimal 1 kali)             ║
║    → Total deadline: 60 menit                                         ║
║                                                                       ║
║  Lewat 60 menit tanpa arrive:                                         ║
║    → Alarm HRD + Owner                                                ║
║    → Sistem reassign ke SO lain (rotasi)                              ║
║    → Catat hrd_violations (so_visit_timeout)                          ║
╚═══════════════════════════════════════════════════════════════════════╝
```

**Tabel baru `order_so_visits`:**
```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
order_id UUID REFERENCES orders(id) ON DELETE CASCADE
so_id UUID REFERENCES users(id)
sequence SMALLINT NOT NULL DEFAULT 1          -- 1 = SO awal, 2+ = reassignment

-- Lokasi target (rumah keluarga / RS / lokasi yang disepakati)
target_address TEXT NOT NULL
target_lat DECIMAL(10,7) NULLABLE
target_lng DECIMAL(10,7) NULLABLE

-- Deadline tracking
assigned_at TIMESTAMP NOT NULL DEFAULT NOW()
initial_deadline TIMESTAMP NOT NULL            -- assigned_at + 30 menit
extended_deadline TIMESTAMP NULLABLE           -- assigned_at + 60 menit (jika extend)
extension_requested_at TIMESTAMP NULLABLE
extension_reason TEXT NULLABLE

-- Arrival (foto selfie + geofence wajib, pakai photo_evidences v1.35)
arrived_at TIMESTAMP NULLABLE
arrival_photo_evidence_id UUID NULLABLE REFERENCES photo_evidences(id)
arrival_distance_meters DECIMAL(10,2) NULLABLE

-- Status
status ENUM(
  'assigned',           -- SO ditugaskan, belum berangkat
  'en_route',           -- SO sudah tekan "berangkat"
  'extended',           -- minta perpanjangan 30 menit
  'arrived',            -- SO tiba (dalam deadline)
  'arrived_late',       -- SO tiba setelah extended_deadline (tetap rekam)
  'timeout',            -- tidak arrive sampai deadline → reassign
  'reassigned'          -- SO ini di-skip, task pindah ke SO lain
) DEFAULT 'assigned'

timeout_at TIMESTAMP NULLABLE
notes TEXT NULLABLE
created_at TIMESTAMP
updated_at TIMESTAMP

INDEX: (order_id, sequence), (so_id, status), (initial_deadline)
```

**System thresholds baru:**
```
so_visit_initial_deadline_minutes = 30     -- deadline awal SO tiba
so_visit_extension_minutes = 30            -- tambahan perpanjangan
so_visit_max_extensions = 1                -- hanya boleh 1x extend
```

**API endpoints:**
```
POST   /so/orders/{id}/visit/depart            -- SO tekan "berangkat" → en_route
POST   /so/orders/{id}/visit/request-extension -- minta perpanjangan 30 menit
  Body: { reason: "macet di [lokasi]" }
POST   /so/orders/{id}/visit/arrive            -- tiba (foto selfie + geofence wajib)
  Body: { photo: file, latitude, longitude, device_id }
GET    /so/orders/{id}/visit                   -- status visit saat ini + countdown
```

**Scheduler:**
```php
// Setiap menit — cek SO visit yang lewat deadline
$schedule->command('so:check-visit-timeout')->everyMinute();

// Logic:
// 1. Cari order_so_visits.status IN ('assigned','en_route','extended')
//    AND COALESCE(extended_deadline, initial_deadline) < NOW()
// 2. Set status = 'timeout', timeout_at = now()
// 3. Alarm HRD + Owner
// 4. Auto-reassign: pilih SO lain (yang berbeda tipe layanan dari so_id sebelumnya
//    tidak berlaku di sini — rotation hanya untuk assignment awal, bukan failover)
// 5. Buat record order_so_visits baru dengan sequence++
// 6. Insert hrd_violations (so_visit_timeout)
```

**Flutter screens:**
```
lib/features/service_officer/screens/
  ├── so_home.dart                         -- PERKAYA:
  │     -- Section "Visit Aktif" di atas:
  │     -- Card merah kalau ada visit aktif:
  │     │   "Order SM-XXX — Tiba di lokasi sebelum 08:45 (12 menit lagi)"
  │     │   [📍 Berangkat] [🏠 Tiba] [⏱️ Minta Perpanjangan]
  │
  ├── so_visit_screen.dart                 -- BARU:
  │     -- Map: lokasi SO saat ini vs lokasi keluarga
  │     -- Timer countdown besar (warna: hijau > 15 menit, kuning < 15, merah overdue)
  │     -- Tombol aksi sesuai status:
  │     │   assigned → [Berangkat Sekarang]
  │     │   en_route → [Saya Tiba] / [Minta Perpanjangan 30 menit]
  │     │   extended → [Saya Tiba] (tidak bisa extend lagi)
  │     -- Saat tekan "Saya Tiba":
  │     │   - Buka kamera selfie (WAJIB, bukan galeri)
  │     │   - Geofencing validation: dalam radius target
  │     │   - Upload via photo_evidences
  │     │   - Status → 'arrived'
```

---

### C. SERVICE TYPE — ANGGOTA vs NON-ANGGOTA (REPLACE PAKET SEBAGAI CATEGORIZATION UTAMA)

```
╔═══════════════════════════════════════════════════════════════════════╗
║  2 TIPE LAYANAN (TIDAK ADA "PAKET" LAGI SEBAGAI LABEL UTAMA)          ║
║                                                                       ║
║  1. ANGGOTA                                                           ║
║     - Profit MARGIN LEBIH KECIL (loyalty/membership benefit)          ║
║     - Harga lebih murah dari Non-Anggota                              ║
║     - Syarat: consumer terdaftar sebagai Anggota Santa Maria          ║
║                                                                       ║
║  2. NON-ANGGOTA                                                       ║
║     - Profit margin normal                                            ║
║     - Harga standard                                                  ║
║     - Consumer walk-in / baru / tidak jadi anggota                    ║
╚═══════════════════════════════════════════════════════════════════════╝

CATATAN:
- "Paket" sebagai label konsumen DIHAPUS
- Tabel `packages` TETAP dipakai sebagai CONTENT TEMPLATE internal
  (untuk generate stok, peralatan, billing items) — tapi BUKAN label publik
- Orderan dikategorisasi pertama oleh service_type,
  content-nya tetap bisa variatif via package_id (internal only)
```

**Tabel baru `service_offerings` (menggantikan konsep "paket" konsumen):**
```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
service_type ENUM('anggota','non_anggota') UNIQUE NOT NULL
display_name VARCHAR(255) NOT NULL             -- "Layanan Anggota Santa Maria"
description TEXT NULLABLE

-- Harga
base_price DECIMAL(15,2) NOT NULL              -- harga dasar layanan
profit_margin_percent DECIMAL(5,2) NOT NULL   -- margin (anggota lebih kecil)

-- Content template (opsional — link ke packages untuk items default)
default_package_id UUID NULLABLE REFERENCES packages(id)

is_active BOOLEAN DEFAULT TRUE
sort_order INTEGER DEFAULT 0
created_at TIMESTAMP
updated_at TIMESTAMP
```

**Seed awal:**
```
anggota      | "Layanan Anggota Santa Maria"      | base: [konsultasi harga owner] | margin: [kecil]
non_anggota  | "Layanan Non-Anggota Santa Maria"  | base: [konsultasi harga owner] | margin: [normal]
```

> ⏳ **PENDING OWNER:** Harga dasar dan margin persis untuk kedua tipe layanan.

**Perubahan `orders` table:**
```sql
ALTER TABLE orders ADD COLUMN service_type ENUM('anggota','non_anggota') NOT NULL DEFAULT 'non_anggota';
ALTER TABLE orders ADD COLUMN service_offering_id UUID REFERENCES service_offerings(id);
-- package_id TETAP ADA untuk internal content template, tidak dihapus
```

**Perubahan `users` (consumer) — membership:**
```sql
-- Tabel baru membership consumer:
CREATE TABLE consumer_memberships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  membership_number VARCHAR(50) UNIQUE NOT NULL,   -- contoh: AGG-2026-0001
  joined_at DATE NOT NULL,
  expires_at DATE NULLABLE,                        -- NULL = seumur hidup
  status ENUM('active','expired','suspended','cancelled') DEFAULT 'active',
  notes TEXT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- Saat SO input order:
-- 1. Cari apakah consumer sudah punya consumer_memberships.status='active'
-- 2. Jika ya → service_type = 'anggota'
-- 3. Jika tidak → service_type = 'non_anggota'
-- 4. SO bisa override manual (misal: keluarga anggota meninggal tapi order atas nama non-anggota)
```

**API endpoints:**
```
GET    /admin/master/service-offerings           -- list offerings (anggota, non_anggota)
PUT    /admin/master/service-offerings/{id}      -- Super Admin update harga/margin

GET    /admin/consumer-memberships               -- list anggota
POST   /admin/consumer-memberships               -- daftarkan consumer sebagai anggota
PUT    /admin/consumer-memberships/{id}          -- update status membership
GET    /so/check-membership?phone=XXX             -- cek apakah consumer anggota (by HP)

GET    /so/service-types                         -- list service_type + harga dasar
```

**Billing implication:**
- `order_billings.grand_total` dihitung berdasarkan `service_type` + items
- Discount/margin ditangani di service_offerings level
- Item-level pricing tetap dari billing_item_master

---

### D. SO ROTATION — FAIR DISTRIBUTION PER SERVICE TYPE

```
╔═══════════════════════════════════════════════════════════════════════╗
║  ROTASI ASSIGNMENT SO PER TIPE LAYANAN                                ║
║                                                                       ║
║  Prinsip:                                                             ║
║  - Jika SO A baru saja handle order ANGGOTA,                         ║
║    order ANGGOTA BERIKUTNYA → diserahkan ke SO lain (bukan SO A)     ║
║  - Logika sama untuk NON-ANGGOTA                                      ║
║  - Rotation track per (user_id, service_type)                         ║
║                                                                       ║
║  Tujuan:                                                              ║
║  - Distribusi rata antar SO                                           ║
║  - Cegah SO monopoli tipe layanan tertentu                           ║
║  - Fair commission/performance opportunity                            ║
╚═══════════════════════════════════════════════════════════════════════╝
```

**Tabel baru `so_assignment_history`:**
```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
so_id UUID REFERENCES users(id)
order_id UUID REFERENCES orders(id)
service_type ENUM('anggota','non_anggota') NOT NULL
assigned_at TIMESTAMP NOT NULL DEFAULT NOW()
created_at TIMESTAMP

INDEX: (so_id, service_type, assigned_at DESC)
```

**Algoritma auto-rotation (pseudocode):**
```
function assignSoForOrder(Order order, service_type):
    // 1. Cari SO eligible:
    //    - role = 'service_officer'
    //    - is_active = true
    //    - currently clock-in (daily_attendances.status IN ('present','late'))
    //    - tidak sedang ada visit yang belum arrive (order_so_visits.status IN ('assigned','en_route','extended'))
    eligibleSos = Users.where(role='service_officer', is_active=true)
                       .whereClockedIn()
                       .whereNotOnActiveVisit()

    if eligibleSos.isEmpty:
        // Fallback: assign ke SO yang clock-in (abaikan active visit)
        eligibleSos = Users.where(role='service_officer', is_active=true)
                           .whereClockedIn()

    // 2. Untuk setiap SO, ambil last assignment timestamp untuk service_type ini
    //    dari so_assignment_history
    eligibleSos.map(so =>
        lastAssigned = SoAssignmentHistory
                          .where(so_id=so.id, service_type=service_type)
                          .orderBy('assigned_at', 'desc')
                          .first()
        so.last_assigned_at_for_type = lastAssigned?.assigned_at ?? '1970-01-01'
    )

    // 3. Sort ASC — yang paling lama TIDAK dapat jenis ini → prioritas
    eligibleSos.sortBy(so => so.last_assigned_at_for_type)

    // 4. Pilih SO pertama
    selectedSo = eligibleSos.first

    // 5. Catat di so_assignment_history
    SoAssignmentHistory.create({
        so_id: selectedSo.id,
        order_id: order.id,
        service_type: service_type,
        assigned_at: now()
    })

    // 6. Buat order_so_visits awal
    OrderSoVisit.create({
        order_id: order.id,
        so_id: selectedSo.id,
        sequence: 1,
        target_address: order.address,
        initial_deadline: now() + 30 minutes,
        status: 'assigned'
    })

    return selectedSo
```

**Aturan bisnis:**
```
1. Rotation hanya untuk SO yang sedang CLOCK-IN. SO yang tidak bekerja hari itu tidak ikut rotasi.
2. Rotation tidak memperhatikan SO channel (field vs office) — semua SO masuk rotation.
3. Owner/Super Admin bisa OVERRIDE rotation dan assign manual ke SO tertentu.
4. Jika SO pertama timeout (tidak arrive dalam 60 menit) → reassignment TIDAK masuk rotation
   (failover berbeda dari fresh assignment; pakai SO next-available tanpa pengaruh history).
5. SO history disimpan selamanya untuk audit.
```

**API endpoints:**
```
POST   /so/orders                            -- DIPERKAYA: saat create order, sistem otomatis rotate
  // Logic internal: assignSoForOrder() dipanggil otomatis berdasarkan service_type

GET    /admin/so-rotation-status             -- Super Admin: lihat last_assigned per SO per service_type
POST   /admin/so-orders/{id}/manual-assign   -- Super Admin override: force assign ke SO tertentu
  Body: { so_id: X, reason: "..." }
```

---

## PART 2 — CONSOLIDATED CRITICAL BUG FIXES v1.38

Patch ini juga menegaskan keputusan atas bug kritis hasil audit v1.37:

### BUG-FIX 1: Version header (fixed di commit ini)
- Header `Version 1.27` → `Version 1.38` (sudah di-update).

### BUG-FIX 2: Role seed — hapus `admin` dan `finance`
```
KEPUTUSAN:
- Role `admin` dihapus (sesuai v1.8 "admin diotomasi").
- Role `finance` dihapus (sesuai v1.15 "finance → purchasing").
- Seed role v1.29 dikoreksi:

SEBELUM (v1.29):
super_admin, consumer, service_officer, admin, gudang, finance, driver,
dekor, konsumsi, supplier, owner, pemuka_agama, hrd, purchasing, viewer,
tukang_foto, tukang_angkat_peti, tukang_jaga

SESUDAH (v1.38):
super_admin, consumer, service_officer, gudang, driver, dekor,
supplier, owner, pemuka_agama, hrd, purchasing, viewer,
tukang_foto, tukang_angkat_peti, tukang_jaga, petugas_akta, musisi, security

Catatan:
- `konsumsi` TIDAK di-seed sebagai role app (sesuai v1.36 — konsumsi = supplier eksternal).
- Tambah 2 role baru v1.36: petugas_akta, musisi.
- security dipertahankan sebagai role internal.
```

**Migration:**
```php
// database/migrations/2026_04_18_000001_v1_38_role_cleanup.php

public function up(): void {
    // 1. Hapus role admin & finance dari tabel roles
    DB::table('roles')->whereIn('slug', ['admin', 'finance'])->delete();

    // 2. Migrasi user lama:
    //    - role='admin' → role='super_admin' (atau 'purchasing' sesuai bidang)
    //    - role='finance' → role='purchasing'
    DB::table('users')->where('role', 'admin')->update(['role' => 'super_admin']);
    DB::table('users')->where('role', 'finance')->update(['role' => 'purchasing']);

    // 3. Seed role baru yang belum ada
    foreach (['petugas_akta', 'musisi'] as $slug) {
        DB::table('roles')->updateOrInsert(
            ['slug' => $slug],
            ['label' => Str::headline($slug), 'is_system' => true, 'is_active' => true,
             'created_at' => now(), 'updated_at' => now()]
        );
    }
}
```

### BUG-FIX 3: Role `konsumsi` — BUKAN role app
```
KEPUTUSAN FINAL (sesuai v1.36):
- Konsumsi = SUPPLIER EKSTERNAL (datang dari supplier luar, bukan karyawan SM)
- Dihapus dari route guard, dari seed users test, dari VendorHome routing
- field_attendances records lama dengan role='konsumsi' → archive (set is_legacy=true)
- Koordinasi dengan supplier konsumsi dilakukan oleh Purchasing via e-Katalog / WA supplier sementara
```

**Migration impact:**
```php
// Remove from roles table
DB::table('roles')->where('slug', 'konsumsi')->delete();

// Users yang role='konsumsi' (jika ada) → ubah ke 'supplier' dengan supplier_type='temporary'
DB::table('users')->where('role', 'konsumsi')->update([
    'role' => 'supplier',
    'supplier_type' => 'temporary'
]);
```

**Route guard update:**
```dart
// lib/app/routing.dart — HAPUS case 'konsumsi'
switch (user.role) {
  // ... role lain
  case 'dekor'           : → VendorHome(accentColor: AppColors.roleDekor)
  // case 'konsumsi'     : → HAPUS (v1.38)
  case 'pemuka_agama'    : → VendorHome(accentColor: AppColors.rolePemukaAgama)
  // ...
}
```

### BUG-FIX 4: Status order ENUM — v1.26 (17 status) AUTHORITATIVE

```
KEPUTUSAN FINAL:
- ENUM 17 status di v1.26 adalah SATU-SATUNYA yang valid.
- ENUM 6 status lama di v1.25 dianggap OBSOLETE.
- `cancelled` TETAP ADA di ENUM (untuk kasus luar biasa / Super Admin emergency)
  tapi TIDAK diekspos sebagai aksi di UI (sesuai v1.36 "tidak ada pembatalan").

Status valid (17 total):
  pending, awaiting_signature, so_review, confirmed, preparing, ready_to_dispatch,
  driver_assigned, delivering_equipment, equipment_arrived, picking_up_body,
  body_arrived, in_ceremony, heading_to_burial, burial_completed,
  returning_equipment, completed, cancelled

Auto-complete query update:
  SEBELUM: WHERE driver_overall_status = 'all_done'
  SESUDAH: WHERE status IN ('burial_completed', 'returning_equipment')
             AND driver_overall_status = 'all_done'
             AND NOW() > scheduled_at + estimated_duration_hours
```

### BUG-FIX 5: Tabel `order_checklists` — CANONICAL SCHEMA
```sql
CREATE TABLE order_checklists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  provider_role VARCHAR(50) NOT NULL,           -- role yang provide item ini
  stock_item_id UUID NULLABLE REFERENCES stock_items(id),
  item_name VARCHAR(255) NOT NULL,              -- snapshot dari stock_items/package_items
  quantity DECIMAL(10,2) NOT NULL DEFAULT 1,
  unit VARCHAR(50) DEFAULT 'pcs',
  is_checked BOOLEAN DEFAULT FALSE,
  checked_at TIMESTAMP NULLABLE,
  checked_by UUID NULLABLE REFERENCES users(id),
  check_photo_evidence_id UUID NULLABLE REFERENCES photo_evidences(id),
  deduction_transaction_id UUID NULLABLE REFERENCES stock_transactions(id),
  notes TEXT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

CREATE INDEX idx_order_checklists_order ON order_checklists(order_id);
CREATE INDEX idx_order_checklists_provider ON order_checklists(provider_role, is_checked);
```

**Generated saat order confirmed:**
- Loop semua `package_items` dari package terkait
- Group by `provider_role`
- Insert 1 row per item ke `order_checklists`
- Alarm dikirim per provider_role ke semua user role tersebut

### BUG-FIX 6: Tabel `stock_items` — CANONICAL SCHEMA
```sql
CREATE TABLE stock_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Identifikasi
  item_code VARCHAR(50) UNIQUE NOT NULL,          -- SKU internal, contoh: 'PTI', 'KPR', 'CLN'
  item_name VARCHAR(255) NOT NULL,                -- contoh: 'Peti Jenazah Premium'
  description TEXT,
  category VARCHAR(100),                          -- 'peti', 'dekorasi', 'konsumabel', dll

  -- Kuantitas
  current_quantity DECIMAL(10,2) NOT NULL DEFAULT 0,
  minimum_quantity DECIMAL(10,2) NOT NULL DEFAULT 0,  -- alert threshold
  unit VARCHAR(50) NOT NULL DEFAULT 'pcs',

  -- Sifat item (v1.18)
  item_nature ENUM('sewa','pakai_habis','pakai_kembali') NOT NULL DEFAULT 'pakai_habis',

  -- Lokasi kepemilikan (v1.29 + v1.31)
  owner_role VARCHAR(50) NOT NULL DEFAULT 'gudang',
  -- Nilai valid: 'gudang', 'service_officer' (untuk kantor), 'dekor' (untuk Lafiore)

  -- Harga
  unit_cost DECIMAL(15,2),                        -- biaya beli per unit (untuk profit calc)
  unit_price DECIMAL(15,2),                       -- harga jual per unit (untuk billing)

  -- Metadata
  photo_path TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  last_restocked_at TIMESTAMP,
  notes TEXT,

  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

CREATE INDEX idx_stock_items_code ON stock_items(item_code);
CREATE INDEX idx_stock_items_owner ON stock_items(owner_role, is_active);
CREATE INDEX idx_stock_items_low ON stock_items(current_quantity, minimum_quantity)
  WHERE is_active = true;
```

### BUG-FIX 7: `vehicles.status` ENUM extension
```sql
ALTER TABLE vehicles
  ALTER COLUMN status TYPE VARCHAR(30);

-- ENUM valid baru:
-- 'available'          : bisa di-assign
-- 'in_use'             : sedang dipakai order
-- 'maintenance'        : sedang servis
-- 'blocked_inspection' : inspeksi critical gagal, tidak boleh jalan (v1.20)
-- 'external'           : kendaraan sewa eksternal (v1.12)
-- 'retired'            : sudah tidak dipakai
```

**State machine:**
```
available → in_use (saat di-assign ke order)
in_use → available (saat order selesai + vehicle kembali)
available → maintenance (saat Gudang schedule servis)
maintenance → available (saat servis selesai + inspeksi pass)
available → blocked_inspection (saat pre-trip inspection critical gagal)
blocked_inspection → maintenance (saat Gudang buat maintenance request)
any → retired (manual oleh Super Admin)
external: status tetap 'external' sampai sewa berakhir
```

### BUG-FIX 8: `orders.payment_method` — EKSPLISIT
```sql
ALTER TABLE orders ADD COLUMN payment_method ENUM('cash','transfer') NULL;

-- Constraint: WAJIB terisi sebelum status bisa berubah ke 'confirmed'
-- Enforced di application layer (OrderController::confirm)
```

### BUG-FIX 9: Namespace `/finance/*` vs `/purchasing/*`
```
KEPUTUSAN FINAL:
- `/finance/*` = endpoint utama (authoritative, sesuai v1.30 reporting)
- `/purchasing/*` = deprecated alias untuk backward compat

Untuk Flutter:
- Semua panggilan API baru pakai /finance/*
- Endpoint /purchasing/* TETAP jalan tapi marked @deprecated di code
- Migrasi bertahap Flutter screens dari /purchasing → /finance (post go-live)

Role yang akses: 'purchasing' (role name tetap 'purchasing' di users table —
ini hanya namespace URL, bukan role name).
```

### BUG-FIX 10: Alarm severity levels (NORMAL/HIGH/ALARM) + v1.34
```
KEPUTUSAN FINAL:
- BACKEND: tetap simpan severity level ('NORMAL', 'HIGH', 'ALARM') di
  kolom notifications.severity untuk:
    * Dashboard filter (HRD lihat hanya ALARM-level)
    * Audit & analytics
    * Sort prioritas di list notif

- FCM DELIVERY: SEMUA notif dikirim dengan full-screen intent + sound + DND bypass
  (sesuai v1.34). Tidak ada lagi "silent notification" atau "low priority delivery".

- UX: Di dashboard notif app, severity ditandai via warna badge
  (ALARM=merah, HIGH=kuning, NORMAL=abu). Suara notif sama untuk semua.

Update tabel alarm legacy (v1.13, v1.23 master table):
- Baca sebagai "severity level untuk dashboard", BUKAN "mode delivery"
- Tidak perlu rewrite tabel alarm
```

### BUG-FIX 11: WhatsApp CS International format
```
SEBELUM (v1.37 typo):
cs_whatsapp_international = '6281127144440'  -- SALAH: 13 digit

SESUDAH (v1.38 fix):
cs_whatsapp_international = '628112714440'   -- BENAR: 12 digit

Validasi:
- Nomor lokal: '08112714440' (11 digit, diawali 0)
- Nomor internasional: '628112714440' (12 digit, diawali 62 tanpa 0)
- wa.me link: https://wa.me/628112714440
```

---

## TABEL BARU v1.38 — RINGKASAN

| Tabel | Fungsi |
|-------|--------|
| `order_so_visits` | Tracking visit SO ke lokasi keluarga (30+30 menit deadline) |
| `service_offerings` | 2 tipe layanan: anggota, non_anggota |
| `consumer_memberships` | Keanggotaan consumer (untuk service_type anggota) |
| `so_assignment_history` | Audit trail rotation SO per service_type |

## TABEL DIPERKAYA v1.38

| Tabel | Perubahan |
|-------|-----------|
| `orders` | + service_type, service_offering_id, payment_method, input_source |
| `orders.created_by_so_channel` | Hapus nilai 'consumer_self' |
| `vehicles.status` | Extend dengan 'blocked_inspection', 'external' |
| `roles` | Hapus 'admin', 'finance', 'konsumsi'; tambah 'petugas_akta', 'musisi' |

## SCHEMA CANONICAL YANG DIDEFINISIKAN ULANG v1.38

| Tabel | Status |
|-------|--------|
| `stock_items` | Full schema definition (sebelumnya hanya direferensikan) |
| `order_checklists` | Full schema definition (dipakai v1.29 tanpa schema) |

---

## DAMPAK KE ALUR ORDER v1.38

```
╔═══════════════════════════════════════════════════════════════════════╗
║  ALUR BARU SEJAK ORDER MASUK                                         ║
╠═══════════════════════════════════════════════════════════════════════╣
║                                                                       ║
║  Menit 0    : Keluarga hubungi SM (telepon/WA/walk-in)                ║
║  Menit 0-5  : SO input order ke app                                   ║
║               - service_type: anggota / non_anggota (auto cek membership)
║               - payment_method: cash / transfer                       ║
║  Menit 5-10 : Sistem auto-rotation → assign SO berdasarkan            ║
║               so_assignment_history (fair distribution)               ║
║  Menit 5-35 : SO WAJIB tiba di lokasi keluarga (30 menit deadline)   ║
║               - Foto selfie + geofence saat tiba                      ║
║               - Atau request perpanjangan 30 menit (sekali saja)      ║
║  Menit 35+  : Jika lewat → alarm HRD + reassign SO                   ║
║  Di lokasi  : SO bantu isi SAL + tanda tangan                         ║
║               → SO konfirmasi order                                   ║
║               → Mulai alur distribusi ke Gudang/Kantor/Lafiore        ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝
```

---

## ATURAN BISNIS v1.38

```
1. ORDER INPUT: 100% via SO. Consumer app tidak bisa buat order baru.

2. SO VISIT: 30 menit initial + 30 menit extension maksimal 1x.
   Foto selfie + geofencing WAJIB saat tiba.

3. SERVICE TYPE: Anggota atau Non-Anggota. Tidak ada "paket" sebagai label.
   Anggota profit lebih kecil, Non-Anggota profit normal.

4. SO ROTATION: Fair distribution — SO yang paling lama tidak dapat
   tipe layanan tertentu → prioritas pertama untuk tipe itu.

5. BUG FIXES: Role cleanup, status ENUM alignment, schema canonical,
   namespace /finance, alarm severity clarification, WA international
   format fix — semua diselesaikan di v1.38.
```

## CHANGELOG v1.38

### v1.38 — SO-Mandatory, Visit Deadline, Service Type Anggota/Non-Anggota, Critical Bug Consolidation

**New Requirements:**
- Input order WAJIB via SO (consumer self-order deprecated)
- SO visit deadline 30 menit + 30 menit perpanjangan (foto selfie + geofence)
- Service type Anggota vs Non-Anggota (menggantikan konsep "paket" sebagai label utama)
- Membership tracking untuk consumer
- Auto-rotation SO per service type (fair distribution)
- 4 tabel baru: order_so_visits, service_offerings, consumer_memberships, so_assignment_history

**Critical Bug Fixes (dari audit v1.37):**
- Header version 1.27 → 1.38
- Role seed cleanup: hapus admin, finance, konsumsi
- Status order ENUM v1.26 (17 status) authoritative
- stock_items schema canonical
- order_checklists schema canonical
- vehicles.status ENUM extension (blocked_inspection, external)
- orders.payment_method explicit column
- /finance/* vs /purchasing/* namespace resolution
- Alarm severity clarification (storage vs delivery)
- WhatsApp CS international format fix

**Pending (konsultasi owner):**
- Harga dasar & margin untuk service_type Anggota vs Non-Anggota
- Kriteria/syarat menjadi Anggota Santa Maria
- Biaya/iuran keanggotaan (jika ada)

---

# SANTA MARIA — PATCH v1.39
# Konsolidasi 100 Jawaban Owner: Paket Dipertahankan, Admin Kantor Reinstated, Membership Subscription, Transport Luar Kota, GDrive SM, Barcode Barang Rusak

---

## KLARIFIKASI FUNDAMENTAL & KOREKSI v1.38 → v1.39

Berdasarkan jawaban owner atas 100 pertanyaan (tanggal 18 April 2026),
spec v1.38 dikoreksi dan diperluas sebagai berikut.

---

## PART 1 — KOREKSI FUNDAMENTAL v1.38

### KOREKSI-1: PAKET TETAP DIPAKAI (v1.38 SALAH MENGHAPUS)

```
╔═══════════════════════════════════════════════════════════════════════╗
║  SERVICE TYPE dan PAKET adalah DUA DIMENSI ORTHOGONAL                ║
║                                                                       ║
║  DIMENSI 1 — SERVICE TYPE (baru v1.38):                               ║
║    • Anggota       → dapat diskon harga paket + bayar iuran bulanan   ║
║    • Non-Anggota   → harga paket standar (lebih mahal dari Anggota)   ║
║                                                                       ║
║  DIMENSI 2 — PAKET (lama, TETAP HIDUP):                               ║
║    • Paket Dasar / Premium / Eksklusif (atau apapun namanya)          ║
║    • Menentukan CONTENT layanan (peti, dekorasi, makanan, dll)        ║
║                                                                       ║
║  Kombinasi order:                                                     ║
║    • [Anggota × Paket Dasar]      → paket A dengan harga diskon       ║
║    • [Non-Anggota × Paket Premium] → paket B harga standar            ║
║    • dll                                                              ║
║                                                                       ║
║  ISI PAKET UNTUK ANGGOTA vs NON-ANGGOTA BISA BERBEDA                  ║
║  (konten dinamis per service_type)                                    ║
╚═══════════════════════════════════════════════════════════════════════╝
```

**Schema correction:**
```sql
-- v1.38 bilang service_offerings menggantikan packages — SALAH.
-- v1.39: service_offerings dihapus. Cukup extend packages:

ALTER TABLE packages
  ADD COLUMN price_anggota DECIMAL(15,2),      -- harga untuk service_type = anggota
  ADD COLUMN price_non_anggota DECIMAL(15,2);  -- harga untuk service_type = non_anggota

-- Content paket bisa beda per service_type:
ALTER TABLE package_items
  ADD COLUMN applicable_service_types VARCHAR(50) DEFAULT 'both';
-- Nilai: 'anggota_only', 'non_anggota_only', 'both'

-- orders.service_type TETAP ada (dari v1.38)
-- orders.package_id TETAP WAJIB
-- orders.service_offering_id DIHAPUS (tidak dipakai)
```

**Pricing calc saat order dibuat:**
```
order.total = CASE order.service_type
  WHEN 'anggota' THEN packages.price_anggota
  WHEN 'non_anggota' THEN packages.price_non_anggota
END + Σ(add-ons)
```

### KOREKSI-2: STOK KANTOR DIPEGANG SUPER ADMIN (BUKAN REINSTATE ADMIN)

```
╔═══════════════════════════════════════════════════════════════════════╗
║  Owner mengklarifikasi (setelah v1.39 draft):                         ║
║  "Itu seharusnya SUPER ADMIN, bukan admin. Admin tetap dihapus."      ║
║                                                                       ║
║  KEPUTUSAN FINAL:                                                     ║
║  • Role `admin` TETAP DIHAPUS PERMANEN (sesuai v1.8 & v1.38)          ║
║  • Stok kantor dipegang oleh SUPER ADMIN                              ║
║  • Super Admin (God Mode, v1.27) bertambah tanggung jawab operasional:║
║    - Kelola stok kantor (CRUD stock_items owner_role='super_admin')   ║
║    - Input data consumer walk-in (atas nama SO jika perlu)            ║
║    - Daftarkan Anggota baru                                           ║
║    - Administrasi umum kantor                                         ║
║  • Super Admin TETAP God Mode untuk fungsi sistem (master data, dll)  ║
╚═══════════════════════════════════════════════════════════════════════╝
```

**Implikasi:**
- Jumlah Super Admin = 1 orang (jawaban Q68), merangkap administrasi kantor.
- Super Admin berperan seperti "kepala kantor" operasional + admin sistem.
- Tidak ada role `admin` baru. `admin` tetap di-deprecated permanent.

**Schema update:**
```sql
-- TIDAK ADA re-insert role 'admin'. Admin tetap dihapus.
-- stock_items.owner_role valid values:
--   'gudang'      → stok gudang
--   'super_admin' → stok kantor (dipegang Super Admin)
--   'dekor'       → stok Lafiore

-- Migration (cleanup jika ada legacy data):
UPDATE stock_items SET owner_role = 'super_admin' WHERE owner_role = 'admin';
DELETE FROM roles WHERE slug = 'admin';  -- pastikan admin tidak ada
```

**Route guard:** TIDAK ADA `case 'admin'`. Super Admin tetap pakai `AdminDashboard` (v1.27) yang sudah God Mode — sekarang diperkaya dengan tab khusus untuk operasional kantor.

**Flutter screen tambahan untuk Super Admin (operasional kantor):**
```
lib/features/admin/screens/
  ├── admin_dashboard.dart                    -- (sudah ada) tambah quick access ke:
  │     -- [📦 Stok Kantor] [👥 Daftar Anggota] [🚶 Walk-in Consumer]
  │
  ├── kantor_stock_screen.dart                -- BARU: kelola stok kantor
  │     -- Pakai shared role_inventory_screen dengan owner_role='super_admin'
  │
  ├── walkin_consumer_screen.dart             -- BARU: input consumer walk-in
  │     -- Form lengkap data consumer (biasanya SO input, tapi Super Admin bisa bantu)
  │     -- Setelah input selesai → assign SO yang akan handle order-nya
  │
  └── (membership_registration_screen sudah ada di Super Admin scope via master data)
```

### KOREKSI-3: GOOGLE DRIVE TUKANG FOTO = DARI SM (bukan pribadi)

```
v1.36 bilang: "upload ke Google Drive PRIBADI mereka"
v1.39 koreksi (jawaban Q43): Google Drive DARI SM (shared workspace SM)

Tukang foto dapat akses ke folder Google Drive SM per order.
Upload foto → folder tersebut → link otomatis terikat ke order.
Consumer akses link TANPA melihat folder lain (via shared link dengan permission).
```

**Implication:**
- SM perlu setup Google Workspace dengan struktur folder: `/orders/{order_number}/photos/`
- Tukang foto login dengan akun tamu/shared credential atau Google Drive API
- Link per order auto-generated + shareable dengan consumer (view-only)

### KOREKSI-4: CANCEL FITUR `service_offerings` DARI v1.38

```sql
-- v1.38 create table service_offerings dan consumer_memberships
-- v1.39: HAPUS service_offerings (tidak dipakai).
-- consumer_memberships TETAP ada, tapi struktur diperluas (lihat PART 2).

DROP TABLE IF EXISTS service_offerings;
```

---

## PART 2 — SERVICE TYPE & MEMBERSHIP (JAWABAN Q1-Q10, Q97-Q100)

### Membership Model — Subscription Bulanan

```
Anggota = konsumen yang daftar dan BAYAR IURAN BULANAN ke SM.

Aturan:
- Status Anggota AKTIF selama masih bayar iuran bulanan.
- Tidak bayar 1 bulan → status 'grace_period' (tetap dapat harga anggota)
- Tidak bayar 2 bulan berturut → status 'inactive' (harga kembali non-anggota)
- Anggota boleh cancel kapan saja, uang iuran TIDAK dikembalikan.
- Kriteria jadi Anggota: cukup daftar + setuju bayar iuran bulanan.
  (Tidak ada background check, referral, dll)
- Kartu anggota: DIGITAL saja di consumer app (tidak ada kartu fisik)
- Yang didaftarkan Anggota: konsumen itu sendiri (bukan keluarga).
  Saat ada kematian, yang dapat harga anggota = almarhum adalah Anggota,
  atau PJ order adalah Anggota yang daftar.
```

**Update `consumer_memberships`:**
```sql
-- Dari v1.38, perluas:
ALTER TABLE consumer_memberships
  ADD COLUMN monthly_fee DECIMAL(15,2),           -- iuran per bulan (PENDING confirm)
  ADD COLUMN last_payment_date DATE,
  ADD COLUMN next_payment_due DATE,
  ADD COLUMN grace_period_until DATE,             -- batas toleransi tidak bayar
  ADD COLUMN total_paid DECIMAL(15,2) DEFAULT 0,
  ADD COLUMN cancelled_at TIMESTAMP,
  ADD COLUMN cancellation_reason TEXT;

-- status ENUM diperluas:
-- 'active'         : bayar tepat waktu
-- 'grace_period'   : telat < 1 bulan (tetap dapat harga anggota)
-- 'inactive'       : telat 2+ bulan (kembali ke non-anggota)
-- 'cancelled'      : consumer cancel sendiri
-- 'suspended'      : suspended oleh admin (mis. fraud)
```

**Tabel `membership_payments`:**
```sql
CREATE TABLE membership_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  membership_id UUID REFERENCES consumer_memberships(id) ON DELETE CASCADE,
  payment_period_year INTEGER NOT NULL,
  payment_period_month INTEGER NOT NULL,
  amount DECIMAL(15,2) NOT NULL,
  payment_method ENUM('cash','transfer') NOT NULL,
  paid_at TIMESTAMP NOT NULL DEFAULT NOW(),
  received_by UUID REFERENCES users(id),        -- Admin/Purchasing yang input
  receipt_path TEXT,
  notes TEXT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  UNIQUE(membership_id, payment_period_year, payment_period_month)
);
```

**Scheduler:**
```php
// Setiap hari pagi — cek status membership
$schedule->command('membership:check-payment-status')->dailyAt('06:00');

// Logic:
// - Jika next_payment_due lewat > 30 hari → set status 'grace_period'
// - Jika next_payment_due lewat > 60 hari → set status 'inactive'
// - Kirim reminder ke consumer H-7, H-3, H-1 sebelum jatuh tempo
```

**API endpoints:**
```
POST   /so/membership/register               -- SO input pendaftaran anggota baru
  Body: { consumer_user_id, membership_number (optional, auto-gen), monthly_fee }
GET    /so/membership/{id}                   -- lihat detail
POST   /purchasing/membership/{id}/payment   -- input pembayaran iuran bulanan
  Body: { period_year, period_month, amount, payment_method, receipt }
GET    /consumer/me/membership               -- consumer lihat status keanggotaan sendiri
GET    /consumer/me/membership/payments      -- riwayat pembayaran iuran
PUT    /consumer/me/membership/cancel        -- consumer cancel keanggotaan
PUT    /consumer/me/profile                  -- update alamat/HP via app
```

### ⏳ PENDING — Membership

| # | Item | Status |
|---|------|--------|
| Q2 | Nominal iuran keanggotaan per bulan | Belum dikonfirmasi |
| Q5 | Profit margin Anggota vs Non-Anggota | Belum dikonfirmasi |
| Q9 | List add-on + harga | Belum dikonfirmasi |
| Q8 | Detail isi paket untuk Anggota vs Non-Anggota | Belum dikonfirmasi |

---

## PART 3 — SO DETAIL (JAWABAN Q11-Q18, Q94-Q96)

```
✓ Jumlah SO saat ini: 2 orang (dinamis, bisa bertambah)
✓ Semua SO handle kedua service_type (Anggota + Non-Anggota)
✓ Jam kerja SO: 24 JAM (shift — detail shift belum dikonfirmasi)
✓ SO lapangan vs SO kantor: job desc sama
✓ SO TIDAK menyimpan stok (stok kantor dipegang Admin)
✓ Target harian/bulanan: ada (nominal PENDING)
✓ Keluarga TIDAK input order — SO yang input (diperkuat v1.38)
✓ Tie rotation: pilih RANDOM (kalau last_assigned_at sama persis)
✓ Bonus SO: formula PENDING

✓ SO sedang visit BOLEH terima order baru
  → SO janjian dulu sama consumer via WhatsApp
  → Upload bukti follow-up WA di app (screenshot percakapan)
  → Order masuk sebagai sequence berikutnya dalam rotation
  
✓ Jika semua SO sedang visit: force-assign ke SO paling lama idle
  (dengan tetap consider service_type history untuk fair rotation)

✓ Rotation tidak pernah di-reset (cumulative selamanya — audit trail abadi)
```

**Update `order_so_visits`:**
```sql
ALTER TABLE order_so_visits
  ADD COLUMN followup_whatsapp_screenshot_evidence_id UUID REFERENCES photo_evidences(id);

-- Saat SO sedang handle visit lain dan dapat order baru:
-- → SO kirim WA ke consumer baru: "Saya akan ke tempat Anda setelah selesai order X"
-- → Screenshot WA di-upload via photo_evidences (context: 'so_followup_whatsapp')
-- → Field ini link ke screenshot
```

**Rotation tie-break update:**
```
if eligibleSos.size > 1 and all(last_assigned_at sama persis):
    selectedSo = eligibleSos.random()  // bukan urutan alfabet, bukan senior
```

### ⏳ PENDING — SO

| # | Item | Status |
|---|------|--------|
| Q13 | Detail shift 24 jam (jam berapa shift ganti) | Belum dikonfirmasi |
| Q15 | Target harian/bulanan SO (angka konkrit) | Belum dikonfirmasi |
| Q18 | Commission/bonus SO formula | Belum dikonfirmasi |

---

## PART 4 — GUDANG, KANTOR (ADMIN), LAFIORE (JAWABAN Q19-Q28)

### Gudang
```
✓ Jumlah staff gudang: PENDING
✓ Weekend/libur nasional: ada yang standby (rotasi)
✓ Stock opname: MINGGUAN, oleh masing-masing role yang punya stok
  (bukan hanya gudang — Super Admin (stok kantor) & Lafiore juga opname mingguan)
✓ Stok critical habis saat order masuk: Purchasing langsung PO darurat.
  Kalau PETI kosong stok → paket TIDAK MUNCUL di pilihan SO
  (stock-aware dari v1.25 diperkuat)
✓ Consignment supplier: PENDING
```

**Extension `packages` stock-aware logic (dari v1.25):**
```sql
-- v1.25 mendefinisikan package_items.is_critical. Tambahkan rule:
-- Saat SO pilih paket, filter:
-- - Paket dengan item critical stok=0 di KEDUA lokasi (gudang & kantor)
--   → TIDAK MUNCUL di list paket SO
-- - Peti adalah item paling critical: kalau habis di gudang & lokasi lain,
--   paket langsung di-hide
```

### Kantor (Super Admin)
```
✓ Stok kantor dipegang SUPER ADMIN (owner_role = 'super_admin' di stock_items)
✓ Role `admin` tetap dihapus permanen (KOREKSI-2 di atas)
✓ Super Admin (1 orang) = God Mode sistem + kepala operasional kantor
✓ Barang apa saja di kantor vs gudang: PENDING list detail

CATATAN:
Stok di kantor tidak sebanyak gudang — biasanya item darurat / 
item yang dibutuhkan di kantor sendiri.
Super Admin mingguan stock opname seperti role lain yang punya stok.
```

### Lafiore (Dekor)
```
✓ Jumlah staff Lafiore: PENDING
✓ Lafiore layani klien LUAR SM: TIDAK (hanya order SM internal)
✓ Bahan baku (bunga, vas, kayu): beli via Purchasing (bukan Lafiore beli sendiri)
```

**Procurement flow untuk Lafiore (diperkuat):**
```
Lafiore butuh bahan → POST /procurement-requests
  (requested_by = user_lafiore, category = 'bahan_dekorasi')
→ Purchasing review + cari supplier (bidding atau manual)
→ Purchasing approve + supplier kirim ke Lafiore
→ Lafiore terima barang + update stok (owner_role='dekor')
```

### ⏳ PENDING — Gudang/Kantor/Lafiore

| # | Item | Status |
|---|------|--------|
| Q19 | Jumlah staff gudang | Belum dikonfirmasi |
| Q23 | Consignment supplier (ada/tidak) | Belum dikonfirmasi |
| Q25 | List barang kantor vs gudang | Belum dikonfirmasi |
| Q26 | Jumlah staff Lafiore | Belum dikonfirmasi |

---

## PART 5 — DRIVER (JAWABAN Q29-Q32)

```
✓ Jumlah driver per lokasi (gudang/kantor/Lafiore): PENDING
✓ Driver TIDAK ada libur tetap (selalu stand-by — konsekuensi layanan 24 jam)
✓ Driver sakit mendadak: sistem auto-pilih driver backup dari pool yang available
✓ Driver TIDAK BOLEH refuse assignment (harus terima apapun)
```

**Update rule v1.32 "driver selalu aktif":**
```
- "Tidak ada libur" ≠ "kerja 24/7 non-stop"
- Sistem tetap track jam kerja driver via daily_attendances
- Overtime detection tetap jalan (driver_max_duty_hours = 12 di system_thresholds)
- Jika driver sakit → clock-in dengan alasan 'sakit' → sistem skip dari assignment
  → alarm HRD untuk follow-up
- Jika driver tolak assignment → catat hrd_violations (driver_refuse_assignment)
  → severity: high
```

**System thresholds tambah:**
```
driver_consecutive_days_without_rest_max = 6   -- alarm HRD jika > 6 hari tanpa rest day
```

### ⏳ PENDING — Driver

| # | Item | Status |
|---|------|--------|
| Q29 | Jumlah driver per lokasi | Belum dikonfirmasi |

---

## PART 6 — PURCHASING, PEMUKA AGAMA, TUKANG FOTO (JAWABAN Q33-Q44)

### Purchasing / Finance
```
✓ Jumlah staff Purchasing: 1 ORANG
✓ Approval limit: TIDAK ADA (Purchasing bebas approve nominal berapa pun)
✓ Pajak PPN/PPh: TIDAK DITRACK di sistem
✓ Petty cash: BUTUH, tidak ada limit nominal
✓ Backup saat cuti: TIDAK ADA (harus Purchasing itu sendiri yang handle)

IMPLIKASI:
- Jika Purchasing cuti → sistem akan freeze approval pending
- Owner bisa override manual via Super Admin impersonate
- Urgent PO saat Purchasing off: notifikasi ke Super Admin/Owner
```

**Risk mitigation:**
```sql
-- Tabel untuk tracking Purchasing availability:
CREATE TABLE purchasing_availability (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  purchasing_user_id UUID REFERENCES users(id),
  date DATE NOT NULL,
  status ENUM('available','sick','leave','off') DEFAULT 'available',
  notes TEXT,
  created_at TIMESTAMP
);

-- Trigger: jika status != 'available' dan ada procurement_requests urgent → alert Owner
```

**Petty cash:**
```sql
-- Tabel baru:
CREATE TABLE petty_cash_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  amount DECIMAL(15,2) NOT NULL,
  direction ENUM('in','out') NOT NULL,
  category VARCHAR(100),
  description TEXT NOT NULL,
  reference_type VARCHAR(50),               -- 'order', 'procurement', 'operational'
  reference_id UUID,
  performed_by UUID REFERENCES users(id),
  receipt_photo_path TEXT,
  balance_after DECIMAL(15,2) NOT NULL,     -- saldo kas setelah transaksi
  created_at TIMESTAMP
);

-- Auto-integrate ke financial_transactions (v1.30)
```

### Pemuka Agama
```
✓ Database pemuka agama internal SM: semua agama (jumlah bertambah, PENDING detail)
✓ Honor: PER ORDER (bukan bulanan)
✓ Nominal honor per order: PENDING
✓ Consumer bawa pemuka agama sendiri (external):
  → SM TETAP BAYAR HONOR ke pemuka agama tersebut
  → Bukan zero fee seperti dugaan spec lama
  → Fee ditransfer oleh Purchasing setelah prosesi

CATATAN:
Ini berbeda dari spec v1.24 yang menyebut "Rp 0 jika vendor gratis".
Di SM, pemuka agama SELALU dibayar (baik internal maupun external).
```

**Update `order_vendor_assignments` fee logic:**
```
Sebelum v1.39: external vendor bisa fee = Rp 0
Sesudah v1.39: untuk vendor_role = 'pemuka_agama', fee WAJIB > 0
  → Rate per order dikonfigurasi di vendor_role_master + system setting
```

### Tukang Foto
```
✓ Database tukang foto freelance: belum ada (akan dibangun)
✓ Upah per order (bukan per jam)
✓ Google Drive: DARI SM (bukan pribadi tukang foto) — KOREKSI-3
✓ Watermark "Santa Maria" di foto: OPSIONAL
```

**Update schema untuk Google Drive SM:**
```sql
-- Tabel order_photo_deliveries (replace konsep v1.36 Google Drive pribadi):
CREATE TABLE order_photo_deliveries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  assigned_photographer_id UUID REFERENCES users(id),
  
  -- Google Drive folder per order (dari workspace SM)
  gdrive_folder_id VARCHAR(255),              -- Google Drive folder ID
  gdrive_folder_url TEXT,                     -- shareable URL
  consumer_shareable_url TEXT,                -- link view-only untuk consumer (setelah lunas)
  
  -- Upload tracking
  upload_deadline TIMESTAMP NOT NULL,         -- scheduled_at + 3 jam (v1.34)
  uploaded_at TIMESTAMP,
  photo_count INTEGER DEFAULT 0,
  video_count INTEGER DEFAULT 0,
  total_size_mb DECIMAL(10,2),
  
  -- Status
  status ENUM(
    'pending',              -- belum upload
    'uploaded',             -- sudah upload sebelum deadline
    'late',                 -- upload setelah deadline
    'not_delivered'         -- > 24 jam setelah deadline tidak upload
  ) DEFAULT 'pending',
  
  notes TEXT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

**Google Drive integration:**
- SM setup Google Workspace
- Root folder: `/SantaMaria_Orders/{year}/{month}/{order_number}/`
- Tukang foto dapat akses via Google OAuth (login dengan akun pribadi, authorized untuk SM workspace)
- Consumer akses via shareable link (view-only) SETELAH lunas
- Link otomatis expire jika consumer belum lunas > 30 hari? (PENDING confirm)

### ⏳ PENDING — Purchasing/Pemuka Agama/Tukang Foto

| # | Item | Status |
|---|------|--------|
| Q38 | Jumlah pemuka agama per agama | Belum dikonfirmasi |
| Q39 | Nominal honor pemuka agama per order | Belum dikonfirmasi |
| Q41 | Database tukang foto (akan dibangun) | Belum dikonfirmasi |
| Q42 | Nominal upah tukang foto per order | Belum dikonfirmasi |

---

## PART 7 — TUKANG JAGA, TUKANG ANGKAT PETI, MUSISI (JAWABAN Q45-Q54)

### Tukang Jaga
```
✓ Database tukang jaga: 1 ORANG per shift (bukan pool besar)
✓ Rekrut baru: HRD yang wawancara
✓ Sakit/tidak datang: fallback ke tukang jaga lain yang available
✓ Makan & minum: PENDING (SM atau bawa sendiri)
```

**Update `tukang_jaga_shifts` (dari v1.29):**
```sql
-- Tambah kolom:
ALTER TABLE tukang_jaga_shifts
  ADD COLUMN backup_tukang_jaga_id UUID REFERENCES users(id),  -- backup yang di-call
  ADD COLUMN original_assigned_to UUID REFERENCES users(id);   -- yang awalnya di-assign
```

### Tukang Angkat Peti
```
✓ Jumlah orang TERGANTUNG UKURAN PETI (dari master data peti):
  - Peti kecil/standard: 4-6 orang
  - Peti besar/medium: 6-8 orang
  - Peti jumbo/oversize: 8-10 orang
  - Exact number: koordinator yang tentukan

✓ Koordinator pilih orang-orangnya (punya jaringan sendiri)
✓ Koordinator digaji PER ORDER (bukan bulanan)
✓ Upah Rp 75.000/hari/orang = LUMP SUM ke koordinator
  → Koordinator distribusi sendiri ke anak buahnya
  → SM bayar total ke koordinator saja (1 transaksi)
```

**Schema extension (dari v1.14 + v1.34):**
```sql
-- Tabel master ukuran peti → rekomendasi jumlah angkat:
CREATE TABLE coffin_size_master (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  size_label VARCHAR(50) UNIQUE NOT NULL,         -- 'kecil','standard','medium','besar','jumbo'
  min_length_cm INTEGER,
  max_length_cm INTEGER,
  recommended_lifters_min SMALLINT NOT NULL,      -- cth: 4
  recommended_lifters_max SMALLINT NOT NULL,      -- cth: 6
  sort_order INTEGER,
  is_active BOOLEAN DEFAULT TRUE
);

-- Link ke order:
ALTER TABLE orders
  ADD COLUMN coffin_size_id UUID REFERENCES coffin_size_master(id),
  ADD COLUMN lifters_count SMALLINT;    -- jumlah aktual (ditentukan koordinator)
```

**Seed:**
```
kecil    | 150-180 cm | 4-4 orang
standard | 180-200 cm | 4-6 orang
medium   | 200-215 cm | 6-6 orang
besar    | 215-230 cm | 6-8 orang
jumbo    | 230+ cm    | 8-10 orang
```

### Musisi
```
✓ Jumlah musisi/grup: PENDING
✓ MC MERANGKAP sebagai musisi (bisa 1 orang yang sama)
✓ Alat musik: PENDING (SM sediakan atau musisi bawa)
```

### ⏳ PENDING — Tukang Jaga/Angkat Peti/Musisi

| # | Item | Status |
|---|------|--------|
| Q48 | Makan & minum tukang jaga (SM/bawa sendiri) | Belum dikonfirmasi |
| Q52 | Jumlah musisi/grup langganan | Belum dikonfirmasi |
| Q54 | Alat musik (SM sediakan/musisi bawa) | Belum dikonfirmasi |

---

## PART 8 — PETUGAS AKTA, HRD, SECURITY, OWNER (JAWABAN Q55-Q68)

### Petugas Akta
```
✓ Jumlah: 1 ORANG
✓ Durasi akta: TERGANTUNG DUKCAPIL (variable — ambil rata-rata dari internet)
✓ Akta jadi: TUNGGU CONSUMER LUNAS (baru diserahkan)
✓ Biaya admin instansi: KELUARGA YANG TANGGUNG (bukan SM)
✓ Instansi mana saja: PENDING (akan ambil dari internet nanti)
```

**Update `order_death_cert_progress` (dari spec v1.36):**
```sql
CREATE TABLE order_death_cert_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id),
  petugas_akta_id UUID REFERENCES users(id),
  
  -- Tahapan
  current_stage ENUM(
    'not_started',
    'collecting_docs',         -- kumpulkan dokumen dari keluarga
    'submitted_to_kelurahan',  -- submit ke kelurahan
    'processing_kelurahan',
    'submitted_to_kecamatan',
    'processing_kecamatan',
    'submitted_to_dukcapil',
    'processing_dukcapil',
    'cert_issued',             -- akta jadi
    'waiting_payment',         -- tunggu consumer lunas
    'handed_to_family'         -- sudah serahkan ke keluarga
  ) DEFAULT 'not_started',
  
  -- Biaya instansi (ditagihkan ke keluarga via order_billing_items)
  total_admin_fees DECIMAL(15,2) DEFAULT 0,
  admin_fees_breakdown JSONB,                -- {kelurahan: 50000, dukcapil: 150000, dll}
  
  started_at TIMESTAMP,
  cert_issued_at TIMESTAMP,
  handed_to_family_at TIMESTAMP,
  days_elapsed INTEGER,                      -- auto-calc
  
  notes TEXT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- Log per tahap dengan foto bukti:
CREATE TABLE death_cert_stage_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  progress_id UUID REFERENCES order_death_cert_progress(id) ON DELETE CASCADE,
  stage VARCHAR(50) NOT NULL,
  institution_name VARCHAR(255),             -- "Kelurahan Pandanaran"
  visited_at TIMESTAMP NOT NULL,
  photo_evidence_id UUID REFERENCES photo_evidences(id),   -- foto kunjungan (geofence)
  fee_paid DECIMAL(15,2),                    -- biaya di instansi ini
  receipt_photo_evidence_id UUID REFERENCES photo_evidences(id),
  notes TEXT,
  created_at TIMESTAMP
);
```

**Consumer view (real-time):**
```dart
// lib/features/consumer/screens/death_cert_progress_screen.dart
// Timeline step-by-step:
// ✅ Collecting documents     (14 Apr)
// ✅ Submitted to Kelurahan   (15 Apr)  [foto bukti]
// 🔵 Processing at Kelurahan  (16 Apr — now)
// ⏳ Submit to Dukcapil
// ⏳ Cert Issued
// ⏳ Handed to Family
```

### HRD
```
✓ Gaji pokok per role: PENDING (nanti dilengkapi)
✓ THR/cuti/sakit: TRACK DI APP
✓ Progression teguran (SP1→SP2→SP3→PHK): PENDING
✓ Bonus formula: PENDING (ada formula)
```

**Tabel HRD tambahan:**
```sql
CREATE TABLE employee_leaves (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  leave_type ENUM('cuti_tahunan','sakit','izin','thr','cuti_khusus') NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  days_count INTEGER NOT NULL,
  reason TEXT,
  medical_cert_photo TEXT,                  -- jika sakit, foto surat dokter
  status ENUM('requested','approved','rejected','cancelled') DEFAULT 'requested',
  approved_by UUID REFERENCES users(id),
  approved_at TIMESTAMP,
  rejection_reason TEXT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

CREATE TABLE employee_thr (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  year INTEGER NOT NULL,
  amount DECIMAL(15,2) NOT NULL,
  paid_at TIMESTAMP,
  notes TEXT,
  created_at TIMESTAMP,
  UNIQUE(user_id, year)
);
```

### Security
```
✓ Shift security (pagi/malam/24 jam detail PENDING)
✓ Tamu WAJIB REGISTRASI di security (bawa KTP, dll)
✓ CCTV TERINTEGRASI (ada IP untuk disambung ke dashboard owner)
```

**CCTV integration:**
```sql
CREATE TABLE cctv_cameras (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  camera_label VARCHAR(255) NOT NULL,          -- "Kantor Depan", "Gudang Pintu 1"
  location_type ENUM('kantor','gudang','lafiore','parkiran','pos_security'),
  ip_address VARCHAR(50) NOT NULL,
  stream_url TEXT NOT NULL,                    -- RTSP atau HTTP stream URL
  username VARCHAR(100),                       -- credential (encrypted)
  password_encrypted TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  added_by UUID REFERENCES users(id),
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- Owner dashboard:
-- GET /owner/cctv/cameras           -- list semua camera
-- GET /owner/cctv/cameras/{id}/live -- ambil live stream URL (auth via VPN atau proxy)
```

**Update Security incident form (v1.23):**
```sql
-- Tambah ke security_incident_logs:
ALTER TABLE security_incident_logs
  ADD COLUMN visitor_ktp_photo_evidence_id UUID REFERENCES photo_evidences(id);
-- Foto KTP tamu saat registrasi (wajib)
```

### Owner
```
✓ Auto-alert anomali: APAPUN yang AI bisa provide
  → Owner mau "smart alert" — AI detect anything unusual
✓ Super Admin: 1 ORANG (owner sendiri atau staff IT)
```

**AI Anomaly Detection (v1.39):**
```
Implementasi AI-powered anomaly detection:
- Baseline: data historis (min 3 bulan operasional)
- AI detect:
  * Order volume unusual (spike/drop > 30%)
  * BBM efficiency drop > 20%
  * KPI karyawan turun drastis
  * Payment delay pattern unusual
  * Vehicle idle time > rata-rata
  * Stock movement anomaly
  * Login attempt mencurigakan
  * Geolocation anomaly (karyawan jauh dari expected location)
- Alert via OpenAI GPT-4o mini:
  "Anomali terdeteksi: [detail]. Saran: [action]"
- Frekuensi check: setiap 15 menit (scheduler)
```

### ⏳ PENDING — Petugas Akta/HRD/Security/Owner

| # | Item | Status |
|---|------|--------|
| Q56 | Durasi akta rata-rata (ambil dari internet) | Belum dikonfirmasi |
| Q59 | List instansi akta (ambil dari internet) | Belum dikonfirmasi |
| Q60 | Gaji pokok per role (list) | Belum dikonfirmasi |
| Q62 | Progression teguran SP1-SP3 trigger | Belum dikonfirmasi |
| Q63 | Bonus formula | Belum dikonfirmasi |
| Q64 | Jumlah security + detail shift | Belum dikonfirmasi |

---

## PART 9 — PAYMENT & TRANSPORT LUAR KOTA (JAWABAN Q69-Q74)

### Payment
```
✓ SOP keterlambatan bayar (> 3 hari): PENDING
✓ Cicilan: TIDAK BOLEH
✓ Metode: CASH dan TRANSFER (via bukti upload dari aplikasi consumer)
  → Tidak ada QRIS, Virtual Account, payment gateway online
  → Transfer manual ke rekening SM + consumer upload bukti via app
```

**Schema adjustment:**
```sql
-- orders.payment_method sudah ada dari v1.38 (cash/transfer)
-- Tidak perlu tambahan.
```

### Transport Luar Kota
```
✓ SM MELAYANI pemakaman luar kota + LUAR PULAU
✓ Jenazah dari luar kota (bandara/terminal): alur sama
✓ Biaya tambahan: Rp 25.000 PER KM FIX (dari titik penjemputan)
  → Bukan negosiasi, fixed rate
  → Dihitung otomatis: distance × 25.000
```

**Schema extension:**
```sql
-- Tambah ke orders:
ALTER TABLE orders
  ADD COLUMN is_out_of_city BOOLEAN DEFAULT FALSE,
  ADD COLUMN out_of_city_origin VARCHAR(255),     -- titik penjemputan
  ADD COLUMN out_of_city_distance_km DECIMAL(10,2),
  ADD COLUMN out_of_city_transport_fee DECIMAL(15,2);   -- distance × rate

-- System thresholds:
-- out_of_city_rate_per_km = 25000
-- out_of_city_rate_currency = 'IDR'
```

**Flow:**
```
SO input order luar kota:
  1. Centang "is_out_of_city"
  2. Input titik penjemputan (alamat) → Google Maps autocomplete
  3. Sistem hitung jarak (Google Maps Distance Matrix API) ke rumah duka / SM
  4. Auto-hitung: out_of_city_transport_fee = distance × 25000
  5. Fee masuk ke order_billing_items sebagai line item "Transport Luar Kota"
  6. Consumer lihat breakdown di invoice
```

### Multi Rumah Duka
```
✓ Q75: TIDAK ADA prosesi pindah rumah duka
  → Multi rumah duka dalam 1 order TIDAK DI-SUPPORT (untuk sekarang)
  → Kalaupun terjadi di lapangan, harus dibuat order terpisah
```

### ⏳ PENDING — Payment

| # | Item | Status |
|---|------|--------|
| Q69 | SOP keterlambatan bayar consumer | Belum dikonfirmasi |

---

## PART 10 — PROSESI, STOK, AKTA (JAWABAN Q76-Q83)

### Prosesi Harian
```
✓ Jadwal kegiatan di rumah duka: DI-TRACK DI APP
  → Setelah database rumah duka + TPU terbentuk, check-in/out karyawan
    akan otomatis tercatat di lokasi mana + kapan
  → Timeline aktivitas per hari di rumah duka tersusun otomatis
  
✓ Durasi prosesi per agama: PERLU DI-CONFIG (PENDING)
```

**Schema: `location_presence_logs` (tracking karyawan di lokasi):**
```sql
CREATE TABLE location_presence_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id),
  user_id UUID REFERENCES users(id),
  user_role VARCHAR(50),
  
  location_type ENUM('rumah_duka','tpu','gereja','rumah_keluarga','lainnya'),
  location_name VARCHAR(255),                -- nama rumah duka / TPU
  location_ref_id UUID,                      -- FK ke funeral_homes atau cemeteries
  
  action ENUM('check_in','check_out') NOT NULL,
  timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
  latitude DECIMAL(10,7),
  longitude DECIMAL(10,7),
  photo_evidence_id UUID REFERENCES photo_evidences(id),
  
  notes TEXT,
  created_at TIMESTAMP,
  
  INDEX (order_id, timestamp),
  INDEX (user_id, timestamp)
);
```

### Stok & Barang
```
✓ Stock opname: MINGGUAN
✓ Barang rusak: scan BARCODE per item → print barcode per item → nominal estimasi kerugian
  → Setiap stok item dapat unique barcode
  → Saat rusak: scan barcode → input kerusakan + estimasi kerugian
  → Auto-log ke stock_damage_logs
  
✓ Barang hilang di rumah duka: TUKANG JAGA TERAKHIR yang menerima bertanggung jawab
  → Tracking via tukang_jaga_item_deliveries (v1.29)
  → Jika hilang → claim ke tukang jaga shift terakhir sebelum hilang
  → Potong dari upah tukang jaga tersebut
  
✓ Minimum quantity: masing-masing role yang punya stok tentukan
  → Gudang tentukan minimum untuk stok gudang
  → Super Admin tentukan minimum untuk stok kantor
  → Lafiore tentukan minimum untuk stok dekor
```

**Schema: barcode per item:**
```sql
-- Update stock_items:
ALTER TABLE stock_items
  ADD COLUMN barcode VARCHAR(255) UNIQUE,           -- unique barcode
  ADD COLUMN barcode_image_path TEXT;               -- path ke barcode PNG di R2

-- Auto-generate barcode saat stock_items dibuat (Code128 atau EAN13)

-- Tabel stock_damage_logs:
CREATE TABLE stock_damage_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stock_item_id UUID REFERENCES stock_items(id),
  order_id UUID NULLABLE REFERENCES orders(id),    -- order terkait jika ada
  barcode_scanned VARCHAR(255),
  reported_by UUID REFERENCES users(id),
  reported_role VARCHAR(50),
  
  quantity_damaged DECIMAL(10,2) NOT NULL,
  damage_level ENUM('minor','moderate','severe','total_loss') NOT NULL,
  estimated_loss_amount DECIMAL(15,2) NOT NULL,
  
  damage_photo_evidence_id UUID REFERENCES photo_evidences(id),
  damage_description TEXT NOT NULL,
  
  responsible_party ENUM('sm_gudang','sm_driver','sm_dekor','tukang_jaga','keluarga','unknown'),
  responsible_user_id UUID REFERENCES users(id),  -- jika karyawan
  
  status ENUM('reported','investigated','resolved','written_off') DEFAULT 'reported',
  resolution_notes TEXT,
  resolved_by UUID REFERENCES users(id),
  resolved_at TIMESTAMP,
  
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- Tabel stock_lost_logs (mirip, untuk barang hilang):
CREATE TABLE stock_lost_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stock_item_id UUID REFERENCES stock_items(id),
  order_id UUID NULLABLE REFERENCES orders(id),
  
  quantity_lost DECIMAL(10,2) NOT NULL,
  estimated_loss_amount DECIMAL(15,2) NOT NULL,
  
  -- Auto-detect tukang jaga terakhir yang terima
  last_tukang_jaga_id UUID REFERENCES users(id),
  last_delivery_id UUID REFERENCES tukang_jaga_item_deliveries(id),
  
  -- Penalty
  penalty_amount DECIMAL(15,2),              -- nominal dipotong dari upah tukang jaga
  penalty_deducted BOOLEAN DEFAULT FALSE,
  penalty_deducted_at TIMESTAMP,
  
  reported_by UUID REFERENCES users(id),
  reported_at TIMESTAMP NOT NULL,
  status ENUM('reported','investigating','charged','written_off','recovered') DEFAULT 'reported',
  notes TEXT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

**Flutter screens:**
```
lib/features/shared/screens/
  ├── barcode_scanner_screen.dart              -- reusable barcode scanner (pakai mobile_scanner)
  └── damage_report_screen.dart                -- scan barcode → form kerusakan
        -- Input: barcode, quantity damaged, damage level, estimated loss,
        --        foto kerusakan (geofencing wajib), description
        -- Auto-create stock_damage_logs
```

### Akta
```
✓ Consumer bisa lihat real-time progress di app
✓ Jangka waktu maksimal: PENDING (tergantung Dukcapil)
```

### ⏳ PENDING — Prosesi/Stok/Akta

| # | Item | Status |
|---|------|--------|
| Q77 | Durasi prosesi per agama (config) | Belum dikonfirmasi |
| Q83 | Jangka waktu max akta (SOP internal) | Belum dikonfirmasi |

---

## PART 11 — DEVICE, LANDING PAGE, CONSUMER APP (JAWABAN Q84-Q93)

### Device & Teknis
```
✓ HP kantor: Android 12 MINIMUM
✓ Consumer HP: Android 12 MINIMUM
✓ Internet kantor down: tetap pakai app, ada kuota data (fallback ke mobile data)
✓ Backup database: SETIAP HARI (daily backup)
```

**App requirements:**
```yaml
# pubspec.yaml:
environment:
  sdk: ">=3.0.0 <4.0.0"

# android/app/build.gradle:
android:
  minSdkVersion 31    # Android 12 = API 31
  targetSdkVersion 34

# iOS: tidak di-support (SM tidak punya iPhone kantor)
```

**Backup strategy:**
```
- PostgreSQL: pg_dump harian ke Cloudflare R2 pukul 03:00 WIB
- Retention: 30 hari daily backup + 12 bulan monthly archive
- Hot backup ke standby server (jika budget cukup — PENDING)
- Test restore bulanan: backup diverifikasi dengan restore ke staging
```

### Landing Page & Blog
```
✓ Blog publish: BUTUH APPROVAL OWNER sebelum publish
✓ Obituary: OTOMATIS DIBUAT saat order dibuat
  → Begitu SO konfirmasi order → system auto-create obituary draft
  → Data auto-fill dari orders: nama almarhum, tanggal meninggal, foto, dll
  → Status: 'draft' sampai owner approve → 'published'
✓ Testimonial: SO INPUT MANUAL (setelah consumer beri feedback lisan)
```

**Update `obituaries` (v1.28):**
```sql
ALTER TABLE obituaries
  ADD COLUMN auto_generated_from_order BOOLEAN DEFAULT FALSE,
  ADD COLUMN requires_owner_approval BOOLEAN DEFAULT TRUE,
  ADD COLUMN approval_status ENUM('pending','approved','rejected') DEFAULT 'pending',
  ADD COLUMN approved_by UUID REFERENCES users(id),
  ADD COLUMN approved_at TIMESTAMP,
  ADD COLUMN rejection_reason TEXT;
```

**Trigger auto-create obituary:**
```php
// app/Listeners/CreateObituaryOnOrderConfirmed.php
class CreateObituaryOnOrderConfirmed {
  public function handle(OrderConfirmed $event) {
    $order = $event->order;
    Obituary::create([
      'order_id' => $order->id,
      'deceased_name' => $order->alm_nama_lengkap,
      'deceased_dob' => $order->alm_tanggal_lahir,
      'deceased_dod' => $order->alm_tanggal_meninggal,
      'deceased_religion' => $order->alm_agama,
      'funeral_location' => $order->rumah_duka,
      'funeral_datetime' => $order->scheduled_at,
      'family_contact_name' => $order->pj_nama,
      'family_contact_phone' => $order->pj_no_telp,
      'status' => 'draft',
      'auto_generated_from_order' => true,
      'requires_owner_approval' => true,
      'approval_status' => 'pending',
      'created_by' => auth()->id() ?? $order->so_user_id,
    ]);

    // Alarm Owner:
    NotificationService::send(
      ownerUserId(),
      'HIGH',
      'Berita Duka Baru Menunggu Approval',
      "Order {$order->order_number} — Almarhum {$order->alm_nama_lengkap}"
    );
  }
}
```

### Consumer App
```
✓ Fitur consumer app (tanpa input order):
  - Tracking order real-time
  - Tanda tangan Surat Penerimaan Layanan
  - Amendment approval
  - Konfirmasi barang diterima (chain)
  - Lihat invoice + upload bukti bayar
  - Akses dokumen & foto setelah lunas
  - Lihat status membership + riwayat iuran
  - Update profil (alamat/HP) sendiri
  - Lihat progress akta real-time
  
✓ Rating prompt ke Play Store/App Store: SETELAH LUNAS
✓ 1 account 1 device (tidak multi-device)
```

**Device binding implementation:**
```sql
ALTER TABLE users
  ADD COLUMN bound_device_id VARCHAR(255),        -- device_id yang terdaftar
  ADD COLUMN bound_device_model VARCHAR(255),
  ADD COLUMN bound_at TIMESTAMP;

-- Saat login: 
-- - Jika bound_device_id NULL → bind ke device sekarang
-- - Jika bound_device_id != device sekarang → TOLAK login
--   → Error: "Akun sudah terdaftar di device lain. Hubungi admin untuk reset."
-- - Admin bisa reset binding: PUT /admin/users/{id}/reset-device
```

### ⏳ PENDING — Device/Landing/Consumer

Tidak ada pending dari jawaban Anda.

---

## PART 12 — RINGKASAN PENDING ITEMS v1.39

Total item yang belum dikonfirmasi (akan ditanya kembali nanti):

### PAKET & PRICING
- [ ] Q2: Nominal iuran keanggotaan per bulan
- [ ] Q5: Profit margin Anggota vs Non-Anggota
- [ ] Q8: Detail isi paket Anggota vs Non-Anggota
- [ ] Q9: List add-on + harga

### SDM
- [ ] Q13: Detail shift 24 jam SO
- [ ] Q15: Target harian/bulanan SO
- [ ] Q18: Commission/bonus SO formula
- [ ] Q19: Jumlah staff gudang
- [ ] Q23: Consignment supplier
- [ ] Q26: Jumlah staff Lafiore
- [ ] Q29: Jumlah driver per lokasi
- [ ] Q38: Jumlah & database pemuka agama
- [ ] Q39: Nominal honor pemuka agama
- [ ] Q41: Database tukang foto (akan dibangun)
- [ ] Q42: Nominal upah tukang foto per order
- [ ] Q48: Makan & minum tukang jaga
- [ ] Q52: Jumlah musisi/grup
- [ ] Q54: Alat musik (sediakan/bawa)
- [ ] Q60: Gaji pokok per role
- [ ] Q62: Progression teguran
- [ ] Q63: Bonus formula
- [ ] Q64: Detail shift security

### OPS
- [ ] Q25: List barang kantor vs gudang
- [ ] Q56: Durasi akta rata-rata (dari internet)
- [ ] Q59: List instansi akta (dari internet)
- [ ] Q69: SOP keterlambatan bayar consumer
- [ ] Q77: Durasi prosesi per agama
- [ ] Q83: Jangka waktu max akta

---

## PART 13 — TABEL BARU/DIPERKAYA v1.39

### Tabel Baru
| Tabel | Fungsi |
|-------|--------|
| `membership_payments` | Pembayaran iuran bulanan anggota |
| `purchasing_availability` | Cuti/sakit Purchasing |
| `petty_cash_transactions` | Kas kecil kantor |
| `order_photo_deliveries` | Google Drive SM per order untuk foto |
| `coffin_size_master` | Master ukuran peti → rekomendasi jumlah angkat |
| `employee_leaves` | Cuti, sakit, izin karyawan |
| `employee_thr` | Pencatatan THR |
| `cctv_cameras` | Integrasi CCTV ke owner dashboard |
| `order_death_cert_progress` | Progress akta real-time |
| `death_cert_stage_logs` | Log per tahap akta + foto bukti |
| `location_presence_logs` | Check-in/out karyawan di lokasi (rumah duka/TPU) |
| `stock_damage_logs` | Log barang rusak dengan barcode |
| `stock_lost_logs` | Log barang hilang + accountability tukang jaga |

### Tabel Diperkaya
| Tabel | Perubahan |
|-------|-----------|
| `packages` | + price_anggota, price_non_anggota |
| `package_items` | + applicable_service_types |
| `consumer_memberships` | + monthly_fee, payment tracking, grace_period |
| `order_so_visits` | + followup_whatsapp_screenshot |
| `orders` | + is_out_of_city, out_of_city fields, coffin_size_id, lifters_count |
| `stock_items` | + barcode, barcode_image_path |
| `tukang_jaga_shifts` | + backup_tukang_jaga_id |
| `security_incident_logs` | + visitor_ktp_photo |
| `obituaries` | + auto_generated_from_order, approval workflow |
| `users` | + bound_device_id (1 account 1 device) |
| `roles` | Tidak ada perubahan (admin TETAP dihapus — Super Admin handle stok kantor) |

### Tabel Dihapus (dari v1.38)
| Tabel | Alasan |
|-------|--------|
| `service_offerings` | Tidak dipakai — paket TETAP hidup, service_type jadi kolom di orders |

---

## PART 14 — ATURAN BISNIS TAMBAHAN v1.39

```
1. PAKET TETAP dipakai sebagai penentu konten layanan.
   service_type (Anggota/Non-Anggota) menentukan harga paket tersebut.

2. Role `admin` TETAP DIHAPUS (sesuai v1.8). SUPER ADMIN (1 orang) yang
   merangkap kelola stok kantor + input data consumer walk-in + daftar
   anggota baru (selain God Mode sistem). Tidak ada role `admin` baru.

3. MEMBERSHIP = subscription bulanan. Status aktif selama bayar.
   Grace period 30 hari, inactive 60 hari, tidak bayar 2 bulan → non-anggota.
   Cancel boleh, iuran TIDAK dikembalikan.

4. GOOGLE DRIVE untuk foto dokumentasi dari WORKSPACE SM (bukan pribadi).
   Consumer akses via shareable link SETELAH lunas.

5. TRANSPORT LUAR KOTA: Rp 25.000/km fix dari titik penjemputan.
   Auto-calc via Google Maps Distance Matrix.

6. BARANG RUSAK: scan barcode → input kerusakan + estimasi kerugian.
   Setiap stock_item punya unique barcode.

7. BARANG HILANG DI RUMAH DUKA: tukang jaga terakhir yang menerima
   bertanggung jawab. Potongan dari upah tukang jaga tersebut.

8. PEMUKA AGAMA SELALU DIBAYAR — baik internal SM maupun vendor external
   yang dibawa consumer. Tidak pernah Rp 0.

9. OBITUARY OTOMATIS DIBUAT saat order confirmed, draft menunggu approval Owner.

10. 1 ACCOUNT = 1 DEVICE. Login di device lain → error + minta reset admin.

11. INTERNET DOWN: tetap pakai app via mobile data / kuota HP. Backup database harian.

12. CCTV TERINTEGRASI: Owner dashboard bisa lihat live feed dari semua CCTV
    kantor/gudang/Lafiore via IP camera streaming.
```

---

## CHANGELOG v1.39

### v1.39 — Konsolidasi 100 Jawaban Owner

**Koreksi Fundamental dari v1.38:**
- Paket DIPERTAHANKAN (bukan dihapus) — orthogonal dengan service_type
- Role `admin` TETAP DIHAPUS — Super Admin yang handle stok kantor (+ tanggung jawab operasional admin)
- Google Drive tukang foto dari workspace SM (bukan pribadi)
- `service_offerings` table DIHAPUS (tidak dipakai)

**Fitur Baru:**
- Membership subscription bulanan dengan grace period + inactive logic
- Transport luar kota dengan rate Rp 25.000/km fix
- Barcode scanning untuk stock_items
- Stock damage & lost tracking dengan accountability
- CCTV integration ke owner dashboard (IP cameras)
- Obituary auto-generate saat order confirmed + owner approval workflow
- Petty cash tracking di kantor
- Purchasing availability (cuti/sakit)
- Employee leaves & THR tracking
- 1 account 1 device binding
- Order death cert progress real-time untuk consumer
- Location presence logs (check-in/out di rumah duka/TPU)
- Coffin size master (rekomendasi jumlah tukang angkat)

**Tabel Baru:** 13 tabel
**Tabel Diperkaya:** 11 tabel
**Tabel Dihapus:** 1 (service_offerings)

**Pending Items:** 25 item (detail di PART 12)

---

# SANTA MARIA — PATCH v1.40
# Koreksi Operasional: Hapus Pemuka Agama Internal, Upah Tukang Foto per Hari, Stock Opname 6 Bulan, Flow Akta Lengkap, Barang Titipan Kacang, Layanan Custom

---

## KOREKSI FUNDAMENTAL DARI v1.39

### KOREKSI-1: HAPUS FITUR PEMUKA AGAMA INTERNAL

```
╔═══════════════════════════════════════════════════════════════════════╗
║  TIDAK ADA PEMUKA AGAMA INTERNAL SM                                   ║
║                                                                       ║
║  • Hapus role internal `pemuka_agama` dari pool SM                    ║
║  • Pihak keluarga menghubungi pemuka agama sendiri                    ║
║  • Pihak keluarga LANGSUNG BAYAR ke pemuka agama (BUKAN via SM)       ║
║  • SM TIDAK transfer honor ke pemuka agama (koreksi v1.39 Q39)        ║
║                                                                       ║
║  Peran SM hanya: fasilitasi jadwal + koordinasi lokasi                ║
╚═══════════════════════════════════════════════════════════════════════╝
```

**Schema update:**
```sql
-- Hapus role pemuka_agama dari pool internal
DELETE FROM roles WHERE slug = 'pemuka_agama';

-- User existing role='pemuka_agama' → soft deactivate atau ubah ke role lain
UPDATE users SET is_active = false WHERE role = 'pemuka_agama' AND is_active = true;

-- vendor_role_master.pemuka_agama TETAP ADA sebagai opsi EXTERNAL saja
-- (untuk konsumer yang input data pemuka agama mereka — kontak only, tanpa transaksi)
-- Tetapi: order_vendor_assignments.fee untuk pemuka_agama WAJIB = 0
--         karena SM tidak bayar, keluarga yang bayar langsung
```

**Koreksi aturan v1.39:**
- Hapus aturan "PEMUKA AGAMA SELALU DIBAYAR" (dari PART 14 v1.39 point 8)
- Pemuka agama di `order_vendor_assignments` → fee selalu 0, tracking info only

**Flutter update:**
```
lib/features/service_officer/screens/vendor_assign_form_screen.dart
  -- Saat pilih jenis vendor 'pemuka_agama':
  --   → Sumber WAJIB = 'external' (tidak ada opsi internal)
  --   → Fee field WAJIB = 0 (disabled, tidak bisa diisi)
  --   → Tampilkan notice: "Pemuka agama dibayar langsung oleh keluarga ke pemuka agama,
  --                        bukan via SM."
```

---

### KOREKSI-2: UPAH TUKANG FOTO PER HARI (BUKAN PER ORDER)

```
v1.34/v1.36: upah tukang foto per order
v1.40: upah tukang foto PER HARI, untuk banyak sesi/order di hari itu
```

**Schema update:**
```sql
-- Hapus asumsi fee per order untuk tukang_foto di order_vendor_assignments
-- Tukang foto bisa handle multiple order di 1 hari, upah dihitung per hari (bukan per order)

-- Tabel baru untuk track upah harian tukang foto:
CREATE TABLE photographer_daily_wages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  photographer_user_id UUID REFERENCES users(id),
  work_date DATE NOT NULL,
  session_count INTEGER NOT NULL DEFAULT 0,     -- jumlah sesi/order hari itu
  order_ids JSONB DEFAULT '[]',                 -- array order_id yang dihandle hari itu
  daily_rate DECIMAL(15,2) NOT NULL,            -- tarif per hari (dari master)
  bonus_per_extra_session DECIMAL(15,2) DEFAULT 0,  -- bonus jika > threshold sesi
  total_wage DECIMAL(15,2) NOT NULL,
  status ENUM('draft','finalized','paid') DEFAULT 'draft',
  finalized_at TIMESTAMP,
  paid_at TIMESTAMP,
  paid_by UUID REFERENCES users(id),
  payment_receipt_path TEXT,
  notes TEXT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  UNIQUE(photographer_user_id, work_date)
);
```

**Business logic:**
- Tukang foto check-in di hari H → `photographer_daily_wages` record dibuat
- Setiap kali handle order baru di hari itu → `session_count++`, `order_ids` append
- Di akhir hari (atau H+1) → Purchasing finalize + bayar
- Jika 1 order span multi-day → tiap hari masuk sebagai 1 session berbeda

---

### KOREKSI-3: STOCK OPNAME 6 BULANAN (BUKAN MINGGUAN)

```
v1.39 Q21: "Stock opname mingguan oleh role yang punya stok"
v1.40: STOCK OPNAME SETIAP 6 BULAN (semester)
```

**Scheduler update:**
```php
// Dari v1.39 daily/weekly → v1.40 per 6 bulan
$schedule->command('stock:opname-reminder')
  ->cron('0 8 1 1,7 *')   // Januari 1 & Juli 1, jam 08:00
  ->timezone('Asia/Jakarta');

// Reminder ke role yang punya stok:
// - Gudang
// - Super Admin (stok kantor)
// - Dekor/Lafiore
```

**Tabel baru `stock_opname_sessions`:**
```sql
CREATE TABLE stock_opname_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  period_year INTEGER NOT NULL,
  period_semester ENUM('H1','H2') NOT NULL,   -- H1 = Jan-Jun, H2 = Jul-Dec
  owner_role VARCHAR(50) NOT NULL,            -- 'gudang','super_admin','dekor'
  started_at TIMESTAMP,
  completed_at TIMESTAMP,
  performed_by UUID REFERENCES users(id),
  total_items_counted INTEGER DEFAULT 0,
  total_variance_count INTEGER DEFAULT 0,     -- jumlah item dengan selisih
  total_variance_amount DECIMAL(15,2) DEFAULT 0,  -- nilai total selisih (kerugian/kelebihan)
  status ENUM('open','in_progress','completed','reviewed') DEFAULT 'open',
  notes TEXT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  UNIQUE(period_year, period_semester, owner_role)
);

CREATE TABLE stock_opname_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES stock_opname_sessions(id) ON DELETE CASCADE,
  stock_item_id UUID REFERENCES stock_items(id),
  system_quantity DECIMAL(10,2) NOT NULL,     -- jumlah di sistem sebelum opname
  actual_quantity DECIMAL(10,2) NOT NULL,     -- jumlah fisik hasil hitung
  variance DECIMAL(10,2) NOT NULL,            -- actual - system (bisa negatif)
  variance_value DECIMAL(15,2),               -- nominal kerugian/kelebihan
  photo_evidence_id UUID REFERENCES photo_evidences(id),
  notes TEXT,
  reconciled_at TIMESTAMP,                    -- kapan adjustment dibuat
  adjustment_transaction_id UUID REFERENCES stock_transactions(id),
  created_at TIMESTAMP
);
```

---

### KOREKSI-4: BIAYA ADMINISTRASI AKTA INCLUDE DI PAKET

```
v1.39: "Biaya admin instansi ditanggung keluarga"
v1.40: BIAYA ADMINISTRASI AKTA SUDAH INCLUDE DI PAKET LAYANAN
```

**Update `order_death_cert_progress` (v1.39):**
```sql
-- Hapus konsep "admin_fees ditagihkan ke keluarga"
-- admin_fees tetap di-track untuk accounting internal SM
-- Tapi TIDAK ditambahkan ke order_billing_items

-- Dokumentasi internal saja:
ALTER TABLE order_death_cert_progress
  ALTER COLUMN total_admin_fees SET DEFAULT 0;
-- Admin fees = biaya internal SM, dicatat untuk financial_transactions (v1.30)
-- Bukan baris tagihan di invoice consumer
```

**Billing logic:**
- Saat akta progress selesai → admin_fees masuk ke `financial_transactions`
  dengan category = `operational`, direction = `out`
- TIDAK muncul di invoice consumer (sudah include di harga paket)
- Paket harga sudah budget untuk biaya admin ini

---

### KOREKSI-5: PROSESI PINDAH RUMAH DUKA = LAYANAN CUSTOM

```
v1.39 Q75: "Multi rumah duka tidak di-support"
v1.40: MEMUNGKINKAN sebagai LAYANAN CUSTOM
```

**Schema update:**
```sql
-- Tambah flag layanan custom di orders:
ALTER TABLE orders
  ADD COLUMN is_custom_service BOOLEAN DEFAULT FALSE,
  ADD COLUMN custom_service_notes TEXT,
  ADD COLUMN custom_service_extra_fee DECIMAL(15,2) DEFAULT 0;

-- Tabel untuk multi-location per order (jika is_custom_service = true):
CREATE TABLE order_location_phases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  phase_sequence SMALLINT NOT NULL,            -- 1, 2, 3, ...
  funeral_home_id UUID REFERENCES funeral_homes(id),
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  activities TEXT,                             -- kegiatan di phase ini
  notes TEXT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  UNIQUE(order_id, phase_sequence)
);
```

**Flow:**
- SO input order normal (1 rumah duka) → flag `is_custom_service = false`
- Keluarga minta pindah rumah duka di tengah prosesi → SO ubah flag ke `true`
- SO input phase baru di `order_location_phases`
- Barang & tim di-arrange ulang ke rumah duka baru
- Extra fee dikenakan (nominal manual, negotiable)

---

## PART 1 — OPERASIONAL SDM (KLARIFIKASI)

### Gudang
```
✓ GUDANG TIDAK ADA LIBUR (24/7 standby)
✓ Rotasi staff internal untuk weekend/libur nasional (sudah disinggung v1.39)
✓ Stock opname setiap 6 BULAN (koreksi dari v1.39 mingguan)
```

### Driver
```
✓ DRIVER TIDAK ADA LIBUR (re-confirm dari v1.32/v1.39)
✓ Sistem track jam kerja via daily_attendances
✓ Overtime/rest day tetap dipantau (driver_max_duty_hours = 12)
```

### Tukang Jaga
```
✓ Rekrut tukang jaga baru: HRD YANG WAWANCARA & TAMBAHKAN KE SISTEM
  (jawaban Q45 v1.39 diperjelas)
✓ Tukang jaga sakit/tidak bisa datang: WAJIB MENGABARI HRD
  → HRD cari backup tukang jaga dari pool
  → Catat di employee_leaves (v1.39) dengan leave_type = 'sakit'
✓ Makan & minum TIDAK disediakan SM (koreksi dari v1.39 PENDING Q48)
  → Tukang jaga bawa/beli sendiri
  → Biaya makan/minum SUDAH INCLUDE di upah shift mereka
```

**Schema update:**
```sql
-- tukang_jaga_shifts (v1.29) tetap, tambahkan:
ALTER TABLE tukang_jaga_shifts
  ADD COLUMN meals_included BOOLEAN DEFAULT FALSE;  -- SM tidak sediakan makan
-- Default FALSE untuk tukang_jaga (per v1.40)
-- Field ini ada agar di masa depan bisa flexible per order
```

**HRD workflow — tukang jaga sakit:**
```
API endpoint baru:
POST /tukang-jaga/report-sick
  Body: { shift_id, reason, medical_cert_photo (optional) }
  → Auto-create employee_leaves (leave_type='sakit')
  → Alarm HRD: "Tukang jaga [nama] sakit untuk shift [X]. Cari backup."
  → HRD cari tukang jaga lain yang available → assign via tukang_jaga_shifts.backup_tukang_jaga_id
```

### Musisi / Grup Musisi
```
✓ Bayaran PER ORANG PER SESI (bukan per grup per order)
  → 1 grup musisi 5 orang, 1 sesi misa = 5 × rate_per_orang
  → 2 sesi = 10 × rate_per_orang
✓ MC merangkap musisi (v1.36) — bayaran juga per orang per sesi
```

**Schema update:**
```sql
-- Tabel baru untuk konfigurasi upah musisi:
CREATE TABLE musician_wage_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role_label VARCHAR(100) NOT NULL,             -- 'musisi', 'mc', 'paduan_suara'
  rate_per_session_per_person DECIMAL(15,2) NOT NULL,
  effective_date DATE NOT NULL,
  end_date DATE,
  is_active BOOLEAN DEFAULT TRUE,
  notes TEXT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- Tabel sesi musisi per order:
CREATE TABLE order_musician_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  session_date DATE NOT NULL,
  session_type ENUM('misa','doa_malam','prosesi','pemberkatan','lainnya') NOT NULL,
  session_start_time TIME,
  session_end_time TIME,
  location VARCHAR(255),
  musician_count SMALLINT NOT NULL,
  rate_per_person DECIMAL(15,2) NOT NULL,
  total_wage DECIMAL(15,2) NOT NULL,           -- musician_count × rate_per_person
  musicians_user_ids JSONB DEFAULT '[]',       -- array user_id musisi yang hadir
  notes TEXT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

---

## PART 2 — ALUR AKTA KEMATIAN LENGKAP v1.40

### Proses & Durasi
```
✓ Durasi total: 1-2 MINGGU (jawaban Q56 v1.39)
✓ Jangka waktu MAKSIMAL pengurusan: 2 MINGGU (jawaban Q83 v1.39)
✓ Jika lewat 2 minggu → alarm HRD + Owner
```

### Flow Detail (KRONOLOGIS)
```
╔═══════════════════════════════════════════════════════════════════════╗
║  FLOW AKTA KEMATIAN SANTA MARIA                                       ║
╠═══════════════════════════════════════════════════════════════════════╣
║                                                                       ║
║  KASUS A — MENINGGAL DI RUMAH SAKIT:                                 ║
║  1. Keluarga dapat surat kematian dari RS                             ║
║  2. Keluarga serahkan surat ke SM (Petugas Akta)                      ║
║  3. SM bawa ke DUKCAPIL                                               ║
║  4. Dukcapil proses (durasi variable)                                 ║
║  5. Akta jadi → Dukcapil serahkan ke SM                               ║
║  6. SM simpan akta, tunggu consumer LUNAS                             ║
║  7. Consumer lunas → keluarga datang ke SM bawa KTP + KK              ║
║  8. SM serahkan akta ke keluarga                                      ║
║                                                                       ║
║  KASUS B — MENINGGAL DI RUMAH:                                        ║
║  1. Keluarga minta surat kematian dari RT/RW                          ║
║  2. Keluarga serahkan surat RT/RW ke SM                               ║
║  3. SM bawa ke DUKCAPIL                                               ║
║  4. Dukcapil proses                                                   ║
║  5. Akta jadi → Dukcapil serahkan ke SM                               ║
║  6. SM simpan akta, tunggu consumer LUNAS                             ║
║  7. Consumer lunas → keluarga datang ke SM bawa KTP + KK              ║
║  8. SM serahkan akta ke keluarga                                      ║
║                                                                       ║
║  WAJIB SAAT PENGAMBILAN AKTA:                                         ║
║  • KTP asli penanggung jawab (untuk verifikasi)                       ║
║  • KK asli keluarga (untuk verifikasi)                                ║
║  • Foto KTP + KK di-upload ke sistem sebagai bukti serah terima       ║
╚═══════════════════════════════════════════════════════════════════════╝
```

**Schema update `order_death_cert_progress` (v1.39):**
```sql
ALTER TABLE order_death_cert_progress
  -- Tempat meninggal: menentukan asal surat
  ADD COLUMN death_location_type ENUM('rumah_sakit','rumah','tempat_lain') NOT NULL DEFAULT 'rumah_sakit',
  ADD COLUMN death_certificate_source VARCHAR(255),  -- "RS Telogorejo" / "RT 05 RW 02 Pandanaran"

  -- Dokumen sumber (dari keluarga)
  ADD COLUMN source_document_received_at TIMESTAMP,  -- tanggal terima surat dari keluarga
  ADD COLUMN source_document_photo_evidence_id UUID REFERENCES photo_evidences(id),

  -- Dokumen saat serah terima akta ke keluarga
  ADD COLUMN family_ktp_photo_evidence_id UUID REFERENCES photo_evidences(id),
  ADD COLUMN family_kk_photo_evidence_id UUID REFERENCES photo_evidences(id),
  ADD COLUMN family_ktp_received BOOLEAN DEFAULT FALSE,
  ADD COLUMN family_kk_received BOOLEAN DEFAULT FALSE;
```

**Update ENUM `current_stage` (simplify untuk flow v1.40):**
```sql
-- Stages baru (hapus yang tidak relevan karena skip kelurahan/kecamatan):
-- current_stage ENUM:
--   'not_started'              - belum terima surat dari keluarga
--   'source_doc_received'      - surat RS/RT-RW sudah diterima SM
--   'submitted_to_dukcapil'    - SM sudah submit ke Dukcapil
--   'processing_dukcapil'      - Dukcapil proses
--   'cert_issued'              - akta jadi, SM sudah terima dari Dukcapil
--   'waiting_payment'          - tunggu consumer lunas
--   'waiting_ktp_kk_pickup'    - consumer lunas, tunggu keluarga bawa KTP+KK
--   'handed_to_family'         - selesai, akta diserahkan
```

**Scheduler untuk max 2 minggu:**
```php
// Setiap hari cek akta yang belum selesai > 14 hari
$schedule->command('death-cert:check-overdue')->dailyAt('09:00');

// Logic:
// SELECT * FROM order_death_cert_progress
// WHERE current_stage NOT IN ('handed_to_family')
//   AND started_at < NOW() - INTERVAL '14 days'
//
// → Alarm HRD + Owner: "Akta order [X] sudah {days} hari belum selesai"
// → Update hrd_violations: petugas_akta_overdue
```

**System thresholds:**
```
death_cert_max_processing_days = 14   -- 2 minggu max
death_cert_expected_processing_days = 7   -- 1 minggu ekspektasi
```

---

## PART 3 — DURASI PROSESI (JAWABAN Q77 v1.39)

```
✓ Upacara kematian: 1 - 1.5 JAM (sekali sesi)
✓ Durasi keseluruhan di rumah duka: 3, 5, atau 7 HARI
  → Sesuai permintaan pihak keluarga
  → Menjadi pilihan di PAKET:
    - Paket 3 hari (tarif A)
    - Paket 5 hari (tarif B)
    - Paket 7 hari (tarif C)
  → Harga paket sudah include durasi ini
```

**Schema update `packages`:**
```sql
ALTER TABLE packages
  ADD COLUMN service_duration_days SMALLINT NOT NULL DEFAULT 3;
  -- Nilai valid: 3, 5, 7 (dari owner)
  -- Bisa paket khusus dengan durasi custom (untuk layanan custom)
```

**Schema update `orders`:**
```sql
-- v1.13 sudah ada estimated_duration_hours, tapi itu untuk 1 sesi eksekusi
-- Tambahkan:
ALTER TABLE orders
  ADD COLUMN service_duration_days SMALLINT,  -- snapshot dari packages, 3/5/7
  ADD COLUMN ceremony_duration_minutes SMALLINT DEFAULT 90;  -- 60-90 menit
```

**Auto-generate tukang_jaga_shifts (v1.29):**
```
Saat SO konfirmasi order:
- Baca orders.service_duration_days
- Generate shifts: 2 shift/hari × N hari = total shifts
  Contoh paket 5 hari = 10 shift (pagi + malam × 5)
- Assign tukang jaga otomatis dari pool
```

---

## PART 4 — BARANG TITIPAN SUPPLIER (KACANG)

```
╔═══════════════════════════════════════════════════════════════════════╗
║  ONLY SUPPLIER KACANG YANG MENITIPKAN BARANG                          ║
║                                                                       ║
║  Flow:                                                                ║
║  1. Supplier kacang KIRIM kacang ke KANTOR SM                         ║
║  2. Stok kantor bertambah (owner_role = 'super_admin')                ║
║  3. Saat butuh untuk order → TRANSFER dari stok kantor ke stok gudang ║
║  4. Gudang yang distribusi ke order                                   ║
║                                                                       ║
║  TIDAK ADA barang titipan supplier lain selain kacang.                ║
║  Ini tipe "consignment" spesifik — stok tetap milik SM saat sudah     ║
║  dikirim supplier (bukan model konsinyasi "bayar setelah terjual").    ║
╚═══════════════════════════════════════════════════════════════════════╝
```

**Schema: inter-location transfer:**
```sql
CREATE TABLE stock_inter_location_transfers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_owner_role VARCHAR(50) NOT NULL,          -- 'super_admin' (kantor)
  to_owner_role VARCHAR(50) NOT NULL,            -- 'gudang'
  stock_item_id UUID REFERENCES stock_items(id),
  quantity DECIMAL(10,2) NOT NULL,

  requested_by UUID REFERENCES users(id),        -- role tujuan yang request
  approved_by UUID REFERENCES users(id),         -- role asal yang approve
  transferred_by UUID REFERENCES users(id),      -- yang fisik pindahkan
  received_by UUID REFERENCES users(id),         -- yang terima di tujuan

  requested_at TIMESTAMP NOT NULL,
  transferred_at TIMESTAMP,
  received_at TIMESTAMP,

  photo_evidence_id UUID REFERENCES photo_evidences(id),

  -- Supplier asal (untuk tracking barang titipan kacang)
  source_supplier_id UUID NULLABLE REFERENCES users(id),
  source_consignment_batch VARCHAR(100),         -- batch/PO number dari supplier

  status ENUM('requested','approved','in_transit','completed','cancelled') DEFAULT 'requested',
  notes TEXT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

**API:**
```
POST   /role-stock/transfer-request              -- Gudang request transfer dari kantor
  Body: { stock_item_id, quantity, notes }
  → Auto-set from='super_admin', to='gudang'
PUT    /admin/stock-transfers/{id}/approve        -- Super Admin approve
PUT    /role-stock/transfers/{id}/mark-transferred -- transporter mark
PUT    /gudang/stock-transfers/{id}/confirm-receive -- Gudang confirm terima
```

---

## PART 5 — SOP KETERLAMBATAN BAYAR CONSUMER (JAWABAN Q69)

```
✓ Deadline bayar: 3 hari setelah prosesi (v1.33)
✓ KETERLAMBATAN TOLERANSI: 7 HARI (total = 3 + 7 = 10 hari maksimal)
✓ Lewat 7 hari keterlambatan → eskalasi (SOP detail belum final)
```

**System thresholds:**
```
consumer_payment_grace_days_after_deadline = 7   -- toleransi keterlambatan
consumer_payment_total_max_days = 10              -- 3 deadline + 7 toleransi
```

**Scheduler:**
```php
// Setiap hari cek order completed yang belum lunas
$schedule->command('consumer-payment:check-overdue')->dailyAt('09:00');

// Logic:
// - Day H+0..H+3 (deadline): normal
// - Day H+4..H+10 (toleransi 7 hari): reminder WA ke consumer harian
//   → Pakai template ORDER_PAYMENT_REMINDER
//   → Escalate severity dengan hari (NORMAL → HIGH → ALARM)
// - Day H+11 (lewat toleransi): alarm Purchasing + Owner
//   → Petugas Akta STOP serah terima (sudah gated lunas, tidak berubah)
//   → Mungkin blacklist? (PENDING SOP final)
```

**Tabel untuk tracking reminder:**
```sql
CREATE TABLE consumer_payment_reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  reminder_day SMALLINT NOT NULL,        -- H+4, H+5, ... H+10
  reminder_date DATE NOT NULL,
  sent_via ENUM('whatsapp','sms','phone','app_notif') NOT NULL,
  sent_by UUID REFERENCES users(id),
  recipient_phone VARCHAR(30),
  template_used VARCHAR(50),
  message_content TEXT,
  consumer_responded BOOLEAN DEFAULT FALSE,
  response_notes TEXT,
  created_at TIMESTAMP,
  UNIQUE(order_id, reminder_day)
);
```

---

## PART 6 — FORM BIAYA KERUGIAN (BARANG RUSAK/HILANG)

```
╔═══════════════════════════════════════════════════════════════════════╗
║  OWNER AKAN BERIKAN FORM BIAYA KERUGIAN                               ║
║  ⏳ MOHON KONFIRMASI: Owner akan kirim template form                  ║
║                                                                       ║
║  Sementara spec v1.39 (stock_damage_logs, stock_lost_logs) TETAP      ║
║  berlaku. Saat form resmi diberikan owner, struktur akan disesuaikan  ║
║  agar input form = kolom di database.                                 ║
╚═══════════════════════════════════════════════════════════════════════╝
```

**Pending:** Form biaya kerugian dari owner → akan update schema `stock_damage_logs` & `stock_lost_logs` v1.39 untuk match form tersebut.

---

## TABEL BARU v1.40

| Tabel | Fungsi |
|-------|--------|
| `photographer_daily_wages` | Upah tukang foto per hari (banyak sesi/order) |
| `stock_opname_sessions` | Sesi stock opname 6-bulanan |
| `stock_opname_items` | Detail item per sesi opname |
| `order_location_phases` | Multi rumah duka untuk layanan custom |
| `musician_wage_config` | Tarif musisi per orang per sesi |
| `order_musician_sessions` | Sesi musisi per order |
| `stock_inter_location_transfers` | Transfer stok antar lokasi (termasuk barang titipan kacang) |
| `consumer_payment_reminders` | Log reminder pembayaran consumer (H+4..H+10) |

## TABEL DIPERKAYA v1.40

| Tabel | Perubahan |
|-------|-----------|
| `orders` | + is_custom_service, custom_service_notes, custom_service_extra_fee, service_duration_days, ceremony_duration_minutes |
| `packages` | + service_duration_days (3/5/7) |
| `tukang_jaga_shifts` | + meals_included (default false) |
| `order_death_cert_progress` | + death_location_type, death_certificate_source, source_document_*, family_ktp/kk_* |

## TABEL/FITUR DIHAPUS v1.40

| Item | Alasan |
|------|--------|
| Role `pemuka_agama` dari pool internal | Keluarga langsung bayar ke pemuka agama, bukan via SM |
| Aturan "SM bayar pemuka agama" (v1.39 PART 14 point 8) | Koreksi — SM tidak bayar, keluarga langsung bayar |

## ATURAN BISNIS v1.40

```
1. PEMUKA AGAMA: Tidak ada internal SM. Keluarga hubungi & bayar sendiri.
   SM hanya fasilitasi koordinasi jadwal.

2. TUKANG FOTO: Upah per hari, bukan per order. Bisa handle multi-order/hari.

3. STOCK OPNAME: Setiap 6 bulan (H1 & H2). Semua role dengan stok wajib opname.

4. BIAYA ADMIN AKTA: Include di harga paket. Keluarga tidak ditagih terpisah.

5. AKTA FLOW: RS/RT-RW → SM → Dukcapil → SM → Keluarga (setelah lunas + bawa KTP+KK)
   Max durasi: 2 minggu. Lewat → alarm HRD + Owner.

6. PINDAH RUMAH DUKA: MEMUNGKINKAN via layanan custom.
   Extra fee manual oleh SO, dicatat di orders.custom_service_extra_fee.

7. UPACARA: 1-1.5 jam per sesi.

8. DURASI RUMAH DUKA: 3/5/7 hari sesuai paket. Jumlah shift tukang jaga
   auto-generate (2 shift/hari × N hari).

9. BARANG TITIPAN KACANG: Supplier kirim ke kantor → transfer ke gudang saat butuh.
   Stok milik SM sejak sudah dikirim supplier (bukan konsinyasi finansial).

10. TUKANG JAGA: Makan/minum tidak disediakan SM, sudah include dalam upah.
    Rekrut baru via HRD. Sakit → lapor HRD → HRD cari backup.

11. MUSISI: Bayaran per orang per sesi (bukan per grup per order).

12. SOP KETERLAMBATAN BAYAR: Toleransi 7 hari setelah deadline 3 hari.
    Total max 10 hari. Reminder WA harian day H+4..H+10.

13. GUDANG & DRIVER: Tidak ada libur, 24/7 standby.
    Rotasi internal untuk weekend/libur nasional.
```

## PENDING ITEMS v1.40

### Baru Muncul di v1.40
| # | Item | Konfirmasi |
|---|------|-----------|
| v1.40-1 | Template form biaya kerugian barang rusak/hilang | Owner akan kirim |
| v1.40-2 | Tarif harian tukang foto (rate_per_day + bonus extra session) | Belum dikonfirmasi |
| v1.40-3 | Rate per orang per sesi untuk musisi & MC | Belum dikonfirmasi |
| v1.40-4 | Extra fee nominal untuk layanan custom (pindah rumah duka) | Belum dikonfirmasi |
| v1.40-5 | SOP escalation jika consumer tidak bayar > H+10 | Belum dikonfirmasi |

### Masih PENDING dari v1.39 (belum terjawab)
| # | Item | Status |
|---|------|--------|
| Q2 | Nominal iuran keanggotaan per bulan | Belum dikonfirmasi |
| Q5 | Profit margin Anggota vs Non-Anggota | Belum dikonfirmasi |
| Q8 | Detail isi paket Anggota vs Non-Anggota | Belum dikonfirmasi |
| Q9 | List add-on + harga | Belum dikonfirmasi |
| Q13 | Detail shift 24 jam SO | Belum dikonfirmasi |
| Q15 | Target harian/bulanan SO | Belum dikonfirmasi |
| Q18 | Commission/bonus SO formula | Belum dikonfirmasi |
| Q19 | Jumlah staff gudang | Belum dikonfirmasi |
| Q25 | List barang kantor vs gudang | Belum dikonfirmasi |
| Q26 | Jumlah staff Lafiore | Belum dikonfirmasi |
| Q29 | Jumlah driver per lokasi | Belum dikonfirmasi |
| Q41 | Database tukang foto (akan dibangun) | Belum dikonfirmasi |
| Q52 | Jumlah musisi/grup | Belum dikonfirmasi |
| Q54 | Alat musik (sediakan/bawa) | Belum dikonfirmasi |
| Q60 | Gaji pokok per role | Belum dikonfirmasi |
| Q62 | Progression teguran | Belum dikonfirmasi |
| Q63 | Bonus formula | Belum dikonfirmasi |
| Q64 | Detail shift security | Belum dikonfirmasi |

### Terjawab di v1.40
| Q# | Pertanyaan | Jawaban |
|----|-----------|---------|
| Q23 | Consignment supplier | Hanya supplier kacang, via transfer kantor→gudang |
| Q38 | Jumlah pemuka agama | Tidak ada internal, keluarga bawa sendiri |
| Q39 | Nominal honor pemuka agama | Keluarga bayar langsung, bukan via SM |
| Q42 | Upah tukang foto | Per hari (bukan per order) |
| Q48 | Makan minum tukang jaga | Tidak disediakan SM (sudah di upah) |
| Q56 | Durasi akta rata-rata | 1-2 minggu |
| Q59 | List instansi akta | RS/RT-RW → Dukcapil (skip kelurahan/kecamatan) |
| Q69 | SOP keterlambatan bayar | Toleransi 7 hari (total 10 hari max) |
| Q75 | Multi rumah duka | Memungkinkan via layanan custom |
| Q77 | Durasi prosesi | Upacara 1-1.5 jam, durasi rumah duka 3/5/7 hari |
| Q83 | Max durasi akta | 2 minggu |

## CHANGELOG v1.40

### v1.40 — Koreksi Operasional: Pemuka Agama External Only, Upah Tukang Foto Harian, Flow Akta Final

**Koreksi dari v1.39:**
- Hapus pemuka agama internal SM — keluarga bayar langsung ke pemuka agama
- Stock opname MINGGUAN → 6 BULANAN
- Upah tukang foto PER ORDER → PER HARI (banyak sesi)
- Biaya admin akta: keluarga tanggung → INCLUDE di paket
- Multi rumah duka: TIDAK SUPPORT → MEMUNGKINKAN via layanan custom

**Fitur Baru / Klarifikasi:**
- Flow akta lengkap: 2 jalur (RS vs Rumah) → Dukcapil → SM → Keluarga (bawa KTP+KK)
- Durasi prosesi: 1-1.5 jam upacara, 3/5/7 hari di rumah duka sesuai paket
- Barang titipan kacang: kantor → transfer ke gudang saat butuh
- Tukang jaga: HRD rekrut & handle sakit, makan include di upah
- Musisi: bayaran per orang per sesi
- SOP keterlambatan: toleransi 7 hari setelah deadline 3 hari

**Tabel Baru:** 8
**Tabel Diperkaya:** 4
**Tabel/Fitur Dihapus:** Role internal pemuka_agama

**Pending Terselesaikan:** 11 pertanyaan v1.39
**Pending Baru:** 5 item v1.40

---

*Dilarang mengurangi atau memodifikasi prompt ini tanpa persetujuan owner proyek*