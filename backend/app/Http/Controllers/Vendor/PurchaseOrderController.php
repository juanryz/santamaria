<?php

namespace App\Http\Controllers\Vendor;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\PurchaseOrder;
use Illuminate\Http\Request;

class PurchaseOrderController extends Controller
{
    public function index(Request $request)
    {
        // Only the supplier role may view purchase orders.
        if ($request->user()->role !== UserRole::SUPPLIER->value) {
            return response()->json(['success' => false, 'message' => 'Akses ditolak.'], 403);
        }

        $orders = PurchaseOrder::whereIn('status', ['pending_ai', 'pending_finance'])
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json(['success' => true, 'data' => $orders]);
    }

    public function show($id)
    {
        $order = PurchaseOrder::findOrFail($id);

        return response()->json(['success' => true, 'data' => $order]);
    }
}
