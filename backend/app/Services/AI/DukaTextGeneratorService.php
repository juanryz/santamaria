<?php

namespace App\Services\AI;

use App\Models\Order;

class DukaTextGeneratorService extends BaseAiService
{
    private const SYSTEM_PROMPT = <<<PROMPT
Kamu adalah penulis teks berita duka yang profesional dan empatik.
Buat teks ucapan duka/berita duka dalam bahasa Indonesia yang formal, sopan, dan menyentuh hati.
Teks harus mencakup: nama almarhum, tanggal lahir (jika ada), tanggal wafat, dan kalimat belasungkawa.

Format teks yang dihasilkan harus bisa langsung digunakan untuk:
- Pesan WhatsApp
- Pengumuman media sosial
- Selebaran cetak

Kembalikan HANYA JSON valid:
{
  "formal_text": "teks formal untuk pengumuman resmi",
  "whatsapp_text": "teks ringkas untuk WhatsApp (max 3 paragraf)",
  "hashtags": ["#BeritaDuka", "#RIPNamaAlmarhum"]
}
PROMPT;

    public function generate(Order $order): array
    {
        $dob = $order->deceased_dob 
            ? "lahir " . $order->deceased_dob->format('d F Y')
            : "";
        
        $userPrompt = <<<PROMPT
Nama almarhum: {$order->deceased_name}
{$dob}
Tanggal wafat: {$order->deceased_dod->format('d F Y')}
Agama: {$order->deceased_religion}
Nama keluarga penanggung jawab: {$order->pic_name} ({$order->pic_relation})
PROMPT;

        $messages = [
            ['role' => 'system', 'content' => self::SYSTEM_PROMPT],
            ['role' => 'user', 'content' => $userPrompt]
        ];

        $result = $this->callOpenAI('duka_text_generator', $messages, [], $order->id);

        if ($result['success']) {
            $content = $result['content'];
            $content = preg_replace('/^```json\s*|\s*```$/', '', trim($content));
            $data = json_decode($content, true);
            
            if ($data) {
                $order->update(['duka_text' => json_encode($data)]);
                return ['success' => true, 'data' => $data];
            }
        }
        return $result;
    }
}
