<?php

namespace App\Http\Controllers\Purchasing;

use App\Http\Controllers\Controller;
use App\Models\ConsumerMembership;
use App\Models\MembershipPayment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * v1.39 — Purchasing input pembayaran iuran membership bulanan.
 * Setiap pembayaran update next_payment_due + total_paid + restore status ke active.
 */
class MembershipPaymentController extends Controller
{
    /** List all payments (filter: membership_id, period). */
    public function index(Request $request)
    {
        $q = MembershipPayment::with([
            'membership.user:id,name,phone',
            'receiver:id,name',
        ]);

        if ($request->filled('membership_id')) {
            $q->where('membership_id', $request->membership_id);
        }
        if ($request->filled('year')) {
            $q->where('payment_period_year', $request->year);
        }
        if ($request->filled('month')) {
            $q->where('payment_period_month', $request->month);
        }

        return $this->success($q->orderByDesc('paid_at')->paginate(30));
    }

    /** Record payment + update membership status. */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'membership_id' => 'required|uuid|exists:consumer_memberships,id',
            'payment_period_year' => 'required|integer|min:2020|max:2100',
            'payment_period_month' => 'required|integer|min:1|max:12',
            'amount' => 'required|numeric|min:0',
            'payment_method' => 'required|string|in:cash,transfer',
            'receipt_path' => 'nullable|string|max:500',
            'notes' => 'nullable|string|max:500',
        ]);

        // Cek duplicate
        $exists = MembershipPayment::where([
            'membership_id' => $validated['membership_id'],
            'payment_period_year' => $validated['payment_period_year'],
            'payment_period_month' => $validated['payment_period_month'],
        ])->exists();
        if ($exists) {
            return $this->error(
                'Pembayaran untuk period ini sudah tercatat.',
                409
            );
        }

        $payment = DB::transaction(function () use ($validated, $request) {
            $payment = MembershipPayment::create(array_merge($validated, [
                'paid_at' => now(),
                'received_by' => $request->user()->id,
            ]));

            $m = ConsumerMembership::find($validated['membership_id']);
            if ($m) {
                $m->total_paid = (float) $m->total_paid + (float) $validated['amount'];
                $m->last_payment_date = now()->toDateString();
                // Next due = paid period + 1 month
                $nextDue = \Carbon\Carbon::create(
                    $validated['payment_period_year'],
                    $validated['payment_period_month']
                )->addMonth()->endOfMonth();
                $m->next_payment_due = $nextDue->toDateString();
                $m->grace_period_until = null;

                // Restore status ke active jika sedang grace/inactive
                if (in_array($m->status, ['grace_period', 'inactive'])) {
                    $m->status = 'active';
                }

                $m->save();
            }

            return $payment;
        });

        return $this->created($payment->load('membership.user:id,name,phone'));
    }

    /** List membership dengan pembayaran yang jatuh tempo (Purchasing follow-up). */
    public function dueList()
    {
        $memberships = ConsumerMembership::with('user:id,name,phone')
            ->whereIn('status', ['active', 'grace_period'])
            ->whereNotNull('next_payment_due')
            ->where('next_payment_due', '<=', now()->addDays(7)->toDateString())
            ->orderBy('next_payment_due')
            ->get();

        return $this->success($memberships);
    }
}
