<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $thresholds = [
            // KPI grading
            ['key' => 'kpi_grade_a_min', 'value' => '90', 'unit' => 'score', 'description' => 'Skor minimum untuk grade A'],
            ['key' => 'kpi_grade_b_min', 'value' => '75', 'unit' => 'score', 'description' => 'Skor minimum untuk grade B'],
            ['key' => 'kpi_grade_c_min', 'value' => '60', 'unit' => 'score', 'description' => 'Skor minimum untuk grade C'],
            ['key' => 'kpi_grade_d_min', 'value' => '40', 'unit' => 'score', 'description' => 'Skor minimum untuk grade D'],

            // Driver
            ['key' => 'driver_max_orders_per_day', 'value' => '3', 'unit' => 'count', 'description' => 'Maksimal order per driver per hari'],

            // Consumer payment
            ['key' => 'payment_proof_max_size_mb', 'value' => '5', 'unit' => 'MB', 'description' => 'Ukuran maksimal foto bukti transfer (MB)'],

            // Stock
            ['key' => 'stock_low_multiplier', 'value' => '1.5', 'unit' => 'multiplier', 'description' => 'Multiplier minimum_quantity untuk alert low_stock'],

            // Vendor
            ['key' => 'vendor_max_concurrent_orders', 'value' => '2', 'unit' => 'count', 'description' => 'Maks order bersamaan per vendor'],

            // AI
            ['key' => 'ai_price_variance_warning_pct', 'value' => '10', 'unit' => 'percent', 'description' => 'Batas % variance harga supplier sebelum badge kuning'],
            ['key' => 'ai_price_variance_anomaly_pct', 'value' => '20', 'unit' => 'percent', 'description' => 'Batas % variance harga supplier sebelum badge merah'],

            // Order
            ['key' => 'order_auto_complete_buffer_hours', 'value' => '2', 'unit' => 'hours', 'description' => 'Buffer jam setelah estimasi selesai sebelum auto-complete'],
            ['key' => 'order_max_extension_hours', 'value' => '24', 'unit' => 'hours', 'description' => 'Maks perpanjangan waktu order oleh SO'],

            // Procurement
            ['key' => 'procurement_quote_min_count', 'value' => '1', 'unit' => 'count', 'description' => 'Minimum penawaran sebelum Gudang bisa evaluasi'],
            ['key' => 'procurement_auto_close_days', 'value' => '7', 'unit' => 'days', 'description' => 'Otomatis tutup permintaan jika belum ada pemenang setelah X hari'],
        ];

        foreach ($thresholds as $t) {
            DB::table('system_thresholds')->insertOrIgnore($t);
        }
    }

    public function down(): void
    {
        DB::table('system_thresholds')->whereIn('key', [
            'kpi_grade_a_min', 'kpi_grade_b_min', 'kpi_grade_c_min', 'kpi_grade_d_min',
            'driver_max_orders_per_day', 'payment_proof_max_size_mb',
            'stock_low_multiplier', 'vendor_max_concurrent_orders',
            'ai_price_variance_warning_pct', 'ai_price_variance_anomaly_pct',
            'order_auto_complete_buffer_hours', 'order_max_extension_hours',
            'procurement_quote_min_count', 'procurement_auto_close_days',
        ])->delete();
    }
};
