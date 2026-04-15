<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class TukangJagaDeliveryItem extends Model {
    use HasUuids;
    protected $fillable = ['delivery_id','item_name','quantity','unit','notes'];
}
