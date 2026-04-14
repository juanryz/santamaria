<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('order_stock_deductions', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('order_id');
            $table->uuid('stock_item_id');
            $table->uuid('package_item_id');
            $table->decimal('deducted_quantity', 10, 2);
            $table->decimal('stock_before', 10, 2);
            $table->decimal('stock_after', 10, 2);
            $table->boolean('is_sufficient');
            $table->uuid('deducted_by');
            $table->timestamp('deducted_at')->useCurrent();
            $table->text('notes')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->foreign('order_id')->references('id')->on('orders');
            $table->foreign('stock_item_id')->references('id')->on('stock_items');
            $table->foreign('package_item_id')->references('id')->on('package_items');
            $table->foreign('deducted_by')->references('id')->on('users');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('order_stock_deductions');
    }
};
