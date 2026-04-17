<?php

namespace App\Console\Commands;

use App\Models\ItemLocationTracking;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;

class DetectStuckItems extends Command
{
    protected $signature = 'items:detect-stuck';
    protected $description = 'Detect items stuck at a location for over 24 hours';

    public function handle(): int
    {
        $stuckItems = ItemLocationTracking::query()
            ->whereNotIn('status', ['returned', 'at_origin', 'lost'])
            ->whereColumn('current_location_type', '!=', 'origin_type')
            ->where('updated_at', '<', now()->subHours(24))
            ->get();

        $count = 0;

        foreach ($stuckItems as $item) {
            $updates = ['is_stuck' => true];

            if (!$item->stuck_since) {
                $updates['stuck_since'] = now();
            }

            $updates['ai_suggestion'] = "Item '{$item->item_description}' stuck at {$item->current_location_label} "
                . "since " . ($item->stuck_since ?? now())->format('d/m/Y H:i')
                . ". Consider retrieving or updating status.";

            $item->update($updates);

            if (!$item->stuck_alert_sent) {
                Log::warning('Stuck item detected', [
                    'tracking_id' => $item->id,
                    'order_id' => $item->order_id,
                    'item' => $item->item_description,
                    'location' => $item->current_location_label,
                    'stuck_since' => $item->stuck_since,
                ]);
                $item->update(['stuck_alert_sent' => true]);
                $count++;
            }
        }

        $this->info("Detected {$stuckItems->count()} stuck items, {$count} new alerts sent.");

        return self::SUCCESS;
    }
}
