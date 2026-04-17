<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class OwnerCommand extends Model
{
    use HasUuids;

    protected $fillable = [
        'owner_id', 'title', 'message', 'priority',
        'target_user_id', 'target_role', 'status',
    ];

    public function owner()      { return $this->belongsTo(User::class, 'owner_id'); }
    public function targetUser() { return $this->belongsTo(User::class, 'target_user_id'); }
    public function receipts()   { return $this->hasMany(OwnerCommandReceipt::class, 'command_id'); }
    public function logs()       { return $this->hasMany(OwnerCommandLog::class, 'command_id')->orderBy('created_at'); }
}
