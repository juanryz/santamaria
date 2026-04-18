<?php

namespace App\Console\Commands;

use App\Models\ConsumerMembership;
use App\Models\SystemThreshold;
use App\Services\NotificationService;
use Illuminate\Console\Command;

/**
 * v1.39 — Auto-update membership status berdasarkan keterlambatan bayar iuran.
 *
 * Rule:
 *  - next_payment_due lewat 0..30 hari → tetap active (grace reset atau tetap active)
 *  - next_payment_due lewat > 30 hari  → status 'grace_period' (tetap dapat harga anggota)
 *  - next_payment_due lewat > 60 hari  → status 'inactive' (harga kembali non-anggota)
 *
 * Juga kirim reminder H-7, H-3, H-1 sebelum jatuh tempo.
 */
class CheckMembershipPaymentStatus extends Command
{
    protected $signature = 'membership:check-payment-status';
    protected $description = 'Auto-update status membership + kirim reminder iuran bulanan (v1.39)';

    public function handle(): void
    {
        $gracePeriodDays = (int) SystemThreshold::getValue('membership_grace_period_days', 30);
        $inactiveAfterDays = (int) SystemThreshold::getValue('membership_inactive_after_days', 60);

        $promotedToGrace = 0;
        $demotedToInactive = 0;
        $remindersSent = 0;

        $memberships = ConsumerMembership::with('user:id,name,phone')
            ->whereIn('status', ['active', 'grace_period'])
            ->whereNotNull('next_payment_due')
            ->get();

        $today = now()->startOfDay();

        foreach ($memberships as $m) {
            $dueDate = $m->next_payment_due;
            if (!$dueDate) continue;

            $daysOverdue = (int) $today->diffInDays($dueDate, false) * -1;
            // diff signed: jika due di masa depan, negatif; jika lewat, positif

            if ($daysOverdue > $inactiveAfterDays) {
                if ($m->status !== 'inactive') {
                    $m->update(['status' => 'inactive']);
                    $demotedToInactive++;
                    $this->notifyInactive($m);
                }
            } elseif ($daysOverdue > $gracePeriodDays) {
                if ($m->status !== 'grace_period') {
                    $m->update([
                        'status' => 'grace_period',
                        'grace_period_until' =>
                            $dueDate->copy()->addDays($inactiveAfterDays),
                    ]);
                    $promotedToGrace++;
                    $this->notifyGracePeriod($m);
                }
            } else {
                // Kirim reminder H-7, H-3, H-1 sebelum due
                $daysUntilDue = $daysOverdue * -1;
                if (in_array($daysUntilDue, [7, 3, 1]) && $m->user?->phone) {
                    $this->sendReminder($m, $daysUntilDue);
                    $remindersSent++;
                }
            }
        }

        $this->info(
            "Membership status check: {$promotedToGrace} → grace_period, " .
            "{$demotedToInactive} → inactive, {$remindersSent} reminders sent."
        );
    }

    private function notifyGracePeriod(ConsumerMembership $m): void
    {
        if (!$m->user_id) return;
        NotificationService::send(
            $m->user_id,
            'HIGH',
            'Iuran Membership Tertunggak',
            "Iuran membership {$m->membership_number} belum dibayar > 30 hari. " .
            "Anda masih dapat harga anggota sampai 60 hari. Segera bayar iuran."
        );
    }

    private function notifyInactive(ConsumerMembership $m): void
    {
        if (!$m->user_id) return;
        NotificationService::send(
            $m->user_id,
            'ALARM',
            'Membership Nonaktif',
            "Membership {$m->membership_number} kini NONAKTIF karena belum bayar iuran " .
            "> 60 hari. Harga paket kembali non-anggota."
        );

        // Alarm Purchasing juga untuk follow up
        NotificationService::sendToRole(
            'purchasing',
            'NORMAL',
            'Membership Inactive',
            "{$m->user?->name} — {$m->membership_number} menjadi inactive."
        );
    }

    private function sendReminder(ConsumerMembership $m, int $daysUntilDue): void
    {
        if (!$m->user_id) return;
        NotificationService::send(
            $m->user_id,
            'NORMAL',
            'Reminder Iuran Membership',
            "Iuran membership {$m->membership_number} jatuh tempo dalam {$daysUntilDue} hari " .
            "({$m->next_payment_due->format('d M Y')}). Nominal: Rp " .
            number_format((float) $m->monthly_fee, 0, ',', '.')
        );
    }
}
