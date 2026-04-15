<?php

namespace App\Http\Controllers\Finance;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Services\FinancialTransactionService;
use App\Services\NotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ConsumerPaymentController extends Controller
{
    public function __construct(private FinancialTransactionService $finService) {}

    // GET /finance/orders — list semua order aktif yang perlu dipantau Finance
    public function index(Request $request): JsonResponse
    {
        $query = Order::with(['package:id,name,base_price', 'soUser:id,name'])
            ->whereIn('status', ['confirmed', 'approved', 'in_progress', 'completed', 'pending'])
            ->whereNotIn('status', ['cancelled']);

        // Filter by payment_status if requested
        if ($request->filled('payment_status')) {
            $query->where('payment_status', $request->payment_status);
        }

        $orders = $query
            ->orderByRaw("CASE payment_status
                WHEN 'proof_uploaded' THEN 0
                WHEN 'unpaid' THEN 1
                WHEN 'proof_rejected' THEN 2
                ELSE 3 END")
            ->orderByDesc('created_at')
            ->get();

        return response()->json(['success' => true, 'data' => $orders]);
    }

    // GET /finance/orders/{id} — lihat detail order
    public function show(string $id): JsonResponse
    {
        $order = Order::with(['package', 'pic', 'soUser', 'orderAddOns.addOnService'])
            ->findOrFail($id);

        return response()->json(['success' => true, 'data' => $order]);
    }

    // GET /finance/orders/{id}/payment-proof — lihat foto bukti (signed URL)
    public function getPaymentProof(string $id): JsonResponse
    {
        $order = Order::findOrFail($id);
        abort_if(!$order->payment_proof_path, 404, 'Bukti belum diupload.');

        $url = \App\Services\StorageService::getSignedUrl($order->payment_proof_path);

        return response()->json([
            'order_number'              => $order->order_number,
            'payment_proof_url'         => $url,
            'payment_proof_uploaded_at' => $order->payment_proof_uploaded_at,
            'final_price'               => $order->final_price,
        ]);
    }

    // PUT /finance/orders/{id}/payment/verify — konfirmasi lunas
    public function verify(Request $request, string $id): JsonResponse
    {
        $data = $request->validate([
            'notes' => 'nullable|string',
        ]);

        $order = Order::where('payment_status', 'proof_uploaded')->findOrFail($id);

        if ($order->payment_method === 'cash') {
            return response()->json(['success' => false, 'message' => 'Gunakan endpoint cash-paid untuk pembayaran cash.'], 422);
        }

        $order->update([
            'payment_status'      => 'paid',
            'payment_verified_by' => $request->user()->id,
            'payment_updated_at'  => now(),
            'payment_notes'       => $data['notes'] ?? null,
        ]);

        // Record financial transaction
        $this->finService->record([
            'transaction_type' => 'order_payment',
            'reference_type'   => 'order',
            'reference_id'     => $order->id,
            'order_id'         => $order->id,
            'amount'           => $order->final_price ?? $order->total_amount ?? 0,
            'direction'        => 'in',
            'category'         => $this->resolveIncomeCategory($order),
            'description'      => "Pembayaran transfer order {$order->order_number}",
            'transaction_date' => now()->toDateString(),
            'recorded_by'      => $request->user()->id,
            'metadata'         => ['payment_method' => $order->payment_method],
        ]);

        // Notif consumer
        if ($order->pic_user_id) {
            NotificationService::send(
                $order->pic_user_id,
                'HIGH',
                'Pembayaran Dikonfirmasi',
                "Pembayaran untuk order {$order->order_number} telah dikonfirmasi. Terima kasih.",
                ['order_id' => $order->id, 'action' => 'view_order']
            );
        }

        // Notif owner
        NotificationService::sendToRole('owner', 'NORMAL',
            'Payment Dikonfirmasi',
            "Order {$order->order_number} sudah lunas. Nilai: Rp " . number_format($order->final_price ?? 0, 0, ',', '.'),
            ['order_id' => $order->id]
        );

        return response()->json(['message' => 'Payment dikonfirmasi lunas.']);
    }

    // POST /finance/orders/{id}/cash-paid — tandai lunas untuk pembayaran cash
    public function markCashPaid(Request $request, string $id): JsonResponse
    {
        $order = Order::findOrFail($id);

        if ($order->payment_method !== 'cash') {
            return response()->json(['success' => false, 'message' => 'Metode pembayaran bukan cash.'], 422);
        }
        if ($order->payment_status === 'paid') {
            return response()->json(['success' => false, 'message' => 'Order sudah lunas.'], 422);
        }

        $order->update([
            'payment_status'    => 'paid',
            'cash_received_at'  => now(),
            'cash_received_by'  => $request->user()->id,
            'payment_amount'    => $request->input('amount', $order->final_price),
            'payment_notes'     => $request->input('notes'),
        ]);

        // Record financial transaction
        $this->finService->record([
            'transaction_type' => 'order_payment',
            'reference_type'   => 'order',
            'reference_id'     => $order->id,
            'order_id'         => $order->id,
            'amount'           => $request->input('amount', $order->final_price ?? $order->total_amount ?? 0),
            'direction'        => 'in',
            'category'         => $this->resolveIncomeCategory($order),
            'description'      => "Pembayaran cash order {$order->order_number}",
            'transaction_date' => now()->toDateString(),
            'recorded_by'      => $request->user()->id,
            'metadata'         => ['payment_method' => 'cash'],
        ]);

        // Notif ke consumer
        if ($order->pic_user_id) {
            NotificationService::send(
                $order->pic_user_id,
                'HIGH',
                'Pembayaran Dikonfirmasi',
                "Pembayaran cash untuk order {$order->order_number} telah dikonfirmasi. Terima kasih.",
                ['order_id' => $order->id, 'action' => 'view_order']
            );
        }

        return response()->json(['success' => true, 'message' => 'Pembayaran cash dikonfirmasi.', 'data' => $order->fresh()]);
    }

    // PUT /finance/orders/{id}/payment/reject — tolak bukti, consumer harus upload ulang
    public function reject(Request $request, string $id): JsonResponse
    {
        $data = $request->validate([
            'reason' => 'required|string',
        ]);

        $order = Order::where('payment_status', 'proof_uploaded')->findOrFail($id);

        $order->update([
            'payment_status' => 'proof_rejected',
            'payment_notes'  => $data['reason'],
        ]);

        if ($order->pic_user_id) {
            NotificationService::send(
                $order->pic_user_id,
                'HIGH',
                'Bukti Payment Ditolak',
                "Bukti payment untuk order {$order->order_number} ditolak. Alasan: {$data['reason']}. Silakan upload ulang.",
                ['order_id' => $order->id, 'action' => 'upload_payment_proof']
            );
        }

        return response()->json(['message' => 'Bukti ditolak. Konsumen akan diminta upload ulang.']);
    }

    private function resolveIncomeCategory(Order $order): string
    {
        $packageName = strtolower($order->package?->name ?? '');
        if (str_contains($packageName, 'dasar'))     return 'paket_dasar';
        if (str_contains($packageName, 'premium'))   return 'paket_premium';
        if (str_contains($packageName, 'eksklusif')) return 'paket_eksklusif';
        return 'jasa_funeral';
    }
}
