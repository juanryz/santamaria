<?php

namespace App\Http\Controllers\Gudang;

use App\Http\Controllers\Controller;
use App\Models\StockItem;
use App\Models\StockTransaction;
use App\Models\OrderStockDeduction;
use Illuminate\Http\Request;

class StockFormController extends Controller
{
    /**
     * POST /gudang/stock/form — Formulir Pengambilan / Pengembalian Barang
     * form_type: 'pengambilan' (keluar) atau 'pengembalian' (masuk)
     */
    public function submitForm(Request $request)
    {
        $request->validate([
            'stock_item_id' => 'required|uuid|exists:stock_items,id',
            'form_type' => 'required|in:pengambilan,pengembalian',
            'quantity' => 'required|numeric|min:0.01',
            'order_id' => 'nullable|uuid|exists:orders,id',
            'notes' => 'nullable|string',
            'pic_name' => 'nullable|string|max:255',
        ]);

        $stockItem = StockItem::findOrFail($request->stock_item_id);
        $qty = $request->quantity;
        $type = $request->form_type === 'pengambilan' ? 'out' : 'in';

        if ($type === 'out' && $stockItem->current_quantity < $qty) {
            return response()->json([
                'success' => false,
                'message' => "Stok tidak cukup. Tersedia: {$stockItem->current_quantity} {$stockItem->unit}",
            ], 422);
        }

        $before = $stockItem->current_quantity;

        if ($type === 'out') {
            $stockItem->decrement('current_quantity', $qty);
        } else {
            $stockItem->increment('current_quantity', $qty);
        }

        $transaction = StockTransaction::create([
            'stock_item_id' => $stockItem->id,
            'type' => $type,
            'quantity' => $qty,
            'notes' => trim(implode(' | ', array_filter([
                $request->form_type,
                $request->pic_name ? "PIC: {$request->pic_name}" : null,
                $request->notes,
            ]))),
            'created_by' => $request->user()->id,
        ]);

        return response()->json([
            'success' => true,
            'message' => $request->form_type === 'pengambilan'
                ? "Berhasil mengambil {$qty} {$stockItem->unit} {$stockItem->item_name}"
                : "Berhasil mengembalikan {$qty} {$stockItem->unit} {$stockItem->item_name}",
            'data' => [
                'transaction' => $transaction,
                'stock_before' => $before,
                'stock_after' => $stockItem->fresh()->current_quantity,
            ],
        ]);
    }

    /**
     * GET /gudang/stock/deductions — History deduction per order
     */
    public function deductions(Request $request)
    {
        $query = OrderStockDeduction::with(['stockItem', 'order', 'deductedByUser'])
            ->orderBy('created_at', 'desc');

        if ($request->has('order_id')) {
            $query->where('order_id', $request->order_id);
        }

        return response()->json(['success' => true, 'data' => $query->paginate(20)]);
    }
}
