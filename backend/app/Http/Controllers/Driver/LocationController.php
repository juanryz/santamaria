<?php

namespace App\Http\Controllers\Driver;

use App\Events\DriverLocationUpdated;
use App\Http\Controllers\Controller;
use App\Models\DriverLocation;
use App\Models\Order;
use App\Services\GeofenceService;
use Illuminate\Http\Request;

class LocationController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'lat' => 'required|numeric',
            'lng' => 'required|numeric',
            'speed' => 'nullable|numeric',
            'heading' => 'nullable|numeric',
            'accuracy' => 'nullable|numeric',
            'recorded_at' => 'required|date',
            'order_id' => 'nullable|uuid|exists:orders,id',
        ]);

        $location = DriverLocation::create([
            'driver_id' => $request->user()->id,
            'order_id' => $request->order_id,
            'lat' => $request->lat,
            'lng' => $request->lng,
            'speed' => $request->speed,
            'heading' => $request->heading,
            'accuracy' => $request->accuracy,
            'recorded_at' => $request->recorded_at,
        ]);

        // Real-time broadcast
        broadcast(new DriverLocationUpdated($location));

        // Geofence check if there is an active order
        if ($request->order_id) {
            $order = Order::find($request->order_id);
            if ($order) {
                (new GeofenceService())->check($request->user(), $order, $request->lat, $request->lng);
            }
        }

        return response()->json([
            'success' => true,
            'message' => 'Location recorded'
        ]);
    }
}
