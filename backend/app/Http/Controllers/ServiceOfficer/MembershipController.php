<?php

namespace App\Http\Controllers\ServiceOfficer;

use App\Http\Controllers\Controller;
use App\Models\ConsumerMembership;
use App\Models\SystemThreshold;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * v1.39 — SO register & manage consumer memberships.
 * Subscription bulanan — anggota dapat harga paket lebih murah.
 */
class MembershipController extends Controller
{
    /** List all memberships (paginated, filter by status + search nama). */
    public function index(Request $request)
    {
        $q = ConsumerMembership::with('user:id,name,phone');

        if ($request->filled('status')) {
            $q->where('status', $request->status);
        }
        if ($request->filled('search')) {
            $search = $request->search;
            $q->where(function ($w) use ($search) {
                $w->where('membership_number', 'like', "%{$search}%")
                  ->orWhereHas('user', fn($u) =>
                      $u->where('name', 'like', "%{$search}%")
                        ->orWhere('phone', 'like', "%{$search}%"));
            });
        }

        return $this->success(
            $q->orderByDesc('joined_at')->paginate(30)
        );
    }

    /** Register a new consumer as member. */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'user_id' => 'required|uuid|exists:users,id',
            'monthly_fee' => 'nullable|numeric|min:0',
            'joined_at' => 'nullable|date',
            'notes' => 'nullable|string|max:500',
        ]);

        // Pastikan user adalah consumer
        $user = User::findOrFail($validated['user_id']);
        if ($user->role !== 'consumer') {
            return $this->error('Hanya role consumer yang bisa didaftarkan sebagai anggota.', 422);
        }

        // Cek existing active membership
        $existing = ConsumerMembership::where('user_id', $user->id)
            ->whereIn('status', ['active', 'grace_period'])
            ->first();
        if ($existing) {
            return $this->error(
                'Consumer sudah punya membership aktif ' . $existing->membership_number,
                409
            );
        }

        $joinedAt = $validated['joined_at'] ?? now()->toDateString();
        $nextDue = \Carbon\Carbon::parse($joinedAt)->addMonth();
        $defaultFee = (float) SystemThreshold::getValue('membership_default_monthly_fee', 0);

        $membership = ConsumerMembership::create([
            'user_id' => $user->id,
            'membership_number' => ConsumerMembership::generateNumber(),
            'joined_at' => $joinedAt,
            'status' => 'active',
            'monthly_fee' => $validated['monthly_fee'] ?? $defaultFee,
            'next_payment_due' => $nextDue->toDateString(),
            'notes' => $validated['notes'] ?? null,
        ]);

        return $this->created($membership->load('user:id,name,phone'));
    }

    /** Show detail + payment history. */
    public function show(string $id)
    {
        $membership = ConsumerMembership::with([
            'user:id,name,phone',
            'payments' => fn($q) => $q->orderByDesc('payment_period_year')
                ->orderByDesc('payment_period_month'),
            'payments.receiver:id,name',
        ])->findOrFail($id);

        return $this->success($membership);
    }

    /** Update (monthly_fee, notes, status — manual override). */
    public function update(Request $request, string $id)
    {
        $validated = $request->validate([
            'monthly_fee' => 'sometimes|numeric|min:0',
            'status' => 'sometimes|string|in:active,grace_period,inactive,cancelled,suspended',
            'notes' => 'nullable|string|max:500',
        ]);

        $membership = ConsumerMembership::findOrFail($id);
        $membership->update($validated);

        return $this->success($membership->fresh());
    }

    /** Cancel membership (keep history, status → cancelled). */
    public function cancel(Request $request, string $id)
    {
        $validated = $request->validate([
            'reason' => 'required|string|max:500',
        ]);

        $membership = ConsumerMembership::findOrFail($id);
        $membership->update([
            'status' => 'cancelled',
            'cancelled_at' => now(),
            'cancellation_reason' => $validated['reason'],
        ]);

        return $this->success($membership->fresh(), 'Membership dibatalkan.');
    }

    /** Cek apakah consumer (by user_id) punya membership aktif. Dipakai di SO order form. */
    public function checkByUser(Request $request)
    {
        $validated = $request->validate([
            'user_id' => 'nullable|uuid',
            'phone' => 'nullable|string',
        ]);

        $q = ConsumerMembership::with('user:id,name,phone')
            ->whereIn('status', ['active', 'grace_period']);

        if (!empty($validated['user_id'])) {
            $q->where('user_id', $validated['user_id']);
        } elseif (!empty($validated['phone'])) {
            $q->whereHas('user', fn($u) => $u->where('phone', $validated['phone']));
        } else {
            return $this->error('Masukkan user_id atau phone', 422);
        }

        $membership = $q->first();
        return $this->success([
            'is_member' => $membership !== null,
            'membership' => $membership,
        ]);
    }
}
