<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('stock_items', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('item_name', 255);
            $table->string('category', 100);
            $table->integer('current_quantity')->default(0);
            $table->integer('minimum_quantity')->default(0);
            $table->string('unit', 50);
            $table->uuid('last_updated_by')->nullable();
            $table->timestamps();

            $table->foreign('last_updated_by')->references('id')->on('users');
        });

        Schema::create('stock_transactions', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('stock_item_id');
            $table->uuid('order_id')->nullable();
            $table->enum('type', ['in', 'out', 'adjustment']);
            $table->integer('quantity');
            $table->text('notes')->nullable();
            $table->uuid('user_id');
            $table->timestamp('created_at')->nullable();

            $table->foreign('stock_item_id')->references('id')->on('stock_items');
            $table->foreign('order_id')->references('id')->on('orders');
            $table->foreign('user_id')->references('id')->on('users');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('stock_transactions');
        Schema::dropIfExists('stock_items');
    }
};
