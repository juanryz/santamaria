<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('purchase_orders', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('order_id')->nullable();
            $table->uuid('gudang_user_id');
            $table->string('item_name', 255);
            $table->integer('quantity');
            $table->string('unit', 50);
            $table->decimal('proposed_price', 15, 2);
            $table->decimal('market_price', 15, 2)->nullable();
            $table->decimal('price_variance_pct', 5, 2)->nullable();
            $table->boolean('is_anomaly')->default(false);
            $table->text('ai_analysis')->nullable();
            $table->enum('status', [
                'pending_ai', 'pending_finance', 'anomaly_pending_owner',
                'approved_finance', 'approved_owner_override', 'rejected', 'completed'
            ])->default('pending_ai');
            $table->uuid('finance_user_id')->nullable();
            $table->text('finance_notes')->nullable();
            $table->timestamp('finance_reviewed_at')->nullable();
            $table->enum('owner_decision', ['approved_override', 'rejected'])->nullable();
            $table->text('owner_notes')->nullable();
            $table->timestamp('owner_decided_at')->nullable();
            $table->string('supplier_name', 255)->nullable();
            $table->string('supplier_phone', 20)->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamps();

            $table->foreign('order_id')->references('id')->on('orders');
            $table->foreign('gudang_user_id')->references('id')->on('users');
            $table->foreign('finance_user_id')->references('id')->on('users');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('purchase_orders');
    }
};
