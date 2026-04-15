<?php

namespace App\Http\Controllers\Driver;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderBuktiLapangan;
use App\Services\StorageService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BuktiController extends Controller
{
    // POST /driver/orders/{id}/bukti
    public function store(Request $request, string $id): JsonResponse
    {
        $data = $request->validate([
            'bukti_type' => 'required|in:penjemputan,tiba_tujuan,lainnya',
            'photo'      => 'required|file|mimes:jpg,jpeg,png|max:15360',
            'notes'      => 'nullable|string',
        ]);

        $order = Order::where('driver_id', $request->user()->id)->findOrFail($id);

        $path = StorageService::upload(
            $request->file('photo'),
            "bukti_lapangan/{$order->id}/driver"
        );

        $fileSize = $request->file('photo')->getSize();

        $bukti = OrderBuktiLapangan::create([
            'order_id'        => $order->id,
            'uploaded_by'     => $request->user()->id,
            'role'            => UserRole::DRIVER->value,
            'bukti_type'      => $data['bukti_type'],
            'file_path'       => $path,
            'file_size_bytes' => $fileSize,
            'notes'           => $data['notes'] ?? null,
            'created_at'      => now(),
        ]);

        return response()->json(['message' => 'Bukti berhasil diunggah.', 'data' => $bukti], 201);
    }

    // GET /driver/orders/{id}/bukti
    public function index(Request $request, string $id): JsonResponse
    {
        Order::where('driver_id', $request->user()->id)->findOrFail($id);

        $bukti = OrderBuktiLapangan::where('order_id', $id)
            ->where('role', UserRole::DRIVER->value)
            ->get()
            ->map(function ($b) {
                $b->url = StorageService::getSignedUrl($b->file_path);
                return $b;
            });

        return response()->json($bukti);
    }
}
