<?php

namespace App\Services\AI;

use App\Models\Order;
use App\Services\NotificationService;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Support\Facades\Storage;

class InvoiceGeneratorService extends BaseAiService
{
    public function generate(Order $order): string
    {
        // Issue date and format items
        $invoiceData = [
            'invoice_number' => 'INV-' . $order->order_number,
            'issued_date' => now()->format('d F Y'),
            'order' => $order->load('package'),
            'items' => $this->buildLineItems($order),
            'total' => $order->final_price,
        ];

        // Generate PDF using Laravel DomPDF
        // Note: You would need to create resources/views/invoices/santa_maria.blade.php
        $pdf = Pdf::loadView('invoices.santa_maria', $invoiceData);

        // Save to storage (R2/Local)
        $disk = config('filesystems.disks.r2.key') ? 'r2' : 'public';
        $path = "invoices/{$order->id}/invoice.pdf";
        Storage::disk($disk)->put($path, $pdf->output());

        // Update order
        $order->update(['invoice_path' => $path]);

        // Notify consumer
        NotificationService::send($order->pic_user_id, 'NORMAL', 'Invoice Tersedia', 'Invoice layanan pemakaman Anda sudah tersedia di aplikasi');

        return $path;
    }

    private function buildLineItems(Order $order): array
    {
        $items = [];
        if ($order->package) {
            $items[] = ['name' => $order->package->name, 'price' => $order->final_price];
        } else if ($order->custom_package_name) {
            $items[] = ['name' => $order->custom_package_name, 'price' => $order->final_price];
        }
        return $items;
    }
}
