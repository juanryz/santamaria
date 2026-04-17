<?php

namespace App\Console\Commands;

use App\Enums\UserRole;
use App\Enums\NotificationPriority;
use App\Models\Order;
use App\Models\SoProspect;
use App\Models\SoVisitLog;
use App\Models\User;
use App\Services\NotificationService;
use Illuminate\Console\Command;
use Illuminate\Support\Carbon;

class GenerateSODailyReport extends Command
{
    protected $signature = 'so:daily-report';
    protected $description = 'Generate and send daily summary report to each active Service Officer';

    public function handle(): void
    {
        $today = Carbon::today('Asia/Jakarta');
        $tomorrow = $today->copy()->addDay();

        $soUsers = User::where('role', UserRole::SERVICE_OFFICER->value)
            ->where('is_active', true)
            ->get();

        if ($soUsers->isEmpty()) {
            $this->info('No active SO users found.');
            return;
        }

        foreach ($soUsers as $so) {
            $stats = $this->gatherStats($so, $today, $tomorrow);
            $this->sendToSo($so, $stats);
            $this->sendToOwner($so, $stats);
        }

        $this->info("Daily report sent to {$soUsers->count()} SO(s).");
    }

    private function gatherStats(User $so, Carbon $today, Carbon $tomorrow): array
    {
        $ordersCreated = Order::where('so_user_id', $so->id)
            ->whereDate('created_at', $today)
            ->count();

        $ordersConfirmed = Order::where('so_user_id', $so->id)
            ->whereDate('so_submitted_at', $today)
            ->count();

        $visits = SoVisitLog::where('so_user_id', $so->id)
            ->whereDate('visit_date', $today)
            ->count();

        $prospects = SoProspect::where('so_user_id', $so->id)
            ->whereDate('created_at', $today)
            ->count();

        $amendmentsHandled = 0;
        // OrderAmendment may not exist yet; guard with table check
        if (\Schema::hasTable('order_amendments')) {
            $amendmentsHandled = \DB::table('order_amendments')
                ->where('so_id', $so->id)
                ->whereDate('updated_at', $today)
                ->whereIn('status', ['so_reviewed', 'family_approved', 'completed'])
                ->count();
        }

        $followUpsTomorrow = SoProspect::where('so_user_id', $so->id)
            ->whereDate('follow_up_date', $tomorrow)
            ->whereNotIn('status', ['converted', 'lost'])
            ->get(['name', 'phone', 'notes']);

        return [
            'orders_created' => $ordersCreated,
            'orders_confirmed' => $ordersConfirmed,
            'visits' => $visits,
            'prospects' => $prospects,
            'amendments' => $amendmentsHandled,
            'follow_ups' => $followUpsTomorrow,
        ];
    }

    private function sendToSo(User $so, array $stats): void
    {
        $followUpCount = $stats['follow_ups']->count();
        $body = "Laporan Harian Anda: "
            . "{$stats['orders_created']} order baru, "
            . "{$stats['orders_confirmed']} dikonfirmasi, "
            . "{$stats['visits']} visit, "
            . "{$stats['prospects']} prospek baru, "
            . "{$stats['amendments']} amendment.";

        if ($followUpCount > 0) {
            $names = $stats['follow_ups']->pluck('name')->take(3)->join(', ');
            $body .= " Besok: {$followUpCount} follow-up pending ({$names}" . ($followUpCount > 3 ? ', ...' : '') . ").";
        }

        NotificationService::send($so, 'NORMAL', 'Laporan Harian SO', $body);
    }

    private function sendToOwner(User $so, array $stats): void
    {
        $body = "Ringkasan SO: {$so->name} - "
            . "{$stats['orders_created']} order, "
            . "{$stats['visits']} visit, "
            . "{$stats['prospects']} prospek, "
            . "{$stats['amendments']} amendment.";

        NotificationService::sendToRole(
            UserRole::OWNER->value,
            'NORMAL',
            "Laporan SO: {$so->name}",
            $body
        );
    }
}
