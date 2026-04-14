<?php

namespace App\Http\Controllers\Supplier;

use App\Http\Controllers\Controller;
use App\Models\ProcurementRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CatalogController extends Controller
{
    // GET /supplier/procurement-requests — semua request status 'open'
    public function index(Request $request): JsonResponse
    {
        $query = ProcurementRequest::where('status', 'open')
            ->withCount(['quotes as quote_count' => function ($q) {
                $q->whereNotIn('status', ['cancelled']);
            }])
            ->with('gudangUser:id,name');

        if ($request->filled('category')) {
            $query->where('category', $request->category);
        }

        if ($request->filled('search')) {
            $query->where('item_name', 'ilike', '%' . $request->search . '%');
        }

        $sort = $request->input('sort', 'newest');
        match ($sort) {
            'deadline' => $query->orderBy('quote_deadline'),
            default    => $query->orderByDesc('published_at'),
        };

        $items = $query->paginate(20);
        return response()->json($items);
    }

    // GET /supplier/procurement-requests/{id}
    public function show(Request $request, string $id): JsonResponse
    {
        $pr = ProcurementRequest::where('status', 'open')
            ->withCount(['quotes as quote_count' => function ($q) {
                $q->whereNotIn('status', ['cancelled']);
            }])
            ->findOrFail($id);

        // Cek apakah supplier ini sudah punya penawaran aktif
        $myQuote = \App\Models\SupplierQuote::where('procurement_request_id', $id)
            ->where('supplier_id', $request->user()->id)
            ->whereNotIn('status', ['cancelled'])
            ->first();

        return response()->json([
            'request'  => $pr,
            'my_quote' => $myQuote,
        ]);
    }
}
