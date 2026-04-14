<?php

namespace App\Services;

use App\Models\Order;
use App\Models\SystemSetting;
use App\Models\User;
use App\Models\OrderStatusLog;

class GeofenceService
{
    public function check(User $driver, Order $order, float $lat, float $lng): void
    {
        $radius = (int) SystemSetting::getValue('geofence_radius_meters', 100);

        // Calculate distance to pickup point
        $distanceToPickup = $this->haversine($lat, $lng, $order->pickup_lat, $order->pickup_lng);
        
        // Calculate distance to destination
        $distanceToDest = $this->haversine($lat, $lng, $order->destination_lat, $order->destination_lng);

        // Trigger geofence pickup
        if ($distanceToPickup <= $radius && $order->driver_status === 'on_the_way') {
            $order->update([
                'driver_status' => 'arrived_pickup',
                'driver_arrived_pickup_at' => now()
            ]);

            OrderStatusLog::create([
                'order_id' => $order->id,
                'user_id' => $driver->id,
                'from_status' => $order->status,
                'to_status' => $order->status,
                'notes' => 'Geofence: Driver tiba di lokasi penjemputan'
            ]);

            NotificationService::send($order->pic_user_id, 'HIGH', 'Driver Tiba', 'Driver telah tiba di lokasi penjemputan');
            NotificationService::sendToRole(UserRole::ADMIN->value, 'NORMAL', 'Driver Tiba', "{$driver->name} tiba di lokasi penjemputan {$order->order_number}");
        }

        // Trigger geofence destination
        if ($distanceToDest <= $radius && $order->driver_status === 'arrived_pickup') {
            $order->update([
                'driver_status' => 'arrived_destination',
                'driver_arrived_destination_at' => now()
            ]);

            OrderStatusLog::create([
                'order_id' => $order->id,
                'user_id' => $driver->id,
                'from_status' => $order->status,
                'to_status' => $order->status,
                'notes' => 'Geofence: Jenazah telah tiba di tujuan'
            ]);

            NotificationService::send($order->pic_user_id, 'HIGH', 'Sampai Tujuan', 'Jenazah telah tiba di tujuan');
        }
    }

    private function haversine(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $R = 6371000; // Earth radius in meters
        $phi1 = deg2rad($lat1);
        $phi2 = deg2rad($lat2);
        $dphi = deg2rad($lat2 - $lat1);
        $dlambda = deg2rad($lng2 - $lng1);
        
        $a = sin($dphi / 2) ** 2 + cos($phi1) * cos($phi2) * sin($dlambda / 2) ** 2;
        return $R * 2 * atan2(sqrt($a), sqrt(1 - $a));
    }
}
