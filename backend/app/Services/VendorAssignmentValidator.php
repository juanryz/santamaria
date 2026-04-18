<?php

namespace App\Services;

use App\Models\VendorRoleMaster;

/**
 * Validator untuk vendor assignment.
 *
 * Enforcement v1.40:
 * - Vendor dengan vendor_role_master.is_paid_by_sm = false → fee HARUS 0
 *   Contoh: pemuka_agama (keluarga bayar langsung ke pemuka agama, bukan via SM)
 * - Vendor pemuka_agama → source WAJIB 'external' (tidak ada internal SM lagi)
 */
class VendorAssignmentValidator
{
    /**
     * Normalisasi data vendor assignment sebelum save.
     *
     * Mutates input: jika role tidak dibayar SM, fee di-force 0.
     * Jika role pemuka_agama, source di-force 'external'.
     *
     * @param array $data raw input dari request
     * @return array $data sudah dinormalisasi
     * @throws \InvalidArgumentException jika role_id tidak valid
     */
    public function normalize(array $data): array
    {
        if (empty($data['vendor_role_id'])) {
            return $data;
        }

        $role = VendorRoleMaster::find($data['vendor_role_id']);
        if (! $role) {
            throw new \InvalidArgumentException(
                "Vendor role tidak ditemukan: {$data['vendor_role_id']}"
            );
        }

        // Rule 1: Jika role tidak dibayar SM → fee = 0
        if ($role->is_paid_by_sm === false) {
            $data['fee'] = 0;
        }

        // Rule 2: Pemuka agama → source WAJIB external (v1.40 koreksi)
        // Model booted() akan normalize source='internal' → 'external_consumer'.
        // Di sini kita juga set eksplisit supaya request payload konsisten.
        if ($role->role_code === 'pemuka_agama') {
            // Hormati source yang sudah external_consumer / external_so.
            // Kalau user kirim 'internal', ubah ke 'external_consumer' (default).
            if (($data['source'] ?? 'internal') === 'internal') {
                $data['source'] = 'external_consumer';
            }
            $data['user_id'] = null;
        }

        return $data;
    }

    /**
     * Cek apakah suatu vendor role dibayar oleh SM.
     */
    public function isPaidBySm(string $vendorRoleId): bool
    {
        $role = VendorRoleMaster::find($vendorRoleId);
        return $role?->is_paid_by_sm ?? true;
    }

    /**
     * Ringkasan aturan untuk UI (dipakai di tooltip / help text).
     */
    public function getRuleForRole(string $vendorRoleId): ?array
    {
        $role = VendorRoleMaster::find($vendorRoleId);
        if (! $role) {
            return null;
        }

        if ($role->is_paid_by_sm === false) {
            return [
                'enforced_fee' => 0,
                'message' => "{$role->role_name} tidak dibayar oleh SM. Keluarga bayar langsung.",
            ];
        }

        if ($role->role_code === 'pemuka_agama') {
            return [
                'enforced_source' => 'external_consumer',
                'enforced_fee' => 0,
                'message' => 'Pemuka agama selalu external (tidak ada internal SM). Keluarga bayar langsung.',
            ];
        }

        return null;
    }
}
