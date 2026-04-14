<?php

namespace App\Http\Controllers\Owner;

use App\Http\Controllers\Controller;
use App\Models\HrdViolation;
use App\Models\SystemThreshold;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ViolationController extends Controller
{
    // GET /owner/hrd/violations
    public function index(Request $request): JsonResponse
    {
        $query = HrdViolation::with([
            'violatedByUser:id,name,role',
            'order:id,order_number',
        ]);

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }
        if ($request->filled('severity')) {
            $query->where('severity', $request->severity);
        }

        return response()->json($query->orderByDesc('created_at')->paginate(30));
    }

    // PUT /owner/thresholds/{key}
    public function updateThreshold(Request $request, string $key): JsonResponse
    {
        $data = $request->validate([
            'value'       => 'required|numeric|min:0',
            'description' => 'nullable|string',
        ]);

        $threshold = SystemThreshold::where('key', $key)->firstOrFail();
        $threshold->update([
            'value'       => $data['value'],
            'description' => $data['description'] ?? $threshold->description,
            'updated_by'  => $request->user()->id,
            'updated_at'  => now(),
        ]);

        return response()->json(['message' => 'Threshold diperbarui.', 'data' => $threshold]);
    }
}
