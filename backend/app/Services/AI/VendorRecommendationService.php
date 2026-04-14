<?php

namespace App\Services\AI;

use App\Models\User;
use App\Models\FieldAttendance;
use App\Models\KpiUserSummary;
use App\Models\HrdViolation;
use App\Enums\UserRole;

class VendorRecommendationService extends BaseAiService
{
    private const SYSTEM_PROMPT = <<<PROMPT
Kamu adalah sistem rekomendasi vendor untuk Santa Maria Funeral Organizer.
Berdasarkan data KPI, kehadiran, dan riwayat pelanggaran, rekomendasikan vendor terbaik.
Pertimbangkan: skor KPI, tingkat kehadiran, jumlah pelanggaran, dan ketersediaan jadwal.

Kembalikan HANYA JSON valid:
{
  "recommended_id": "uuid vendor terbaik",
  "recommended_name": "nama vendor",
  "reason": "alasan singkat rekomendasi",
  "alternatives": [
    {"id": "uuid", "name": "nama", "score": 85, "note": "catatan singkat"}
  ],
  "warning": "peringatan jika ada masalah (null jika tidak ada)"
}
PROMPT;

    /**
     * Recommend the best vendor for a given role and date.
     * Uses KPI scores, attendance history, and violations.
     */
    public function recommend(string $role, string $date, ?string $orderId = null): array
    {
        $vendors = User::where('role', $role)
            ->where('is_active', true)
            ->get();

        if ($vendors->isEmpty()) {
            return ['success' => false, 'message' => "Tidak ada vendor aktif untuk role: {$role}"];
        }

        $vendorData = [];
        foreach ($vendors as $vendor) {
            $kpi = KpiUserSummary::where('user_id', $vendor->id)
                ->orderBy('calculated_at', 'desc')
                ->first();

            $attendanceRate = $this->calcAttendanceRate($vendor->id);
            $violationCount = HrdViolation::where('violated_by', $vendor->id)
                ->where('created_at', '>=', now()->subMonths(3))
                ->count();

            // Check if busy on this date
            $busyOnDate = FieldAttendance::where('user_id', $vendor->id)
                ->where('attendance_date', $date)
                ->whereIn('status', ['scheduled', 'present'])
                ->exists();

            $vendorData[] = [
                'id' => $vendor->id,
                'name' => $vendor->name,
                'kpi_score' => $kpi?->total_score ?? 0,
                'kpi_grade' => $kpi?->grade ?? '-',
                'attendance_rate' => $attendanceRate,
                'violations_3mo' => $violationCount,
                'busy_on_date' => $busyOnDate,
                'available' => !$busyOnDate,
            ];
        }

        $userPrompt = "Role: {$role}\nTanggal: {$date}\n\nData vendor:\n";
        foreach ($vendorData as $vd) {
            $status = $vd['available'] ? 'TERSEDIA' : 'SIBUK';
            $userPrompt .= "- {$vd['name']} (ID: {$vd['id']}): KPI {$vd['kpi_score']} ({$vd['kpi_grade']}), "
                . "kehadiran {$vd['attendance_rate']}%, pelanggaran 3bln: {$vd['violations_3mo']}, status: {$status}\n";
        }

        $messages = [
            ['role' => 'system', 'content' => self::SYSTEM_PROMPT],
            ['role' => 'user', 'content' => $userPrompt],
        ];

        $result = $this->callOpenAI('vendor_recommendation', $messages);

        if ($result['success']) {
            $content = preg_replace('/^```json\s*|\s*```$/', '', trim($result['content']));
            $parsed = json_decode($content, true);
            return ['success' => true, 'data' => $parsed ?? ['raw' => $content], 'vendor_data' => $vendorData];
        }

        // Fallback: sort by KPI score (available first)
        usort($vendorData, function ($a, $b) {
            if ($a['available'] !== $b['available']) return $b['available'] <=> $a['available'];
            return $b['kpi_score'] <=> $a['kpi_score'];
        });

        return [
            'success' => true,
            'data' => [
                'recommended_id' => $vendorData[0]['id'],
                'recommended_name' => $vendorData[0]['name'],
                'reason' => 'Berdasarkan skor KPI tertinggi dan ketersediaan',
                'alternatives' => array_slice($vendorData, 1, 3),
                'warning' => null,
            ],
            'vendor_data' => $vendorData,
            'source' => 'fallback_kpi_sort',
        ];
    }

    private function calcAttendanceRate(string $userId): float
    {
        $total = FieldAttendance::where('user_id', $userId)
            ->where('created_at', '>=', now()->subMonths(3))
            ->count();

        if ($total === 0) return 100;

        $present = FieldAttendance::where('user_id', $userId)
            ->where('created_at', '>=', now()->subMonths(3))
            ->whereIn('status', ['present', 'late'])
            ->count();

        return round(($present / $total) * 100, 1);
    }
}
