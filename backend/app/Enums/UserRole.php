<?php

namespace App\Enums;

enum UserRole: string
{
    case SUPER_ADMIN = 'super_admin';
    case CONSUMER = 'consumer';
    case SERVICE_OFFICER = 'service_officer';
    case ADMIN = 'admin';
    case GUDANG = 'gudang';
    case FINANCE = 'finance';
    case DRIVER = 'driver';
    case DEKOR = 'dekor';
    case KONSUMSI = 'konsumsi';
    case SUPPLIER = 'supplier';
    case OWNER = 'owner';
    case PEMUKA_AGAMA = 'pemuka_agama';
    case HRD = 'hrd';
    case PURCHASING = 'purchasing';
    case VIEWER = 'viewer';
    case TUKANG_FOTO = 'tukang_foto';
    case TUKANG_ANGKAT_PETI = 'tukang_angkat_peti';
    case TUKANG_JAGA = 'tukang_jaga';

    public static function values(): array
    {
        return array_map(fn(self $role) => $role->value, self::cases());
    }

    public static function vendorValues(): array
    {
        return array_map(fn(self $role) => $role->value, self::vendor());
    }

    public static function vendor(): array
    {
        return [
            self::DEKOR,
            self::KONSUMSI,
            self::SUPPLIER,
            self::PEMUKA_AGAMA,
            self::TUKANG_FOTO,
            self::TUKANG_ANGKAT_PETI,
        ];
    }

    public static function viewerValues(): array
    {
        return array_map(fn(self $role) => $role->value, self::viewer());
    }

    public static function viewer(): array
    {
        return [self::VIEWER];
    }

    public static function activeValues(): array
    {
        return array_values(array_filter(self::values(), fn(string $value) => !in_array($value, self::viewerValues(), true)));
    }
}

