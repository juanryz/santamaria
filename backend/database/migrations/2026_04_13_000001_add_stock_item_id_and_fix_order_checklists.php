<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * v1.12 — Package-Stock sync
 *
 * 1. package_items  → tambah stock_item_id (FK ke stock_items, nullable)
 *    Memungkinkan link eksplisit paket ↔ stok sehingga deduction stok akurat.
 *
 * 2. order_checklists → tambah kolom yang dipakai kode tapi belum ada di migration:
 *    quantity, unit, notes, stock_item_id
 *    (checked_at & checked_by sudah ada di migration lama)
 */
return new class extends Migration
{
    public function up(): void
    {
        // ── package_items ────────────────────────────────────────────────────
        Schema::table('package_items', function (Blueprint $table) {
            if (! Schema::hasColumn('package_items', 'stock_item_id')) {
                $table->uuid('stock_item_id')->nullable()->after('category');
                $table->foreign('stock_item_id')->references('id')->on('stock_items')->nullOnDelete();
            }
        });

        // ── order_checklists ─────────────────────────────────────────────────
        Schema::table('order_checklists', function (Blueprint $table) {
            if (! Schema::hasColumn('order_checklists', 'quantity')) {
                $table->integer('quantity')->default(1)->after('item_name');
            }
            if (! Schema::hasColumn('order_checklists', 'unit')) {
                $table->string('unit', 50)->default('pcs')->after('quantity');
            }
            if (! Schema::hasColumn('order_checklists', 'notes')) {
                $table->text('notes')->nullable()->after('unit');
            }
            if (! Schema::hasColumn('order_checklists', 'stock_item_id')) {
                $table->uuid('stock_item_id')->nullable()->after('notes');
                $table->foreign('stock_item_id')->references('id')->on('stock_items')->nullOnDelete();
            }
        });
    }

    public function down(): void
    {
        Schema::table('package_items', function (Blueprint $table) {
            $table->dropForeignIfExists(['stock_item_id']);
            $table->dropColumnIfExists('stock_item_id');
        });

        Schema::table('order_checklists', function (Blueprint $table) {
            $table->dropForeignIfExists(['stock_item_id']);
            $table->dropColumnIfExists('stock_item_id');
            $table->dropColumnIfExists('quantity');
            $table->dropColumnIfExists('unit');
            $table->dropColumnIfExists('notes');
        });
    }
};
