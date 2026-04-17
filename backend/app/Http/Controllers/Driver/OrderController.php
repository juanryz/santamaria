<?php

namespace App\Http\Controllers\Driver;

use App\Enums\OrderStatus;
use App\Enums\NotificationPriority;
use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Services\NotificationService;
use App\Services\OrderStateMachine;
use App\Services\OrderStatusSyncService;
use Illuminate\Http\Request;

class OrderController extends Controller
{
    public function index(Request $request)
    {
        $activeStatuses = collect(OrderStatus::activeStatuses())->map->value->toArray();

        $orders = Order::with('pic')
            ->where('driver_id', $request->user()->id)
            ->whereIn('status', $activeStatuses)
            ->orderBy('scheduled_at', 'asc')
            ->get();

        return response()->json(['success' => true, 'data' => $orders]);
    }

    public function show($id, Request $request)
    {
        $order = Order::with(['pic', 'package', 'statusLogs', 'equipmentItems', 'vehicleTripLogs'])
            ->where('driver_id', $request->user()->id)
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $order,
            'next_statuses' => OrderStateMachine::nextStatuses($order->status),
        ]);
    }

    /**
     * PUT /driver/orders/{id}/transition — state-machine driven status update.
     * Driver memilih dari next_statuses yang valid — TIDAK hardcode.
     */
    public function transition($id, Request $request)
    {
        $request->validate([
            'to_status' => 'required|string',
            'notes' => 'nullable|string',
        ]);

        $order = Order::where('driver_id', $request->user()->id)->findOrFail($id);

        if (!OrderStateMachine::canTransition($order->status, $request->to_status)) {
            return response()->json([
                'success' => false,
                'message' => "Transisi tidak valid: '{$order->status}' → '{$request->to_status}'",
                'valid_transitions' => OrderStateMachine::nextStatuses($order->status),
            ], 422);
        }

        // Record timestamps for specific transitions
        $timestamps = [];
        $toStatus = $request->to_status;

        if ($toStatus === OrderStatus::DELIVERING_EQUIPMENT->value) {
            $timestamps['driver_departed_at'] = now();
        } elseif ($toStatus === OrderStatus::EQUIPMENT_ARRIVED->value) {
            // Trigger dekor gate notification
            NotificationService::sendToRole('dekor', NotificationPriority::ALARM->value,
                'Perlengkapan Tiba!', "Perlengkapan untuk order {$order->order_number} telah tiba di lokasi.");
            NotificationService::send($order->pic_user_id, NotificationPriority::HIGH->value,
                'Perlengkapan Tiba', 'Perlengkapan prosesi telah tiba di lokasi.');
        } elseif ($toStatus === OrderStatus::BODY_ARRIVED->value) {
            $timestamps['driver_arrived_destination_at'] = now();
            NotificationService::send($order->pic_user_id, NotificationPriority::HIGH->value,
                'Jenazah Tiba', 'Jenazah telah tiba di lokasi prosesi.');
        }

        if (!empty($timestamps)) {
            $order->update($timestamps);
        }

        OrderStateMachine::transition(
            $order,
            $toStatus,
            $request->user()->id,
            $request->input('notes', "Driver update: {$toStatus}")
        );

        // Send consumer-facing notification with label from order_status_labels
        OrderStatusSyncService::notifyConsumerOfStatus($order->fresh(), $toStatus);

        return response()->json([
            'success' => true,
            'data' => $order->fresh(),
            'next_statuses' => OrderStateMachine::nextStatuses($toStatus),
            'message' => 'Status diperbarui: ' . OrderStateMachine::getInternalLabel($toStatus),
        ]);
    }

    /**
     * Legacy endpoint — kept for backward compatibility, delegates to transition().
     */
    public function updateStatus($id, Request $request)
    {
        // Map legacy driver statuses to new order statuses
        $legacyMap = [
            'on_the_way' => OrderStatus::DELIVERING_EQUIPMENT->value,
            'arrived_pickup' => OrderStatus::PICKING_UP_BODY->value ?? 'picking_up_body',
            'arrived_destination' => OrderStatus::BODY_ARRIVED->value,
            'done' => OrderStatus::COMPLETED->value,
        ];

        $mapped = $legacyMap[$request->status] ?? $request->status;
        $request->merge(['to_status' => $mapped]);

        return $this->transition($id, $request);
    }
}
