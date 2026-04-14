<?php

namespace App\Http\Controllers\Consumer;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderPhoto;
use App\Services\StorageService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Gallery & Berita Duka — yang dapat dilihat oleh konsumen.
 */
class GalleryController extends Controller
{
    public function __construct(private readonly StorageService $storage) {}

    // GET /consumer/orders/{id}/gallery
    // Returns staff-uploaded photos + drive links for this order
    public function gallery(Request $request, string $id): JsonResponse
    {
        // Verify order belongs to this consumer
        $order = Order::where('id', $id)
            ->where('pic_user_id', $request->user()->id)
            ->firstOrFail();

        $media = OrderPhoto::where('order_id', $id)
            ->where('source', 'staff')
            ->orderByDesc('created_at')
            ->get()
            ->map(function ($p) {
                $p->url = ($p->file_path && $p->file_type !== 'link')
                    ? $this->storage->getSignedUrl($p->file_path)
                    : null;
                return $p;
            });

        return response()->json([
            'success' => true,
            'data'    => [
                'order' => $order->only([
                    'id', 'order_number', 'status', 'deceased_name', 'deceased_dod',
                    'deceased_religion', 'destination_address', 'scheduled_at',
                ]),
                'media' => $media,
                'has_media' => $media->isNotEmpty(),
            ],
        ]);
    }

    // GET /consumer/orders/{id}/obituary
    // Returns order data used to render the berita duka card client-side
    public function obituary(Request $request, string $id): JsonResponse
    {
        $order = Order::where('id', $id)
            ->where('pic_user_id', $request->user()->id)
            ->firstOrFail();

        // Get first 'almarhum' photo (for display in card)
        $photo = OrderPhoto::where('order_id', $id)
            ->where('category', 'almarhum')
            ->whereNotNull('file_path')
            ->oldest('created_at')
            ->first();

        $photoUrl = $photo ? $this->storage->getSignedUrl($photo->file_path) : null;

        return response()->json([
            'success' => true,
            'data'    => [
                'deceased_name'     => $order->deceased_name,
                'deceased_dod'      => $order->deceased_dod,
                'deceased_religion' => $order->deceased_religion,
                'destination'       => $order->destination_address,
                'photo_url'         => $photoUrl,
                'order_number'      => $order->order_number,
            ],
        ]);
    }
}
