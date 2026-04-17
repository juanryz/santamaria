<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('order_billing_items', function (Blueprint $table) {
            // Allow null for add-ons added during the event that have no billing_item_master entry
            $table->uuid('billing_master_id')->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('order_billing_items', function (Blueprint $table) {
            $table->uuid('billing_master_id')->nullable(false)->change();
        });
    }
};
