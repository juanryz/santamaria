<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class EmployeeLeave extends Model
{
    use HasUuids;

    protected $table = 'employee_leaves';

    protected $fillable = [
        'user_id', 'leave_type', 'start_date', 'end_date', 'days_count',
        'reason', 'medical_cert_photo',
        'status', 'approved_by', 'approved_at', 'rejection_reason',
    ];

    protected $casts = [
        'start_date' => 'date',
        'end_date' => 'date',
        'approved_at' => 'datetime',
    ];

    public function user() { return $this->belongsTo(User::class); }
    public function approver() { return $this->belongsTo(User::class, 'approved_by'); }

    public function isPending(): bool { return $this->status === 'requested'; }
    public function isApproved(): bool { return $this->status === 'approved'; }

    public function isActive(): bool
    {
        return $this->isApproved()
            && now()->startOfDay()->between($this->start_date, $this->end_date);
    }
}
