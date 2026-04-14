<?php

namespace App\Enums;

enum AttendanceStatus: string
{
    case SCHEDULED = 'scheduled';
    case PRESENT = 'present';
    case ABSENT = 'absent';
    case LATE = 'late';

    public static function values(): array
    {
        return array_map(fn(self $s) => $s->value, self::cases());
    }

    public function label(): string
    {
        return match ($this) {
            self::SCHEDULED => 'Dijadwalkan',
            self::PRESENT => 'Hadir',
            self::ABSENT => 'Tidak Hadir',
            self::LATE => 'Terlambat',
        };
    }

    public function color(): string
    {
        return match ($this) {
            self::SCHEDULED => '#9E9E9E',
            self::PRESENT => '#4CAF50',
            self::ABSENT => '#F44336',
            self::LATE => '#FF9800',
        };
    }
}
