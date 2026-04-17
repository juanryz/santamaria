<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class OwnerCommandReceipt extends Model
{
    use HasUuids;
    public $timestamps = false;

    protected $fillable = ['command_id', 'user_id', 'delivered_at', 'acknowledged_at', 'note'];
    protected $casts    = ['delivered_at' => 'datetime', 'acknowledged_at' => 'datetime'];

    public function command() { return $this->belongsTo(OwnerCommand::class, 'command_id'); }
    public function user()    { return $this->belongsTo(User::class); }
}
