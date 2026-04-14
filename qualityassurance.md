# SANTA MARIA FUNERAL ORGANIZER — QUALITY ASSURANCE
# Test Plan: Full User Journey per Role (Start → End)
# Tanggal: 2026-04-14

---

## PETUNJUK PENGGUNAAN

- Setiap test case memiliki checkbox `[ ]` — tandai `[x]` jika PASS, `[!]` jika FAIL
- Jika FAIL, catat bug di kolom "Catatan" di bawah step tersebut
- Test dilakukan di device Android & iOS (jika tersedia)
- Gunakan akun test dari DatabaseSeeder (lihat bagian Kredensial)

---

## KREDENSIAL TEST

| Role | Email | Password/PIN | Channel |
|------|-------|-------------|---------|
| Super Admin | superadmin@santamaria.id | superadmin123 | Internal |
| Owner | owner@santamaria.id | owner123 | Internal |
| Service Officer (Lapangan) | so@santamaria.id | so123456 | Internal |
| Service Officer (Kantor) | sokantor@santamaria.id | sokantor123 | Internal |
| Gudang | gudang@santamaria.id | gudang123 | Internal |
| Finance | finance@santamaria.id | finance123 | Internal |
| Purchasing | purchasing@santamaria.id | purchasing123 | Internal |
| Driver | driver@santamaria.id | driver123 | Internal |
| HRD | hrd@santamaria.id | hrd123456 | Internal |
| Dekor | dekor@santamaria.id | dekor123 | Internal |
| Konsumsi | konsumsi@santamaria.id | konsumsi123 | Internal |
| Pemuka Agama | pemuka@santamaria.id | pemuka123 | Internal |
| Tukang Foto | foto@santamaria.id | foto1234 | Internal |
| Supplier 1 | supplier@santamaria.id | supplier123 | Internal |
| Supplier 2 | supplier2@santamaria.id | supplier123 | Internal |
| Koordinator Angkat Peti | angkatpeti@santamaria.id | angkatpeti123 | Internal |
| Viewer | viewer@santamaria.id | viewer123 | Internal |
| Consumer | HP: 08199999999 | PIN: 1234 | Consumer |

---

## 1. CONSUMER — Perjalanan Konsumen

### 1.1 Login & Onboarding
- [ ] Buka app → splash screen tampil logo Santa Maria (2 detik)
- [ ] Config API terload (cek: status label tidak hardcode)
- [ ] Pilih "Masuk sebagai Konsumen"
- [ ] Input nomor HP + PIN → login berhasil
- [ ] Dashboard consumer tampil dengan benar
- [ ] Tombol back TIDAK muncul di dashboard (root screen)

### 1.2 Buat Order Baru
- [ ] Tap "Buat Order" → form order tampil
- [ ] Isi semua field wajib (nama almarhum, tanggal wafat, agama, alamat)
- [ ] Pilih paket → cek harga tampil jelas
- [ ] **Stock-aware**: paket dengan stok kritis tampil warning/disabled
- [ ] Submit order → order berhasil dibuat
- [ ] Redirect ke tracking screen

### 1.3 Tracking Order
- [ ] Status banner tampil dengan label dari ConfigService (bukan hardcode)
- [ ] **Order Timeline** tampil dengan DB-driven labels + warna + icon
- [ ] Saat status "confirmed" + belum tanda tangan → banner orange "Tanda Tangani Surat Penerimaan"
- [ ] Tap banner → ConsumerAcceptanceScreen tampil
- [ ] Baca S&K → isi nama PJ + hubungan → centang → Tanda Tangan
- [ ] Kembali ke tracking → banner hilang

### 1.4 Pembayaran
- [ ] Saat order "completed" + belum bayar → tombol "Lakukan Pembayaran" tampil
- [ ] Tap → ConsumerPaymentScreen
- [ ] Toggle CASH vs TRANSFER tampil
- [ ] Pilih TRANSFER → upload foto bukti (max 5MB, kompresi otomatis)
- [ ] Submit → status "proof_uploaded"
- [ ] Kembali ke tracking → tombol payment hilang

