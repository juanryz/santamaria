<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * v1.39 → v1.40 — Membership subscription + Petty cash.
 *
 * Membership:
 *  - consumer_memberships: subscription bulanan, status: active / grace_period / inactive / cancelled / suspended
 *  - membership_payments: log pembayaran iuran per period (year, month)
 *
 * Petty cash (kas kecil kantor):
 *  - petty_cash_transactions: cash in/out + balance tracking + receipt
 */
return new class extends Migration
{
    public function up(): void
    {
        // ── consumer_memberships ─────────────────────────────────────────────
        Schema::create('consumer_memberships', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('user_id');
            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();

            $table->string('membership_number', 50)->unique();
            $table->date('joined_at');
            $table->date('expires_at')->nullable();

            // Status lifecycle
            $table->string('status', 20)->default('active');
            // active, grace_period, inactive, cancelled, suspended

            // Subscription fee
            $table->decimal('monthly_fee', 15, 2)->default(0);

            // Payment tracking
            $table->date('last_payment_date')->nullable();
            $table->date('next_payment_due')->nullable();
            $table->date('grace_period_until')->nullable();
            $table->decimal('total_paid', 15, 2)->default(0);

            // Cancellation
            $table->timestamp('cancelled_at')->nullable();
            $table->text('cancellation_reason')->nullable();

            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'status']);
            $table->index('status');
            $table->index('next_payment_due');
        });

        // ── membership_payments ──────────────────────────────────────────────
        Schema::create('membership_payments', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('membership_id');
            $table->foreign('membership_id')
                ->references('id')->on('consumer_memberships')->cascadeOnDelete();

            $table->integer('payment_period_year');
            $table->integer('payment_period_month');
            $table->decimal('amount', 15, 2);
            $table->string('payment_method', 20); // cash, transfer
            $table->timestamp('paid_at')->useCurrent();

            $table->uuid('received_by')->nullable();
            $table->foreign('received_by')->references('id')->on('users')->nullOnDelete();

            $table->text('receipt_path')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->unique(
                ['membership_id', 'payment_period_year', 'payment_period_month'],
                'ms_pay_period_unique',
            );
            $table->index(['payment_period_year', 'payment_period_month']);
        });

        // ── petty_cash_transactions (kas kecil kantor) ──────────────────────
        Schema::create('petty_cash_transactions', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->decimal('amount', 15, 2);
            $table->string('direction', 5); // 'in' / 'out'
            $table->string('category', 100)->nullable();
            // 'operational', 'refund', 'reimbursement', 'initial_topup', dll
            $table->text('description');

            // Referensi (optional)
            $table->string('reference_type', 50)->nullable();
            $table->uuid('reference_id')->nullable();

            $table->uuid('performed_by');
            $table->foreign('performed_by')->references('id')->on('users')->cascadeOnDelete();

            $table->text('receipt_photo_path')->nullable();
            $table->decimal('balance_after', 15, 2);

            $table->timestamps();

            $table->index('direction');
            $table->index(['reference_type', 'reference_id']);
            $table->index('created_at');
        });

        // ── Seed thresholds ─────────────────────────────────────────────────
        if (Schema::hasTable('system_thresholds')) {
            $thresholds = [
                [
                    'key' => 'membership_grace_period_days',
                    'value' => 30,
                    'unit' => 'days',
                    'description' => 'Toleransi hari telat bayar iuran membership (tetap dapat harga anggota) — v1.39',
                ],
                [
                    'key' => 'membership_inactive_after_days',
                    'value' => 60,
                    'unit' => 'days',
                    'description' => 'Hari telat bayar sebelum membership jadi inactive (harga kembali non-anggota) — v1.39',
                ],
                [
                    'key' => 'membership_default_monthly_fee',
                    'value' => 0,
                    'unit' => 'currency',
                    'description' => 'Default iuran bulanan — PENDING owner confirm nominal — v1.39',
                ],
            ];

            foreach ($thresholds as $t) {
                DB::table('system_thresholds')->updateOrInsert(
                    ['key' => $t['key']],
                    array_merge($t, ['updated_at' => now()])
                );
            }
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('petty_cash_transactions');
        Schema::dropIfExists('membership_payments');
        Schema::dropIfExists('consumer_memberships');

        if (Schema::hasTable('system_thresholds')) {
            DB::table('system_thresholds')->whereIn('key', [
                'membership_grace_period_days',
                'membership_inactive_after_days',
                'membership_default_monthly_fee',
            ])->delete();
        }
    }
};
