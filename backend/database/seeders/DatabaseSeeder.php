<?php

namespace Database\Seeders;

use App\Enums\UserRole;
use App\Models\AddOnService;
use App\Models\ConsumerStorageQuota;
use App\Models\Package;
use App\Models\PackageItem;
use App\Models\StockItem;
use App\Models\SystemSetting;
use App\Models\SystemThreshold;
use App\Models\User;
use App\Models\Vehicle;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // ─────────────────────────────────────────────────────────────────
        // 1. USERS — semua role
        // Login konsumen  : POST /auth/login-consumer  (phone + pin)
        // Login personel  : POST /auth/login-internal  (phone/email + password)
        // ─────────────────────────────────────────────────────────────────

        // ── Catatan: password & pin TIDAK dibungkus Hash::make() ──────────────
        // Model User punya cast 'password' => 'hashed' dan 'pin' => 'hashed'
        // sehingga hashing otomatis dilakukan saat assignment.
        // Memanggil Hash::make() sebelum assign = double hash = login gagal.

        // Super Admin
        User::create([
            'name'      => 'Super Admin',
            'phone'     => '08100000000',
            'email'     => 'superadmin@santamaria.id',
            'role'      => UserRole::SUPER_ADMIN->value,
            'password'  => 'superadmin123',
            'is_active' => true,
            'is_viewer' => false,
        ]);

        // Admin (legacy — tidak digunakan di v1.8+ tapi tetap ada untuk backward compat)
        User::create([
            'name'      => 'Admin Santa Maria',
            'phone'     => '08100000001',
            'email'     => 'admin@santamaria.id',
            'role'      => UserRole::ADMIN->value,
            'password'  => 'admin123',
            'is_active' => true,
        ]);

        // Owner
        User::create([
            'name'      => 'Owner Santa Maria',
            'phone'     => '08100000002',
            'email'     => 'owner@santamaria.id',
            'role'      => UserRole::OWNER->value,
            'password'  => 'owner123',
            'is_active' => true,
        ]);

        // Service Officer — Lapangan
        User::create([
            'name'       => 'Budi SO Lapangan',
            'phone'      => '08100000003',
            'email'      => 'so@santamaria.id',
            'role'       => UserRole::SERVICE_OFFICER->value,
            'password'   => 'so123456',
            'is_active'  => true,
            'so_channel' => 'field',
        ]);

        // Service Officer — Kantor
        User::create([
            'name'       => 'Kantor Santa Maria',
            'phone'      => '08100000013',
            'email'      => 'sokantor@santamaria.id',
            'role'       => UserRole::SERVICE_OFFICER->value,
            'password'   => 'sokantor123',
            'is_active'  => true,
            'so_channel' => 'office',
        ]);

        // Gudang
        User::create([
            'name'      => 'Gerry Gudang',
            'phone'     => '08100000004',
            'email'     => 'gudang@santamaria.id',
            'role'      => UserRole::GUDANG->value,
            'password'  => 'gudang123',
            'is_active' => true,
        ]);

        // Finance
        User::create([
            'name'      => 'Siti Finance',
            'phone'     => '08100000005',
            'email'     => 'finance@santamaria.id',
            'role'      => UserRole::FINANCE->value,
            'password'  => 'finance123',
            'is_active' => true,
        ]);

        // Driver
        User::create([
            'name'      => 'Anto Driver',
            'phone'     => '08100000006',
            'email'     => 'driver@santamaria.id',
            'role'      => UserRole::DRIVER->value,
            'password'  => 'driver123',
            'is_active' => true,
        ]);

        // Supplier 1
        User::create([
            'name'                 => 'CV Maju Jaya',
            'phone'                => '08100000007',
            'email'                => 'supplier@santamaria.id',
            'role'                 => UserRole::SUPPLIER->value,
            'password'             => 'supplier123',
            'is_active'            => true,
            'is_verified_supplier' => true,
        ]);

        // Supplier 2
        User::create([
            'name'                 => 'UD Sinar Baru',
            'phone'                => '08100000017',
            'email'                => 'supplier2@santamaria.id',
            'role'                 => UserRole::SUPPLIER->value,
            'password'             => 'supplier123',
            'is_active'            => true,
            'is_verified_supplier' => true,
        ]);

        // Dekor
        User::create([
            'name'      => 'Laviore Dekor',
            'phone'     => '08100000008',
            'email'     => 'dekor@santamaria.id',
            'role'      => UserRole::DEKOR->value,
            'password'  => 'dekor123',
            'is_active' => true,
        ]);

        // Konsumsi
        User::create([
            'name'      => 'Katering Konsumsi',
            'phone'     => '08100000009',
            'email'     => 'konsumsi@santamaria.id',
            'role'      => UserRole::KONSUMSI->value,
            'password'  => 'konsumsi123',
            'is_active' => true,
        ]);

        // Pemuka Agama
        User::create([
            'name'      => 'Romo Petrus',
            'phone'     => '08100000010',
            'email'     => 'pemuka@santamaria.id',
            'role'      => UserRole::PEMUKA_AGAMA->value,
            'password'  => 'pemuka123',
            'is_active' => true,
            'religion'  => 'katolik',
        ]);

        // HRD — v1.10
        User::create([
            'name'      => 'Hendra HRD',
            'phone'     => '08100000012',
            'email'     => 'hrd@santamaria.id',
            'role'      => UserRole::HRD->value,
            'password'  => 'hrd123456',
            'is_active' => true,
        ]);

        // Tukang Foto — v1.14
        User::create([
            'name'      => 'Benny Fotografer',
            'phone'     => '08100000014',
            'email'     => 'foto@santamaria.id',
            'role'      => UserRole::TUKANG_FOTO->value,
            'password'  => 'foto1234',
            'is_active' => true,
        ]);

        // Purchasing — v1.14
        User::create([
            'name'      => 'Purchasing Santa Maria',
            'phone'     => '08100000015',
            'email'     => 'purchasing@santamaria.id',
            'role'      => UserRole::PURCHASING->value,
            'password'  => 'purchasing123',
            'is_active' => true,
        ]);

        // Koordinator Tukang Angkat Peti
        User::create([
            'name'      => 'Koordinator Angkat Peti',
            'phone'     => '08100000016',
            'email'     => 'angkatpeti@santamaria.id',
            'role'      => UserRole::TUKANG_ANGKAT_PETI->value,
            'password'  => 'angkatpeti123',
            'is_active' => true,
        ]);

        // Viewer — v1.14
        User::create([
            'name'      => 'Viewer Laporan',
            'phone'     => '08100000018',
            'email'     => 'viewer@santamaria.id',
            'role'      => UserRole::VIEWER->value,
            'password'  => 'viewer123',
            'is_active' => true,
            'is_viewer' => true,
        ]);

        // Consumer (login HP + PIN)
        $consumer = User::create([
            'name'      => 'Keluarga Bpk. Yohanes',
            'phone'     => '08199999999',
            'role'      => UserRole::CONSUMER->value,
            'pin'       => '1234',
            'is_active' => true,
        ]);

        ConsumerStorageQuota::create([
            'user_id'     => $consumer->id,
            'quota_bytes' => 1 * 1024 * 1024 * 1024, // 1 GB
            'used_bytes'  => 0,
        ]);

        // ─────────────────────────────────────────────────────────────────
        // 2. SYSTEM SETTINGS
        // ─────────────────────────────────────────────────────────────────
        $settings = [
            ['key' => 'price_anomaly_threshold_pct',   'value' => '20',    'description' => 'Threshold anomali harga dalam persen'],
            ['key' => 'consumer_storage_quota_gb',      'value' => '1',     'description' => 'Kuota storage konsumen dalam GB'],
            ['key' => 'session_duration_days',          'value' => '30',    'description' => 'Durasi sesi login dalam hari'],
            ['key' => 'pemuka_agama_timeout_minutes',   'value' => '30',    'description' => 'Timeout konfirmasi pemuka agama dalam menit'],
            ['key' => 'geofence_radius_meters',         'value' => '100',   'description' => 'Radius geofence dalam meter'],
            ['key' => 'daily_report_time',              'value' => '21:00', 'description' => 'Jam pengiriman laporan harian ke owner'],
        ];

        foreach ($settings as $setting) {
            SystemSetting::firstOrCreate(['key' => $setting['key']], $setting);
        }

        // ─────────────────────────────────────────────────────────────────
        // 3. VEHICLES
        // ─────────────────────────────────────────────────────────────────
        Vehicle::create(['model' => 'Alphard Hearse Silver', 'plate_number' => 'B 1234 SM', 'capacity' => 1, 'is_active' => true]);
        Vehicle::create(['model' => 'Starex Mover Black',    'plate_number' => 'B 5678 SM', 'capacity' => 1, 'is_active' => true]);

        // ─────────────────────────────────────────────────────────────────
        // 4. STOCK ITEMS — inventori gudang dengan stok awal yang cukup
        // ─────────────────────────────────────────────────────────────────
        $stiPetiStandar = StockItem::create([
            'item_name'        => 'Peti Standar',
            'category'         => 'peti',
            'current_quantity' => 10,
            'minimum_quantity' => 2,
            'unit'             => 'pcs',
        ]);
        $stiPetiMahoni = StockItem::create([
            'item_name'        => 'Peti Mahoni',
            'category'         => 'peti',
            'current_quantity' => 8,
            'minimum_quantity' => 2,
            'unit'             => 'pcs',
        ]);
        $stiPetiJati = StockItem::create([
            'item_name'        => 'Peti Ukir Jati Premium',
            'category'         => 'peti',
            'current_quantity' => 5,
            'minimum_quantity' => 1,
            'unit'             => 'pcs',
        ]);
        $stiKainKafan = StockItem::create([
            'item_name'        => 'Kain Kafan',
            'category'         => 'kain',
            'current_quantity' => 30,
            'minimum_quantity' => 5,
            'unit'             => 'lembar',
        ]);
        $stiBungaPapan = StockItem::create([
            'item_name'        => 'Bunga Papan',
            'category'         => 'bunga',
            'current_quantity' => 15,
            'minimum_quantity' => 3,
            'unit'             => 'set',
        ]);
        $stiBungaSegar = StockItem::create([
            'item_name'        => 'Bunga Segar Full',
            'category'         => 'bunga',
            'current_quantity' => 10,
            'minimum_quantity' => 2,
            'unit'             => 'set',
        ]);
        $stiDupaTapers = StockItem::create([
            'item_name'        => 'Lilin & Dupa Set',
            'category'         => 'perlengkapan_ibadah',
            'current_quantity' => 50,
            'minimum_quantity' => 10,
            'unit'             => 'set',
        ]);
        $stiSabunMandi = StockItem::create([
            'item_name'        => 'Perlengkapan Pemandian',
            'category'         => 'perlengkapan_fisik',
            'current_quantity' => 20,
            'minimum_quantity' => 5,
            'unit'             => 'set',
        ]);
        $stiPlasticBag = StockItem::create([
            'item_name'        => 'Kantong Jenazah',
            'category'         => 'perlengkapan_fisik',
            'current_quantity' => 25,
            'minimum_quantity' => 5,
            'unit'             => 'pcs',
        ]);

        // ─────────────────────────────────────────────────────────────────
        // 5. PACKAGES — dengan link ke stock items
        // ─────────────────────────────────────────────────────────────────
        $p1 = Package::create(['name' => 'Paket Silver (Ekonomis)', 'description' => 'Layanan pemakaman lengkap dengan harga terjangkau.', 'base_price' => 5000000,  'is_active' => true]);
        $p2 = Package::create(['name' => 'Paket Gold (Standar)',    'description' => 'Layanan pemakaman standar dengan dekorasi dan katering.', 'base_price' => 15000000, 'is_active' => true]);
        $p3 = Package::create(['name' => 'Paket Platinum (VVIP)',   'description' => 'Layanan pemakaman VVIP premium, lengkap dan berkesan.', 'base_price' => 50000000, 'is_active' => true]);

        // Paket Silver
        PackageItem::create(['package_id' => $p1->id, 'item_name' => 'Peti Standar',            'quantity' => 1, 'unit' => 'pcs',    'category' => 'gudang',       'stock_item_id' => $stiPetiStandar->id]);
        PackageItem::create(['package_id' => $p1->id, 'item_name' => 'Kain Kafan',               'quantity' => 3, 'unit' => 'lembar', 'category' => 'gudang',       'stock_item_id' => $stiKainKafan->id]);
        PackageItem::create(['package_id' => $p1->id, 'item_name' => 'Perlengkapan Pemandian',   'quantity' => 1, 'unit' => 'set',    'category' => 'gudang',       'stock_item_id' => $stiSabunMandi->id]);
        PackageItem::create(['package_id' => $p1->id, 'item_name' => 'Kantong Jenazah',          'quantity' => 1, 'unit' => 'pcs',    'category' => 'gudang',       'stock_item_id' => $stiPlasticBag->id]);
        PackageItem::create(['package_id' => $p1->id, 'item_name' => 'Pemandian Jenazah',        'quantity' => 1, 'unit' => 'sesi',   'category' => 'dekor',        'stock_item_id' => null]);
        PackageItem::create(['package_id' => $p1->id, 'item_name' => 'Mobil Jenazah Starex',     'quantity' => 1, 'unit' => 'trip',   'category' => 'transportasi', 'stock_item_id' => null]);

        // Paket Gold
        PackageItem::create(['package_id' => $p2->id, 'item_name' => 'Peti Mahoni',              'quantity' => 1, 'unit' => 'pcs',    'category' => 'gudang',       'stock_item_id' => $stiPetiMahoni->id]);
        PackageItem::create(['package_id' => $p2->id, 'item_name' => 'Kain Kafan',               'quantity' => 3, 'unit' => 'lembar', 'category' => 'gudang',       'stock_item_id' => $stiKainKafan->id]);
        PackageItem::create(['package_id' => $p2->id, 'item_name' => 'Perlengkapan Pemandian',   'quantity' => 1, 'unit' => 'set',    'category' => 'gudang',       'stock_item_id' => $stiSabunMandi->id]);
        PackageItem::create(['package_id' => $p2->id, 'item_name' => 'Kantong Jenazah',          'quantity' => 1, 'unit' => 'pcs',    'category' => 'gudang',       'stock_item_id' => $stiPlasticBag->id]);
        PackageItem::create(['package_id' => $p2->id, 'item_name' => 'Lilin & Dupa Set',         'quantity' => 2, 'unit' => 'set',    'category' => 'gudang',       'stock_item_id' => $stiDupaTapers->id]);
        PackageItem::create(['package_id' => $p2->id, 'item_name' => 'Bunga Papan',              'quantity' => 1, 'unit' => 'set',    'category' => 'dekor',        'stock_item_id' => $stiBungaPapan->id]);
        PackageItem::create(['package_id' => $p2->id, 'item_name' => 'Dekorasi Bunga Standar',   'quantity' => 1, 'unit' => 'set',    'category' => 'dekor',        'stock_item_id' => null]);
        PackageItem::create(['package_id' => $p2->id, 'item_name' => 'Katering 50 Pax',          'quantity' => 1, 'unit' => 'paket',  'category' => 'konsumsi',     'stock_item_id' => null]);
        PackageItem::create(['package_id' => $p2->id, 'item_name' => 'Mobil Jenazah Starex',     'quantity' => 1, 'unit' => 'trip',   'category' => 'transportasi', 'stock_item_id' => null]);

        // Paket Platinum
        PackageItem::create(['package_id' => $p3->id, 'item_name' => 'Peti Ukir Jati Premium',   'quantity' => 1, 'unit' => 'pcs',    'category' => 'gudang',       'stock_item_id' => $stiPetiJati->id]);
        PackageItem::create(['package_id' => $p3->id, 'item_name' => 'Kain Kafan',               'quantity' => 5, 'unit' => 'lembar', 'category' => 'gudang',       'stock_item_id' => $stiKainKafan->id]);
        PackageItem::create(['package_id' => $p3->id, 'item_name' => 'Perlengkapan Pemandian',   'quantity' => 1, 'unit' => 'set',    'category' => 'gudang',       'stock_item_id' => $stiSabunMandi->id]);
        PackageItem::create(['package_id' => $p3->id, 'item_name' => 'Kantong Jenazah',          'quantity' => 1, 'unit' => 'pcs',    'category' => 'gudang',       'stock_item_id' => $stiPlasticBag->id]);
        PackageItem::create(['package_id' => $p3->id, 'item_name' => 'Lilin & Dupa Set',         'quantity' => 5, 'unit' => 'set',    'category' => 'gudang',       'stock_item_id' => $stiDupaTapers->id]);
        PackageItem::create(['package_id' => $p3->id, 'item_name' => 'Bunga Segar Full',         'quantity' => 3, 'unit' => 'set',    'category' => 'dekor',        'stock_item_id' => $stiBungaSegar->id]);
        PackageItem::create(['package_id' => $p3->id, 'item_name' => 'Dekorasi Bunga Segar Full','quantity' => 1, 'unit' => 'set',    'category' => 'dekor',        'stock_item_id' => null]);
        PackageItem::create(['package_id' => $p3->id, 'item_name' => 'Catering VVIP 100 Pax',   'quantity' => 1, 'unit' => 'paket',  'category' => 'konsumsi',     'stock_item_id' => null]);
        PackageItem::create(['package_id' => $p3->id, 'item_name' => 'Mobil Jenazah Alphard',    'quantity' => 1, 'unit' => 'trip',   'category' => 'transportasi', 'stock_item_id' => null]);

        // ─────────────────────────────────────────────────────────────────
        // 6. ADD-ON SERVICES
        // ─────────────────────────────────────────────────────────────────
        AddOnService::create(['name' => 'Dokumentasi Foto & Video', 'description' => 'Dokumentasi profesional selama prosesi.', 'price' => 2500000, 'is_active' => true]);
        AddOnService::create(['name' => 'Live Streaming',           'description' => 'Siaran langsung untuk keluarga yang tidak bisa hadir.', 'price' => 1500000, 'is_active' => true]);
        AddOnService::create(['name' => 'Bunga Tambahan',           'description' => 'Set bunga dekorasi tambahan.', 'price' => 500000, 'is_active' => true]);
        AddOnService::create(['name' => 'Koordinasi Pemakaman',     'description' => 'Koordinator lapangan tambahan.', 'price' => 750000, 'is_active' => true]);

        // ─────────────────────────────────────────────────────────────────
        // 7. SYSTEM THRESHOLDS — semua nilai operasional yang bisa dikonfigurasi
        // ─────────────────────────────────────────────────────────────────
        $thresholds = [
            ['key' => 'driver_max_duty_hours',                  'value' => 12,  'unit' => 'hours',   'description' => 'Maksimal jam kerja driver per shift sebelum alarm HRD'],
            ['key' => 'so_max_processing_minutes',              'value' => 30,  'unit' => 'minutes', 'description' => 'Batas waktu SO konfirmasi order sebelum alarm HRD'],
            ['key' => 'vendor_max_reject_count_monthly',        'value' => 3,   'unit' => 'count',   'description' => 'Maksimal penolakan tugas vendor per bulan sebelum alarm HRD'],
            ['key' => 'bukti_upload_deadline_hours',            'value' => 2,   'unit' => 'hours',   'description' => 'Batas waktu upload bukti foto setelah order selesai'],
            ['key' => 'payment_verify_deadline_hours',          'value' => 24,  'unit' => 'hours',   'description' => 'Batas waktu Finance verifikasi bukti payment konsumen'],
            ['key' => 'field_team_payment_deadline_hours',      'value' => 48,  'unit' => 'hours',   'description' => 'Batas waktu Finance bayar upah tim lapangan setelah order selesai'],
            ['key' => 'order_completion_tolerance_hours',       'value' => 2,   'unit' => 'hours',   'description' => 'Toleransi waktu melebihi estimasi sebelum alarm Owner dikirim'],
            ['key' => 'consumer_payment_reminder_interval_hours', 'value' => 24, 'unit' => 'hours',  'description' => 'Interval kirim reminder payment ke consumer setelah order selesai'],
            ['key' => 'consumer_payment_reminder_max_count',    'value' => 3,   'unit' => 'count',   'description' => 'Maksimal jumlah reminder payment yang dikirim ke consumer'],
        ];

        foreach ($thresholds as $t) {
            SystemThreshold::firstOrCreate(['key' => $t['key']], $t);
        }

        // ─────────────────────────────────────────────────────────────────
        // 8. v1.14 — MASTER DATA & KPI METRICS
        // ─────────────────────────────────────────────────────────────────
        $this->call([
            MasterDataV114Seeder::class,
            KpiMetricSeeder::class,
            MasterDataV117Seeder::class,
            AttendanceVehicleSeeder::class,
            V140Seeder::class,
        ]);
    }
}
