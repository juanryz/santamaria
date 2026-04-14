<?php

namespace App\Http\Controllers\HRD;

use App\Http\Controllers\Controller;
use App\Models\SystemThreshold;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ThresholdController extends Controller
{
    // GET /hrd/thresholds
    public function index(): JsonResponse
    {
        return response()->json(SystemThreshold::orderBy('key')->get());
    }

    // PUT /hrd/thresholds/{key}
    public function update(Request $request, string $key): JsonResponse
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
