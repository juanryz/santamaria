<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * SANTA MARIA — PATCH v1.40 (gap filler)
 *
 * Melengkapi 6 tabel/kolom yang tercantum di spec v1.39/v1.40 tapi belum di-migrate:
 *   1. coffin_size_master          — ukuran peti + rekomendasi jumlah angkat peti
 *   2. location_presence_logs      — tracking karyawan di rumah duka / TPU / gereja
 *   3. orders.coffin_size_id       — FK ke coffin_size_master
 *   4. orders.lifters_count        — jumlah aktual tukang angkat peti
 *   5. vendor_role_master.is_paid_by_sm — flag: dibayar SM (true) atau keluarga langsung (false)
 *   6. Seed coffin_size_master + update vendor_role_master row pemuka_agama
 */
return new class extends Migration
{
    public function up(): void
    {
        // =====================================================================
        // 1. coffin_size_master — dari v1.39 PART 7
        // =====================================================================
        Schema::create('coffin_size_master', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('size_label', 50)->unique();
            // kecil, standard, medium, besar, jumbo
            $table->integer('min_length_cm')->nullable();
            $table->integer('max_length_cm')->nullable();
            $table->smallInteger('recommended_lifters_min');
            $table->smallInteger('recommended_lifters_max');
            $table->integer('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // Seed 5 ukuran default
        $seed = [
            ['kecil',    150, 180, 4, 4,  1],
            ['standard', 180, 200, 4, 6,  2],
            ['medium',   200, 215, 6, 6,  3],
            ['besar',    215, 230, 6, 8,  4],
            ['jumbo',    230, 280, 8, 10, 5],
        ];
        foreach ($seed as [$label, $min, $max, $liftMin, $liftMax, $order]) {
            DB::table('coffin_size_master')->insert([
                'id' => DB::raw('gen_random_uuid()'),
                'size_label' => $label,
                'min_length_cm' => $min,
                'max_length_cm' => $max,
                'recommended_lifters_min' => $liftMin,
                'recommended_lifters_max' => $liftMax,
                'sort_order' => $order,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        // =====================================================================
        // 2. orders — tambah coffin_size_id, lifters_count
        // =====================================================================
        Schema::table('orders', function (Blueprint $table) {
            if (!Schema::hasColumn('orders', 'coffin_size_id')) {
                $table->uuid('coffin_size_id')->nullable();
                $table->foreign('coffin_size_id')
                    ->references('id')->on('coffin_size_master')->nullOnDelete();
            }
            if (!Schema::hasColumn('orders', 'lifters_count')) {
                $table->smallInteger('lifters_count')->nullable();
            }
        });

        // =====================================================================
        // 3. location_presence_logs — v1.40 PART 10
        //    Check-in / check-out karyawan di lokasi non-kantor
        //    (rumah duka, TPU, gereja, rumah keluarga)
        // =====================================================================
        Schema::create('location_presence_logs', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));

            $table->uuid('order_id')->nullable();
            $table->foreign('order_id')->references('id')->on('orders')->nullOnDelete();

            $table->uuid('user_id');
            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->string('user_role', 50)->nullable(); // snapshot role

            $table->string('location_type', 30);
            // rumah_duka, tpu, gereja, rumah_keluarga, lainnya
            $table->string('location_name', 255)->nullable();
            $table->uuid('location_ref_id')->nullable();
            // FK ke funeral_homes atau cemeteries (polymorphic-style, soft ref)

            $table->string('action', 20); // check_in, check_out
            $table->timestamp('timestamp')->useCurrent();

            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();

            $table->uuid('photo_evidence_id')->nullable();
            $table->foreign('photo_evidence_id')
                ->references('id')->on('photo_evidences')->nullOnDelete();

            $table->text('notes')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index(['order_id', 'timestamp']);
            $table->index(['user_id', 'timestamp']);
            $table->index(['location_type', 'location_ref_id']);
        });

        // =====================================================================
        // 4. vendor_role_master — tambah is_paid_by_sm
        //    Untuk v1.40 KOREKSI-1: pemuka_agama dibayar keluarga langsung (fee=0)
        // =====================================================================
        if (Schema::hasTable('vendor_role_master')) {
            Schema::table('vendor_role_master', function (Blueprint $table) {
                if (!Schema::hasColumn('vendor_role_master', 'is_paid_by_sm')) {
                    // true  = SM bayar vendor (masuk billing/extra_approval)
                    // false = keluarga bayar langsung (fee=0 dari SM, info-only)
                    $table->boolean('is_paid_by_sm')->default(true);
                }
            });

            // Set is_paid_by_sm = false untuk pemuka_agama (keluarga bayar langsung)
            DB::table('vendor_role_master')
                ->where('role_code', 'pemuka_agama')
                ->update([
                    'is_paid_by_sm' => false,
                    'updated_at' => now(),
                ]);
        }
    }

    public function down(): void
    {
        // Rollback vendor_role_master
        if (Schema::hasTable('vendor_role_master')) {
            Schema::table('vendor_role_master', function (Blueprint $table) {
                if (Schema::hasColumn('vendor_role_master', 'is_paid_by_sm')) {
                    $table->dropColumn('is_paid_by_sm');
                }
            });
        }

        // Rollback orders columns
        Schema::table('orders', function (Blueprint $table) {
            if (Schema::hasColumn('orders', 'coffin_size_id')) {
                $table->dropForeign(['coffin_size_id']);
                $table->dropColumn('coffin_size_id');
            }
            if (Schema::hasColumn('orders', 'lifters_count')) {
                $table->dropColumn('lifters_count');
            }
        });

        Schema::dropIfExists('location_presence_logs');
        Schema::dropIfExists('coffin_size_master');
    }
};
