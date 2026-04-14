<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('system_settings', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('key', 100)->unique();
            $table->text('value');
            $table->text('description')->nullable();
            $table->uuid('updated_by')->nullable();
            $table->timestamp('updated_at')->nullable();

            $table->foreign('updated_by')->references('id')->on('users');
        });

        // Insert default settings
        DB::table('system_settings')->insert([
            ['id' => DB::raw('gen_random_uuid()'), 'key' => 'price_anomaly_threshold_pct', 'value' => '20', 'description' => 'Threshold percentage for AI price anomaly detection'],
            ['id' => DB::raw('gen_random_uuid()'), 'key' => 'consumer_storage_quota_gb', 'value' => '1', 'description' => 'Default storage quota in GB for consumers'],
            ['id' => DB::raw('gen_random_uuid()'), 'key' => 'session_duration_days', 'value' => '30', 'description' => 'Session duration in days'],
            ['id' => DB::raw('gen_random_uuid()'), 'key' => 'pemuka_agama_timeout_minutes', 'value' => '30', 'description' => 'Timeout in minutes for pemuka agama confirmation'],
            ['id' => DB::raw('gen_random_uuid()'), 'key' => 'geofence_radius_meters', 'value' => '100', 'description' => 'Geofence radius in meters for driver GPS tracking'],
            ['id' => DB::raw('gen_random_uuid()'), 'key' => 'daily_report_time', 'value' => '21:00', 'description' => 'Time to send daily report to owner'],
        ]);
    }

    public function down(): void
    {
        Schema::dropIfExists('system_settings');
    }
};
