<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('dekor_daily_package', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('order_id');
            $table->date('form_date');
            $table->string('rumah_duka', 255)->nullable();
            $table->smallInteger('selected_supplier')->nullable();
            $table->string('supplier_1_name', 255)->nullable();
            $table->string('supplier_2_name', 255)->nullable();
            $table->string('supplier_3_name', 255)->nullable();
            $table->decimal('total_anggaran', 15, 2)->default(0);
            $table->decimal('total_biaya_aktual', 15, 2)->default(0);
            $table->decimal('selisih', 15, 2)->default(0);
            $table->uuid('div_dekorasi_id')->nullable();
            $table->uuid('administrasi_id')->nullable();
            $table->timestamp('div_dekorasi_signed_at')->nullable();
            $table->timestamp('administrasi_signed_at')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->foreign('order_id')->references('id')->on('orders');
            $table->foreign('div_dekorasi_id')->references('id')->on('users');
            $table->foreign('administrasi_id')->references('id')->on('users');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('dekor_daily_package');
    }
};
