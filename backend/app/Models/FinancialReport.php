<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class FinancialReport extends Model
{
    use HasUuids;

    protected $fillable = [
        'report_type', 'period_year', 'period_month',
        'generated_at', 'data', 'manual_notes', 'reviewed_by', 'reviewed_at',
    ];

    protected $casts = [
        'data' => 'array',
        'generated_at' => 'datetime',
        'reviewed_at' => 'datetime',
    ];

    public static function regenerateAll(): void
    {
        $service = app(\App\Services\FinancialTransactionService::class);
        $now = now();
        // regenerate this month and last month
        $service->generateMonthlySummary($now->year, $now->month);
        $service->generateMonthlySummary($now->copy()->subMonth()->year, $now->copy()->subMonth()->month);
        $service->generateAnnualSummary($now->year);
    }
}
