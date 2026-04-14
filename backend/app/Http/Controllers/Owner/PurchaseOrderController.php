<?php

namespace App\Http\Controllers\Owner;

use App\Http\Controllers\Controller;
use App\Models\PurchaseOrder;
use App\Services\NotificationService;
use Illuminate\Http\Request;

class PurchaseOrderController extends Controller
{
    public function anomalies()
    {
        $pos = PurchaseOrder::where('is_anomaly', true)
            ->whereNull('owner_decision')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json(['success' => true, 'data' => $pos]);
    }

    public function override(Request $request, $id)
    {
        $request->validate(['decision' => 'required|in:approved_override,rejected', 'notes' => 'required|string']);

        $po = PurchaseOrder::findOrFail($id);
        
        $po->update([
            'status' => $request->decision === 'approved_override' ? 'approved_owner_override' : 'rejected',
            'owner_decision' => $request->decision,
            'owner_notes' => $request->notes,
            'owner_decided_at' => now()
        ]);

        NotificationService::send($po->gudang_user_id, 'HIGH', 'Keputusan Owner PO', "Owner telah " . ($request->decision === 'approved_override' ? "menyetujui" : "menolak") . " PO {$po->item_name}.");

        return response()->json(['success' => true, 'message' => 'Owner decision recorded']);
    }
}
