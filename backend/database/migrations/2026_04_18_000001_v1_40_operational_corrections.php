<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * SANTA MARIA — PATCH v1.40
 * Koreksi Operasional: Hapus Pemuka Agama Internal, Upah Tukang Foto per Hari,
 * Stock Opname 6 Bulan, Flow Akta Lengkap, Barang Titipan Kacang, Layanan Custom
 *
 * Lihat CLAUDE.md v1.40 untuk detail bisnis.
 */
return new class extends Migration
{
    public function up(): void
    {
        // =====================================================================
        // KOREKSI-1 — Hapus role pemuka_agama internal + deactivate users
        // =====================================================================
        if (Schema::hasTable('roles')) {
            DB::table('roles')->where('slug', 'pemuka_agama')->delete();
        }
        if (Schema::hasTable('users')) {
            DB::table('users')
                ->where('role', 'pemuka_agama')
                ->update(['is_active' => false, 'updated_at' => now()]);
        }

        // =====================================================================
        // ALTER orders — layanan custom, durasi prosesi, transport luar kota fix
        // =====================================================================
        Schema::table('orders', function (Blueprint $table) {
            if (!Schema::hasColumn('orders', 'is_custom_service')) {
                $table->boolean('is_custom_service')->default(false);
            }
            if (!Schema::hasColumn('orders', 'custom_service_notes')) {
                $table->text('custom_service_notes')->nullable();
            }
            if (!Schema::hasColumn('orders', 'custom_service_extra_fee')) {
                $table->decimal('custom_service_extra_fee', 15, 2)->default(0);
            }
            if (!Schema::hasColumn('orders', 'service_duration_days')) {
                $table->smallInteger('service_duration_days')->nullable();
            }
            if (!Schema::hasColumn('orders', 'ceremony_duration_minutes')) {
                $table->smallInteger('ceremony_duration_minutes')->default(90);
            }
        });

        // =====================================================================
        // ALTER packages — durasi layanan (3/5/7 hari)
        // =====================================================================
        if (Schema::hasTable('packages')) {
            Schema::table('packages', function (Blueprint $table) {
                if (!Schema::hasColumn('packages', 'service_duration_days')) {
                    $table->smallInteger('service_duration_days')->default(3);
                }
            });
        }

        // =====================================================================
        // ALTER tukang_jaga_shifts — makan tidak disediakan SM
        // =====================================================================
        if (Schema::hasTable('tukang_jaga_shifts')) {
            Schema::table('tukang_jaga_shifts', function (Blueprint $table) {
                if (!Schema::hasColumn('tukang_jaga_shifts', 'meals_included')) {
                    $table->boolean('meals_included')->default(false);
                }
                if (!Schema::hasColumn('tukang_jaga_shifts', 'backup_tukang_jaga_id')) {
                    $table->uuid('backup_tukang_jaga_id')->nullable();
                    $table->foreign('backup_tukang_jaga_id')
                        ->references('id')->on('users')->nullOnDelete();
                }
                if (!Schema::hasColumn('tukang_jaga_shifts', 'original_assigned_to')) {
                    $table->uuid('original_assigned_to')->nullable();
                    $table->foreign('original_assigned_to')
                        ->references('id')->on('users')->nullOnDelete();
                }
            });
        }

        // =====================================================================
        // NEW: photographer_daily_wages — upah tukang foto per hari
        // =====================================================================
        Schema::create('photographer_daily_wages', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('photographer_user_id');
            $table->foreign('photographer_user_id')
                ->references('id')->on('users')->cascadeOnDelete();
            $table->date('work_date');
            $table->integer('session_count')->default(0);
            $table->jsonb('order_ids')->default('[]');
            $table->decimal('daily_rate', 15, 2);
            $table->decimal('bonus_per_extra_session', 15, 2)->default(0);
            $table->decimal('total_wage', 15, 2);
            $table->string('status', 20)->default('draft'); // draft, finalized, paid
            $table->timestamp('finalized_at')->nullable();
            $table->timestamp('paid_at')->nullable();
            $table->uuid('paid_by')->nullable();
            $table->foreign('paid_by')->references('id')->on('users')->nullOnDelete();
            $table->text('payment_receipt_path')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->unique(['photographer_user_id', 'work_date'], 'photog_daily_wages_unique');
            $table->index(['work_date', 'status']);
        });

        // =====================================================================
        // NEW: stock_opname_sessions + stock_opname_items
        // =====================================================================
        Schema::create('stock_opname_sessions', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->integer('period_year');
            $table->string('period_semester', 2); // H1, H2
            $table->string('owner_role', 50); // gudang, super_admin, dekor
            $table->timestamp('started_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->uuid('performed_by')->nullable();
            $table->foreign('performed_by')->references('id')->on('users')->nullOnDelete();
            $table->integer('total_items_counted')->default(0);
            $table->integer('total_variance_count')->default(0);
            $table->decimal('total_variance_amount', 15, 2)->default(0);
            $table->string('status', 20)->default('open'); // open, in_progress, completed, reviewed
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->unique(['period_year', 'period_semester', 'owner_role'], 'stock_opname_period_unique');
            $table->index(['owner_role', 'status']);
        });

        Schema::create('stock_opname_items', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('session_id');
            $table->foreign('session_id')
                ->references('id')->on('stock_opname_sessions')->cascadeOnDelete();
            $table->uuid('stock_item_id');
            $table->foreign('stock_item_id')
                ->references('id')->on('stock_items')->cascadeOnDelete();
            $table->decimal('system_quantity', 10, 2);
            $table->decimal('actual_quantity', 10, 2);
            $table->decimal('variance', 10, 2); // actual - system
            $table->decimal('variance_value', 15, 2)->nullable();
            $table->uuid('photo_evidence_id')->nullable();
            $table->foreign('photo_evidence_id')
                ->references('id')->on('photo_evidences')->nullOnDelete();
            $table->text('notes')->nullable();
            $table->timestamp('reconciled_at')->nullable();
            $table->uuid('adjustment_transaction_id')->nullable();
            $table->foreign('adjustment_transaction_id')
                ->references('id')->on('stock_transactions')->nullOnDelete();
            $table->timestamp('created_at')->useCurrent();

            $table->index('session_id');
            $table->index('stock_item_id');
        });

        // =====================================================================
        // NEW: order_location_phases — multi rumah duka untuk layanan custom
        // =====================================================================
        Schema::create('order_location_phases', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('order_id');
            $table->foreign('order_id')->references('id')->on('orders')->cascadeOnDelete();
            $table->smallInteger('phase_sequence');
            $table->uuid('funeral_home_id')->nullable();
            $table->foreign('funeral_home_id')
                ->references('id')->on('funeral_homes')->nullOnDelete();
            $table->date('start_date');
            $table->date('end_date');
            $table->text('activities')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->unique(['order_id', 'phase_sequence']);
            $table->index('order_id');
        });

        // =====================================================================
        // NEW: musician_wage_config + order_musician_sessions
        // =====================================================================
        Schema::create('musician_wage_config', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('role_label', 100); // musisi, mc, paduan_suara
            $table->decimal('rate_per_session_per_person', 15, 2);
            $table->date('effective_date');
            $table->date('end_date')->nullable();
            $table->boolean('is_active')->default(true);
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['role_label', 'is_active']);
        });

        Schema::create('order_musician_sessions', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('order_id');
            $table->foreign('order_id')->references('id')->on('orders')->cascadeOnDelete();
            $table->date('session_date');
            $table->string('session_type', 30); // misa, doa_malam, prosesi, pemberkatan, lainnya
            $table->time('session_start_time')->nullable();
            $table->time('session_end_time')->nullable();
            $table->string('location')->nullable();
            $table->smallInteger('musician_count');
            $table->decimal('rate_per_person', 15, 2);
            $table->decimal('total_wage', 15, 2);
            $table->jsonb('musicians_user_ids')->default('[]');
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['order_id', 'session_date']);
        });

        // =====================================================================
        // NEW: stock_inter_location_transfers — termasuk barang titipan kacang
        // =====================================================================
        Schema::create('stock_inter_location_transfers', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('from_owner_role', 50); // super_admin (kantor)
            $table->string('to_owner_role', 50);   // gudang
            $table->uuid('stock_item_id');
            $table->foreign('stock_item_id')
                ->references('id')->on('stock_items')->cascadeOnDelete();
            $table->decimal('quantity', 10, 2);

            $table->uuid('requested_by')->nullable();
            $table->foreign('requested_by')->references('id')->on('users')->nullOnDelete();
            $table->uuid('approved_by')->nullable();
            $table->foreign('approved_by')->references('id')->on('users')->nullOnDelete();
            $table->uuid('transferred_by')->nullable();
            $table->foreign('transferred_by')->references('id')->on('users')->nullOnDelete();
            $table->uuid('received_by')->nullable();
            $table->foreign('received_by')->references('id')->on('users')->nullOnDelete();

            $table->timestamp('requested_at');
            $table->timestamp('transferred_at')->nullable();
            $table->timestamp('received_at')->nullable();

            $table->uuid('photo_evidence_id')->nullable();
            $table->foreign('photo_evidence_id')
                ->references('id')->on('photo_evidences')->nullOnDelete();

            // Supplier asal (khusus barang titipan kacang)
            $table->uuid('source_supplier_id')->nullable();
            $table->foreign('source_supplier_id')
                ->references('id')->on('users')->nullOnDelete();
            $table->string('source_consignment_batch', 100)->nullable();

            $table->string('status', 20)->default('requested'); // requested, approved, in_transit, completed, cancelled
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['from_owner_role', 'status']);
            $table->index(['to_owner_role', 'status']);
            $table->index('stock_item_id');
        });

        // =====================================================================
        // NEW: consumer_payment_reminders — log reminder H+4..H+10
        // =====================================================================
        Schema::create('consumer_payment_reminders', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('order_id');
            $table->foreign('order_id')->references('id')->on('orders')->cascadeOnDelete();
            $table->smallInteger('reminder_day'); // 4..10
            $table->date('reminder_date');
            $table->string('sent_via', 20); // whatsapp, sms, phone, app_notif
            $table->uuid('sent_by')->nullable();
            $table->foreign('sent_by')->references('id')->on('users')->nullOnDelete();
            $table->string('recipient_phone', 30)->nullable();
            $table->string('template_used', 50)->nullable();
            $table->text('message_content')->nullable();
            $table->boolean('consumer_responded')->default(false);
            $table->text('response_notes')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->unique(['order_id', 'reminder_day']);
            $table->index('order_id');
        });

        // =====================================================================
        // NEW: order_death_cert_progress + death_cert_stage_logs (v1.39 + v1.40)
        // =====================================================================
        Schema::create('order_death_cert_progress', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('order_id');
            $table->foreign('order_id')->references('id')->on('orders')->cascadeOnDelete();
            $table->uuid('petugas_akta_id')->nullable();
            $table->foreign('petugas_akta_id')->references('id')->on('users')->nullOnDelete();

            // Tahap simplified untuk v1.40 (skip kelurahan/kecamatan)
            $table->string('current_stage', 40)->default('not_started');
            // not_started, source_doc_received, submitted_to_dukcapil, processing_dukcapil,
            // cert_issued, waiting_payment, waiting_ktp_kk_pickup, handed_to_family

            // KOREKSI v1.40 — biaya admin internal saja (tidak ditagihkan ke keluarga)
            $table->decimal('total_admin_fees', 15, 2)->default(0);
            $table->jsonb('admin_fees_breakdown')->default('{}');

            // Tempat meninggal — menentukan jalur dokumen sumber
            $table->string('death_location_type', 20)->default('rumah_sakit');
            // rumah_sakit, rumah, tempat_lain
            $table->string('death_certificate_source')->nullable();
            // "RS Telogorejo" / "RT 05 RW 02 Pandanaran"

            // Dokumen sumber dari keluarga
            $table->timestamp('source_document_received_at')->nullable();
            $table->uuid('source_document_photo_evidence_id')->nullable();
            $table->foreign('source_document_photo_evidence_id', 'fk_acp_src_doc_photo')
                ->references('id')->on('photo_evidences')->nullOnDelete();

            // Dokumen serah terima akta ke keluarga
            $table->uuid('family_ktp_photo_evidence_id')->nullable();
            $table->foreign('family_ktp_photo_evidence_id', 'fk_acp_family_ktp')
                ->references('id')->on('photo_evidences')->nullOnDelete();
            $table->uuid('family_kk_photo_evidence_id')->nullable();
            $table->foreign('family_kk_photo_evidence_id', 'fk_acp_family_kk')
                ->references('id')->on('photo_evidences')->nullOnDelete();
            $table->boolean('family_ktp_received')->default(false);
            $table->boolean('family_kk_received')->default(false);

            $table->timestamp('started_at')->nullable();
            $table->timestamp('cert_issued_at')->nullable();
            $table->timestamp('handed_to_family_at')->nullable();
            $table->integer('days_elapsed')->nullable();

            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['order_id', 'current_stage']);
            $table->index('current_stage');
        });

        Schema::create('death_cert_stage_logs', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('progress_id');
            $table->foreign('progress_id', 'fk_dcsl_progress')
                ->references('id')->on('order_death_cert_progress')->cascadeOnDelete();
            $table->string('stage', 40);
            $table->string('institution_name')->nullable(); // "Kelurahan Pandanaran"
            $table->timestamp('visited_at');
            $table->uuid('photo_evidence_id')->nullable();
            $table->foreign('photo_evidence_id', 'fk_dcsl_photo')
                ->references('id')->on('photo_evidences')->nullOnDelete();
            $table->decimal('fee_paid', 15, 2)->nullable();
            $table->uuid('receipt_photo_evidence_id')->nullable();
            $table->foreign('receipt_photo_evidence_id', 'fk_dcsl_receipt')
                ->references('id')->on('photo_evidences')->nullOnDelete();
            $table->text('notes')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index('progress_id');
        });

        // =====================================================================
        // SEED: system_thresholds v1.40
        // =====================================================================
        if (Schema::hasTable('system_thresholds')) {
            $thresholds = [
                [
                    'key' => 'consumer_payment_grace_days_after_deadline',
                    'value' => 7,
                    'unit' => 'days',
                    'description' => 'Toleransi hari keterlambatan bayar consumer setelah deadline 3 hari (v1.40)',
                ],
                [
                    'key' => 'consumer_payment_total_max_days',
                    'value' => 10,
                    'unit' => 'days',
                    'description' => 'Total maksimal hari sejak order selesai sebelum eskalasi (3 deadline + 7 toleransi, v1.40)',
                ],
                [
                    'key' => 'death_cert_max_processing_days',
                    'value' => 14,
                    'unit' => 'days',
                    'description' => 'Maksimal 2 minggu pengurusan akta kematian (v1.40)',
                ],
                [
                    'key' => 'death_cert_expected_processing_days',
                    'value' => 7,
                    'unit' => 'days',
                    'description' => 'Ekspektasi durasi pengurusan akta kematian (v1.40)',
                ],
                [
                    'key' => 'ceremony_duration_minutes_default',
                    'value' => 90,
                    'unit' => 'minutes',
                    'description' => 'Default durasi upacara kematian 1-1.5 jam (v1.40)',
                ],
                [
                    'key' => 'stock_opname_frequency_months',
                    'value' => 6,
                    'unit' => 'months',
                    'description' => 'Frekuensi stock opname 6 bulan sekali (v1.40)',
                ],
            ];

            foreach ($thresholds as $t) {
                DB::table('system_thresholds')->updateOrInsert(
                    ['key' => $t['key']],
                    array_merge($t, [
                        'updated_at' => now(),
                    ])
                );
            }
        }
    }

    public function down(): void
    {
        // Drop new tables (reverse order untuk FK)
        Schema::dropIfExists('death_cert_stage_logs');
        Schema::dropIfExists('order_death_cert_progress');
        Schema::dropIfExists('consumer_payment_reminders');
        Schema::dropIfExists('stock_inter_location_transfers');
        Schema::dropIfExists('order_musician_sessions');
        Schema::dropIfExists('musician_wage_config');
        Schema::dropIfExists('order_location_phases');
        Schema::dropIfExists('stock_opname_items');
        Schema::dropIfExists('stock_opname_sessions');
        Schema::dropIfExists('photographer_daily_wages');

        // Rollback altered columns
        if (Schema::hasTable('tukang_jaga_shifts')) {
            Schema::table('tukang_jaga_shifts', function (Blueprint $table) {
                if (Schema::hasColumn('tukang_jaga_shifts', 'original_assigned_to')) {
                    $table->dropForeign(['original_assigned_to']);
                    $table->dropColumn('original_assigned_to');
                }
                if (Schema::hasColumn('tukang_jaga_shifts', 'backup_tukang_jaga_id')) {
                    $table->dropForeign(['backup_tukang_jaga_id']);
                    $table->dropColumn('backup_tukang_jaga_id');
                }
                if (Schema::hasColumn('tukang_jaga_shifts', 'meals_included')) {
                    $table->dropColumn('meals_included');
                }
            });
        }

        if (Schema::hasTable('packages')) {
            Schema::table('packages', function (Blueprint $table) {
                if (Schema::hasColumn('packages', 'service_duration_days')) {
                    $table->dropColumn('service_duration_days');
                }
            });
        }

        Schema::table('orders', function (Blueprint $table) {
            foreach ([
                'ceremony_duration_minutes',
                'service_duration_days',
                'custom_service_extra_fee',
                'custom_service_notes',
                'is_custom_service',
            ] as $col) {
                if (Schema::hasColumn('orders', $col)) {
                    $table->dropColumn($col);
                }
            }
        });

        // Drop seeded thresholds (keep roles/users state — not auto-reversed)
        if (Schema::hasTable('system_thresholds')) {
            DB::table('system_thresholds')->whereIn('key', [
                'consumer_payment_grace_days_after_deadline',
                'consumer_payment_total_max_days',
                'death_cert_max_processing_days',
                'death_cert_expected_processing_days',
                'ceremony_duration_minutes_default',
                'stock_opname_frequency_months',
            ])->delete();
        }
    }
};
