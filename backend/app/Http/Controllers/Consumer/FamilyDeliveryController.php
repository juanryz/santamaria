<?php
namespace App\Http\Controllers\Consumer;

use App\Http\Controllers\Controller;
use App\Models\TukangJagaItemDelivery;
use App\Models\Order;
use App\Services\NotificationService;
use Illuminate\Http\Request;

class FamilyDeliveryController extends Controller
{
    // GET /consumer/orders/{orderId}/deliveries — pihak keluarga lihat barang yang sudah diterima jaga
    public function index(string $orderId)
    {
        $order = Order::where('pic_user_id', request()->user()->id)->findOrFail($orderId);
        $deliveries = TukangJagaItemDelivery::where('order_id', $orderId)
            ->whereIn('status', ['received_by_jaga', 'confirmed_by_family'])
            ->with(['items', 'receivedByUser:id,name', 'shift:id,shift_number,shift_type'])
            ->orderByDesc('received_at')
            ->get();
        return response()->json(['success' => true, 'data' => $deliveries]);
    }

    // POST /consumer/orders/{orderId}/deliveries/{deliveryId}/confirm — keluarga konfirmasi terima
    public function confirm(Request $request, string $orderId, string $deliveryId)
    {
        $order = Order::where('pic_user_id', $request->user()->id)->findOrFail($orderId);
        $delivery = TukangJagaItemDelivery::where('order_id', $orderId)
            ->where('status', 'received_by_jaga')
            ->findOrFail($deliveryId);

        $delivery->update([
            'status'               => 'confirmed_by_family',
            'family_confirmed_at'  => now(),
            'family_confirmed_by'  => $request->user()->id,
            'family_notes'         => $request->input('notes'),
        ]);

        return response()->json(['success' => true, 'data' => $delivery->fresh(), 'message' => 'Konfirmasi penerimaan berhasil.']);
    }
}
