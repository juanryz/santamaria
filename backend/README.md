# Santa Maria Funeral Organizer — Backend API

## Changelog

### 2026-04-12 — Implementasi Penuh v1.9, v1.10, v1.11

#### v1.9 — Alur Order Definitif
- `PUT /so/orders/{id}/confirm` — SO konfirmasi order dengan `scheduled_at` + `estimated_duration_hours`; sistem broadcast ALARM ke Gudang, Finance, Dekor, Konsumsi, Pemuka Agama secara bersamaan
- `PUT /gudang/orders/{id}/stock-ready` — Gate konfirmasi stok siap; setelah ini baru driver mendapat ALARM
- `PUT /gudang/orders/{id}/checklist/{itemId}` — Centang item checklist stok
- `POST /consumer/orders/{id}/payment-proof` — Consumer upload bukti payment (cash/transfer)
- `GET|PUT /finance/orders/{id}/payment/verify|reject` — Finance verifikasi bukti payment
- `POST /driver/orders/{id}/bukti` — Driver upload foto bukti lapangan
- `POST /vendor/assignments/{id}/bukti` — Vendor (dekor/konsumsi) upload foto bukti
- Command `order:auto-complete-by-time` — Auto-complete order berdasarkan waktu (setiap 5 menit)
- Command `order:send-payment-reminder` — Reminder consumer upload bukti payment (tiap jam)

#### v1.10 — Finance, HRD, SO Multi-Channel
- **UserRole::HRD** ditambahkan ke enum
- `POST /so/orders/walkin` — SO kantor/lapangan input order tanpa consumer punya akun; `so_channel` field
- Finance field-team endpoints: `GET|POST /finance/orders/{id}/field-team`, `PUT /finance/field-team/{id}/pay`
- HRD endpoints: violations CRUD + thresholds management
- Owner endpoints: `GET /owner/hrd/violations`, `PUT /owner/thresholds/{key}`
- Commands HRD: `hrd:check-driver-overtime`, `hrd:check-so-late-processing`, `hrd:check-vendor-repeated-reject`, `hrd:check-finance-late-payment`, `hrd:check-late-bukti-upload`
- `NotificationService::sendHrdViolationAlert()` — broadcast ke HRD + Owner
- Tabel baru: `order_field_team_payments`, `hrd_violations`, `system_thresholds`
- Kolom baru di `orders`: `estimated_duration_hours`, `payment_proof_path`, `created_by_so_channel`, `needs_restock`
- Kolom baru di `users`: `so_channel`

#### v1.11 — e-Katalog Lengkap (7 Fase)
- Tabel baru: `procurement_requests`, `supplier_quotes` (dedicated), `supplier_transactions`, `supplier_ratings`
- Gudang: buat/publikasikan permintaan, evaluasi penawaran, pilih pemenang, konfirmasi terima barang, beri rating
- Finance: review & approve procurement, bayar supplier (`PUT /finance/supplier-transactions/{id}/pay`)
- Supplier: lihat permintaan `open`, ajukan penawaran (sealed bid, validasi max_price), tandai kirim barang, konfirmasi terima pembayaran
- AI validasi harga (background job `ValidateQuotePrice`)
- Sistem stok auto-tambah saat Gudang konfirmasi terima barang
- Seeder diperbarui: HRD, 2 SO channel, 2 Supplier terverifikasi

#### v1.12 — Order Visibility Fix untuk Gudang & Finance + Harga Paket SO

**Backend**
- `GET /gudang/orders` — endpoint baru; mengembalikan order dengan status `confirmed` & `in_progress` agar Gudang bisa melihat dan menangani order baru
- `GET /finance/orders` — diperluas untuk mengembalikan semua order aktif (`confirmed`, `in_progress`, `completed`, `pending`) yang perlu dipantau Finance, bukan hanya `proof_uploaded`; urutan prioritas: `proof_uploaded` → `unpaid` → `proof_rejected`
- `Gudang\OrderController` — controller baru untuk `GET /gudang/orders`

**Frontend — Gudang**
- Dashboard Gudang: tab baru **"Order Aktif"** (tab pertama) dengan badge merah jumlah order `confirmed`
- `GudangOrdersScreen` — screen baru: list semua order aktif, tampilkan info paket, jadwal, dan badge "Stok Kurang" jika `needs_restock = true`
- `_GudangChecklistScreen` — inline screen: checklist stok per order dengan progress bar, toggle per item, dan tombol "Konfirmasi Stok Siap" (unlock setelah semua item dicek)

**Frontend — Finance**
- Dashboard Finance: tab **"Payment Order"** (tab pertama) menampilkan semua order aktif dengan status payment; Finance bisa langsung konfirmasi lunas atau tolak bukti payment dari dashboard
- Tab PO dibagi menjadi "Perlu Review PO" dan "Riwayat PO" dengan badge count

**Frontend — SO**
- `SOOrderDetailScreen`: setelah memilih paket, card harga paket muncul dengan harga besar dan jelas — tidak lagi hanya tersembunyi di dalam dropdown


#### v1.27 — Phase 17: Google Drive Links, Back Button, Design, Animations, Biometric, QA

**1. Google Drive Link — Tukang Foto → Consumer/SO:**
- Migration: `order_gallery_links` (title, drive_url, link_type, visibility flags)
- Model: `OrderGalleryLink`
- Controller: `TukangFoto\GalleryLinkController` (3 endpoints: list, create, delete)
- Routes: `/tukang-foto/orders/{id}/gallery-links` (CRUD) + `/orders/{id}/gallery-links` (read for Consumer/SO)
- Flutter: `GalleryLinkScreen` — list links with Drive icon, tap → `launchUrl` external, FAB add, bottom sheet form
- Wired: Tukang Foto dashboard card "Galeri" button

