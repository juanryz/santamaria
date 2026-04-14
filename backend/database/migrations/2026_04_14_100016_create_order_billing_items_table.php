<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("DO $$ BEGIN CREATE TYPE billing_source AS ENUM ('package','addon','manual'); EXCEPTION WHEN duplicate_object THEN null; END $$");

        Schema::create('order_billing_items', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('order_id');
            $table->uuid('billing_master_id');
            $table->decimal('qty', 10, 2)->default(1);
            $table->string('unit', 50)->default('unit');
            $table->decimal('unit_price', 15, 2)->default(0);
            $table->decimal('total_price', 15, 2)->default(0);
            $table->decimal('tambahan', 15, 2)->default(0);
            $table->decimal('kembali', 15, 2)->default(0);
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->foreign('order_id')->references('id')->on('orders');
            $table->foreign('billing_master_id')->references('id')->on('billing_item_master');
        });

        DB::statement("ALTER TABLE order_billing_items ADD COLUMN source billing_source NOT NULL DEFAULT 'package'");
    }

    public function down(): void
    {
        Schema::dropIfExists('order_billing_items');
        DB::statement("DROP TYPE IF EXISTS billing_source");
    }
};
