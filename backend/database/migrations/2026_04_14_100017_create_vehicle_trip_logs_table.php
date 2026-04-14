<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('vehicle_trip_logs', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('nota_number', 50)->unique();
            $table->uuid('order_id')->nullable();
            $table->uuid('vehicle_id');
            $table->uuid('driver_id');
            $table->string('atas_nama', 255);
            $table->text('alamat_penjemputan');
            $table->text('tujuan');
            $table->text('tempat_pemberangkatan')->nullable();
            $table->decimal('biaya_per_km', 15, 2)->nullable();
            $table->timestamp('waktu_pemakaian');
            $table->integer('hari')->nullable();
            $table->decimal('jam', 4, 1)->nullable();
            $table->decimal('km_berangkat', 10, 2)->nullable();
            $table->decimal('km_tiba', 10, 2)->nullable();
            $table->decimal('km_total', 10, 2)->nullable();
            $table->decimal('biaya_km', 15, 2)->nullable();
            $table->decimal('biaya_administrasi', 15, 2)->nullable();
            $table->decimal('total_biaya', 15, 2)->nullable();
            $table->string('penyewa_name', 255)->nullable();
            $table->timestamp('penyewa_signed_at')->nullable();
            $table->string('sm_officer_name', 255)->nullable();
            $table->timestamp('sm_officer_signed_at')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->foreign('order_id')->references('id')->on('orders');
            $table->foreign('vehicle_id')->references('id')->on('vehicles');
            $table->foreign('driver_id')->references('id')->on('users');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('vehicle_trip_logs');
    }
};