### 1.5 Gallery Foto
- [ ] Lihat galeri foto dari tukang foto
- [ ] **Link Google Drive** tampil sebagai card dengan icon Drive
- [ ] Tap link → buka Google Drive di browser/app external
- [ ] Foto-foto order tampil di galeri

### 1.6 Navigasi & UX
- [ ] Tombol back muncul di SEMUA sub-screen (auto-detect via canPop)
- [ ] Warna tema konsisten biru muda (roleConsumer)
- [ ] Pull-to-refresh berfungsi di tracking screen
- [ ] Logout → kembali ke login screen
- Catatan: _______________________________________________

---

## 2. SERVICE OFFICER — Perjalanan SO

### 2.1 Login
- [ ] Login dengan email + password
- [ ] Dashboard SO tampil (order list)
- [ ] Warna tema: navy logo (roleSO)

### 2.2 Order Management
- [ ] List order pending tampil
- [ ] Tap order → detail lengkap (info keluarga, almarhum, paket)
- [ ] Pilih paket → **harga paket tampil jelas**
- [ ] **Stock Check Preview**: tap sebelum konfirmasi → lihat ketersediaan stok
- [ ] Konfirmasi order (scheduled_at + estimated_duration + final_price)
- [ ] Sistem broadcast alarm ke semua pihak

### 2.3 Walk-in Order
- [ ] Buat order walk-in (consumer belum punya akun)
- [ ] Isi semua data langsung di form
- [ ] Order berhasil tanpa consumer login

### 2.4 Surat Penerimaan Layanan
- [ ] Pada order detail confirmed → section "Dokumen & Formulir" tampil
- [ ] Tap "Berkas Akta Kematian" → checklist 21 dokumen tampil
- [ ] Toggle diterima SM / dikembalikan keluarga
- [ ] Tap "Persetujuan Tambahan" → form extra approval
- [ ] Isi item + biaya → simpan → tanda tangan digital
- [ ] **WA Keluarga** chip → buka WhatsApp dengan pesan template

### 2.5 Acceptance Letter
- [ ] Buat Surat Penerimaan Layanan dari order detail
- [ ] 6 section form terisi otomatis dari data order
- [ ] Update data PJ jika perlu
- [ ] Tanda tangan PJ (keluarga) → signature captured
- [ ] Tanda tangan SM (SO) → signature captured
- [ ] Tanda tangan Saksi (opsional)
- [ ] Download PDF → format A4 dengan 3 kolom tanda tangan
- [ ] Kirim via WhatsApp → deep link terbuka
- Catatan: _______________________________________________

---

## 3. GUDANG — Perjalanan Gudang

### 3.1 Login & Dashboard
- [ ] Login → dashboard Gudang tampil (3 tab: Order Aktif, Inventori, Pengadaan)
- [ ] Quick-access chips tampil: Workshop Peti, Alert Stok, Pinjaman Peralatan, Ambil/Kembali Barang, Maintenance Kendaraan
- [ ] Badge merah jumlah order confirmed

### 3.2 Stock Management
- [ ] Tab Inventori → list stok item
- [ ] Tambah item baru
- [ ] Edit quantity item
- [ ] **Stock Alert** → tap chip → list alert (low_stock, out_of_stock)
- [ ] Resolve alert

### 3.3 Order Stock Checklist
- [ ] Tab Order Aktif → list order confirmed
- [ ] Tap order → checklist stok tampil
- [ ] Toggle per item → progress bar update
- [ ] "Stok Kurang" badge tampil jika needs_restock
- [ ] **Peralatan** button → EquipmentChecklistScreen
- [ ] **Konsumabel** button → ConsumableDailyScreen

### 3.4 Workshop Peti
- [ ] Tap "Workshop Peti" → list order peti
- [ ] Buat order peti baru (kode, finishing type melamin/duco)
- [ ] Stages auto-generate dari master (10 melamin / 11 duco)
- [ ] Centang tahap per tahap (nama tukang)
- [ ] Tab QC → input QC per kriteria (6 item)
- [ ] QC passed / QC failed → status update

### 3.5 Equipment & Loans
- [ ] Prepare equipment untuk order (pilih dari master)
- [ ] Kirim peralatan (mark sent)
- [ ] Terima kembali (mark returned, partial, atau missing)
- [ ] **Pinjaman Peralatan** → form pinjaman peringatan
- [ ] **Ambil/Kembali Barang** → StockFormScreen (pengambilan/pengembalian)

