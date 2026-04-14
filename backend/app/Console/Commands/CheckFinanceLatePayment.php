<?php

namespace App\Console\Commands;

use App\Models\HrdViolation;
use App\Models\Order;
use App\Models\OrderFieldTeamPayment;
use App\Models\SystemThreshold;
use App\Services\NotificationService;
use Carbon\Carbon;
use Illuminate\Console\Command;

class CheckFinanceLatePayment extends Command
{
    protected $signature   = 'hrd:check-finance-late-payment';
    protected $description = 'Detect late payment verification by Finance and late field team payments.';

    public function handle(): void
    {
        $this->checkLatePaymentVerification();
        $this->checkLateFieldTeamPayment();
        $this->info('Finance late payment checks selesai.');
    }

    private function checkLatePaymentVerification(): void
    {
        $deadlineHours = SystemThreshold::getValue('payment_verify_deadline_hours', 24);

        Order::where('payment_status', 'proof_uploaded')
            ->whereNotNull('payment_proof_uploaded_at')
            ->get()
            ->each(function (Order $order) use ($deadlineHours) {
                $hoursWaiting = Carbon::parse($order->payment_proof_uploaded_at)->diffInHours(now());

                if ($hoursWaiting < $deadlineHours) {
                    return;
                }

                $exists = HrdViolation::where('order_id', $order->id)
                    ->where('violation_type', 'late_payment_processing')
                    ->exists();

                if ($exists) {
                    return;
                }

                // Target: finance user yang bertugas, atau generic
                $financeUsers = \App\Models\User::where('role', 'finance')->pluck('id');
                $targetUserId = $financeUsers->first();

                if (!$targetUserId) {
                    return;
                }

                $violation = HrdViolation::create([
                    'violated_by'     => $targetUserId,
                    'order_id'        => $order->id,
                    'violation_type'  => 'late_payment_processing',
                    'description'     => "Finance terlambat verifikasi bukti payment order {$order->order_number}. Sudah {$hoursWaiting} jam (maks {$deadlineHours} jam).",
                    'threshold_value' => $deadlineHours,
                    'actual_value'    => $hoursWaiting,
                    'severity'        => $hoursWaiting > ($deadlineHours * 2) ? 'high' : 'medium',
                    'status'          => 'new',
                ]);

                NotificationService::sendHrdViolationAlert($violation);
                $this->warn("Finance late payment verify: order {$order->order_number}");
            });
    }

    private function checkLateFieldTeamPayment(): void
    {
        $deadlineHours = SystemThreshold::getValue('field_team_payment_deadline_hours', 48);

        // Cari order yang sudah completed tapi masih ada field team payment pending
        OrderFieldTeamPayment::where('payment_status', 'pending')
            ->where('is_absent', false)
            ->with('order:id,order_number,status,completed_at')
            ->get()
            ->each(function (OrderFieldTeamPayment $member) use ($deadlineHours) {
                if (!$member->order || $member->order->status !== 'completed' || !$member->order->completed_at) {
                    return;
                }

                $hoursAfterComplete = Carbon::parse($member->order->completed_at)->diffInHours(now());

                if ($hoursAfterComplete < $deadlineHours) {
                    return;
                }

                $exists = HrdViolation::where('order_id', $member->order_id)
                    ->where('violation_type', 'late_field_team_payment')
                    ->whereDate('created_at', today())
                    ->exists();

                if ($exists) {
                    return;
                }

                $financeUsers = \App\Models\User::where('role', 'finance')->pluck('id');
                $targetUserId = $financeUsers->first();

                if (!$targetUserId) {
                    return;
                }

                $violation = HrdViolation::create([
                    'violated_by'     => $targetUserId,
                    'order_id'        => $member->order_id,
                    'violation_type'  => 'late_field_team_payment',
                    'description'     => "Upah tim lapangan order {$member->order->order_number} belum dibayar. Sudah {$hoursAfterComplete} jam sejak order selesai (maks {$deadlineHours} jam).",
                    'threshold_value' => $deadlineHours,
                    'actual_value'    => $hoursAfterComplete,
                    'severity'        => 'medium',
                    'status'          => 'new',
                ]);

                NotificationService::sendHrdViolationAlert($violation);
                $this->warn("Late field team payment: order {$member->order->order_number}");
            });
    }
}
