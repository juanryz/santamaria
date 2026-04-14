<?php

namespace App\Http\Controllers\Supplier;

use App\Http\Controllers\Controller;
use App\Models\SupplierTransaction;
use App\Services\NotificationService;
use App\Services\StorageService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TransactionController extends Controller
{
    // GET /supplier/transactions
    public function index(Request $request): JsonResponse
    {
        $transactions = SupplierTransaction::with([
            'procurementRequest:id,request_number,item_name,quantity,unit,delivery_address,needed_by',
        ])
            ->where('supplier_id', $request->user()->id)
            ->orderByDesc('created_at')
            ->paginate(20);

        return response()->json($transactions);
    }

    // GET /supplier/transactions/{id}
    public function show(Request $request, string $id): JsonResponse
    {
        $trx = SupplierTransaction::with([
            'procurementRequest',
            'supplierQuote',
            'financeUser:id,name',
        ])
            ->where('supplier_id', $request->user()->id)
            ->findOrFail($id);

        $paymentReceiptUrl = $trx->payment_receipt_path
            ? StorageService::getSignedUrl($trx->payment_receipt_path)
            : null;

        return response()->json([
            'transaction'        => $trx,
            'payment_receipt_url'=> $paymentReceiptUrl,
        ]);
    }

    // PUT /supplier/quotes/{id}/mark-shipped
    public function markShipped(Request $request, string $quoteId): JsonResponse
    {
        $data = $request->validate([
            'tracking_number' => 'required|string|max:100',
            'photo'           => 'nullable|file|mimes:jpg,jpeg,png|max:10240',
        ]);

        $quote = \App\Models\SupplierQuote::where('supplier_id', $request->user()->id)
            ->where('status', 'awarded')
            ->findOrFail($quoteId);

        $trx = $quote->transaction;
        abort_if(!$trx, 422, 'Transaksi belum dibuat.');
        abort_if($trx->shipment_status !== 'pending_shipment', 422, 'Barang sudah ditandai dikirim.');

        $photoPath = null;
        if ($request->hasFile('photo')) {
            $photoPath = StorageService::upload($request->file('photo'), "shipment_photos/{$trx->id}");
        }

        $trx->update([
            'shipment_status'      => 'shipped',
            'tracking_number'      => $data['tracking_number'],
            'shipment_photo_path'  => $photoPath,
            'shipped_at'           => now(),
        ]);

        $quote->update([
            'status'          => 'shipped',
            'tracking_number' => $data['tracking_number'],
            'shipped_at'      => now(),
            'shipment_photo_path' => $photoPath,
        ]);

        // Notif Gudang
        NotificationService::sendToRole('gudang', 'ALARM',
            'Supplier Sudah Mengirim Barang',
            "Supplier sudah mengirim {$trx->procurementRequest->item_name}. Nomor resi: {$data['tracking_number']}",
            ['transaction_id' => $trx->id, 'action' => 'receive_goods']
        );

        return response()->json(['message' => 'Pengiriman berhasil ditandai.']);
    }

    // PUT /supplier/transactions/{id}/confirm-payment
    public function confirmPayment(Request $request, string $id): JsonResponse
    {
        $trx = SupplierTransaction::where('supplier_id', $request->user()->id)
            ->where('payment_status', 'paid')
            ->where('payment_confirmed_by_supplier', false)
            ->findOrFail($id);

        $trx->update([
            'payment_confirmed_by_supplier' => true,
            'payment_confirmed_at'          => now(),
        ]);

        return response()->json(['message' => 'Penerimaan pembayaran dikonfirmasi.']);
    }

    // GET /supplier/stats
    public function stats(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        $totalBid  = \App\Models\SupplierQuote::where('supplier_id', $userId)->count();
        $totalWin  = \App\Models\SupplierQuote::where('supplier_id', $userId)->where('status', 'awarded')->count();
        $winRate   = $totalBid > 0 ? round(($totalWin / $totalBid) * 100, 1) : 0;
        $totalTrx  = SupplierTransaction::where('supplier_id', $userId)->where('payment_status', 'paid')->sum('payment_amount');
        $avgRating = $request->user()->supplier_rating_avg;

        return response()->json([
            'total_bid'        => $totalBid,
            'total_win'        => $totalWin,
            'win_rate_pct'     => $winRate,
            'total_transaksi'  => $totalTrx,
            'avg_rating'       => $avgRating,
            'rating_count'     => $request->user()->supplier_rating_count,
        ]);
    }

    // GET /supplier/profile
    public function profile(Request $request): JsonResponse
    {
        return response()->json($request->user());
    }

    // PUT /supplier/profile
    public function updateProfile(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name'    => 'sometimes|string|max:255',
            'phone'   => 'sometimes|string|max:20',
            'address' => 'sometimes|string',
            'npwp'    => 'sometimes|string|max:50',
        ]);

        $request->user()->update($data);
        return response()->json(['message' => 'Profil diperbarui.', 'data' => $request->user()]);
    }

    // GET /supplier/ratings
    public function ratings(Request $request): JsonResponse
    {
        $ratings = \App\Models\SupplierRating::with('procurementRequest:id,request_number,item_name')
            ->where('supplier_id', $request->user()->id)
            ->orderByDesc('created_at')
            ->paginate(20);

        return response()->json($ratings);
    }
}
