<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("DO $$ BEGIN CREATE TYPE coffin_order_status AS ENUM ('draft','busa_process','busa_done','amplas_process','amplas_done','qc_pending','qc_passed','qc_failed','delivered'); EXCEPTION WHEN duplicate_object THEN null; END $$");

        Schema::create('coffin_orders', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('coffin_order_number', 50)->unique();
            $table->uuid('order_id')->nullable();
            $table->string('nama_pemesan', 255)->nullable();
            $table->string('kode_peti', 100);
            $table->string('ukuran', 50)->nullable();
            $table->string('warna', 100)->nullable();
            $table->string('finishing_type', 50)->default('melamin');
            $table->timestamps();

            $table->uuid('pemberi_order_id')->nullable();
            $table->string('tukang_busa_name', 255)->nullable();
            $table->string('tukang_amplas_name', 255)->nullable();
            $table->string('tukang_finishing_name', 255)->nullable();
            $table->uuid('qc_officer_id')->nullable();

            $table->date('mulai_busa')->nullable();
            $table->date('selesai_busa')->nullable();
            $table->date('mulai_finishing')->nullable();
            $table->date('selesai_finishing')->nullable();
            $table->date('qc_date')->nullable();
            $table->text('qc_notes')->nullable();
            $table->text('notes')->nullable();

            $table->foreign('order_id')->references('id')->on('orders');
            $table->foreign('pemberi_order_id')->references('id')->on('users');
            $table->foreign('qc_officer_id')->references('id')->on('users');
        });

        DB::statement("ALTER TABLE coffin_orders ADD COLUMN status coffin_order_status NOT NULL DEFAULT 'draft'");
    }

    public function down(): void
    {
        Schema::dropIfExists('coffin_orders');
        DB::statement("DROP TYPE IF EXISTS coffin_order_status");
    }
};
