<?php

namespace App\Services\AI;

use App\Enums\UserRole;
use App\Models\PurchaseOrder;
use App\Models\SystemSetting;
use App\Services\NotificationService;

class PriceValidationService extends BaseAiService
{
    public function validate(PurchaseOrder $po): array
    {
        $threshold = (int) SystemSetting::getValue('price_anomaly_threshold_pct', 20);

        // Define tools for web search if the SDK supports it, 
        // otherwise we prompt GPT to use its internal knowledge or simulate search.
        $tools = [
            ['type' => 'web_search_preview'] 
        ];

        $systemPrompt = <<<PROMPT
Kamu adalah validator harga untuk sistem pengadaan barang Santa Maria Funeral Organizer.
Cari harga referensi untuk item yang disebutkan di marketplace Indonesia (Tokopedia, Shopee, Lazada) atau Google Shopping.
Berikan estimasi harga pasar yang wajar berdasarkan pencarian tersebut.

Kembalikan HANYA JSON valid:
{
  "item_name": "nama item",
  "proposed_price": 0,
  "market_price_estimate": 0,
  "price_variance_pct": 0,
  "is_anomaly": false,
  "sources": ["url atau nama sumber"],
  "analysis": "penjelasan singkat tentang harga dan anomali jika ada"
}

is_anomaly = true jika proposed_price lebih tinggi dari market_price_estimate sebesar lebih dari threshold%.
PROMPT;

        $userPrompt = <<<PROMPT
Item: {$po->item_name}
Jumlah: {$po->quantity} {$po->unit}
Harga yang diajukan: Rp {$po->proposed_price} per {$po->unit}
Threshold anomali: {$threshold}%

Cari harga referensi pasar untuk item ini dan analisis apakah harga yang diajukan wajar.
PROMPT;

        $messages = [
            ['role' => 'system', 'content' => $systemPrompt],
            ['role' => 'user', 'content' => $userPrompt]
        ];

        $result = $this->callOpenAI('price_validation', $messages, $tools, $po->order_id);

        if ($result['success']) {
            $content = $result['content'];
            $content = preg_replace('/^```json\s*|\s*```$/', '', trim($content));
            $data = json_decode($content, true);

            if ($data) {
                $po->update([
                    'market_price' => $data['market_price_estimate'],
                    'price_variance_pct' => $data['price_variance_pct'],
                    'is_anomaly' => $data['is_anomaly'],
                    'ai_analysis' => $data['analysis'],
                    'status' => $data['is_anomaly'] ? 'anomaly_pending_owner' : 'pending_finance',
                ]);

                if ($data['is_anomaly']) {
                    NotificationService::sendToRole(UserRole::OWNER->value, 'HIGH', 'Anomali Harga Terdeteksi', "PO {$po->item_name}: harga {$data['price_variance_pct']}% di atas pasar");
                } else {
                    NotificationService::sendToRole(UserRole::FINANCE->value, 'HIGH', 'PO Perlu Disetujui', "PO baru untuk {$po->item_name} menunggu persetujuan");
                }
            }
        }
        return $result;
    }
}
