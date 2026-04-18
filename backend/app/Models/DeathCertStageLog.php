<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class DeathCertStageLog extends Model
{
    use HasUuids;

    protected $table = 'death_cert_stage_logs';

    public $timestamps = false;

    protected $fillable = [
        'progress_id', 'stage', 'institution_name', 'visited_at',
        'photo_evidence_id', 'fee_paid', 'receipt_photo_evidence_id', 'notes',
        'created_at',
    ];

    protected $casts = [
        'visited_at' => 'datetime',
        'fee_paid' => 'decimal:2',
        'created_at' => 'datetime',
    ];

    public function progress() { return $this->belongsTo(OrderDeathCertProgress::class, 'progress_id'); }
    public function photoEvidence() { return $this->belongsTo(PhotoEvidence::class, 'photo_evidence_id'); }
    public function receiptPhoto() { return $this->belongsTo(PhotoEvidence::class, 'receipt_photo_evidence_id'); }
}
