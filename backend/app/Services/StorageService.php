<?php

namespace App\Services;

use App\Models\ConsumerStorageQuota;
use App\Models\SystemSetting;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

/**
 * File storage service — target utama Cloudflare R2 (production).
 * Fallback ke disk 'public' kalau R2 belum dikonfigurasi (dev/local).
 *
 * Disk resolution urutan:
 *   1. env(FILESYSTEM_DISK) kalau di-set eksplisit
 *   2. 'r2' kalau R2_ACCESS_KEY_ID terisi
 *   3. 'public' sebagai fallback aman
 *
 * Untuk kompresi foto: dilakukan di sisi Flutter (flutter_image_compress)
 * sebelum upload. Backend hanya validate size cap.
 */
class StorageService
{
    /**
     * Max file size per upload (MB). Bisa di-override per context.
     */
    private const MAX_FILE_MB = 10;

    /**
     * Resolve disk yang dipakai untuk upload.
     * Prioritas: env > r2 (kalau configured) > public.
     */
    public function resolveDisk(): string
    {
        $envDisk = env('FILESYSTEM_DISK');
        if ($envDisk && $envDisk !== 'local' && config("filesystems.disks.{$envDisk}")) {
            return $envDisk;
        }

        // R2 configured?
        if (config('filesystems.disks.r2.key')) {
            return 'r2';
        }

        // Fallback dev
        return 'public';
    }

    /**
     * Upload photo to active disk.
     *
     * @param UploadedFile $file
     * @param string       $path  Target path (tanpa leading slash)
     * @return string Final path yang disimpan di disk
     * @throws \RuntimeException Kalau file size melewati limit
     */
    public function putPhoto(UploadedFile $file, string $path): string
    {
        $this->assertSize($file);

        $disk = $this->resolveDisk();
        Storage::disk($disk)->put($path, file_get_contents($file->path()));
        return $path;
    }

    /**
     * Upload photo utk order (generic — bukti lapangan, dll).
     */
    public function uploadOrderPhoto(UploadedFile $file, string $orderId): string
    {
        $path = "orders/{$orderId}/photos/" . Str::uuid() . '.' . $file->extension();
        return $this->putPhoto($file, $path);
    }

    /**
     * Upload photo_evidences (v1.35) — bukti universal dengan geofencing.
     */
    public function uploadPhotoEvidence(UploadedFile $file, string $context, ?string $orderId = null): string
    {
        $folder = $orderId ? "orders/{$orderId}/evidences/{$context}" : "evidences/{$context}";
        $path = "{$folder}/" . now()->format('YmdHis') . '_' . Str::random(8) . '.' . $file->extension();
        return $this->putPhoto($file, $path);
    }

    /**
     * Upload selfie presensi (foto kecil, biasanya < 1 MB karena sudah compressed client).
     */
    public function uploadAttendanceSelfie(UploadedFile $file, string $userId): string
    {
        $path = "attendance/{$userId}/" . now()->format('Y/m/d') . '/' . Str::uuid() . '.' . $file->extension();
        return $this->putPhoto($file, $path);
    }

    /**
     * Upload dokumen consumer (KTP, KK, bukti bayar).
     */
    public function uploadConsumerDoc(UploadedFile $file, string $orderId, string $docType): string
    {
        $path = "orders/{$orderId}/docs/{$docType}." . $file->extension();
        return $this->putPhoto($file, $path);
    }

    /**
     * Upload supplier quote product photo.
     * Replaces any previously stored photo for the same quote (1 photo per quote).
     */
    public function uploadQuotePhoto(UploadedFile $file, string $quoteId): string
    {
        $path = "quotes/{$quoteId}/product." . $file->extension();
        return $this->putPhoto($file, $path);
    }

    /**
     * Delete file dari disk aktif.
     */
    public function delete(string $path): bool
    {
        $disk = $this->resolveDisk();
        if (! Storage::disk($disk)->exists($path)) {
            return false;
        }
        return Storage::disk($disk)->delete($path);
    }

    /**
     * Generate a URL for a stored file.
     * On R2/S3 (cloud): returns a signed temporary URL valid for 24 hours.
     * On local public disk (dev): returns a plain public asset URL.
     */
    public function getSignedUrl(string $path): string
    {
        $disk = $this->resolveDisk();

        if ($disk === 'public' || $disk === 'local') {
            return asset("storage/{$path}");
        }

        /** @var \Illuminate\Filesystem\FilesystemAdapter $storage */
        $storage = Storage::disk($disk);
        return $storage->temporaryUrl($path, now()->addHours(24));
    }

    /**
     * Get direct public URL (tanpa signed). Untuk file public di R2 dengan custom domain.
     * Fallback ke signed URL kalau tidak available.
     */
    public function getPublicUrl(string $path): string
    {
        $disk = $this->resolveDisk();
        $publicUrl = config("filesystems.disks.{$disk}.url");

        if ($publicUrl) {
            return rtrim($publicUrl, '/') . '/' . ltrim($path, '/');
        }

        return $this->getSignedUrl($path);
    }

    /**
     * Validate file size — throw kalau melewati cap.
     */
    private function assertSize(UploadedFile $file): void
    {
        $maxBytes = self::MAX_FILE_MB * 1024 * 1024;
        if ($file->getSize() > $maxBytes) {
            throw new \RuntimeException(
                "File terlalu besar (max " . self::MAX_FILE_MB . "MB). "
                . "Kompres foto di Flutter sebelum upload."
            );
        }
    }

    /**
     * Check and update consumer storage quota.
     * Returns true if quota is sufficient, false otherwise.
     */
    public function checkAndUpdateQuota(User $consumer, int $fileSizeBytes): bool
    {
        $quotaGb = (int) SystemSetting::getValue('consumer_storage_quota_gb', 1);
        $quota = ConsumerStorageQuota::firstOrCreate(
            ['user_id' => $consumer->id],
            ['quota_bytes' => $quotaGb * 1024 * 1024 * 1024]
        );

        if ($quota->used_bytes + $fileSizeBytes > $quota->quota_bytes) {
            return false;
        }

        $quota->increment('used_bytes', $fileSizeBytes);
        return true;
    }

    /**
     * Revert quota when a file is deleted.
     */
    public function revertQuota(User $consumer, int $fileSizeBytes): void
    {
        $quota = ConsumerStorageQuota::where('user_id', $consumer->id)->first();
        if ($quota) {
            $quota->decrement('used_bytes', min($quota->used_bytes, $fileSizeBytes));
        }
    }
}
