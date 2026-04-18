<?php

namespace App\Http\Controllers\Purchasing;

use App\Http\Controllers\Controller;
use App\Models\PettyCashTransaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * v1.39 — Petty cash (kas kecil kantor) tracking.
 * In / out + running balance + foto bukti.
 */
class PettyCashController extends Controller
{
    /** List transaksi + saldo saat ini. */
    public function index(Request $request)
    {
        $q = PettyCashTransaction::with('performer:id,name');

        if ($request->filled('direction')) {
            $q->where('direction', $request->direction);
        }
        if ($request->filled('category')) {
            $q->where('category', $request->category);
        }
        if ($request->filled('from')) {
            $q->whereDate('created_at', '>=', $request->from);
        }
        if ($request->filled('to')) {
            $q->whereDate('created_at', '<=', $request->to);
        }

        return $this->success([
            'current_balance' => PettyCashTransaction::currentBalance(),
            'transactions' => $q->orderByDesc('created_at')->paginate(50),
        ]);
    }

    /** Current balance shortcut. */
    public function balance()
    {
        return $this->success([
            'balance' => PettyCashTransaction::currentBalance(),
        ]);
    }

    /** Record cash in/out. Balance_after dihitung otomatis. */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'amount' => 'required|numeric|min:0.01',
            'direction' => 'required|string|in:in,out',
            'category' => 'nullable|string|max:100',
            'description' => 'required|string|max:500',
            'reference_type' => 'nullable|string|max:50',
            'reference_id' => 'nullable|uuid',
            'receipt_photo_path' => 'nullable|string|max:500',
        ]);

        $transaction = DB::transaction(function () use ($validated, $request) {
            $current = PettyCashTransaction::currentBalance();
            $amount = (float) $validated['amount'];
            $balanceAfter = $validated['direction'] === 'in'
                ? $current + $amount
                : $current - $amount;

            if ($balanceAfter < 0) {
                abort(422, 'Saldo kas tidak mencukupi. Saldo saat ini: Rp ' .
                    number_format($current, 0, ',', '.'));
            }

            return PettyCashTransaction::create(array_merge($validated, [
                'performed_by' => $request->user()->id,
                'balance_after' => $balanceAfter,
            ]));
        });

        return $this->created($transaction->load('performer:id,name'));
    }

    /** Summary: in/out/net per month. */
    public function summary(Request $request)
    {
        $year = $request->input('year', now()->year);
        $month = $request->input('month', now()->month);

        $txns = PettyCashTransaction::whereYear('created_at', $year)
            ->whereMonth('created_at', $month)
            ->get();

        $in = $txns->where('direction', 'in')->sum('amount');
        $out = $txns->where('direction', 'out')->sum('amount');

        return $this->success([
            'period' => "{$year}-" . str_pad($month, 2, '0', STR_PAD_LEFT),
            'total_in' => (float) $in,
            'total_out' => (float) $out,
            'net' => (float) $in - (float) $out,
            'current_balance' => PettyCashTransaction::currentBalance(),
            'transaction_count' => $txns->count(),
        ]);
    }
}
