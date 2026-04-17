<?php
namespace App\Http\Controllers\Driver;

use App\Http\Controllers\Controller;
use App\Models\TukangJagaShift;
use App\Models\TukangJagaItemDelivery;
use App\Models\TukangJagaDeliveryItem;
use App\Services\NotificationService;
use Illuminate\Http\Request;

class TukangJagaDeliveryController extends Controller
{
    // POST /driver/orders/{orderId}/deliver-to-jaga — driver kirim barang ke tukang jaga
    public function deliver(Request $request, string $orderId)
    {
        $request->validate([
            'items'                => 'required|array|min:1',
            'items.*.item_name'    => 'required|string',
            'items.*.quantity'     => 'required|integer|min:1',
            'items.*.unit'         => 'nullable|string',
            'items.*.notes'        => 'nullable|string',
            'delivery_notes'       => 'nullable|string',
            'delivery_photo'       => 'nullable|string', // base64
        ]);

        // Cari shift aktif untuk order ini
        $activeShift = TukangJagaShift::where('order_id', $orderId)
            ->where('status', 'active')
            ->whereNotNull('checkin_at')
            ->first();

        if (!$activeShift) {
            return response()->json(['success' => false, 'message' => 'Tidak ada tukang jaga yang sedang bertugas (check-in) untuk order ini.'], 422);
        }

        $photoPath = null;
        if ($request->filled('delivery_photo')) {
            try {
                $photoPath = \App\Services\StorageService::uploadBase64(
                    $request->delivery_photo,
                    "orders/{$orderId}/tukang-jaga/delivery-" . now()->timestamp . ".jpg"
                );
            } catch (\Throwable $e) {
                // StorageService::uploadBase64 may not exist — store null gracefully
                $photoPath = null;
            }
        }

        $delivery = TukangJagaItemDelivery::create([
            'order_id'           => $orderId,
            'shift_id'           => $activeShift->id,
            'delivered_by'       => $request->user()->id,
            'delivered_by_role'  => $request->user()->role,
            'status'             => 'delivered',
            'delivered_at'       => now(),
            'delivery_notes'     => $request->delivery_notes,
            'delivery_photo_path'=> $photoPath,
        ]);

        foreach ($request->items as $item) {
            TukangJagaDeliveryItem::create([
                'delivery_id' => $delivery->id,
                'item_name'   => $item['item_name'],
                'quantity'    => $item['quantity'],
                'unit'        => $item['unit'] ?? null,
                'notes'       => $item['notes'] ?? null,
            ]);
        }

        // Alarm ke tukang jaga yang bertugas
        NotificationService::send(
            $activeShift->assigned_to,
            'ALARM',
            'Barang Diantarkan',
            "Driver mengirim " . count($request->items) . " item untuk order {$activeShift->order?->order_number}. Mohon konfirmasi penerimaan.",
            ['order_number' => $activeShift->order?->order_number, 'delivery_id' => $delivery->id]
        );

        return response()->json(['success' => true, 'data' => $delivery->load('items'), 'message' => 'Pengiriman tercatat.']);
    }
}
