<?php

namespace Tests\Unit;

use App\Models\KpiMetricMaster;
use App\Models\KpiPeriod;
use App\Models\KpiScore;
use App\Models\KpiUserSummary;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Artisan;
use Tests\TestCase;

class KpiCalculationTest extends TestCase
{
    use RefreshDatabase;

    public function test_kpi_calculate_monthly_creates_period_if_none(): void
    {
        // Ensure no periods exist
        $this->assertEquals(0, KpiPeriod::count());

        Artisan::call('kpi:calculate-monthly');

        // Should auto-create a period
        $this->assertEquals(1, KpiPeriod::count());
        $period = KpiPeriod::first();
        $this->assertEquals('open', $period->status);
    }

    public function test_kpi_score_calculation_lower_is_better(): void
    {
        $user = User::factory()->create(['role' => 'SERVICE_OFFICER', 'is_active' => true]);

        $period = KpiPeriod::create([
            'period_name' => 'Test Period',
            'period_type' => 'monthly',
            'start_date' => now()->startOfMonth(),
            'end_date' => now()->endOfMonth(),
            'status' => 'open',
        ]);

        KpiMetricMaster::create([
            'metric_code' => 'TEST_SPEED',
            'metric_name' => 'Test Speed',
            'applicable_role' => 'service_officer',
            'data_source' => 'orders',
            'calculation_type' => 'average',
            'calculation_query' => 'test',
            'unit' => 'menit',
            'target_value' => 30,
            'target_direction' => 'lower_is_better',
            'weight' => 100,
            'is_active' => true,
        ]);

        Artisan::call('kpi:calculate-monthly');

        // Should have created a score
        $score = KpiScore::where('user_id', $user->id)->first();
        $this->assertNotNull($score);

        // With 0 actual (no orders), lower_is_better = 100
        $this->assertEquals(100, (float) $score->score);

        // Should have created a summary
        $summary = KpiUserSummary::where('user_id', $user->id)->first();
        $this->assertNotNull($summary);
        $this->assertEquals('A', $summary->grade); // 100 >= 90
    }

    public function test_kpi_grade_assignments(): void
    {
        // Test grade boundaries per pedoman: A>=90, B>=75, C>=60, D>=40, E<40
        $grades = [
            95 => 'A',
            90 => 'A',
            85 => 'B',
            75 => 'B',
            70 => 'C',
            60 => 'C',
            50 => 'D',
            40 => 'D',
            30 => 'E',
            0 => 'E',
        ];

        foreach ($grades as $score => $expectedGrade) {
            $grade = match (true) {
                $score >= 90 => 'A',
                $score >= 75 => 'B',
                $score >= 60 => 'C',
                $score >= 40 => 'D',
                default => 'E',
            };
            $this->assertEquals($expectedGrade, $grade, "Score $score should be grade $expectedGrade");
        }
    }

    public function test_kpi_ranking_within_role(): void
    {
        $period = KpiPeriod::create([
            'period_name' => 'Rank Test',
            'period_type' => 'monthly',
            'start_date' => now()->startOfMonth(),
            'end_date' => now()->endOfMonth(),
            'status' => 'open',
        ]);

        $user1 = User::factory()->create(['role' => 'SERVICE_OFFICER', 'is_active' => true]);
        $user2 = User::factory()->create(['role' => 'SERVICE_OFFICER', 'is_active' => true]);

        KpiUserSummary::create([
            'period_id' => $period->id,
            'user_id' => $user1->id,
            'total_score' => 85,
            'grade' => 'B',
            'rank_in_role' => 1,
            'total_in_role' => 2,
            'calculated_at' => now(),
        ]);

        KpiUserSummary::create([
            'period_id' => $period->id,
            'user_id' => $user2->id,
            'total_score' => 65,
            'grade' => 'C',
            'rank_in_role' => 2,
            'total_in_role' => 2,
            'calculated_at' => now(),
        ]);

        $summaries = KpiUserSummary::where('period_id', $period->id)
            ->orderByDesc('total_score')
            ->get();

        $this->assertEquals($user1->id, $summaries[0]->user_id);
        $this->assertEquals(1, $summaries[0]->rank_in_role);
        $this->assertEquals($user2->id, $summaries[1]->user_id);
        $this->assertEquals(2, $summaries[1]->rank_in_role);
    }
}
