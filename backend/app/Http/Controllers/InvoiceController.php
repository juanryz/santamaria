<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Models\OrderBillingItem;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Request;

class InvoiceController extends Controller
{
    /**
     * Generate an invoice PDF for a specific order.
     *
     * Accessible by:
     *   - Finance/Purchasing: GET /finance/orders/{orderId}/invoice-pdf
     *   - Consumer: GET /consumer/orders/{id}/invoice (only if payment_status allows)
     */
    public function generatePdf(Request $request, string $orderId)
    {
        $order = Order::with('pic', 'package')->findOrFail($orderId);

        // If consumer, only allow after order is completed or payment proof uploaded
        $user = $request->user();
        if ($user && $user->role === 'consumer') {
            if (! in_array($order->payment_status, ['paid', 'proof_uploaded', 'proof_rejected'])
                && $order->status !== 'completed') {
                return response()->json([
                    'success' => false,
                    'message' => 'Invoice belum tersedia. Order belum selesai.',
                ], 403);
            }

            // Ensure consumer only accesses their own order
            if ($order->pic_user_id && $order->pic_user_id !== $user->id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Anda tidak memiliki akses ke order ini.',
                ], 403);
            }
        }

        $items = OrderBillingItem::where('order_id', $orderId)
            ->with('billingMaster')
            ->orderBy('created_at')
            ->get();

        $subtotal      = $items->sum('total_price');
        $totalTambahan = $items->sum('tambahan');
        $totalKembali  = $items->sum('kembali');
        $grandTotal    = $subtotal + $totalTambahan - $totalKembali;

        // Payment display values
        $paymentMethod = match ($order->payment_method) {
            'cash'     => 'Tunai (Cash)',
            'transfer' => 'Transfer Bank',
            default    => '-',
        };

        $paymentStatusLabel = match ($order->payment_status) {
            'paid'           => 'LUNAS',
            'proof_uploaded' => 'Menunggu Verifikasi',
            'proof_rejected' => 'Bukti Ditolak',
            default          => 'Belum Lunas',
        };

        $paymentStatusClass = match ($order->payment_status) {
            'paid'           => 'status-paid',
            'proof_uploaded' => 'status-proof',
            default          => 'status-unpaid',
        };

        $data = [
            'order'              => $order,
            'items'              => $items,
            'subtotal'           => $subtotal,
            'totalTambahan'      => $totalTambahan,
            'totalKembali'       => $totalKembali,
            'grandTotal'         => $grandTotal,
            'paymentMethod'      => $paymentMethod,
            'paymentStatusLabel' => $paymentStatusLabel,
            'paymentStatusClass' => $paymentStatusClass,
            'generatedAt'        => now()->format('d M Y H:i'),
        ];

        $pdf = Pdf::loadView('invoices.order_invoice', $data);
        $pdf->setPaper('A4', 'portrait');

        return $pdf->download("Invoice-{$order->order_number}.pdf");
    }
}
