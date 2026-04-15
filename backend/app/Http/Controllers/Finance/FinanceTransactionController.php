<?php
namespace App\Http\Controllers\Finance;

use App\Http\Controllers\Controller;
use App\Models\FinancialTransaction;
use App\Services\FinancialTransactionService;
use Illuminate\Http\Request;

class FinanceTransactionController extends Controller
{
    public function __construct(private FinancialTransactionService $service) {}

    public function index(Request $request)
    {
        $query = FinancialTransaction::with(['recordedBy:id,name', 'order:id,order_code,deceased_name']);

        if ($request->from)      $query->whereDate('transaction_date', '>=', $request->from);
        if ($request->to)        $query->whereDate('transaction_date', '<=', $request->to);
        if ($request->type)      $query->where('transaction_type', $request->type);
        if ($request->category)  $query->where('category', $request->category);
        if ($request->direction) $query->where('direction', $request->direction);
        if ($request->search)    $query->where('description', 'ilike', '%' . $request->search . '%');

        $data = $query->orderBy('transaction_date', 'desc')->paginate(30);
        return response()->json(['success' => true, 'data' => $data]);
    }

    public function correction(Request $request)
    {
        $request->validate([
            'direction'               => 'required|in:in,out',
            'amount'                  => 'required|numeric|min:0.01',
            'category'                => 'required|string|max:100',
            'description'             => 'required|string|max:500',
            'transaction_date'        => 'required|date',
            'correction_reason'       => 'required|string|max:500',
            'original_transaction_id' => 'nullable|exists:financial_transactions,id',
            'order_id'                => 'nullable|exists:orders,id',
        ]);

        $tx = $this->service->record([
            'transaction_type'        => 'manual_correction',
            'direction'               => $request->direction,
            'amount'                  => $request->amount,
            'category'                => $request->category,
            'description'             => $request->description,
            'transaction_date'        => $request->transaction_date,
            'recorded_by'             => $request->user()->id,
            'is_correction'           => true,
            'original_transaction_id' => $request->original_transaction_id,
            'correction_reason'       => $request->correction_reason,
            'corrected_at'            => now(),
            'corrected_by'            => $request->user()->id,
            'order_id'                => $request->order_id,
        ]);

        // patch is_correction directly since record() uses standard fillable
        $tx->update([
            'is_correction'           => true,
            'original_transaction_id' => $request->original_transaction_id,
            'correction_reason'       => $request->correction_reason,
            'corrected_at'            => now(),
            'corrected_by'            => $request->user()->id,
        ]);

        return response()->json(['success' => true, 'data' => $tx, 'message' => 'Koreksi berhasil dicatat.'], 201);
    }

    public function void(Request $request, string $id)
    {
        $request->validate(['void_reason' => 'required|string|max:500']);
        $this->service->voidTransaction($id, $request->void_reason, $request->user());
        return response()->json(['success' => true, 'message' => 'Transaksi berhasil dibatalkan.']);
    }
}
