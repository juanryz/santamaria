<?php

namespace App\Enums;

enum NotificationPriority: string
{
    case ALARM = 'ALARM';          // Bypass DND, alarm sound keras
    case VERY_HIGH = 'VERY_HIGH';  // Alarm sound
    case HIGH = 'HIGH';            // Custom sound
    case NORMAL = 'NORMAL';        // Default sound
    case LOW = 'LOW';              // Silent / badge only
    case VIEW = 'VIEW';            // No push, hanya in-app

    public function androidPriority(): string
    {
        return match ($this) {
            self::ALARM, self::VERY_HIGH, self::HIGH => 'high',
            default => 'normal',
        };
    }

    public function soundName(): string
    {
        return match ($this) {
            self::ALARM, self::VERY_HIGH => 'santa_maria_alarm',
            self::HIGH => 'santa_maria_high',
            default => 'default',
        };
    }

    public function shouldBypassDnd(): bool
    {
        return in_array($this, [self::ALARM, self::VERY_HIGH]);
    }
}
