<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('supplier_transactions', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('transaction_number', 50)->unique(); // TRX-YYYYMMDD-XXXX

            $table->uuid('procurement_request_id');
            $table->foreign('procurement_request_id')->references('id')->on('procurement_requests');

            $table->uuid('supplier_quote_id');
            $table->foreign('supplier_quote_id')->references('id')->on('supplier_quotes');

            $table->uuid('supplier_id');
            $table->foreign('supplier_id')->references('id')->on('users');

            $table->uuid('finance_user_id');
            $table->foreign('finance_user_id')->references('id')->on('users');

            // Nilai Transaksi
            $table->decimal('agreed_unit_price', 15, 2);
            $table->integer('agreed_quantity');
            $table->decimal('agreed_total', 15, 2);

            // Pengiriman
            $table->enum('shipment_status', [
                'pending_shipment',
                'shipped',
                'goods_received',
                'partial_received',
            ])->default('pending_shipment');

            $table->string('tracking_number', 100)->nullable();
            $table->text('shipment_photo_path')->nullable();
            $table->timestamp('shipped_at')->nullable();
            $table->timestamp('received_at')->nullable();
            $table->integer('received_quantity')->nullable();
            $table->text('received_condition')->nullable();
            $table->text('received_photo_path')->nullable();

            // Pembayaran ke Supplier
            $table->enum('payment_status', ['unpaid', 'paid'])->default('unpaid');
            $table->enum('payment_method', ['transfer', 'cash'])->nullable();
            $table->decimal('payment_amount', 15, 2)->nullable();
            $table->text('payment_receipt_path')->nullable();
            $table->date('payment_date')->nullable();
            $table->boolean('payment_confirmed_by_supplier')->default(false);
            $table->timestamp('payment_confirmed_at')->nullable();

            $table->timestamp('finance_approved_at');
            $table->timestamps();
        });

        // Add supplier_transaction_id FK to procurement_requests after supplier_transactions created
        Schema::table('procurement_requests', function (Blueprint $table) {
            $table->foreign('supplier_transaction_id')->references('id')->on('supplier_transactions');
        });
    }

    public function down(): void
    {
        Schema::table('procurement_requests', function (Blueprint $table) {
            $table->dropForeign(['supplier_transaction_id']);
        });
        Schema::dropIfExists('supplier_transactions');
    }
};
