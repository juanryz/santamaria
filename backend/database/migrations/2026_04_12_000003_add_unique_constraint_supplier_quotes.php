<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('purchase_order_supplier_quotes', function (Blueprint $table) {
            // Enforce: 1 supplier can only submit 1 quote per purchase order.
            $table->unique(['purchase_order_id', 'supplier_user_id'], 'unique_supplier_quote_per_po');
        });
    }

    public function down(): void
    {
        Schema::table('purchase_order_supplier_quotes', function (Blueprint $table) {
            $table->dropUnique('unique_supplier_quote_per_po');
        });
    }
};
