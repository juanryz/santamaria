<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class MasterDataV117Seeder extends Seeder
{
    public function run(): void
    {
        $this->seedOrderStatusLabels();
        $this->seedTripLegMaster();
        $this->seedVendorRoleMaster();
        $this->seedWaTemplates();
        $this->seedTermsAndConditions();
    }

    private function seedOrderStatusLabels(): void
    {
        $labels = [
            ['pending', 'Order Diterima', 'Pesanan Anda telah kami terima', 'Pending', 'hourglass_empty', '#B2BEC3', 1, true, false],
            ['confirmed', 'Dikonfirmasi', 'Layanan telah dikonfirmasi', 'Confirmed', 'check_circle', '#00B894', 2, true, false],
            ['preparing', 'Menyiapkan Perlengkapan', 'Tim gudang sedang menyiapkan', 'Preparing', 'inventory', '#6C5CE7', 3, true, false],
            ['ready_to_dispatch', 'Siap Dikirim', 'Perlengkapan siap', 'Ready', 'local_shipping', '#00CEC9', 4, true, false],
            ['driver_assigned', 'Driver Ditugaskan', 'Driver siap berangkat', 'Driver Assigned', 'directions_car', '#2D3436', 5, true, true],
            ['delivering_equipment', 'Perlengkapan Dalam Perjalanan', 'Perlengkapan dalam perjalanan', 'Delivering Equipment', 'local_shipping', '#0984E3', 6, true, true],
            ['equipment_arrived', 'Perlengkapan Tiba', 'Perlengkapan telah tiba', 'Equipment Arrived', 'place', '#00B894', 7, true, false],
            ['picking_up_body', 'Menjemput Jenazah', 'Driver menuju lokasi jemput', 'Picking Up', 'directions_car', '#E84393', 8, true, true],
            ['body_arrived', 'Jenazah Tiba', 'Jenazah telah tiba', 'Body Arrived', 'sentiment_satisfied', '#6D4C41', 9, true, false],
            ['in_ceremony', 'Prosesi Berlangsung', 'Prosesi sedang berlangsung', 'In Ceremony', 'church', '#6C5CE7', 10, true, false],
            ['heading_to_burial', 'Menuju Pemakaman', 'Rombongan menuju pemakaman', 'Heading to Burial', 'directions_car', '#2D3436', 11, true, true],
            ['burial_completed', 'Pemakaman Selesai', 'Prosesi pemakaman selesai', 'Burial Done', 'done_all', '#636E72', 12, true, false],
            ['returning_equipment', 'Pengembalian Peralatan', 'Peralatan dikembalikan', 'Returning', 'replay', '#B2BEC3', 13, false, false],
            ['completed', 'Layanan Selesai', 'Seluruh layanan selesai', 'Completed', 'star', '#00B894', 14, true, false],
            ['cancelled', 'Dibatalkan', 'Pesanan dibatalkan', 'Cancelled', 'cancel', '#D63031', 15, true, false],
        ];

        foreach ($labels as [$code, $cLabel, $cDesc, $iLabel, $icon, $color, $sort, $showConsumer, $showMap]) {
            DB::table('order_status_labels')->insertOrIgnore([
                'id' => Str::uuid(), 'status_code' => $code,
                'consumer_label' => $cLabel, 'consumer_description' => $cDesc,
                'internal_label' => $iLabel, 'icon' => $icon, 'color' => $color,
                'sort_order' => $sort, 'show_to_consumer' => $showConsumer,
                'show_map_tracking' => $showMap, 'is_active' => true,
                'created_at' => now(), 'updated_at' => now(),
            ]);
        }
    }

    private function seedTripLegMaster(): void
    {
        $legs = [
            ['ANTAR_BARANG', 'Antar Barang/Perlengkapan', 'logistics', true, 'dekor_gate', 'local_shipping', 1],
            ['JEMPUT_JENAZAH', 'Jemput Jenazah', 'transport_jenazah', true, null, 'airline_seat_flat', 2],
            ['ANTAR_JENAZAH_RD', 'Antar Jenazah ke Rumah Duka', 'transport_jenazah', true, 'consumer_notify', 'directions_car', 3],
            ['ANTAR_JENAZAH_PMK', 'Antar Jenazah ke Pemakaman', 'transport_jenazah', true, 'consumer_notify', 'directions_car', 4],
            ['ANTAR_JENAZAH_KRM', 'Antar Jenazah ke Krematorium', 'transport_jenazah', true, 'consumer_notify', 'directions_car', 5],
            ['ANGKUT_KEMBALI', 'Angkut Barang Kembali ke Gudang', 'return', false, null, 'replay', 6],
            ['ANTAR_PERALATAN', 'Antar Peralatan Peringatan', 'logistics', false, null, 'build', 7],
            ['JEMPUT_JENAZAH_LUAR', 'Jemput Jenazah Luar Kota', 'transport_jenazah', true, 'consumer_notify', 'flight', 8],
            ['ANTAR_PETI', 'Antar Peti dari Workshop', 'logistics', false, null, 'inventory_2', 9],
        ];

        foreach ($legs as [$code, $name, $cat, $proof, $gate, $icon, $sort]) {
            DB::table('trip_leg_master')->insertOrIgnore([
                'id' => Str::uuid(), 'leg_code' => $code, 'leg_name' => $name,
                'category' => $cat, 'requires_proof_photo' => $proof,
                'triggers_gate' => $gate, 'icon' => $icon,
                'sort_order' => $sort, 'is_active' => true,
                'created_at' => now(), 'updated_at' => now(),
            ]);
        }
    }

    private function seedVendorRoleMaster(): void
    {
        $roles = [
            ['pemuka_agama', 'Pemuka Agama / Romo', 'religious', 'pemuka_agama', true, null, true, false],
            ['fotografer', 'Fotografer / Dokumentasi', 'documentation', 'tukang_foto', true, null, true, true],
            ['videografer', 'Videografer', 'documentation', null, false, null, true, true],
            ['dekorator', 'Dekorator / Bunga', 'decoration', 'dekor', true, null, true, true],
            ['katering', 'Katering / Konsumsi', 'catering', 'konsumsi', true, null, true, true],
            ['musisi', 'Musisi / Organis', 'music', null, false, null, true, false],
            ['paduan_suara', 'Paduan Suara / Koor', 'music', null, false, null, true, false],
            ['penggali_makam', 'Penggali Makam', 'other', null, false, null, false, false],
            ['mc', 'MC / Pembawa Acara', 'other', null, false, null, true, false],
            ['doa_malam', 'Pemimpin Doa Malam', 'religious', null, false, null, true, false],
        ];

        foreach ($roles as $i => [$code, $name, $cat, $appRole, $defPkg, $max, $att, $bukti]) {
            DB::table('vendor_role_master')->insertOrIgnore([
                'id' => Str::uuid(), 'role_code' => $code, 'role_name' => $name,
                'category' => $cat, 'app_role' => $appRole,
                'is_default_in_package' => $defPkg, 'max_per_order' => $max,
                'requires_attendance' => $att, 'requires_bukti_foto' => $bukti,
                'sort_order' => $i + 1, 'is_active' => true,
                'created_at' => now(), 'updated_at' => now(),
            ]);
        }
    }

    private function seedWaTemplates(): void
    {
        $templates = [
            ['ORDER_CONFIRMED_CONSUMER', 'Konfirmasi Order ke Consumer', 'consumer', 'SO konfirmasi order',
                "Kepada Yth. {consumer_name},\n\nTerima kasih telah mempercayakan layanan pemakaman kepada Santa Maria Funeral Organizer.\n\nKami turut berduka cita atas berpulangnya {almarhum_name}.\n\nDetail Layanan:\nNo. Order: {order_number}\nPaket: {package_name}\nJadwal: {scheduled_date}, pukul {scheduled_time} WIB\nLokasi: {location}\n\nHormat kami,\n{so_name}\nSanta Maria Funeral Organizer\n{office_phone}"],

            ['VENDOR_ASSIGNMENT', 'Penugasan Vendor', 'vendor_external', 'Vendor di-assign ke order',
                "Yth. {vendor_name},\n\nAnda ditugaskan untuk layanan pemakaman:\nNo. Order: {order_number}\nAlmarhum: {almarhum_name}\nTanggal: {scheduled_date}\nWaktu: {scheduled_time} WIB\nLokasi: {location}\n\nMohon konfirmasi kehadiran.\n\nSanta Maria FO\n{office_phone}"],

            ['PAYMENT_REMINDER', 'Reminder Pembayaran', 'consumer', 'Order selesai, belum bayar',
                "Yth. {consumer_name},\n\nLayanan pemakaman untuk Alm. {almarhum_name} telah selesai.\n\nSilakan lakukan pembayaran:\nNo. Order: {order_number}\nTotal: Rp {total_price}\n\nUpload bukti transfer melalui aplikasi Santa Maria.\n\nTerima kasih,\nSanta Maria FO"],

            ['DRIVER_DISPATCH', 'Notifikasi Driver Berangkat', 'consumer', 'Driver berangkat jemput',
                "Yth. {consumer_name},\n\nDriver kami {driver_name} dengan kendaraan {vehicle_model} ({plate_number}) sedang menuju lokasi.\n\nEstimasi tiba: {eta}\n\nAnda dapat melacak posisi driver melalui aplikasi Santa Maria.\n\nSanta Maria FO"],
        ];

        foreach ($templates as [$code, $name, $audience, $trigger, $message]) {
            DB::table('wa_message_templates')->insertOrIgnore([
                'id' => Str::uuid(), 'template_code' => $code,
                'template_name' => $name, 'target_audience' => $audience,
                'trigger_moment' => $trigger, 'message_template' => $message,
                'is_active' => true, 'created_at' => now(), 'updated_at' => now(),
            ]);
        }
    }

    private function seedTermsAndConditions(): void
    {
        DB::table('terms_and_conditions')->insertOrIgnore([
            'id' => Str::uuid(),
            'version' => '1.0',
            'title' => 'Syarat & Ketentuan Layanan Pemakaman Santa Maria',
            'content' => "SURAT PENERIMAAN LAYANAN KEMATIAN\n\nYang bertanda tangan di bawah ini (\"Pihak Pertama\" / Penanggung Jawab), dengan ini menyatakan menerima dan menyetujui layanan pemakaman yang diselenggarakan oleh CV Santa Maria Funeral Organizer (\"Pihak Kedua\") dengan ketentuan sebagai berikut:\n\n1. LINGKUP LAYANAN\nPihak Kedua akan menyediakan layanan pemakaman sesuai paket yang dipilih.\n\n2. BIAYA LAYANAN\na. Biaya layanan sesuai dengan paket dan add-on yang dipilih.\nb. Biaya tambahan memerlukan persetujuan tertulis.\nc. Pembayaran dilakukan setelah layanan selesai.\n\n3. TANGGUNG JAWAB\na. Pihak Kedua bertanggung jawab atas kelancaran prosesi.\nb. Pihak Pertama bertanggung jawab atas kebenaran data.\n\n4. FORCE MAJEURE\nKedua pihak dibebaskan dari tanggung jawab jika terjadi hal di luar kendali.",
            'effective_date' => '2026-01-01',
            'is_current' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }
}
