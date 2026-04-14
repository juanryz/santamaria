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
