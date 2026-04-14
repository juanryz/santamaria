<?php

namespace App\Enums;

enum EquipmentItemStatus: string
{
    case PREPARED = 'prepared';
    case SENT = 'sent';
    case RECEIVED = 'received';
    case PARTIAL_RETURN = 'partial_return';
    case RETURNED = 'returned';
    case MISSING = 'missing';

    public static function values(): array
    {
        return array_map(fn(self $s) => $s->value, self::cases());
    }

    public function label(): string
    {
        return match ($this) {
            self::PREPARED => 'Disiapkan',
            self::SENT => 'Dikirim',
            self::RECEIVED => 'Diterima',
            self::PARTIAL_RETURN => 'Kembali Sebagian',
            self::RETURNED => 'Dikembalikan',
            self::MISSING => 'Hilang',
        };
    }
}
