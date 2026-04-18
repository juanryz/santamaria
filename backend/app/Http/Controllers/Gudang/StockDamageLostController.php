<?php

namespace App\Http\Controllers\Gudang;

use App\Http\Controllers\Controller;
use App\Models\StockDamageLog;
use App\Models\StockItem;
use App\Models\StockLostLog;
use App\Models\StockTransaction;
use App\Services\NotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * v1.39 PART 10 — Stock damage & lost tracking.
 * Scan barcode → laporkan kerusakan / kehilangan → log + estimasi kerugian.
 */
class StockDamageLostController extends Controller
{
    // ══ Scan barcode ═════════════════════════════════════════════════════

    /** Resolve stock_item dari barcode scan. */
    public function scan(Request $request)
    {
        $validated = $request->validate([
            'barcode' => 'required|string|max:255',
        ]);

        $item = StockItem::where('barcode', $validated['barcode'])->first();
        if (!$item) {
            return $this->error('Barcode tidak ditemukan di master stok.', 404);
        }

        return $this->success([
            'stock_item' => $item,
            'current_quantity' => (float) $item->current_quantity,
            'minimum_quantity' => (float) $item->minimum_quantity,
            'owner_role' => $item->owner_role,
        ]);
    }

    // ══ Damage ═══════════════════════════════════════════════════════════

    public function damageIndex(Request $request)
    {
        $q = StockDamageLog::with([
            'stockItem:id,item_name,barcode,unit',
            'reporter:id,name,role',
            'responsibleUser:id,name,role',
            'order:id,order_number',
        ]);
        if ($request->filled('status')) $q->where('status', $request->status);
        if ($request->filled('damage_level')) $q->where('damage_level', $request->damage_level);
        if ($request->filled('stock_item_id')) $q->where('stock_item_id', $request->stock_item_id);

        return $this->success($q->orderByDesc('created_at')->paginate(30));
    }

    public function damageReport(Request $request)
    {
        $validated = $request->validate([
            'stock_item_id' => 'required|uuid|exists:stock_items,id',
            'order_id' => 'nullable|uuid|exists:orders,id',
            'barcode_scanned' => 'nullable|string|max:255',
            'quantity_damaged' => 'required|numeric|min:0.01',
            'damage_level' => 'required|in:minor,moderate,severe,total_loss',
            'estimated_loss_amount' => 'required|numeric|min:0',
            'damage_photo_evidence_id' => 'nullable|uuid',
            'damage_description' => 'required|string|max:1000',
            'responsible_party' => 'nullable|in:sm_gudang,sm_driver,sm_dekor,tukang_jaga,keluarga,unknown',
            'responsible_user_id' => 'nullable|uuid|exists:users,id',
        ]);

        $log = DB::transaction(function () use ($validated, $request) {
            $log = StockDamageLog::create(array_merge($validated, [
                'reported_by' => $request->user()->id,
                'reported_role' => $request->user()->role,
                'status' => 'reported',
            ]));

            // Deduct qty_damaged dari stock_items (severe atau total_loss)
            if (in_array($validated['damage_level'], ['severe', 'total_loss'])) {
                $item = StockItem::find($validated['stock_item_id']);
                if ($item) {
                    $item->decrement('current_quantity', $validated['quantity_damaged']);

                    StockTransaction::create([
                        'stock_item_id' => $item->id,
                        'order_id' => $validated['order_id'] ?? null,
                        'type' => 'out',
                        'quantity' => $validated['quantity_damaged'],
                        'notes' => "Damage {$validated['damage_level']} — {$validated['damage_description']}",
                        'user_id' => $request->user()->id,
                    ]);
                }
            }

            return $log;
        });

        NotificationService::sendToRole('gudang', 'HIGH',
            'Barang Rusak Dilaporkan',
            "Level: {$validated['damage_level']} · " .
            "Kerugian: Rp " . number_format($validated['estimated_loss_amount'], 0, ',', '.'));
        NotificationService::sendToRole('hrd', 'NORMAL',
            'Laporan Kerusakan Stok',
            "User {$request->user()->name} melaporkan kerusakan stok.");

        return $this->created($log->load('stockItem:id,item_name'));
    }

