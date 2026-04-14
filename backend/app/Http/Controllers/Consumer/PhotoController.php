<?php

namespace App\Http\Controllers\Consumer;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderPhoto;
use App\Models\ConsumerStorageQuota;
use App\Services\StorageService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PhotoController extends Controller
{
    protected $storageService;

    public function __construct(StorageService $storageService)
    {
        $this->storageService = $storageService;
    }

    public function store($orderId, Request $request)
    {
        $request->validate([
            'photo' => 'required|image|max:5120', // 5MB max
            'category' => 'nullable|in:almarhum,dokumentasi,lapangan',
            'file_name' => 'nullable|string'
        ]);

        $order = Order::where('id', $orderId)
            ->where('pic_user_id', $request->user()->id)
            ->firstOrFail();

        $file = $request->file('photo');
        $fileSize = $file->getSize();

        // 1. Check Quota
        if (!$this->storageService->checkAndUpdateQuota($request->user(), $fileSize)) {
            return response()->json([
                'success' => false,
                'message' => 'Penyimpanan penuh. Silakan upgrade atau hapus foto lain.'
            ], 403);
        }

        return DB::transaction(function () use ($order, $request, $file, $fileSize) {
            // 2. Upload to storage
            $path = $this->storageService->uploadOrderPhoto($file, $order->id);

            // 3. Create record
            $photo = OrderPhoto::create([
                'order_id' => $order->id,
                'uploaded_by' => $request->user()->id,
                'file_path' => $path,
                'file_name' => $request->file_name ?? $file->getClientOriginalName(),
                'file_size_bytes' => $fileSize,
                'file_type' => $file->getMimeType(),
                'category' => $request->category ?? 'almarhum',
            ]);

            // Update order metadata
            $order->increment('storage_used_bytes', $fileSize);

            return response()->json([
                'success' => true,
                'data' => array_merge($photo->toArray(), [
                    'url' => $this->storageService->getSignedUrl($path)
                ]),
                'message' => 'Foto berhasil diunggah'
            ]);
        });
    }

    public function destroy($orderId, $photoId, Request $request)
    {
        $photo = OrderPhoto::where('id', $photoId)
            ->where('order_id', $orderId)
            ->where('uploaded_by', $request->user()->id)
            ->firstOrFail();

        $order = Order::findOrFail($orderId);

        return DB::transaction(function () use ($photo, $order, $request) {
            $fileSize = $photo->file_size_bytes;

            // Revert quota
            $this->storageService->revertQuota($request->user(), $fileSize);
            
            // Update order
            $order->decrement('storage_used_bytes', $fileSize);

            // Delete record
            $photo->delete();

            // Note: Actual file deletion from R2 could be handled by a cleanup job or here
            // Storage::disk('r2')->delete($photo->file_path);

            return response()->json([
                'success' => true,
                'message' => 'Foto berhasil dihapus'
            ]);
        });
    }

    public function getQuota(Request $request)
    {
        $quota = ConsumerStorageQuota::where('user_id', $request->user()->id)->first();
        
        return response()->json([
            'success' => true,
            'data' => [
                'used_bytes' => $quota ? $quota->used_bytes : 0,
                'quota_bytes' => $quota ? $quota->quota_bytes : (1024 * 1024 * 1024)
            ]
        ]);
    }
}
