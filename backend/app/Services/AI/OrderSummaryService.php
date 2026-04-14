<?php

namespace App\Services\AI;

use App\Models\Order;
use App\Models\OrderBillingItem;
use App\Models\FieldAttendance;
use App\Models\OrderEquipmentItem;

class OrderSummaryService extends BaseAiService
{
    private const SYSTEM_PROMPT = <<<PROMPT
Kamu adalah asisten operasional untuk Santa Maria Funeral Organizer.
Buatkan ringkasan pelayanan harian yang profesional untuk satu order.
Ringkasan mencakup: kehadiran tim, status peralatan, konsumabel yang terpakai, dan status tagihan.

Kembalikan HANYA JSON valid:
{
  "summary": "ringkasan operasional 2-3 kalimat",
  "highlights": ["hal positif 1", "hal positif 2"],
  "issues": ["masalah 1 + dampak", "masalah 2"],
  "billing_status": "ringkasan status tagihan",
  "next_action": "tindakan yang perlu dilakukan selanjutnya"
}
PROMPT;

    /**
     * Generate daily operational summary for an order.
     */
    public function generateDailySummary(Order $order): array
    {
        $attendances = FieldAttendance::where('order_id', $order->id)->get();
        $equipment = OrderEquipmentItem::where('order_id', $order->id)->get();
        $billing = OrderBillingItem::where('order_id', $order->id)->get();

        $attendanceSummary = $attendances->groupBy('status')->map->count()->toArray();
        $equipmentSummary = $equipment->groupBy('status')->map->count()->toArray();
        $billingTotal = $billing->sum('total_price');

        $userPrompt = <<<PROMPT
Order: {$order->order_number}
Status: {$order->status}
Almarhum: {$order->deceased_name}
Lokasi: {$order->destination_address}
Jadwal: {$order->scheduled_at}

Kehadiran Tim:
PROMPT;

        foreach ($attendanceSummary as $status => $count) {
            $userPrompt .= "\n- {$status}: {$count} orang";
        }

        $userPrompt .= "\n\nStatus Peralatan:";
        foreach ($equipmentSummary as $status => $count) {
            $userPrompt .= "\n- {$status}: {$count} item";
        }

        $unreturned = $equipment->whereIn('status', ['sent', 'received'])->count();
        $missing = $equipment->where('status', 'missing')->count();

        $userPrompt .= "\n\nTagihan: Rp " . number_format($billingTotal, 0, ',', '.');
        $userPrompt .= "\nItem tagihan: {$billing->count()} item";
        $userPrompt .= "\nPeralatan belum kembali: {$unreturned}, hilang: {$missing}";

        $messages = [
            ['role' => 'system', 'content' => self::SYSTEM_PROMPT],
            ['role' => 'user', 'content' => $userPrompt],
        ];

        $result = $this->callOpenAI('order_daily_summary', $messages, [], $order->id);

        if ($result['success']) {
            $content = preg_replace('/^```json\s*|\s*```$/', '', trim($result['content']));
            $parsed = json_decode($content, true);
            return ['success' => true, 'data' => $parsed ?? ['raw' => $content]];
        }

        return ['success' => false, 'message' => $result['error'] ?? 'AI summary failed'];
    }
}
