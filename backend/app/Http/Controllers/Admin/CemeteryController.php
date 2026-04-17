<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Cemetery;
use Illuminate\Http\Request;

class CemeteryController extends Controller
{
    public function index(Request $request)
    {
        $query = Cemetery::query();

        if ($request->filled('city')) {
            $query->where('city', 'ILIKE', '%' . $request->city . '%');
        }
        if ($request->filled('search')) {
            $query->where('name', 'ILIKE', '%' . $request->search . '%');
        }
        if ($request->filled('cemetery_type')) {
            $query->where('cemetery_type', $request->cemetery_type);
        }
        if ($request->has('is_active')) {
            $query->where('is_active', filter_var($request->is_active, FILTER_VALIDATE_BOOLEAN));
        }

        $data = $query->orderByDesc('usage_count')->paginate($request->input('per_page', 20));

        return response()->json(['success' => true, 'data' => $data]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name'          => 'required|string|max:255',
            'city'          => 'required|string|max:100',
            'cemetery_type' => 'nullable|string|max:50',
            'address'       => 'nullable|string|max:500',
            'phone'         => 'nullable|string|max:30',
            'latitude'      => 'nullable|numeric',
            'longitude'     => 'nullable|numeric',
            'notes'         => 'nullable|string|max:1000',
        ]);

        $validated['cemetery_type'] = $validated['cemetery_type'] ?? 'umum';

        $cemetery = Cemetery::create($validated);

        return response()->json(['success' => true, 'data' => $cemetery], 201);
    }

    public function show(string $id)
    {
        $cemetery = Cemetery::findOrFail($id);

        return response()->json(['success' => true, 'data' => $cemetery]);
    }

    public function update(Request $request, string $id)
    {
        $cemetery = Cemetery::findOrFail($id);

        $validated = $request->validate([
            'name'          => 'sometimes|required|string|max:255',
            'city'          => 'sometimes|required|string|max:100',
            'cemetery_type' => 'nullable|string|max:50',
            'address'       => 'nullable|string|max:500',
            'phone'         => 'nullable|string|max:30',
            'latitude'      => 'nullable|numeric',
            'longitude'     => 'nullable|numeric',
            'notes'         => 'nullable|string|max:1000',
            'is_active'     => 'nullable|boolean',
        ]);

        $cemetery->update($validated);

        return response()->json(['success' => true, 'data' => $cemetery]);
    }

    public function destroy(string $id)
    {
        $cemetery = Cemetery::findOrFail($id);
        $cemetery->update(['is_active' => false]);

        return response()->json(['success' => true, 'message' => 'Cemetery deactivated.']);
    }
}
