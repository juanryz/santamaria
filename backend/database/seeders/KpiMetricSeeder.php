<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class KpiMetricSeeder extends Seeder
{
    public function run(): void
    {
        $metrics = [
            // Service Officer
            ['SO_PROCESS_SPEED', 'Kecepatan Proses Order', 'service_officer', 'orders', 'average', 'AVG menit dari pending → confirmed', 'menit', 30, 'lower_is_better', 25],
            ['SO_ORDER_COUNT', 'Jumlah Order Dihandle', 'service_officer', 'orders', 'count', 'COUNT orders yang di-confirm SO ini', 'order', 20, 'higher_is_better', 20],
            ['SO_VIOLATION_COUNT', 'Jumlah Pelanggaran', 'service_officer', 'hrd_violations', 'inverse_count', 'COUNT violations oleh user ini', 'kali', 0, 'lower_is_better', 20],
            ['SO_ATTENDANCE_RATE', 'Tingkat Kehadiran', 'service_officer', 'field_attendances', 'percentage', '% hari hadir vs hari kerja', 'persen', 95, 'higher_is_better', 20],
            ['SO_EXTRA_APPROVAL', 'Persetujuan Tambahan Closed', 'service_officer', 'order_extra_approvals', 'count', 'COUNT approved per periode', 'kali', 5, 'higher_is_better', 15],

            // Gudang
            ['GDG_STOCK_READY_SPEED', 'Kecepatan Siapkan Stok', 'gudang', 'orders', 'average', 'AVG menit dari confirmed → stock_ready', 'menit', 60, 'lower_is_better', 25],
            ['GDG_EQUIPMENT_RETURN', 'Tingkat Pengembalian Peralatan', 'gudang', 'order_equipment_items', 'percentage', '% peralatan returned vs total', 'persen', 98, 'higher_is_better', 20],
            ['GDG_QC_PASS_RATE', 'Tingkat Lolos QC Peti', 'gudang', 'coffin_orders', 'percentage', '% peti lolos QC pertama kali', 'persen', 90, 'higher_is_better', 20],
            ['GDG_VIOLATION_COUNT', 'Jumlah Pelanggaran', 'gudang', 'hrd_violations', 'inverse_count', 'COUNT violations', 'kali', 0, 'lower_is_better', 15],
            ['GDG_PROCUREMENT_SPEED', 'Kecepatan Pengadaan', 'gudang', 'procurement_requests', 'average', 'AVG jam dari open → awarded', 'jam', 24, 'lower_is_better', 20],

            // Purchasing
            ['PRC_PAYMENT_VERIFY_SPEED', 'Kecepatan Verifikasi Payment', 'purchasing', 'orders', 'average', 'AVG jam dari proof_uploaded → verified', 'jam', 24, 'lower_is_better', 25],
            ['PRC_SUPPLIER_PAY_SPEED', 'Kecepatan Bayar Supplier', 'purchasing', 'supplier_transactions', 'average', 'AVG jam dari goods_received → paid', 'jam', 48, 'lower_is_better', 20],
            ['PRC_FIELD_PAY_SPEED', 'Kecepatan Bayar Tim Lapangan', 'purchasing', 'order_field_team_payments', 'average', 'AVG jam', 'jam', 48, 'lower_is_better', 20],
            ['PRC_VIOLATION_COUNT', 'Jumlah Pelanggaran', 'purchasing', 'hrd_violations', 'inverse_count', 'COUNT violations', 'kali', 0, 'lower_is_better', 15],
            ['PRC_APPROVAL_SPEED', 'Kecepatan Approval Pengadaan', 'purchasing', 'procurement_requests', 'average', 'AVG jam dari awarded → purchasing_approved', 'jam', 12, 'lower_is_better', 20],

            // Driver
            ['DRV_ONTIME_RATE', 'Tingkat Ketepatan Waktu', 'driver', 'orders', 'percentage', '% order tiba tepat waktu', 'persen', 95, 'higher_is_better', 25],
            ['DRV_TRIP_COUNT', 'Jumlah Trip', 'driver', 'vehicle_trip_logs', 'count', 'COUNT trips per bulan', 'trip', 15, 'higher_is_better', 20],
            ['DRV_OVERTIME_COUNT', 'Jumlah Overtime', 'driver', 'hrd_violations', 'inverse_count', 'COUNT overtime violations', 'kali', 0, 'lower_is_better', 20],
            ['DRV_EVIDENCE_RATE', 'Upload Bukti Lapangan', 'driver', 'order_bukti_lapangan', 'percentage', '% bukti diupload', 'persen', 100, 'higher_is_better', 20],
            ['DRV_VIOLATION_COUNT', 'Jumlah Pelanggaran', 'driver', 'hrd_violations', 'inverse_count', 'COUNT violations', 'kali', 0, 'lower_is_better', 15],
        ];

        foreach ($metrics as $i => $m) {
            DB::table('kpi_metric_master')->insertOrIgnore([
                'id' => Str::uuid(),
                'metric_code' => $m[0],
                'metric_name' => $m[1],
                'applicable_role' => $m[2],
                'data_source' => $m[3],
                'calculation_type' => $m[4],
                'calculation_query' => $m[5],
                'unit' => $m[6],
                'target_value' => $m[7],
                'target_direction' => $m[8],
                'weight' => $m[9],
                'sort_order' => $i + 1,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }
}
