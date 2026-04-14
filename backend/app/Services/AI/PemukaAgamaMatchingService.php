<?php

namespace App\Services\AI;

use App\Models\Order;

class PemukaAgamaMatchingService extends BaseAiService
{
    public function rankCandidates(Order $order, array $candidates): array
    {
        $candidatesJson = json_encode($candidates);

        $systemPrompt = <<<PROMPT
Kamu membantu sistem matching pemuka agama untuk layanan pemakaman.
Rangking kandidat pemuka agama berdasarkan kriteria berikut:
1. Jarak dari lokasi pemakaman (semakin dekat semakin baik)
2. Skor performa historis (konfirmasi rate, ketepatan waktu)
3. Ketersediaan jadwal

Kembalikan HANYA JSON valid:
{
  "ranked_candidates": [
    {"user_id": "uuid", "rank": 1, "reason": "alasan singkat"},
    {"user_id": "uuid", "rank": 2, "reason": "alasan singkat"},
    {"user_id": "uuid", "rank": 3, "reason": "alasan singkat"}
  ]
}
PROMPT;

        $userPrompt = "Lokasi pemakaman: {$order->destination_address}. Kandidat: {$candidatesJson}";

        $messages = [
            ['role' => 'system', 'content' => $systemPrompt],
            ['role' => 'user', 'content' => $userPrompt]
        ];

        return $this->callOpenAI('pemuka_agama_matching', $messages, [], $order->id);
    }
}
