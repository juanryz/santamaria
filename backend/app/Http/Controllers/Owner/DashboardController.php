<?php

namespace App\Http\Controllers\Owner;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\PurchaseOrder;
use App\Models\User;
use App\Models\DailyReport;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function index()
    {
        $today = now()->startOfDay();
        
        $stats = [
            'total_revenue' => (float) Order::where('payment_status', 'paid')->sum('payment_amount'),
            'orders_today' => Order::whereDate('created_at', $today)->count(),
            'total_orders' => Order::count(),
            'active_orders' => Order::whereIn('status', ['pending', 'admin_review', 'approved', 'in_progress'])->count(),
            'drivers_on_duty' => User::where('role', UserRole::DRIVER->value)->where('is_active', true)->count(),
            'pending_po' => PurchaseOrder::where('status', 'pending_finance')->count(),
            'po_anomalies' => PurchaseOrder::where('is_anomaly', true)->whereNull('owner_decision')->count(),
            'active_drivers' => User::where('role', UserRole::DRIVER->value)
                ->where('is_active', true)
                ->whereNotNull('location_lat')
                ->get(['id', 'name', 'location_lat', 'location_lng']),
        ];

        return response()->json([
            'success' => true,
            'data' => $stats
        ]);
    }

    public function orders(Request $request)
    {
        $orders = Order::with(['pic', 'driver', 'package'])
            ->orderBy('created_at', 'desc')
            ->get(); // Change to get() or fix frontend to handle pagination

        return response()->json([
            'success' => true,
            'data' => $orders
        ]);
    }

    public function reports()
    {
        $reports = DailyReport::orderBy('report_date', 'desc')->limit(30)->get();
        return response()->json(['success' => true, 'data' => $reports]);
    }
}
