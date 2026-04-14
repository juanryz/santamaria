<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

return new class extends Migration
{
    public function up(): void
    {
        $metrics = [
            // All internal roles — attendance
            ['ATT_DAILY_RATE', 'Tingkat Kehadiran Harian', 'service_officer', 'daily_attendances', 'percentage', '% hari hadir vs hari kerja', 'persen', 95, 'higher_is_better', 10],
            ['ATT_DAILY_RATE_GDG', 'Tingkat Kehadiran Harian', 'gudang', 'daily_attendances', 'percentage', '% hari hadir', 'persen', 95, 'higher_is_better', 10],
            ['ATT_DAILY_RATE_DRV', 'Tingkat Kehadiran Harian', 'driver', 'daily_attendances', 'percentage', '% hari hadir', 'persen', 95, 'higher_is_better', 10],
            ['ATT_DAILY_RATE_PRC', 'Tingkat Kehadiran Harian', 'purchasing', 'daily_attendances', 'percentage', '% hari hadir', 'persen', 95, 'higher_is_better', 10],

            // Punctuality
            ['ATT_PUNCTUALITY', 'Ketepatan Waktu Hadir', 'service_officer', 'daily_attendances', 'percentage', '% hadir tepat waktu', 'persen', 90, 'higher_is_better', 5],
            ['ATT_PUNCTUALITY_DRV', 'Ketepatan Waktu Hadir', 'driver', 'daily_attendances', 'percentage', '% hadir tepat waktu', 'persen', 90, 'higher_is_better', 5],

            // Driver vehicle
            ['DRV_INSPECTION_RATE', 'Tingkat Inspeksi Harian', 'driver', 'vehicle_inspections', 'percentage', '% hari dengan pre-trip inspection', 'persen', 95, 'higher_is_better', 10],
            ['DRV_FUEL_EFFICIENCY', 'Efisiensi BBM', 'driver', 'vehicle_fuel_logs', 'average', 'Rata-rata km/liter', 'km/l', 8, 'higher_is_better', 5],
            ['DRV_KM_LOG_COMPLIANCE', 'Kepatuhan Log KM', 'driver', 'vehicle_km_logs', 'percentage', '% hari dengan foto KM start+end', 'persen', 100, 'higher_is_better', 5],

            // Mock detection (all roles, should be 0)
            ['ATT_MOCK_ATTEMPTS', 'Percobaan Lokasi Palsu', 'driver', 'daily_attendances', 'inverse_count', 'Jumlah mock GPS terdeteksi', 'kali', 0, 'lower_is_better', 5],
        ];

        foreach ($metrics as $i => $m) {
            DB::table('kpi_metric_master')->insertOrIgnore([
                'id' => Str::uuid(),
                'metric_code' => $m[0], 'metric_name' => $m[1],
                'applicable_role' => $m[2], 'data_source' => $m[3],
                'calculation_type' => $m[4], 'calculation_query' => $m[5],
                'unit' => $m[6], 'target_value' => $m[7],
                'target_direction' => $m[8], 'weight' => $m[9],
                'sort_order' => 100 + $i, 'is_active' => true,
                'created_at' => now(), 'updated_at' => now(),
            ]);
        }

        // violation_type is varchar(255) — new types are simply string values.
        // Tracked in App\Enums\ViolationType PHP enum for code validation.
    }

    public function down(): void
    {
        DB::table('kpi_metric_master')->whereIn('metric_code', [
            'ATT_DAILY_RATE', 'ATT_DAILY_RATE_GDG', 'ATT_DAILY_RATE_DRV', 'ATT_DAILY_RATE_PRC',
            'ATT_PUNCTUALITY', 'ATT_PUNCTUALITY_DRV',
            'DRV_INSPECTION_RATE', 'DRV_FUEL_EFFICIENCY', 'DRV_KM_LOG_COMPLIANCE', 'ATT_MOCK_ATTEMPTS',
        ])->delete();
    }
};
