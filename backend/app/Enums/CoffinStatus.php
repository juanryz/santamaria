<?php

namespace App\Enums;

enum CoffinStatus: string
{
    case DRAFT = 'draft';
    case BUSA_PROCESS = 'busa_process';
    case BUSA_DONE = 'busa_done';
    case AMPLAS_PROCESS = 'amplas_process';
    case AMPLAS_DONE = 'amplas_done';
    case QC_PENDING = 'qc_pending';
    case QC_PASSED = 'qc_passed';
    case QC_FAILED = 'qc_failed';
    case DELIVERED = 'delivered';

    public static function values(): array
    {
        return array_map(fn(self $s) => $s->value, self::cases());
    }

    public function label(): string
    {
        return match ($this) {
            self::DRAFT => 'Draft',
            self::BUSA_PROCESS => 'Proses Busa',
            self::BUSA_DONE => 'Busa Selesai',
            self::AMPLAS_PROCESS => 'Proses Amplas',
            self::AMPLAS_DONE => 'Amplas Selesai',
            self::QC_PENDING => 'Menunggu QC',
            self::QC_PASSED => 'Lolos QC',
            self::QC_FAILED => 'Gagal QC',
            self::DELIVERED => 'Dikirim',
        };
    }
}
