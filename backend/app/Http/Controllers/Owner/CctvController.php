<?php

namespace App\Http\Controllers\Owner;

use App\Http\Controllers\Controller;
use App\Models\CctvCamera;
use Illuminate\Http\Request;

/**
 * v1.39 — Owner CCTV live feed viewer.
 */
class CctvController extends Controller
{
    /** List all active cameras, grouped by location_type for grid display. */
    public function index(Request $request)
    {
        $q = CctvCamera::query();
        if (!$request->boolean('include_inactive')) {
            $q->where('is_active', true);
        }
        if ($request->filled('location')) {
            $q->where('location_type', $request->location);
        }
        $cameras = $q->orderBy('location_type')
            ->orderBy('camera_label')
            ->get(['id', 'camera_label', 'location_type', 'ip_address',
                'stream_type', 'area_detail', 'is_active']);

        // Group by location for UI
        $grouped = $cameras->groupBy('location_type')->map(fn($g) => $g->values());

        return $this->success([
            'total' => $cameras->count(),
            'by_location' => $grouped,
            'cameras' => $cameras,
        ]);
    }

    /** Get live stream URL with embedded auth (not exposed in list endpoint). */
    public function live(Request $request, string $id)
    {
        $camera = CctvCamera::findOrFail($id);
        if (!$camera->is_active) {
            return $this->error('Kamera tidak aktif.', 422);
        }

        return $this->success([
            'camera_id' => $camera->id,
            'label' => $camera->camera_label,
            'stream_url' => $camera->buildAuthenticatedStreamUrl(),
            'stream_type' => $camera->stream_type,
            'location_type' => $camera->location_type,
            'area_detail' => $camera->area_detail,
        ]);
    }
}
