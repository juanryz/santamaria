<?php

namespace App\Console\Commands;

use App\Models\KpiMetricMaster;
use App\Models\KpiPeriod;
use App\Models\KpiScore;
use App\Models\KpiUserSummary;
use App\Models\User;
use App\Models\SystemThreshold;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class CalculateMonthlyKpi extends Command
{
    protected $signature   = 'kpi:calculate-monthly';
    protected $description = 'Auto-calculate KPI scores for all users in the current period.';

    public function handle(): void
    {
        $period = KpiPeriod::where('status', 'open')
            ->orderBy('start_date', 'desc')
            ->first();

        if (!$period) {
            // Auto-create monthly period
            $period = KpiPeriod::create([
                'period_name' => now()->format('F Y'),
                'period_type' => 'monthly',
                'start_date' => now()->startOfMonth(),
                'end_date' => now()->endOfMonth(),
                'status' => 'open',
            ]);
        }

        $period->update(['status' => 'calculating']);

        $metrics = KpiMetricMaster::where('is_active', true)->get()->groupBy('applicable_role');

        foreach ($metrics as $role => $roleMetrics) {
            $users = User::where('role', strtoupper($role))->where('is_active', true)->get();

            foreach ($users as $user) {
                $totalWeightedScore = 0;

                foreach ($roleMetrics as $metric) {
                    $actualValue = $this->calculateActualValue($metric, $user, $period);

                    $score = $this->calculateScore(
                        $actualValue,
                        (float) ($metric->target_value ?? 0),
                        $metric->target_direction
                    );

                    $weightedScore = $score * $metric->weight / 100;
                    $totalWeightedScore += $weightedScore;

                    KpiScore::updateOrCreate(
                        ['period_id' => $period->id, 'user_id' => $user->id, 'metric_id' => $metric->id],
                        [
                            'actual_value' => $actualValue,
                            'target_value' => $metric->target_value,
                            'score' => $score,
                            'weighted_score' => $weightedScore,
                            'weight' => $metric->weight,
                            'calculation_detail' => ['raw_value' => $actualValue],
                            'calculated_at' => now(),
                        ]
                    );
                }

                // Determine grade — boundaries from system_thresholds (no hardcode)
                $gradeA = SystemThreshold::getValue('kpi_grade_a_min', 90);
                $gradeB = SystemThreshold::getValue('kpi_grade_b_min', 75);
                $gradeC = SystemThreshold::getValue('kpi_grade_c_min', 60);
                $gradeD = SystemThreshold::getValue('kpi_grade_d_min', 40);

                $grade = match(true) {
                    $totalWeightedScore >= $gradeA => 'A',
                    $totalWeightedScore >= $gradeB => 'B',
                    $totalWeightedScore >= $gradeC => 'C',
                    $totalWeightedScore >= $gradeD => 'D',
                    default => 'E',
                };

                // Get previous period score for trend
                $prevSummary = KpiUserSummary::where('user_id', $user->id)
                    ->where('period_id', '!=', $period->id)
                    ->orderBy('calculated_at', 'desc')
                    ->first();

                $trend = 'stable';
                if ($prevSummary) {
                    if ($totalWeightedScore > $prevSummary->total_score + 2) $trend = 'up';
                    elseif ($totalWeightedScore < $prevSummary->total_score - 2) $trend = 'down';
                }

                KpiUserSummary::updateOrCreate(
                    ['period_id' => $period->id, 'user_id' => $user->id],
                    [
                        'total_score' => $totalWeightedScore,
                        'grade' => $grade,
                        'prev_total_score' => $prevSummary?->total_score,
                        'trend' => $trend,
                        'calculated_at' => now(),
                    ]
                );
            }

            // Calculate rankings per role
            $summaries = KpiUserSummary::where('period_id', $period->id)
                ->whereHas('user', fn($q) => $q->where('role', strtoupper($role)))
                ->orderByDesc('total_score')
                ->get();

            $total = $summaries->count();
            foreach ($summaries as $rank => $summary) {
                $summary->update(['rank_in_role' => $rank + 1, 'total_in_role' => $total]);
            }
        }

        $period->update(['status' => 'open']); // Keep open for refreshes

        $this->info('KPI calculation completed for period: ' . $period->period_name);
    }

    private function calculateActualValue(KpiMetricMaster $metric, User $user, KpiPeriod $period): float
    {
        $start = $period->start_date;
        $end = $period->end_date;

        return match($metric->metric_code) {
            'SO_PROCESS_SPEED' => $this->avgProcessingTime($user->id, $start, $end),
            'SO_ORDER_COUNT' => DB::table('orders')
                ->where('so_user_id', $user->id)
                ->whereBetween('confirmed_at', [$start, $end])
                ->count(),
            'SO_VIOLATION_COUNT', 'GDG_VIOLATION_COUNT', 'PRC_VIOLATION_COUNT', 'DRV_VIOLATION_COUNT',
            'DRV_OVERTIME_COUNT' => DB::table('hrd_violations')
                ->where('violated_by', $user->id)
                ->whereBetween('created_at', [$start, $end])
                ->count(),
            'DRV_TRIP_COUNT' => DB::table('vehicle_trip_logs')
                ->where('driver_id', $user->id)
                ->whereBetween('created_at', [$start, $end])
                ->count(),
            default => 0,
        };
    }

    private function avgProcessingTime(string $userId, $start, $end): float
    {
        $result = DB::table('orders')
            ->where('so_user_id', $userId)
            ->whereNotNull('confirmed_at')
            ->whereBetween('confirmed_at', [$start, $end])
            ->selectRaw('AVG(EXTRACT(EPOCH FROM (confirmed_at - created_at)) / 60) as avg_minutes')
            ->first();

        return round($result->avg_minutes ?? 0, 2);
    }

    private function calculateScore(float $actual, float $target, string $direction): float
    {
        if ($direction === 'lower_is_better') {
            if ($actual <= $target) return 100;
            if ($target == 0) return max(0, 100 - $actual * 10);
            return max(0, 100 - (($actual - $target) / $target * 100));
        }

        // higher_is_better
        if ($actual >= $target) return 100;
        if ($target == 0) return 0;
        return max(0, ($actual / $target) * 100);
    }
}
