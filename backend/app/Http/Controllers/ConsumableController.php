<?php

namespace App\Http\Controllers;

use App\Models\OrderConsumablesDaily;
use App\Models\OrderConsumableLine;
use App\Models\ConsumableMaster;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ConsumableController extends Controller
{
    public function index($orderId)
    {
        $entries = OrderConsumablesDaily::where('order_id', $orderId)
            ->with('lines.master')
            ->orderBy('consumable_date')
            ->orderByRaw("CASE shift WHEN 'pagi' THEN 1 WHEN 'kirim' THEN 2 WHEN 'malam' THEN 3 END")
            ->get();

        return response()->json(['success' => true, 'data' => $entries]);
    }

    public function store(Request $request, $orderId)
    {
        $request->validate([
            'consumable_date' => 'required|date',
            'shift' => 'required|in:pagi,kirim,malam',
            'is_retur' => 'boolean',
            'lines' => 'required|array',
            'lines.*.consumable_master_id' => 'required|uuid|exists:consumable_master,id',
            'lines.*.qty' => 'required|integer|min:0',
        ]);

        return DB::transaction(function () use ($request, $orderId) {
            $daily = OrderConsumablesDaily::create([
                'order_id' => $orderId,
                'consumable_date' => $request->consumable_date,
                'shift' => $request->shift,
                'is_retur' => $request->input('is_retur', false),
                'input_by' => $request->user()->id,
                'tukang_jaga_1_name' => $request->input('tukang_jaga_1_name'),
                'tukang_jaga_2_name' => $request->input('tukang_jaga_2_name'),
                'notes' => $request->input('notes'),
            ]);

            foreach ($request->lines as $line) {
                OrderConsumableLine::create([
                    'consumable_daily_id' => $daily->id,
                    'consumable_master_id' => $line['consumable_master_id'],
                    'qty' => $line['qty'],
                    'notes' => $line['notes'] ?? null,
                ]);
            }

            return response()->json(['success' => true, 'data' => $daily->load('lines.master')], 201);
        });
    }

    public function update(Request $request, $orderId, $id)
    {
        $daily = OrderConsumablesDaily::where('order_id', $orderId)->findOrFail($id);

        return DB::transaction(function () use ($request, $daily) {
            $daily->update($request->only(['notes', 'tukang_jaga_1_name', 'tukang_jaga_2_name']));

            if ($request->has('lines')) {
                $daily->lines()->delete();
                foreach ($request->lines as $line) {
                    OrderConsumableLine::create([
                        'consumable_daily_id' => $daily->id,
                        'consumable_master_id' => $line['consumable_master_id'],
                        'qty' => $line['qty'],
                        'notes' => $line['notes'] ?? null,
                    ]);
                }
            }

            return response()->json(['success' => true, 'data' => $daily->load('lines.master')]);
        });
    }
}
