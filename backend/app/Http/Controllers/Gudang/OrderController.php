<?php

namespace App\Http\Controllers\Gudang;

use App\Http\Controllers\Controller;
use App\Models\Order;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class OrderController extends Controller
{
    /**
     * GET /gudang/orders
     * Returns orders that Gudang need to act on:
     *  - 'confirmed' : SO has confirmed → Gudang must check stock & fill checklist
     *  - 'in_progress': order is running
     */
    public function index(Request $request): JsonResponse
    {
        $orders = Order::with(['package:id,name,base_price', 'pic:id,name,phone'])
            ->whereIn('status', ['pending', 'confirmed', 'approved', 'in_progress'])
            ->orderByRaw("CASE status WHEN 'pending' THEN 0 WHEN 'confirmed' THEN 1 WHEN 'approved' THEN 2 WHEN 'in_progress' THEN 3 ELSE 4 END")
            ->orderBy('scheduled_at')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $orders,
        ]);
    }
}
