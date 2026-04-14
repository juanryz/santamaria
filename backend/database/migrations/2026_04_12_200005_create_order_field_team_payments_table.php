<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('order_field_team_payments', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));

            $table->uuid('order_id');
            $table->foreign('order_id')->references('id')->on('orders');

            $table->string('name', 255);                   // nama anggota tim lapangan
            $table->string('role_description', 255);       // "Musisi", "Koordinator Peti", dll
            $table->string('phone', 20)->nullable();       // kontak (opsional)
            $table->decimal('amount', 15, 2);              // upah
            $table->enum('payment_method', ['cash', 'transfer']);
            $table->enum('payment_status', ['pending', 'paid'])->default('pending');
            $table->boolean('is_absent')->default(false);  // tandai tidak hadir (trigger HRD)
            $table->timestamp('paid_at')->nullable();

            $table->uuid('paid_by')->nullable();
            $table->foreign('paid_by')->references('id')->on('users');

            $table->text('receipt_path')->nullable();
            $table->text('notes')->nullable();

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('order_field_team_payments');
    }
};
