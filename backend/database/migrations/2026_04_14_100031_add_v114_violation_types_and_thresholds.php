<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // violation_type is varchar(255), not a PG enum — no ALTER TYPE needed.
        // New violation types are simply string values stored in the column.

        // Add new threshold seeds
        DB::table('system_thresholds')->insertOrIgnore([
            ['key' => 'attendance_radius_meters', 'value' => 500, 'unit' => 'meters', 'description' => 'Radius geofence check-in vendor/tukang_foto (meter)'],
            ['key' => 'attendance_checkin_early_minutes', 'value' => 120, 'unit' => 'minutes', 'description' => 'Boleh check-in maks X menit sebelum scheduled_at'],
            ['key' => 'attendance_late_threshold_minutes', 'value' => 30, 'unit' => 'minutes', 'description' => 'Jika belum check-in X menit setelah jadwal → alarm HRD'],
            ['key' => 'equipment_return_deadline_hours', 'value' => 24, 'unit' => 'hours', 'description' => 'Peralatan harus kembali dalam X jam setelah order selesai'],
            ['key' => 'coffin_qc_deadline_hours', 'value' => 48, 'unit' => 'hours', 'description' => 'Peti harus di-QC dalam X jam setelah finishing selesai'],
            ['key' => 'death_cert_deadline_hours', 'value' => 24, 'unit' => 'hours', 'description' => 'Berkas akta harus dibuat dalam X jam setelah order complete'],
        ]);

        // default_city is a string setting, not a numeric threshold — goes in system_settings
        DB::table('system_settings')->insertOrIgnore([
            'key' => 'default_city', 'value' => 'Semarang', 'description' => 'Kota default untuk form surat/approval',
        ]);
    }

    public function down(): void
    {
        DB::table('system_thresholds')->whereIn('key', [
            'attendance_radius_meters', 'attendance_checkin_early_minutes',
            'attendance_late_threshold_minutes', 'equipment_return_deadline_hours',
            'coffin_qc_deadline_hours', 'death_cert_deadline_hours', 'default_city',
        ])->delete();
    }
};
