<?php

namespace App\Http\Controllers;

use App\Models\Package;
use App\Models\PackageItem;
use App\Models\StockItem;

class PackageStockController extends Controller
{
    /**
     * GET /packages/stock-check — List all packages with real-time stock availability.
     * Frontend uses this for package selection — out-of-stock critical items = disabled.
     */
    public function index()
    {
        $packages = Package::where('is_active', true)
            ->with('items')
            ->orderBy('base_price')
            ->get();

        $result = $packages->map(function ($package) {
            $items = PackageItem::where('package_id', $package->id)
                ->whereNotNull('stock_item_id')
                ->with('stockItem')
                ->get();

            $stockDetails = [];
            $hasCriticalOutOfStock = false;
            $hasPartialStock = false;

            foreach ($items as $item) {
                $stock = $item->stockItem;
                if (!$stock) continue;

                $needed = $item->deduct_quantity ?? $item->quantity ?? 1;
                $available = $stock->current_quantity;
                $sufficient = $available >= $needed;
                $isCritical = ($item->is_critical ?? true); // default critical

                if (!$sufficient) {
                    if ($isCritical) {
                        $hasCriticalOutOfStock = true;
                    } else {
                        $hasPartialStock = true;
                    }
                }

                $stockDetails[] = [
                    'item_name' => $stock->item_name,
                    'needed' => $needed,
                    'available' => $available,
                    'sufficient' => $sufficient,
                    'is_critical' => $isCritical,
                ];
            }

            $stockStatus = $hasCriticalOutOfStock ? 'unavailable'
                : ($hasPartialStock ? 'partial' : 'available');

            return [
                'id' => $package->id,
                'name' => $package->name,
                'description' => $package->description,
                'base_price' => $package->base_price,
                'stock_status' => $stockStatus,
                'can_select' => !$hasCriticalOutOfStock,
                'stock_details' => $stockDetails,
                'warning' => $hasPartialStock ? 'Beberapa item non-kritis stoknya terbatas' : null,
            ];
        });

        return $this->success($result);
    }
}
