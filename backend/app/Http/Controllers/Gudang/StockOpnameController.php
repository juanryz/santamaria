<?php

namespace App\Http\Controllers\Gudang;

use App\Http\Controllers\Controller;
use App\Models\StockItem;
use App\Models\StockOpnameItem;
use App\Models\StockOpnameSession;
use App\Models\StockTransaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * v1.40 — Stock Opname Semester (6 bulan sekali).
 * Setiap role pemilik stok (gudang, super_admin, dekor) opname sendiri.
 */
class StockOpnameController extends Controller
{
    /**
     * List sesi opname untuk role pemanggil (filter owner_role = user.role).
     */
    public function index(Request $request)
    {
        $user = $request->user();
        $ownerRole = $this->resolveOwnerRole($user->role);

        $sessions = StockOpnameSession::where('owner_role', $ownerRole)
            ->orderByDesc('period_year')
            ->orderByDesc('period_semester')
            ->paginate(12);

        return $this->success($sessions);
    }

    /**
     * Start / resume current semester opname.
     */
    public function start(Request $request)
    {
        $user = $request->user();
        $ownerRole = $this->resolveOwnerRole($user->role);
        $now = now();
        $semester = $now->month <= 6 ? 'H1' : 'H2';

        $session = StockOpnameSession::firstOrCreate(
            [
                'period_year' => $now->year,
                'period_semester' => $semester,
                'owner_role' => $ownerRole,
            ],
            [
                'status' => 'in_progress',
                'started_at' => $now,
                'performed_by' => $user->id,
            ]
        );

        if ($session->status === 'open') {
            $session->update([
                'status' => 'in_progress',
                'started_at' => $session->started_at ?? $now,
                'performed_by' => $session->performed_by ?? $user->id,
            ]);
        }

        // Auto-populate items dari stock_items yang owner_role-nya cocok
        $existingItemIds = $session->items()->pluck('stock_item_id')->toArray();
        $stockItems = StockItem::where('owner_role', $ownerRole)
            ->whereNotIn('id', $existingItemIds)
            ->get();

        foreach ($stockItems as $item) {
            StockOpnameItem::create([
                'session_id' => $session->id,
                'stock_item_id' => $item->id,
                'system_quantity' => $item->current_quantity,
                'actual_quantity' => $item->current_quantity,
                'variance' => 0,
                'variance_value' => 0,
            ]);
        }

        return $this->success($session->fresh('items.stockItem'), 'Sesi opname dimulai.');
    }

    /**
     * Record actual count untuk 1 item.
     */
    public function countItem(Request $request, string $sessionId, string $itemId)
    {
        $request->validate([
            'actual_quantity' => 'required|numeric|min:0',
            'photo_evidence_id' => 'nullable|uuid',
            'notes' => 'nullable|string|max:500',
        ]);

        $item = StockOpnameItem::where('session_id', $sessionId)
            ->where('id', $itemId)
            ->firstOrFail();

        $stockItem = $item->stockItem;
        $actual = (float) $request->actual_quantity;
        $system = (float) $item->system_quantity;
        $variance = $actual - $system;
        $varianceValue = $stockItem && $stockItem->unit_cost
            ? $variance * (float) $stockItem->unit_cost
            : 0;

        $item->update([
            'actual_quantity' => $actual,
            'variance' => $variance,
            'variance_value' => $varianceValue,
            'photo_evidence_id' => $request->photo_evidence_id,
            'notes' => $request->notes,
        ]);

        return $this->success($item->fresh());
    }

    /**
     * Reconcile: generate stock_transactions untuk items yang ada variance.
     */
    public function reconcile(Request $request, string $sessionId)
    {
        $session = StockOpnameSession::with('items')->findOrFail($sessionId);
        if (in_array($session->status, ['completed', 'reviewed'])) {
            return $this->error('Sesi sudah selesai, tidak bisa reconcile ulang.', 422);
        }

        DB::transaction(function () use ($session, $request) {
            $totalVarianceCount = 0;
            $totalVarianceAmount = 0;

            foreach ($session->items as $item) {
                if ((float) $item->variance == 0 || $item->reconciled_at) {
                    continue;
                }

                // Buat stock_transaction adjustment (in atau out)
                $txn = StockTransaction::create([
                    'stock_item_id' => $item->stock_item_id,
                    'type' => (float) $item->variance > 0 ? 'in' : 'out',
                    'quantity' => abs((float) $item->variance),
                    'notes' => "Stock opname adjustment — session {$session->id}",
                    'user_id' => $request->user()->id,
                ]);

                // Sync stock_items.current_quantity ke actual_quantity
                StockItem::where('id', $item->stock_item_id)
                    ->update(['current_quantity' => $item->actual_quantity]);

                $item->update([
                    'reconciled_at' => now(),
                    'adjustment_transaction_id' => $txn->id,
                ]);

                $totalVarianceCount++;
                $totalVarianceAmount += (float) $item->variance_value;
            }

            $session->update([
                'status' => 'completed',
                'completed_at' => now(),
                'total_items_counted' => $session->items()->count(),
                'total_variance_count' => $totalVarianceCount,
                'total_variance_amount' => $totalVarianceAmount,
            ]);
        });

        return $this->success($session->fresh('items'), 'Opname selesai & stok direkonsiliasi.');
    }

    /**
     * Map user role → stock owner_role.
     */
    private function resolveOwnerRole(string $userRole): string
    {
        return match ($userRole) {
            'super_admin' => 'super_admin',
            'dekor' => 'dekor',
            default => 'gudang',
        };
    }
}
