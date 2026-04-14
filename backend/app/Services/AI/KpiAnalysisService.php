<?php

namespace App\Services\AI;

use App\Models\KpiUserSummary;
use App\Models\KpiScore;
use App\Models\User;

class KpiAnalysisService extends BaseAiService
{
    private const SYSTEM_PROMPT = <<<PROMPT
Kamu adalah analis KPI untuk perusahaan jasa pemakaman Santa Maria.
Analisis data KPI karyawan dan berikan insight yang actionable.
Fokus pada: area yang perlu perbaikan, tren, dan rekomendasi spesifik.

Kembalikan HANYA JSON valid:
{
  "summary": "ringkasan performa 1-2 kalimat",
  "strengths": ["kekuatan 1", "kekuatan 2"],
  "improvements": ["area perbaikan 1 + saran spesifik", "area 2"],
  "trend_analysis": "analisis tren dibanding periode sebelumnya",
  "recommendation": "rekomendasi utama untuk periode berikutnya"
}
PROMPT;

    /**
     * Analyze a user's KPI for a given period and generate AI insights.
     */
    public function analyzeUserKpi(string $userId, string $periodId): array
    {
        $user = User::findOrFail($userId);
        $summary = KpiUserSummary::where('user_id', $userId)->where('period_id', $periodId)->first();
        $scores = KpiScore::where('user_id', $userId)->where('period_id', $periodId)
            ->with('metric')
            ->get();

        if (!$summary || $scores->isEmpty()) {
            return ['success' => false, 'message' => 'No KPI data found'];
        }

        $scoreDetails = $scores->map(fn($s) => [
            'metric' => $s->metric->metric_name,
            'actual' => $s->actual_value,
            'target' => $s->target_value,
            'score' => $s->score,
            'weight' => $s->weight,
            'unit' => $s->metric->unit,
        ])->toArray();

        $userPrompt = <<<PROMPT
Nama: {$user->name}
Role: {$user->role}
Grade: {$summary->grade} (Skor Total: {$summary->total_score}/100)
Ranking: {$summary->rank_in_role}/{$summary->total_in_role}
Trend: {$summary->trend}
Skor sebelumnya: {$summary->prev_total_score}

Detail per metrik:
PROMPT;

        foreach ($scoreDetails as $sd) {
            $userPrompt .= "\n- {$sd['metric']}: aktual {$sd['actual']} {$sd['unit']} (target: {$sd['target']}), skor: {$sd['score']}, bobot: {$sd['weight']}%";
        }

        $messages = [
            ['role' => 'system', 'content' => self::SYSTEM_PROMPT],
            ['role' => 'user', 'content' => $userPrompt],
        ];

        $result = $this->callOpenAI('kpi_analysis', $messages, [], $userId);

        if ($result['success']) {
            $content = preg_replace('/^```json\s*|\s*```$/', '', trim($result['content']));
            $parsed = json_decode($content, true);
            return ['success' => true, 'data' => $parsed ?? ['raw' => $content]];
        }

        return ['success' => false, 'message' => $result['error'] ?? 'AI analysis failed'];
    }
}
