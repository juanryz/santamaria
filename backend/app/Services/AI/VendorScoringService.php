<?php

namespace App\Services\AI;

use App\Enums\UserRole;
use App\Models\PemukaAgamaAssignment;
use App\Models\User;
use App\Models\VendorPerformance;

class VendorScoringService extends BaseAiService
{
    public function calculateMonthlyScores(int $month, int $year): void
    {
        $vendors = User::whereIn('role', UserRole::vendorValues())->get();

        foreach ($vendors as $vendor) {
            $assignments = PemukaAgamaAssignment::where('pemuka_agama_id', $vendor->id)
                ->whereMonth('created_at', $month)
                ->whereYear('created_at', $year)
                ->get();

            $total = $assignments->count();
            if ($total === 0) continue;

            $confirmed = $assignments->where('response', 'confirmed')->count();
            $rejected = $assignments->where('response', 'rejected')->count();
            $expired = $assignments->where('response', 'expired')->count();
            
            $avgResponse = $assignments->where('response', 'confirmed')
                ->avg(fn($a) => $a->responded_at ? $a->responded_at->diffInMinutes($a->notified_at) : null);

            // Scoring Formula (Heuristic)
            $confirmRate = ($confirmed / $total) * 50;
            $responseScore = $avgResponse ? max(0, 30 - ($avgResponse / 25 * 30)) : 0;
            $rejectionPenalty = ($rejected / $total) * 20;
            $score = round($confirmRate + $responseScore - $rejectionPenalty, 2);

            VendorPerformance::updateOrCreate(
                ['vendor_id' => $vendor->id, 'period_month' => $month, 'period_year' => $year],
                [
                    'total_assignments' => $total,
                    'confirmed_count' => $confirmed,
                    'rejected_count' => $rejected,
                    'expired_count' => $expired,
                    'avg_response_minutes' => $avgResponse,
                    'performance_score' => $score,
                ]
            );
        }
    }
}
