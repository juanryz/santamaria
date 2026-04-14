<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('order_bukti_lapangan', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));

            $table->uuid('order_id');
            $table->foreign('order_id')->references('id')->on('orders');

            $table->uuid('uploaded_by');
            $table->foreign('uploaded_by')->references('id')->on('users');

            $table->string('role', 50);   // 'driver', 'dekor', 'konsumsi'
            $table->enum('bukti_type', [
                'penjemputan',
                'tiba_tujuan',
                'dekorasi_selesai',
                'konsumsi_selesai',
                'lainnya',
            ]);

            $table->text('file_path');
            $table->bigInteger('file_size_bytes');
            $table->text('notes')->nullable();
            $table->timestamp('created_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('order_bukti_lapangan');
    }
};
