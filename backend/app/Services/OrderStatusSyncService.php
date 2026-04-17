<?php

namespace App\Services;

use App\Models\Order;
use App\Models\OrderStatusLog;
use App\Models\OrderStatusLabel;
use Illuminate\Support\Facades\Log;

/**
 * Syncs order status from driver trip-leg updates.
 *
 * Called after OrderStateMachine::transition() to send consumer-facing
 * notifications using order_status_labels for the label text.
 */
class OrderStatusSyncService
{
    /**
     * Send a consumer-facing notification for the new order status,
     * using the label from order_status_labels if available.
     */
    public static function notifyConsumerOfStatus(Order $order, string $newStatus): void
    {
        if (!$order->pic_user_id) {
            return;
        }

        $label = null;
        $description = null;

        // Try to fetch from order_status_labels table
        try {
            $statusLabel = OrderStatusLabel::where('status_code', $newStatus)->first();
            if ($statusLabel) {
                if (!$statusLabel->show_to_consumer) {
                    return; // This status should not be shown to consumer
                }
                $label = $statusLabel->consumer_label;
                $description = $statusLabel->consumer_description;

                // Replace placeholders if we have data
                if ($description && $order->driver) {
                    $description = str_replace(
                        ['{driver_name}', '{plate_number}'],
                        [$order->driver->name ?? '', $order->vehicle->plate_number ?? ''],
                        $description
                    );
                }
            }
        } catch (\Throwable $e) {
            // Table may not exist yet; fall back to defaults
            Log::debug("OrderStatusSyncService: order_status_labels lookup failed: {$e->getMessage()}");
        }

        $label = $label ?: 'Update Layanan';
        $description = $description ?: 'Status layanan Anda telah diperbarui.';

        NotificationService::send(
            $order->pic_user_id,
            'HIGH',
            $label,
            $description
        );
    }

    /**
     * Determine the expected order status based on a trip leg code and leg status.
     * Returns null if no mapping applies (order status should not change).
     *
     * This is a reference/utility method. The actual driver controller already
     * uses OrderStateMachine::transition() directly with the correct target status.
     * Use this to derive the target when only leg metadata is available.
     */
    public static function deriveOrderStatus(string $legCode, string $legStatus): ?string
    {
        $code = strtolower($legCode);
        $status = strtolower($legStatus);

        return match (true) {
            // Assigned
            $status === 'assigned' => 'driver_assigned',

            // Departed with goods/logistics
            $status === 'departed' && (str_contains($code, 'barang') || str_contains($code, 'logistics') || str_contains($code, 'peralatan'))
                => 'delivering_equipment',

            // Equipment arrived
            ($status === 'arrived' || $status === 'completed') && (str_contains($code, 'barang') || str_contains($code, 'logistics'))
                => 'equipment_arrived',

            // Picking up body
            $status === 'departed' && (str_contains($code, 'jenazah') || str_contains($code, 'hearse') || str_contains($code, 'jemput'))
                => 'picking_up_body',

            // Body arrived
            ($status === 'arrived' || $status === 'completed') && (str_contains($code, 'jenazah') || str_contains($code, 'hearse'))
                => 'body_arrived',

            // Heading to burial/cremation
            $status === 'departed' && (str_contains($code, 'makam') || str_contains($code, 'kremasi') || str_contains($code, 'burial'))
                => 'heading_to_burial',

            // Burial completed
            $status === 'completed' && (str_contains($code, 'makam') || str_contains($code, 'kremasi') || str_contains($code, 'burial'))
                => 'burial_completed',

            // Returning equipment
            $status === 'departed' && (str_contains($code, 'kembali') || str_contains($code, 'return'))
                => 'returning_equipment',

            default => null,
        };
    }
}
