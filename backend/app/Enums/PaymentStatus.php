<?php

namespace App\Enums;

enum PaymentStatus: string
{
    case UNPAID = 'unpaid';
    case PROOF_UPLOADED = 'proof_uploaded';
    case PROOF_REJECTED = 'proof_rejected';
    case PARTIAL = 'partial';
    case PAID = 'paid';
    case VERIFIED = 'verified';

    public static function values(): array
    {
        return array_map(fn(self $s) => $s->value, self::cases());
    }

    public function label(): string
    {
        return match ($this) {
            self::UNPAID => 'Belum Bayar',
            self::PROOF_UPLOADED => 'Bukti Diupload',
            self::PROOF_REJECTED => 'Bukti Ditolak',
            self::PARTIAL => 'Sebagian',
            self::PAID => 'Lunas',
            self::VERIFIED => 'Terverifikasi',
        };
    }
}
