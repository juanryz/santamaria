<?php

namespace App\Http\Controllers\TukangFoto;

use App\Http\Controllers\Controller;
use App\Models\OrderGalleryLink;
use Illuminate\Http\Request;

class GalleryLinkController extends Controller
{
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
            'drive_url' => 'required|url|max:2048',
            'description' => 'nullable|string',
        ]);

        $link = OrderGalleryLink::create([
            'order_id' => $orderId,
            'uploaded_by' => $request->user()->id,
            'title' => $request->title,
            'drive_url' => $request->drive_url,
            'description' => $request->description,
            'link_type' => str_contains($request->drive_url, 'drive.google') ? 'google_drive' : 'other',
        ]);

        return $this->created($link, 'Link galeri berhasil ditambahkan');
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
