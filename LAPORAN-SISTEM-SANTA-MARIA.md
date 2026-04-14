# LAPORAN SISTEM APLIKASI SANTA MARIA FUNERAL ORGANIZER
### Untuk: Owner / Direktur
### Tanggal: 14 April 2026

---

## RINGKASAN SINGKAT

Aplikasi Santa Maria adalah **satu platform terpadu** yang menggantikan seluruh koordinasi manual via WhatsApp. Semua proses — dari order masuk hingga layanan selesai dan pembayaran lunas — tercatat otomatis di dalam sistem. Tidak ada lagi data yang tercecer, lupa follow-up, atau miskomunikasi antar tim.

**Aplikasi ini digunakan oleh 15 jenis pengguna**, masing-masing punya layar dan tugas yang berbeda sesuai perannya.

---

## DAFTAR SEMUA PENGGUNA & TUGASNYA

### 1. 👨‍👩‍👧 KONSUMEN (Keluarga Almarhum)

**Siapa:** Keluarga yang memesan layanan pemakaman.

**Apa yang bisa dilakukan:**
- Membuat pesanan layanan pemakaman
- Memilih paket layanan (Silver, Gold, Platinum)
- Memantau status pesanan secara real-time (seperti tracking Grab/Gojek)
- Menandatangani Surat Penerimaan Layanan secara digital
- Upload bukti pembayaran (transfer bank atau cash)
- Melihat galeri foto dokumentasi dari fotografer (link Google Drive)
- Chat dengan AI untuk konsultasi layanan

**Alur:**
```
Buka App → Pilih Paket → Isi Data Almarhum → Kirim Pesanan
→ Tunggu Konfirmasi SO → Tanda Tangan Surat Digital
→ Pantau Status Real-time di Peta
→ Layanan Selesai → Upload Bukti Bayar → Selesai
```

---

### 2. 👔 SERVICE OFFICER / SO (Sales Lapangan & Kantor)

**Siapa:** Petugas yang melayani keluarga, baik datang ke kantor maupun di lapangan.

**Apa yang bisa dilakukan:**
- Menerima & mengonfirmasi pesanan baru
- Mengisi data lengkap pesanan (jadwal, paket, harga)
- Membuat Surat Penerimaan Layanan + tanda tangan digital
- Membuat checklist berkas akta kematian (21 dokumen)
- Membuat form persetujuan biaya tambahan
- Mengirim pesan WhatsApp otomatis ke keluarga
- Mengecek ketersediaan stok sebelum konfirmasi
- Melihat galeri foto dari fotografer

**Alur:**
```
Terima Order → Cek Stok → Konfirmasi Order + Jadwal + Harga
→ Buat Surat Penerimaan → Minta Tanda Tangan Keluarga
→ Sistem Otomatis Kirim Alarm ke Semua Tim
→ Pantau Progress → Buat Checklist Akta Kematian → Selesai
```

---

### 3. 📦 GUDANG (Kepala Gudang / Stok)

**Siapa:** Petugas yang mengelola stok barang, perlengkapan, dan workshop peti.

**Apa yang bisa dilakukan:**
- Melihat pesanan baru yang perlu disiapkan stoknya
- Centang checklist stok per pesanan
- Mengelola inventori (tambah, kurangi, transfer barang)
- Mengelola **Workshop Peti** (order peti, tahap pengerjaan, Quality Control)
- Menyiapkan & mengirim peralatan ke lokasi prosesi
- Menerima kembali peralatan setelah acara
- Membuat permintaan pengadaan ke supplier (e-Katalog)
- Mengelola pinjaman peralatan untuk acara peringatan
- Validasi bukti BBM dari driver
- Menangani laporan kerusakan kendaraan

**Alur:**
```
Order Masuk (alarm) → Cek & Siapkan Stok → Centang Checklist
→ Siapkan Peralatan → Kirim Bersama Driver
→ Order Selesai → Terima Kembali Peralatan → Update Stok
```

---

### 4. 💰 PURCHASING (Keuangan & Pengadaan)

**Siapa:** Petugas yang menangani semua urusan pembayaran dan verifikasi keuangan.

