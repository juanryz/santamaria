<?php

namespace App\Http\Controllers\ServiceOfficer;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderStatusLog;
use App\Services\NotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class WalkInController extends Controller
{
    // POST /so/orders/walkin — SO kantor/lapangan input order tanpa consumer punya akun
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            // Data Penanggung Jawab (consumer mungkin tidak punya akun)
            'pic_name'             => 'required|string|max:255',
            'pic_phone'            => 'required|string|max:20',
            'pic_relation'         => 'required|in:anak,suami_istri,orang_tua,saudara,lainnya',
            'pic_address'          => 'required|string',
            'pic_user_id'          => 'nullable|uuid|exists:users,id',

            // Data Almarhum
            'deceased_name'        => 'required|string|max:255',
            'deceased_dob'         => 'nullable|date',
            'deceased_dod'         => 'required|date',
            'deceased_religion'    => 'required|in:islam,kristen,katolik,hindu,buddha,konghucu',
            'pickup_address'       => 'required|string',
            'pickup_lat'           => 'nullable|numeric',
            'pickup_lng'           => 'nullable|numeric',
            'destination_address'  => 'required|string',
            'destination_lat'      => 'nullable|numeric',
            'destination_lng'      => 'nullable|numeric',
            'special_notes'        => 'nullable|string',
            'estimated_guests'     => 'nullable|integer|min:0',

            'so_channel'           => 'required|in:field,office',
        ]);

        $soUser = $request->user();

        // Generate order number
        $orderNumber = 'SM-' . now()->format('Ymd') . '-' . str_pad(
            Order::whereDate('created_at', today())->count() + 1, 4, '0', STR_PAD_LEFT
        );

        $order = Order::create(array_merge($data, [
            'order_number'          => $orderNumber,
            'status'                => 'pending',
            'so_user_id'            => $soUser->id,
            'created_by_so_channel' => $data['so_channel'],
        ]));

        // Alarm ke semua SO aktif
        NotificationService::sendToRole(
            'service_officer',
            'ALARM',
            'Order Baru Masuk!',
            "Order {$order->order_number} dari {$data['pic_name']} ({$data['so_channel']} channel). Segera konfirmasi.",
            ['order_id' => $order->id, 'action' => 'confirm_order']
        );

        OrderStatusLog::create([
            'order_id'    => $order->id,
            'user_id'     => $soUser->id,
            'from_status' => null,
            'to_status'   => 'pending',
            'notes'       => "Walk-in order dibuat oleh SO ({$data['so_channel']}).",
        ]);

        return response()->json($order, 201);
    }
}
