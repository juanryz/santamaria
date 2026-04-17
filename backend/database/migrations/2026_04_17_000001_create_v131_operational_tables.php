<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

/**
 * v1.31-v1.35 — Tabel operasional dari klarifikasi owner:
 * - funeral_homes (database rumah duka)
 * - cemeteries (database pemakaman per kota)
 * - photo_evidences (bukti foto universal + geofencing)
 * - activity_logs (log aktivitas semua karyawan di app)
 * - employee_salaries (gaji pokok & performa)
 * - monthly_payroll (slip gaji bulanan)
 * - item_location_tracking (tracking barang antar lokasi, deteksi stuck)
 */
return new class extends Migration
{
    public function up(): void
    {
        // 1. Database Rumah Duka
        Schema::create('funeral_homes', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('name');
            $table->string('city', 100);
            $table->text('address')->nullable();
            $table->decimal('lat', 10, 7)->nullable();
            $table->decimal('lng', 10, 7)->nullable();
            $table->string('contact_phone', 30)->nullable();
            $table->string('contact_person')->nullable();
            $table->text('notes')->nullable();
            $table->integer('usage_count')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->index('city');
            $table->index('name');
            $table->index(['usage_count']);
        });

        // 2. Database Pemakaman per Kota
        Schema::create('cemeteries', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('name');
            $table->string('city', 100);
            $table->text('address')->nullable();
            $table->decimal('lat', 10, 7)->nullable();
            $table->decimal('lng', 10, 7)->nullable();
            $table->string('cemetery_type', 50)->default('umum'); // umum, khusus_agama, krematorium, taman_makam
            $table->string('contact_phone', 30)->nullable();
            $table->text('notes')->nullable();
            $table->integer('usage_count')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->index('city');
            $table->index('name');
            $table->index('cemetery_type');
        });

        // 3. Bukti Foto Universal + Geofencing
        Schema::create('photo_evidences', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('context', 100); // driver_pickup_goods, tukang_jaga_receive, attendance_clock_in, dll
            $table->foreignUuid('order_id')->nullable()->constrained('orders')->nullOnDelete();
            $table->foreignUuid('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('reference_type', 50)->nullable();
            $table->uuid('reference_id')->nullable();

            // File
            $table->text('file_path');
            $table->bigInteger('file_size_bytes')->nullable();
            $table->text('thumbnail_path')->nullable();

            // Geofencing (WAJIB)
            $table->decimal('latitude', 10, 7);
            $table->decimal('longitude', 10, 7);
            $table->decimal('accuracy_meters', 8, 2)->nullable();
            $table->decimal('altitude', 10, 2)->nullable();

            // Timestamp
            $table->timestamp('taken_at');
            $table->timestamp('server_received_at')->useCurrent();

            // Device
            $table->string('device_id');
            $table->string('device_model')->nullable();

            // Validasi
            $table->boolean('is_validated')->default(false);
            $table->foreignUuid('validated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->text('validation_notes')->nullable();

            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index('context');
            $table->index('order_id');
            $table->index('user_id');
            $table->index('taken_at');
            $table->index(['reference_type', 'reference_id']);
        });

        // 4. Log Aktivitas Semua Karyawan
        Schema::create('activity_logs', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('action'); // open_screen, confirm_order, upload_photo, dll
            $table->string('screen')->nullable();
            $table->jsonb('metadata')->default('{}');
            $table->string('ip_address', 50)->nullable();
            $table->string('device_id')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index(['user_id', 'created_at']);
            $table->index('action');
            $table->index('created_at');
        });

        // 5. Gaji Pokok & Performa
        Schema::create('employee_salaries', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('user_id')->constrained('users')->cascadeOnDelete();
            $table->decimal('base_salary', 15, 2);
            $table->date('effective_date');
            $table->date('end_date')->nullable();
            $table->string('salary_type', 30)->default('performance_based'); // fixed, performance_based
            $table->text('notes')->nullable();
            $table->foreignUuid('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });

        // 6. Slip Gaji Bulanan (Auto-Generated)
        Schema::create('monthly_payroll', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('user_id')->constrained('users')->cascadeOnDelete();
            $table->integer('period_year');
            $table->integer('period_month');
            $table->decimal('base_salary', 15, 2);
            $table->integer('tasks_assigned')->default(0);
            $table->integer('tasks_completed')->default(0);
            $table->decimal('completion_rate', 5, 2)->default(0);
            $table->decimal('kpi_score', 5, 2)->nullable();
            $table->decimal('calculated_salary', 15, 2);
            $table->decimal('adjustments', 15, 2)->default(0);
            $table->decimal('final_salary', 15, 2);
            $table->text('adjustment_notes')->nullable();
            $table->string('status', 20)->default('draft'); // draft, reviewed, approved, paid
            $table->foreignUuid('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignUuid('approved_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('paid_at')->nullable();
            $table->timestamps();

            $table->unique(['user_id', 'period_year', 'period_month']);
        });

        // 7. Tracking Lokasi Barang (deteksi stuck)
        Schema::create('item_location_tracking', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('order_id')->constrained('orders')->cascadeOnDelete();
            $table->uuid('stock_item_id')->nullable();
            $table->uuid('equipment_item_id')->nullable();
            $table->string('item_description');

            $table->string('origin_type', 50); // gudang, kantor, lafiore, rumah_duka, pemakaman, other
            $table->string('origin_label');
            $table->string('destination_type', 50);
            $table->string('destination_label');
            $table->string('current_location_type', 50);
            $table->string('current_location_label');
            $table->string('status', 30)->default('at_origin'); // at_origin, in_transit, at_destination, returning, returned, stuck, lost

            // Serah terima
            $table->foreignUuid('sent_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('sent_at')->nullable();
            $table->foreignUuid('received_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('received_at')->nullable();
            $table->foreignUuid('return_sent_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('return_sent_at')->nullable();
            $table->foreignUuid('return_received_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('return_received_at')->nullable();

            // AI stuck detection
            $table->boolean('is_stuck')->default(false);
            $table->timestamp('stuck_since')->nullable();
            $table->boolean('stuck_alert_sent')->default(false);
            $table->text('ai_suggestion')->nullable();

            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index('order_id');
            $table->index('status');
            $table->index('is_stuck');
            $table->index('current_location_type');
        });

        // 8. Tambah FK di orders ke funeral_homes dan cemeteries
        Schema::table('orders', function (Blueprint $table) {
            $table->uuid('funeral_home_id')->nullable()->after('status');
            $table->uuid('cemetery_id')->nullable()->after('funeral_home_id');
            $table->foreign('funeral_home_id')->references('id')->on('funeral_homes')->nullOnDelete();
            $table->foreign('cemetery_id')->references('id')->on('cemeteries')->nullOnDelete();
        });

        // 9. Tambah petugas_akta role ke roles table (jika belum ada)
        DB::table('roles')->insertOrIgnore([
            'id' => DB::raw('gen_random_uuid()'),
            'slug' => 'petugas_akta',
            'label' => 'Petugas Akta Kematian',
            'description' => 'Mengurus akta kematian untuk consumer, tracking progress per instansi',
            'is_system' => true,
            'is_active' => true,
            'can_have_inventory' => false,
            'is_vendor' => false,
            'is_viewer_only' => false,
            'can_manage_orders' => false,
            'receives_order_alarm' => true,
            'permissions' => '{}',
            'color_hex' => '#8E44AD',
            'sort_order' => 14,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Tambah musisi role
        DB::table('roles')->insertOrIgnore([
            'id' => DB::raw('gen_random_uuid()'),
            'slug' => 'musisi',
            'label' => 'Musisi / MC',
            'description' => 'Musisi dan MC pembawa acara, many-to-many per order',
            'is_system' => true,
            'is_active' => true,
            'can_have_inventory' => false,
            'is_vendor' => false,
            'is_viewer_only' => false,
            'can_manage_orders' => false,
            'receives_order_alarm' => true,
            'permissions' => '{}',
            'color_hex' => '#E91E63',
            'sort_order' => 15,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropForeign(['funeral_home_id']);
            $table->dropForeign(['cemetery_id']);
            $table->dropColumn(['funeral_home_id', 'cemetery_id']);
        });

        Schema::dropIfExists('item_location_tracking');
        Schema::dropIfExists('monthly_payroll');
        Schema::dropIfExists('employee_salaries');
        Schema::dropIfExists('activity_logs');
        Schema::dropIfExists('photo_evidences');
        Schema::dropIfExists('cemeteries');
        Schema::dropIfExists('funeral_homes');

        DB::table('roles')->whereIn('slug', ['petugas_akta', 'musisi'])->delete();
    }
};
