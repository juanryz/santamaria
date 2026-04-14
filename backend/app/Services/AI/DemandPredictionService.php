<?php

namespace App\Services\AI;

use App\Models\Order;
use Illuminate\Support\Facades\DB;

class DemandPredictionService extends BaseAiService
{
    public function predict(): array
    {
        // Get historical data for the last 12 months
        $historicalData = Order::select(
                DB::raw("EXTRACT(YEAR FROM created_at) as year"),
                DB::raw("EXTRACT(MONTH FROM created_at) as month"),
                DB::raw("COUNT(*) as total")
            )
            ->where('created_at', '>=', now()->subYear())
            ->where('status', '!=', 'cancelled')
            ->groupBy('year', 'month')
            ->orderBy('year', 'month')
            ->get();

        $systemPrompt = <<<PROMPT
Kamu adalah analis bisnis untuk Santa Maria Funeral Organizer.
Analisis histori data order bulanan dan buat prediksi 3 bulan ke depan.

Kembalikan HANYA JSON valid:
{
  "historical_avg": 0,
  "predictions": [
    {
      "month": "Mei 2026",
      "predicted_orders": 0,
      "confidence": "high/medium/low",
      "recommendation": "saran persiapan"
    }
  ],
  "peak_months": ["bulan yang secara historis sibuk"],
  "insights": "insight keseluruhan tentang pola permintaan"
}
PROMPT;

        return $this->callOpenAI('demand_prediction', [
            ['role' => 'system', 'content' => $systemPrompt],
            ['role' => 'user', 'content' => "Data histori order: " . json_encode($historicalData)]
        ]);
    }
}