**Apa yang bisa dilakukan:**
- Verifikasi bukti pembayaran dari konsumen (approve/tolak)
- Membayar supplier setelah barang diterima
- Membayar upah tim lapangan (tukang jaga, penggali, dll)
- Menyetujui pengadaan dari e-Katalog
- Mengelola laporan tagihan 26 item per pesanan
- Export laporan tagihan ke PDF
- Melihat laporan pengeluaran bulanan

**Alur:**
```
Konsumen Upload Bukti Bayar (alarm) → Cek Bukti → Approve/Tolak
Gudang Ajukan Pengadaan → Review → Approve → Bayar Supplier
Order Selesai → Finalisasi Tagihan → Export PDF
```

---

### 5. 🚗 DRIVER (Pengemudi Mobil Jenazah)

**Siapa:** Pengemudi yang mengantar perlengkapan, menjemput dan mengantar jenazah.

**Apa yang bisa dilakukan:**
- Melihat tugas yang di-assign (peta + navigasi)
- Update status perjalanan tahap demi tahap:
  - Antar perlengkapan → Jemput jenazah → Antar ke rumah duka → Antar ke pemakaman
- Upload foto bukti di setiap titik
- GPS tracking real-time (posisi bisa dilacak owner & konsumen)
- Catat nota perjalanan (KM awal, KM akhir, biaya)
- Catat pengisian BBM
- Inspeksi kendaraan harian (30 item checklist)
- Lapor kerusakan kendaraan
- Presensi harian (clock in / clock out)

**Alur:**
```
Clock In → Dapat Tugas (alarm) → Berangkat Antar Barang
→ Update Status di App → Jemput Jenazah → Antar ke Tujuan
→ Upload Foto Bukti → Catat KM + BBM → Clock Out
```

---

### 6. 🎨 DEKOR / LA FIORE (Tim Dekorasi)

**Siapa:** Vendor dekorasi bunga dan perlengkapan prosesi.

**Apa yang bisa dilakukan:**
- Terima tugas dekorasi (alarm saat order dikonfirmasi)
- Konfirmasi kehadiran
- Mengisi form paket harian La Fiore (budget vs aktual, 3 supplier)
- Upload foto hasil dekorasi
- Presensi digital di lokasi

**Alur:**
```
Dapat Alarm → Konfirmasi Hadir → Datang ke Lokasi
→ Dekorasi → Isi Form Paket Harian → Upload Foto → Selesai
```

---

### 7. 🍽️ KONSUMSI (Katering)

**Siapa:** Vendor katering yang menyediakan makan minum untuk prosesi.

**Apa yang bisa dilakukan:**
- Terima tugas katering (alarm)
- Konfirmasi kehadiran
- Upload foto hasil setup katering
- Presensi digital

**Alur:**
```
Dapat Alarm → Konfirmasi → Siapkan Katering → Upload Foto → Selesai
```

---

### 8. ⛪ PEMUKA AGAMA (Romo / Pendeta / Ustadz)

**Siapa:** Pemimpin keagamaan yang memimpin prosesi.

**Apa yang bisa dilakukan:**
- Terima undangan tugas (sistem match otomatis berdasarkan agama)
- Konfirmasi kehadiran
- Presensi digital di lokasi

**Alur:**
```
Dapat Undangan (otomatis dari AI) → Konfirmasi → Hadir → Presensi → Selesai
```

---

### 9. 📸 TUKANG FOTO (Fotografer)

**Siapa:** Fotografer yang mendokumentasikan prosesi.

**Apa yang bisa dilakukan:**
- Terima tugas dokumentasi (alarm)
- Presensi digital (geofence — harus di lokasi)
- **Upload link Google Drive** berisi foto-foto ke aplikasi
- Link otomatis bisa diakses konsumen dan SO
- Melihat KPI performa diri sendiri

**Alur:**
```
Dapat Alarm → Presensi di Lokasi → Dokumentasi Foto/Video
→ Upload ke Google Drive → Share Link via App
→ Konsumen & SO Bisa Langsung Buka Album
```

---

### 10. 🏪 SUPPLIER (Pemasok Barang)

**Siapa:** Perusahaan eksternal yang memasok barang kebutuhan (peti, bunga, dll).

