<?php

namespace App\Http\Controllers\Purchasing;

use App\Http\Controllers\Controller;
use App\Models\ServiceWageClaim;
use App\Models\ServiceWagePayment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class WageClaimController extends Controller
{
    /**
     * Daftar semua klaim upah — untuk review Purchasing.
     */
    public function index(Request $request)
    {
        $query = ServiceWageClaim::with([
            'claimant:id,name,phone,role',
            'order:id,order_number,deceased_name,scheduled_at',
            'wageRate:id,rate_amount,service_package',
            'payment',
        ])->orderByRaw("CASE status WHEN 'pending' THEN 0 WHEN 'approved' THEN 1 ELSE 2 END")
          ->orderByDesc('created_at');

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }
        if ($request->filled('role')) {
            $query->where('claimant_role', $request->role);
        }

        return response()->json([
            'success' => true,
            'data'    => $query->get(),
        ]);
    }

    /**
     * Detail klaim.
     */
    public function show(string $id)
    {
        $claim = ServiceWageClaim::with([
            'claimant:id,name,phone,role,email',
            'order:id,order_number,deceased_name,scheduled_at,service_package',
            'wageRate',
            'reviewer:id,name',
            'payment.payer:id,name',
        ])->findOrFail($id);

        return response()->json(['success' => true, 'data' => $claim]);
    }

    /**
     * Approve klaim + tentukan jumlah yg disetujui.
     */
    public function approve(Request $request, string $id)
    {
        $claim = ServiceWageClaim::where('status', 'pending')->findOrFail($id);

        $request->validate([
            'approved_amount' => 'required|numeric|min:0',
            'review_notes'    => 'nullable|string|max:500',
        ]);

        $claim->update([
            'status'          => 'approved',
            'approved_amount' => $request->approved_amount,
            'review_notes'    => $request->review_notes,
            'reviewed_by'     => $request->user()->id,
            'reviewed_at'     => now(),
        ]);

        return response()->json([
            'success' => true,
            'data'    => $claim->fresh()->load('claimant:id,name'),
            'message' => 'Klaim upah disetujui.',
        ]);
    }

    /**
     * Tolak klaim.
     */
    public function reject(Request $request, string $id)
    {
        $claim = ServiceWageClaim::where('status', 'pending')->findOrFail($id);

        $request->validate([
            'review_notes' => 'required|string|max:500',
        ]);

        $claim->update([
            'status'      => 'rejected',
            'review_notes' => $request->review_notes,
            'reviewed_by'  => $request->user()->id,
            'reviewed_at'  => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Klaim upah ditolak.',
        ]);
    }

    /**
     * Bayar klaim yang sudah di-approve — upload bukti cash/transfer.
     */
    public function pay(Request $request, string $id)
    {
        $claim = ServiceWageClaim::where('status', 'approved')->findOrFail($id);

        $request->validate([
            'payment_method' => 'required|in:cash,transfer',
            'paid_amount'    => 'required|numeric|min:0',
            'receipt_photo'  => 'required|image|mimes:jpg,jpeg,png|max:5120',
            'bank_name'      => 'nullable|string|max:100',
            'account_number' => 'nullable|string|max:50',
            'account_holder' => 'nullable|string|max:255',
            'payment_notes'  => 'nullable|string|max:500',
        ]);

        $receiptPath = null;
        if ($request->hasFile('receipt_photo')) {
            $receiptPath = $request->file('receipt_photo')
                ->store("wage_payments/{$claim->id}", 'public');
        }

        $payment = ServiceWagePayment::create([
            'claim_id'       => $claim->id,
            'paid_amount'    => $request->paid_amount,
            'payment_method' => $request->payment_method,
            'receipt_photo_path' => $receiptPath,
            'bank_name'      => $request->bank_name,
            'account_number' => $request->account_number,
            'account_holder' => $request->account_holder,
            'payment_notes'  => $request->payment_notes,
            'paid_by'        => $request->user()->id,
            'paid_at'        => now(),
        ]);

        $claim->update(['status' => 'paid']);

        return response()->json([
            'success' => true,
            'data'    => $payment->load('payer:id,name'),
            'message' => 'Pembayaran upah berhasil dicatat.',
        ]);
    }

    /**
     * Ringkasan akumulasi per pekerja (belum dibayar).
     */
    public function summary(Request $request)
    {
        $claims = ServiceWageClaim::selectRaw("
                claimant_id,
                claimant_role,
                COUNT(*) as total_claims,
                SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending_count,
                SUM(CASE WHEN status = 'approved' THEN 1 ELSE 0 END) as approved_count,
                SUM(CASE WHEN status = 'paid' THEN 1 ELSE 0 END) as paid_count,
                SUM(CASE WHEN status = 'approved' THEN COALESCE(approved_amount, claimed_amount) ELSE 0 END) as unpaid_total,
                SUM(CASE WHEN status = 'pending' THEN claimed_amount ELSE 0 END) as pending_total
            ")
            ->groupBy('claimant_id', 'claimant_role')
            ->with('claimant:id,name,phone,role')
            ->get();

        return response()->json(['success' => true, 'data' => $claims]);
    }
}
