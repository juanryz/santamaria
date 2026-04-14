<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->uuid('coffin_order_id')->nullable()->after('id');
            $table->uuid('tukang_foto_id')->nullable();
            $table->boolean('death_cert_submitted')->default(false);
            $table->decimal('extra_approval_total', 15, 2)->default(0);

            $table->foreign('coffin_order_id')->references('id')->on('coffin_orders');
            $table->foreign('tukang_foto_id')->references('id')->on('users');
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropForeign(['coffin_order_id']);
            $table->dropForeign(['tukang_foto_id']);
            $table->dropColumn(['coffin_order_id', 'tukang_foto_id', 'death_cert_submitted', 'extra_approval_total']);
        });
    }
};
