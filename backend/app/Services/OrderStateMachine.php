<?php

namespace App\Services;

use App\Enums\OrderStatus;
use App\Models\Order;
use App\Models\OrderStatusLog;
use App\Models\OrderStatusLabel;
use InvalidArgumentException;

/**
 * Order State Machine — single source of truth for valid status transitions.
 * TIDAK BOLEH ada perubahan status order tanpa melalui service ini.
 */
class OrderStateMachine
{
    /**
     * Valid transitions: from_status => [allowed_to_statuses]
     * Semua transition harus explicit — tidak boleh ada wildcard.
     */
    private static array $transitions = [
        'pending' => ['confirmed', 'cancelled'],
        'confirmed' => ['preparing', 'cancelled'],
        'preparing' => ['ready_to_dispatch', 'cancelled'],
        'ready_to_dispatch' => ['driver_assigned', 'cancelled'],
        'driver_assigned' => ['delivering_equipment', 'cancelled'],
        'delivering_equipment' => ['equipment_arrived'],
        'equipment_arrived' => ['picking_up_body'],
        'picking_up_body' => ['body_arrived'],
        'body_arrived' => ['in_ceremony'],
        'in_ceremony' => ['heading_to_burial'],
        'heading_to_burial' => ['burial_completed'],
        'burial_completed' => ['returning_equipment', 'completed'],
        'returning_equipment' => ['completed'],
        'completed' => [], // terminal state
        'cancelled' => [], // terminal state
    ];

    /**
     * Attempt to transition an order to a new status.
     *
     * @throws InvalidArgumentException if transition is not allowed
     */
    public static function transition(Order $order, string $toStatus, string $userId, ?string $notes = null): Order
    {
        $fromStatus = $order->status;

        if (!self::canTransition($fromStatus, $toStatus)) {
            $allowed = implode(', ', self::$transitions[$fromStatus] ?? []);
            throw new InvalidArgumentException(
                "Transisi status tidak valid: '{$fromStatus}' → '{$toStatus}'. "
                . "Transisi yang diperbolehkan: [{$allowed}]"
            );
        }

        $order->update(['status' => $toStatus]);

        OrderStatusLog::create([
            'order_id' => $order->id,
            'user_id' => $userId,
            'from_status' => $fromStatus,
            'to_status' => $toStatus,
            'notes' => $notes,
        ]);

        return $order;
    }

    /**
     * Check if a transition is valid.
     */
    public static function canTransition(string $fromStatus, string $toStatus): bool
    {
        $allowed = self::$transitions[$fromStatus] ?? [];
        return in_array($toStatus, $allowed, true);
    }

    /**
     * Get all valid next statuses for a given status.
     */
    public static function nextStatuses(string $currentStatus): array
    {
        return self::$transitions[$currentStatus] ?? [];
    }

    /**
     * Get the full transition map (for documentation / admin UI).
     */
    public static function transitionMap(): array
    {
        return self::$transitions;
    }

    /**
     * Check if a status is terminal (no further transitions).
     */
    public static function isTerminal(string $status): bool
    {
        return empty(self::$transitions[$status] ?? ['placeholder']);
    }

    /**
     * Get consumer-facing label for a status (from DB).
     */
    public static function getConsumerLabel(string $status): string
    {
        return OrderStatusLabel::getLabel($status, true) ?? $status;
    }

    /**
     * Get internal label for a status (from DB).
     */
    public static function getInternalLabel(string $status): string
    {
        return OrderStatusLabel::getLabel($status, false) ?? $status;
    }
}
