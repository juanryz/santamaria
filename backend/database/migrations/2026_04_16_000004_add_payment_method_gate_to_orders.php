<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up(): void {
        // payment_method mungkin sudah ada, pastikan ada enum cash/transfer
        // Kalau belum ada, tambahkan
        if (!Schema::hasColumn('orders', 'payment_method')) {
            Schema::table('orders', function (Blueprint $table) {
                $table->string('payment_method', 30)->nullable()->after('payment_status');
            });
        }
        // cash_received_at — waktu SO/purchasing catat pembayaran cash
        Schema::table('orders', function (Blueprint $table) {
            $table->timestamp('cash_received_at')->nullable()->after('payment_method');
            $table->uuid('cash_received_by')->nullable()->after('cash_received_at');
        });
    }
    public function down(): void {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn(['cash_received_at', 'cash_received_by']);
        });
    }
};
