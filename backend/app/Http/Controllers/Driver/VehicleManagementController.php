<?php

namespace App\Http\Controllers\Driver;

use App\Http\Controllers\Controller;
use App\Models\VehicleKmLog;
use App\Models\VehicleFuelLog;
use App\Models\VehicleInspection;
use App\Models\VehicleInspectionItem;
use App\Models\VehicleInspectionMaster;
use App\Models\VehicleMaintenanceRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class VehicleManagementController extends Controller
{
    // === KM Logs ===

    public function storeKmLog(Request $request, string $vehicleId)
    {
        $request->validate([
            'log_type' => 'required|in:start,end,refuel',
            'km_reading' => 'required|numeric|min:0',
            'photo_path' => 'nullable|string',
            'order_id' => 'nullable|uuid',
        ]);

        $log = VehicleKmLog::create([
            'vehicle_id' => $vehicleId,
            'driver_id' => $request->user()->id,
            'log_type' => $request->log_type,
            'km_reading' => $request->km_reading,
            'photo_path' => $request->photo_path,
            'order_id' => $request->order_id,
            'notes' => $request->notes,
        ]);

        return $this->created($log, 'KM log recorded');
    }

    public function getKmLogs(Request $request, string $vehicleId)
    {
        $logs = VehicleKmLog::where('vehicle_id', $vehicleId)
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return $this->success($logs);
    }

    // === Fuel Logs ===

    public function storeFuelLog(Request $request, string $vehicleId)
    {
        $request->validate([
            'liters' => 'required|numeric|min:0.1',
            'price_per_liter' => 'required|numeric|min:0',
            'fuel_type' => 'nullable|string',
            'km_reading' => 'nullable|numeric',
            'receipt_photo_path' => 'nullable|string',
            'speedometer_photo_path' => 'nullable|string',
            'station_name' => 'nullable|string',
        ]);

        $totalCost = $request->liters * $request->price_per_liter;

        $log = VehicleFuelLog::create([
            'vehicle_id' => $vehicleId,
            'driver_id' => $request->user()->id,
            'liters' => $request->liters,
            'price_per_liter' => $request->price_per_liter,
            'total_cost' => $totalCost,
            'fuel_type' => $request->input('fuel_type', 'pertamax'),
            'km_reading' => $request->km_reading,
            'receipt_photo_path' => $request->receipt_photo_path,
            'speedometer_photo_path' => $request->speedometer_photo_path,
            'station_name' => $request->station_name,
            'notes' => $request->notes,
        ]);

        return $this->created($log, 'Fuel log recorded');
    }

    public function getFuelLogs(Request $request, string $vehicleId)
    {
        $logs = VehicleFuelLog::where('vehicle_id', $vehicleId)
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return $this->success($logs);
    }

    // === Inspections ===

    public function storeInspection(Request $request, string $vehicleId)
    {
        $request->validate([
            'inspection_type' => 'required|in:pre_trip,post_trip',
            'km_reading' => 'nullable|numeric',
            'items' => 'required|array',
            'items.*.master_item_id' => 'required|uuid',
            'items.*.is_passed' => 'required|boolean',
        ]);

        return DB::transaction(function () use ($request, $vehicleId) {
            $totalItems = count($request->items);
            $passedItems = collect($request->items)->where('is_passed', true)->count();
            $failedItems = $totalItems - $passedItems;

            $hasCriticalFail = false;
            $criticalIds = VehicleInspectionMaster::where('is_critical', true)->pluck('id')->toArray();
            foreach ($request->items as $item) {
                if (!$item['is_passed'] && in_array($item['master_item_id'], $criticalIds)) {
                    $hasCriticalFail = true;
                    break;
                }
            }

            $inspection = VehicleInspection::create([
                'vehicle_id' => $vehicleId,
                'driver_id' => $request->user()->id,
                'inspection_type' => $request->inspection_type,
                'km_reading' => $request->km_reading,
                'total_items' => $totalItems,
                'passed_items' => $passedItems,
                'failed_items' => $failedItems,
                'overall_passed' => !$hasCriticalFail,
                'notes' => $request->notes,
            ]);

            foreach ($request->items as $item) {
                VehicleInspectionItem::create([
                    'inspection_id' => $inspection->id,
                    'master_item_id' => $item['master_item_id'],
                    'is_passed' => $item['is_passed'],
                    'value' => $item['value'] ?? null,
                    'photo_path' => $item['photo_path'] ?? null,
                    'notes' => $item['notes'] ?? null,
                ]);
            }

            return $this->created($inspection->load('items'), 'Inspection recorded');
        });
    }

    // === Maintenance Requests ===

    public function storeMaintenanceRequest(Request $request, string $vehicleId)
    {
        $request->validate([
            'category' => 'required|string',
            'priority' => 'required|in:low,medium,high,critical',
            'description' => 'required|string',
            'photo_path' => 'nullable|string',
        ]);

        $mr = VehicleMaintenanceRequest::create([
            'vehicle_id' => $vehicleId,
            'reported_by' => $request->user()->id,
            'category' => $request->category,
            'priority' => $request->priority,
            'description' => $request->description,
            'photo_path' => $request->photo_path,
        ]);

        return $this->created($mr, 'Maintenance request submitted');
    }

    public function getMyMaintenanceRequests(Request $request)
    {
        $requests = VehicleMaintenanceRequest::where('reported_by', $request->user()->id)
            ->with('vehicle')
            ->orderBy('created_at', 'desc')
            ->get();

        return $this->success($requests);
    }
}
