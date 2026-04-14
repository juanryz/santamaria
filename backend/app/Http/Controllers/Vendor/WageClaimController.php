<?php

namespace App\Http\Controllers\Vendor;

use App\Http\Controllers\Controller;
use App\Models\ServiceWageClaim;
use App\Models\ServiceWageRate;
use Illuminate\Http\Request;

class WageClaimController extends Controller
{
    /**
     * Daftar klaim upah milik pekerja yg login.
     */
    public function index(Request $request)
    {
        $claims = ServiceWageClaim::with([
            'order:id,order_number,deceased_name,scheduled_at',
            'wageRate:id,rate_amount,service_package',
            'payment',
        ])
            ->where('claimant_id', $request->user()->id)
            ->orderByDesc('created_at')
            ->get();

        return response()->json(['success' => true, 'data' => $claims]);
    }

    /**
     * Ajukan klaim upah untuk order tertentu.
     */
    public function store(Request $request)
    {
        $request->validate([
            'order_id'    => 'required|uuid|exists:orders,id',
            'claim_notes' => 'nullable|string|max:500',
        ]);

        $user = $request->user();

        // Cek belum pernah klaim untuk order ini
        $exists = ServiceWageClaim::where('order_id', $request->order_id)
            ->where('claimant_id', $user->id)
            ->whereIn('status', ['pending', 'approved', 'paid'])
            ->exists();

        if ($exists) {
            return response()->json([
                'success' => false,
                'message' => 'Anda sudah mengajukan klaim untuk order ini.',
            ], 422);
        }

        // Cari tarif aktif untuk role + paket
        $rate = ServiceWageRate::where('role', $user->role)
            ->where('is_active', true)
            ->orderByDesc('updated_at')
            ->first();

        $claimedAmount = $rate ? $rate->rate_amount : 0;

        $claim = ServiceWageClaim::create([
            'order_id'       => $request->order_id,
            'claimant_id'    => $user->id,
            'claimant_role'  => $user->role,
            'wage_rate_id'   => $rate?->id,
            'claimed_amount' => $claimedAmount,
            'claim_notes'    => $request->claim_notes,
            'status'         => 'pending',
        ]);

        return response()->json([
            'success' => true,
            'data'    => $claim->load(['order:id,order_number,deceased_name', 'wageRate:id,rate_amount']),
            'message' => 'Klaim upah berhasil diajukan. Silakan ambil di kantor setelah disetujui.',
        ], 201);
    }

    /**
     * Detail klaim.
     */
    public function show(Request $request, string $id)
    {
        $claim = ServiceWageClaim::with([
            'order:id,order_number,deceased_name,scheduled_at',
            'wageRate:id,rate_amount,service_package',
            'reviewer:id,name',
            'payment',
        ])
            ->where('claimant_id', $request->user()->id)
            ->findOrFail($id);

        return response()->json(['success' => true, 'data' => $claim]);
    }

    /**
     * Konfirmasi sudah terima uang (oleh pekerja).
     */
    public function confirmReceived(Request $request, string $id)
    {
        $claim = ServiceWageClaim::where('claimant_id', $request->user()->id)
            ->where('status', 'paid')
            ->findOrFail($id);

        $payment = $claim->payment;
        if ($payment) {
            $payment->update([
                'confirmed_by_claimant' => true,
                'confirmed_at'          => now(),
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Penerimaan upah telah dikonfirmasi.',
        ]);
    }

    /**
     * Ringkasan upah saya.
     */
    public function mySummary(Request $request)
    {
        $userId = $request->user()->id;

        $pending = ServiceWageClaim::where('claimant_id', $userId)
            ->where('status', 'pending')->sum('claimed_amount');
        $approved = ServiceWageClaim::where('claimant_id', $userId)
            ->where('status', 'approved')->sum('approved_amount');
        $paid = ServiceWageClaim::where('claimant_id', $userId)
            ->where('status', 'paid')
            ->join('service_wage_payments', 'service_wage_claims.id', '=', 'service_wage_payments.claim_id')
            ->sum('service_wage_payments.paid_amount');

        return response()->json([
            'success' => true,
            'data'    => [
                'pending_amount'  => (float) $pending,
                'approved_amount' => (float) $approved,
                'paid_amount'     => (float) $paid,
                'total_unpaid'    => (float) ($pending + $approved),
            ],
        ]);
    }
}
