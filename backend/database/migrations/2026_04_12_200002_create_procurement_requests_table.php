<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('procurement_requests', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('request_number', 50)->unique(); // PRQ-YYYYMMDD-XXXX

            $table->uuid('gudang_user_id');
            $table->foreign('gudang_user_id')->references('id')->on('users');

            $table->uuid('order_id')->nullable();
            $table->foreign('order_id')->references('id')->on('orders');

            // Spesifikasi Barang
            $table->string('item_name', 255);
            $table->text('specification')->nullable();
            $table->string('category', 100);
            $table->integer('quantity');
            $table->string('unit', 50);
            $table->decimal('estimated_price', 15, 2)->nullable();  // harga perkiraan (referensi)
            $table->decimal('max_price', 15, 2)->nullable();        // batas harga maksimum
            $table->text('delivery_address');
            $table->timestamp('needed_by')->nullable();             // tanggal barang dibutuhkan
            $table->timestamp('quote_deadline')->nullable();        // deadline pengajuan penawaran

            // Status
            $table->enum('status', [
                'draft',
                'open',
                'evaluating',
                'awarded',
                'finance_approved',
                'goods_received',
                'partial_received',
                'completed',
                'cancelled',
            ])->default('draft');

            // Setelah Finance approve
            $table->uuid('supplier_transaction_id')->nullable();
            $table->uuid('finance_user_id')->nullable();
            $table->foreign('finance_user_id')->references('id')->on('users');
            $table->text('finance_rejection_reason')->nullable();
            $table->timestamp('finance_approved_at')->nullable();
            $table->timestamp('published_at')->nullable();
            $table->timestamp('cancelled_at')->nullable();
            $table->text('cancelled_reason')->nullable();

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('procurement_requests');
    }
};