### 3.6 Konsumabel Harian
- [ ] Input data barang per shift (Pagi/Kirim/Malam)
- [ ] Pilih item dari master → input qty
- [ ] Simpan → data tersimpan per tanggal + shift

### 3.7 Maintenance Kendaraan
- [ ] Tap "Maintenance Kendaraan" → 2 tab (Maintenance + Validasi BBM)
- [ ] Tab Maintenance: list laporan kerusakan → Terima & Proses → Selesaikan
- [ ] Tab BBM: list fuel log pending → Validasi / Tolak
- Catatan: _______________________________________________

---

## 4. PURCHASING / FINANCE — Perjalanan Purchasing

### 4.1 Login & Dashboard
- [ ] Login (finance@... atau purchasing@...) → dashboard Purchasing
- [ ] Stat cards: Payment Menunggu, Pengadaan Menunggu, Tim Lapangan Menunggu
- [ ] Menu grid navigable

### 4.2 Verifikasi Payment
- [ ] Tap "Verifikasi Payment" → list proof_uploaded
- [ ] Lihat bukti foto transfer
- [ ] Verifikasi → status "verified"
- [ ] Tolak (dengan alasan) → status "proof_rejected"

### 4.3 Laporan Tagihan
- [ ] Buka billing order → 26 item tagihan tampil
- [ ] Grand total: Total + Tambahan - Kembali
- [ ] Export PDF → download file A4

### 4.4 Pengadaan (e-Katalog)
- [ ] Approval pengadaan → review detail + harga AI
- [ ] Approve / Reject dengan alasan
- [ ] Bayar supplier setelah barang diterima

### 4.5 Kelola Upah Layanan
- [ ] Tap "Kelola Upah Layanan" di menu grid → WageManagementScreen
- [ ] **Tab Tarif**: list tarif aktif per role (Tukang Foto / Koordinator Angkat Peti)
- [ ] Tambah tarif baru (role, paket, nominal) → tersimpan
- [ ] Edit tarif → nominal berubah
- [ ] Nonaktifkan tarif → hilang dari list
- [ ] **Tab Klaim**: list klaim masuk (sorted: pending → approved → paid)
- [ ] Klaim pending: tombol Setujui + Tolak tampil
- [ ] Setujui → isi jumlah disetujui → status approved
- [ ] Tolak → isi alasan → status rejected
- [ ] Klaim approved: tombol "Bayar Sekarang" tampil
- [ ] Bayar → pilih cash/transfer → foto bukti (wajib) → tersimpan
- [ ] **Tab Ringkasan**: akumulasi per pekerja (pending/approved/paid count + total belum dibayar)
- [ ] Dialog popup menggunakan Glass theme (bukan AlertDialog default)
- Catatan: _______________________________________________

---

## 5. DRIVER — Perjalanan Driver

### 5.1 Login & Dashboard
- [ ] Login → peta OpenStreetMap tampil
- [ ] FAB column: Fingerprint (Clock-in) + Receipt (Trip Log)
- [ ] On Duty toggle berfungsi
- [ ] GPS tracking aktif saat On Duty

### 5.2 Order Assignment
- [ ] Dapat alarm order baru
- [ ] Lihat detail order + paket + lokasi
- [ ] **State machine**: `next_statuses` tampil → pilih transisi yang valid
- [ ] Transisi: delivering_equipment → equipment_arrived → picking_up_body → body_arrived → ...
- [ ] Tidak bisa skip status (422 error)

### 5.3 Bukti Lapangan
- [ ] Upload foto bukti (penjemputan, tiba tujuan)
- [ ] Foto tersimpan dan visible di order detail

### 5.4 Trip Log
- [ ] Tap FAB Receipt → nota perjalanan
- [ ] Buat nota baru (atas nama, alamat, tujuan)
- [ ] Input KM berangkat + KM tiba → KM total auto-calculate

### 5.5 Vehicle Management
- [ ] Log KM (start/end) dengan foto speedometer
- [ ] Isi BBM (liter, harga, SPBU)
- [ ] Lapor kerusakan (kategori, prioritas, deskripsi)

