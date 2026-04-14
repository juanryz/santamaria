<?php

namespace App\Http\Controllers\Supplier;

use App\Http\Controllers\Controller;
use App\Models\ProcurementRequest;
use App\Models\SupplierQuote;
use App\Services\StorageService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class QuoteController extends Controller
{
    // POST /supplier/quotes — ajukan penawaran baru
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'procurement_request_id'  => 'required|uuid|exists:procurement_requests,id',
            'unit_price'              => 'required|numeric|min:1',
            'brand'                   => 'nullable|string|max:255',
            'description'             => 'nullable|string',
            'estimated_delivery_days' => 'required|integer|min:1',
            'warranty_info'           => 'nullable|string',
            'terms'                   => 'nullable|string',
        ]);

        $pr = ProcurementRequest::where('status', 'open')->findOrFail($data['procurement_request_id']);

        // Validasi deadline
        if ($pr->quote_deadline && now()->isAfter($pr->quote_deadline)) {
            return response()->json(['message' => 'Deadline pengajuan penawaran sudah terlewat.'], 422);
        }

        // Validasi sealed bid: supplier hanya boleh 1 penawaran aktif per permintaan
        $existing = SupplierQuote::where('procurement_request_id', $pr->id)
            ->where('supplier_id', $request->user()->id)
            ->whereNotIn('status', ['cancelled'])
            ->exists();

        if ($existing) {
            return response()->json(['message' => 'Anda sudah mengajukan penawaran untuk permintaan ini.'], 422);
        }

        $totalPrice = $data['unit_price'] * $pr->quantity;

        // Validasi max_price
        if ($pr->max_price && $totalPrice > $pr->max_price) {
            return response()->json([
                'message' => "Total harga Rp " . number_format($totalPrice, 0, ',', '.') . " melebihi batas maksimum Rp " . number_format($pr->max_price, 0, ',', '.') . ".",
            ], 422);
        }

        $data['supplier_id'] = $request->user()->id;
        $data['total_price'] = $totalPrice;
        $data['status']      = 'submitted';

        $quote = SupplierQuote::create($data);

        // Dispatch AI validasi harga di background
        dispatch(new \App\Jobs\ValidateQuotePrice($quote));

        return response()->json($quote, 201);
    }

    // GET /supplier/quotes — riwayat semua penawaran supplier ini
    public function index(Request $request): JsonResponse
    {
        $quotes = SupplierQuote::with('procurementRequest:id,request_number,item_name,quantity,unit,status')
            ->where('supplier_id', $request->user()->id)
            ->orderByDesc('created_at')
            ->paginate(20);

        return response()->json($quotes);
    }

    // GET /supplier/quotes/{id}
    public function show(Request $request, string $id): JsonResponse
    {
        $quote = SupplierQuote::with([
            'procurementRequest:id,request_number,item_name,quantity,unit,delivery_address,needed_by,status',
            'transaction',
        ])
            ->where('supplier_id', $request->user()->id)
            ->findOrFail($id);

        return response()->json($quote);
    }

    // PUT /supplier/quotes/{id}/cancel
    public function cancel(Request $request, string $id): JsonResponse
    {
        $quote = SupplierQuote::where('supplier_id', $request->user()->id)
            ->where('status', 'submitted')
            ->findOrFail($id);

        $pr = $quote->procurementRequest;
        if ($pr->quote_deadline && now()->isAfter($pr->quote_deadline)) {
            return response()->json(['message' => 'Tidak bisa membatalkan setelah deadline.'], 422);
        }

        $quote->update(['status' => 'cancelled']);

        return response()->json(['message' => 'Penawaran dibatalkan.']);
    }

    // POST /supplier/quotes/{id}/product-photo
    public function uploadPhoto(Request $request, string $id): JsonResponse
    {
        $request->validate(['photo' => 'required|file|mimes:jpg,jpeg,png|max:10240']);

        $quote = SupplierQuote::where('supplier_id', $request->user()->id)
            ->where('status', 'submitted')
            ->findOrFail($id);

        $path = StorageService::upload($request->file('photo'), "supplier_quote_photos/{$id}");
        $quote->update(['photo_path' => $path]);

        return response()->json(['message' => 'Foto produk diunggah.', 'path' => $path]);
    }
}
