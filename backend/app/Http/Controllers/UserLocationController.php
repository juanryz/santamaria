<?php

namespace App\Http\Controllers;

use App\Models\UserLocation;
use App\Models\UserLocationConsent;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

/**
 * v1.35 — User Location Tracking Controller
 *
 * POST /user/location          — Karyawan kirim koordinat GPS (setiap 30 detik)
 * POST /user/location/consent  — Simpan persetujuan karyawan
 * GET  /user/location/consent  — Cek status persetujuan user saat ini
 * GET  /owner/employee-locations — Owner lihat lokasi terbaru semua karyawan
 * GET  /owner/employee-locations/{userId}/history — Owner lihat riwayat lokasi
 */
class UserLocationController extends Controller
{
    // ── Karyawan: kirim lokasi ──────────────────────────────────────────────

    /**
     * POST /user/location
     * Dipanggil background service Flutter setiap 30 detik.
     */
    public function updateLocation(Request $request)
    {
        $request->validate([
            'latitude'      => 'required|numeric|between:-90,90',
            'longitude'     => 'required|numeric|between:-180,180',
            'accuracy'      => 'nullable|numeric|min:0',
            'speed'         => 'nullable|numeric|min:0',
            'heading'       => 'nullable|numeric|between:0,360',
            'altitude'      => 'nullable|numeric',
            'battery_level' => 'nullable|string|max:5',
            'is_moving'     => 'nullable|boolean',
        ]);

        $userId = $request->user()->id;

        // Cek apakah user sudah setuju
        $consent = UserLocationConsent::find($userId);
        if (!$consent || !$consent->agreed) {
            return response()->json([
                'success' => false,
                'message' => 'Persetujuan lokasi belum diberikan.',
            ], 403);
        }

        // Simpan ke database
        UserLocation::create([
            'user_id'       => $userId,
            'latitude'      => $request->latitude,
            'longitude'     => $request->longitude,
            'accuracy'      => $request->accuracy,
            'speed'         => $request->speed,
            'heading'       => $request->heading,
            'altitude'      => $request->altitude,
            'battery_level' => $request->battery_level,
            'is_moving'     => $request->boolean('is_moving', false),
            'recorded_at'   => now(),
        ]);

        // Cache lokasi terbaru untuk akses cepat owner
        Cache::put("user_location:{$userId}", [
            'latitude'      => $request->latitude,
            'longitude'     => $request->longitude,
            'accuracy'      => $request->accuracy,
            'speed'         => $request->speed,
            'heading'       => $request->heading,
            'battery_level' => $request->battery_level,
            'is_moving'     => $request->boolean('is_moving', false),
            'updated_at'    => now()->toIso8601String(),
        ], now()->addMinutes(5));

        return response()->json(['success' => true]);
    }

    // ── Persetujuan ─────────────────────────────────────────────────────────

    /**
     * POST /user/location/consent
     * Dipanggil saat karyawan menekan "Setuju" di consent dialog.
     */
    public function storeConsent(Request $request)
    {
        $request->validate([
            'agreed' => 'required|boolean',
        ]);

        $userId = $request->user()->id;

        UserLocationConsent::updateOrCreate(
            ['user_id' => $userId],
            [
                'agreed'     => $request->boolean('agreed'),
                'agreed_at'  => $request->boolean('agreed') ? now() : null,
                'ip_address' => $request->ip(),
            ]
        );

        return response()->json(['success' => true]);
    }

    /**
     * GET /user/location/consent
     * Cek apakah user saat ini sudah memberikan persetujuan.
     */
    public function checkConsent(Request $request)
    {
        $consent = UserLocationConsent::find($request->user()->id);

        return response()->json([
            'success' => true,
            'data'    => [
                'agreed'    => $consent?->agreed ?? false,
                'agreed_at' => $consent?->agreed_at?->toIso8601String(),
            ],
        ]);
    }

    // ── Owner: lihat lokasi semua karyawan ──────────────────────────────────

    /**
     * GET /owner/employee-locations
     * Mengembalikan lokasi terbaru semua karyawan aktif.
     */
    public function allEmployeeLocations(Request $request)
    {
        // Ambil semua user kecuali consumer & owner sendiri
        $employees = User::whereNotIn('role', ['consumer', 'owner', 'super_admin'])
            ->where('is_active', true)
            ->get(['id', 'name', 'role']);

        $result = [];

        foreach ($employees as $emp) {
            // Coba dari cache dulu
            $cached = Cache::get("user_location:{$emp->id}");

            if ($cached) {
                $result[] = [
                    'user_id'  => $emp->id,
                    'name'     => $emp->name,
                    'role'     => $emp->role,
                    'location' => $cached,
                    'source'   => 'live',
                ];
                continue;
            }

            // Fallback ke database — ambil yang terbaru
            $latest = UserLocation::where('user_id', $emp->id)
                ->orderBy('recorded_at', 'desc')
                ->first();

            if ($latest) {
                $result[] = [
                    'user_id' => $emp->id,
                    'name'    => $emp->name,
                    'role'    => $emp->role,
                    'location' => [
                        'latitude'      => $latest->latitude,
                        'longitude'     => $latest->longitude,
                        'accuracy'      => $latest->accuracy,
                        'speed'         => $latest->speed,
                        'heading'       => $latest->heading,
                        'battery_level' => $latest->battery_level,
                        'is_moving'     => $latest->is_moving,
                        'updated_at'    => $latest->recorded_at->toIso8601String(),
                    ],
                    'source' => 'database',
                ];
            }
            // Jika tidak ada data lokasi sama sekali, tidak dimasukkan
        }

        return response()->json(['success' => true, 'data' => $result]);
    }

    /**
     * GET /owner/employee-locations/{userId}/history?date=2026-04-16
     * Riwayat perjalanan seorang karyawan dalam satu hari.
     */
    public function employeeLocationHistory(Request $request, string $userId)
    {
        $date = $request->query('date', now()->toDateString());

        $history = UserLocation::where('user_id', $userId)
            ->whereDate('recorded_at', $date)
            ->orderBy('recorded_at')
            ->get(['latitude', 'longitude', 'speed', 'heading', 'battery_level', 'is_moving', 'recorded_at']);

        $user = User::select('id', 'name', 'role')->find($userId);

        return response()->json([
            'success' => true,
            'data'    => [
                'user'    => $user,
                'date'    => $date,
                'points'  => $history,
                'count'   => $history->count(),
            ],
        ]);
    }
}