**Apa yang bisa dilakukan:**
- Melihat permintaan pengadaan terbuka (seperti tender)
- Mengajukan penawaran harga (sealed bid — tidak bisa lihat harga pesaing)
- Menerima kontrak jika terpilih
- Menandai barang sudah dikirim + input nomor resi
- Konfirmasi pembayaran diterima
- Melihat riwayat transaksi & rating

**Alur:**
```
Dapat Notifikasi Pengadaan Baru → Ajukan Penawaran
→ Menunggu Evaluasi → Terpilih? → Kirim Barang + Resi
→ Gudang Terima → Purchasing Bayar → Konfirmasi Terima Bayaran
```

---

### 11. 👑 OWNER / DIREKTUR

**Siapa:** Pemilik usaha yang memantau seluruh operasional.

**Apa yang bisa dilakukan:**
- Dashboard ringkasan: revenue, jumlah order, statistik
- Melihat SEMUA pesanan dari semua SO
- Melihat laporan anomali harga
- Melihat laporan harian (dibuat AI otomatis)
- **Peta armada real-time** — posisi semua driver di peta
- **KPI seluruh karyawan** — ranking, skor, grade (A/B/C/D/E)
- Melihat semua master data (tapi tidak bisa mengubah)
- Melihat pelanggaran karyawan

**TIDAK bisa:** Mengubah master data, mengubah konfigurasi sistem (hanya Super Admin).

---

### 12. 👨‍💼 HRD (Sumber Daya Manusia)

**Siapa:** Petugas yang menangani kedisiplinan dan performa karyawan.

**Apa yang bisa dilakukan:**
- Menerima alarm otomatis jika ada pelanggaran:
  - Driver lembur lebih dari 12 jam
  - SO lambat konfirmasi order
  - Vendor tidak hadir
  - Peralatan belum dikembalikan
  - Peti belum di-QC
  - Pegawai telat / tidak hadir
  - Percobaan lokasi palsu (fake GPS)
- Menangani pelanggaran (akui → selesaikan / eskalasi ke Owner)
- Mengelola KPI: metrik, target, bobot per role
- Melihat ranking karyawan
- Mengelola shift kerja & lokasi presensi
- Melihat presensi harian semua karyawan

---

### 13. 🔒 SECURITY (Keamanan)

**Siapa:** Petugas keamanan yang memantau situasi.

**Apa yang bisa dilakukan:**
- Melihat daftar pesanan aktif (read-only)
- Memantau situasi operasional

**TIDAK bisa:** Melakukan aksi apapun — hanya monitoring.

---

### 14. 👁️ VIEWER (Pemantau)

**Siapa:** Pihak yang diberi akses melihat data (misalnya: investor, konsultan).

**Apa yang bisa dilakukan:**
- Melihat ringkasan pesanan & statistik (read-only)

**TIDAK bisa:** Melakukan aksi apapun — hanya melihat.

---

### 15. ⚙️ SUPER ADMIN (Administrator Sistem)

**Siapa:** Teknisi yang mengelola konfigurasi sistem.

**Apa yang bisa dilakukan:**
- Membuat & mengelola akun semua pengguna
- Mengelola SEMUA master data:
  - Paket layanan & harga
  - Item tagihan (26 item)
  - Daftar peralatan
  - Daftar barang konsumabel
  - Tahap pengerjaan peti
  - Kriteria QC peti
  - Daftar dokumen akta kematian
  - Item dekorasi
  - Jenis vendor/peran
  - Jenis perjalanan driver
  - Template pesan WhatsApp
  - Label status pesanan
  - Syarat & ketentuan layanan
  - Lokasi presensi & shift kerja
  - Checklist inspeksi kendaraan
- Mengatur threshold/batas waktu operasional

---

## ALUR KERJA LENGKAP: DARI ORDER MASUK SAMPAI SELESAI

