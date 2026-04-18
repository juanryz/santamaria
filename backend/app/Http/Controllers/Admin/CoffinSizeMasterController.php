<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\CoffinSizeMaster;
use Illuminate\Http\Request;

/**
 * v1.40 — CRUD master ukuran peti.
 *
 * Super Admin kelola label ukuran + rekomendasi jumlah tukang angkat peti.
 * Dipakai saat SO konfirmasi order untuk suggest jumlah pekerja lepas.
 */
class CoffinSizeMasterController extends Controller
{
    public function index()
    {
        $sizes = CoffinSizeMaster::ordered()->get();
        return response()->json(['success' => true, 'data' => $sizes]);
    }

    public function store(Request $request)
    {
        $validated = $this->validatePayload($request);

        // Ensure size_label unique
        if (CoffinSizeMaster::where('size_label', $validated['size_label'])->exists()) {
            return response()->json([
                'success' => false,
                'message' => "Label '{$validated['size_label']}' sudah ada.",
                'error_code' => 'DUPLICATE_LABEL',
            ], 422);
        }

        $size = CoffinSizeMaster::create($validated);

        return response()->json([
            'success' => true,
            'data' => $size,
            'message' => 'Ukuran peti ditambahkan.',
        ], 201);
    }

    public function show(string $id)
    {
        $size = CoffinSizeMaster::findOrFail($id);
        return response()->json(['success' => true, 'data' => $size]);
    }

    public function update(Request $request, string $id)
    {
        $size = CoffinSizeMaster::findOrFail($id);
        $validated = $this->validatePayload($request, $id);

        $size->update($validated);

        return response()->json(['success' => true, 'data' => $size->fresh()]);
    }

    public function destroy(string $id)
    {
        $size = CoffinSizeMaster::findOrFail($id);

        // Soft deactivate kalau sudah dipakai order
        if ($size->orders()->exists()) {
            $size->update(['is_active' => false]);
            return response()->json([
                'success' => true,
                'message' => 'Ukuran dinon-aktifkan (sudah dipakai di order).',
            ]);
        }

        $size->delete();
        return response()->json(['success' => true, 'message' => 'Ukuran dihapus.']);
    }

    private function validatePayload(Request $request, ?string $exceptId = null): array
    {
        return $request->validate([
            'size_label'              => 'required|string|max:50',
            'min_length_cm'           => 'nullable|integer|min:50|max:500',
            'max_length_cm'           => 'nullable|integer|min:50|max:500|gte:min_length_cm',
            'recommended_lifters_min' => 'required|integer|min:2|max:20',
            'recommended_lifters_max' => 'required|integer|min:2|max:20|gte:recommended_lifters_min',
            'sort_order'              => 'nullable|integer|min:0',
            'is_active'               => 'nullable|boolean',
        ]);
    }
}
