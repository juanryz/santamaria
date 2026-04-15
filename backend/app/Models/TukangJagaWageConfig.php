<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class TukangJagaWageConfig extends Model {
    use HasUuids;
    protected $fillable = ['label','shift_type','rate','currency','is_active'];
    protected $casts = ['rate'=>'decimal:2','is_active'=>'boolean'];
}
