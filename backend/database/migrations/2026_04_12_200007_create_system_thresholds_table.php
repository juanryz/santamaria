<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('system_thresholds', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('key', 100)->unique();
            $table->decimal('value', 10, 2);
            $table->string('unit', 50);   // 'hours', 'minutes', 'count', 'percent'
            $table->text('description');
            $table->uuid('updated_by')->nullable();
            $table->foreign('updated_by')->references('id')->on('users');
            $table->timestamp('updated_at')->nullable();
        });

        // Seed default thresholds
        DB::table('system_thresholds')->insert([
            ['key' => 'driver_max_duty_hours',           'value' => 12,  'unit' => 'hours',   'description' => 'Maksimal jam kerja driver per hari sebelum alarm HRD', 'updated_by' => null, 'updated_at' => now()],
            ['key' => 'so_max_processing_minutes',       'value' => 30,  'unit' => 'minutes', 'description' => 'Maksimal waktu SO konfirmasi order sebelum alarm HRD', 'updated_by' => null, 'updated_at' => now()],
            ['key' => 'vendor_max_reject_count_monthly', 'value' => 3,   'unit' => 'count',   'description' => 'Maksimal penolakan assignment vendor per bulan sebelum alarm HRD', 'updated_by' => null, 'updated_at' => now()],
            ['key' => 'bukti_upload_deadline_hours',     'value' => 2,   'unit' => 'hours',   'description' => 'Deadline upload bukti foto lapangan setelah order selesai', 'updated_by' => null, 'updated_at' => now()],
            ['key' => 'payment_verify_deadline_hours',   'value' => 24,  'unit' => 'hours',   'description' => 'Deadline Finance verifikasi bukti payment konsumen', 'updated_by' => null, 'updated_at' => now()],
            ['key' => 'field_team_payment_deadline_hours','value' => 48,  'unit' => 'hours',   'description' => 'Deadline Finance bayar upah tim lapangan setelah order selesai', 'updated_by' => null, 'updated_at' => now()],
            ['key' => 'consumer_payment_reminder_hours', 'value' => 24,  'unit' => 'hours',   'description' => 'Interval reminder ke consumer untuk upload bukti payment', 'updated_by' => null, 'updated_at' => now()],
        ]);
    }

    public function down(): void
    {
        Schema::dropIfExists('system_thresholds');
    }
};
