<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("DO $$ BEGIN CREATE TYPE stock_alert_type AS ENUM ('low_stock','out_of_stock','restock_needed'); EXCEPTION WHEN duplicate_object THEN null; END $$");

        Schema::create('stock_alerts', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('stock_item_id');
            $table->uuid('order_id')->nullable();
            $table->decimal('current_quantity', 10, 2);
            $table->decimal('minimum_quantity', 10, 2);
            $table->text('message');
            $table->boolean('is_resolved')->default(false);
            $table->uuid('resolved_by')->nullable();
            $table->timestamp('resolved_at')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->foreign('stock_item_id')->references('id')->on('stock_items');
            $table->foreign('order_id')->references('id')->on('orders');
            $table->foreign('resolved_by')->references('id')->on('users');
        });

        DB::statement("ALTER TABLE stock_alerts ADD COLUMN alert_type stock_alert_type NOT NULL");
    }

    public function down(): void
    {
        Schema::dropIfExists('stock_alerts');
        DB::statement("DROP TYPE IF EXISTS stock_alert_type");
    }
};
