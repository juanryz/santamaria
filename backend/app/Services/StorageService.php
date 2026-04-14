<?php

namespace App\Services;

use App\Models\ConsumerStorageQuota;
use App\Models\SystemSetting;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class StorageService
{
    /**
     * Upload photo to Cloudflare R2.
     */
    public function uploadOrderPhoto(UploadedFile $file, string $orderId): string
    {
        $path = "orders/{$orderId}/photos/" . Str::uuid() . '.' . $file->extension();
        
        // Since we are in local development and R2 might not be set up yet, 
        // we check if R2 is configured, otherwise fallback to local 'public'
        $disk = config('filesystems.disks.r2.key') ? 'r2' : 'public';
        
        Storage::disk($disk)->put($path, file_get_contents($file->path()));
        
        return $path;
    }

    /**
     * Upload supplier quote product photo.
     * Replaces any previously stored photo for the same quote (1 photo per quote).
     */
    public function uploadQuotePhoto(UploadedFile $file, string $quoteId): string
    {
        $disk = config('filesystems.disks.r2.key') ? 'r2' : 'public';
        $path = "quotes/{$quoteId}/product." . $file->extension();

        // Delete previous photo if exists (overwrite — same path).
        Storage::disk($disk)->put($path, file_get_contents($file->path()));

        return $path;
    }

    /**
     * Generate a URL for a stored file.
     * On R2/S3 (cloud): returns a signed temporary URL valid for 24 hours.
     * On local public disk (dev): returns a plain public asset URL.
     */
    public function getSignedUrl(string $path): string
    {
        if (!config('filesystems.disks.r2.key')) {
            return asset("storage/{$path}");
        }

        /** @var \Illuminate\Filesystem\FilesystemAdapter $r2 */
        $r2 = Storage::disk('r2');
        return $r2->temporaryUrl($path, now()->addHours(24));
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
