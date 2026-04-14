<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Models\OrderBillingItem;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Request;

class BillingExportController extends Controller
{
    public function exportPdf($orderId)
    {
        $order = Order::with('pic', 'package')->findOrFail($orderId);

        $items = OrderBillingItem::where('order_id', $orderId)
            ->with('billingMaster')
            ->orderBy('created_at')
            ->get();

        $total = $items->sum('total_price');
        $totalTambahan = $items->sum('tambahan');
        $totalKembali = $items->sum('kembali');
        $grandTotal = $total + $totalTambahan - $totalKembali;

        $data = [
            'order' => $order,
            'items' => $items,
            'total' => $total,
            'totalTambahan' => $totalTambahan,
            'totalKembali' => $totalKembali,
            'grandTotal' => $grandTotal,
            'generatedAt' => now()->format('d M Y H:i'),
        ];

        $pdf = Pdf::loadView('pdf.billing-report', $data);
        $pdf->setPaper('A4', 'portrait');

        return $pdf->download("Laporan-Tagihan-{$order->order_number}.pdf");
    }
}
