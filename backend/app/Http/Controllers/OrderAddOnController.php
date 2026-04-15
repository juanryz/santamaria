<?php

namespace App\Http\Controllers;

use App\Enums\UserRole;
use App\Models\AddOnService;
use App\Models\Order;
use App\Models\OrderAddOn;
use Illuminate\Http\Request;

class OrderAddOnController extends Controller
{
    public function index()
    {
        $addons = AddOnService::where('is_active', true)->get();
        return response()->json([
            'success' => true,
            'data' => $addons
        ]);
    }

    public function store($orderId, Request $request)
    {
        $request->validate([
            'add_on_service_id' => 'required|uuid|exists:add_on_services,id',
            'quantity' => 'nullable|integer|min:1'
        ]);

        // Security check: only consumer of this order or service officer can add it
        $order = Order::findOrFail($orderId);
        
        $user = $request->user();
        if ($user->role === UserRole::CONSUMER->value) {
            if ($order->pic_user_id !== $user->id) {
                return response()->json(['message' => 'Unauthorized'], 403);
            }
        } elseif ($user->role === UserRole::SERVICE_OFFICER->value) {
            // SO can add to any order or just theirs, depending on business rules.
            // Assuming SO can touch any order that is pending or in review.
        } else {
             return response()->json(['message' => 'Unauthorized'], 403);
        }

        $addonService = AddOnService::findOrFail($request->add_on_service_id);

        $orderAddOn = OrderAddOn::create([
            'order_id' => $order->id,
            'add_on_service_id' => $addonService->id,
            'price_at_time' => $addonService->price,
            'quantity' => $request->quantity ?? 1
        ]);

        return response()->json([
            'success' => true,
            'data' => $orderAddOn->load('addOnService'),
            'message' => 'Add-On berhasil ditambahkan'
        ]);
    }
}
