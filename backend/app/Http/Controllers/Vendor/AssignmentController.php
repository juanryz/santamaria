<?php

namespace App\Http\Controllers\Vendor;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\PemukaAgamaAssignment;
use App\Models\OrderStatusLog;
use App\Services\NotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AssignmentController extends Controller
{
    public function index(Request $request)
    {
        $role = $request->user()->role;
        
        if ($role === UserRole::PEMUKA_AGAMA->value) {
            $assignments = PemukaAgamaAssignment::where('pemuka_agama_id', $request->user()->id)
                ->with('order')
                ->orderBy('created_at', 'desc')
                ->get();
        } else {
            // Internal vendors (Dekor, Konsumsi) subscribe to order statuses
            $statusField = ($role === UserRole::DEKOR->value) ? 'dekor_status' : 'konsumsi_status';
            $assignments = Order::whereIn($statusField, ['pending', 'confirmed'])
                ->orderBy('created_at', 'desc')
                ->get();
        }

        return response()->json([
            'success' => true,
            'data' => $assignments
        ]);
    }

    public function confirm($id, Request $request)
    {
        $user = $request->user();
        
        if ($user->role === UserRole::PEMUKA_AGAMA->value) {
            $assignment = PemukaAgamaAssignment::where('id', $id)
                ->where('pemuka_agama_id', $user->id)
                ->firstOrFail();

            return DB::transaction(function () use ($assignment, $user) {
                $assignment->update([
                    'response' => 'confirmed',
                    'responded_at' => now()
                ]);

                $order = $assignment->order;
                $order->update([
                    'pemuka_agama_status' => 'confirmed',
                    'pemuka_agama_user_id' => $user->id,
                    'pemuka_agama_confirmed_at' => now()
                ]);

                NotificationService::sendToRole(UserRole::ADMIN->value, 'NORMAL', 'Pemuka Agama Ditemukan', "{$user->name} telah mengonfirmasi untuk order {$order->order_number}");

                return response()->json(['success' => true, 'message' => 'Assignment confirmed']);
            });
        }

        // For Dekor/Konsumsi
        $order = Order::findOrFail($id);
        $statusField = ($user->role === UserRole::DEKOR->value) ? 'dekor_status' : 'konsumsi_status';
        $timeField = ($user->role === UserRole::DEKOR->value) ? 'dekor_confirmed_at' : 'konsumsi_confirmed_at';

        $order->update([
            $statusField => 'confirmed',
            $timeField => now()
        ]);

        return response()->json(['success' => true, 'message' => 'Task confirmed']);
    }

    public function reject($id, Request $request)
    {
        $user = $request->user();
        
        if ($user->role !== UserRole::PEMUKA_AGAMA->value) {
            return response()->json(['success' => false, 'message' => 'Only Pemuka Agama can reject assignments'], 403);
        }

        $assignment = PemukaAgamaAssignment::where('id', $id)
            ->where('pemuka_agama_id', $user->id)
            ->firstOrFail();

        $assignment->update([
            'response' => 'rejected',
            'responded_at' => now()
        ]);

        // Note: Job to notify next candidate would be dispatched here
        // NotifyNextPemukaAgama::dispatch($assignment->order_id);

        return response()->json(['success' => true, 'message' => 'Assignment rejected']);
    }

    public function done($id, Request $request)
    {
        $user = $request->user();
        $order = Order::findOrFail($id);
        
        $statusField = match($user->role) {
            UserRole::DEKOR->value => 'dekor_status',
            UserRole::KONSUMSI->value => 'konsumsi_status',
            UserRole::PEMUKA_AGAMA->value => 'pemuka_agama_status', // Simplified
            default => null
        };

        if (!$statusField) return response()->json(['success' => false, 'message' => 'Invalid role'], 403);

        $order->update([$statusField => 'done']);

        return response()->json(['success' => true, 'message' => 'Task marked as done']);
    }
}
