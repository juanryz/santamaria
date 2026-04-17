<?php
namespace App\Http\Controllers\TukangJaga;

use App\Http\Controllers\Controller;
use App\Models\TukangJagaShift;
use App\Models\TukangJagaWageConfig;
use App\Models\Order;
use App\Services\FinancialTransactionService;
use App\Services\NotificationService;
use Illuminate\Http\Request;

class ShiftController extends Controller
{
    public function __construct(private FinancialTransactionService $finService) {}

    // GET /tukang-jaga/shifts — my shifts
    public function myShifts(Request $request)
    {
        $shifts = TukangJagaShift::where('assigned_to', $request->user()->id)
            ->with(['order:id,order_number,deceased_name,scheduled_at,destination_address', 'wageConfig'])
            ->orderBy('scheduled_start')
            ->get();
        return response()->json(['success' => true, 'data' => $shifts]);
    }

    // GET /tukang-jaga/shifts/{id}
    public function show(string $id)
    {
        $shift = TukangJagaShift::with(['order', 'assignedUser', 'wageConfig', 'deliveries.items'])
            ->findOrFail($id);
        return response()->json(['success' => true, 'data' => $shift]);
    }

    // POST /tukang-jaga/shifts/{id}/checkin
    public function checkin(Request $request, string $id)
    {
        $shift = TukangJagaShift::where('assigned_to', $request->user()->id)
            ->where('status', 'scheduled')
            ->findOrFail($id);

        // Cek waktu tidak terlalu jauh dari jadwal (15 menit sebelum / kapan saja setelah jadwal)
        $now = now();
        $allowedEarly = $shift->scheduled_start->copy()->subMinutes(15);
        if ($now->lt($allowedEarly)) {
            return response()->json(['success' => false, 'message' => 'Terlalu awal untuk check-in. Bisa check-in 15 menit sebelum shift.'], 422);
        }

        $shift->update([
            'status'     => 'active',
            'checkin_at' => $now,
        ]);

        return response()->json(['success' => true, 'data' => $shift->fresh('wageConfig'), 'message' => 'Check-in berhasil.']);
    }

    // POST /tukang-jaga/shifts/{id}/checkout
    public function checkout(Request $request, string $id)
    {
        $shift = TukangJagaShift::where('assigned_to', $request->user()->id)
            ->where('status', 'active')
            ->findOrFail($id);

        $wageConfig = $shift->wageConfig;
        $wageAmount = $wageConfig ? $wageConfig->rate : 0;

        $shift->update([
            'status'      => 'completed',
            'checkout_at' => now(),
            'wage_amount' => $wageAmount,
            'notes'       => $request->input('notes', $shift->notes),
        ]);

        // Record financial transaction for wage
        if ($wageAmount > 0) {
            $this->finService->record([
                'transaction_type' => 'tukang_jaga_wage',
                'reference_type'   => 'shift',
                'reference_id'     => $shift->id,
                'order_id'         => $shift->order_id,
                'amount'           => $wageAmount,
                'direction'        => 'out',
                'category'         => 'upah_tukang_jaga',
                'description'      => "Upah shift #{$shift->shift_number} - {$shift->assignedUser?->name}",
                'transaction_date' => now()->toDateString(),
                'recorded_by'      => $request->user()->id,
            ]);
        }

        // Notify purchasing untuk proses upah
        NotificationService::sendToRole(
            \App\Enums\UserRole::PURCHASING->value,
            'HIGH',
            'Tukang Jaga Checkout',
            "Shift #{$shift->shift_number} order {$shift->order?->order_number} selesai. Upah: Rp " . number_format($wageAmount),
            ['shift_id' => $shift->id, 'order_number' => $shift->order?->order_number, 'wage' => $wageAmount]
        );

        return response()->json(['success' => true, 'data' => $shift->fresh(), 'message' => 'Check-out berhasil. Upah: Rp ' . number_format($wageAmount)]);
    }

    // POST /tukang-jaga/shifts/{id}/switch — handover shift ke tukang jaga pengganti
    public function switchShift(Request $request, string $id)
    {
        $request->validate([
            'incoming_shift_id' => 'required|uuid|exists:tukang_jaga_shifts,id',
        ]);

        $currentShift = TukangJagaShift::where('assigned_to', $request->user()->id)
            ->where('status', 'active')
            ->findOrFail($id);

        $incomingShift = TukangJagaShift::where('id', $request->input('incoming_shift_id'))
            ->where('status', 'scheduled')
            ->where('order_id', $currentShift->order_id)
            ->firstOrFail();

        if ($incomingShift->assigned_to === $currentShift->assigned_to) {
            return response()->json([
                'success' => false,
                'message' => 'Shift pengganti harus milik tukang jaga yang berbeda.',
            ], 422);
        }

        // Calculate wage for completing shift
        $wageConfig = $currentShift->wageConfig;
        $wageAmount = $wageConfig ? $wageConfig->rate : 0;

        $now = now();

        // 1. Complete current shift
        $currentShift->update([
            'status'      => 'completed',
            'checkout_at' => $now,
            'wage_amount' => $wageAmount,
        ]);

        // 2. Activate incoming shift
        $incomingShift->update([
            'status'              => 'active',
            'checkin_at'          => $now,
            'checkin_verified_by' => $request->user()->id,
        ]);

        // 3. Record financial transaction for completed shift wage
        if ($wageAmount > 0) {
            $this->finService->record([
                'transaction_type' => 'tukang_jaga_wage',
                'reference_type'   => 'shift',
                'reference_id'     => $currentShift->id,
                'order_id'         => $currentShift->order_id,
                'amount'           => $wageAmount,
                'direction'        => 'out',
                'category'         => 'upah_tukang_jaga',
                'description'      => "Upah shift #{$currentShift->shift_number} (switch) - {$currentShift->assignedUser?->name}",
                'transaction_date' => $now->toDateString(),
                'recorded_by'      => $request->user()->id,
            ]);
        }

        // Notify purchasing
        NotificationService::sendToRole(
            \App\Enums\UserRole::PURCHASING->value,
            'HIGH',
            'Tukang Jaga Switch Shift',
            "Shift #{$currentShift->shift_number} → #{$incomingShift->shift_number} order {$currentShift->order?->order_number}. Upah shift selesai: Rp " . number_format($wageAmount),
            ['current_shift_id' => $currentShift->id, 'incoming_shift_id' => $incomingShift->id]
        );

        return response()->json([
            'success' => true,
            'data'    => [
                'completed_shift' => $currentShift->fresh('wageConfig'),
                'active_shift'    => $incomingShift->fresh('wageConfig'),
            ],
            'message' => 'Switch shift berhasil.',
        ]);
    }
}
