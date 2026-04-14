<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("DO $$ BEGIN CREATE TYPE consumable_shift AS ENUM ('pagi','kirim','malam'); EXCEPTION WHEN duplicate_object THEN null; END $$");

        Schema::create('order_consumables_daily', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('order_id');
            $table->date('consumable_date');
            $table->boolean('is_retur')->default(false);
            $table->uuid('input_by')->nullable();
            $table->string('tukang_jaga_1_name', 255)->nullable();
            $table->string('tukang_jaga_2_name', 255)->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->foreign('order_id')->references('id')->on('orders');
            $table->foreign('input_by')->references('id')->on('users');
        });

        DB::statement("ALTER TABLE order_consumables_daily ADD COLUMN shift consumable_shift NOT NULL");
        DB::statement("ALTER TABLE order_consumables_daily ADD CONSTRAINT uq_consumable_daily UNIQUE (order_id, consumable_date, shift, is_retur)");
    }

    public function down(): void
    {
        Schema::dropIfExists('order_consumables_daily');
        DB::statement("DROP TYPE IF EXISTS consumable_shift");
    }
};
