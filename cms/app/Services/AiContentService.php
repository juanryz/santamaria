<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class AiContentService
{
    protected string $apiKey;
    protected string $textModel = 'gpt-4o-mini';
    protected string $imageModel = 'dall-e-3';

    public function __construct()
    {
        $this->apiKey = (string) config('services.openai.key');
    }

    public function isConfigured(): bool
    {
        return $this->apiKey !== '';
    }

    /**
     * Generate a full SEO-optimized blog article about a given topic.
     * Returns: [title, slug_hint, excerpt, body_html, category, tags[], meta_title, meta_description, image_prompt]
     */
    public function generateArticle(string $topic, ?string $category = null): array
    {
        $brandContext = <<<CTX
            Santa Maria Funeral Organizer adalah penyedia layanan pemakaman terpadu di Semarang, Indonesia.
            Layanan meliputi: transportasi jenazah, dekorasi & rangkaian bunga, konsumsi & katering,
            pendampingan keagamaan (lintas agama), perlengkapan pemakaman (peti, guci abu), dan aplikasi
            pemantauan real-time dengan GPS tracking. Beroperasi 24/7 dengan nomor kontak 024-3560444 dan WA 081.128.8286.
            Alamat: Jl. Citarum Tengah E-1, Semarang 50126.
            Tone konten: empatik, profesional, informatif, tidak sensasional.
            Target audiens: keluarga berduka dan pembaca umum yang mencari informasi seputar pemakaman, tradisi, dukungan emosional.
        CTX;

        $systemPrompt = <<<SYS
            Kamu adalah content writer SEO senior untuk website Santa Maria Funeral Organizer.
            Tulis artikel blog berbahasa Indonesia yang SEO-friendly (1000-1500 kata), terstruktur rapi dengan H2 dan H3,
            empatik dan tidak clickbait, relevan dengan layanan pemakaman.

            $brandContext

            Output HARUS valid JSON dengan struktur berikut:
            {
              "title": "Judul menarik, mengandung keyword, maks 70 karakter",
              "excerpt": "Ringkasan 1-2 kalimat yang memikat, maks 300 karakter",
              "body_html": "Konten lengkap dalam HTML (gunakan <h2>, <h3>, <p>, <ul>, <li>, <strong>, <em>). JANGAN sertakan <html>/<body>. Minimal 1000 kata.",
              "category": "salah satu: umum, panduan, tradisi, tips, edukasi",
              "tags": ["3-6 tag relevan"],
              "meta_title": "Judul SEO maks 60 karakter (bisa berbeda dari title)",
              "meta_description": "Meta description SEO 140-160 karakter",
              "image_prompt": "Prompt bahasa Inggris deskriptif untuk DALL-E 3 menggambarkan cover image artikel ini. Style: elegant, tasteful, muted colors (navy/gold/cream), calming atmosphere. HINDARI gambar jenazah/peti mati/simbol religius eksplisit. Contoh: 'Elegant minimalist illustration of a candle beside white lilies on a wooden table, soft golden morning light, muted warm tones, serene atmosphere, editorial photography style'"
            }

            HANYA output JSON, tanpa penjelasan, tanpa markdown code fence.
        SYS;

        $userPrompt = "Topik artikel: {$topic}";
        if ($category) {
            $userPrompt .= "\nKategori yang diinginkan: {$category}";
        }

        $response = Http::withToken($this->apiKey)
            ->timeout(120)
            ->post('https://api.openai.com/v1/chat/completions', [
                'model' => $this->textModel,
                'messages' => [
                    ['role' => 'system', 'content' => $systemPrompt],
                    ['role' => 'user', 'content' => $userPrompt],
                ],
                'temperature' => 0.8,
                'response_format' => ['type' => 'json_object'],
            ]);

        if (! $response->successful()) {
            throw new \RuntimeException('OpenAI API error: '.$response->body());
        }

        $content = $response->json('choices.0.message.content');
        $data = json_decode($content, true);

        if (! is_array($data) || empty($data['title']) || empty($data['body_html'])) {
            throw new \RuntimeException('Invalid AI response structure.');
        }

        return [
            'title' => $data['title'],
            'excerpt' => Str::limit($data['excerpt'] ?? '', 500, ''),
            'body_html' => $data['body_html'],
            'category' => $data['category'] ?? ($category ?? 'umum'),
            'tags' => array_values(array_filter((array) ($data['tags'] ?? []))),
            'meta_title' => Str::limit($data['meta_title'] ?? $data['title'], 255, ''),
            'meta_description' => Str::limit($data['meta_description'] ?? '', 500, ''),
            'image_prompt' => $data['image_prompt'] ?? null,
        ];
    }

    /**
     * Generate cover image via DALL-E 3 and return storage path (on 'public' disk).
     */
    public function generateImage(string $prompt, string $folder = 'articles'): ?string
    {
        $response = Http::withToken($this->apiKey)
            ->timeout(180)
            ->post('https://api.openai.com/v1/images/generations', [
                'model' => $this->imageModel,
                'prompt' => $prompt,
                'n' => 1,
                'size' => '1792x1024',
                'quality' => 'standard',
                'response_format' => 'b64_json',
            ]);

        if (! $response->successful()) {
            throw new \RuntimeException('DALL-E API error: '.$response->body());
        }

        $b64 = $response->json('data.0.b64_json');
        if (! $b64) {
            return null;
        }

        $binary = base64_decode($b64);
        $filename = $folder.'/ai-'.Str::random(16).'.png';
        Storage::disk('public')->put($filename, $binary);

        return $filename;
    }
}
