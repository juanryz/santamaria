<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * v1.24/v1.40 — Tambah kolom fee, fee_source, billing_item_id, wa_contacted*
 * ke order_vendor_assignments.
 *
 * Kolom-kolom ini disebut di spec v1.24 tapi terlewat di migration asli.
 * Dibutuhkan untuk v1.40 koreksi fee=0 pemuka_agama.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('order_vendor_assignments')) {
            return;
        }

        Schema::table('order_vendor_assignments', function (Blueprint $table) {
            // Biaya vendor (untuk billing). Default 0.
            // Untuk pemuka_agama (is_paid_by_sm=false) selalu di-force 0 via validator.
            if (! Schema::hasColumn('order_vendor_assignments', 'fee')) {
                $table->decimal('fee', 15, 2)->default(0);
            }
            if (! Schema::hasColumn('order_vendor_assignments', 'fee_source')) {
                $table->string('fee_source', 30)->default('package');
                // Values: 'package', 'addon', 'amendment', 'manual'
            }

            // Link ke billing items (kalau fee masuk tagihan consumer)
            if (! Schema::hasColumn('order_vendor_assignments', 'billing_item_id')) {
                $table->uuid('billing_item_id')->nullable();
                $table->foreign('billing_item_id')
                    ->references('id')->on('order_billing_items')->nullOnDelete();
            }

            // Koordinasi WhatsApp untuk external vendor
            if (! Schema::hasColumn('order_vendor_assignments', 'wa_contacted')) {
                $table->boolean('wa_contacted')->default(false);
            }
            if (! Schema::hasColumn('order_vendor_assignments', 'wa_contacted_at')) {
                $table->timestamp('wa_contacted_at')->nullable();
            }
            if (! Schema::hasColumn('order_vendor_assignments', 'wa_contacted_by')) {
                $table->uuid('wa_contacted_by')->nullable();
                $table->foreign('wa_contacted_by')
                    ->references('id')->on('users')->nullOnDelete();
            }

            // Alasan decline jika vendor menolak
            if (! Schema::hasColumn('order_vendor_assignments', 'declined_reason')) {
                $table->text('declined_reason')->nullable();
            }

            // Activity description
            if (! Schema::hasColumn('order_vendor_assignments', 'activity_description')) {
                $table->text('activity_description')->nullable();
            }

            // Estimated duration
            if (! Schema::hasColumn('order_vendor_assignments', 'estimated_duration_hours')) {
                $table->decimal('estimated_duration_hours', 4, 1)->nullable();
            }

            // Link ke field_attendance (auto-create saat assigned)
            if (! Schema::hasColumn('order_vendor_assignments', 'field_attendance_id')) {
                $table->uuid('field_attendance_id')->nullable();
                $table->foreign('field_attendance_id')
                    ->references('id')->on('field_attendances')->nullOnDelete();
            }
        });
    }

    public function down(): void
    {
        if (! Schema::hasTable('order_vendor_assignments')) {
            return;
        }

        Schema::table('order_vendor_assignments', function (Blueprint $table) {
            foreach ([
                'field_attendance_id', 'estimated_duration_hours', 'activity_description',
                'declined_reason', 'wa_contacted_by', 'wa_contacted_at', 'wa_contacted',
                'billing_item_id', 'fee_source', 'fee',
            ] as $col) {
                if (Schema::hasColumn('order_vendor_assignments', $col)) {
                    // Drop FK dulu jika ada
                    if (in_array($col, ['billing_item_id', 'wa_contacted_by', 'field_attendance_id'])) {
                        try {
                            $table->dropForeign([$col]);
                        } catch (\Throwable $e) {
                            // FK mungkin belum ada, skip
                        }
                    }
                    $table->dropColumn($col);
                }
            }
        });
    }
};
