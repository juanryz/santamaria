<?php

namespace App\Http\Controllers\Finance;

use App\Http\Controllers\Controller;
use App\Models\ProcurementRequest;
use App\Models\SupplierTransaction;
use App\Services\NotificationService;
use App\Services\StorageService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SupplierTransactionController extends Controller
{
    // GET /finance/supplier-transactions — list transaksi yang perlu dibayar (goods_received)
    public function index(Request $request): JsonResponse
    {
        $query = SupplierTransaction::with([
            'supplier:id,name',
            'procurementRequest:id,request_number,item_name,quantity,unit',
        ]);

        $status = $request->input('payment_status', 'unpaid');
        if ($status !== 'all') {
            $query->where('payment_status', $status);
        }

        if ($request->filled('shipment_status')) {
            $query->where('shipment_status', $request->shipment_status);
        }

        $items = $query->orderByDesc('created_at')->paginate(20);
        return response()->json($items);
    }

    // GET /finance/supplier-transactions/{id}
    public function show(string $id): JsonResponse
    {
        $trx = SupplierTransaction::with([
            'supplier:id,name,supplier_rating_avg',
            'procurementRequest',
            'supplierQuote',
            'financeUser:id,name',
        ])->findOrFail($id);

        return response()->json($trx);
    }

    // PUT /finance/supplier-transactions/{id}/pay
    public function pay(Request $request, string $id): JsonResponse
    {
        $data = $request->validate([
            'method'         => 'required|in:transfer,cash',
            'amount'         => 'required|numeric|min:1',
            'receipt_photo'  => 'nullable|file|mimes:jpg,jpeg,png|max:10240',
            'transfer_date'  => 'nullable|date',
        ]);

        $trx = SupplierTransaction::where('payment_status', 'unpaid')
            ->whereIn('shipment_status', ['goods_received', 'partial_received'])
            ->findOrFail($id);

        $receiptPath = null;
        if ($request->hasFile('receipt_photo')) {
            $receiptPath = StorageService::upload(
                $request->file('receipt_photo'),
                "supplier_payments/{$trx->id}"
            );
        }

        $trx->update([
            'payment_status'       => 'paid',
            'payment_method'       => $data['method'],
            'payment_amount'       => $data['amount'],
            'payment_receipt_path' => $receiptPath,
            'payment_date'         => $data['transfer_date'] ?? now()->toDateString(),
        ]);

        // Update procurement_request ke completed jika goods_received + paid
        $pr = $trx->procurementRequest;
        if ($pr && in_array($pr->status, ['goods_received', 'partial_received'])) {
            $pr->update(['status' => 'completed']);
        }

        // Alarm ke supplier
        NotificationService::send(
            $trx->supplier_id,
            'ALARM',
            'Pembayaran Sudah Dikirimkan',
            "Pembayaran untuk {$pr->item_name} sudah dikirimkan. Silakan cek rekening Anda.",
            ['transaction_id' => $trx->id, 'action' => 'confirm_payment']
        );

        // Notif owner
        NotificationService::sendToRole('owner', 'NORMAL',
            'Pembayaran Supplier Selesai',
            "Transaksi {$trx->transaction_number} dibayar. Total: Rp " . number_format($data['amount'], 0, ',', '.'),
            ['transaction_id' => $trx->id]
        );

        return response()->json(['message' => 'Pembayaran berhasil dicatat.']);
    }

    // GET /finance/supplier-transactions/summary
    public function summary(Request $request): JsonResponse
    {
        $from = $request->input('from', now()->startOfMonth()->toDateString());
        $to   = $request->input('to',   now()->toDateString());

        $data = SupplierTransaction::whereBetween('payment_date', [$from, $to])
            ->where('payment_status', 'paid')
            ->selectRaw('COUNT(*) as total_transactions, SUM(payment_amount) as total_paid')
            ->first();

        return response()->json([
            'period' => ['from' => $from, 'to' => $to],
            'data'   => $data,
        ]);
    }
}
