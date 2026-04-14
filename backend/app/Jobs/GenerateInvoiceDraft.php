<?php

namespace App\Jobs;

use App\Models\Order;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class GenerateInvoiceDraft implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(private Order $order) {}

    public function handle(): void
    {
        // Delegasi ke existing AI service jika ada
        try {
            $aiService = app(\App\Services\AI\InvoiceService::class ?? null);
            if ($aiService) {
                $aiService->generateDraft($this->order);
            }
        } catch (\Throwable $e) {
            Log::warning("GenerateInvoiceDraft failed for order {$this->order->id}: {$e->getMessage()}");
        }
    }
}
