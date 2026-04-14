<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("DO $$ BEGIN CREATE TYPE equipment_loan_status AS ENUM ('draft','sent','active','returning','completed','overdue'); EXCEPTION WHEN duplicate_object THEN null; END $$");

        Schema::create('equipment_loans', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('loan_number', 50)->unique();
            $table->uuid('order_id')->nullable();
            $table->string('nama_almarhum', 255);
            $table->string('rumah_duka', 255)->nullable();
            $table->string('cp_almarhum', 255)->nullable();
            $table->date('tgl_peringatan');
            $table->date('tgl_kirim')->nullable();
            $table->date('tgl_kembali')->nullable();
            $table->uuid('order_by_id')->nullable();
            $table->uuid('bagian_peralatan_id')->nullable();
            $table->uuid('pengirim_id')->nullable();
            $table->uuid('pengambil_id')->nullable();
            $table->string('penerima_name', 255)->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->foreign('order_id')->references('id')->on('orders');
            $table->foreign('order_by_id')->references('id')->on('users');
            $table->foreign('bagian_peralatan_id')->references('id')->on('users');
            $table->foreign('pengirim_id')->references('id')->on('users');
            $table->foreign('pengambil_id')->references('id')->on('users');
        });

        DB::statement("ALTER TABLE equipment_loans ADD COLUMN status equipment_loan_status NOT NULL DEFAULT 'draft'");
    }

    public function down(): void
    {
        Schema::dropIfExists('equipment_loans');
        DB::statement("DROP TYPE IF EXISTS equipment_loan_status");
    }
};
