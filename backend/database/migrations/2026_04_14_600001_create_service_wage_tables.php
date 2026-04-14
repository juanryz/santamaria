<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Tarif upah per role per paket layanan — diatur oleh Purchasing
        Schema::create('service_wage_rates', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('role', 50);           // tukang_foto, tukang_angkat_peti
            $table->string('service_package', 100)->nullable(); // Silver, Gold, Platinum, atau null = default
            $table->decimal('rate_amount', 12, 2); // tarif per order/layanan
            $table->string('currency', 3)->default('IDR');
            $table->text('notes')->nullable();
            $table->uuid('set_by');                // purchasing user
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->foreign('set_by')->references('id')->on('users');
            $table->index(['role', 'service_package', 'is_active']);
        });

        // Klaim upah dari pekerja (tukang foto / koordinator angkat peti)
        Schema::create('service_wage_claims', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('order_id');
            $table->uuid('claimant_id');           // user yang klaim (tukang foto / koordinator)
            $table->string('claimant_role', 50);   // role saat klaim
            $table->uuid('wage_rate_id')->nullable(); // referensi tarif
            $table->decimal('claimed_amount', 12, 2);
            $table->text('claim_notes')->nullable();
            $table->string('status', 30)->default('pending');
            // pending → approved → paid | rejected
            $table->uuid('reviewed_by')->nullable();  // purchasing/finance
            $table->timestamp('reviewed_at')->nullable();
            $table->decimal('approved_amount', 12, 2)->nullable(); // bisa beda dari claimed
            $table->text('review_notes')->nullable();
            $table->timestamps();

            $table->foreign('order_id')->references('id')->on('orders');
            $table->foreign('claimant_id')->references('id')->on('users');
            $table->foreign('wage_rate_id')->references('id')->on('service_wage_rates');
            $table->foreign('reviewed_by')->references('id')->on('users');
            $table->index(['claimant_id', 'status']);
            $table->index(['status']);
        });

        // Pembayaran upah — bukti cash/transfer
        Schema::create('service_wage_payments', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('claim_id');
            $table->decimal('paid_amount', 12, 2);
            $table->string('payment_method', 20); // cash, transfer
            $table->string('receipt_photo_path', 500)->nullable(); // foto bukti
            $table->string('bank_name', 100)->nullable();
            $table->string('account_number', 50)->nullable();
            $table->string('account_holder', 255)->nullable();
            $table->text('payment_notes')->nullable();
            $table->uuid('paid_by');               // purchasing/finance yg bayar
            $table->timestamp('paid_at');
            $table->boolean('confirmed_by_claimant')->default(false);
            $table->timestamp('confirmed_at')->nullable();
            $table->timestamps();

            $table->foreign('claim_id')->references('id')->on('service_wage_claims');
            $table->foreign('paid_by')->references('id')->on('users');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('service_wage_payments');
        Schema::dropIfExists('service_wage_claims');
        Schema::dropIfExists('service_wage_rates');
    }
};
