<?php

namespace App\Http\Controllers\Gudang;

use App\Http\Controllers\Controller;
use App\Models\EquipmentMaster;
use App\Models\EquipmentLoan;
use App\Models\OrderEquipmentItem;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class EquipmentController extends Controller
{
    // === Equipment Master ===

    public function masterIndex()
    {
        $items = EquipmentMaster::where('is_active', true)->orderBy('category')->orderBy('item_name')->get();
        return response()->json(['success' => true, 'data' => $items]);
    }

    // === Order Equipment Items ===

    public function orderEquipmentIndex($orderId)
    {
        $items = OrderEquipmentItem::where('order_id', $orderId)
            ->with('equipmentMaster')
            ->orderBy('category')
            ->get();

        return response()->json(['success' => true, 'data' => $items]);
    }

    public function prepareOrderEquipment(Request $request, $orderId)
    {
        $request->validate([
            'items' => 'required|array',
            'items.*.equipment_item_id' => 'required|uuid|exists:equipment_master,id',
            'items.*.qty_sent' => 'required|integer|min:1',
        ]);

        $created = [];
        foreach ($request->items as $item) {
            $master = EquipmentMaster::find($item['equipment_item_id']);
            $created[] = OrderEquipmentItem::create([
                'order_id' => $orderId,
                'equipment_item_id' => $item['equipment_item_id'],
                'category' => $master->category,
                'item_code' => $master->item_code,
                'item_description' => $master->item_name,
                'qty_sent' => $item['qty_sent'],
                'status' => 'prepared',
            ]);
        }

        return response()->json(['success' => true, 'message' => 'Equipment prepared', 'data' => $created], 201);
    }

    public function sendItem(Request $request, $orderId, $itemId)
    {
        $item = OrderEquipmentItem::where('order_id', $orderId)->findOrFail($itemId);
        $item->update([
            'status' => 'sent',
            'sent_by' => $request->user()->id,
            'sent_at' => now(),
            'qty_sent' => $request->input('qty_sent', $item->qty_sent),
        ]);

        return response()->json(['success' => true, 'data' => $item]);
    }

    public function returnItem(Request $request, $orderId, $itemId)
    {
        $item = OrderEquipmentItem::where('order_id', $orderId)->findOrFail($itemId);

        $qtyReturned = $request->input('qty_returned', $item->qty_sent);
        $status = $qtyReturned >= $item->qty_sent ? 'returned' : 'partial_return';
        if ($qtyReturned == 0) $status = 'missing';

        $item->update([
            'qty_returned' => $qtyReturned,
            'status' => $status,
            'returned_by_family_name' => $request->input('returned_by_family_name'),
            'returned_at' => now(),
            'accepted_return_by' => $request->user()->id,
        ]);

        return response()->json(['success' => true, 'data' => $item]);
    }

    public function missingEquipment()
    {
        $items = OrderEquipmentItem::whereIn('status', ['sent', 'received', 'partial_return', 'missing'])
            ->where('qty_returned', '<', DB::raw('qty_sent'))
            ->with(['order', 'equipmentMaster'])
            ->get();

        return response()->json(['success' => true, 'data' => $items]);
    }

    // === Equipment Loans ===

    public function loanIndex()
    {
        $loans = EquipmentLoan::with('items.equipmentMaster')->orderBy('created_at', 'desc')->paginate(20);
        return response()->json(['success' => true, 'data' => $loans]);
    }

    public function loanStore(Request $request)
    {
        $request->validate([
            'nama_almarhum' => 'required|string|max:255',
            'tgl_peringatan' => 'required|date',
        ]);

        $number = 'LOAN-' . now()->format('Ymd') . '-' . str_pad(
            EquipmentLoan::whereDate('created_at', today())->count() + 1, 3, '0', STR_PAD_LEFT
        );

        $loan = EquipmentLoan::create(array_merge($request->all(), [
            'loan_number' => $number,
            'order_by_id' => $request->user()->id,
            'status' => 'draft',
        ]));

        return response()->json(['success' => true, 'data' => $loan], 201);
    }

    public function loanShow($id)
    {
        $loan = EquipmentLoan::with('items.equipmentMaster')->findOrFail($id);
        return response()->json(['success' => true, 'data' => $loan]);
    }

    public function loanUpdateStatus(Request $request, $id)
    {
        $request->validate(['status' => 'required|string']);
        $loan = EquipmentLoan::findOrFail($id);
        $loan->update(['status' => $request->status]);
        return response()->json(['success' => true, 'data' => $loan]);
    }
}
