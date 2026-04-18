<?php

namespace App\Http\Controllers\Attendance;

use App\Http\Controllers\Controller;
use App\Models\LocationPresenceLog;
use App\Models\Order;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * v1.40 — Shared check-in/out karyawan di lokasi non-kantor.
 *
 * Contoh use case:
 * - SO tiba di rumah duka untuk koordinasi → check_in
 * - Dekor pasang dekorasi di rumah duka → check_in + check_out
 * - Driver tiba di TPU → check_in (via order_driver_assignments juga di-track)
 * - Petugas akta tiba di Dukcapil → check_in (via death_cert_stage_logs juga)
 *
 * Log ini sebagai data melengkapi presensi harian di kantor (daily_attendances).
 */
class LocationPresenceController extends Controller
{
    /**
     * List log presence saya (user login) hari ini atau per order.
     */
    public function index(Request $request)
    {
        $query = LocationPresenceLog::with([
            'order:id,order_number,deceased_name',
            'photoEvidence:id,file_path,taken_at,latitude,longitude',
        ])->where('user_id', $request->user()->id)
            ->orderByDesc('timestamp');

        if ($request->filled('order_id')) {
            $query->where('order_id', $request->order_id);
        }
        if ($request->filled('date')) {
            $query->whereDate('timestamp', $request->date);
        } else {
            // Default: today
            $query->whereDate('timestamp', today());
        }

        return response()->json([
            'success' => true,
            'data' => $query->get(),
        ]);
    }

    /**
     * Log per order — siapa saja yg pernah check-in di order ini.
     * Akses untuk SO (owner order), Owner, HRD.
     */
    public function byOrder(string $orderId)
    {
        $logs = LocationPresenceLog::with([
            'user:id,name,role',
            'photoEvidence:id,file_path,taken_at',
        ])->where('order_id', $orderId)
            ->orderByDesc('timestamp')
            ->get();

        return response()->json(['success' => true, 'data' => $logs]);
    }

    /**
     * Check-in ke lokasi.
     */
    public function checkIn(Request $request)
    {
        $request->validate([
            'order_id'          => 'nullable|uuid|exists:orders,id',
            'location_type'     => 'required|in:rumah_duka,tpu,gereja,rumah_keluarga,lainnya',
            'location_name'     => 'required|string|max:255',
            'location_ref_id'   => 'nullable|uuid',
            'latitude'          => 'nullable|numeric|between:-90,90',
            'longitude'         => 'nullable|numeric|between:-180,180',
            'photo_evidence_id' => 'nullable|uuid|exists:photo_evidences,id',
            'notes'             => 'nullable|string',
        ]);

        $user = $request->user();

        // Cek apakah sudah check-in di lokasi ini tapi belum check-out
        $openPresence = LocationPresenceLog::where('user_id', $user->id)
            ->where('action', 'check_in')
            ->where('location_type', $request->location_type)
            ->where('location_name', $request->location_name)
            ->whereNotExists(function ($q) {
                // Ada check-out setelahnya?
                $q->select(DB::raw(1))
                  ->from('location_presence_logs as co')
                  ->whereColumn('co.user_id', 'location_presence_logs.user_id')
                  ->whereColumn('co.location_type', 'location_presence_logs.location_type')
                  ->whereColumn('co.location_name', 'location_presence_logs.location_name')
                  ->where('co.action', 'check_out')
                  ->whereColumn('co.timestamp', '>', 'location_presence_logs.timestamp');
            })
            ->whereDate('timestamp', today())
            ->exists();

        if ($openPresence) {
            return response()->json([
                'success' => false,
                'message' => 'Anda sudah check-in di lokasi ini. Check-out dulu sebelum check-in lagi.',
                'error_code' => 'PRESENCE_ALREADY_OPEN',
            ], 422);
        }

        $log = LocationPresenceLog::create([
            'order_id'          => $request->order_id,
            'user_id'           => $user->id,
            'user_role'         => $user->role,
            'location_type'     => $request->location_type,
            'location_name'     => $request->location_name,
            'location_ref_id'   => $request->location_ref_id,
            'action'            => 'check_in',
            'timestamp'         => now(),
            'latitude'          => $request->latitude,
            'longitude'         => $request->longitude,
            'photo_evidence_id' => $request->photo_evidence_id,
            'notes'             => $request->notes,
        ]);

        return response()->json([
            'success' => true,
            'data' => $log,
            'message' => 'Check-in tercatat.',
        ], 201);
    }

    /**
     * Check-out dari lokasi.
     */
    public function checkOut(Request $request)
    {
        $request->validate([
            'order_id'          => 'nullable|uuid|exists:orders,id',
            'location_type'     => 'required|in:rumah_duka,tpu,gereja,rumah_keluarga,lainnya',
            'location_name'     => 'required|string|max:255',
            'latitude'          => 'nullable|numeric|between:-90,90',
            'longitude'         => 'nullable|numeric|between:-180,180',
            'photo_evidence_id' => 'nullable|uuid|exists:photo_evidences,id',
            'notes'             => 'nullable|string',
        ]);

        $user = $request->user();

        $log = LocationPresenceLog::create([
            'order_id'          => $request->order_id,
            'user_id'           => $user->id,
            'user_role'         => $user->role,
            'location_type'     => $request->location_type,
            'location_name'     => $request->location_name,
            'action'            => 'check_out',
            'timestamp'         => now(),
            'latitude'          => $request->latitude,
            'longitude'         => $request->longitude,
            'photo_evidence_id' => $request->photo_evidence_id,
            'notes'             => $request->notes,
        ]);

        return response()->json([
            'success' => true,
            'data' => $log,
            'message' => 'Check-out tercatat.',
        ], 201);
    }

    /**
     * Status presence saat ini — user sedang check-in di lokasi mana?
     */
    public function currentStatus(Request $request)
    {
        $user = $request->user();

        // Ambil log terbaru user hari ini
        $latest = LocationPresenceLog::where('user_id', $user->id)
            ->whereDate('timestamp', today())
            ->orderByDesc('timestamp')
            ->first();

        if (! $latest || $latest->action === 'check_out') {
            return response()->json([
                'success' => true,
                'data' => [
                    'is_checked_in' => false,
                    'current_location' => null,
                ],
            ]);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'is_checked_in' => true,
                'current_location' => [
                    'log_id'        => $latest->id,
                    'order_id'      => $latest->order_id,
                    'location_type' => $latest->location_type,
                    'location_name' => $latest->location_name,
                    'checked_in_at' => $latest->timestamp,
                ],
            ],
        ]);
    }
}
