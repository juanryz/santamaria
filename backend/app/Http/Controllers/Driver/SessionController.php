<?php

namespace App\Http\Controllers\Driver;

use App\Http\Controllers\Controller;
use App\Models\DriverSession;
use Illuminate\Http\Request;

class SessionController extends Controller
{
    public function start(Request $request)
    {
        $driver = $request->user();

        // End any existing active session first
        DriverSession::where('driver_id', $driver->id)
            ->whereNull('ended_at')
            ->update(['ended_at' => now()]);

        $session = DriverSession::create([
            'driver_id' => $driver->id,
            'started_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'data' => $session,
            'message' => 'Sesi On Duty dimulai.',
        ]);
    }

    public function end(Request $request)
    {
        $driver = $request->user();

        $session = DriverSession::where('driver_id', $driver->id)
            ->whereNull('ended_at')
            ->latest('started_at')
            ->first();

        if (! $session) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak ada sesi aktif.',
            ], 404);
        }

        $session->update(['ended_at' => now()]);

        return response()->json([
            'success' => true,
            'data' => $session,
            'message' => 'Sesi On Duty berakhir.',
        ]);
    }

    public function active(Request $request)
    {
        $session = DriverSession::where('driver_id', $request->user()->id)
            ->whereNull('ended_at')
            ->latest('started_at')
            ->first();

        return response()->json([
            'success' => true,
            'data' => [
                'is_on_duty' => $session !== null,
                'session' => $session,
            ],
        ]);
    }
}
