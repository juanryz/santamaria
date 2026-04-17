<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class OwnerCommandLog extends Model
{
    use HasUuids;
    public $timestamps = false;
    const CREATED_AT = 'created_at';

    protected $fillable = ['command_id', 'actor_id', 'action', 'note'];
    protected $casts    = ['created_at' => 'datetime'];

    public function actor() { return $this->belongsTo(User::class, 'actor_id'); }
}
