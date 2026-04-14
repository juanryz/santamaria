<?php

namespace App\Services\AI;

use OpenAI\Laravel\Facades\OpenAI;

class VoiceTranscriptionService extends BaseAiService
{
    public function transcribeAndExtract(string $audioFilePath): array
    {
        try {
            // Step 1: Transcribe using Whisper API
            $transcription = OpenAI::audio()->transcribe([
                'model' => 'whisper-1',
                'file' => fopen($audioFilePath, 'r'),
                'language' => 'id',
            ]);

            $transcribedText = $transcription->text;

            // Step 2: Extract structured data from transcription
            $systemPrompt = <<<PROMPT
Kamu menerima transkripsi voice note dari keluarga yang ingin memesan layanan pemakaman.
Ekstrak informasi berikut dari teks transkripsi jika ada:
- Nama almarhum
- Tanggal lahir almarhum (jika disebutkan)
- Tanggal meninggal
- Agama almarhum
- Alamat penjemputan
- Alamat tujuan/pemakaman
- Nama penanggung jawab
- Hubungan dengan almarhum
- Estimasi jumlah tamu
- Kebutuhan khusus

Kembalikan HANYA JSON valid berikut tanpa penjelasan apapun:
{
  "transcription": "teks lengkap transkripsi",
  "extracted": {
    "deceased_name": null,
    "deceased_dob": null,
    "deceased_dod": null,
    "deceased_religion": null,
    "pickup_address": null,
    "destination_address": null,
    "pic_name": null,
    "pic_relation": null,
    "estimated_guests": null,
    "special_notes": null
  },
  "confidence_notes": "catatan tentang data yang tidak yakin atau tidak lengkap"
}
PROMPT;

            $messages = [
                ['role' => 'system', 'content' => $systemPrompt],
                ['role' => 'user', 'content' => "Transkripsi voice note: {$transcribedText}"]
            ];

            $result = $this->callOpenAI('voice_to_text', $messages);

            if ($result['success']) {
                $json = json_decode($result['content'], true);
                if (!$json) {
                     // Try to fix JSON if AI wrapped it in markdown
                     $clean = preg_replace('/^```json\s*|\s*```$/', '', trim($result['content']));
                     $json = json_decode($clean, true);
                }
                return ['success' => true, 'data' => $json];
            }
            return $result;

        } catch (\Exception $e) {
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }
}
