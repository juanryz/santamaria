<?php
namespace App\Http\Controllers\Finance;

use App\Http\Controllers\Controller;
use App\Models\FinancialReport;
use App\Models\FinancialTransaction;
use App\Models\Order;
use App\Services\FinancialTransactionService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FinanceReportController extends Controller
{
    public function __construct(private FinancialTransactionService $service) {}

    public function summary(Request $request)
    {
        $year  = (int) ($request->year ?? now()->year);
        $month = $request->month ? (int) $request->month : null;

        if ($month) {
            $data = $this->service->generateMonthlySummary($year, $month);
        } else {
            $data = $this->service->generateAnnualSummary($year);
        }

        return response()->json(['success' => true, 'data' => $data]);
    }

    public function orders(Request $request)
    {
        $request->validate([
            'from'   => 'nullable|date',
            'to'     => 'nullable|date',
            'status' => 'nullable|string',
        ]);

        $query = Order::query()
            ->with(['consumer:id,name,phone', 'serviceOfficer:id,name', 'package:id,name'])
            ->select('id', 'order_code', 'consumer_id', 'service_officer_id', 'package_id',
                     'deceased_name', 'total_amount', 'payment_method', 'paid_at', 'status', 'created_at');

        if ($request->from) $query->whereDate('created_at', '>=', $request->from);
        if ($request->to)   $query->whereDate('created_at', '<=', $request->to);
        if ($request->status) {
            if ($request->status === 'paid') $query->whereNotNull('paid_at');
            else $query->where('status', $request->status);
        }

        $orders = $query->orderBy('created_at', 'desc')->paginate(30);

        $orders->getCollection()->transform(function ($order) {
            $expenses = FinancialTransaction::active()
                ->where('order_id', $order->id)
                ->expense()
                ->sum('amount');
            $order->expense_total = $expenses;
            $order->profit = ($order->total_amount ?? 0) - $expenses;
            return $order;
        });

        return response()->json(['success' => true, 'data' => $orders]);
    }

    public function receivables()
    {
        $orders = Order::whereIn('status', ['confirmed', 'processing', 'in_progress'])
            ->whereNull('paid_at')
            ->with('consumer:id,name,phone')
            ->select('id', 'order_code', 'consumer_id', 'total_amount', 'payment_method', 'created_at')
            ->orderBy('created_at')
            ->get()
            ->map(fn($o) => [
                'order_id'         => $o->id,
                'order_code'       => $o->order_code,
                'consumer_name'    => $o->consumer?->name,
                'consumer_phone'   => $o->consumer?->phone,
                'total_amount'     => $o->total_amount,
                'payment_method'   => $o->payment_method,
                'order_date'       => $o->created_at->toDateString(),
                'days_outstanding' => $o->created_at->diffInDays(now()),
            ]);

        return response()->json(['success' => true, 'data' => $orders]);
    }

    public function expenses(Request $request)
    {
        $query = FinancialTransaction::active()->expense();

        if ($request->from)     $query->whereDate('transaction_date', '>=', $request->from);
        if ($request->to)       $query->whereDate('transaction_date', '<=', $request->to);
        if ($request->category) $query->where('category', $request->category);

        $data = $query->orderBy('transaction_date', 'desc')
            ->select('id', 'transaction_date', 'transaction_type', 'category', 'description', 'amount', 'reference_type', 'reference_id')
            ->paginate(30);

        return response()->json(['success' => true, 'data' => $data]);
    }

    public function export(Request $request)
    {
        $request->validate([
            'type'   => 'required|in:monthly_summary,order_list,transactions',
            'format' => 'required|in:pdf,xlsx',
            'year'   => 'nullable|integer',
            'month'  => 'nullable|integer',
            'from'   => 'nullable|date',
            'to'     => 'nullable|date',
        ]);

        $type   = $request->type;
        $format = $request->format;

        if ($format === 'pdf') {
            $view = match ($type) {
                'monthly_summary' => 'reports.monthly_summary',
                'order_list'      => 'reports.order_list',
                default           => 'reports.transactions',
            };

            $data = match ($type) {
                'monthly_summary' => $this->service->generateMonthlySummary(
                    (int) ($request->year ?? now()->year),
                    (int) ($request->month ?? now()->month)
                ),
                'order_list' => Order::query()
                    ->with(['consumer:id,name', 'package:id,name'])
                    ->when($request->from, fn($q) => $q->whereDate('created_at', '>=', $request->from))
                    ->when($request->to,   fn($q) => $q->whereDate('created_at', '<=', $request->to))
                    ->orderBy('created_at', 'desc')->limit(500)->get()->toArray(),
                default => FinancialTransaction::active()
                    ->when($request->from, fn($q) => $q->whereDate('transaction_date', '>=', $request->from))
                    ->when($request->to,   fn($q) => $q->whereDate('transaction_date', '<=', $request->to))
                    ->orderBy('transaction_date', 'desc')->limit(500)->get()->toArray(),
            };

            $pdf = \Barryvdh\DomPDF\Facade\Pdf::loadView($view, ['data' => $data, 'generated_at' => now()]);
            return $pdf->download("laporan_{$type}_" . now()->format('Ymd') . '.pdf');
        }

        // xlsx via maatwebsite/excel — return JSON if package not installed
        if (!class_exists(\Maatwebsite\Excel\Facades\Excel::class)) {
            return response()->json(['success' => false, 'message' => 'Excel export requires maatwebsite/excel package.'], 422);
        }

        $exportClass = match ($type) {
            'order_list'   => new \App\Exports\OrderReportExport($request->from, $request->to),
            default        => new \App\Exports\TransactionExport($request->from, $request->to, $request->category ?? null),
        };

        return \Maatwebsite\Excel\Facades\Excel::download($exportClass, "laporan_{$type}_" . now()->format('Ymd') . '.xlsx');
    }
}
