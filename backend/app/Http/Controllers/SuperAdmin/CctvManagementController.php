<?php

namespace App\Http\Controllers\SuperAdmin;

use App\Http\Controllers\Controller;
use App\Models\CctvCamera;
use Illuminate\Http\Request;

/**
 * v1.39 — Super Admin CRUD CCTV cameras.
 */
class CctvManagementController extends Controller
{
    public function index(Request $request)
    {
        $cameras = CctvCamera::with('addedByUser:id,name')
            ->orderBy('location_type')
            ->orderBy('camera_label')
            ->paginate(50);

        return $this->success($cameras);
    }

    public function show(string $id)
    {
        $camera = CctvCamera::with('addedByUser:id,name')->findOrFail($id);
        // Include password in clear for admin edit (manual injection)
        $data = $camera->toArray();
        $data['password'] = $camera->password; // decrypted via accessor
        return $this->success($data);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'camera_label' => 'required|string|max:255',
            'location_type' => 'required|string|in:kantor,gudang,lafiore,parkiran,pos_security',
            'ip_address' => 'required|string|max:50',
            'stream_url' => 'required|string|max:1000',
            'username' => 'nullable|string|max:100',
            'password' => 'nullable|string|max:255',
            'stream_type' => 'nullable|string|in:rtsp,http,hls,m3u8',
            'area_detail' => 'nullable|string|max:255',
            'is_active' => 'boolean',
        ]);

        $camera = new CctvCamera(array_merge($validated, [
            'added_by' => $request->user()->id,
            'stream_type' => $validated['stream_type'] ?? 'rtsp',
            'is_active' => $validated['is_active'] ?? true,
        ]));

        if (!empty($validated['password'])) {
            $camera->password = $validated['password']; // auto-encrypt via setter
        }
        $camera->save();

        return $this->created($camera);
    }

    public function update(Request $request, string $id)
    {
        $camera = CctvCamera::findOrFail($id);

        $validated = $request->validate([
            'camera_label' => 'sometimes|string|max:255',
            'location_type' => 'sometimes|string|in:kantor,gudang,lafiore,parkiran,pos_security',
            'ip_address' => 'sometimes|string|max:50',
            'stream_url' => 'sometimes|string|max:1000',
            'username' => 'nullable|string|max:100',
            'password' => 'nullable|string|max:255',
            'stream_type' => 'sometimes|string|in:rtsp,http,hls,m3u8',
            'area_detail' => 'nullable|string|max:255',
            'is_active' => 'sometimes|boolean',
        ]);

        $camera->fill(collect($validated)->except('password')->toArray());
        if (array_key_exists('password', $validated)) {
            // Only update password if explicitly provided (empty string → clear)
            $camera->password = $validated['password'];
        }
        $camera->save();

        return $this->success($camera->fresh());
    }

    public function destroy(string $id)
    {
        $camera = CctvCamera::findOrFail($id);
        $camera->delete();
        return $this->success(null, 'Camera dihapus.');
    }

    public function toggleActive(Request $request, string $id)
    {
        $camera = CctvCamera::findOrFail($id);
        $camera->is_active = !$camera->is_active;
        $camera->save();
        return $this->success($camera);
    }
}
