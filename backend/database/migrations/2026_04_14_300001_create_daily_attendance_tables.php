<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Master geofence locations
        Schema::create('attendance_locations', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('name', 255);
            $table->text('address');
            $table->decimal('latitude', 10, 8);
            $table->decimal('longitude', 11, 8);
            $table->integer('radius_meters')->default(100);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // Master work shifts
        Schema::create('work_shifts', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('shift_name', 100);
            $table->time('start_time');
            $table->time('end_time');
            $table->integer('late_tolerance_minutes')->default(15);
            $table->integer('early_leave_tolerance_minutes')->default(15);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // Shift assignments per user
        Schema::create('user_shift_assignments', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('user_id');
            $table->uuid('shift_id');
            $table->uuid('location_id');
            $table->date('effective_from');
            $table->date('effective_until')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users');
            $table->foreign('shift_id')->references('id')->on('work_shifts');
            $table->foreign('location_id')->references('id')->on('attendance_locations');
        });

        // Daily attendance records
        DB::statement("DO $$ BEGIN CREATE TYPE daily_attendance_status AS ENUM ('present','late','early_leave','absent','leave','holiday'); EXCEPTION WHEN duplicate_object THEN null; END $$");

        Schema::create('daily_attendances', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('user_id');
            $table->date('attendance_date');
            $table->uuid('shift_id')->nullable();
            $table->uuid('location_id')->nullable();

            // Clock in
            $table->timestamp('clock_in_at')->nullable();
            $table->decimal('clock_in_lat', 10, 8)->nullable();
            $table->decimal('clock_in_lng', 11, 8)->nullable();
            $table->integer('clock_in_distance_meters')->nullable();
            $table->text('clock_in_selfie_path')->nullable();

            // Clock out
            $table->timestamp('clock_out_at')->nullable();
            $table->decimal('clock_out_lat', 10, 8)->nullable();
            $table->decimal('clock_out_lng', 11, 8)->nullable();
            $table->integer('clock_out_distance_meters')->nullable();
            $table->text('clock_out_selfie_path')->nullable();

            // Duration
            $table->decimal('work_hours', 5, 2)->nullable();

            // Flags
            $table->boolean('is_mock_detected')->default(false);
            $table->text('mock_details')->nullable();
            $table->boolean('is_overridden')->default(false);
            $table->uuid('overridden_by')->nullable();
            $table->text('override_reason')->nullable();

            $table->text('notes')->nullable();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users');
            $table->foreign('shift_id')->references('id')->on('work_shifts');
            $table->foreign('location_id')->references('id')->on('attendance_locations');
            $table->foreign('overridden_by')->references('id')->on('users');
            $table->unique(['user_id', 'attendance_date']);
        });

        DB::statement("ALTER TABLE daily_attendances ADD COLUMN status daily_attendance_status NOT NULL DEFAULT 'absent'");

        // Audit log for all clock attempts
        Schema::create('attendance_logs', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('user_id');
            $table->string('action', 50); // clock_in, clock_out, mock_detected, override
            $table->decimal('latitude', 10, 8)->nullable();
            $table->decimal('longitude', 11, 8)->nullable();
            $table->integer('distance_meters')->nullable();
            $table->boolean('is_within_radius')->nullable();
            $table->boolean('is_mock')->default(false);
            $table->string('device_info', 255)->nullable();
            $table->text('details')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->foreign('user_id')->references('id')->on('users');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('attendance_logs');
        Schema::dropIfExists('daily_attendances');
        Schema::dropIfExists('user_shift_assignments');
        Schema::dropIfExists('work_shifts');
        Schema::dropIfExists('attendance_locations');
        DB::statement("DROP TYPE IF EXISTS daily_attendance_status");
    }
};
