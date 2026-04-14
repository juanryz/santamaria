<?php

namespace App\Http\Controllers\Purchasing;

use App\Http\Controllers\Controller;
use App\Models\ServiceWageRate;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class WageRateController extends Controller
{
    /**
     * Daftar semua tarif upah (aktif).
     */
    public function index(Request $request)
    {
        $query = ServiceWageRate::with('setter:id,name')
            ->where('is_active', true)
            ->orderBy('role')
            ->orderBy('service_package');

        if ($request->filled('role')) {
            $query->where('role', $request->role);
        }

        return response()->json([
            'success' => true,
            'data'    => $query->get(),
        ]);
    }

    /**
     * Buat tarif baru.
     */
    public function store(Request $request)
    {
        $request->validate([
            'role'            => ['required', Rule::in(['tukang_foto', 'tukang_angkat_peti'])],
            'service_package' => 'nullable|string|max:100',
            'rate_amount'     => 'required|numeric|min:0',
            'notes'           => 'nullable|string|max:500',
        ]);

        $rate = ServiceWageRate::create([
            'role'            => $request->role,
            'service_package' => $request->service_package,
            'rate_amount'     => $request->rate_amount,
            'notes'           => $request->notes,
            'set_by'          => $request->user()->id,
        ]);

        return response()->json([
            'success' => true,
            'data'    => $rate->load('setter:id,name'),
            'message' => 'Tarif upah berhasil ditambahkan.',
        ], 201);
    }

    /**
     * Update tarif.
     */
    public function update(Request $request, string $id)
    {
        $rate = ServiceWageRate::findOrFail($id);

        $request->validate([
            'rate_amount'     => 'sometimes|numeric|min:0',
            'service_package' => 'nullable|string|max:100',
            'notes'           => 'nullable|string|max:500',
            'is_active'       => 'sometimes|boolean',
        ]);

        $rate->update($request->only(['rate_amount', 'service_package', 'notes', 'is_active']));

        return response()->json([
            'success' => true,
            'data'    => $rate->fresh()->load('setter:id,name'),
            'message' => 'Tarif upah berhasil diperbarui.',
        ]);
    }

    /**
     * Nonaktifkan tarif.
     */
    public function destroy(string $id)
    {
        $rate = ServiceWageRate::findOrFail($id);
        $rate->update(['is_active' => false]);

        return response()->json([
            'success' => true,
            'message' => 'Tarif upah dinonaktifkan.',
        ]);
    }
}