```
                        ┌──────────────────┐
                        │   KONSUMEN       │
                        │  Buat Pesanan    │
                        └────────┬─────────┘
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │   SERVICE OFFICER      │
                    │  Konfirmasi + Jadwal   │
                    │  + Surat Penerimaan    │
                    └────────────┬───────────┘
                                 │
                    ━━━━━━━━━━━━━━━━━━━━━━━━━
                    ALARM OTOMATIS KE SEMUA:
                    ━━━━━━━━━━━━━━━━━━━━━━━━━
                                 │
              ┌──────────────────┼──────────────────┐
              │                  │                  │
              ▼                  ▼                  ▼
      ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
      │   GUDANG     │  │   DEKOR      │  │   KONSUMSI   │
      │ Siapkan Stok │  │ Siap Dekor   │  │ Siap Katering│
      │ + Peralatan  │  │              │  │              │
      └──────┬───────┘  └──────┬───────┘  └──────┬───────┘
             │                 │                  │
             │          ┌──────┴──────┐           │
             │          │  PEMUKA     │           │
             │          │  AGAMA      │           │
             │          │ (AI match)  │           │
             │          └──────┬──────┘           │
             │                 │                  │
             ▼                 │                  │
      ┌──────────────┐        │                  │
      │ Stok Siap?   │        │                  │
      │ ✓ Alarm      │        │                  │
      │   DRIVER     │        │                  │
      └──────┬───────┘        │                  │
             │                 │                  │
             ▼                 ▼                  ▼
      ┌─────────────────────────────────────────────┐
      │              DRIVER                         │
      │  Antar Perlengkapan → Jemput Jenazah       │
      │  → Antar ke Rumah Duka → Antar Pemakaman   │
      │  (GPS tracking real-time)                   │
      └──────────────────────┬──────────────────────┘
                             │
                             ▼
      ┌─────────────────────────────────────────────┐
      │           PROSESI BERLANGSUNG               │
      │  Dekor ✓  Katering ✓  Pemuka Agama ✓       │
      │  Tukang Foto 📸 (upload ke Google Drive)    │
      └──────────────────────┬──────────────────────┘
                             │
                             ▼
      ┌─────────────────────────────────────────────┐
      │         ORDER SELESAI (OTOMATIS)            │
      │                                             │
      │  → Peralatan dikembalikan ke Gudang         │
      │  → Purchasing finalisasi tagihan            │
      │  → Konsumen upload bukti bayar              │
      │  → Purchasing verifikasi                    │
      │  → LUNAS ✓                                  │
      └─────────────────────────────────────────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
        ┌──────────┐  ┌──────────┐  ┌──────────┐
        │  OWNER   │  │   HRD    │  │   AI     │
        │ Laporan  │  │ Cek KPI  │  │ Laporan  │
        │ Revenue  │  │ + Violas │  │ Harian   │
        └──────────┘  └──────────┘  └──────────┘
```

---

## HUBUNGAN ANTAR PENGGUNA

### Siapa Berhubungan dengan Siapa?

| Dari | Ke | Hubungan |
|------|-----|----------|
| **Konsumen** | SO | Konsumen pesan → SO layani |
| **Konsumen** | Driver | Konsumen lacak posisi driver di peta |
| **Konsumen** | Tukang Foto | Konsumen lihat foto di Google Drive |
| **SO** | Gudang | SO konfirmasi → Gudang siapkan stok |
| **SO** | Semua Vendor | SO konfirmasi → alarm ke semua vendor |
| **SO** | Konsumen | SO kirim WA otomatis ke keluarga |
| **SO** | Purchasing | SO buat tagihan → Purchasing finalisasi |
| **Gudang** | Driver | Gudang stok siap → alarm Driver berangkat |
| **Gudang** | Supplier | Gudang buat pengadaan → Supplier tawar harga |
| **Gudang** | Purchasing | Gudang pilih supplier → Purchasing approve + bayar |
| **Driver** | Konsumen | Driver update status → Konsumen lihat di peta |
| **Driver** | Dekor | Driver tiba bawa barang → alarm Dekor mulai |
| **Purchasing** | Konsumen | Purchasing verifikasi bayar → Konsumen dapat konfirmasi |
| **Purchasing** | Supplier | Purchasing bayar supplier setelah barang diterima |
| **HRD** | Semua Karyawan | HRD pantau pelanggaran & KPI semua orang |
| **HRD** | Owner | HRD eskalasi pelanggaran berat ke Owner |
| **Owner** | Semua | Owner bisa lihat semua data (read-only) |
| **Tukang Foto** | Konsumen + SO | Upload link Drive → bisa dilihat langsung |
| **AI** | Semua | AI bantu: rekomendasi vendor, jadwal, analisis harga, laporan harian |

