<?php

namespace App\Http\Controllers\AI;

use App\Http\Controllers\Controller;
use App\Services\AI\VendorRecommendationService;
use App\Services\AI\ScheduleOptimizationService;
use App\Models\Order;
use Illuminate\Http\Request;

class RecommendationController extends Controller
{
    /**
     * GET /ai/recommend-vendor — Recommend best vendor for a role + date.
     */
    public function recommendVendor(Request $request)
    {
        $request->validate([
            'role' => 'required|string',
            'date' => 'required|date',
            'order_id' => 'nullable|uuid',
        ]);

        $service = new VendorRecommendationService();
        $result = $service->recommend($request->role, $request->date, $request->order_id);

        return response()->json($result);
    }

    /**
     * GET /ai/optimize-schedule/{orderId} — Recommend optimal driver + vehicle for order.
     */
    public function optimizeSchedule(string $orderId)
    {
        $order = Order::findOrFail($orderId);
        $service = new ScheduleOptimizationService();
        $result = $service->optimizeSchedule($order);

        return response()->json($result);
    }
}
