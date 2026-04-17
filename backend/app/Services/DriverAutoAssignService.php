<?php

namespace App\Services;

use App\Models\Order;
use App\Models\User;

class DriverAutoAssignService
{
    /**
     * Called when any location confirms stock ready.
     * Checks if ALL locations are ready, then auto-assigns driver.
     */
    public function checkAndAssign(Order $order): bool
    {
        // 1. Get all checklist items grouped by provider_role
        $checklists = $order->checklists()->get();
        if ($checklists->isEmpty()) {
            return false;
        }

        $groups = $checklists->groupBy('provider_role');

        // 2. Check each group - all items must be checked
        foreach ($groups as $role => $items) {
            $allChecked = $items->every(fn($item) => $item->is_checked);
            if (!$allChecked) {
                return false; // Still waiting on this role
            }
        }

        // 3. All confirmed! Skip if driver already assigned
        if ($order->assigned_driver_id || $order->driver_id) {
            return false;
        }

        // 4. Find available driver (not currently on an active assignment)
        $driver = User::where('role', 'driver')
            ->where('is_active', true)
            ->whereDoesntHave('driverAssignments', function ($q) {
                $q->whereIn('status', ['assigned', 'accepted', 'departed', 'arrived']);
            })
            ->first();

        if (!$driver) {
            // No driver available — could notify owner here in the future
            return false;
        }

        // 5. Assign driver to order
        $order->update([
            'status' => 'driver_assigned',
            'assigned_driver_id' => $driver->id,
            'driver_id' => $driver->id,
        ]);

        return true;
    }
}
