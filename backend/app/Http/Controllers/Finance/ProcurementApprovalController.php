<?php

namespace App\Http\Controllers\Finance;

use App\Http\Controllers\Controller;
use App\Models\ProcurementRequest;
use App\Models\SupplierTransaction;
use App\Services\NotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ProcurementApprovalController extends Controller
{
    // GET /finance/procurement-requests — list status 'awarded'
    public function index(Request $request): JsonResponse
    {
        $query = ProcurementRequest::with([
            'gudangUser:id,name',
            'winnerQuote.supplier:id,name,supplier_rating_avg',
        ]);

        $status = $request->input('status', 'awarded');
        $query->where('status', $status);

        $items = $query->orderByDesc('updated_at')->paginate(20);
        return response()->json($items);
    }

    // GET /finance/procurement-requests/{id}
    public function show(string $id): JsonResponse
    {
        $pr = ProcurementRequest::with([
            'gudangUser:id,name',
            'winnerQuote.supplier:id,name,supplier_rating_avg,supplier_rating_count',
            'supplierTransaction',
        ])->findOrFail($id);

        return response()->json($pr);
    }

    // PUT /finance/procurement-requests/{id}/approve
    public function approve(Request $request, string $id): JsonResponse
    {
        $pr = ProcurementRequest::where('status', 'awarded')
            ->with('winnerQuote.supplier')
            ->findOrFail($id);

        $winnerQuote = $pr->winnerQuote;
        abort_if(!$winnerQuote, 422, 'Tidak ada penawaran terpilih.');

        DB::transaction(function () use ($pr, $winnerQuote, $request) {
            $pr->update([
                'status'              => 'finance_approved',
                'finance_user_id'     => $request->user()->id,
                'finance_approved_at' => now(),
            ]);

            // Buat supplier_transactions
            $trx = SupplierTransaction::create([
                'transaction_number'    => SupplierTransaction::generateTransactionNumber(),
                'procurement_request_id'=> $pr->id,
                'supplier_quote_id'     => $winnerQuote->id,
                'supplier_id'           => $winnerQuote->supplier_id,
                'finance_user_id'       => $request->user()->id,
                'agreed_unit_price'     => $winnerQuote->unit_price,
                'agreed_quantity'       => $pr->quantity,
                'agreed_total'          => $winnerQuote->total_price,
                'shipment_status'       => 'pending_shipment',
                'payment_status'        => 'unpaid',
                'finance_approved_at'   => now(),
            ]);

            $pr->update(['supplier_transaction_id' => $trx->id]);

            // FCM ALARM ke supplier pemenang
            NotificationService::send(
                $winnerQuote->supplier_id,
                'ALARM',
                '🎉 Penawaran Anda Disetujui!',
                "Silakan kirimkan {$pr->item_name} sejumlah {$pr->quantity} {$pr->unit} ke {$pr->delivery_address}. Batas pengiriman: " . optional($pr->needed_by)->format('d M Y'),
                ['transaction_id' => $trx->id, 'action' => 'view_transaction']
            );

            // Notif supplier yang kalah
            $loserIds = \App\Models\SupplierQuote::where('procurement_request_id', $pr->id)
                ->where('status', 'rejected')
                ->pluck('supplier_id');

            foreach ($loserIds as $loserId) {
                NotificationService::send(
                    $loserId,
                    'NORMAL',
                    'Penawaran Tidak Dipilih',
                    "Penawaran Anda untuk permintaan {$pr->request_number} tidak dipilih. Terima kasih telah berpartisipasi.",
                    []
                );
            }

            // Notif Gudang
            NotificationService::sendToRole('gudang', 'NORMAL',
                'Finance Menyetujui Pengadaan',
                "Pengadaan {$pr->item_name} disetujui. Tunggu barang dari supplier.",
                ['procurement_request_id' => $pr->id]
            );
        });

        return response()->json(['message' => 'Pengadaan disetujui. Supplier akan segera dihubungi.']);
    }

    // PUT /finance/procurement-requests/{id}/reject
    public function reject(Request $request, string $id): JsonResponse
    {
        $data = $request->validate([
            'reason' => 'required|string',
        ]);

        $pr = ProcurementRequest::where('status', 'awarded')->findOrFail($id);

        $pr->update([
            'status'                   => 'evaluating',
            'finance_rejection_reason' => $data['reason'],
        ]);

        NotificationService::sendToRole('gudang', 'ALARM',
            'Pengadaan Ditolak Finance',
            "Pengadaan {$pr->item_name} ditolak. Alasan: {$data['reason']}. Silakan pilih supplier lain.",
            ['procurement_request_id' => $pr->id, 'action' => 'view_quotes']
        );

        return response()->json(['message' => 'Pengadaan ditolak. Gudang akan memilih ulang.']);
    }
}
