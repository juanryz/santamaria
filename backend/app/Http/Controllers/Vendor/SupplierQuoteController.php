<?php

namespace App\Http\Controllers\Vendor;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\PurchaseOrder;
use App\Models\PurchaseOrderSupplierQuote;
use App\Services\NotificationService;
use App\Services\StorageService;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;

class SupplierQuoteController extends Controller
{
    public function index(Request $request)
    {
        $quotes = PurchaseOrderSupplierQuote::with('purchaseOrder')
            ->where('supplier_user_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json(['success' => true, 'data' => $quotes]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'purchase_order_id' => 'required|uuid|exists:purchase_orders,id',
            'quote_price' => 'required|numeric',
            'quote_notes' => 'nullable|string',
        ]);

        $purchaseOrder = PurchaseOrder::findOrFail($request->purchase_order_id);

        // Guard: 1 supplier → 1 quote per purchase order (backed by DB UNIQUE constraint).
        $exists = PurchaseOrderSupplierQuote::where('purchase_order_id', $purchaseOrder->id)
            ->where('supplier_user_id', $request->user()->id)
            ->exists();

        if ($exists) {
            return response()->json([
                'success' => false,
                'message' => 'Anda sudah mengajukan penawaran untuk permintaan ini.',
            ], 422);
        }

        try {
            $quote = PurchaseOrderSupplierQuote::create([
                'purchase_order_id' => $purchaseOrder->id,
                'supplier_user_id' => $request->user()->id,
                'quote_price' => $request->quote_price,
                'quote_notes' => $request->quote_notes,
                'status' => 'pending',
            ]);
        } catch (QueryException $e) {
            // Catch any race-condition duplicate that slips past the guard above.
            if ($e->errorInfo[1] === 1062 || str_contains($e->getMessage(), 'unique_supplier_quote_per_po')) {
                return response()->json([
                    'success' => false,
                    'message' => 'Anda sudah mengajukan penawaran untuk permintaan ini.',
                ], 422);
            }
            throw $e;
        }

        NotificationService::sendToRole(
            UserRole::GUDANG->value,
            'HIGH',
            'Supplier Mengajukan Penawaran',
            "Supplier {$request->user()->name} mengajukan penawaran untuk {$purchaseOrder->item_name}.",
            ['quote_id' => $quote->id]
        );

        return response()->json(['success' => true, 'data' => $quote, 'message' => 'Quote submitted successfully']);
    }

    public function show($id)
    {
        $quote = PurchaseOrderSupplierQuote::with(['purchaseOrder', 'supplier'])
            ->where('supplier_user_id', auth()->id())
            ->findOrFail($id);

        return response()->json(['success' => true, 'data' => $quote]);
    }

    public function accept($id)
    {
        $quote = PurchaseOrderSupplierQuote::with(['purchaseOrder', 'supplier'])
            ->findOrFail($id);

        if ($quote->status !== 'pending') {
            return response()->json(['success' => false, 'message' => 'Quote sudah diproses sebelumnya.'], 422);
        }

        $purchaseOrder = $quote->purchaseOrder;
        if (!$purchaseOrder) {
            return response()->json(['success' => false, 'message' => 'Purchase order tidak ditemukan.'], 404);
        }

        $quote->update(['status' => 'accepted']);
        PurchaseOrderSupplierQuote::where('purchase_order_id', $purchaseOrder->id)
            ->where('id', '!=', $quote->id)
            ->update(['status' => 'cancelled']);

        $purchaseOrder->update([
            'supplier_name' => $quote->supplier?->name,
            'supplier_phone' => $quote->supplier?->phone,
            'status' => in_array($purchaseOrder->status, ['pending_ai', 'pending_finance'], true)
                ? 'pending_finance'
                : $purchaseOrder->status,
        ]);

        NotificationService::sendToRole(
            UserRole::FINANCE->value,
            'HIGH',
            'Quote Supplier Diterima',
            "Penawaran supplier {$quote->supplier?->name} untuk {$purchaseOrder->item_name} telah diterima.",
            ['quote_id' => $quote->id]
        );

        if ($quote->supplier) {
            NotificationService::send(
                $quote->supplier,
                'NORMAL',
                'Penawaran Anda Diterima',
                "Penawaran untuk {$purchaseOrder->item_name} telah diterima oleh Purchasing.",
                ['quote_id' => $quote->id]
            );
        }

        return response()->json(['success' => true, 'data' => $quote, 'message' => 'Quote berhasil diterima']);
    }

    public function reject($id)
    {
        $quote = PurchaseOrderSupplierQuote::with(['purchaseOrder', 'supplier'])
            ->findOrFail($id);

        if ($quote->status !== 'pending') {
            return response()->json(['success' => false, 'message' => 'Quote sudah diproses sebelumnya.'], 422);
        }

        $quote->update(['status' => 'rejected']);

        if ($quote->supplier) {
            NotificationService::send(
                $quote->supplier,
                'NORMAL',
                'Penawaran Anda Ditolak',
                "Penawaran untuk {$quote->purchaseOrder?->item_name} ditolak oleh Purchasing.",
                ['quote_id' => $quote->id]
            );
        }

        return response()->json(['success' => true, 'data' => $quote, 'message' => 'Quote berhasil ditolak']);
    }

    /**
     * Upload or replace product photo for a quote.
     */
    public function uploadPhoto(Request $request, string $id, StorageService $storageService)
    {
        $request->validate([
            'photo' => 'required|image|mimes:jpeg,jpg,png,webp|max:5120',
        ]);

        $quote = PurchaseOrderSupplierQuote::where('supplier_user_id', $request->user()->id)
            ->findOrFail($id);

        if ($quote->status !== 'pending') {
            return response()->json([
                'success' => false,
                'message' => 'Foto hanya bisa diunggah untuk penawaran yang masih pending.',
            ], 422);
        }

        $path = $storageService->uploadQuotePhoto($request->file('photo'), $quote->id);
        $quote->update(['photo_path' => $path]);

        return response()->json([
            'success' => true,
            'data'    => ['photo_url' => $storageService->getSignedUrl($path)],
            'message' => 'Foto produk berhasil diunggah.',
        ]);
    }

    /**
     * Cancel quote oleh supplier (sebelum diproses).
     */
    public function cancel(Request $request, string $id)
    {
        $quote = PurchaseOrderSupplierQuote::where('supplier_user_id', $request->user()->id)
            ->findOrFail($id);

        if ($quote->status !== 'pending') {
            return response()->json([
                'success' => false,
                'message' => 'Penawaran tidak dapat dibatalkan setelah diproses.',
            ], 422);
        }

        $quote->update(['status' => 'cancelled']);

        return response()->json([
            'success' => true,
            'message' => 'Penawaran berhasil dibatalkan.',
        ]);
    }

    /**
     * Statistik supplier: total quote, awarded, win rate, avg rating.
     */
    public function stats(Request $request)
    {
        $supplierId = $request->user()->id;

        $totalQuotes  = PurchaseOrderSupplierQuote::where('supplier_user_id', $supplierId)->count();
        $awarded      = PurchaseOrderSupplierQuote::where('supplier_user_id', $supplierId)->where('status', 'accepted')->count();
        $winRate      = $totalQuotes > 0 ? round($awarded / $totalQuotes * 100, 1) : 0;
        $avgRating    = $request->user()->supplier_rating ?? 0;

        return response()->json([
            'success' => true,
            'data' => [
                'total_quotes'  => $totalQuotes,
                'awarded_count' => $awarded,
                'win_rate'      => $winRate,
                'avg_rating'    => $avgRating,
            ],
        ]);
    }
}
