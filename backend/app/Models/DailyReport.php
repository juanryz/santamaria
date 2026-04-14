<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DailyReport extends Model
{
    use \App\Traits\Uuids;

    protected $fillable = [
        'report_date',
        'total_orders_today',
        'completed_orders',
        'pending_orders',
        'total_revenue',
        'total_paid',
        'anomalies_detected',
        'ai_narrative',
        'sent_to_owner_at'
    ];

    public $timestamps = false; // migration has created_at but not updated_at explicitly or handles it differently
}
