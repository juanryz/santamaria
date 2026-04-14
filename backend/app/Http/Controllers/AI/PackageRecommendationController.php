<?php

namespace App\Http\Controllers\AI;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Services\AI\PackageRecommendationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PackageRecommendationController extends Controller
{
    public function __construct(
        protected PackageRecommendationService $service,
    ) {}

    /**
     * GET /so/ai/package-recommendation?order_id=&package_ids[]=
     */
    public function recommend(Request $request): JsonResponse
    {
        $request->validate([
            'order_id' => 'required|uuid|exists:orders,id',
        ]);

        $order = Order::findOrFail($request->input('order_id'));

        // Load available packages
        $packages = \App\Models\Package::where('is_active', true)
            ->with('items')
            ->get()
            ->toArray();

        if (empty($packages)) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak ada paket yang tersedia.',
            ], 422);
        }

        $result = $this->service->recommend($order, $packages);

        if (!$result['success']) {
            return response()->json([
                'success' => false,
                'message' => $result['error'] ?? 'AI tidak dapat memberikan rekomendasi saat ini.',
            ], 500);
        }

        return response()->json([
            'success' => true,
            'data'    => $result['data'] ?? $result['content'] ?? null,
        ]);
    }
}
