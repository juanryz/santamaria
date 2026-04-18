<?php

namespace App\Services;

use App\Enums\UserRole;
use App\Models\Order;
use App\Models\FieldAttendance;
use App\Models\OrderEquipmentItem;
use App\Models\OrderBillingItem;
use App\Models\EquipmentMaster;
use App\Models\BillingItemMaster;
use App\Models\PackageItem;
use App\Models\AddOnService;
use App\Models\OrderAddOn;
use Illuminate\Support\Facades\Log;

class OrderAutoGenerateService
{
    /**
     * Dipanggil setelah SO konfirmasi order.
     * Auto-generate: field_attendances, order_equipment_items, order_billing_items.
     */
    public function onOrderConfirmed(Order $order): void
    {
        $this->generateAttendances($order);
        $this->generateEquipmentItems($order);
        $this->generateBillingItems($order);
        $this->generateTukangJagaShifts($order);
    }

    /**
     * v1.40: Auto-generate tukang jaga shifts
     * (2 shift/hari × service_duration_days).
     */
    private function generateTukangJagaShifts(Order $order): void
    {
        try {
            (new TukangJagaShiftGenerator())->generate($order);
        } catch (\Throwable $e) {
            Log::error('Failed to generate tukang jaga shifts', [
                'order_id' => $order->id,
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Auto-generate field_attendances untuk vendor yang di-assign.
     */
    private function generateAttendances(Order $order): void
    {
        $scheduledDate = $order->scheduled_at ? $order->scheduled_at->toDateString() : now()->toDateString();

        $assignments = [
            ['user_id' => $order->dekor_user_id, 'role' => UserRole::DEKOR->value],
            ['user_id' => $order->konsumsi_user_id, 'role' => UserRole::KONSUMSI->value],
            ['user_id' => $order->pemuka_agama_id, 'role' => UserRole::PEMUKA_AGAMA->value],
            ['user_id' => $order->tukang_foto_id, 'role' => UserRole::TUKANG_FOTO->value],
        ];

        foreach ($assignments as $a) {
            if (!$a['user_id']) continue;

            FieldAttendance::firstOrCreate([
                'order_id' => $order->id,
                'user_id' => $a['user_id'],
                'attendance_date' => $scheduledDate,
            ], [
                'role' => $a['role'],
                'kegiatan' => "Order {$order->order_number}",
                'status' => 'scheduled',
            ]);
        }
    }

    /**
     * Auto-generate order_equipment_items dari equipment_master sesuai paket.
     */
    private function generateEquipmentItems(Order $order): void
    {
        if (OrderEquipmentItem::where('order_id', $order->id)->exists()) return;

        // Generate default equipment set
        $defaultItems = EquipmentMaster::where('is_active', true)->get();

        foreach ($defaultItems as $master) {
            OrderEquipmentItem::create([
                'order_id' => $order->id,
                'equipment_item_id' => $master->id,
                'category' => $master->category,
                'item_code' => $master->item_code,
                'item_description' => $master->item_name,
                'qty_sent' => $master->default_qty,
                'status' => 'prepared',
            ]);
        }
    }

    /**
     * Auto-generate order_billing_items dari package + addons.
     */
    private function generateBillingItems(Order $order): void
    {
        if (OrderBillingItem::where('order_id', $order->id)->exists()) return;

        // From package items
        if ($order->package_id) {
            $packageItems = PackageItem::where('package_id', $order->package_id)->get();
            foreach ($packageItems as $pkgItem) {
                $billingMaster = BillingItemMaster::where('item_code', $pkgItem->item_code)->first();
                if (!$billingMaster) continue;

                OrderBillingItem::create([
                    'order_id' => $order->id,
                    'billing_master_id' => $billingMaster->id,
                    'qty' => $pkgItem->quantity ?? 1,
                    'unit' => $billingMaster->default_unit,
                    'unit_price' => $billingMaster->default_unit_price,
                    'total_price' => ($pkgItem->quantity ?? 1) * $billingMaster->default_unit_price,
                    'source' => 'package',
                ]);
            }
        }

        // From add-ons
        $addons = OrderAddOn::where('order_id', $order->id)->with('addOnService')->get();
        foreach ($addons as $addon) {
            if (!$addon->addOnService) continue;

            $billingMaster = BillingItemMaster::where('item_name', 'LIKE', '%' . $addon->addOnService->name . '%')->first();
            if (!$billingMaster) continue;

            OrderBillingItem::create([
                'order_id' => $order->id,
                'billing_master_id' => $billingMaster->id,
                'qty' => $addon->quantity ?? 1,
                'unit' => $billingMaster->default_unit,
                'unit_price' => $addon->price ?? $billingMaster->default_unit_price,
                'total_price' => ($addon->quantity ?? 1) * ($addon->price ?? $billingMaster->default_unit_price),
                'source' => 'addon',
            ]);
        }
    }
}
