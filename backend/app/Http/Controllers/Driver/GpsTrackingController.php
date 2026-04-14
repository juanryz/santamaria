<?php

namespace App\Http\Controllers\Driver;

use App\Http\Controllers\Controller;
use App\Models\DriverLocation;
use App\Models\Order;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class GpsTrackingController extends Controller
{
    /**
     * POST /driver/gps — Send real-time GPS location.
     * Called every 10 seconds by Flutter geolocator when on duty.
     * Broadcasts to Pusher for consumer/owner tracking.
     */
    public function updateLocation(Request $request)
    {
        $request->validate([
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'accuracy' => 'nullable|numeric',
            'speed' => 'nullable|numeric',
            'heading' => 'nullable|numeric',
            'order_id' => 'nullable|uuid',
        ]);

        $userId = $request->user()->id;

        // Store in DB
        $location = DriverLocation::create([
            'driver_id' => $userId,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'accuracy' => $request->accuracy,
            'speed' => $request->speed,
            'heading' => $request->heading,
        ]);

        // Cache latest location for quick reads
        Cache::put("driver_location:{$userId}", [
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'accuracy' => $request->accuracy,
            'speed' => $request->speed,
            'heading' => $request->heading,
            'updated_at' => now()->toIso8601String(),
        ], now()->addMinutes(5));

        // Broadcast to order channel if order_id provided
        if ($request->order_id) {
            broadcast(new \App\Events\DriverLocationBroadcast(
                $request->order_id,
                $userId,
                $request->latitude,
                $request->longitude,
                $request->speed,
                $request->heading,
            ))->toOthers();
        }

        return response()->json(['success' => true]);
    }

    /**
     * GET /driver/gps/latest/{driverId} — Get latest location of a driver.
     * Used by consumer/owner to check driver position.
     */
    public function latestLocation(string $driverId)
    {
        $cached = Cache::get("driver_location:{$driverId}");

        if ($cached) {
            return response()->json(['success' => true, 'data' => $cached, 'source' => 'cache']);
        }

        $latest = DriverLocation::where('driver_id', $driverId)
            ->orderBy('created_at', 'desc')
            ->first();

        if (!$latest) {
            return response()->json(['success' => true, 'data' => null, 'message' => 'No location data']);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'latitude' => $latest->latitude,
                'longitude' => $latest->longitude,
                'accuracy' => $latest->accuracy,
                'speed' => $latest->speed,
                'heading' => $latest->heading,
                'updated_at' => $latest->created_at->toIso8601String(),
            ],
            'source' => 'database',
        ]);
    }
}
