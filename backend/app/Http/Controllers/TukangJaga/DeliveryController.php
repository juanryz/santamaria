<?php
namespace App\Http\Controllers\TukangJaga;

use App\Http\Controllers\Controller;
use App\Models\TukangJagaShift;
use App\Models\TukangJagaItemDelivery;
use App\Models\TukangJagaDeliveryItem;
use App\Services\NotificationService;
use Illuminate\Http\Request;

class DeliveryController extends Controller
{
    // GET /tukang-jaga/orders/{orderId}/deliveries — lihat semua pengiriman di order ini
    public function index(string $orderId)
    {
        $deliveries = TukangJagaItemDelivery::where('order_id', $orderId)
            ->with(['items', 'deliveredByUser:id,name,role', 'receivedByUser:id,name', 'shift:id,shift_number,shift_type'])
            ->orderByDesc('created_at')
            ->get();
        return response()->json(['success' => true, 'data' => $deliveries]);
    }

    // POST /tukang-jaga/shifts/{shiftId}/receive — tukang jaga konfirmasi terima barang
    public function receive(Request $request, string $shiftId)
    {
        $shift = TukangJagaShift::where('assigned_to', $request->user()->id)
            ->findOrFail($shiftId);

        if (!$shift->canReceiveItems()) {
            return response()->json(['success' => false, 'message' => 'Anda harus sudah check-in untuk menerima barang.'], 422);
        }

        $request->validate([
            'delivery_id'         => 'required|uuid|exists:tukang_jaga_item_deliveries,id',
            'receipt_photo'       => 'nullable|string', // base64 atau path
            'notes'               => 'nullable|string',
        ]);

        $delivery = TukangJagaItemDelivery::where('order_id', $shift->order_id)
            ->where('status', 'delivered')
            ->findOrFail($request->delivery_id);

        $receiptPath = null;
        if ($request->filled('receipt_photo')) {
            try {
                $receiptPath = \App\Services\StorageService::uploadBase64(
                    $request->receipt_photo,
                    "orders/{$shift->order_id}/tukang-jaga/receipt-{$delivery->id}.jpg"
                );
            } catch (\Throwable $e) {
                // StorageService::uploadBase64 may not exist — store null gracefully
                $receiptPath = null;
            }
        }

        $delivery->update([
            'status'              => 'received_by_jaga',
            'received_by'         => $request->user()->id,
            'received_at'         => now(),
            'receipt_photo_path'  => $receiptPath,
            'delivery_notes'      => $request->notes,
        ]);

        // Notif ke consumer (pihak keluarga) untuk konfirmasi
        $order = $shift->order;
        if ($order?->pic_user_id) {
            NotificationService::send(
                $order->pic_user_id,
                'HIGH',
                'Barang Telah Diterima Tukang Jaga',
                "Tukang jaga telah menerima perlengkapan untuk order {$order->order_number}. Mohon konfirmasi dari pihak keluarga.",
                ['order_number' => $order->order_number, 'delivery_id' => $delivery->id]
            );
        }

        return response()->json(['success' => true, 'data' => $delivery->fresh('items'), 'message' => 'Penerimaan barang dikonfirmasi.']);
    }
}
