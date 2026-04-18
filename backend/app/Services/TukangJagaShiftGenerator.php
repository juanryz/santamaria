<?php

namespace App\Services;

use App\Models\Order;
use App\Models\Package;
use App\Models\TukangJagaShift;
use App\Models\TukangJagaWageConfig;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

/**
 * Auto-generate tukang jaga shifts saat order confirmed.
 *
 * Aturan v1.40:
 * - Durasi prosesi di rumah duka: 3, 5, atau 7 hari (dari package.service_duration_days)
 * - 2 shift per hari: PAGI + MALAM
 * - Total shifts = 2 × service_duration_days
 *
 * Contoh order paket 5 hari = 10 shift generated.
 */
class TukangJagaShiftGenerator
{
    /**
     * Generate tukang jaga shifts untuk 1 order.
     *
     * Dipanggil saat order baru confirmed. Idempotent — tidak duplikat
     * kalau sudah pernah digenerate sebelumnya.
     *
     * @return int jumlah shifts yang dibuat
     */
    public function generate(Order $order): int
    {
        if (! $order->scheduled_at) {
            Log::warning('Cannot generate tukang jaga shifts — order belum ada scheduled_at', [
                'order_id' => $order->id,
            ]);
            return 0;
        }

        // Skip kalau sudah digenerate sebelumnya
        if (TukangJagaShift::where('order_id', $order->id)->exists()) {
            return 0;
        }

        $durationDays = $this->resolveDurationDays($order);
        if ($durationDays < 1) {
            return 0;
        }

        $startDate = Carbon::parse($order->scheduled_at)->startOfDay();
        $wageConfigs = $this->loadWageConfigs();

        $created = 0;
        $shiftNumber = 1;

        for ($day = 0; $day < $durationDays; $day++) {
            $currentDate = $startDate->copy()->addDays($day);

            foreach (['pagi', 'malam'] as $shiftType) {
                $times = $this->resolveShiftTimes($currentDate, $shiftType);

                TukangJagaShift::create([
                    'order_id'         => $order->id,
                    'shift_number'     => $shiftNumber++,
                    'shift_type'       => $shiftType,
                    'scheduled_start'  => $times['start'],
                    'scheduled_end'    => $times['end'],
                    'status'           => 'scheduled',
                    'wage_config_id'   => $wageConfigs[$shiftType] ?? null,
                    'wage_amount'      => 0, // akan dihitung saat checkout
                    'wage_paid'        => false,
                    'meals_included'   => false, // v1.40: SM tidak sediakan makan
                ]);

                $created++;
            }
        }

        Log::info('Generated tukang jaga shifts', [
            'order_id'      => $order->id,
            'duration_days' => $durationDays,
            'shifts_count'  => $created,
        ]);

        return $created;
    }

    /**
     * Resolve durasi hari dari order atau package.
     */
    private function resolveDurationDays(Order $order): int
    {
        // 1. Dari order langsung (kalau SO override)
        if ($order->service_duration_days) {
            return (int) $order->service_duration_days;
        }

        // 2. Dari package
        if ($order->package_id) {
            $package = Package::find($order->package_id);
            if ($package && $package->service_duration_days) {
                return (int) $package->service_duration_days;
            }
        }

        // 3. Default fallback: 3 hari
        return 3;
    }

    /**
     * Resolve jam mulai/akhir shift berdasarkan tipe.
     *
     * Aturan default (bisa di-customize via work_shifts master):
     * - PAGI: 06:00 - 18:00
     * - MALAM: 18:00 - 06:00 (hari berikutnya)
     */
    private function resolveShiftTimes(Carbon $date, string $shiftType): array
    {
        if ($shiftType === 'pagi') {
            return [
                'start' => $date->copy()->setTime(6, 0),
                'end'   => $date->copy()->setTime(18, 0),
            ];
        }

        // malam
        return [
            'start' => $date->copy()->setTime(18, 0),
            'end'   => $date->copy()->addDay()->setTime(6, 0),
        ];
    }

    /**
     * Load wage configs aktif, index by shift_type.
     */
    private function loadWageConfigs(): array
    {
        return TukangJagaWageConfig::where('is_active', true)
            ->get()
            ->keyBy('shift_type')
            ->map(fn($c) => $c->id)
            ->toArray();
    }
}
