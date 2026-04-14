<?php

namespace App\Http\Controllers;

use App\Models\OrderBillingItem;
use App\Models\BillingItemMaster;
use Illuminate\Http\Request;

class BillingController extends Controller
{
    public function index($orderId)
    {
        $items = OrderBillingItem::where('order_id', $orderId)
            ->with('billingMaster')
            ->orderBy('created_at')
            ->get();

        $total = $items->sum('total_price');
        $totalTambahan = $items->sum('tambahan');
        $totalKembali = $items->sum('kembali');
        $grandTotal = $total + $totalTambahan - $totalKembali;

        return response()->json([
            'success' => true,
            'data' => $items,
            'summary' => compact('total', 'totalTambahan', 'totalKembali', 'grandTotal'),
        ]);
    }

    public function storeManual(Request $request, $orderId)
    {
        $request->validate([
            'billing_master_id' => 'required|uuid|exists:billing_item_master,id',
            'qty' => 'required|numeric|min:0',
            'unit_price' => 'required|numeric|min:0',
        ]);

        $totalPrice = $request->qty * $request->unit_price;

        $item = OrderBillingItem::create([
            'order_id' => $orderId,
            'billing_master_id' => $request->billing_master_id,
            'qty' => $request->qty,
            'unit' => $request->input('unit', 'unit'),
            'unit_price' => $request->unit_price,
            'total_price' => $totalPrice,
            'source' => 'manual',
            'notes' => $request->input('notes'),
        ]);

        return response()->json(['success' => true, 'data' => $item], 201);
    }

    public function update(Request $request, $orderId, $itemId)
    {
        $item = OrderBillingItem::where('order_id', $orderId)->findOrFail($itemId);

        $item->update($request->only(['qty', 'unit_price', 'tambahan', 'kembali', 'notes']));

        if ($request->has('qty') || $request->has('unit_price')) {
            $item->update(['total_price' => $item->qty * $item->unit_price]);
        }

        return response()->json(['success' => true, 'data' => $item]);
    }

    public function total($orderId)
    {
        $items = OrderBillingItem::where('order_id', $orderId)->get();

        $total = $items->sum('total_price');
        $totalTambahan = $items->sum('tambahan');
        $totalKembali = $items->sum('kembali');
        $grandTotal = $total + $totalTambahan - $totalKembali;

        return response()->json([
            'success' => true,
            'data' => compact('total', 'totalTambahan', 'totalKembali', 'grandTotal'),
        ]);
    }
}
