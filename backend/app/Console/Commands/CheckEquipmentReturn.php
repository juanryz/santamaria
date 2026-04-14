<?php

namespace App\Console\Commands;

use App\Enums\EquipmentItemStatus;
use App\Enums\NotificationPriority;
use App\Enums\OrderStatus;
use App\Enums\UserRole;
use App\Enums\ViolationType;
use App\Models\Order;
use App\Models\OrderEquipmentItem;
use App\Models\HrdViolation;
use App\Models\SystemThreshold;
use App\Services\NotificationService;
use Illuminate\Console\Command;

class CheckEquipmentReturn extends Command
{
    protected $signature   = 'equipment:check-return-deadline';
    protected $description = 'Alert Gudang if equipment not returned after order completion deadline.';

    public function handle(): void
    {
        $deadlineHours = SystemThreshold::getValue(ViolationType::EQUIPMENT_NOT_RETURNED->thresholdKey(), 24);

        $orders = Order::where('status', OrderStatus::COMPLETED->value)
            ->where('updated_at', '<=', now()->subHours($deadlineHours))
            ->pluck('id');

        $unreturnedStatuses = [
            EquipmentItemStatus::SENT->value,
            EquipmentItemStatus::RECEIVED->value,
            EquipmentItemStatus::PARTIAL_RETURN->value,
        ];

        $unreturned = OrderEquipmentItem::whereIn('order_id', $orders)
            ->whereIn('status', $unreturnedStatuses)
            ->with(['order', 'equipmentMaster'])
            ->get();

        foreach ($unreturned as $item) {
            $exists = HrdViolation::where('violation_type', ViolationType::EQUIPMENT_NOT_RETURNED->value)
                ->where('related_order_id', $item->order_id)
                ->whereDate('created_at', today())
                ->exists();

            if ($exists) continue;

            HrdViolation::create([
                'violation_type' => ViolationType::EQUIPMENT_NOT_RETURNED->value,
                'related_order_id' => $item->order_id,
                'description' => "Peralatan '{$item->item_description}' belum dikembalikan setelah {$deadlineHours} jam (Order {$item->order->order_number})",
                'severity' => ViolationType::EQUIPMENT_NOT_RETURNED->severity(),
            ]);

            NotificationService::send(UserRole::GUDANG->value, NotificationPriority::ALARM->value, 'Peralatan Belum Kembali!',
                "'{$item->item_description}' dari order {$item->order->order_number} belum dikembalikan");
        }

        $this->info("Equipment return check done. Found {$unreturned->count()} unreturned items.");
    }
}
