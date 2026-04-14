<?php

namespace App\Http\Controllers\Consumer;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Services\NotificationService;
use App\Services\StorageService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PaymentProofController extends Controller
{
    // POST /consumer/orders/{id}/payment-proof
    public function store(Request $request, string $id): JsonResponse
    {
        $request->validate([
            'proof' => 'required_if:payment_method,transfer|file|mimes:jpg,jpeg,png,pdf|max:10240',
            'payment_method' => 'required|in:cash,transfer',
        ]);

        $order = Order::where('pic_user_id', $request->user()->id)
            ->where('status', 'completed')
            ->whereIn('payment_status', ['unpaid', 'proof_rejected'])
            ->findOrFail($id);

        $updateData = [
            'payment_method' => $request->payment_method,
        ];

        if ($request->payment_method === 'transfer' && $request->hasFile('proof')) {
            $path = (new StorageService())->uploadOrderPhoto(
                $request->file('proof'),
                "payment_proofs/{$order->id}"
            );
            $updateData['payment_proof_path'] = $path;
            $updateData['payment_proof_uploaded_at'] = now();
            $updateData['payment_status'] = 'proof_uploaded';
        } elseif ($request->payment_method === 'cash') {
            $updateData['payment_status'] = 'proof_uploaded';
        }

        $order->update($updateData);

        // Alarm Finance
        NotificationService::sendToRole(
            'finance',
            'ALARM',
            'Bukti Payment Masuk!',
            "Bukti payment untuk order {$order->order_number} sudah diterima. Segera verifikasi.",
            ['order_id' => $order->id, 'action' => 'verify_payment']
        );

        return response()->json(['message' => 'Bukti pembayaran berhasil dikirim. Tim kami akan verifikasi segera.']);
    }

    // GET /consumer/orders/{id}/payment-status
    public function status(Request $request, string $id): JsonResponse
    {
        $order = Order::where('pic_user_id', $request->user()->id)->findOrFail($id);

        return response()->json([
            'order_number'              => $order->order_number,
            'payment_status'            => $order->payment_status,
            'payment_proof_uploaded_at' => $order->payment_proof_uploaded_at,
            'final_price'               => $order->final_price,
        ]);
    }
}
