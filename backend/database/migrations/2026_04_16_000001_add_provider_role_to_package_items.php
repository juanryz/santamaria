<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up(): void {
        // 1. Add provider_role to package_items (replaces category logically but keep category for compat)
        Schema::table('package_items', function (Blueprint $table) {
            $table->string('provider_role', 50)->nullable()->after('category');
            // notes for fulfillment instructions
            $table->text('fulfillment_notes')->nullable()->after('provider_role');
        });

        // Migrate existing category → provider_role
        DB::statement("UPDATE package_items SET provider_role = CASE
            WHEN category = 'gudang' THEN 'gudang'
            WHEN category = 'dekor' THEN 'laviore'
            WHEN category = 'konsumsi' THEN 'konsumsi'
            WHEN category = 'transportasi' THEN 'gudang'
            ELSE 'gudang' END");

        // 2. Add owner_role to stock_items
        Schema::table('stock_items', function (Blueprint $table) {
            $table->string('owner_role', 50)->default('gudang')->after('category');
        });

        // 3. Add provider_role to order_checklists (align with package_items)
        // target_role already exists but add provider_role as alias for clarity
        if (!Schema::hasColumn('order_checklists', 'provider_role')) {
            Schema::table('order_checklists', function (Blueprint $table) {
                $table->string('provider_role', 50)->nullable()->after('target_role');
            });
            // sync with target_role
            DB::statement("UPDATE order_checklists SET provider_role = target_role WHERE target_role IS NOT NULL");
        }
    }

    public function down(): void {
        Schema::table('package_items', function (Blueprint $table) {
            $table->dropColumn(['provider_role', 'fulfillment_notes']);
        });
        Schema::table('stock_items', function (Blueprint $table) {
            $table->dropColumn('owner_role');
        });
        Schema::table('order_checklists', function (Blueprint $table) {
            $table->dropColumn('provider_role');
        });
    }
};
