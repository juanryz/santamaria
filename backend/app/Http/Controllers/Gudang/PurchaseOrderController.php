<?php

namespace App\Http\Controllers\Gudang;

use App\Events\PurchaseOrderCreated;
use App\Http\Controllers\Controller;
use App\Enums\UserRole;
use App\Models\PurchaseOrder;
use App\Services\AI\PriceValidationService;
use App\Services\NotificationService;
use Illuminate\Http\Request;

class PurchaseOrderController extends Controller
{
    public function index(Request $request)
    {
        $pos = PurchaseOrder::where('gudang_user_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json(['success' => true, 'data' => $pos]);
    }

    public function store(Request $request, PriceValidationService $aiService)
    {
        $request->validate([
            'order_id' => 'nullable|uuid|exists:orders,id',
            'item_name' => 'required|string',
            'quantity' => 'required|integer',
            'unit' => 'required|string',
            'proposed_price' => 'required|numeric',
            'supplier_name' => 'nullable|string',
        ]);

        $po = PurchaseOrder::create([
            'order_id' => $request->order_id,
            'gudang_user_id' => $request->user()->id,
            'item_name' => $request->item_name,
            'quantity' => $request->quantity,
            'unit' => $request->unit,
            'proposed_price' => $request->proposed_price,
            'supplier_name' => $request->supplier_name,
            'status' => 'pending_ai'
        ]);

        NotificationService::sendToRole(
            UserRole::SUPPLIER->value,
            'ALARM',
            'Permintaan e-Katalog Baru',
            "Ada kebutuhan barang baru untuk {$po->item_name}. Cek sekarang!",
            ['purchase_order_id' => $po->id]
        );

        // Broadcast real-time event to all supplier clients via Pusher.
        broadcast(new PurchaseOrderCreated($po))->afterCommit();

        // Run AI validation (best-effort — PO already saved regardless of AI outcome)
        try {
            $aiService->validate($po);
        } catch (\Throwable $e) {
            // AI gagal: update status ke pending_finance agar Finance bisa review manual
            $po->update([
                'status'      => 'pending_finance',
                'ai_analysis' => 'Validasi AI gagal. Mohon review manual oleh Finance.',
            ]);
        }

        return response()->json([
            'success' => true,
            'data'    => $po->fresh(),
            'message' => 'PO berhasil dibuat dan sedang diproses.',
        ]);
    }

    public function show($id)
    {
        $po = PurchaseOrder::with(['supplierQuotes.supplier'])->findOrFail($id);
        return response()->json(['success' => true, 'data' => $po]);
    }

    /**
     * Tandai PO sebagai selesai (barang sudah diterima).
     */
    public function complete(Request $request, string $id)
    {
        $po = PurchaseOrder::where('gudang_user_id', $request->user()->id)->findOrFail($id);

        if (! in_array($po->status, ['approved_finance', 'approved_owner_override'])) {
            return response()->json([
                'success' => false,
                'message' => 'PO belum disetujui Finance atau Owner.',
            ], 422);
        }

        $po->update([
            'status'       => 'completed',
            'completed_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'data'    => $po->fresh(),
            'message' => 'PO berhasil ditandai selesai.',
        ]);
    }
}
