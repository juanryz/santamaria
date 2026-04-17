<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

/**
 * v1.35 — User Location Tracking
 * Menyimpan riwayat lokasi semua karyawan (bukan hanya driver).
 * Karyawan menyetujui pelacakan via consent dialog saat pertama login.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_locations', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('user_id');
            $table->decimal('latitude', 10, 7);
            $table->decimal('longitude', 10, 7);
            $table->float('accuracy')->nullable();
            $table->float('speed')->nullable();       // m/s
            $table->float('heading')->nullable();     // derajat 0-360
            $table->float('altitude')->nullable();    // meter
            $table->string('battery_level', 5)->nullable(); // persen
            $table->boolean('is_moving')->default(false);
            $table->timestamp('recorded_at')->useCurrent();

            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->index(['user_id', 'recorded_at']);
        });

        // Tabel untuk menyimpan persetujuan karyawan
        Schema::create('user_location_consents', function (Blueprint $table) {
            $table->uuid('user_id')->primary();
            $table->boolean('agreed')->default(false);
            $table->timestamp('agreed_at')->nullable();
            $table->string('ip_address', 45)->nullable();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_locations');
        Schema::dropIfExists('user_location_consents');
    }
};
