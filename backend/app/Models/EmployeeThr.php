<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class EmployeeThr extends Model
{
    use HasUuids;

    protected $table = 'employee_thr';

    protected $fillable = [
        'user_id', 'year', 'amount',
        'paid_at', 'paid_by', 'receipt_path', 'notes',
    ];

    protected $casts = [
        'paid_at' => 'datetime',
        'amount' => 'decimal:2',
    ];

    public function user() { return $this->belongsTo(User::class); }
    public function payer() { return $this->belongsTo(User::class, 'paid_by'); }
}
