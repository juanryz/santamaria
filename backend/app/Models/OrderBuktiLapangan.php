<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OrderBuktiLapangan extends Model
{
    public $timestamps = false;

    protected $table = 'order_bukti_lapangan';

    protected $fillable = [
        'order_id',
        'uploaded_by',
        'role',
        'bukti_type',
        'file_path',
        'file_size_bytes',
        'notes',
        'created_at',
    ];

    protected $casts = [
        'created_at' => 'datetime',
    ];

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function uploader(): BelongsTo
    {
        return $this->belongsTo(User::class, 'uploaded_by');
    }
}
