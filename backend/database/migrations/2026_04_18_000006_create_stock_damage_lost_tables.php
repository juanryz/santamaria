<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * v1.39 PART 10 — Stock damage & lost tracking via barcode.
 *
 * Setiap stock_item dapat unique barcode (Code128).
 * Saat barang rusak: scan barcode → form kerugian → log + estimasi kerugian.
 * Saat barang hilang di rumah duka: tukang_jaga terakhir bertanggung jawab,
 * potongan dari upah.
 *
 * Form fields sementara menggunakan struktur yang owner berikan di spec v1.39.
 * Template form dari owner akan dijadikan sumber perluasan saat tersedia.
 */
return new class extends Migration
{
    public function up(): void
    {
        // ── Add barcode ke stock_items ──────────────────────────────────
        Schema::table('stock_items', function (Blueprint $table) {
            if (!Schema::hasColumn('stock_items', 'barcode')) {
                $table->string('barcode', 255)->nullable()->unique();
            }
            if (!Schema::hasColumn('stock_items', 'barcode_image_path')) {
                $table->text('barcode_image_path')->nullable();
            }
        });

        // ── stock_damage_logs ────────────────────────────────────────────
        Schema::create('stock_damage_logs', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('stock_item_id');
            $table->foreign('stock_item_id')
                ->references('id')->on('stock_items')->cascadeOnDelete();

            $table->uuid('order_id')->nullable();
            $table->foreign('order_id')->references('id')->on('orders')->nullOnDelete();

            $table->string('barcode_scanned', 255)->nullable();

            $table->uuid('reported_by');
            $table->foreign('reported_by')->references('id')->on('users')->cascadeOnDelete();
            $table->string('reported_role', 50);

            $table->decimal('quantity_damaged', 10, 2);
            $table->string('damage_level', 20);
            // minor, moderate, severe, total_loss
            $table->decimal('estimated_loss_amount', 15, 2);

            $table->uuid('damage_photo_evidence_id')->nullable();
            $table->foreign('damage_photo_evidence_id', 'fk_sdl_photo')
                ->references('id')->on('photo_evidences')->nullOnDelete();
            $table->text('damage_description');

            $table->string('responsible_party', 30)->nullable();
            // sm_gudang, sm_driver, sm_dekor, tukang_jaga, keluarga, unknown
            $table->uuid('responsible_user_id')->nullable();
            $table->foreign('responsible_user_id', 'fk_sdl_user')
                ->references('id')->on('users')->nullOnDelete();

            $table->string('status', 20)->default('reported');
            // reported, investigated, resolved, written_off
            $table->text('resolution_notes')->nullable();
            $table->uuid('resolved_by')->nullable();
            $table->foreign('resolved_by', 'fk_sdl_resolved')
                ->references('id')->on('users')->nullOnDelete();
            $table->timestamp('resolved_at')->nullable();

            $table->timestamps();

            $table->index(['stock_item_id', 'status']);
            $table->index(['order_id', 'status']);
            $table->index('damage_level');
        });

        // ── stock_lost_logs ──────────────────────────────────────────────
        Schema::create('stock_lost_logs', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('stock_item_id');
            $table->foreign('stock_item_id')
                ->references('id')->on('stock_items')->cascadeOnDelete();

            $table->uuid('order_id')->nullable();
            $table->foreign('order_id')->references('id')->on('orders')->nullOnDelete();

            $table->decimal('quantity_lost', 10, 2);
            $table->decimal('estimated_loss_amount', 15, 2);

            // Auto-detect tukang jaga terakhir yang terima
            $table->uuid('last_tukang_jaga_id')->nullable();
            $table->foreign('last_tukang_jaga_id', 'fk_sll_tj')
                ->references('id')->on('users')->nullOnDelete();
            $table->uuid('last_delivery_id')->nullable();
            $table->foreign('last_delivery_id', 'fk_sll_delivery')
                ->references('id')->on('tukang_jaga_item_deliveries')->nullOnDelete();

            // Penalty
            $table->decimal('penalty_amount', 15, 2)->nullable();
            $table->boolean('penalty_deducted')->default(false);
            $table->timestamp('penalty_deducted_at')->nullable();

            $table->uuid('reported_by');
            $table->foreign('reported_by', 'fk_sll_reporter')
                ->references('id')->on('users')->cascadeOnDelete();
            $table->timestamp('reported_at');
            $table->string('status', 20)->default('reported');
            // reported, investigating, charged, written_off, recovered
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['stock_item_id', 'status']);
            $table->index(['order_id', 'status']);
            $table->index('last_tukang_jaga_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('stock_lost_logs');
        Schema::dropIfExists('stock_damage_logs');

        Schema::table('stock_items', function (Blueprint $table) {
            if (Schema::hasColumn('stock_items', 'barcode_image_path')) {
                $table->dropColumn('barcode_image_path');
            }
            if (Schema::hasColumn('stock_items', 'barcode')) {
                $table->dropColumn('barcode');
            }
        });
    }
};
