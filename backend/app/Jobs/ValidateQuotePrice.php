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

            $result = $client->chat()->create([
                'model'    => 'gpt-4o-mini',
                'messages' => [
                    ['role' => 'system', 'content' => 'Kamu adalah analis harga pengadaan barang di Indonesia. Analisis apakah harga yang diajukan wajar berdasarkan kondisi pasar saat ini.'],
                    ['role' => 'user',   'content'  => "Barang: {$pr->item_name}. Spesifikasi: {$pr->specification}. Jumlah: {$pr->quantity} {$pr->unit}. Harga per unit yang diajukan: Rp " . number_format($this->quote->unit_price, 0, ',', '.') . ". Apakah harga ini wajar? Berikan estimasi harga pasar dan persentase variansi."],
                ],
                'max_tokens' => 300,
            ]);

            $analysis = $result->choices[0]->message->content ?? '';

            // Simple parsing: asumsi wajar jika tidak ada kata anomali/terlalu tinggi/tidak wajar
            $isReasonable = !preg_match('/terlalu tinggi|anomali|tidak wajar|jauh di atas/i', $analysis);

            $this->quote->update([
                'ai_is_reasonable' => $isReasonable,
                'ai_analysis'      => $analysis,
                'ai_analyzed_at'   => now(),
                'status'           => 'under_review',
            ]);
        } catch (\Throwable $e) {
            Log::warning("ValidateQuotePrice failed for quote {$this->quote->id}: {$e->getMessage()}");
        }
    }
}
