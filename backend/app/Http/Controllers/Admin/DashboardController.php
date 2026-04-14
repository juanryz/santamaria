<?php

namespace App\Http\Controllers\Admin;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\User;
use App\Models\Vehicle;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function index()
    {
        $today = now()->startOfDay();
        
        $stats = [
            'total_orders' => Order::count(),
            'pending_orders' => Order::whereIn('status', ['admin_review', 'pending'])->count(),
            'active_orders' => Order::whereIn('status', ['approved', 'in_progress'])->count(),
            'completed_today' => Order::whereDate('completed_at', $today)->count(),
            'total_revenue' => (float) Order::where('payment_status', 'paid')->sum('payment_amount'),
        ];

        $recentOrders = Order::with('pic')
            ->orderBy('created_at', 'desc')
            ->limit(5)
            ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'stats' => $stats,
                'recent_orders' => $recentOrders
            ]
        ]);
    }

    public function getAvailableDrivers(Request $request)
    {
        $scheduledAt = $request->query('scheduled_at');
        if (!$scheduledAt) return response()->json(['success' => false, 'message' => 'scheduled_at is required'], 400);

        // Basic implementation: Find drivers who are not assigned to an active order within 3 hours
        $scheduledTime = new \DateTime($scheduledAt);
        $startTime = (clone $scheduledTime)->modify('-3 hours')->format('Y-m-d H:i:s');
        $endTime = (clone $scheduledTime)->modify('+3 hours')->format('Y-m-d H:i:s');

        $assignedDriverIds = Order::whereBetween('scheduled_at', [$startTime, $endTime])
            ->whereIn('status', ['approved', 'in_progress'])
            ->pluck('driver_id')
            ->filter();

        $availableDrivers = User::where('role', UserRole::DRIVER->value)
            ->where('is_active', true)
            ->whereNotIn('id', $assignedDriverIds)
            ->get();

        return response()->json(['success' => true, 'data' => $availableDrivers]);
    }

    public function getAvailableVehicles(Request $request)
    {
        $scheduledAt = $request->query('scheduled_at');
        if (!$scheduledAt) return response()->json(['success' => false, 'message' => 'scheduled_at is required'], 400);

        $scheduledTime = new \DateTime($scheduledAt);
        $startTime = (clone $scheduledTime)->modify('-3 hours')->format('Y-m-d H:i:s');
        $endTime = (clone $scheduledTime)->modify('+3 hours')->format('Y-m-d H:i:s');

        $assignedVehicleIds = Order::whereBetween('scheduled_at', [$startTime, $endTime])
            ->whereIn('status', ['approved', 'in_progress'])
            ->pluck('vehicle_id')
            ->filter();

        $availableVehicles = Vehicle::where('is_active', true)
            ->whereNotIn('id', $assignedVehicleIds)
            ->get();

        return response()->json(['success' => true, 'data' => $availableVehicles]);
    }
}
