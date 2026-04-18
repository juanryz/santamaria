<?php

namespace App\Http\Controllers\ServiceOfficer;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\SystemThreshold;
use Illuminate\Http\Request;

/**
 * v1.39 — Transport luar kota Rp 25.000/km fix.
 * SO set is_out_of_city + jarak → sistem auto-hitung fee dari threshold.
 */
class OutOfCityTransportController extends Controller
{
    /** Get current out-of-city config for order + rate snapshot. */
    public function show(string $orderId)
    {
        $order = Order::findOrFail($orderId);
        $ratePerKm = (float) SystemThreshold::getValue('out_of_city_rate_per_km', 25000);

        return $this->success([
            'is_out_of_city' => (bool) $order->is_out_of_city,
            'origin' => $order->out_of_city_origin,
            'distance_km' => $order->out_of_city_distance_km,
            'transport_fee' => $order->out_of_city_transport_fee,
            'rate_per_km' => $ratePerKm,
        ]);
    }

    /** Set / update out-of-city config with auto-calc fee. */
    public function update(Request $request, string $orderId)
    {
        $validated = $request->validate([
            'is_out_of_city' => 'required|boolean',
            'origin' => 'required_if:is_out_of_city,true|nullable|string|max:255',
            'distance_km' => 'required_if:is_out_of_city,true|nullable|numeric|min:0',
        ]);

        $order = Order::findOrFail($orderId);
        $ratePerKm = (float) SystemThreshold::getValue('out_of_city_rate_per_km', 25000);

        if (!$validated['is_out_of_city']) {
            // Unset
            $order->update([
                'is_out_of_city' => false,
                'out_of_city_origin' => null,
                'out_of_city_distance_km' => null,
                'out_of_city_transport_fee' => 0,
            ]);
        } else {
            $distance = (float) $validated['distance_km'];
            $fee = $distance * $ratePerKm;

            $order->update([
                'is_out_of_city' => true,
                'out_of_city_origin' => $validated['origin'],
                'out_of_city_distance_km' => $distance,
                'out_of_city_transport_fee' => $fee,
            ]);
        }

        return $this->success([
            'is_out_of_city' => (bool) $order->is_out_of_city,
            'origin' => $order->out_of_city_origin,
            'distance_km' => $order->out_of_city_distance_km,
            'transport_fee' => $order->out_of_city_transport_fee,
            'rate_per_km' => $ratePerKm,
        ], 'Konfigurasi transport luar kota tersimpan.');
    }
}
