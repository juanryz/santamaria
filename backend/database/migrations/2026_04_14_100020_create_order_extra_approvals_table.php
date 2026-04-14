<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('order_extra_approvals', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('order_id');
            $table->string('nama_almarhum', 255);
            $table->decimal('total_biaya', 15, 2)->default(0);
            $table->string('pj_nama', 255);
            $table->text('pj_alamat')->nullable();
            $table->string('pj_no_telp', 30)->nullable();
            $table->string('pj_hub_alm', 100)->nullable();
            $table->timestamp('pj_signed_at')->nullable();
            $table->text('pj_signature_path')->nullable();
            $table->date('tanggal');
            $table->uuid('so_id')->nullable();
            $table->boolean('approved')->default(false);
            $table->timestamp('approved_at')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->foreign('order_id')->references('id')->on('orders');
            $table->foreign('so_id')->references('id')->on('users');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('order_extra_approvals');
    }
};
