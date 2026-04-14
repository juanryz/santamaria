<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderPhoto;
use App\Services\StorageService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * CRM Dokumentasi Pasca Acara — Admin upload foto/video/link ke konsumen.
 *
 * Flow:
 *  1. GET /admin/documentation/orders           → list order in_progress & completed
 *  2. GET /admin/documentation/orders/{id}      → detail order + semua media
 *  3. POST /admin/documentation/orders/{id}/photos   → bulk file upload (multipart)
 *  4. POST /admin/documentation/orders/{id}/drive-link → lampirkan Google Drive / YouTube link
 *  5. DELETE /admin/documentation/photos/{photoId}   → hapus media
 *
 * Consumer melihat hasilnya via GET /consumer/orders/{id}/gallery
 */
class DocumentationController extends Controller
{
    public function __construct(private readonly StorageService $storage) {}

    // GET /admin/documentation/orders
    public function orders(Request $request): JsonResponse
    {
        $search = $request->query('search');

        $query = Order::with('pic:id,name,phone')
            ->whereIn('status', ['in_progress', 'completed'])
            ->orderByDesc('scheduled_at');

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('order_number', 'ilike', "%{$search}%")
                  ->orWhere('deceased_name', 'ilike', "%{$search}%");
            });
        }

        $orders = $query->paginate(20);

        // Append staff photo count to each order
        $orders->getCollection()->transform(function ($order) {
            $order->staff_media_count = OrderPhoto::where('order_id', $order->id)
                ->where('source', 'staff')
                ->count();
            return $order;
        });

        return response()->json(['success' => true, 'data' => $orders]);
    }

    // GET /admin/documentation/orders/{id}
    public function show(string $id): JsonResponse
    {
        $order = Order::with('pic:id,name,phone')->findOrFail($id);

        $media = OrderPhoto::where('order_id', $id)
            ->where('source', 'staff')
            ->orderByDesc('created_at')
            ->get()
            ->map(function ($p) {
                $p->url = $p->file_path
                    ? $this->storage->getSignedUrl($p->file_path)
                    : null;
                return $p;
            });

        return response()->json([
            'success' => true,
            'data'    => [
                'order' => $order->only([
                    'id', 'order_number', 'status', 'deceased_name', 'deceased_dod',
                    'deceased_religion', 'destination_address', 'scheduled_at', 'final_price',
                ]),
                'media' => $media,
                'total' => $media->count(),
            ],
        ]);
    }

    // POST /admin/documentation/orders/{id}/photos — bulk file upload
    public function uploadPhotos(Request $request, string $id): JsonResponse
    {
        $request->validate([
            'photos'          => 'required|array|min:1|max:30',
            'photos.*'        => 'required|file|mimetypes:image/jpeg,image/png,image/webp,image/gif,video/mp4,video/quicktime,video/webm|max:102400', // 100MB per file
            'category'        => 'nullable|in:almarhum,dokumentasi,lapangan',
            'caption'         => 'nullable|string|max:255',
        ]);

        $order = Order::findOrFail($id);

        $uploaded = [];

        DB::transaction(function () use ($request, $order, &$uploaded) {
            foreach ($request->file('photos') as $file) {
                $path = $this->storage->uploadOrderPhoto($file, $order->id);

                $photo = OrderPhoto::create([
                    'order_id'        => $order->id,
                    'uploaded_by'     => $request->user()->id,
                    'file_path'       => $path,
                    'file_name'       => $file->getClientOriginalName(),
                    'file_size_bytes' => $file->getSize(),
                    'file_type'       => $file->getMimeType(),
                    'category'        => $request->category ?? 'dokumentasi',
                    'source'          => 'staff',
                    'caption'         => $request->caption,
                ]);

                $photo->url = $this->storage->getSignedUrl($path);
                $uploaded[] = $photo;
            }
        });

        return response()->json([
            'success' => true,
            'data'    => $uploaded,
            'message' => count($uploaded) . ' file berhasil diunggah.',
        ], 201);
    }

    // POST /admin/documentation/orders/{id}/drive-link — lampirkan link eksternal
    public function attachDriveLink(Request $request, string $id): JsonResponse
    {
        $data = $request->validate([
            'drive_link' => 'required|url|max:2048',
            'caption'    => 'nullable|string|max:255',
            'category'   => 'nullable|in:almarhum,dokumentasi,lapangan',
        ]);

        $order = Order::findOrFail($id);

        $photo = OrderPhoto::create([
            'order_id'    => $order->id,
            'uploaded_by' => $request->user()->id,
            'file_path'   => null,
            'file_name'   => 'Link Eksternal',
            'file_type'   => 'link',
            'category'    => $data['category'] ?? 'dokumentasi',
            'source'      => 'staff',
            'drive_link'  => $data['drive_link'],
            'caption'     => $data['caption'] ?? null,
        ]);

        return response()->json([
            'success' => true,
            'data'    => $photo,
            'message' => 'Link berhasil dilampirkan.',
        ], 201);
    }

    // DELETE /admin/documentation/photos/{photoId}
    public function deletePhoto(string $photoId): JsonResponse
    {
        $photo = OrderPhoto::where('source', 'staff')->findOrFail($photoId);
        $photo->delete();

        return response()->json(['success' => true, 'message' => 'Media dihapus.']);
    }
}
