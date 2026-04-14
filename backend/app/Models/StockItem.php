<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class StockItem extends Model
{
    use HasFactory, \App\Traits\Uuids;
    
    protected $fillable = [
        'item_name',
        'category',
        'current_quantity',
        'minimum_quantity',
        'unit',
        'last_updated_by'
    ];
}
