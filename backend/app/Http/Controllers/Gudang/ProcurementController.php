<?php

namespace App\Http\Controllers\Gudang;

use App\Http\Controllers\Controller;
use App\Models\ProcurementRequest;
use App\Models\SupplierQuote;
use App\Models\SupplierRating;
use App\Models\StockTransaction;
use App\Services\NotificationService;
use App\Services\StorageService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class ProcurementController extends Controller
{
    // GET /gudang/procurement-requests
    public function index(Request $request): JsonResponse
    {
        $query = ProcurementRequest::with(['gudangUser:id,name', 'supplierTransaction'])
            ->where('gudang_user_id', $request->user()->id);

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        $items = $query->orderByDesc('created_at')->paginate(20);
        return response()->json($items);
    }

    // POST /gudang/procurement-requests
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'item_name'        => 'required|string|max:255',
            'specification'    => 'nullable|string',
            'category'         => 'required|string|max:100',
            'quantity'         => 'required|integer|min:1',
            'unit'             => 'required|string|max:50',
            'estimated_price'  => 'nullable|numeric|min:0',
            'max_price'        => 'nullable|numeric|min:0',
            'delivery_address' => 'required|string',
            'needed_by'        => 'nullable|date|after:today',
            'quote_deadline'   => 'nullable|date|after:today',
            'order_id'         => 'nullable|uuid|exists:orders,id',
        ]);

        $data['gudang_user_id']  = $request->user()->id;
        $data['request_number']  = ProcurementRequest::generateRequestNumber();
        $data['status']          = 'draft';

        $pr = ProcurementRequest::create($data);

        return response()->json($pr, 201);
    }

    // GET /gudang/procurement-requests/{id}
    public function show(Request $request, string $id): JsonResponse
    {
        $pr = ProcurementRequest::with([
            'gudangUser:id,name',
            'quotes.supplier:id,name,supplier_rating_avg',
            'supplierTransaction',
        ])->where('gudang_user_id', $request->user()->id)->findOrFail($id);

        return response()->json($pr);
    }

    // PUT /gudang/procurement-requests/{id}/publish
    public function publish(Request $request, string $id): JsonResponse
    {
        $pr = ProcurementRequest::where('gudang_user_id', $request->user()->id)
            ->where('status', 'draft')
            ->findOrFail($id);

        $pr->update([
            'status'       => 'open',
            'published_at' => now(),
        ]);

        // Alarm ke semua supplier terverifikasi
        $supplierIds = \App\Models\User::where('role', 'supplier')
            ->where('is_verified_supplier', true)
            ->pluck('id');

        foreach ($supplierIds as $sid) {
            NotificationService::send(
                $sid,
                'ALARM',
                'Pengadaan Baru Tersedia',
                "Pengadaan baru: {$pr->item_name} ({$pr->quantity} {$pr->unit}). Segera ajukan penawaran!",
                ['procurement_request_id' => $pr->id, 'action' => 'view_procurement']
            );
        }

        return response()->json(['message' => 'Permintaan dipublikasikan.', 'data' => $pr]);
    }

    // PUT /gudang/procurement-requests/{id}/cancel
    public function cancel(Request $request, string $id): JsonResponse
    {
        $data = $request->validate(['reason' => 'nullable|string']);

        $pr = ProcurementRequest::where('gudang_user_id', $request->user()->id)
            ->whereNotIn('status', ['finance_approved', 'goods_received', 'completed'])
            ->findOrFail($id);

        $pr->update([
            'status'           => 'cancelled',
            'cancelled_at'     => now(),
            'cancelled_reason' => $data['reason'] ?? null,
        ]);

        return response()->json(['message' => 'Permintaan dibatalkan.']);
    }

    // GET /gudang/procurement-requests/{id}/quotes
    public function quotes(Request $request, string $id): JsonResponse
    {
        $pr = ProcurementRequest::where('gudang_user_id', $request->user()->id)->findOrFail($id);

        $quotes = SupplierQuote::with('supplier:id,name,supplier_rating_avg,supplier_rating_count')
            ->where('procurement_request_id', $id)
            ->whereNotIn('status', ['cancelled'])
            ->orderBy('total_price')
            ->get();

        return response()->json([
            'procurement_request' => $pr,
            'quotes'              => $quotes,
            'quote_count'         => $quotes->count(),
        ]);
    }

    // PUT /gudang/supplier-quotes/{quoteId}/award — pilih pemenang
    public function awardQuote(Request $request, string $quoteId): JsonResponse
    {
        $quote = SupplierQuote::with('procurementRequest')->findOrFail($quoteId);
        $pr    = $quote->procurementRequest;

        abort_if($pr->gudang_user_id !== $request->user()->id, 403);
        abort_if($pr->status !== 'evaluating', 422, 'Status permintaan harus evaluating.');
        abort_if($quote->status !== 'submitted' && $quote->status !== 'under_review', 422, 'Quote tidak dapat dipilih.');

        DB::transaction(function () use ($quote, $pr) {
            // Tandai pemenang
            $quote->update(['status' => 'awarded']);

            // Tolak yang lain
            SupplierQuote::where('procurement_request_id', $pr->id)
                ->where('id', '!=', $quote->id)
                ->whereNotIn('status', ['cancelled'])
                ->update(['status' => 'rejected']);

            $pr->update(['status' => 'awarded']);

            // Alarm Finance
            NotificationService::sendToRole(
                'finance',
                'ALARM',
                'Pengadaan Butuh Approval!',
                "Barang: {$pr->item_name} | Supplier: {$quote->supplier->name} | Total: Rp " . number_format($quote->total_price, 0, ',', '.'),
                ['procurement_request_id' => $pr->id, 'action' => 'finance_approve_procurement']
            );
        });

        return response()->json(['message' => 'Penawaran terpilih. Menunggu approval Finance.']);
    }

    // PUT /gudang/supplier-quotes/{quoteId}/reject — tolak satu quote
    public function rejectQuote(Request $request, string $quoteId): JsonResponse
    {
        $quote = SupplierQuote::with('procurementRequest')->findOrFail($quoteId);
        $pr    = $quote->procurementRequest;

        abort_if($pr->gudang_user_id !== $request->user()->id, 403);
        abort_if(!in_array($quote->status, ['submitted', 'under_review']), 422, 'Quote tidak dapat ditolak.');

        $quote->update(['status' => 'rejected']);

        return response()->json(['message' => 'Penawaran ditolak.']);
    }

    // PUT /gudang/procurement-requests/{id}/receive — konfirmasi terima barang
    public function receive(Request $request, string $id): JsonResponse
    {
        $data = $request->validate([
            'received_qty'  => 'required|integer|min:1',
            'condition'     => 'required|in:baik,ada_kerusakan',
            'notes'         => 'nullable|string',
            'photo'         => 'nullable|file|mimes:jpg,jpeg,png|max:10240',
        ]);

        $pr = ProcurementRequest::where('gudang_user_id', $request->user()->id)
            ->where('status', 'finance_approved')
            ->with('supplierTransaction')
            ->findOrFail($id);

        $photoPath = null;
        if ($request->hasFile('photo')) {
            $photoPath = StorageService::upload($request->file('photo'), "procurement_receipts/{$pr->id}");
        }

        $isPartial = $data['received_qty'] < $pr->quantity || $data['condition'] === 'ada_kerusakan';
        $newStatus = $isPartial ? 'partial_received' : 'goods_received';

        DB::transaction(function () use ($pr, $data, $photoPath, $newStatus, $isPartial, $request) {
            $pr->update(['status' => $newStatus]);

            if ($pr->supplierTransaction) {
                $pr->supplierTransaction->update([
                    'shipment_status'    => $isPartial ? 'partial_received' : 'goods_received',
                    'received_at'        => now(),
                    'received_quantity'  => $data['received_qty'],
                    'received_condition' => $data['notes'] ?? $data['condition'],
                    'received_photo_path'=> $photoPath,
                ]);
            }

            // Otomatis tambah stok jika tidak partial
            if (!$isPartial) {
                // Cari stock_item berdasarkan nama item
                $stockItem = \App\Models\StockItem::where('item_name', 'like', "%{$pr->item_name}%")->first();
                if ($stockItem) {
                    $stockItem->increment('current_quantity', $data['received_qty']);
                    StockTransaction::create([
                        'stock_item_id' => $stockItem->id,
                        'type'          => 'in',
                        'quantity'      => $data['received_qty'],
                        'notes'         => "Dari e-Katalog {$pr->request_number}, supplier: " . optional($pr->supplierTransaction?->supplier)->name,
                        'user_id'       => $request->user()->id,
                    ]);
                }
            }

            // Alarm Finance untuk bayar
            NotificationService::sendToRole(
                'finance',
                'ALARM',
                'Barang Diterima — Proses Pembayaran!',
                "Barang {$pr->item_name} sudah diterima. Segera proses pembayaran ke supplier.",
                ['procurement_request_id' => $pr->id, 'action' => 'finance_pay_supplier']
            );

            if ($isPartial) {
                NotificationService::send(
                    $pr->supplierTransaction->supplier_id,
                    'HIGH',
                    'Ada Ketidaksesuaian Pengiriman',
                    "Barang yang diterima tidak sesuai pesanan. Tim akan menghubungi Anda.",
                    ['transaction_id' => $pr->supplierTransaction->id]
                );
            }
        });

        return response()->json(['message' => $isPartial ? 'Barang diterima sebagian.' : 'Barang diterima lengkap. Stok bertambah otomatis.']);
    }

    // POST /gudang/supplier-ratings — beri rating
    public function rateSupplier(Request $request): JsonResponse
    {
        $data = $request->validate([
            'supplier_id'             => 'required|uuid|exists:users,id',
            'procurement_request_id'  => 'required|uuid|exists:procurement_requests,id',
            'rating'                  => 'required|integer|min:1|max:5',
            'review'                  => 'nullable|string|max:500',
        ]);

        $data['rated_by'] = $request->user()->id;

        $rating = SupplierRating::updateOrCreate(
            ['supplier_id' => $data['supplier_id'], 'procurement_request_id' => $data['procurement_request_id']],
            $data
        );

        // Update avg rating on user
        $avg   = SupplierRating::where('supplier_id', $data['supplier_id'])->avg('rating');
        $count = SupplierRating::where('supplier_id', $data['supplier_id'])->count();
        \App\Models\User::where('id', $data['supplier_id'])->update([
            'supplier_rating_avg'   => round($avg, 2),
            'supplier_rating_count' => $count,
        ]);

        return response()->json(['message' => 'Rating disimpan.', 'data' => $rating], 201);
    }
}
