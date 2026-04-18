<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\MusicianWageConfig;
use App\Models\OrderMusicianSession;
use Illuminate\Http\Request;

/**
 * v1.40 — Musisi bayaran PER ORANG PER SESI.
 * MC merangkap musisi (bisa masuk sebagai role_label 'mc').
 */
class MusicianSessionController extends Controller
{
    // ── Wage Config (per role_label) ──

    public function wageConfigs(Request $request)
    {
        $configs = MusicianWageConfig::where('is_active', true)
            ->orderBy('role_label')
            ->get();

        return $this->success($configs);
    }

    public function storeWageConfig(Request $request)
    {
        $validated = $request->validate([
            'role_label' => 'required|string|max:100',
            'rate_per_session_per_person' => 'required|numeric|min:0',
            'effective_date' => 'required|date',
            'end_date' => 'nullable|date|after:effective_date',
            'notes' => 'nullable|string|max:500',
        ]);
        $validated['is_active'] = true;

        $config = MusicianWageConfig::create($validated);

        return $this->created($config);
    }

    public function updateWageConfig(Request $request, string $id)
    {
        $config = MusicianWageConfig::findOrFail($id);
        $validated = $request->validate([
            'role_label' => 'sometimes|string|max:100',
            'rate_per_session_per_person' => 'sometimes|numeric|min:0',
            'effective_date' => 'sometimes|date',
            'end_date' => 'nullable|date',
            'is_active' => 'sometimes|boolean',
            'notes' => 'nullable|string|max:500',
        ]);

        $config->update($validated);

        return $this->success($config);
    }

    // ── Order Musician Sessions ──

    public function sessions(Request $request, string $orderId)
    {
        $sessions = OrderMusicianSession::where('order_id', $orderId)
            ->orderBy('session_date')
            ->orderBy('session_start_time')
            ->get();

        return $this->success($sessions);
    }

    public function storeSession(Request $request, string $orderId)
    {
        $validated = $request->validate([
            'session_date' => 'required|date',
            'session_type' => 'required|string|in:misa,doa_malam,prosesi,pemberkatan,lainnya',
            'session_start_time' => 'nullable|date_format:H:i',
            'session_end_time' => 'nullable|date_format:H:i',
            'location' => 'nullable|string|max:255',
            'musician_count' => 'required|integer|min:1',
            'rate_per_person' => 'required|numeric|min:0',
            'musicians_user_ids' => 'nullable|array',
            'musicians_user_ids.*' => 'uuid',
            'notes' => 'nullable|string|max:500',
        ]);

        $validated['order_id'] = $orderId;
        $validated['total_wage'] = (int) $validated['musician_count'] * (float) $validated['rate_per_person'];

        $session = OrderMusicianSession::create($validated);

        return $this->created($session);
    }

    public function updateSession(Request $request, string $orderId, string $sessionId)
    {
        $session = OrderMusicianSession::where('order_id', $orderId)
            ->where('id', $sessionId)
            ->firstOrFail();

        $validated = $request->validate([
            'session_date' => 'sometimes|date',
            'session_type' => 'sometimes|string',
            'session_start_time' => 'nullable|date_format:H:i',
            'session_end_time' => 'nullable|date_format:H:i',
            'location' => 'nullable|string|max:255',
            'musician_count' => 'sometimes|integer|min:1',
            'rate_per_person' => 'sometimes|numeric|min:0',
            'musicians_user_ids' => 'nullable|array',
            'notes' => 'nullable|string|max:500',
        ]);

        $session->fill($validated);
        $session->total_wage = (int) $session->musician_count * (float) $session->rate_per_person;
        $session->save();

        return $this->success($session);
    }

    public function deleteSession(string $orderId, string $sessionId)
    {
        $session = OrderMusicianSession::where('order_id', $orderId)
            ->where('id', $sessionId)
            ->firstOrFail();
        $session->delete();

        return $this->success(null, 'Session dihapus.');
    }
}
