<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Vehicle;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Manajemen Armada (Mobil Jenazah) — hanya Admin yang bisa akses.
 * Driver di-assign otomatis oleh AI (AssignDriverToOrder job).
 */
class VehicleController extends Controller
{
    // GET /admin/vehicles
    public function index(): JsonResponse
    {
        $vehicles = Vehicle::with('package')->orderBy('plate_number')->get();
        return response()->json(['success' => true, 'data' => $vehicles]);
    }

    // GET /admin/vehicles/{id}
    public function show(string $id): JsonResponse
    {
        $vehicle = Vehicle::with('package')->findOrFail($id);
        return response()->json(['success' => true, 'data' => $vehicle]);
    }

    // POST /admin/vehicles
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'plate_number' => 'required|string|max:20|unique:vehicles,plate_number',
            'model'        => 'required|string|max:100',
            'capacity'     => 'required|integer|min:1',
            'package_id'   => 'nullable|uuid|exists:packages,id',
            'type'         => 'nullable|in:jenazah,ambulans,operasional',
            'is_active'    => 'boolean',
        ]);

        $vehicle = Vehicle::create($data);

        return response()->json([
            'success' => true,
            'data'    => $vehicle,
            'message' => 'Kendaraan berhasil ditambahkan.',
        ], 201);
    }

    // PUT /admin/vehicles/{id}
    public function update(Request $request, string $id): JsonResponse
    {
        $vehicle = Vehicle::findOrFail($id);

        $data = $request->validate([
            'plate_number' => "sometimes|string|max:20|unique:vehicles,plate_number,{$id}",
            'model'        => 'sometimes|string|max:100',
            'capacity'     => 'sometimes|integer|min:1',
            'package_id'   => 'nullable|uuid|exists:packages,id',
            'type'         => 'nullable|in:jenazah,ambulans,operasional',
            'is_active'    => 'sometimes|boolean',
        ]);

        $vehicle->update($data);

        return response()->json([
            'success' => true,
            'data'    => $vehicle,
            'message' => 'Kendaraan berhasil diperbarui.',
        ]);
    }

    // DELETE /admin/vehicles/{id} — soft disable
    public function destroy(string $id): JsonResponse
    {
        $vehicle = Vehicle::findOrFail($id);
        $vehicle->update(['is_active' => false]);

        return response()->json(['success' => true, 'message' => 'Kendaraan dinonaktifkan.']);
    }
}