### 5.6 Attendance
- [ ] Tap FAB Fingerprint → ClockInScreen
- [ ] Clock-in dengan GPS (geofence validation)
- [ ] Clock-out → durasi kerja tampil
- [ ] Riwayat presensi bulanan
- Catatan: _______________________________________________

---

## 6. HRD — Perjalanan HRD

### 6.1 Login & Dashboard
- [ ] Login → stat cards (total pelanggaran, pending, kritis)
- [ ] Menu: Pelanggaran, Threshold, Presensi Karyawan, KPI, Shift & Lokasi

### 6.2 Pelanggaran
- [ ] List pelanggaran + filter (pending/acknowledged/resolved/escalated)
- [ ] Detail pelanggaran → Akui → Selesaikan / Eskalasi
- [ ] Input catatan penyelesaian

### 6.3 Threshold
- [ ] List threshold settings → tap → edit nilai
- [ ] Perubahan tersimpan

### 6.4 Presensi Karyawan
- [ ] "Presensi Karyawan" → HrdAttendanceDashboardScreen
- [ ] Summary: Hadir / Telat / Belum
- [ ] Per-employee list dengan DynamicStatusBadge

### 6.5 KPI
- [ ] "KPI Karyawan" → KpiManagementScreen (3 tab)
- [ ] Tab Metrik: per role, target + bobot
- [ ] Tab Ranking: dropdown periode → ranking per role dengan grade badge
- [ ] Tab Periode: list periode (open/closed)

### 6.6 Shift & Lokasi
- [ ] "Shift & Lokasi" → 2 tab
- [ ] Tab Shift: list shift (nama, jam, toleransi)
- [ ] Tab Lokasi: list lokasi presensi (nama, alamat, radius)
- Catatan: _______________________________________________

---

## 7. OWNER — Perjalanan Owner

### 7.1 Login & Dashboard
- [ ] Login → 6 tab: Dashboard, Order, Anomali, Laporan, KPI, Armada

### 7.2 Dashboard
- [ ] Revenue card, order stats, ring chart
- [ ] Daily report dari AI

### 7.3 KPI Tab
- [ ] Embedded KpiManagementScreen berfungsi

### 7.4 Armada Tab
- [ ] **OwnerFleetMapScreen** → peta dengan posisi driver real-time
- [ ] Auto-refresh 15 detik
- [ ] Stat overlay: order aktif + driver terlacak

### 7.5 Master Data (Read-Only)
- [ ] Bisa GET semua master data via admin/master
- [ ] **TIDAK bisa** POST/PUT/DELETE (403 OwnerReadOnly)
- Catatan: _______________________________________________

---

## 8. SUPPLIER — Perjalanan Supplier

### 8.1 Login & Dashboard
- [ ] Login → stats (penawaran aktif, rating)
- [ ] Icon buttons: Katalog, Transaksi, Profil

### 8.2 e-Katalog
- [ ] List permintaan pengadaan "open"
- [ ] Detail: spesifikasi, jumlah, deadline, max_price
- [ ] Ajukan penawaran (harga, merek, estimasi kirim)
- [ ] Validasi: harga > max_price ditolak
- [ ] Status penawaran: submitted → evaluating → awarded/rejected

### 8.3 Transaksi
- [ ] Tap icon Receipt → SupplierTransactionScreen
- [ ] List transaksi dengan status badge
- [ ] Tandai sudah dikirim (nomor resi)
- [ ] Konfirmasi terima pembayaran

### 8.4 Profil
- [ ] Lihat profil, rating, statistik
- Catatan: _______________________________________________

---

## 9. DEKOR — Perjalanan Dekor

### 9.1 Login & Assignment
- [ ] Login → list assignment order
- [ ] Konfirmasi kehadiran
- [ ] Upload bukti foto dekorasi

### 9.2 Paket Harian La Fiore
- [ ] DekorDailyPackageScreen → list paket harian per order
- [ ] Buat paket baru → 19 item default
- [ ] Input anggaran vs biaya aktual per supplier (max 3)
- [ ] Selisih auto-calculate
- Catatan: _______________________________________________

---

## 10. TUKANG FOTO — Perjalanan Tukang Foto