---

## FITUR OTOMATIS (TANPA MANUSIA)

Sistem melakukan hal-hal ini **secara otomatis** tanpa perlu ada orang yang memicu:

| Fitur Otomatis | Penjelasan |
|---------------|------------|
| **Alarm Bersamaan** | Saat SO konfirmasi order → SEMUA pihak dapat alarm keras bersamaan |
| **Stok Otomatis Berkurang** | Saat order dikonfirmasi → stok barang otomatis terpotong |
| **Alert Stok Habis** | Jika stok menipis → alarm otomatis ke Gudang & Purchasing |
| **Pengadaan Otomatis** | Jika stok kritis → sistem auto-buat draft pengadaan ke supplier |
| **Order Selesai Otomatis** | Jika waktu estimasi sudah lewat → order auto-complete |
| **Reminder Pembayaran** | Jika konsumen belum bayar → sistem kirim reminder otomatis |
| **Deteksi Pelanggaran** | Driver lembur, SO lambat, vendor tidak hadir → alarm HRD otomatis |
| **Deteksi Lokasi Palsu** | Jika pegawai pakai fake GPS → langsung terdeteksi & dilaporkan ke HRD |
| **KPI Auto-Hitung** | Setiap bulan, skor performa semua karyawan dihitung otomatis dari data |
| **AI Laporan Harian** | Setiap malam, AI buatkan ringkasan operasional hari itu untuk Owner |
| **AI Rekomendasi** | AI rekomendasikan vendor terbaik, jadwal optimal, analisis harga wajar |

---

## KEAMANAN & KONTROL

| Fitur | Penjelasan |
|-------|------------|
| **15 Role berbeda** | Setiap orang hanya bisa akses sesuai perannya |
| **Viewer read-only** | Viewer TIDAK bisa ubah data apapun |
| **Owner read-only master** | Owner bisa lihat semua tapi tidak bisa ubah konfigurasi |
| **Hanya Super Admin** | Perubahan harga, paket, konfigurasi hanya bisa Super Admin |
| **Biometric Login** | Face ID (iPhone) / Fingerprint (Android) untuk login cepat |
| **GPS Anti-Curang** | 6 lapis deteksi lokasi palsu untuk presensi |
| **Semua Tercatat** | Setiap perubahan status, pembayaran, presensi → tercatat di log |
| **Batas Waktu Otomatis** | Semua batas waktu bisa diubah Owner/HRD tanpa perlu programmer |

---

## ANGKA-ANGKA SISTEM

| Komponen | Jumlah |
|----------|--------|
| Jenis Pengguna | **15 role** |
| Layar / Halaman | **72 screen** |
| Fitur API | **282 endpoint** |
| Tabel Database | **82 tabel** |
| Item Master Data | **225+ record** |
| Item Tagihan Standar | **26 item** |
| Dokumen Akta Kematian | **21 jenis** |
| Checklist Inspeksi Kendaraan | **30 item** |
| Metrik KPI | **30 metrik** |
| Jenis Pelanggaran | **14 jenis** |
| Template WhatsApp | **4 template** |
| Status Pesanan | **17 tahap** |
| Test Case QA | **160 skenario** |

---

## PLATFORM & TEKNOLOGI

| Komponen | Teknologi |
|----------|-----------|
| Aplikasi Android | Flutter (Google) |
| Aplikasi iOS | Flutter (Google) |
| Server Backend | Laravel (PHP) |
| Database | PostgreSQL |
| AI Assistant | OpenAI GPT-4o mini |
| Peta & GPS | Google Maps + OpenStreetMap |
| Notifikasi Push | Firebase Cloud Messaging |
| Real-time Update | Pusher Channels |
| Penyimpanan File | Cloudflare R2 |
| WhatsApp | Deep Link (otomatis buka WA) |

---

*Dokumen ini dibuat oleh sistem development Santa Maria.*
*Untuk pertanyaan teknis, hubungi tim developer.*