**2. Auto Back Button — ALL Screens:**
- `GlassAppBar` updated: `Navigator.of(context).canPop()` auto-detects if back button needed
- No manual `showBack: true` required — back button appears automatically on sub-screens
- Root dashboards: no back button (canPop = false)

**3. Consistent Design Theme — Navy+Blue Palette:**
- ALL role colors redesigned to Navy (#1F3D7A) + Blue (#7BADD4) turunan:
  - HRD: `#2E4A82` (was orange), Purchasing: `#3D6DAE` (was bright blue)
  - Tukang Foto: `#5584B8` (was purple), Viewer: `#B0C4D8` (was grey)
  - Pemuka Agama: `#4A6FA5` (added as named constant)
- `roleColor()` helper updated for all 15+ roles

**4. Animations:**
- `SmoothPageRoute` — slide + fade (350ms, easeOutCubic)
- `FadePageRoute` — fade only (300ms, for modals)
- `ScalePageRoute` — scale + fade (400ms, easeOutBack, for FAB actions)
- `AnimatedLoading` — pulsing church icon with message
- `ShimmerBlock` — gradient shimmer loading placeholder
- `FadeInListItem` — staggered fade-in for list items (per-item delay)

**5. Biometric Authentication:**
- `BiometricService` singleton — Face ID (iOS), Fingerprint (Android)
  - `init()`, `authenticate()`, `enable()`, `disable()`, `getStoredToken()`
  - `biometricLabel` + `biometricIcon` for UI
  - Secure storage for enabled flag + auth token
- `BiometricSettingTile` widget — drop-in SwitchListTile for any settings screen

**6. Quality Assurance Document:**
- `qualityassurance.md` — **160 test cases** across **15 roles**
  - Per-role: start journey → end journey with checkboxes
  - Cross-cutting: anti-hardcode, notifications, WA, PDF, biometric, design, animation, real-time, rate limiting, state machine
  - Summary table for test results
  - Credential reference table

**Flutter APK Build:** PASSED (confirmed via background build)

---

#### v1.26 — Phase 14: Vehicle Maintenance, Fleet Map, Shift Management, Full Navigation Wiring

**Backend — Gudang Vehicle Maintenance Controller:**
- `VehicleMaintenanceController` — 9 endpoint:
  - `GET /gudang/maintenance-requests` (paginated, sorted by priority)
  - `GET /gudang/maintenance-requests/{id}`
  - `PUT .../acknowledge`, `PUT .../start`, `PUT .../complete` (with cost + notes), `PUT .../defer`
  - `GET /gudang/fuel-logs` (pending-first sort)
  - `PUT /gudang/fuel-logs/{id}/validate`, `PUT .../reject` (with reason + notification to driver)

**Frontend — 3 Screen Baru:**
- `VehicleMaintenanceScreen` — 2-tab: Maintenance (acknowledge/complete actions) + Validasi BBM (validate/reject)
- `OwnerFleetMapScreen` — real-time map semua driver aktif, 15s auto-refresh GPS, stat overlay (order aktif + driver terlacak)
- `HrdShiftManagementScreen` — 2-tab: Shift Kerja (list) + Lokasi Presensi (list with radius)

**Frontend — Dashboard Navigation Wiring (5 dashboards upgraded):**
- HRD: "Presensi Karyawan" → `HrdAttendanceDashboardScreen`, "Shift & Lokasi" → `HrdShiftManagementScreen`
- Driver: FAB column — fingerprint (ClockInScreen) + receipt (TripLogScreen)
- Owner: 6th tab "Armada" → `OwnerFleetMapScreen` (embedded)
- Gudang: chip "Maintenance Kendaraan" → `VehicleMaintenanceScreen`

---

#### v1.25 — Phase 13: Acceptance Letter, Stock-Aware Packages, Anti-Mock, HRD Attendance

**Backend — Service Acceptance Letter (v1.25 — Gate sebelum konfirmasi order):**
- Migration: `service_acceptance_letters` — 6 section form (PJ, Almarhum, Layanan, Lokasi, T&C, Tanda Tangan × 3 pihak)
- Model: `ServiceAcceptanceLetter` — `isFullySigned()`, `canBeConfirmed()` helpers
- Controller: `AcceptanceLetterController` — 8 endpoint:
  - `POST /so/orders/{id}/acceptance-letter` (create draft, auto-fill from order)
  - `GET /so/orders/{id}/acceptance-letter` (view with T&C)
  - `PUT /so/orders/{id}/acceptance-letter` (update draft)
  - `POST .../sign-pj` (family signature)
  - `POST .../sign-sm` (SM officer signature)
  - `POST .../sign-saksi` (witness signature, optional)
  - `GET .../pdf` (download PDF A4)
  - `POST .../send-wa` (generate WA deep link with order details)
- PDF Template: `acceptance-letter.blade.php` — 6 sections, 3 signature blocks, T&C embed, footer timestamp
- Order model: `acceptanceLetter()` relationship + `isAcceptanceLetterSigned()` gate check

**Backend — Stock-Aware Package Selection:**
- `PackageStockController::index()` — `GET /packages/stock-check`
- Per package: `stock_status` (available/partial/unavailable), `can_select` flag, `stock_details` per item
- Critical items out of stock → package disabled; non-critical partial → warning only

**Frontend — 2 Screen Baru:**
- `HrdAttendanceDashboardScreen` — real-time summary (hadir/telat/belum), per-employee list with DynamicStatusBadge
- `ClockInScreen` + `MyAttendanceScreen` (from Phase 12 — now wired)

**Frontend — Anti-Mock Detection Service (6 layers):**
- `MockDetectionService` singleton — client-side layers:
  - Layer 1: `checkMockProvider()` — Flutter isMocked flag
  - Layer 3: `checkBlacklistedApps()` — scan installed apps vs blacklist from backend
  - Layer 6: `getDeviceFingerprint()` — device_info consistency
  - `runAllChecks()` — aggregate all client layers, return `is_mock_detected` flag
- Backend layers (already in DailyAttendanceController):
  - Layer 5: Geofence Haversine validation
  - Auto HRD violation on mock detection

---

#### v1.20 — Phase 12: Daily Attendance, Vehicle Management, KPI Metrics

**Database — 3 Migrasi Baru (11 tabel):**

*Daily Attendance (v1.17):*
- `attendance_locations` — master geofence lokasi (nama, alamat, lat/lng, radius)
- `work_shifts` — master shift kerja (start/end time, toleransi telat/pulang awal)
- `user_shift_assignments` — assignment shift per karyawan (effective dates)
- `daily_attendances` — clock in/out harian (GPS, selfie, distance, mock detection, override)
- `attendance_logs` — audit trail semua percobaan clock (termasuk gagal/mock)

*Vehicle Management (v1.20):*
- `vehicle_km_logs` — speedometer reading (start/end/refuel) + foto
- `vehicle_fuel_logs` — isi BBM (liter, harga, SPBU, receipt foto, validasi Gudang)
- `vehicle_inspection_master` — 29 item checklist inspeksi (5 kategori: exterior, interior, engine, safety, documents)
- `vehicle_inspections` — header inspeksi (pre_trip/post_trip, pass/fail)
- `vehicle_inspection_items` — detail per item inspeksi
- `vehicle_maintenance_requests` — laporan kerusakan (reported → acknowledged → in_progress → completed)

**Backend — 11 Model Baru:**
- `AttendanceLocation`, `WorkShift`, `UserShiftAssignment`, `DailyAttendance`, `AttendanceLog`
- `VehicleKmLog`, `VehicleFuelLog`, `VehicleInspection`, `VehicleInspectionItem`, `VehicleInspectionMaster`, `VehicleMaintenanceRequest`

**Backend — 2 Controller Baru:**
- `Attendance\DailyAttendanceController` — `clockIn()` (6-layer: mock detection, geofence Haversine, early check, late detection + HRD violation auto-create), `clockOut()` (early leave detection), `today()`, `myHistory()` (monthly summary)
- `Driver\VehicleManagementController` — KM logs CRUD, fuel logs CRUD, inspection checklist submit (critical item fail detection), maintenance request submit

**Backend — 10 KPI Metrics Baru:**
- `ATT_DAILY_RATE` (SO/Gudang/Driver/Purchasing) — kehadiran harian %
- `ATT_PUNCTUALITY` (SO/Driver) — tepat waktu %
- `DRV_INSPECTION_RATE` — % hari dengan pre-trip inspection
- `DRV_FUEL_EFFICIENCY` — rata-rata km/liter
- `DRV_KM_LOG_COMPLIANCE` — % hari dengan foto KM
- `ATT_MOCK_ATTEMPTS` — percobaan fake GPS (target: 0)

**Backend — 4 HRD Violation Types Baru:**
- `daily_attendance_absent`, `daily_attendance_late`, `daily_attendance_early_leave`, `mock_location_attempt`

**Backend — Routes: 11 endpoint baru:**
- `POST/GET /attendance/clock-in|clock-out|me/today|me` (4 endpoint)
- `POST/GET /driver/vehicles/{id}/km-log|km-logs|fuel-logs|inspections|maintenance-requests` (7 endpoint)

**Backend — Seeder:**
- `AttendanceVehicleSeeder` — 2 attendance locations, 4 work shifts, 29 vehicle inspection checklist items

**Backend — Integration Test:**
- `OrderFlowIntegrationTest` — 10 tests: create → confirm → state machine → transition → acceptance → viewer block → config endpoint

**Frontend — 3 Screen Baru:**
- `ClockInScreen` — clock in/out with status card, shift info, geofence indicator
- `MyAttendanceScreen` — monthly summary (hadir/telat/absen/pulang awal), calendar list with DynamicStatusBadge
- `DriverVehicleScreen` — 4-tab: Quick Action (KM/BBM/maintenance), KM Log, BBM, Maintenance

---

#### v1.17 — Phase 11: Factories, Rate Limiting, Response Trait, Final Wiring

**Backend — Model Factories (5 baru):**
- `UserFactory` — enhanced: `role()`, `consumer()`, `driver()`, `gudang()`, `superAdmin()`, `viewer()`, `supplier()` state methods
- `OrderFactory` — `confirmed()`, `completed()`, `withConsumer()`, `withPackage()` state methods
- `PackageFactory`, `PackageItemFactory` (with `withStock()`), `StockItemFactory` (with `lowStock()`, `outOfStock()`)

**Backend — API Rate Limiting (6 limiters):**
- `api` — 60 req/min per user (default)
- `gps` — 30 req/min (driver GPS tracking)
- `ai` — 10 req/min (AI endpoints)
- `auth` — 5 req/min per IP (brute force prevention)
- `wa` — 10 req/min (WhatsApp spam prevention)
- `config` — 30 req/min (cached config endpoint)
- Applied: AI routes wrapped in `throttle:ai`, WA routes in `throttle:wa`

**Backend — Response Standardization:**
- `ApiResponse` trait — `success()`, `created()`, `error()`, `notFound()`, `forbidden()`, `validationError()`, `paginated()`
- Applied to base `Controller` — all controllers inherit consistent response format

**Frontend — Navigation Wiring:**
- Supplier dashboard: transaction icon button → `SupplierTransactionScreen`
- Consumer tracking: acceptance banner (orange) → `ConsumerAcceptanceScreen` for confirmed unsigned orders

---

### DEFINITIVE PROJECT AUDIT (Phase 1-11)

```
=== BACKEND (Laravel 11) ===
Migrations:          77 files
Models:              67 files
Controllers:         68 files (26 sub-dirs)
Enums:                9 files
Services:            24 files (incl. AI)
Commands:            19 files
Jobs:                 5 files
Events:               8 files
Middleware:            3 files
Seeders:              4 files
Factories:             5 files
Tests:                5 files
Traits:                2 files
API Routes:          ~276 route registrations (~100 unique endpoints)

=== FRONTEND (Flutter 3.x) ===
Dart files:          101 files
Screens:              60 files
Repositories:         15 files
Services:              6 files
Widgets:               9 files
Flutter Tests:         4 files
Localization:         2 files (90+ strings ID + EN)

=== INFRASTRUCTURE ===
Schedulers:            6 new cron jobs
Pusher Events:         5 broadcast events
PDF Templates:         1 Blade template
```

---

#### v1.17 — Phase 10: Middleware, Acceptance Flow, GPS Tracking, Supplier UX, API Docs

**Backend — Middleware (2 baru + 1 enhanced):**
- `EnsureNotViewer` enhanced — checks both `is_viewer` flag AND `VIEWER` role; globally applied to all API routes via `appendToGroup('api')`
- `OwnerReadOnly` baru — blocks POST/PUT/DELETE for Owner role; applied to master data write routes (v1.27 compliance)
- Master data routes split: GET open to Super Admin + Owner, write routes wrapped in `owner_readonly` middleware

**Backend — Consumer Acceptance Flow:**
- `Consumer\AcceptanceController` — `GET /consumer/orders/{id}/acceptance` (show T&C + order summary), `POST /consumer/orders/{id}/acceptance/sign` (sign with name, relation, agreement)
- Migration `add_acceptance_fields_to_orders` — 5 fields: `acceptance_signed_at`, `acceptance_signed_by_name`, `acceptance_signed_relation`, `acceptance_signature_path`, `acceptance_terms_version`
- Order model updated with acceptance fields + `isAcceptanceSigned()` helper

**Backend — GPS Real-Time Tracking:**
- `Driver\GpsTrackingController` — `POST /driver/gps` (update location, cache + DB + Pusher broadcast), `GET /driver/gps/latest/{driverId}` (latest location from cache/DB)
- `DriverLocationBroadcast` event — broadcasts to `order.{orderId}` channel for consumer/owner real-time tracking
- Redis cache for latest location (5min TTL) for fast reads

**Backend — API Documentation:**
- `ApiDocController` — `GET /api-docs` — auto-generates route summary grouped by path, shows method, URI, middleware, action
- Currently ~100 endpoints documented

**Frontend — 2 Screen Baru:**
- `ConsumerAcceptanceScreen` — T&C display, PJ name/relation input, checkbox agreement, sign button; already-signed state
- `SupplierTransactionScreen` — transaction list with DynamicStatusBadge, mark-shipped dialog, confirm-payment button, currency formatting

**Frontend — Order Model Updated:**
- `driverAssignments()`, `vendorAssignments()` relationships added
- Consumer tracking: payment button wired to `ConsumerPaymentScreen`

---

#### v1.17 — Phase 9: Controller Refactor, Trip Legs, Consumer UX, FCM, Widget Tests

**Backend — Controller Refactors (state machine wired):**
- `Admin\OrderController::approve()` — uses `OrderStateMachine::canTransition()` + `::transition()` instead of hardcoded status checks; `OrderStatus::activeStatuses()` for conflict detection; `PaymentStatus::values()` for validation
- `Admin\OrderController::close()` — uses state machine transition + validates terminal state
- `Driver\OrderController` — complete rewrite: `transition()` endpoint (state-machine driven, driver picks from `nextStatuses()`); legacy `updateStatus()` maps to new statuses; notifications via `NotificationPriority` enum; `PUT /driver/orders/{id}/transition` new endpoint
- All status string comparisons replaced with enum references

**Database — 1 Migration + 1 Model:**
- `order_driver_assignments` — trip leg tracking per order: leg_master_id, driver_id, vehicle_id, origin/destination labels + GPS, status (assigned→departed→arrived→completed), proof photo, KM start/end
- `OrderDriverAssignment` model with relationships to Order, TripLegMaster, User, Vehicle + computed `kmDriven`

**Frontend — Consumer UX Enhancements:**
- `order_tracking_screen.dart` — hardcoded `_steps` list REMOVED, replaced with DB-driven `OrderTimelineWidget` (consumer view); payment button added for completed unpaid orders → `ConsumerPaymentScreen`

**Frontend — WA Deep Links Wired:**
- SO order detail: "WA Keluarga" chip — opens WhatsApp with order context message via `WhatsAppService.contactForOrder()`

**Frontend — FCM Service:**
- `FcmService` singleton — token registration with backend, foreground/background message routing to `NotificationHandler`, dispose on logout

**Frontend — Widget Tests (3 files, 12 tests):**
- `order_timeline_test.dart` (3 tests): fallback rendering, consumer view, status logs
- `dynamic_status_badge_test.dart` (4 tests): fallback label, positive/negative colors, color override
- `glass_alarm_overlay_test.dart` (4 tests): title/message rendering, order ID display, action button, dismiss

---

#### v1.17 — Phase 8: Master Tables, State Machine, WA Templates, Order Timeline

**Database — 5 Migrasi Baru (8 tabel):**
- `order_status_labels` — label consumer/internal per status (17 status, icon, color, show_map)
- `trip_leg_master` — master jenis leg perjalanan (9 seed: antar barang, jemput jenazah, dll)
- `vendor_role_master` — master jenis vendor/peran (10 seed: pemuka agama, fotografer, musisi, dll)
- `wa_message_templates` — template pesan WhatsApp (4 seed: order confirmed, vendor assignment, payment reminder, driver dispatch)
- `wa_message_logs` — log pesan WA yang dikirim
- `terms_and_conditions` — syarat & ketentuan (versioning, 1 seed v1.0)
- `order_trip_templates` — template rute per paket
- `order_vendor_assignments` — unified vendor assignment (internal + external)

**Backend — 7 Model Baru:**
- `OrderStatusLabel`, `TripLegMaster`, `VendorRoleMaster`, `WaMessageTemplate`, `WaMessageLog`, `TermsAndConditions`, `OrderVendorAssignment`

**Backend — Services (2 baru):**
- `OrderStateMachine` — single source of truth untuk transisi status order; `transition()`, `canTransition()`, `nextStatuses()`, `isTerminal()`, `transitionMap()`, label dari DB
- `WaMessageService` — render template WA dari DB, generate deep link, auto-log; `generateMessage()`, `orderConfirmedToConsumer()`

**Backend — Controller & Routes:**
- `WaController` — 4 endpoint: `GET /wa/templates`, `POST /wa/send`, `POST /wa/send-order/{id}`, `GET /wa/logs`
- `GET /terms/current` — syarat & ketentuan berlaku
- `GET /orders/{id}/next-statuses` — valid next status dari state machine
- `ConfigController` diperluas: + `status_labels`, `trip_legs`, `vendor_roles`, `terms_and_conditions`, `order_state_machine`
- `MasterDataController` diperluas: + `vendor-roles`, `trip-legs`, `wa-templates`, `status-labels`, `terms`

**Backend — Seeder:**
- `MasterDataV117Seeder` — 15 order status labels, 9 trip legs, 10 vendor roles, 4 WA templates, 1 T&C v1.0
- `DatabaseSeeder` updated: auto-call `MasterDataV117Seeder`

**Frontend — Widgets (2 baru):**
- `OrderTimelineWidget` — visual timeline status order; DB-driven labels/colors dari ConfigService; consumer view vs internal view; timestamp per status; map icon indicator; fallback jika config belum loaded
- `NotificationHandler` — singleton service; handle FCM/Pusher payloads; priority-based UI (ALARM → overlay, HIGH → orange snackbar, NORMAL → default snackbar); Pusher event mapping

**Frontend — main.dart:**
- Navigator key global untuk notification handler
- `NotificationHandler.instance.init(navigatorKey)` dipanggil saat splash

---

#### v1.14 — Phase 7: Anti-Hardcode Layer, Enums, Config API, AI Recommendations

**ATURAN NO HARD CODE — Implementasi Penuh:**

Semua nilai yang sebelumnya di-hardcode kini digantikan oleh referensi dinamis:

**Backend — 8 Enum Baru:**
- `OrderStatus` — 17 status order + `label()`, `activeStatuses()`, `completedStatuses()`
- `PaymentStatus` — 6 status payment + `label()`
- `CoffinStatus` — 9 status workshop peti + `label()`
- `AttendanceStatus` — 4 status presensi + `label()`, `color()`
- `EquipmentItemStatus` — 6 status peralatan + `label()`
- `ProcurementStatus` — 9 status e-Katalog + `label()`
- `ViolationType` — 10 tipe pelanggaran + `label()`, `severity()`, `thresholdKey()`
- `NotificationPriority` — 6 prioritas + `androidPriority()`, `soundName()`, `shouldBypassDnd()`

**Backend — Config API (Zero Hardcode Frontend):**
- `GET /config` — serves ALL enums (labels + values + colors), thresholds, settings
- `GET /config/thresholds` — lightweight thresholds only
- `ConfigController` — frontend fetches ini pada startup, tidak pernah hardcode label/limit

**Backend — Commands Refactored:**
- `CheckAttendanceLate` — gunakan `AttendanceStatus`, `ViolationType`, `NotificationPriority`, `UserRole` enums
- `CheckEquipmentReturn` — gunakan `EquipmentItemStatus`, `OrderStatus`, `ViolationType` enums
- `CheckCoffinQcDeadline` — gunakan `ViolationType` enum
- `CheckDeathCertPending` — gunakan `OrderStatus`, `ViolationType` enums
- `CalculateMonthlyKpi` — grade boundaries dari `system_thresholds` (bukan hardcode 90/75/60/40)

**Backend — 15 Threshold Baru di system_thresholds:**
- KPI grading: `kpi_grade_a_min` (90), `kpi_grade_b_min` (75), `kpi_grade_c_min` (60), `kpi_grade_d_min` (40)
- Driver: `driver_max_orders_per_day` (3)
- Consumer: `payment_proof_max_size_mb` (5)
- Stock: `stock_low_multiplier` (1.5)
- Vendor: `vendor_max_concurrent_orders` (2)
- AI: `ai_price_variance_warning_pct` (10), `ai_price_variance_anomaly_pct` (20)
- Order: `order_auto_complete_buffer_hours` (2), `order_max_extension_hours` (24)
- Procurement: `procurement_quote_min_count` (1), `procurement_auto_close_days` (7)

**Backend — AI Recommendation Services (2 baru):**
- `VendorRecommendationService` — AI rekomendasi vendor berdasarkan KPI, kehadiran, pelanggaran, ketersediaan jadwal (+ fallback sort by KPI)
- `ScheduleOptimizationService` — AI optimasi jadwal driver + kendaraan berdasarkan beban kerja + konflik (+ fallback first-available)
- `AI\RecommendationController` — 2 endpoints: `GET /ai/recommend-vendor`, `GET /ai/optimize-schedule/{orderId}`

**Frontend — Anti-Hardcode:**
- `ConfigService` — singleton service, load dari `/config` pada startup, cache in-memory
  - `getLabel(enumGroup, value)` — resolve status label dari config
  - `getThreshold(key)` — resolve threshold value
  - `getEnumItems(group)` — get all items for dropdown/filter
  - `getViolationSeverity(type)` — resolve severity
  - `getAttendanceColor(value)` — resolve color
- `DynamicStatusBadge` — widget yang auto-resolve label dari ConfigService, auto-color dari pattern matching
- `main.dart` — `ConfigService.instance.load()` dipanggil saat splash screen

---

#### v1.14 — Phase 6: Pusher Integration, AI Services, Localization, Tests

**Backend — AI Services (2 baru):**
- `KpiAnalysisService` — AI-generated KPI insights per karyawan (strengths, improvements, trend analysis, recommendation)
- `OrderSummaryService` — AI-generated ringkasan operasional harian per order (highlights, issues, billing status, next action)
- `AI\KpiAnalysisController` — 2 endpoints: `GET /ai/kpi-analysis/{userId}`, `GET /ai/order-summary/{orderId}`

**Frontend — Pusher Realtime (5 subscriptions baru):**
- `subscribeToEquipment()`, `subscribeToAttendance()`, `subscribeToCoffinOrders()`, `subscribeToKpi()`, `subscribeToStockAlerts()`, `disconnect()`

**Localization — 90+ string baru (ID + EN):**
- Workshop peti, peralatan, stok, konsumabel, tagihan, akta kematian, persetujuan, presensi, KPI, pelanggaran, payment, alarm, common actions

**Tests (3 files, 18 test cases):**
- `StockManagementServiceTest` (4 tests): deduction logic, insufficient flag, stock alerts
- `KpiCalculationTest` (4 tests): auto-period, scoring formula, grade boundaries, ranking
- `V114EndpointsTest` (10 tests): coffin, equipment, stock, KPI, authorization

---

#### v1.14 — Phase 5: Geofence, Stock Forms, WhatsApp, Alarm, Consumer Payment

**Backend — Geofence Attendance:**
- `Vendor\AttendanceController::checkIn()` — full geofence validation (Haversine formula, 500m default radius from `system_thresholds`), early check-in prevention (max 2h before scheduled), late detection, Pusher event broadcast
- `Vendor\AttendanceController::checkOut()` — status validation + Pusher event

**Backend — Stock Management:**
- `ServiceOfficer\StockCheckController::preview()` — `GET /so/orders/{id}/stock-check` — preview stok sebelum konfirmasi (no deduction, read-only)
- `Gudang\StockFormController::submitForm()` — `POST /gudang/stock/form` — form pengambilan/pengembalian barang dengan validasi stok + auto stock transaction
- `Gudang\StockFormController::deductions()` — `GET /gudang/stock/deductions` — history deduction per order

**Backend — User Model:**
- Relationships: `fieldAttendances`, `kpiScores`, `kpiSummaries`
- Helpers: `isPurchasing()`, `isViewer()`

**Frontend — New Screens:**
- `ConsumerPaymentScreen` — CASH vs TRANSFER toggle, photo upload with 5MB limit, image compression
- `StockFormScreen` — Pengambilan/Pengembalian toggle, stock item dropdown with current qty, PIC name

**Frontend — New Widgets & Services:**
- `GlassAlarmOverlay` — Full-screen pulsing alarm overlay for critical notifications (bypass DND visual)
- `WhatsAppService` — Deep link utility: `openChat()`, `contactForOrder()`, `contactSupplier()` (replaces manual contact buttons per pedoman v1.12)

**Frontend — Gudang Dashboard:**
- New chip: "Ambil/Kembali Barang" → StockFormScreen

---

#### v1.14 — Phase 4: Role System, Model Relations, Seeder, Dashboard Wiring

**Backend — Role System:**
- `UserRole` enum: added `PURCHASING`, `SECURITY`, `VIEWER`, `TUKANG_FOTO` (total 17 cases)
- `vendor()`: added `TUKANG_FOTO`
- `viewer()`: added `VIEWER`
- Finance routes now accept both `FINANCE` and `PURCHASING` roles via `implode` middleware
- Purchasing routes also accept both `FINANCE` and `PURCHASING` roles

**Backend — Order Model v1.14:**
- 4 new fillable fields: `coffin_order_id`, `tukang_foto_id`, `death_cert_submitted`, `extra_approval_total`
- 9 new relationships: `coffinOrder`, `tukangFoto`, `equipmentItems`, `consumablesDaily`, `billingItems`, `deathCertDoc`, `extraApprovals`, `fieldAttendances`, `stockDeductions`, `vehicleTripLogs`

**Backend — Seeder Updates:**
- DatabaseSeeder: 4 new test users (Tukang Foto, Purchasing, Security, Viewer)
- DatabaseSeeder: auto-call `MasterDataV114Seeder` + `KpiMetricSeeder`

**Frontend — Dashboard Enhancements:**
- Driver: FAB button → DriverTripLogScreen (nota mobil jenazah)
- Owner: new "KPI" tab (5th tab) → embedded KpiManagementScreen
- SO Order Detail: "Dokumen & Formulir" section with chips → Berkas Akta Kematian, Persetujuan Tambahan (shown for confirmed orders)
- Gudang Orders: "Peralatan" + "Konsumabel" buttons per order card (shown for non-pending orders)

---

#### v1.14 — Phase 3: Integration, PDF, Events, Full Dashboard Coverage

**Service Integration:**
- `StockManagementService` + `OrderAutoGenerateService` wired into `ServiceOfficer\OrderController::confirm()` — auto-deduct stok, auto-generate equipment/billing/attendance records saat SO konfirmasi order

**PDF Export:**
- `BillingExportController` — Export laporan tagihan 26 item ke PDF (DomPDF)
- `GET /purchasing/billing/export/{orderId}` — endpoint download PDF
- Template Blade `pdf/billing-report.blade.php` — format A4 portrait dengan header Santa Maria, tabel item, summary grand total, area tanda tangan 3 pihak

**Pusher Events (4 baru):**
- `OrderEquipmentUpdated` — broadcast saat peralatan dikirim/dikembalikan
- `AttendanceUpdated` — broadcast saat vendor check-in/check-out
- `CoffinOrderUpdated` — broadcast saat status peti berubah
- `KpiCalculated` — broadcast saat kalkulasi KPI selesai

**Frontend — 3 Dashboard Baru:**
- `TukangFotoDashboardScreen` — tugas aktif, presensi shortcut, KPI link
- `SecurityDashboardScreen` — monitoring order aktif (read-only)
- `ViewerDashboardScreen` — read-only view semua order dengan notice badge

**Frontend — Navigation Wiring:**
- Login switch: `tukang_foto` → TukangFotoDashboardScreen, `security` → SecurityDashboardScreen, `viewer` → ViewerDashboardScreen
- Gudang dashboard: quick-access chips ke Workshop Peti, Alert Stok, Pinjaman Peralatan
- Purchasing dashboard: menu grid navigates ke PaymentVerifyScreen
- HRD dashboard: KPI Karyawan navigates ke KpiManagementScreen

---

#### v1.14 — Phase 2: Services, Commands, Extra Screens

**Services:**
- `StockManagementService` — Auto-deduction stok saat SO konfirmasi order; auto-generate stock alerts; notify Gudang + Purchasing jika stok rendah
- `OrderAutoGenerateService` — Auto-generate `field_attendances`, `order_equipment_items`, `order_billing_items` saat order dikonfirmasi

**Scheduler Commands (6 baru):**
- `attendance:check-late` (setiap 5 menit) — Mark absent + alert HRD jika vendor/tukang_foto belum check-in
- `equipment:check-return-deadline` (tiap jam) — Alert Gudang jika peralatan belum kembali setelah deadline
- `coffin:check-qc-deadline` (tiap 2 jam) — Alert jika peti belum di-QC setelah finishing
- `death-cert:check-pending` (harian 09:00) — Reminder SO jika berkas akta belum dibuat
- `kpi:calculate-monthly` (1st of month 02:00) — Auto-calculate semua skor KPI per role
- `kpi:refresh-current-period` (tiap 6 jam) — Refresh skor KPI periode berjalan

**Frontend Tambahan (5 screen):**
- `consumable_daily_screen.dart` — Form input data barang konsumabel per shift (P/K/M)
- `billing_detail_screen.dart` — Laporan tagihan 26 item dengan grand total
- `kpi_management_screen.dart` — Manajemen metrik, ranking per role, periode KPI (HRD)
- `payment_verify_screen.dart` — Verifikasi/tolak bukti payment konsumen (Purchasing)
- `equipment_loan_form_screen.dart` — Form pinjaman peralatan peringatan

**Database — 29 Tabel Baru + 4 Migrasi Update:**
- Master tables: `equipment_master`, `consumable_master`, `billing_item_master`, `dekor_item_master`, `death_cert_doc_master`, `coffin_stage_master`, `coffin_qc_criteria_master`
- Workshop Peti: `coffin_orders`, `coffin_order_stages`, `coffin_qc_results`
- Presensi: `field_attendances`
- Peralatan: `equipment_loans`, `order_equipment_items`
- Konsumabel: `order_consumables_daily`, `order_consumable_lines`
- Tagihan: `order_billing_items`
- Dekorasi: `dekor_daily_package`, `dekor_daily_package_lines`
- Dokumen: `order_death_certificate_docs`, `order_death_cert_doc_items`, `order_extra_approvals`, `extra_approval_lines`
- Stok: `stock_alerts`, `order_stock_deductions`
- KPI: `kpi_metric_master`, `kpi_periods`, `kpi_scores`, `kpi_user_summary`
- Kendaraan: `vehicle_trip_logs`
- Kolom baru di `orders`: `coffin_order_id`, `tukang_foto_id`, `death_cert_submitted`, `extra_approval_total`
- Role baru: `TUKANG_FOTO`
- Violation types baru: `vendor_attendance_late`, `equipment_not_returned`, `coffin_qc_overdue`, `death_cert_not_submitted`
- Threshold baru: attendance radius, check-in early, late threshold, equipment return deadline, coffin QC deadline, death cert deadline, default city

**Backend — 14 Controller Baru:**
- `Gudang\CoffinOrderController` — CRUD order peti, tahap pengerjaan, QC
- `Gudang\EquipmentController` — Master peralatan, checklist per order, kirim/kembali, pinjaman peringatan
- `Gudang\StockAlertController` — Alert stok, resolve
- `Vendor\AttendanceController` — Check-in/check-out vendor & tukang foto
- `ServiceOfficer\AttendanceController` — Konfirmasi kehadiran
- `ServiceOfficer\DeathCertController` — Checklist berkas akta kematian
- `ServiceOfficer\ExtraApprovalController` — Form persetujuan tambahan + tanda tangan digital
- `Dekor\DailyPackageController` — Formulir paket harian La Fiore
- `Driver\VehicleTripLogController` — Nota pemakaian mobil jenazah
- `ConsumableController` — Data barang konsumabel harian per shift
- `BillingController` — Laporan tagihan 26 item per order
- `SuperAdmin\MasterDataController` — CRUD semua master table
- `HRD\AttendanceController` — View semua presensi
- `KPI\KpiController` — Metrics, periods, scores, summaries, rankings, self KPI

**Backend — Seeders:**
- `MasterDataV114Seeder` — Seed data awal: 13 equipment, 16 consumables, 25 billing items, 19 dekor items, 21 death cert docs, 21 coffin stages (melamin+duco), 6 QC criteria
- `KpiMetricSeeder` — 20 KPI metrics (SO, Gudang, Purchasing, Driver)

**Frontend — 7 Repository Baru:**
- `purchasing_repository.dart`, `hrd_repository.dart`, `equipment_repository.dart`, `coffin_repository.dart`, `attendance_repository.dart`, `billing_repository.dart`, `kpi_repository.dart`

**Frontend — 15 Screen Baru:**
- Purchasing: `purchasing_dashboard_screen.dart`
- HRD: `hrd_dashboard_screen.dart`, `hrd_violation_list_screen.dart`, `hrd_violation_detail_screen.dart`, `hrd_threshold_screen.dart`
- Gudang: `coffin_order_list_screen.dart`, `coffin_order_form_screen.dart`, `coffin_order_detail_screen.dart`, `equipment_checklist_screen.dart`, `stock_alert_screen.dart`
- KPI: `kpi_dashboard_screen.dart`
- SO: `so_extra_approval_screen.dart`, `so_death_cert_screen.dart`
- Dekor: `dekor_daily_package_screen.dart`
- Vendor: `vendor_attendance_screen.dart`
- Driver: `driver_trip_log_screen.dart`

**Frontend — Routing:**
- Login switch ditambah: `purchasing` → PurchasingDashboardScreen, `hrd` → HrdDashboardScreen, `tukang_foto` → VendorAssignmentScreen
- Role constants ditambah: `hrd`, `security`, `viewer`, `tukang_foto`, `purchasing`
- App colors ditambah: `roleHrd`, `rolePurchasing`, `roleTukangFoto`, `roleViewer`

---

<p align="center"><a href="https://laravel.com" target="_blank"><img src="https://raw.githubusercontent.com/laravel/art/master/logo-lockup/5%20SVG/2%20CMYK/1%20Full%20Color/laravel-logolockup-cmyk-red.svg" width="400" alt="Laravel Logo"></a></p>

<p align="center">
<a href="https://github.com/laravel/framework/actions"><img src="https://github.com/laravel/framework/workflows/tests/badge.svg" alt="Build Status"></a>
<a href="https://packagist.org/packages/laravel/framework"><img src="https://img.shields.io/packagist/dt/laravel/framework" alt="Total Downloads"></a>
<a href="https://packagist.org/packages/laravel/framework"><img src="https://img.shields.io/packagist/v/laravel/framework" alt="Latest Stable Version"></a>
<a href="https://packagist.org/packages/laravel/framework"><img src="https://img.shields.io/packagist/l/laravel/framework" alt="License"></a>
</p>

## About Laravel

Laravel is a web application framework with expressive, elegant syntax. We believe development must be an enjoyable and creative experience to be truly fulfilling. Laravel takes the pain out of development by easing common tasks used in many web projects, such as:

- [Simple, fast routing engine](https://laravel.com/docs/routing).
- [Powerful dependency injection container](https://laravel.com/docs/container).
- Multiple back-ends for [session](https://laravel.com/docs/session) and [cache](https://laravel.com/docs/cache) storage.
- Expressive, intuitive [database ORM](https://laravel.com/docs/eloquent).
- Database agnostic [schema migrations](https://laravel.com/docs/migrations).
- [Robust background job processing](https://laravel.com/docs/queues).
- [Real-time event broadcasting](https://laravel.com/docs/broadcasting).

Laravel is accessible, powerful, and provides tools required for large, robust applications.

## Learning Laravel

Laravel has the most extensive and thorough [documentation](https://laravel.com/docs) and video tutorial library of all modern web application frameworks, making it a breeze to get started with the framework.

In addition, [Laracasts](https://laracasts.com) contains thousands of video tutorials on a range of topics including Laravel, modern PHP, unit testing, and JavaScript. Boost your skills by digging into our comprehensive video library.

You can also watch bite-sized lessons with real-world projects on [Laravel Learn](https://laravel.com/learn), where you will be guided through building a Laravel application from scratch while learning PHP fundamentals.

## Agentic Development

Laravel's predictable structure and conventions make it ideal for AI coding agents like Claude Code, Cursor, and GitHub Copilot. Install [Laravel Boost](https://laravel.com/docs/ai) to supercharge your AI workflow:

```bash
composer require laravel/boost --dev

php artisan boost:install
```

Boost provides your agent 15+ tools and skills that help agents build Laravel applications while following best practices.

## Contributing

Thank you for considering contributing to the Laravel framework! The contribution guide can be found in the [Laravel documentation](https://laravel.com/docs/contributions).

## Code of Conduct

In order to ensure that the Laravel community is welcoming to all, please review and abide by the [Code of Conduct](https://laravel.com/docs/contributions#code-of-conduct).

## Security Vulnerabilities

If you discover a security vulnerability within Laravel, please send an e-mail to Taylor Otwell via [taylor@laravel.com](mailto:taylor@laravel.com). All security vulnerabilities will be promptly addressed.

## License

The Laravel framework is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).
