<?php

namespace App\Http\Controllers\Gudang;

use App\Http\Controllers\Controller;
use App\Models\Inventory; // Assuming this model exists
use Illuminate\Http\Request;

class StockController extends Controller
{
    public function index()
    {
        // Simple inventory fetch
        $items = \App\Models\StockItem::orderBy('item_name')->get();
        return response()->json(['success' => true, 'data' => $items]);
    }

    public function update(Request $request, $id)
    {
        $request->validate(['current_quantity' => 'required|integer']);
        $item = \App\Models\StockItem::findOrFail($id);
        $item->update([
            'current_quantity' => $request->current_quantity,
            'last_updated_by' => $request->user()->id
        ]);
        
        return response()->json(['success' => true, 'message' => 'Stock updated', 'data' => $item]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'item_name' => 'required|string|unique:stock_items,item_name',
            'category' => 'required|string',
            'current_quantity' => 'required|integer',
            'unit' => 'required|string',
            'minimum_quantity' => 'nullable|integer'
        ]);

        $item = \App\Models\StockItem::create(array_merge(
            $request->all(),
            ['last_updated_by' => $request->user()->id]
        ));
        return response()->json(['success' => true, 'data' => $item]);
    }
}
