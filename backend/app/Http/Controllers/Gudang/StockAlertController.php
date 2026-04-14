<?php

namespace App\Http\Controllers\Gudang;

use App\Http\Controllers\Controller;
use App\Models\StockAlert;
use Illuminate\Http\Request;

class StockAlertController extends Controller
{
    public function index(Request $request)
    {
        $query = StockAlert::with('stockItem')->orderBy('created_at', 'desc');

        if ($request->has('resolved')) {
            $query->where('is_resolved', $request->boolean('resolved'));
        }

        return response()->json(['success' => true, 'data' => $query->paginate(20)]);
    }

    public function resolve(Request $request, $id)
    {
        $alert = StockAlert::findOrFail($id);
        $alert->update([
            'is_resolved' => true,
            'resolved_by' => $request->user()->id,
            'resolved_at' => now(),
        ]);

        return response()->json(['success' => true, 'data' => $alert]);
    }
}
