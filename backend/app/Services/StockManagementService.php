<?php

namespace App\Services;

use App\Models\Order;
use App\Models\PackageItem;
use App\Models\StockItem;
use App\Models\StockAlert;
use App\Models\OrderStockDeduction;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class StockManagementService
{
    /**
     * Dipanggil saat SO konfirmasi order (PUT /so/orders/{id}/confirm).
     * Cek stok, deduct jika cukup, flag jika tidak cukup.
     */
    public function processOrderConfirmation(Order $order, string $userId): array
    {
        if (!$order->package_id) {
            return ['success' => true, 'needs_restock' => false, 'deductions' => []];
        }

        $packageItems = PackageItem::where('package_id', $order->package_id)
            ->whereNotNull('stock_item_id')
            ->with('stockItem')
            ->get();

        $insufficientItems = [];
        $deductions = [];

        DB::transaction(function () use ($packageItems, $order, $userId, &$insufficientItems, &$deductions) {
            foreach ($packageItems as $pkgItem) {
                $stockItem = $pkgItem->stockItem;
                if (!$stockItem) continue;

                $needed = $pkgItem->deduct_quantity ?? 1;
                $before = $stockItem->current_quantity;
                $isSufficient = $before >= $needed;

                if ($isSufficient) {
                    $stockItem->decrement('current_quantity', $needed);
                } else {
                    $insufficientItems[] = [
                        'item_name' => $stockItem->item_name,
                        'needed' => $needed,
                        'available' => $before,
                    ];
                }

                $deduction = OrderStockDeduction::create([
                    'order_id' => $order->id,
                    'stock_item_id' => $stockItem->id,
                    'package_item_id' => $pkgItem->id,
                    'deducted_quantity' => $isSufficient ? $needed : 0,
                    'stock_before' => $before,
                    'stock_after' => $isSufficient ? $before - $needed : $before,
                    'is_sufficient' => $isSufficient,
                    'deducted_by' => $userId,
                ]);

                $deductions[] = $deduction;

                // Create stock alert if below minimum
                $stockItem->refresh();
                if ($stockItem->current_quantity <= ($stockItem->minimum_quantity ?? 0)) {
                    $alertType = $stockItem->current_quantity <= 0 ? 'out_of_stock' : 'low_stock';
                    StockAlert::create([
                        'stock_item_id' => $stockItem->id,
                        'order_id' => $order->id,
                        'alert_type' => $alertType,
                        'current_quantity' => $stockItem->current_quantity,
                        'minimum_quantity' => $stockItem->minimum_quantity ?? 0,
                        'message' => "Stok {$stockItem->item_name} {$alertType}: sisa {$stockItem->current_quantity} (min: {$stockItem->minimum_quantity})",
                    ]);

                    // Notify Gudang + Purchasing
                    NotificationService::send('GUDANG', 'ALARM', 'Stok Kurang!',
                        "Stok {$stockItem->item_name} tinggal {$stockItem->current_quantity}. Segera restock!");
                    NotificationService::send('PURCHASING', 'NORMAL', 'Stok Kurang',
                        "Stok {$stockItem->item_name} perlu pengadaan.");
                }
            }
        });

        $needsRestock = !empty($insufficientItems);
        if ($needsRestock) {
            $order->update(['needs_restock' => true]);
            Log::warning("Order {$order->order_number}: insufficient stock for " . count($insufficientItems) . " items");
        }

        return [
            'success' => true,
            'needs_restock' => $needsRestock,
            'insufficient_items' => $insufficientItems,
            'deductions' => $deductions,
        ];
    }
}
