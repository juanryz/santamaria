<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('dekor_daily_package_lines', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('package_id');
            $table->uuid('dekor_master_id');
            $table->decimal('anggaran_pendapatan', 15, 2)->default(0);
            $table->decimal('qty', 10, 2)->default(1);
            $table->decimal('biaya_supplier_1', 15, 2)->nullable();
            $table->decimal('biaya_supplier_2', 15, 2)->nullable();
            $table->decimal('biaya_supplier_3', 15, 2)->nullable();
            $table->string('notes', 255)->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->foreign('package_id')->references('id')->on('dekor_daily_package')->onDelete('cascade');
            $table->foreign('dekor_master_id')->references('id')->on('dekor_item_master');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('dekor_daily_package_lines');
    }
};
