<?php

namespace App\Http\Controllers\Admin;

use App\Enums\NotificationPriority;
use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderStatusLog;
use App\Models\User;
use App\Models\Vehicle;
use App\Services\NotificationService;
use App\Services\OrderStateMachine;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OrderController extends Controller
{
    public function index()
    {
        $orders = Order::with(['pic', 'soUser'])
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $orders
        ]);
    }

    public function show($id)
    {
        $order = Order::with(['driver', 'vehicle', 'package', 'photos', 'pic', 'soUser', 'statusLogs', 'orderAddOns'])
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $order
        ]);
    }

    public function approve($id, Request $request)
    {
        $request->validate([
            'scheduled_at' => 'required|date',
            'driver_id' => 'required|uuid|exists:users,id',
            'vehicle_id' => 'required|uuid|exists:vehicles,id',
            'admin_notes' => 'nullable|string',
        ]);

        $order = Order::findOrFail($id);

        if (!OrderStateMachine::canTransition($order->status, OrderStatus::APPROVED->value)) {
            $next = OrderStateMachine::nextStatuses($order->status);
            return response()->json([
                'success' => false,
                'message' => 'Transisi tidak valid dari status: ' . $order->status,
                'valid_transitions' => $next,
            ], 400);
        }

        // Conflict check (± 3 hours)
        $scheduledTime = new \DateTime($request->scheduled_at);
        $startTime = (clone $scheduledTime)->modify('-3 hours')->format('Y-m-d H:i:s');
        $endTime = (clone $scheduledTime)->modify('+3 hours')->format('Y-m-d H:i:s');

        $driverConflict = Order::where('driver_id', $request->driver_id)
            ->whereBetween('scheduled_at', [$startTime, $endTime])
            ->where('id', '!=', $id)
            ->whereIn('status', collect(OrderStatus::activeStatuses())->map->value->toArray())
            ->exists();

        if ($driverConflict) {
            return response()->json([
                'success' => false,
                'message' => 'Driver has another schedule within 3 hours'
            ], 400);
        }

        $vehicleConflict = Order::where('vehicle_id', $request->vehicle_id)
            ->whereBetween('scheduled_at', [$startTime, $endTime])
            ->where('id', '!=', $id)
            ->whereIn('status', collect(OrderStatus::activeStatuses())->map->value->toArray())
            ->exists();

        if ($vehicleConflict) {
            return response()->json([
                'success' => false,
                'message' => 'Vehicle has another schedule within 3 hours'
            ], 400);
        }

        return DB::transaction(function () use ($order, $request) {
            $order->update([
                'scheduled_at' => $request->scheduled_at,
                'driver_id' => $request->driver_id,
                'vehicle_id' => $request->vehicle_id,
                'admin_notes' => $request->admin_notes,
                'admin_user_id' => $request->user()->id,
                'approved_at' => now(),
            ]);

            OrderStateMachine::transition(
                $order,
                OrderStatus::APPROVED->value,
                $request->user()->id,
                'Armada telah diatur. Order disetujui untuk dijalankan.'
            );

            // Notification ALARMS
            NotificationService::sendToRole(UserRole::GUDANG->value, 'ALARM', 'Persiapan Stok Diperlukan', "Order {$order->order_number} telah disetujui.");
            NotificationService::send($request->driver_id, 'ALARM', 'Tugas Baru', "Anda telah ditugaskan untuk order {$order->order_number}.");
            NotificationService::sendToRole(UserRole::DEKOR->value, 'ALARM', 'Tugas Dekorasi Baru', "Order {$order->order_number} memerlukan dekorasi.");
            NotificationService::sendToRole(UserRole::KONSUMSI->value, 'ALARM', 'Tugas Konsumsi Baru', "Order {$order->order_number} memerlukan konsumsi.");

            // Dispatch Jobs (Skeleton calls)
            // GenerateOrderChecklist::dispatch($order);
            // ProcessPemukaAgamaAssignment::dispatch($order);
            // GenerateOrderInvoice::dispatch($order);

            return response()->json([
                'success' => true,
                'data' => $order,
                'message' => 'Order approved and tasks distributed'
            ]);
        });
    }

    public function close($id, Request $request)
    {
        $order = Order::findOrFail($id);

        if (!OrderStateMachine::canTransition($order->status, OrderStatus::COMPLETED->value)) {
            return response()->json([
                'success' => false,
                'message' => 'Order tidak dapat ditutup dari status: ' . $order->status,
                'valid_transitions' => OrderStateMachine::nextStatuses($order->status),
            ], 400);
        }

        $order->update(['completed_at' => now()]);

        OrderStateMachine::transition(
            $order,
            OrderStatus::COMPLETED->value,
            $request->user()->id,
            'Order ditutup oleh Admin.'
        );

        // Generate condolence text via AI (queued in production)
        NotificationService::send($order->pic_user_id, 'NORMAL', 'Layanan Selesai', "Order {$order->order_number} telah selesai. Ucapan duka tersedia di aplikasi.");

        return response()->json([
            'success' => true,
            'data' => $order->fresh(),
            'message' => 'Order berhasil ditutup.',
        ]);
    }

    public function updatePayment($id, Request $request)
    {
        $request->validate([
            'payment_status' => 'required|in:' . implode(',', PaymentStatus::values()),
            'payment_amount' => 'required|numeric',
            'payment_notes' => 'nullable|string',
        ]);

        $order = Order::findOrFail($id);

        $order->update([
            'payment_status' => $request->payment_status,
            'payment_amount' => $request->payment_amount,
            'payment_notes' => $request->payment_notes,
            'payment_updated_at' => now(),
            'payment_updated_by' => $request->user()->id
        ]);

        return response()->json([
            'success' => true,
            'data' => $order,
            'message' => 'Payment status updated'
        ]);
    }
}
