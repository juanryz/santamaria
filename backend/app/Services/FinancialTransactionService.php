<?php
namespace App\Services;

use App\Models\FinancialTransaction;
use App\Models\FinancialReport;
use App\Models\Order;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class FinancialTransactionService
{
    public function record(array $data): FinancialTransaction
    {
        return FinancialTransaction::create([
            'transaction_type' => $data['transaction_type'],
            'reference_type'   => $data['reference_type'] ?? null,
            'reference_id'     => $data['reference_id'] ?? null,
            'order_id'         => $data['order_id'] ?? null,
            'amount'           => $data['amount'],
            'direction'        => $data['direction'],
            'currency'         => $data['currency'] ?? 'IDR',
            'category'         => $data['category'],
            'description'      => $data['description'] ?? null,
            'transaction_date' => $data['transaction_date'] ?? now()->toDateString(),
            'recorded_by'      => $data['recorded_by'] ?? null,
            'metadata'         => $data['metadata'] ?? [],
        ]);
    }

    public function voidTransaction(string $id, string $reason, User $by): void
    {
        $tx = FinancialTransaction::findOrFail($id);
        $tx->update([
            'is_void' => true,
            'voided_at' => now(),
            'voided_by' => $by->id,
            'void_reason' => $reason,
        ]);
    }

    public function generateMonthlySummary(int $year, int $month): array
    {
        $base = FinancialTransaction::active()->period($year, $month);

        $incomeTotal   = (clone $base)->income()->sum('amount');
        $expenseTotal  = (clone $base)->expense()->sum('amount');

        $incomeByCategory  = (clone $base)->income()
            ->select('category', DB::raw('SUM(amount) as total'))
            ->groupBy('category')
            ->pluck('total', 'category')
            ->toArray();

        $expenseByCategory = (clone $base)->expense()
            ->select('category', DB::raw('SUM(amount) as total'))
            ->groupBy('category')
            ->pluck('total', 'category')
            ->toArray();

        $orderCount = (clone $base)->income()
            ->whereNotNull('order_id')
            ->distinct('order_id')
            ->count('order_id');

        $avgOrderValue = $orderCount > 0 ? $incomeTotal / $orderCount : 0;

        $data = [
            'period'               => "$year-" . str_pad($month, 2, '0', STR_PAD_LEFT),
            'income_total'         => $incomeTotal,
            'expense_total'        => $expenseTotal,
            'profit'               => $incomeTotal - $expenseTotal,
            'income_by_category'   => $incomeByCategory,
            'expense_by_category'  => $expenseByCategory,
            'order_count'          => $orderCount,
            'avg_order_value'      => round($avgOrderValue, 2),
        ];

        FinancialReport::updateOrCreate(
            ['report_type' => 'monthly_summary', 'period_year' => $year, 'period_month' => $month],
            ['data' => $data, 'generated_at' => now()]
        );

        return $data;
    }

    public function generateAnnualSummary(int $year): array
    {
        $base = FinancialTransaction::active()->period($year);

        $incomeTotal  = (clone $base)->income()->sum('amount');
        $expenseTotal = (clone $base)->expense()->sum('amount');

        $monthlyBreakdown = [];
        for ($m = 1; $m <= 12; $m++) {
            $mBase = FinancialTransaction::active()->period($year, $m);
            $monthlyBreakdown[$m] = [
                'income'  => (clone $mBase)->income()->sum('amount'),
                'expense' => (clone $mBase)->expense()->sum('amount'),
            ];
        }

        $data = [
            'year'              => $year,
            'income_total'      => $incomeTotal,
            'expense_total'     => $expenseTotal,
            'profit'            => $incomeTotal - $expenseTotal,
            'monthly_breakdown' => $monthlyBreakdown,
        ];

        FinancialReport::updateOrCreate(
            ['report_type' => 'annual_summary', 'period_year' => $year, 'period_month' => null],
            ['data' => $data, 'generated_at' => now()]
        );

        return $data;
    }

    public function getDashboardData(): array
    {
        $now = now();
        $thisYear = $now->year;
        $thisMonth = $now->month;
        $lastMonth = $now->copy()->subMonth()->month;
        $lastMonthYear = $now->copy()->subMonth()->year;

        $thisMIncome  = FinancialTransaction::active()->period($thisYear, $thisMonth)->income()->sum('amount');
        $thisMExpense = FinancialTransaction::active()->period($thisYear, $thisMonth)->expense()->sum('amount');
        $lastMIncome  = FinancialTransaction::active()->period($lastMonthYear, $lastMonth)->income()->sum('amount');
        $lastMExpense = FinancialTransaction::active()->period($lastMonthYear, $lastMonth)->expense()->sum('amount');
        $thisYIncome  = FinancialTransaction::active()->period($thisYear)->income()->sum('amount');
        $thisYExpense = FinancialTransaction::active()->period($thisYear)->expense()->sum('amount');

        $thisMonthOrderCount = FinancialTransaction::active()
            ->period($thisYear, $thisMonth)->income()
            ->whereNotNull('order_id')->distinct('order_id')->count('order_id');

        // Pending payments — orders confirmed/processing without payment
        $pendingPayments = \App\Models\Order::whereIn('status', ['confirmed', 'processing', 'in_progress'])
            ->whereNull('paid_at')
            ->with('consumer:id,name,phone')
            ->select('id', 'order_code', 'consumer_id', 'total_amount', 'created_at')
            ->orderBy('created_at')
            ->limit(20)
            ->get()
            ->map(fn($o) => [
                'order_id'      => $o->id,
                'order_code'    => $o->order_code,
                'consumer_name' => $o->consumer?->name,
                'amount'        => $o->total_amount,
                'order_date'    => $o->created_at->toDateString(),
            ]);

        // Unpaid tukang jaga wages
        $unpaidWages = \App\Models\TukangJagaShift::where('status', 'completed')
            ->where('wage_paid', false)
            ->whereNotNull('wage_amount')
            ->with('assignedUser:id,name')
            ->select('id', 'assigned_to', 'wage_amount', 'checkout_at')
            ->limit(20)
            ->get()
            ->map(fn($s) => [
                'shift_id'          => $s->id,
                'tukang_jaga_name'  => $s->assignedUser?->name,
                'amount'            => $s->wage_amount,
                'checkout_at'       => $s->checkout_at,
            ]);

        return [
            'this_month' => [
                'income'       => $thisMIncome,
                'expense'      => $thisMExpense,
                'profit'       => $thisMIncome - $thisMExpense,
                'order_count'  => $thisMonthOrderCount,
            ],
            'last_month' => [
                'income'  => $lastMIncome,
                'expense' => $lastMExpense,
                'profit'  => $lastMIncome - $lastMExpense,
            ],
            'this_year' => [
                'income'  => $thisYIncome,
                'expense' => $thisYExpense,
                'profit'  => $thisYIncome - $thisYExpense,
            ],
            'pending_payments' => $pendingPayments,
            'unpaid_wages'     => $unpaidWages,
        ];
    }
}
