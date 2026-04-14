<?php

namespace App\Http\Controllers\Driver;

use App\Http\Controllers\Controller;
use App\Models\VehicleTripLog;
use Illuminate\Http\Request;

class VehicleTripLogController extends Controller
{
    public function index(Request $request)
    {
        $logs = VehicleTripLog::where('driver_id', $request->user()->id)
            ->with('vehicle')
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json(['success' => true, 'data' => $logs]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'vehicle_id' => 'required|uuid|exists:vehicles,id',
            'atas_nama' => 'required|string|max:255',
            'alamat_penjemputan' => 'required|string',
            'tujuan' => 'required|string',
            'waktu_pemakaian' => 'required|date',
        ]);

        $number = 'NMJ-' . now()->format('Ymd') . '-' . str_pad(
            VehicleTripLog::whereDate('created_at', today())->count() + 1, 3, '0', STR_PAD_LEFT
        );

        $log = VehicleTripLog::create(array_merge($request->all(), [
            'nota_number' => $number,
            'driver_id' => $request->user()->id,
            'order_id' => $request->input('order_id'),
        ]));

        return response()->json(['success' => true, 'data' => $log], 201);
    }

    public function update(Request $request, $id)
    {
        $log = VehicleTripLog::where('driver_id', $request->user()->id)->findOrFail($id);

        $log->update($request->only([
            'km_berangkat', 'km_tiba', 'km_total', 'biaya_per_km',
            'biaya_km', 'biaya_administrasi', 'total_biaya',
            'hari', 'jam', 'penyewa_name', 'penyewa_signed_at',
            'sm_officer_name', 'sm_officer_signed_at', 'notes',
        ]));

        if ($log->km_berangkat && $log->km_tiba) {
            $log->update([
                'km_total' => $log->km_tiba - $log->km_berangkat,
                'biaya_km' => ($log->km_tiba - $log->km_berangkat) * ($log->biaya_per_km ?? 0),
            ]);
        }

        return response()->json(['success' => true, 'data' => $log]);
    }
}
