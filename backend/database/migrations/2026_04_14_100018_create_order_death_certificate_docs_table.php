<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('order_death_certificate_docs', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('order_id');
            $table->string('nama_almarhum', 255);
            $table->text('catatan')->nullable();
            $table->date('diterima_sm_tanggal')->nullable();
            $table->string('yang_menyerahkan_name', 255)->nullable();
            $table->uuid('penerima_sm_id')->nullable();
            $table->timestamp('penerima_sm_signed_at')->nullable();
            $table->date('diterima_keluarga_tanggal')->nullable();
            $table->string('penerima_keluarga_name', 255)->nullable();
            $table->timestamp('penerima_keluarga_signed_at')->nullable();
            $table->timestamps();

            $table->foreign('order_id')->references('id')->on('orders');
            $table->foreign('penerima_sm_id')->references('id')->on('users');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('order_death_certificate_docs');
    }
};
