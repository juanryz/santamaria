<?php

namespace App\Enums;

/**
 * Semua tipe pelanggaran — referensi ke hrd_violations.violation_type.
 * TIDAK BOLEH di-hardcode sebagai string di controller/command.
 */
enum ViolationType: string
{
    case DRIVER_OVERTIME = 'driver_overtime';
    case SO_LATE_PROCESSING = 'so_late_processing';
    case VENDOR_REPEATED_REJECT = 'vendor_repeated_reject';
    case VENDOR_NO_SHOW = 'vendor_no_show';
    case FINANCE_LATE_PAYMENT = 'finance_late_payment';
    case LATE_BUKTI_UPLOAD = 'late_bukti_upload';
    case VENDOR_ATTENDANCE_LATE = 'vendor_attendance_late';
    case EQUIPMENT_NOT_RETURNED = 'equipment_not_returned';
    case COFFIN_QC_OVERDUE = 'coffin_qc_overdue';
    case DEATH_CERT_NOT_SUBMITTED = 'death_cert_not_submitted';

    public static function values(): array
    {
        return array_map(fn(self $v) => $v->value, self::cases());
    }

    public function label(): string
    {
        return match ($this) {
            self::DRIVER_OVERTIME => 'Driver Overtime',
            self::SO_LATE_PROCESSING => 'SO Terlambat Proses',
            self::VENDOR_REPEATED_REJECT => 'Vendor Berulang Kali Menolak',
            self::VENDOR_NO_SHOW => 'Vendor Tidak Hadir',
            self::FINANCE_LATE_PAYMENT => 'Finance Terlambat Bayar',
            self::LATE_BUKTI_UPLOAD => 'Terlambat Upload Bukti',
            self::VENDOR_ATTENDANCE_LATE => 'Vendor Terlambat Hadir',
            self::EQUIPMENT_NOT_RETURNED => 'Peralatan Belum Kembali',
            self::COFFIN_QC_OVERDUE => 'QC Peti Terlambat',
            self::DEATH_CERT_NOT_SUBMITTED => 'Berkas Akta Belum Dibuat',
        };
    }

    public function severity(): string
    {
        return match ($this) {
            self::DRIVER_OVERTIME, self::VENDOR_NO_SHOW => 'high',
            self::EQUIPMENT_NOT_RETURNED, self::VENDOR_ATTENDANCE_LATE => 'high',
            self::SO_LATE_PROCESSING, self::FINANCE_LATE_PAYMENT => 'medium',
            self::COFFIN_QC_OVERDUE, self::DEATH_CERT_NOT_SUBMITTED => 'medium',
            self::VENDOR_REPEATED_REJECT => 'high',
            self::LATE_BUKTI_UPLOAD => 'low',
        };
    }

    public function thresholdKey(): string
    {
        return match ($this) {
            self::DRIVER_OVERTIME => 'driver_max_duty_hours',
            self::SO_LATE_PROCESSING => 'so_max_processing_minutes',
            self::VENDOR_REPEATED_REJECT => 'vendor_max_reject_count_monthly',
            self::FINANCE_LATE_PAYMENT => 'payment_verify_deadline_hours',
            self::LATE_BUKTI_UPLOAD => 'bukti_upload_deadline_hours',
            self::VENDOR_ATTENDANCE_LATE => 'attendance_late_threshold_minutes',
            self::EQUIPMENT_NOT_RETURNED => 'equipment_return_deadline_hours',
            self::COFFIN_QC_OVERDUE => 'coffin_qc_deadline_hours',
            self::DEATH_CERT_NOT_SUBMITTED => 'death_cert_deadline_hours',
            default => '',
        };
    }
}
