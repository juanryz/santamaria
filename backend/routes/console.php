<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Schedulers for Santa Maria
Schedule::command('report:daily')->dailyAt('21:00')->timezone('Asia/Jakarta');
Schedule::command('pemuka-agama:check-timeout')->everyFiveMinutes();
Schedule::command('vendor:monthly-score')->monthlyOn(1, '00:00');
Schedule::command('stock:check-anomaly')->dailyAt('08:00')->timezone('Asia/Jakarta');
Schedule::command('ai:demand-prediction')->weekly()->mondays()->at('07:00');
Schedule::command('catalog:close-expired-quotes')->hourly();
Schedule::command('notification:repeat-alarms')->everyThirtySeconds();

// v1.9 — Auto-complete orders by time (setiap 5 menit)
Schedule::command('order:auto-complete-by-time')->everyFiveMinutes();

// v1.9 — Consumer payment reminder (tiap jam)
Schedule::command('order:send-payment-reminder')->hourly();

// v1.10 — HRD violation checks
Schedule::command('hrd:check-driver-overtime')->everyThirtyMinutes();
Schedule::command('hrd:check-so-late-processing')->everyFiveMinutes();
Schedule::command('hrd:check-vendor-repeated-reject')->dailyAt('06:00')->timezone('Asia/Jakarta');
Schedule::command('hrd:check-finance-late-payment')->hourly();
Schedule::command('hrd:check-late-bukti-upload')->everyThirtyMinutes();

// v1.14 — Attendance, Equipment, Coffin QC, Death Cert, KPI
Schedule::command('attendance:check-late')->everyFiveMinutes();
Schedule::command('equipment:check-return-deadline')->hourly();
Schedule::command('coffin:check-qc-deadline')->everyTwoHours();
Schedule::command('death-cert:check-pending')->dailyAt('09:00')->timezone('Asia/Jakarta');
Schedule::command('kpi:calculate-monthly')->monthlyOn(1, '02:00')->timezone('Asia/Jakarta');
Schedule::command('kpi:refresh-current-period')->everySixHours();

// v1.31 — Stuck items detection & foto deadline
Schedule::command('items:detect-stuck')->everyTwoHours();
Schedule::command('foto:check-deadline')->everyThirtyMinutes();

// v1.29 — Payment reminders to consumers (every 6 hours)
Schedule::command('payment:send-reminders')->everySixHours();

// SO daily report at 20:00 WIB
Schedule::command('so:daily-report')->dailyAt('20:00')->timezone('Asia/Jakarta');

// v1.15 — Financial report regeneration
Schedule::call(fn() => \App\Models\FinancialReport::regenerateAll())->hourly();

// ── v1.40 — Koreksi Operasional ────────────────────────────────────────
// Consumer payment reminder harian H+4..H+10 + eskalasi H+11+
Schedule::command('consumer-payment:send-reminders')
    ->dailyAt('09:00')->timezone('Asia/Jakarta');

// Akta kematian overdue check (threshold 2 minggu)
Schedule::command('death-cert:check-overdue')
    ->dailyAt('09:30')->timezone('Asia/Jakarta');

// Stock opname reminder semester — 1 Januari & 1 Juli 08:00 WIB
Schedule::command('stock:opname-reminder')
    ->cron('0 8 1 1,7 *')->timezone('Asia/Jakarta');

// Membership payment status: auto grace_period / inactive + reminder H-7/H-3/H-1
Schedule::command('membership:check-payment-status')
    ->dailyAt('06:00')->timezone('Asia/Jakarta');