    public function damageResolve(Request $request, string $id)
    {
        $validated = $request->validate([
            'resolution_notes' => 'required|string|max:1000',
            'status' => 'required|in:investigated,resolved,written_off',
        ]);

        $log = StockDamageLog::findOrFail($id);
        $log->update(array_merge($validated, [
            'resolved_by' => $request->user()->id,
            'resolved_at' => now(),
        ]));

        return $this->success($log->fresh());
    }

    // ══ Lost ═════════════════════════════════════════════════════════════

    public function lostIndex(Request $request)
    {
        $q = StockLostLog::with([
            'stockItem:id,item_name,unit',
            'reporter:id,name,role',
            'lastTukangJaga:id,name',
            'order:id,order_number',
        ]);
        if ($request->filled('status')) $q->where('status', $request->status);
        if ($request->filled('order_id')) $q->where('order_id', $request->order_id);

        return $this->success($q->orderByDesc('reported_at')->paginate(30));
    }

    public function lostReport(Request $request)
    {
        $validated = $request->validate([
            'stock_item_id' => 'required|uuid|exists:stock_items,id',
            'order_id' => 'nullable|uuid|exists:orders,id',
            'quantity_lost' => 'required|numeric|min:0.01',
            'estimated_loss_amount' => 'required|numeric|min:0',
            'last_tukang_jaga_id' => 'nullable|uuid|exists:users,id',
            'last_delivery_id' => 'nullable|uuid',
            'notes' => 'nullable|string|max:1000',
        ]);

        $log = DB::transaction(function () use ($validated, $request) {
            $log = StockLostLog::create(array_merge($validated, [
                'reported_by' => $request->user()->id,
                'reported_at' => now(),
                'status' => 'reported',
                'penalty_amount' => $validated['estimated_loss_amount'],
            ]));

            // Deduct dari stok
            $item = StockItem::find($validated['stock_item_id']);
            if ($item) {
                $item->decrement('current_quantity', $validated['quantity_lost']);
                StockTransaction::create([
                    'stock_item_id' => $item->id,
                    'order_id' => $validated['order_id'] ?? null,
                    'type' => 'out',
                    'quantity' => $validated['quantity_lost'],
                    'notes' => "LOST — " . ($validated['notes'] ?? ''),
                    'user_id' => $request->user()->id,
                ]);
            }

            return $log;
        });

        // Alarm tukang jaga terakhir yang terima
        if (!empty($validated['last_tukang_jaga_id'])) {
            NotificationService::send(
                $validated['last_tukang_jaga_id'],
                'ALARM',
                'Barang Hilang di Shift Anda',
                "Barang di rumah duka hilang saat shift Anda. " .
                "Potongan upah: Rp " . number_format($validated['estimated_loss_amount'], 0, ',', '.')
            );
        }
        NotificationService::sendToRole('hrd', 'HIGH',
            'Laporan Kehilangan Barang',
            'Stok hilang dilaporkan — butuh investigasi.');

        return $this->created($log->load('stockItem:id,item_name', 'lastTukangJaga:id,name'));
    }

    public function lostDeductPenalty(Request $request, string $id)
    {
        $log = StockLostLog::findOrFail($id);
        if ($log->penalty_deducted) {
            return $this->error('Penalty sudah dipotong.', 422);
        }
        if (!$log->last_tukang_jaga_id) {
            return $this->error('Tukang jaga penanggung jawab belum dipilih.', 422);
        }

        $log->update([
            'penalty_deducted' => true,
            'penalty_deducted_at' => now(),
            'status' => 'charged',
        ]);

        return $this->success($log->fresh());
    }
}
