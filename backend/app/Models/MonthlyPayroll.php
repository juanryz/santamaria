<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MonthlyPayroll extends Model
{
    use HasUuids, HasFactory;

    protected $table = 'monthly_payroll';
    protected $keyType = 'string';
    public $incrementing = false;

    protected $fillable = [
        'user_id', 'period_year', 'period_month',
        'base_salary', 'tasks_assigned', 'tasks_completed',
        'completion_rate', 'kpi_score', 'calculated_salary',
        'adjustments', 'final_salary', 'adjustment_notes',
        'status', 'reviewed_by', 'approved_by', 'paid_at',
    ];

    protected $casts = [
        'paid_at' => 'datetime',
        'base_salary' => 'decimal:2',
        'calculated_salary' => 'decimal:2',
        'adjustments' => 'decimal:2',
        'final_salary' => 'decimal:2',
        'completion_rate' => 'decimal:2',
        'kpi_score' => 'decimal:2',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function reviewedBy()
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }

    public function approvedBy()
    {
        return $this->belongsTo(User::class, 'approved_by');
    }
}
