<?php

namespace App\Services\AI;

use App\Models\Order;
use App\Models\OrderChecklist;

class ChecklistGeneratorService extends BaseAiService
{
    private const SYSTEM_PROMPT = <<<PROMPT
Kamu adalah ahli prosesi pemakaman yang memahami tradisi dan ritual dari berbagai agama di Indonesia.
Generate checklist persiapan pemakaman yang detail dan praktis berdasarkan agama almarhum.

Kategorikan setiap item ke dalam:
- perlengkapan_ibadah: peralatan untuk ritual keagamaan
- pakaian_kain: pakaian dan kain yang diperlukan
- perlengkapan_fisik: perlengkapan fisik pemakaman (peti, bunga, dll)
- ritual_prosesi: hal-hal yang perlu dipersiapkan untuk prosesi
- dokumen: dokumen yang perlu disiapkan
- lainnya: kebutuhan lain

Tentukan target_role untuk setiap item:
- gudang: item yang perlu disiapkan gudang
- dekor: item yang ditangani tim dekor
- konsumsi: item yang ditangani tim konsumsi
- admin: item administratif

Kembalikan HANYA JSON valid:
{
  "religion": "nama agama",
  "checklist": [
    {
      "item_name": "nama item",
      "item_category": "kategori",
      "target_role": "role",
      "notes": "catatan opsional"
    }
  ]
}
PROMPT;

    public function generate(Order $order): array
    {
        $packageName = $order->package ? $order->package->name : ($order->custom_package_name ?? 'N/A');
        
        $messages = [
            ['role' => 'system', 'content' => self::SYSTEM_PROMPT],
            ['role' => 'user', 'content' => "Generate checklist pemakaman untuk agama: {$order->deceased_religion}. Paket yang dipilih: {$packageName}. Catatan khusus: {$order->special_notes}"]
        ];

        $result = $this->callOpenAI('checklist_generator', $messages, [], $order->id);

        if ($result['success']) {
            $content = $result['content'];
            // Clean markdown if present
            $content = preg_replace('/^```json\s*|\s*```$/', '', trim($content));
            $data = json_decode($content, true);

            if ($data && isset($data['checklist'])) {
                foreach ($data['checklist'] as $item) {
                    OrderChecklist::create([
                        'order_id' => $order->id,
                        'religion' => $order->deceased_religion,
                        'item_name' => $item['item_name'],
                        'item_category' => $item['item_category'],
                        'target_role' => $item['target_role'],
                    ]);
                }
            }
        }
        return $result;
    }
}
