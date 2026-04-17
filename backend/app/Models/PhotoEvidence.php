<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PhotoEvidence extends Model
{
    use HasUuids, HasFactory;

    protected $keyType = 'string';
    public $incrementing = false;

    protected $fillable = [
        'context', 'order_id', 'user_id', 'reference_type', 'reference_id',
        'file_path', 'file_size_bytes', 'thumbnail_path',
        'latitude', 'longitude', 'accuracy_meters', 'altitude',
        'taken_at', 'server_received_at', 'device_id', 'device_model',
        'is_validated', 'validated_by', 'validation_notes', 'notes',
    ];

    protected $casts = [
        'taken_at' => 'datetime',
        'server_received_at' => 'datetime',
        'is_validated' => 'boolean',
        'latitude' => 'decimal:7',
        'longitude' => 'decimal:7',
    ];

    public function order()
    {
        return $this->belongsTo(Order::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function validatedBy()
    {
        return $this->belongsTo(User::class, 'validated_by');
    }
}
