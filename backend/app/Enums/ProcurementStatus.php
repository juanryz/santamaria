<?php

namespace App\Enums;

enum ProcurementStatus: string
{
    case DRAFT = 'draft';
    case OPEN = 'open';
    case EVALUATING = 'evaluating';
    case AWARDED = 'awarded';
    case PURCHASING_APPROVED = 'finance_approved';
    case GOODS_RECEIVED = 'goods_received';
    case PARTIAL_RECEIVED = 'partial_received';
    case COMPLETED = 'completed';
    case CANCELLED = 'cancelled';

    public static function values(): array
    {
        return array_map(fn(self $s) => $s->value, self::cases());
    }

    public function label(): string
    {
        return match ($this) {
            self::DRAFT => 'Draft',
            self::OPEN => 'Terbuka',
            self::EVALUATING => 'Evaluasi',
            self::AWARDED => 'Terpilih',
            self::PURCHASING_APPROVED => 'Disetujui Finance',
            self::GOODS_RECEIVED => 'Barang Diterima',
            self::PARTIAL_RECEIVED => 'Diterima Sebagian',
            self::COMPLETED => 'Selesai',
            self::CANCELLED => 'Dibatalkan',
        };
    }
}
