<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * v1.39 → v1.40 — Transport luar kota (Rp 25.000/km fix) + threshold rate_per_km.
 *
 * Dipisah dari migration v1.40 utama karena scope berbeda (order-level fields
 * vs master/transactional tables baru).
 */
return new class extends Migration
{
    public function up(): void
    {
        // ── Add out-of-city fields to orders ────────────────────────────────
        Schema::table('orders', function (Blueprint $table) {
            if (!Schema::hasColumn('orders', 'is_out_of_city')) {
                $table->boolean('is_out_of_city')->default(false);
            }
            if (!Schema::hasColumn('orders', 'out_of_city_origin')) {
                $table->string('out_of_city_origin', 255)->nullable();
            }
            if (!Schema::hasColumn('orders', 'out_of_city_distance_km')) {
                $table->decimal('out_of_city_distance_km', 10, 2)->nullable();
            }
            if (!Schema::hasColumn('orders', 'out_of_city_transport_fee')) {
                $table->decimal('out_of_city_transport_fee', 15, 2)->default(0);
            }
        });

        // ── Seed thresholds ─────────────────────────────────────────────────
        if (Schema::hasTable('system_thresholds')) {
            $thresholds = [
                [
                    'key' => 'out_of_city_rate_per_km',
                    'value' => 25000,
                    'unit' => 'currency',
                    'description' => 'Tarif fix transport luar kota per KM (Rp) — v1.39',
                ],
                [
                    'key' => 'amendment_auto_approve_max',
                    'value' => 500000,
                    'unit' => 'currency',
                    'description' => 'Maks nominal amendment yang bisa diapprove SO tanpa tanda tangan keluarga (Rp) — v1.22',
                ],
                [
                    'key' => 'amendment_max_per_order',
                    'value' => 10,
                    'unit' => 'count',
                    'description' => 'Maks jumlah amendment per order (safety limit) — v1.22',
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
        Schema::table('orders', function (Blueprint $table) {
            foreach (['is_out_of_city', 'out_of_city_origin',
                      'out_of_city_distance_km', 'out_of_city_transport_fee'] as $col) {
                if (Schema::hasColumn('orders', $col)) {
                    $table->dropColumn($col);
                }
            }
        });

        if (Schema::hasTable('system_thresholds')) {
            DB::table('system_thresholds')->whereIn('key', [
                'out_of_city_rate_per_km',
                'amendment_auto_approve_max',
                'amendment_max_per_order',
            ])->delete();
        }
    }
};
