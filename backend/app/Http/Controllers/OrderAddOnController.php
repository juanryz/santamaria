<?php

namespace App\Http\Controllers;

use App\Enums\UserRole;
use App\Models\AddOnService;
use App\Models\Order;
use App\Models\OrderAddOn;
use App\Models\OrderBillingItem;
use App\Services\NotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

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
            'quantity'          => 'nullable|integer|min:1',
        ]);

        $order = Order::findOrFail($orderId);
        $user  = $request->user();

        // Only consumer (own order) or SO can add add-ons during active event
        if ($user->role === UserRole::CONSUMER->value) {
            if ($order->pic_user_id !== $user->id) {
                return response()->json(['message' => 'Unauthorized'], 403);
            }
            // Consumer can only add while event is ongoing or confirmed
            if (!in_array($order->status, ['confirmed', 'in_progress'])) {
                return response()->json([
                    'success'    => false,
                    'message'    => 'Layanan tambahan hanya bisa ditambahkan saat acara sedang berlangsung.',
                    'error_code' => 'ORDER_NOT_ACTIVE',
                ], 422);
            }
        } elseif ($user->role === UserRole::SERVICE_OFFICER->value) {
            // SO can add to any confirmed/in_progress order
            if (!in_array($order->status, ['confirmed', 'in_progress', 'pending'])) {
                return response()->json([
                    'success'    => false,
                    'message'    => 'Order sudah selesai atau dibatalkan.',
                    'error_code' => 'ORDER_NOT_ACTIVE',
                ], 422);
            }
        } else {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $addonService = AddOnService::findOrFail($request->add_on_service_id);
        $qty          = $request->quantity ?? 1;

        return DB::transaction(function () use ($order, $addonService, $qty, $user) {
            // 1. Create OrderAddOn record
            $orderAddOn = OrderAddOn::create([
                'order_id'          => $order->id,
                'add_on_service_id' => $addonService->id,
                'price_at_time'     => $addonService->price,
                'quantity'          => $qty,
            ]);

            // 2. Create order_billing_items entry (source = addon)
            // billing_master_id is nullable for add-ons added during the event
            OrderBillingItem::create([
                'order_id'          => $order->id,
                'billing_master_id' => null,
                'qty'               => $qty,
                'unit'              => 'pcs',
                'unit_price'        => $addonService->price,
                'total_price'       => $addonService->price * $qty,
                'source'            => 'addon',
                'notes'             => "Add-on: {$addonService->name} (ditambah saat acara)",
            ]);

            // 3. Notify SO and Gudang
            $addedBy = $user->role === UserRole::CONSUMER->value
                ? "Konsumen {$order->pic_name}"
                : "SO {$user->name}";

            if ($order->so_user_id) {
                NotificationService::send($order->so_user_id, 'INFO',
                    'Add-On Ditambahkan',
                    "{$addedBy} menambahkan '{$addonService->name}' (×{$qty}) pada order {$order->order_number}.",
                    ['order_id' => $order->id]
                );
            }

            NotificationService::sendToRole(UserRole::GUDANG->value, 'INFO',
                'Add-On Order Aktif',
                "Add-on '{$addonService->name}' ×{$qty} ditambahkan pada order {$order->order_number}.",
                ['order_id' => $order->id]
            );

            return response()->json([
                'success' => true,
                'data'    => $orderAddOn->load('addOnService'),
                'message' => 'Layanan tambahan berhasil ditambahkan.',
            ]);
        });
    }
}
