<?php

namespace App\Services\AI;

use App\Models\Order;

class PackageRecommendationService extends BaseAiService
{
    public function recommend(Order $order, array $packages): array
    {
        $packagesJson = json_encode($packages);

        $systemPrompt = <<<PROMPT
Kamu adalah konsultan layanan Santa Maria Funeral Organizer.
Berdasarkan data pesanan dan katalog paket yang tersedia, rekomendasikan 2-3 paket yang paling sesuai.

Kriteria rekomendasi:
1. Kesesuaian agama almarhum dengan paket (jika paket bersifat agama-spesifik)
2. Kapasitas paket vs estimasi jumlah tamu
3. Kelengkapan layanan sesuai kebutuhan khusus yang disebutkan keluarga
4. Pertimbangan value for money

Kembalikan HANYA JSON valid berikut:
{
  "recommendations": [
    {
      "package_id": "uuid",
      "package_name": "nama paket",
      "reason": "alasan singkat kenapa direkomendasikan (1-2 kalimat)",
      "match_score": 85,
      "price": 5000000
    }
  ],
  "notes": "catatan tambahan jika ada"
}
PROMPT;

        $userPrompt = <<<PROMPT
Data Pesanan:
- Agama almarhum: {$order->deceased_religion}
- Estimasi tamu: {$order->estimated_guests} orang
- Kebutuhan khusus: {$order->special_notes}

Katalog Paket Tersedia:
{$packagesJson}
PROMPT;

        $messages = [
            ['role' => 'system', 'content' => $systemPrompt],
            ['role' => 'user', 'content' => $userPrompt]
        ];

        return $this->callOpenAI('package_recommendation', $messages, [], $order->id);
    }
}
