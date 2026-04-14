<?php

namespace App\Http\Controllers\ServiceOfficer;

use App\Http\Controllers\Controller;
use App\Models\Package;
use App\Models\PackageItem;
use App\Models\StockItem;
use Illuminate\Http\Request;

class StockCheckController extends Controller
{
    /**
     * GET /so/orders/{id}/stock-check
     * Preview stock availability BEFORE confirming order. No deduction.
     */
    public function preview(Request $request, $orderId)
    {
        $request->validate(['package_id' => 'required|uuid|exists:packages,id']);

        $packageItems = PackageItem::where('package_id', $request->package_id)
            ->whereNotNull('stock_item_id')
            ->with('stockItem')
            ->get();

        $items = [];
        $allSufficient = true;

        foreach ($packageItems as $pkgItem) {
            $stockItem = $pkgItem->stockItem;
            if (!$stockItem) continue;

            $needed = $pkgItem->deduct_quantity ?? $pkgItem->quantity ?? 1;
            $available = $stockItem->current_quantity;
            $sufficient = $available >= $needed;

            if (!$sufficient) $allSufficient = false;

            $items[] = [
                'item_name' => $stockItem->item_name,
                'category' => $stockItem->category,
                'needed' => $needed,
                'available' => $available,
                'minimum' => $stockItem->minimum_quantity,
                'unit' => $stockItem->unit,
                'sufficient' => $sufficient,
                'after_deduct' => max(0, $available - $needed),
            ];
        }

        return response()->json([
            'success' => true,
            'data' => [
                'items' => $items,
                'all_sufficient' => $allSufficient,
                'total_items' => count($items),
                'insufficient_count' => collect($items)->where('sufficient', false)->count(),
            ],
        ]);
    }
}
