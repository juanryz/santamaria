<?php

namespace App\Console\Commands;

use App\Services\NotificationService;
use Illuminate\Console\Command;

/**
 * v1.40 — Stock opname reminder semester.
 * Dijadwalkan cron: 0 8 1 1,7 *   (1 Januari & 1 Juli jam 08:00)
 * Kirim reminder ke role yang punya stok: gudang, super_admin, dekor.
 */
class StockOpnameReminder extends Command
{
    protected $signature = 'stock:opname-reminder';
    protected $description = 'Reminder opname semester untuk role pemilik stok (v1.40)';

    public function handle(): void
    {
        $now = now();
        $semester = $now->month <= 6 ? 'H1' : 'H2';
        $semesterLabel = $semester === 'H1' ? 'Januari–Juni' : 'Juli–Desember';
        $year = $now->year;

        $title = "Stock Opname Semester {$semester} {$year}";
        $body = "Mohon mulai stock opname untuk periode {$semesterLabel} {$year}. " .
                "Buka menu 'Stock Opname' di aplikasi dan hitung fisik stok yang Anda kelola.";

        foreach (['gudang', 'super_admin', 'dekor'] as $role) {
            NotificationService::sendToRole($role, 'HIGH', $title, $body);
        }

        $this->info("Stock opname reminder sent to gudang, super_admin, dekor for {$semester} {$year}.");
    }
}