### 10.1 Login & Dashboard
- [ ] Login → TukangFotoDashboardScreen
- [ ] List tugas + stat cards

### 10.2 Presensi
- [ ] Tap "Presensi" → VendorAttendanceScreen
- [ ] Check-in (geofence 500m) → Check-out
- [ ] Late detection berfungsi

### 10.3 Klaim Upah
- [ ] Menu "Klaim Upah Layanan" tampil di dashboard
- [ ] Tap → MyWageClaimsScreen
- [ ] Ringkasan upah: Menunggu / Disetujui / Dibayar
- [ ] Riwayat klaim per order tampil
- [ ] Konfirmasi terima uang berfungsi

### 10.4 **Gallery Link (Google Drive)**
- [ ] Tap "Galeri" → GalleryLinkScreen (canAdd: true)
- [ ] Tap FAB "Tambah Link" → bottom sheet form
- [ ] Isi judul + URL Google Drive + deskripsi
- [ ] Simpan → link tampil di list
- [ ] Tap link → buka Google Drive di browser
- [ ] **Consumer** bisa lihat link ini di tracking screen
- [ ] **SO** bisa lihat link ini di order detail
- [ ] Delete link berfungsi (hanya pemilik)
- Catatan: _______________________________________________

---

## 11. PEMUKA AGAMA / KONSUMSI — Perjalanan Vendor

### 11.1 Login & Assignment
- [ ] Login → VendorAssignmentScreen
- [ ] List order yang di-assign
- [ ] Konfirmasi / Tolak assignment
- [ ] Upload bukti foto
- Catatan: _______________________________________________

---

## 12. KOORDINATOR ANGKAT PETI — Perjalanan Tukang Angkat Peti

