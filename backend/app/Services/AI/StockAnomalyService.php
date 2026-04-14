<?php

namespace App\Services\AI;

use App\Models\Order;
use App\Models\StockTransaction;

class StockAnomalyService extends BaseAiService
{
    public function analyze(): array
    {
        // Get stock transactions (out) from last 30 days
        $stockData = StockTransaction::where('type', 'out')
            ->where('created_at', '>=', now()->subDays(30))
            ->with('stockItem')
            ->get();
            
        $activeOrders = Order::whereIn('status', ['approved', 'in_progress'])->count();

        $systemPrompt = <<<PROMPT
Kamu adalah analis inventori untuk Santa Maria Funeral Organizer.
Analisis data penggunaan stok dan deteksi anomali yang tidak wajar.

Anomali yang perlu dicari:
1. Item keluar dalam jumlah jauh lebih banyak dari yang seharusnya berdasarkan jumlah order.
2. Item keluar tanpa referensi order.
3. Pola penggunaan yang tidak konsisten dengan historis.

Kembalikan HANYA JSON valid:
{
  "anomalies_detected": true/false,
  "anomalies": [
    {
      "item_name": "nama item",
      "issue": "deskripsi anomali",
      "severity": "high/medium/low",
      "recommendation": "saran tindakan"
    }
  ],
  "summary": "ringkasan analisis"
}
PROMPT;

        $userPrompt = "Data transaksi stok 30 hari terakhir: " . json_encode($stockData) 
            . "\nJumlah order aktif: {$activeOrders}";

        return $this->callOpenAI('stock_anomaly', [
            ['role' => 'system', 'content' => $systemPrompt],
            ['role' => 'user', 'content' => $userPrompt]
        ]);
    }
}
