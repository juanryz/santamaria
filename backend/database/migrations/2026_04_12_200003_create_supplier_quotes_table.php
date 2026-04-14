<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('supplier_quotes', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));

            $table->uuid('procurement_request_id');
            $table->foreign('procurement_request_id')->references('id')->on('procurement_requests');

            $table->uuid('supplier_id');
            $table->foreign('supplier_id')->references('id')->on('users');

            // Penawaran
            $table->decimal('unit_price', 15, 2);
            $table->decimal('total_price', 15, 2);   // unit_price × quantity (dihitung otomatis)
            $table->string('brand', 255)->nullable();
            $table->text('description')->nullable();
            $table->string('photo_path', 500)->nullable();
            $table->integer('estimated_delivery_days');
            $table->text('warranty_info')->nullable();
            $table->text('terms')->nullable();

            // Status
            $table->enum('status', [
                'submitted',
                'under_review',
                'awarded',
                'rejected',
                'cancelled',
                'shipped',
                'completed',
            ])->default('submitted');

            // AI validasi harga
            $table->boolean('ai_is_reasonable')->nullable();
            $table->decimal('ai_market_price', 15, 2)->nullable();
            $table->decimal('ai_variance_pct', 5, 2)->nullable();
            $table->text('ai_analysis')->nullable();
            $table->timestamp('ai_analyzed_at')->nullable();

            // Pengiriman (setelah awarded + finance approved)
            $table->string('tracking_number', 100)->nullable();
            $table->text('shipment_photo_path')->nullable();
            $table->timestamp('shipped_at')->nullable();

            // Unique: 1 supplier hanya boleh 1 penawaran aktif per permintaan
            $table->unique(['procurement_request_id', 'supplier_id']);

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('supplier_quotes');
    }
};
