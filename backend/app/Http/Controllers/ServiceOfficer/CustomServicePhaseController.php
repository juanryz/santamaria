<?php

namespace App\Http\Controllers\ServiceOfficer;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderLocationPhase;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * v1.40 — SO kelola multi rumah duka untuk layanan custom.
 * Consumer request pindah rumah duka di tengah prosesi → SO input phase baru.
 */
class CustomServicePhaseController extends Controller
{
    /** List phases per order. */
    public function index(string $orderId)
    {
        $phases = OrderLocationPhase::where('order_id', $orderId)
            ->with('funeralHome:id,name,city,address')
            ->orderBy('phase_sequence')
            ->get();

        return $this->success($phases);
    }

    /** Buat phase baru + auto-flag order sebagai custom service. */
    public function store(Request $request, string $orderId)
    {
        $validated = $request->validate([
            'funeral_home_id' => 'nullable|uuid',
            'start_date' => 'required|date',
            'end_date' => 'required|date|after_or_equal:start_date',
            'activities' => 'nullable|string|max:1000',
            'notes' => 'nullable|string|max:500',
            'extra_fee' => 'nullable|numeric|min:0',
        ]);

        $order = Order::findOrFail($orderId);

        $phase = DB::transaction(function () use ($order, $validated) {
            $nextSeq = OrderLocationPhase::where('order_id', $order->id)
                    ->max('phase_sequence') ?? 0;
            $nextSeq++;

            $phase = OrderLocationPhase::create([
                'order_id' => $order->id,
                'phase_sequence' => $nextSeq,
                'funeral_home_id' => $validated['funeral_home_id'] ?? null,
                'start_date' => $validated['start_date'],
                'end_date' => $validated['end_date'],
                'activities' => $validated['activities'] ?? null,
                'notes' => $validated['notes'] ?? null,
            ]);

            // Auto-flag order sebagai custom service
            $updates = ['is_custom_service' => true];

            if (!empty($validated['extra_fee'])) {
                $updates['custom_service_extra_fee'] =
                    (float) ($order->custom_service_extra_fee ?? 0)
                    + (float) $validated['extra_fee'];
            }

            $order->update($updates);

            return $phase;
        });

        return $this->created($phase->load('funeralHome:id,name,city'));
    }

    /** Update phase. */
    public function update(Request $request, string $orderId, string $phaseId)
    {
        $phase = OrderLocationPhase::where('order_id', $orderId)
            ->where('id', $phaseId)
            ->firstOrFail();

        $validated = $request->validate([
            'funeral_home_id' => 'nullable|uuid',
            'start_date' => 'sometimes|date',
            'end_date' => 'sometimes|date',
            'activities' => 'nullable|string|max:1000',
            'notes' => 'nullable|string|max:500',
        ]);

        $phase->update($validated);

        return $this->success($phase->fresh('funeralHome:id,name,city'));
    }

    /** Hapus phase — hanya jika bukan phase terakhir. */
    public function destroy(string $orderId, string $phaseId)
    {
        $phase = OrderLocationPhase::where('order_id', $orderId)
            ->where('id', $phaseId)
            ->firstOrFail();

        DB::transaction(function () use ($orderId, $phase) {
            $phase->delete();

            // Jika tidak ada phase tersisa, un-flag custom service
            $count = OrderLocationPhase::where('order_id', $orderId)->count();
            if ($count === 0) {
                Order::where('id', $orderId)->update([
                    'is_custom_service' => false,
                ]);
            } else {
                // Re-sequence
                $remaining = OrderLocationPhase::where('order_id', $orderId)
                    ->orderBy('phase_sequence')
                    ->get();
                foreach ($remaining as $i => $p) {
                    $p->update(['phase_sequence' => $i + 1]);
                }
            }
        });

        return $this->success(null, 'Phase dihapus.');
    }
}
