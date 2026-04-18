<?php

namespace App\Http\Controllers\Purchasing;

use App\Http\Controllers\Controller;
use App\Models\PhotographerDailyWage;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * v1.40 — Upah Tukang Foto Harian.
 *
 * Rule:
 * - Tukang foto dibayar PER HARI (bukan per order).
 * - 1 hari bisa cover multiple order (session_count).
 * - Nominal daily_rate + bonus extra session dikonfigurasi Admin.
 */
class PhotographerWageController extends Controller
{
    /**
     * List semua daily wages — review Purchasing.
     */
    public function index(Request $request)
    {
        $query = PhotographerDailyWage::with([
            'photographer:id,name,phone',
            'paidByUser:id,name',
        ])->orderByDesc('work_date');

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }
        if ($request->filled('photographer_id')) {
            $query->where('photographer_user_id', $request->photographer_id);
        }
        if ($request->filled('from')) {
            $query->where('work_date', '>=', $request->from);
        }
        if ($request->filled('to')) {
            $query->where('work_date', '<=', $request->to);
        }

        return response()->json([
            'success' => true,
            'data' => $query->paginate($request->per_page ?? 50),
        ]);
    }

    /**
     * Detail 1 daily wage.
     */
    public function show(string $id)
    {
        $wage = PhotographerDailyWage::with([
            'photographer:id,name,phone',
            'paidByUser:id,name',
        ])->findOrFail($id);

        return response()->json(['success' => true, 'data' => $wage]);
    }

    /**
     * Admin finalize daily wage sebelum bayar.
     * Hanya status='draft' yang bisa difinalize.
     */
    public function finalize(Request $request, string $id)
    {
        $wage = PhotographerDailyWage::findOrFail($id);

        if ($wage->status !== 'draft') {
            return response()->json([
                'success' => false,
                'message' => "Hanya wage status 'draft' yang bisa di-finalize.",
            ], 422);
        }

        $wage->update([
            'status' => 'finalized',
            'finalized_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'data' => $wage->fresh(),
            'message' => 'Wage difinalize. Siap untuk dibayar.',
        ]);
    }

    /**
     * Mark as paid (Purchasing).
     */
    public function pay(Request $request, string $id)
    {
        $request->validate([
            'payment_receipt_path' => 'nullable|string',
            'notes' => 'nullable|string',
        ]);

        $wage = PhotographerDailyWage::findOrFail($id);

        if ($wage->status !== 'finalized') {
            return response()->json([
                'success' => false,
                'message' => "Hanya wage status 'finalized' yang bisa dibayar.",
            ], 422);
        }

        $wage->update([
            'status' => 'paid',
            'paid_at' => now(),
            'paid_by' => $request->user()->id,
            'payment_receipt_path' => $request->payment_receipt_path,
            'notes' => $request->notes,
        ]);

        return response()->json([
            'success' => true,
            'data' => $wage->fresh(),
            'message' => 'Pembayaran tercatat.',
        ]);
    }

    /**
     * Ringkasan pending payments — untuk dashboard.
     */
    public function pendingSummary()
    {
        $summary = DB::table('photographer_daily_wages')
            ->select(
                DB::raw("SUM(CASE WHEN status='draft' THEN 1 ELSE 0 END) as draft_count"),
                DB::raw("SUM(CASE WHEN status='finalized' THEN 1 ELSE 0 END) as finalized_count"),
                DB::raw("SUM(CASE WHEN status='finalized' THEN total_wage ELSE 0 END) as total_to_pay"),
            )->first();

        return response()->json(['success' => true, 'data' => $summary]);
    }

    /**
     * List wages yang siap dibayar (status=finalized).
     * Dipakai Flutter approval screen.
     */
    public function pending(Request $request)
    {
        $wages = PhotographerDailyWage::with([
            'photographer:id,name,phone',
        ])->where('status', 'finalized')
            ->orderBy('work_date', 'asc')
            ->get();

        return response()->json(['success' => true, 'data' => $wages]);
    }
}
