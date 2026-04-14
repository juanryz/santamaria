<?php

namespace App\Jobs;

use App\Models\Order;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class GenerateDukaText implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(private Order $order) {}

    public function handle(): void
    {
        try {
            // Generate duka text via OpenAI
            $client = \OpenAI::client(config('services.openai.api_key'));
            $result = $client->chat()->create([
                'model'    => 'gpt-4o-mini',
                'messages' => [
                    ['role' => 'system', 'content' => 'Kamu adalah asisten yang membantu membuat teks ucapan duka dalam bahasa Indonesia yang penuh empati dan sopan.'],
                    ['role' => 'user',   'content'  => "Buat teks ucapan duka singkat untuk almarhum {$this->order->deceased_name} (agama: {$this->order->deceased_religion}). Ucapan ditujukan kepada keluarga."],
                ],
                'max_tokens' => 200,
            ]);

            $dukaText = $result->choices[0]->message->content ?? null;
            if ($dukaText) {
                $this->order->update(['duka_text' => $dukaText]);
            }
        } catch (\Throwable $e) {
            Log::warning("GenerateDukaText failed for order {$this->order->id}: {$e->getMessage()}");
        }
    }
}
