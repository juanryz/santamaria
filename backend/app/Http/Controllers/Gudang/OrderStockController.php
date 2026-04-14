<?php

namespace App\Http\Controllers\Gudang;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderChecklist;
use App\Models\ProcurementRequest;
use App\Models\StockItem;
use App\Models\StockTransaction;
use App\Services\NotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OrderStockController extends Controller
{
    // GET /gudang/orders/{id}/checklist
    public function checklist(string $id): JsonResponse
    {
        $order = Order::with(['package', 'orderAddOns.addOnService'])->findOrFail($id);

        $items = OrderChecklist::where('order_id', $id)
            ->orderBy('is_checked')
            ->get();

        return response()->json([
            'order'       => $order->only(['id', 'order_number', 'status', 'gudang_status', 'needs_restock', 'scheduled_at']),
            'checklist'   => $items,
            'total'       => $items->count(),
            'checked'     => $items->where('is_checked', true)->count(),
        ]);
    }

    // PUT /gudang/orders/{id}/checklist/{itemId}
    public function checkItem(Request $request, string $id, string $itemId): JsonResponse
    {
        $data = $request->validate([
            'is_checked' => 'required|boolean',
            'notes'      => 'nullable|string',
        ]);

        $item = OrderChecklist::where('order_id', $id)->findOrFail($itemId);
        $item->update([
            'is_checked'  => $data['is_checked'],
            'notes'       => $data['notes'] ?? $item->notes,
            'checked_at'  => $data['is_checked'] ? now() : null,
            'checked_by'  => $data['is_checked'] ? $request->user()->id : null,
        ]);

        return response()->json(['message' => 'Item diperbarui.', 'data' => $item]);
    }

    // PUT /gudang/orders/{id}/stock-ready — GATE: konfirmasi stok siap → trigger alarm driver
    public function stockReady(Request $request, string $id): JsonResponse
    {
        $order = Order::whereIn('status', ['confirmed', 'approved', 'in_progress'])->findOrFail($id);

        // Semua checklist harus sudah dicek
        $unchecked = OrderChecklist::where('order_id', $id)->where('is_checked', false)->count();
        if ($unchecked > 0) {
            return response()->json([
                'message' => "Masih ada {$unchecked} item checklist belum dicek.",
            ], 422);
        }

        DB::transaction(function () use ($order, $request) {
            $order->update([
                'gudang_status'       => 'ready',
                'gudang_confirmed_at' => now(),
                'status'              => 'approved',
            ]);

            // Kurangi stok & cek apakah ada item yang perlu restok
            $checklist  = OrderChecklist::where('order_id', $order->id)->get();
            $lowStockItems = []; // kumpulkan untuk notif & auto-draft PR

            foreach ($checklist as $item) {
                // Prioritas: FK langsung → fallback fuzzy name match
                $stock = $item->stock_item_id
                    ? StockItem::find($item->stock_item_id)
                    : StockItem::where('item_name', 'ilike', "%{$item->item_name}%")->first();

                if (! $stock) {
                    continue;
                }

                $deductQty = (int) ($item->quantity ?? 1);
                $stock->decrement('current_quantity', $deductQty);
                $stock->update(['last_updated_by' => $request->user()->id]);

                StockTransaction::create([
                    'stock_item_id' => $stock->id,
                    'order_id'      => $order->id,
                    'type'          => 'out',
                    'quantity'      => $deductQty,
                    'notes'         => "Digunakan untuk order {$order->order_number}",
                    'user_id'       => $request->user()->id,
                    'created_at'    => now(),
                ]);

                // Cek apakah stok sekarang di bawah minimum
                $stock->refresh();
                if ($stock->current_quantity <= $stock->minimum_quantity) {
                    $lowStockItems[] = $stock;
                }
            }

            // ── Auto-trigger draft ProcurementRequest untuk setiap stok kritis ──
            foreach ($lowStockItems as $stock) {
                // Jangan buat duplikat jika sudah ada PR draft/open untuk item ini
                $existing = ProcurementRequest::where('item_name', $stock->item_name)
                    ->whereNotIn('status', ['completed', 'cancelled'])
                    ->exists();

                if (! $existing) {
                    $prNumber = 'PRQ-' . date('Ymd') . '-' . strtoupper(substr(md5($stock->id . now()), 0, 4));
                    ProcurementRequest::create([
                        'request_number'   => $prNumber,
                        'gudang_user_id'   => $request->user()->id,
                        'order_id'         => $order->id,
                        'item_name'        => $stock->item_name,
                        'category'         => $stock->category,
                        'quantity'         => max(1, $stock->minimum_quantity * 2 - $stock->current_quantity),
                        'unit'             => $stock->unit,
                        'delivery_address' => 'Gudang Santa Maria',
                        'status'           => 'draft',
                    ]);
                }
            }

            // ── Notifikasi jika ada stok kritis ──────────────────────────────
            if (count($lowStockItems) > 0) {
                $itemList = implode(', ', array_map(fn($s) => $s->item_name, $lowStockItems));

                NotificationService::sendToRole('gudang', 'ALARM',
                    'Stok Kritis! Buat Permintaan Pengadaan',
                    "Stok tipis setelah order {$order->order_number}: {$itemList}. Draft permintaan sudah dibuat — segera publikasikan.",
                    ['action' => 'view_procurement']
                );

                NotificationService::sendToRole('finance', 'HIGH',
                    'Perhatian: Stok Gudang Kritis',
                    "Stok {$itemList} di bawah minimum setelah order {$order->order_number}. Gudang sedang memproses permintaan pengadaan.",
                    ['action' => 'view_procurement']
                );
            }

            // Dispatch Driver Assignment Job automatically
            dispatch(new \App\Jobs\AssignDriverToOrder($order));

            // Log status
            \App\Models\OrderStatusLog::create([
                'order_id'    => $order->id,
                'user_id'     => $request->user()->id,
                'from_status' => 'confirmed',
                'to_status'   => 'approved',
                'notes'       => 'Gudang konfirmasi stok siap. Stok barang telah dikurangi dan Driver segera di-assign.',
            ]);
        });

        return response()->json(['message' => 'Stok siap! Driver akan segera mendapat notifikasi.']);
    }
}
