<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * v1.39 PART 8 — CCTV cameras integration.
 * Owner dashboard bisa lihat live feed dari IP cameras
 * yang terpasang di kantor / gudang / Lafiore / parkiran / pos_security.
 *
 * Password disimpan encrypted — Laravel `Crypt` facade saat read/write.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('cctv_cameras', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('camera_label');
            $table->string('location_type', 30);
            // kantor, gudang, lafiore, parkiran, pos_security
            $table->string('ip_address', 50);
            $table->text('stream_url'); // RTSP / HTTP stream URL
            $table->string('username', 100)->nullable();
            $table->text('password_encrypted')->nullable();

            $table->string('stream_type', 20)->default('rtsp');
            // rtsp, http, hls, m3u8

            // Metadata posisi di area
            $table->string('area_detail')->nullable();
            // "Pintu depan kantor", "Pintu belakang gudang", dll

            $table->boolean('is_active')->default(true);

            $table->uuid('added_by')->nullable();
            $table->foreign('added_by')->references('id')->on('users')->nullOnDelete();

            $table->timestamps();

            $table->index('location_type');
            $table->index('is_active');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('cctv_cameras');
    }
};
