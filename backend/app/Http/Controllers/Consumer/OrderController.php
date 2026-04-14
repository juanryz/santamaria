<?php

namespace App\Http\Controllers\Consumer;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderStatusLog;
use App\Services\NotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class OrderController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'pic_name' => 'required|string',
            'pic_phone' => 'required|string',
            'pic_relation' => 'required|in:anak,suami_istri,orang_tua,saudara,lainnya',
            'pic_address' => 'required|string',
            'deceased_name' => 'required|string',
            'deceased_dod' => 'required|date',
            'deceased_religion' => 'required|in:islam,kristen,katolik,hindu,buddha,konghucu',
            'pickup_address' => 'required|string',
            'destination_address' => 'required|string',
        ]);

        return DB::transaction(function () use ($request) {
            $orderNumber = 'SM-' . date('Ymd') . '-' . strtoupper(Str::random(4));
            
            $orderData = $request->all();
            $orderData['order_number'] = $orderNumber;
            $orderData['pic_user_id'] = $request->user()->id;
            $orderData['status'] = 'pending';

            $order = Order::create($orderData);

            OrderStatusLog::create([
                'order_id' => $order->id,
                'user_id' => $request->user()->id,
                'to_status' => 'pending',
                'notes' => 'Order baru dibuat oleh konsumen'
            ]);

            NotificationService::sendToRole(
                UserRole::SERVICE_OFFICER->value,
                'ALARM',
                'Order Baru Masuk',
                "Ada order baru dari konsumen: {$order->order_number}. Segera proses!",
                ['order_id' => $order->id]
            );

            return response()->json([
                'success' => true,
                'data' => $order,
                'message' => 'Order created successfully'
            ], 201);
        });
    }

    public function index(Request $request)
    {
        $orders = Order::where('pic_user_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $orders
        ]);
    }

    public function show($id, Request $request)
    {
        $storageService = app(\App\Services\StorageService::class);

        $order = Order::with(['driver', 'package', 'photos', 'orderAddOns'])
            ->where('pic_user_id', $request->user()->id)
            ->findOrFail($id);

        // Append URL to each photo
        $orderData = $order->toArray();
        $orderData['photos'] = collect($order->photos)->map(fn($photo) => array_merge(
            $photo->toArray(),
            ['url' => $storageService->getSignedUrl($photo->file_path)]
        ))->values()->toArray();

        return response()->json([
            'success' => true,
            'data' => $orderData
        ]);
    }
}
