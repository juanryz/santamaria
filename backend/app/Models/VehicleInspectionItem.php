<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class VehicleInspectionItem extends Model
{
    use HasUuids;
    public $timestamps = false;

    protected $fillable = [
        'inspection_id', 'master_item_id', 'is_passed', 'value', 'photo_path', 'notes',
    ];

    protected $casts = ['is_passed' => 'boolean'];

    public function inspection(): BelongsTo { return $this->belongsTo(VehicleInspection::class, 'inspection_id'); }
    public function masterItem(): BelongsTo { return $this->belongsTo(VehicleInspectionMaster::class, 'master_item_id'); }
}
