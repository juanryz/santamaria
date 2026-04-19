<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * v1.39 memory: KK-based payment block.
 *
 * Simpan nomor KK (16 digit) di orders untuk blokir order baru
 * kalau ada anggota keluarga yang KK-nya sama punya tagihan belum lunas.
 *
 * Saat SO input order: ketik nomor KK dari foto KK yang sudah diupload.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->string('kk_number', 20)->nullable()->after('kk_photo_path')->index();
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropIndex(['kk_number']);
            $table->dropColumn('kk_number');
        });
    }
};
