<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

/**
 * Progress akta kematian per order (v1.39 + v1.40).
 * Flow (v1.40): RS/RT-RW → SM → Dukcapil → SM → Keluarga (setelah lunas + bawa KTP+KK).
 */
class OrderDeathCertProgress extends Model
{
    use HasUuids;

    protected $table = 'order_death_cert_progress';

    protected $fillable = [
        'order_id', 'petugas_akta_id', 'current_stage',
        'total_admin_fees', 'admin_fees_breakdown',
        'death_location_type', 'death_certificate_source',
        'source_document_received_at', 'source_document_photo_evidence_id',
        'family_ktp_photo_evidence_id', 'family_kk_photo_evidence_id',
        'family_ktp_received', 'family_kk_received',
        'started_at', 'cert_issued_at', 'handed_to_family_at', 'days_elapsed',
        'notes',
    ];

    protected $casts = [
        'total_admin_fees' => 'decimal:2',
        'admin_fees_breakdown' => 'array',
        'source_document_received_at' => 'datetime',
        'family_ktp_received' => 'boolean',
        'family_kk_received' => 'boolean',
        'started_at' => 'datetime',
        'cert_issued_at' => 'datetime',
        'handed_to_family_at' => 'datetime',
    ];

    public function order() { return $this->belongsTo(Order::class); }
    public function petugasAkta() { return $this->belongsTo(User::class, 'petugas_akta_id'); }
    public function stageLogs() { return $this->hasMany(DeathCertStageLog::class, 'progress_id'); }
    public function sourceDocumentPhoto() { return $this->belongsTo(PhotoEvidence::class, 'source_document_photo_evidence_id'); }
    public function familyKtpPhoto() { return $this->belongsTo(PhotoEvidence::class, 'family_ktp_photo_evidence_id'); }
    public function familyKkPhoto() { return $this->belongsTo(PhotoEvidence::class, 'family_kk_photo_evidence_id'); }

    public function canHandToFamily(): bool
    {
        return $this->current_stage === 'waiting_ktp_kk_pickup'
            && $this->family_ktp_received
            && $this->family_kk_received;
    }

    public function isOverdue(int $maxDays = 14): bool
    {
        if (!$this->started_at || $this->handed_to_family_at) {
            return false;
        }
        return $this->started_at->diffInDays(now()) > $maxDays;
    }
}
