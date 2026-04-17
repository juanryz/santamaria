<?php

namespace App\Jobs;

use App\Models\SupplierQuote;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class ValidateQuotePrice implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(private SupplierQuote $quote) {}

    public function handle(): void
    {
        try {
            $pr     = $this->quote->procurementRequest;
            $client = \OpenAI::client(config('services.openai.api_key'));

            $formattedPrice = number_format($this->quote->unit_price, 0, ',', '.');

            $result = $client->chat()->create([
                'model'    => 'gpt-4o-mini',
                'messages' => [
                    [
                        'role'    => 'system',
                        'content' => 'Kamu adalah analis harga pengadaan barang di Indonesia. Jawab HANYA dalam format JSON valid tanpa markdown, tanpa backtick. Format: {"market_price_estimate": number, "is_reasonable": boolean, "variance_percent": number, "analysis": "string penjelasan singkat"}',
                    ],
                    [
                        'role'    => 'user',
                        'content' => "Berapa harga pasaran untuk {$pr->item_name} di Indonesia saat ini? Spesifikasi: {$pr->specification}. Jumlah: {$pr->quantity} {$pr->unit}. Supplier menawar Rp {$formattedPrice} per {$pr->unit}. Apakah harga ini wajar?",
                    ],
                ],
                'max_tokens'  => 400,
                'temperature' => 0.3,
            ]);

            $raw = trim($result->choices[0]->message->content ?? '');

            // Strip markdown fences if present
            $raw = preg_replace('/^```(?:json)?\s*/i', '', $raw);
            $raw = preg_replace('/\s*```$/', '', $raw);

            $parsed = json_decode($raw, true);

            if (is_array($parsed) && isset($parsed['is_reasonable'])) {
                $this->quote->update([
                    'ai_market_price'  => $parsed['market_price_estimate'] ?? null,
                    'ai_is_reasonable' => (bool) $parsed['is_reasonable'],
                    'ai_variance_pct'  => $parsed['variance_percent'] ?? null,
                    'ai_analysis'      => $parsed['analysis'] ?? $raw,
                    'ai_analyzed_at'   => now(),
                    'status'           => 'under_review',
                ]);
            } else {
                // Fallback: store raw text, infer reasonability from keywords
                $isReasonable = !preg_match('/terlalu tinggi|anomali|tidak wajar|jauh di atas|overpriced/i', $raw);

                $this->quote->update([
                    'ai_is_reasonable' => $isReasonable,
                    'ai_analysis'      => $raw,
                    'ai_analyzed_at'   => now(),
                    'status'           => 'under_review',
                ]);
            }
        } catch (\Throwable $e) {
            Log::warning("ValidateQuotePrice failed for quote {$this->quote->id}: {$e->getMessage()}");
        }
    }
}
