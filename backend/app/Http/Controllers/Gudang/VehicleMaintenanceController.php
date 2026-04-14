<?php

namespace App\Http\Controllers\Gudang;

use App\Http\Controllers\Controller;
use App\Models\VehicleFuelLog;
use App\Models\VehicleMaintenanceRequest;
use App\Services\NotificationService;
use Illuminate\Http\Request;

class VehicleMaintenanceController extends Controller
{
    // === Maintenance Requests ===

    public function index(Request $request)
    {
        $query = VehicleMaintenanceRequest::with(['vehicle', 'reporter'])
            ->orderByRaw("CASE status WHEN 'reported' THEN 1 WHEN 'acknowledged' THEN 2 WHEN 'in_progress' THEN 3 ELSE 4 END")
            ->orderBy('created_at', 'desc');

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        return $this->paginated($query);
    }

    public function show(string $id)
    {
        $request = VehicleMaintenanceRequest::with(['vehicle', 'reporter'])->findOrFail($id);
        return $this->success($request);
    }

    public function acknowledge(Request $request, string $id)
    {
        $mr = VehicleMaintenanceRequest::findOrFail($id);
        $mr->update([
            'status' => 'acknowledged',
            'acknowledged_at' => now(),
            'assigned_to' => $request->user()->id,
        ]);

        NotificationService::send($mr->reported_by, 'NORMAL', 'Maintenance Diterima',
            "Laporan kerusakan kendaraan Anda telah diterima oleh Gudang");

        return $this->success($mr, 'Maintenance request acknowledged');
    }

    public function start(string $id)
    {
        $mr = VehicleMaintenanceRequest::findOrFail($id);
        $mr->update(['status' => 'in_progress', 'started_at' => now()]);
        return $this->success($mr, 'Perbaikan dimulai');
    }

    public function complete(Request $request, string $id)
    {
        $request->validate([
            'resolution_notes' => 'required|string',
            'cost' => 'nullable|numeric|min:0',
        ]);

        $mr = VehicleMaintenanceRequest::findOrFail($id);
        $mr->update([
            'status' => 'completed',
            'completed_at' => now(),
            'resolution_notes' => $request->resolution_notes,
            'cost' => $request->cost,
        ]);

        NotificationService::send($mr->reported_by, 'NORMAL', 'Perbaikan Selesai',
            "Kendaraan Anda telah selesai diperbaiki: {$mr->resolution_notes}");

        return $this->success($mr, 'Maintenance completed');
    }

    public function defer(Request $request, string $id)
    {
        $mr = VehicleMaintenanceRequest::findOrFail($id);
        $mr->update(['status' => 'deferred', 'resolution_notes' => $request->input('reason')]);
        return $this->success($mr, 'Maintenance deferred');
    }

    // === Fuel Log Validation ===

    public function fuelLogs(Request $request)
    {
        $query = VehicleFuelLog::with(['vehicle', 'driver'])
            ->orderByRaw("CASE validation_status WHEN 'pending' THEN 1 ELSE 2 END")
            ->orderBy('created_at', 'desc');

        if ($request->has('status')) {
            $query->where('validation_status', $request->status);
        }

        return $this->paginated($query);
    }

    public function validateFuel(Request $request, string $id)
    {
        $fuel = VehicleFuelLog::findOrFail($id);
        $fuel->update([
            'validation_status' => 'validated',
            'validated_by' => $request->user()->id,
        ]);
        return $this->success($fuel, 'Fuel log validated');
    }

    public function rejectFuel(Request $request, string $id)
    {
        $request->validate(['reason' => 'required|string']);

        $fuel = VehicleFuelLog::findOrFail($id);
        $fuel->update([
            'validation_status' => 'rejected',
            'validated_by' => $request->user()->id,
            'notes' => $request->reason,
        ]);

        NotificationService::send($fuel->driver_id, 'HIGH', 'Fuel Log Ditolak',
            "Log BBM Anda ditolak: {$request->reason}. Silakan perbaiki.");

        return $this->success($fuel, 'Fuel log rejected');
    }
}
