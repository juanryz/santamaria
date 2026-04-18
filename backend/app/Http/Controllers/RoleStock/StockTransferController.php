<?php

namespace App\Http\Controllers\RoleStock;

use App\Http\Controllers\Controller;
use App\Models\StockInterLocationTransfer;
use App\Models\StockItem;
use App\Models\StockTransaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * v1.40 — Inter-location stock transfer (termasuk barang titipan kacang).
 * Flow typical: Gudang request → Super Admin (kantor) approve → transfer fisik →
 *                Gudang terima → stok kantor -qty, stok gudang +qty.
 */
class StockTransferController extends Controller
{
    /**
     * List transfers yang melibatkan role user (sebagai from atau to).
     */
    public function index(Request $request)
    {
        $user = $request->user();
        $role = $this->resolveOwnerRole($user->role);

        $transfers = StockInterLocationTransfer::with([
            'stockItem:id,item_name,item_code,unit',
            'requestedByUser:id,name',
            'approvedByUser:id,name',
            'sourceSupplier:id,name',
        ])
            ->where(function ($q) use ($role) {
                $q->where('from_owner_role', $role)->orWhere('to_owner_role', $role);
            })
            ->orderByDesc('requested_at')
            ->paginate(30);

        return $this->success($transfers);
    }

    /**
     * Request transfer — biasanya dipanggil Gudang minta stok dari Kantor.
     */
    public function request(Request $request)
    {
        $validated = $request->validate([
            'from_owner_role' => 'required|string|in:gudang,super_admin,dekor',
            'to_owner_role' => 'required|string|in:gudang,super_admin,dekor',
            'stock_item_id' => 'required|uuid',
            'quantity' => 'required|numeric|min:0.01',
            'source_supplier_id' => 'nullable|uuid',
            'source_consignment_batch' => 'nullable|string|max:100',
            'notes' => 'nullable|string|max:500',
        ]);

        if ($validated['from_owner_role'] === $validated['to_owner_role']) {
            return $this->error('from_owner_role dan to_owner_role tidak boleh sama.', 422);
        }

        $transfer = StockInterLocationTransfer::create(array_merge($validated, [
            'requested_by' => $request->user()->id,
            'requested_at' => now(),
            'status' => 'requested',
        ]));

        return $this->created($transfer, 'Request transfer stok tercatat.');
    }

    /**
     * Approve — oleh role pemilik stok asal (from_owner_role).
     */
    public function approve(Request $request, string $id)
    {
        $transfer = StockInterLocationTransfer::findOrFail($id);
        if ($transfer->status !== 'requested') {
            return $this->error('Status bukan requested — tidak dapat di-approve.', 422);
        }

        $userRole = $this->resolveOwnerRole($request->user()->role);
        if ($userRole !== $transfer->from_owner_role && $request->user()->role !== 'super_admin') {
            return $this->error('Hanya role asal yang dapat approve.', 403);
        }

        $transfer->update([
            'status' => 'approved',
            'approved_by' => $request->user()->id,
        ]);

        return $this->success($transfer);
    }

    /**
     * Mark transferred — transporter/driver menandai fisik sudah dibawa.
     */
    public function markTransferred(Request $request, string $id)
    {
        $request->validate([
            'photo_evidence_id' => 'nullable|uuid',
            'notes' => 'nullable|string|max:500',
        ]);

        $transfer = StockInterLocationTransfer::findOrFail($id);
        if ($transfer->status !== 'approved') {
            return $this->error('Transfer harus di-approve dulu.', 422);
        }

        $transfer->update([
            'status' => 'in_transit',
            'transferred_by' => $request->user()->id,
            'transferred_at' => now(),
            'photo_evidence_id' => $request->photo_evidence_id ?? $transfer->photo_evidence_id,
            'notes' => $request->notes ?? $transfer->notes,
        ]);

        return $this->success($transfer);
    }

    /**
     * Confirm receive — role tujuan konfirmasi terima + stok di-update.
     */
    public function confirmReceive(Request $request, string $id)
    {
        $transfer = StockInterLocationTransfer::findOrFail($id);
        if ($transfer->status !== 'in_transit') {
            return $this->error('Transfer belum dalam perjalanan.', 422);
        }

        $userRole = $this->resolveOwnerRole($request->user()->role);
        if ($userRole !== $transfer->to_owner_role && $request->user()->role !== 'super_admin') {
            return $this->error('Hanya role tujuan yang dapat konfirmasi terima.', 403);
        }

        DB::transaction(function () use ($transfer, $request) {
            // Stok asal: out
            StockTransaction::create([
                'stock_item_id' => $transfer->stock_item_id,
                'type' => 'out',
                'quantity' => $transfer->quantity,
                'notes' => "Transfer ke {$transfer->to_owner_role} (ID: {$transfer->id})",
                'user_id' => $request->user()->id,
            ]);

            // Stok tujuan: in (same stock_item_id — asumsi shared master)
            // Catatan: dalam model yang lebih kompleks, stok dipisah per owner_role.
            // Untuk sederhananya, kita hanya catat transaksi — quantity tetap di stock_item.
            StockTransaction::create([
                'stock_item_id' => $transfer->stock_item_id,
                'type' => 'in',
                'quantity' => $transfer->quantity,
                'notes' => "Terima dari {$transfer->from_owner_role} (ID: {$transfer->id})",
                'user_id' => $request->user()->id,
            ]);

            $transfer->update([
                'status' => 'completed',
                'received_by' => $request->user()->id,
                'received_at' => now(),
            ]);
        });

        return $this->success($transfer->fresh());
    }

    /**
     * Cancel — salah satu pihak batalkan sebelum fisik dipindah.
     */
    public function cancel(Request $request, string $id)
    {
        $request->validate(['reason' => 'nullable|string|max:500']);
        $transfer = StockInterLocationTransfer::findOrFail($id);
        if (!in_array($transfer->status, ['requested', 'approved'])) {
            return $this->error('Transfer sudah in transit/completed — tidak dapat dibatalkan.', 422);
        }

        $transfer->update([
            'status' => 'cancelled',
            'notes' => trim(($transfer->notes ?? '') . "\nCancelled: " . ($request->reason ?? '-')),
        ]);

        return $this->success($transfer);
    }

    private function resolveOwnerRole(string $userRole): string
    {
        return match ($userRole) {
            'super_admin' => 'super_admin',
            'dekor' => 'dekor',
            default => 'gudang',
        };
    }
}
