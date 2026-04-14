<?php

namespace App\Enums;

/**
 * Semua status order — TIDAK BOLEH di-hardcode di manapun.
 * Referensi tunggal untuk seluruh status order di sistem.
 */
enum OrderStatus: string
{
    // Core flow
    case PENDING = 'pending';
    case CONFIRMED = 'confirmed';
    case APPROVED = 'approved';
    case IN_PROGRESS = 'in_progress';
    case COMPLETED = 'completed';
    case CANCELLED = 'cancelled';

    // Extended flow (v1.13+)
    case SO_REVIEW = 'so_review';
    case ADMIN_REVIEW = 'admin_review';
    case DELIVERING_EQUIPMENT = 'delivering_equipment';
    case EQUIPMENT_ARRIVED = 'equipment_arrived';
    case DELIVERING_BODY = 'delivering_body';
    case BODY_ARRIVED = 'body_arrived';
    case SERVICE_ONGOING = 'service_ongoing';
    case BURIAL_PROCESS = 'burial_process';
    case BURIAL_COMPLETED = 'burial_completed';
    case POST_SERVICE = 'post_service';
    case PAYMENT_PENDING = 'payment_pending';

    public static function values(): array
    {
        return array_map(fn(self $s) => $s->value, self::cases());
    }

    public static function activeStatuses(): array
    {
        return [
            self::PENDING, self::CONFIRMED, self::APPROVED,
            self::IN_PROGRESS, self::DELIVERING_EQUIPMENT,
            self::EQUIPMENT_ARRIVED, self::DELIVERING_BODY,
            self::BODY_ARRIVED, self::SERVICE_ONGOING,
            self::BURIAL_PROCESS,
        ];
    }

    public static function completedStatuses(): array
    {
        return [self::COMPLETED, self::BURIAL_COMPLETED, self::POST_SERVICE];
    }

    public function label(): string
    {
        return match ($this) {
            self::PENDING => 'Menunggu',
            self::CONFIRMED => 'Dikonfirmasi',
            self::APPROVED => 'Disetujui',
            self::IN_PROGRESS => 'Sedang Berlangsung',
            self::COMPLETED => 'Selesai',
            self::CANCELLED => 'Dibatalkan',
            self::SO_REVIEW => 'Review SO',
            self::ADMIN_REVIEW => 'Review Admin',
            self::DELIVERING_EQUIPMENT => 'Pengiriman Peralatan',
            self::EQUIPMENT_ARRIVED => 'Peralatan Tiba',
            self::DELIVERING_BODY => 'Pengiriman Jenazah',
            self::BODY_ARRIVED => 'Jenazah Tiba',
            self::SERVICE_ONGOING => 'Layanan Berlangsung',
            self::BURIAL_PROCESS => 'Proses Pemakaman',
            self::BURIAL_COMPLETED => 'Pemakaman Selesai',
            self::POST_SERVICE => 'Pasca Layanan',
            self::PAYMENT_PENDING => 'Menunggu Pembayaran',
        };
    }
}
