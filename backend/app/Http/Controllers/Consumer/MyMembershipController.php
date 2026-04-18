<?php

namespace App\Http\Controllers\Consumer;

use App\Http\Controllers\Controller;
use App\Models\ConsumerMembership;
use Illuminate\Http\Request;

/**
 * v1.39 — Consumer self-view untuk membership.
 * Consumer cek status membership sendiri + riwayat pembayaran iuran.
 */
class MyMembershipController extends Controller
{
    /** Get my membership (if exists). */
    public function show(Request $request)
    {
        $membership = ConsumerMembership::with([
            'payments' => fn($q) => $q->orderByDesc('payment_period_year')
                ->orderByDesc('payment_period_month')->limit(24),
            'payments.receiver:id,name',
        ])
            ->where('user_id', $request->user()->id)
            ->orderByDesc('joined_at')
            ->first();

        if (!$membership) {
            return $this->success([
                'is_member' => false,
                'membership' => null,
            ]);
        }

        // Compute days_until_due for UI countdown
        $daysUntilDue = null;
        if ($membership->next_payment_due) {
            $daysUntilDue = (int) now()->startOfDay()
                ->diffInDays($membership->next_payment_due, false);
        }

        return $this->success([
            'is_member' => true,
            'qualifies_for_member_pricing' => $membership->qualifiesForMemberPricing(),
            'days_until_due' => $daysUntilDue,
            'membership' => $membership,
        ]);
    }

    /** List all my payment history (paginated). */
    public function payments(Request $request)
    {
        $membership = ConsumerMembership::where('user_id', $request->user()->id)->first();
        if (!$membership) {
            return $this->success(['data' => [], 'total' => 0]);
        }

        $payments = $membership->payments()
            ->with('receiver:id,name')
            ->orderByDesc('payment_period_year')
            ->orderByDesc('payment_period_month')
            ->paginate(20);

        return $this->success($payments);
    }
}
