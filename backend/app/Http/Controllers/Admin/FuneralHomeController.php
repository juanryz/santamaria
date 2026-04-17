<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\FuneralHome;
use Illuminate\Http\Request;

class FuneralHomeController extends Controller
{
    public function index(Request $request)
    {
        $query = FuneralHome::query();

        if ($request->filled('city')) {
            $query->where('city', 'ILIKE', '%' . $request->city . '%');
        }
        if ($request->filled('search')) {
            $query->where('name', 'ILIKE', '%' . $request->search . '%');
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
            'name'    => 'required|string|max:255',
            'city'    => 'required|string|max:100',
            'address' => 'nullable|string|max:500',
            'phone'   => 'nullable|string|max:30',
            'latitude'  => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'notes'   => 'nullable|string|max:1000',
        ]);

        $funeralHome = FuneralHome::create($validated);

        return response()->json(['success' => true, 'data' => $funeralHome], 201);
    }

    public function show(string $id)
    {
        $funeralHome = FuneralHome::findOrFail($id);

        return response()->json(['success' => true, 'data' => $funeralHome]);
    }

    public function update(Request $request, string $id)
    {
        $funeralHome = FuneralHome::findOrFail($id);

        $validated = $request->validate([
            'name'    => 'sometimes|required|string|max:255',
            'city'    => 'sometimes|required|string|max:100',
            'address' => 'nullable|string|max:500',
            'phone'   => 'nullable|string|max:30',
            'latitude'  => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'notes'   => 'nullable|string|max:1000',
            'is_active' => 'nullable|boolean',
        ]);

        $funeralHome->update($validated);

        return response()->json(['success' => true, 'data' => $funeralHome]);
    }

    public function destroy(string $id)
    {
        $funeralHome = FuneralHome::findOrFail($id);
        $funeralHome->update(['is_active' => false]);

        return response()->json(['success' => true, 'message' => 'Funeral home deactivated.']);
    }
}