### 12.1 Login & Dashboard
- [ ] Login dengan angkatpeti@santamaria.id → TukangAngkatPetiDashboardScreen
- [ ] Stat cards: Tugas Aktif + Selesai
- [ ] Menu "Klaim Upah Layanan" tampil
- [ ] Warna tema: biru sedang (#3A5E8C)

### 12.2 Assignment & Presensi
- [ ] List tugas assignment dari vendor/assignments
- [ ] Tap "Presensi" → VendorAttendanceScreen
- [ ] Check-in (geofence) + Check-out berfungsi

### 12.3 Klaim Upah
- [ ] Tap "Klaim Upah Layanan" → MyWageClaimsScreen
- [ ] Ringkasan upah tampil: Menunggu / Disetujui / Dibayar
- [ ] Total belum dibayar tampil di card
- [ ] Riwayat klaim tampil dengan status badge
- [ ] Status klaim: Menunggu → Disetujui → Dibayar
- [ ] Setelah dibayar: tombol "Konfirmasi Sudah Terima" tampil
- [ ] Tap konfirmasi → status confirmed

### 12.4 Tombol Back & Design
- [ ] Tombol back muncul di semua sub-screen
- [ ] Design konsisten glass theme Navy/Blue
- [ ] Pull-to-refresh berfungsi
- Catatan: _______________________________________________

---

## 13. VIEWER — Perjalanan Viewer

### 13.1 Login & Dashboard
- [ ] Login → ViewerDashboardScreen
- [ ] Banner "Mode read-only" tampil
- [ ] Stats: Pending / Aktif / Selesai
- [ ] List semua order (read-only)
- [ ] **TIDAK bisa** melakukan aksi write apapun (403)
- Catatan: _______________________________________________

---

## 14. SUPER ADMIN — Perjalanan Super Admin

### 14.1 Login & Dashboard
- [ ] Login → SuperAdminDashboardScreen
- [ ] User management (CRUD)

### 14.2 Master Data CRUD
- [ ] Semua 16 entity master bisa diakses:
  - [ ] consumables, billing-items, coffin-stages, coffin-qc-criteria
  - [ ] death-cert-docs, dekor-items, equipment
  - [ ] vendor-roles, trip-legs, wa-templates
  - [ ] status-labels, terms
  - [ ] attendance-locations, work-shifts, vehicle-inspection
- [ ] Create, Update, Soft-Delete berfungsi
- [ ] Owner bisa GET tapi TIDAK bisa POST/PUT/DELETE
- Catatan: _______________________________________________

---

## 15. CROSS-CUTTING TESTS

### 15.1 Anti-Hardcode Verification
- [ ] Semua status label berasal dari /config API (bukan hardcode)
- [ ] DynamicStatusBadge menampilkan label dari ConfigService
- [ ] OrderTimeline menggunakan DB-driven labels + warna
- [ ] Threshold values berasal dari system_thresholds
- [ ] KPI grade boundaries berasal dari threshold (bukan 90/75/60/40 hardcode)

### 15.2 Notification & Alarm
- [ ] Alarm overlay muncul untuk priority ALARM
- [ ] Snackbar untuk priority HIGH (orange)
- [ ] Normal snackbar untuk priority NORMAL
- [ ] Push notification FCM diterima (jika configured)

### 15.3 WhatsApp Deep Links
- [ ] WA Keluarga chip → buka WhatsApp dengan pesan terisi
- [ ] Template WA dari database (bukan hardcode)
- [ ] WA log tersimpan di wa_message_logs

### 15.4 PDF Export
- [ ] Laporan Tagihan PDF → download A4, 26 item, grand total, 3 tanda tangan
- [ ] Surat Penerimaan Layanan PDF → 6 section, S&K, 3 tanda tangan

### 15.5 Biometric Auth
- [ ] Settings: toggle Face ID / Fingerprint
- [ ] Enable → authenticate → stored
- [ ] Re-login menggunakan biometric

### 15.6 Design Consistency
- [ ] SEMUA role menggunakan palet turunan Navy (#1F3D7A) + Blue (#7BADD4)
- [ ] Tidak ada warna diluar palet (oranye, ungu, dll)
- [ ] Background putih (#FFFFFF) di semua screen
- [ ] Glass effect konsisten (blur, border, shadow)
- [ ] Tombol back muncul otomatis di semua sub-screen (GlassAppBar auto-detect canPop)
- [ ] Font konsisten (Inter family)
- [ ] **Dialog/Popup**: rounded corner 20px, background putih 94%, title navy bold, accent bar kiri
- [ ] **Bottom Sheet**: rounded top 24px, drag handle, close button, glass background
- [ ] **Buttons**: FilledButton rounded 12px, TextButton rounded 12px
- [ ] **Input fields**: rounded 14px, filled soft background, focus border navy

### 15.7 Animation
- [ ] Page transition: slide + fade smooth (350ms)
- [ ] Loading indicator: pulsing Santa Maria icon
- [ ] List items: staggered fade-in
- [ ] Shimmer loading placeholders

### 15.8 Real-time Updates
- [ ] Pusher events diterima untuk: equipment, attendance, coffin, KPI, stock
- [ ] Consumer tracking update real-time saat driver update status
- [ ] Owner fleet map refresh 15 detik

### 15.9 Rate Limiting
- [ ] API: 60 req/min → test dengan rapid taps
- [ ] AI: 10 req/min → test berulang
- [ ] Auth: 5 req/min → test brute force blocked

### 15.10 State Machine
- [ ] Order status hanya bisa transisi sesuai OrderStateMachine
- [ ] Invalid transition → 422 dengan valid_transitions list
- [ ] Terminal states (completed/cancelled) → tidak bisa transisi lagi

---

## RINGKASAN HASIL TEST

| Role | Total Tests | Pass | Fail | Notes |
|------|------------|------|------|-------|
| Consumer | 15 | | | |
| Service Officer | 18 | | | |
| Gudang | 20 | | | |
| Purchasing | 20 | | | |
| Driver | 16 | | | |
| HRD | 12 | | | |
| Owner | 8 | | | |
| Supplier | 8 | | | |
| Dekor | 5 | | | |
| Tukang Foto | 13 | | | |
| Vendor (Konsumsi/Pemuka) | 4 | | | |
| Koordinator Angkat Peti | 12 | | | |
| Viewer | 4 | | | |
| Super Admin | 6 | | | |
| Cross-Cutting | 29 | | | |
| **TOTAL** | **192** | | | |

---

**Tester:** ________________________
**Tanggal Test:** ________________________
**Device Android:** ________________________
**Device iOS:** ________________________
**Backend Version:** v1.27 (Phase 1-17)
**Frontend Version:** Flutter 3.x
