<?php

namespace App\Http\Controllers\AI;

use App\Http\Controllers\Controller;
use App\Services\AI\KpiAnalysisService;
use App\Services\AI\OrderSummaryService;
use App\Models\Order;
use Illuminate\Http\Request;

class KpiAnalysisController extends Controller
{
    public function analyzeUserKpi(Request $request, string $userId)
    {
        $request->validate(['period_id' => 'required|uuid|exists:kpi_periods,id']);

        $service = new KpiAnalysisService();
        $result = $service->analyzeUserKpi($userId, $request->period_id);

        return response()->json($result);
    }

    public function orderSummary(string $orderId)
    {
        $order = Order::findOrFail($orderId);
        $service = new OrderSummaryService();
        $result = $service->generateDailySummary($order);

        return response()->json($result);
    }
}
