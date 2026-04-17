<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('financial_transactions', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('transaction_type', 50); // order_payment, procurement, tukang_jaga_wage, vendor_payment, operational, manual_correction
            $table->string('reference_type', 50)->nullable(); // 'order', 'procurement', 'shift', 'vendor'
            $table->uuid('reference_id')->nullable();
            $table->foreignUuid('order_id')->nullable()->constrained('orders')->nullOnDelete();
            $table->decimal('amount', 15, 2);
            $table->enum('direction', ['in', 'out']);
            $table->string('currency', 10)->default('IDR');
            $table->string('category', 100);
            // income categories: jasa_funeral, paket_dasar, paket_premium, paket_eksklusif, add_on
            // expense categories: pengadaan, upah_tukang_jaga, vendor_dekor, vendor_konsumsi, vendor_pemuka_agama, vendor_foto, vendor_angkat_peti, operasional
            $table->text('description')->nullable();
            $table->date('transaction_date');
            $table->timestamp('recorded_at')->useCurrent();
            $table->foreignUuid('recorded_by')->nullable()->constrained('users')->nullOnDelete();
            // corrections
            $table->boolean('is_correction')->default(false);
            $table->uuid('original_transaction_id')->nullable();
            $table->text('correction_reason')->nullable();
            $table->timestamp('corrected_at')->nullable();
            $table->foreignUuid('corrected_by')->nullable()->constrained('users')->nullOnDelete();
            // void
            $table->boolean('is_void')->default(false);
            $table->timestamp('voided_at')->nullable();
            $table->foreignUuid('voided_by')->nullable()->constrained('users')->nullOnDelete();
            $table->text('void_reason')->nullable();
            // metadata
            $table->jsonb('metadata')->default('{}');
            $table->timestamps();
            // indexes
            $table->index('transaction_date');
            $table->index('transaction_type');
            $table->index('category');
            $table->index('order_id');
            $table->index('direction');
            $table->index('is_void');
        });

        // Self-referencing FK must be added after table exists
        Schema::table('financial_transactions', function (Blueprint $table) {
            $table->foreign('original_transaction_id')->references('id')->on('financial_transactions')->nullOnDelete();
        });

        Schema::create('financial_reports', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('report_type', 50); // monthly_summary, annual_summary, order_summary
            $table->integer('period_year');
            $table->integer('period_month')->nullable();
            $table->timestamp('generated_at')->useCurrent();
            $table->jsonb('data');
            $table->text('manual_notes')->nullable();
            $table->foreignUuid('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('reviewed_at')->nullable();
            $table->timestamps();
            $table->unique(['report_type', 'period_year', 'period_month']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('financial_reports');
        Schema::dropIfExists('financial_transactions');
    }
};
