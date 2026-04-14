<?php

namespace App\Http\Controllers\Finance;

use App\Http\Controllers\Controller;
use App\Models\PurchaseOrder;
use App\Services\NotificationService;
use Illuminate\Http\Request;

class PurchaseOrderController extends Controller
{
    public function index()
    {
        $pos = PurchaseOrder::with(['supplierQuotes.supplier'])
            ->whereIn('status', ['pending_finance', 'approved_finance', 'rejected'])
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json(['success' => true, 'data' => $pos]);
    }

    public function show($id)
    {
        $po = PurchaseOrder::with(['supplierQuotes.supplier', 'gudangUser'])
            ->whereIn('status', ['pending_finance', 'approved_finance', 'rejected'])
            ->findOrFail($id);

        return response()->json(['success' => true, 'data' => $po]);
    }

    public function approve($id, Request $request)
    {
        $request->validate(['notes' => 'nullable|string']);

        $po = PurchaseOrder::findOrFail($id);
        
        if ($po->status !== 'pending_finance') {
            return response()->json(['success' => false, 'message' => 'PO is not in pending_finance status'], 400);
        }

        $po->update([
            'status' => 'approved_finance',
            'finance_user_id' => $request->user()->id,
            'finance_notes' => $request->notes,
            'finance_reviewed_at' => now()
        ]);

        NotificationService::send($po->gudang_user_id, 'NORMAL', 'PO Disetujui', "PO {$po->item_name} telah disetujui oleh Finance.");

        return response()->json(['success' => true, 'data' => $po, 'message' => 'PO approved by Finance']);
    }

    public function reject($id, Request $request)
    {
        $request->validate(['notes' => 'required|string']);

        $po = PurchaseOrder::findOrFail($id);

        $po->update([
            'status' => 'rejected',
            'finance_user_id' => $request->user()->id,
            'finance_notes' => $request->notes,
            'finance_reviewed_at' => now()
        ]);

        NotificationService::send($po->gudang_user_id, 'HIGH', 'PO Ditolak', "PO {$po->item_name} telah ditolak oleh Finance.");

        return response()->json(['success' => true, 'data' => $po, 'message' => 'PO rejected by Finance']);
    }
}
