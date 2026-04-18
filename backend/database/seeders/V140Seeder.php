<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Seeder v1.40 — musician wage config, extra system_thresholds.
 *
 * Nominal upah = placeholder (PENDING konfirmasi owner).
 * Owner bisa update via /admin/musicians/wage-configs setelah go-live.
 */
class V140Seeder extends Seeder
{
    public function run(): void
    {
        $this->seedMusicianWageConfig();
        $this->seedV140Thresholds();
    }

    /**
     * Default rate musisi: placeholder Rp 100.000/orang/sesi.
     * MC dan paduan suara dengan placeholder rate berbeda.
     * Owner bisa update setelah go-live.
     */
    private function seedMusicianWageConfig(): void
    {
        if (! Schema::hasTable('musician_wage_config')) {
            return;
        }

        $configs = [
            [
                'role_label' => 'musisi',
                'rate_per_session_per_person' => 100000,
                'notes' => 'PLACEHOLDER v1.40. Owner harus konfirmasi tarif aktual.',
            ],
            [
                'role_label' => 'mc',
                'rate_per_session_per_person' => 150000,
                'notes' => 'PLACEHOLDER v1.40. MC biasanya tarif lebih tinggi.',
            ],
            [
                'role_label' => 'paduan_suara',
                'rate_per_session_per_person' => 75000,
                'notes' => 'PLACEHOLDER v1.40. Paduan suara biasanya dibayar per orang.',
            ],
        ];

        foreach ($configs as $c) {
            $exists = DB::table('musician_wage_config')
                ->where('role_label', $c['role_label'])
                ->where('is_active', true)
                ->exists();

            if ($exists) {
                continue;
            }

            DB::table('musician_wage_config')->insert([
                'id' => DB::raw('gen_random_uuid()'),
                'role_label' => $c['role_label'],
                'rate_per_session_per_person' => $c['rate_per_session_per_person'],
                'effective_date' => now()->toDateString(),
                'is_active' => true,
                'notes' => $c['notes'],
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }

    /**
     * System thresholds tambahan yang belum di-seed oleh migration v1.40.
     */
    private function seedV140Thresholds(): void
    {
        if (! Schema::hasTable('system_thresholds')) {
            return;
        }

        $thresholds = [
            [
                'key' => 'cs_whatsapp_number',
                'value' => 0, // string disimpan di description karena kolom value DECIMAL
                'unit' => 'text',
                'description' => 'Nomor WhatsApp CS Santa Maria: 08112714440 (v1.37)',
            ],
            [
                'key' => 'photographer_daily_rate_default',
                'value' => 500000,
                'unit' => 'currency',
                'description' => 'PLACEHOLDER: default daily rate tukang foto Rp 500.000/hari (v1.40)',
            ],
            [
                'key' => 'photographer_bonus_extra_session',
                'value' => 100000,
                'unit' => 'currency',
                'description' => 'PLACEHOLDER: bonus per sesi extra (sesi ke-2 dst) Rp 100.000 (v1.40)',
            ],
            [
                'key' => 'tukang_angkat_peti_rate_per_person_per_day',
                'value' => 75000,
                'unit' => 'currency',
                'description' => 'Upah tukang angkat peti Rp 75.000/orang/hari (v1.34)',
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
