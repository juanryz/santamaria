<?php

namespace App\Http\Controllers\TukangFoto;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderGalleryLink;
use Illuminate\Http\Request;

class GalleryLinkController extends Controller
{
    /**
     * Gallery link deadline: 3 hours after order completed.
     */
    private const DEADLINE_HOURS = 3;

    public function index(Request $request, string $orderId)
    {
        $links = OrderGalleryLink::where('order_id', $orderId)
            ->with('uploader:id,name')
            ->orderBy('created_at', 'desc')
            ->get();

        return $this->success($links);
    }

    public function store(Request $request, string $orderId)
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'drive_url' => [
                'required',
                'url',
                'max:2048',
                function (string $attribute, mixed $value, \Closure $fail) {
                    if (! str_contains($value, 'drive.google.com')) {
                        $fail('URL harus berupa link Google Drive (mengandung drive.google.com).');
                    }
                },
            ],
            'description' => 'nullable|string',
        ]);

        $order = Order::findOrFail($orderId);

        // Determine if submission is late (> 3 hours after order completed)
        $isLate = false;
        if ($order->completed_at) {
            $deadline = $order->completed_at->copy()->addHours(self::DEADLINE_HOURS);
            $isLate = now()->greaterThan($deadline);
        }

        $link = OrderGalleryLink::create([
            'order_id' => $orderId,
            'uploaded_by' => $request->user()->id,
            'title' => $request->title,
            'drive_url' => $request->drive_url,
            'description' => $request->description,
            'link_type' => 'google_drive',
        ]);

        return $this->created([
            'link' => $link,
            'is_late' => $isLate,
            'deadline' => $order->completed_at
                ? $order->completed_at->copy()->addHours(self::DEADLINE_HOURS)->toIso8601String()
                : null,
        ], $isLate
            ? 'Link galeri berhasil ditambahkan (terlambat dari deadline ' . self::DEADLINE_HOURS . ' jam)'
            : 'Link galeri berhasil ditambahkan'
        );
    }

    /**
     * Consumer endpoint: only returns links if payment is confirmed.
     */
    public function consumerIndex(Request $request, string $orderId)
    {
        $order = Order::findOrFail($orderId);

        if (! in_array($order->payment_status, ['paid', 'verified'])) {
            return $this->error('Link galeri hanya tersedia setelah pembayaran dikonfirmasi.', 403);
        }

        $links = OrderGalleryLink::where('order_id', $orderId)
            ->with('uploader:id,name')
            ->orderBy('created_at', 'desc')
            ->get();

        return $this->success($links);
    }

    public function destroy(Request $request, string $orderId, string $id)
    {
        $link = OrderGalleryLink::where('order_id', $orderId)
            ->where('uploaded_by', $request->user()->id)
            ->findOrFail($id);

        $link->delete();
        return $this->success(null, 'Link dihapus');
    }
}
