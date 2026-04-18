<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * v1.39 PART 8 — Employee leaves (cuti, sakit, izin, THR, cuti khusus).
 * Karyawan request cuti/sakit → HRD approve/reject → tracked.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('employee_leaves', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('user_id');
            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();

            $table->string('leave_type', 30); // cuti_tahunan, sakit, izin, thr, cuti_khusus
            $table->date('start_date');
            $table->date('end_date');
            $table->integer('days_count');
            $table->text('reason')->nullable();

            // Untuk sakit: foto surat dokter
            $table->text('medical_cert_photo')->nullable();

            $table->string('status', 20)->default('requested');
            // requested, approved, rejected, cancelled

            $table->uuid('approved_by')->nullable();
            $table->foreign('approved_by')->references('id')->on('users')->nullOnDelete();
            $table->timestamp('approved_at')->nullable();
            $table->text('rejection_reason')->nullable();

            $table->timestamps();

            $table->index(['user_id', 'status']);
            $table->index(['start_date', 'end_date']);
            $table->index('status');
        });

        // Tabel THR yearly tracking
        Schema::create('employee_thr', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('user_id');
            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();

            $table->integer('year');
            $table->decimal('amount', 15, 2);
            $table->timestamp('paid_at')->nullable();
            $table->uuid('paid_by')->nullable();
            $table->foreign('paid_by')->references('id')->on('users')->nullOnDelete();
            $table->text('receipt_path')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->unique(['user_id', 'year']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('employee_thr');
        Schema::dropIfExists('employee_leaves');
    }
};
