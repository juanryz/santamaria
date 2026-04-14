<?php

namespace App\Services\AI;

use App\Enums\UserRole;
use App\Models\DailyReport;
use App\Models\Order;
use App\Models\PurchaseOrder;
use App\Services\NotificationService;

class DailyReportService extends BaseAiService
{
    public function generateAndSend(): void
    {
        $today = today();

        $ordersToday = Order::whereDate('created_at', $today)->get();
        $completedToday = Order::whereDate('completed_at', $today)->get();
        $pendingStatus = ['pending', 'so_review', 'admin_review', 'approved', 'in_progress'];
        $pendingOrders = Order::whereIn('status', $pendingStatus)->get();
        
        $totalRevenue = Order::whereDate('completed_at', $today)->sum('final_price');
        $totalPaid = Order::whereDate('payment_updated_at', $today)
            ->where('payment_status', 'paid')
            ->sum('payment_amount');
            
        $anomalies = PurchaseOrder::where('is_anomaly', true)
            ->whereDate('created_at', $today)
            ->count();

        $systemPrompt = <<<PROMPT
Kamu adalah asisten pelaporan bisnis untuk Owner Santa Maria Funeral Organizer.
Buat laporan harian yang ringkas, informatif, dan actionable dalam bahasa Indonesia.

Laporan harus mencakup:
1. Ringkasan order hari ini.
2. Revenue dan status pembayaran.
3. Anomali atau hal yang perlu perhatian.
4. Rekomendasi tindakan jika ada.

Gaya penulisan: profesional tapi mudah dibaca, gunakan angka konkret.
Kembalikan HANYA JSON valid:
{
  "subject": "judul notifikasi singkat",
  "narrative": "narasi laporan lengkap",
  "alerts": ["hal yang perlu perhatian segera"],
  "recommendations": ["rekomendasi tindakan"]
}
PROMPT;

        $data = [
            'tanggal' => $today->format('d F Y'),
            'stats' => [
                'order_masuk' => $ordersToday->count(),
                'order_selesai' => $completedToday->count(),
                'order_pending' => $pendingOrders->count(),
                'revenue' => $totalRevenue,
                'terbayar' => $totalPaid,
                'anomali_detected' => $anomalies,
            ],
            'pending_details' => $pendingOrders->map(fn($o) => [
                'number' => $o->order_number,
                'status' => $o->status,
                'deceased' => $o->deceased_name
            ])->toArray()
        ];

        $result = $this->callOpenAI('daily_report', [
            ['role' => 'system', 'content' => $systemPrompt],
            ['role' => 'user', 'content' => json_encode($data)]
        ]);

        if ($result['success']) {
            $report = json_decode($result['content'], true);

            DailyReport::create([
                'report_date' => $today,
                'total_orders_today' => $ordersToday->count(),
                'completed_orders' => $completedToday->count(),
                'pending_orders' => $pendingOrders->count(),
                'total_revenue' => $totalRevenue,
                'total_paid' => $totalPaid,
                'anomalies_detected' => $anomalies,
                'ai_narrative' => $report['narrative'] ?? $result['content'],
                'sent_to_owner_at' => now(),
            ]);

            NotificationService::sendToRole(UserRole::OWNER->value, 'NORMAL', $report['subject'] ?? 'Laporan Harian Santa Maria', "Laporan harian {$today->format('d/m')} tersedia.");
        }
    }
}
