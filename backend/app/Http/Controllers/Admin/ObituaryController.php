<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Obituary;
use App\Services\StorageService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

/**
 * CRUD Berita Duka / Pengumuman Kematian — dikelola oleh Super Admin & Service Officer.
 */
class ObituaryController extends Controller
{
    public function __construct(private readonly StorageService $storage) {}

    // GET /v1/admin/obituaries
    public function index(Request $request): JsonResponse
    {
        $query = Obituary::with('creator:id,name')
            ->select([
                'id', 'slug', 'deceased_name', 'deceased_dod', 'deceased_religion',
                'deceased_age', 'funeral_location', 'funeral_datetime',
                'status', 'published_at', 'is_featured', 'view_count',
                'created_by', 'created_at',
            ]);

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        if ($request->has('search')) {
            $query->where('deceased_name', 'ilike', "%{$request->search}%");
        }

        $obituaries = $query->orderByDesc('created_at')
            ->paginate($request->input('per_page', 15));

        return response()->json(['success' => true, 'data' => $obituaries]);
    }

    // GET /v1/admin/obituaries/{id}
    public function show(string $id): JsonResponse
    {
        $obituary = Obituary::with(['creator:id,name', 'order:id,order_number,deceased_name'])
            ->findOrFail($id);

        $obituary->deceased_photo_url = $obituary->deceased_photo_path
            ? $this->storage->getSignedUrl($obituary->deceased_photo_path)
            : null;

        return response()->json(['success' => true, 'data' => $obituary]);
    }

    // POST /v1/admin/obituaries
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'deceased_name'         => 'required|string|max:255',
            'deceased_nickname'     => 'nullable|string|max:100',
            'deceased_dob'          => 'nullable|date',
            'deceased_dod'          => 'required|date',
            'deceased_place_of_birth' => 'nullable|string|max:255',
            'deceased_religion'     => 'nullable|string|max:50',
            'family_contact_name'   => 'nullable|string|max:255',
            'family_contact_phone'  => 'nullable|string|max:20',
            'family_message'        => 'nullable|string|max:2000',
            'survived_by'           => 'nullable|string|max:1000',
            'funeral_location'      => 'nullable|string|max:255',
            'funeral_datetime'      => 'nullable|date',
            'funeral_address'       => 'nullable|string|max:500',
            'cemetery_name'         => 'nullable|string|max:255',
            'prayer_location'       => 'nullable|string|max:255',
            'prayer_datetime'       => 'nullable|date',
            'prayer_notes'          => 'nullable|string|max:1000',
            'order_id'              => 'nullable|uuid|exists:orders,id',
            'status'                => 'nullable|in:draft,published',
            'is_featured'           => 'nullable|boolean',
            'meta_title'            => 'nullable|string|max:255',
            'meta_description'      => 'nullable|string|max:500',
        ]);

        $validated['created_by'] = $request->user()->id;
        $validated['slug'] = Str::slug($validated['deceased_name'] . '-' . $validated['deceased_dod']) . '-' . Str::random(6);

        if ($validated['deceased_dob'] ?? false) {
            $validated['deceased_age'] = \Carbon\Carbon::parse($validated['deceased_dob'])
                ->diffInYears(\Carbon\Carbon::parse($validated['deceased_dod']));
        }

        if (($validated['status'] ?? 'draft') === 'published') {
            $validated['published_at'] = now();
        }

        $obituary = Obituary::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'Berita duka berhasil dibuat.',
            'data'    => $obituary,
        ], 201);
    }

    // PUT /v1/admin/obituaries/{id}
    public function update(Request $request, string $id): JsonResponse
    {
        $obituary = Obituary::findOrFail($id);

        $validated = $request->validate([
            'deceased_name'         => 'sometimes|string|max:255',
            'deceased_nickname'     => 'nullable|string|max:100',
            'deceased_dob'          => 'nullable|date',
            'deceased_dod'          => 'sometimes|date',
            'deceased_place_of_birth' => 'nullable|string|max:255',
            'deceased_religion'     => 'nullable|string|max:50',
            'family_contact_name'   => 'nullable|string|max:255',
            'family_contact_phone'  => 'nullable|string|max:20',
            'family_message'        => 'nullable|string|max:2000',
            'survived_by'           => 'nullable|string|max:1000',
            'funeral_location'      => 'nullable|string|max:255',
            'funeral_datetime'      => 'nullable|date',
            'funeral_address'       => 'nullable|string|max:500',
            'cemetery_name'         => 'nullable|string|max:255',
            'prayer_location'       => 'nullable|string|max:255',
            'prayer_datetime'       => 'nullable|date',
            'prayer_notes'          => 'nullable|string|max:1000',
            'order_id'              => 'nullable|uuid|exists:orders,id',
            'status'                => 'nullable|in:draft,published,archived',
            'is_featured'           => 'nullable|boolean',
            'meta_title'            => 'nullable|string|max:255',
            'meta_description'      => 'nullable|string|max:500',
        ]);

        if (
            isset($validated['status']) &&
            $validated['status'] === 'published' &&
            $obituary->status !== 'published'
        ) {
            $validated['published_at'] = now();
        }

        // Recalculate age jika DOB/DOD berubah
        $dob = $validated['deceased_dob'] ?? $obituary->deceased_dob;
        $dod = $validated['deceased_dod'] ?? $obituary->deceased_dod;
        if ($dob && $dod) {
            $validated['deceased_age'] = \Carbon\Carbon::parse($dob)->diffInYears(\Carbon\Carbon::parse($dod));
        }

        $obituary->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Berita duka berhasil diperbarui.',
            'data'    => $obituary->fresh(),
        ]);
    }

    // POST /v1/admin/obituaries/{id}/photo
    public function uploadPhoto(Request $request, string $id): JsonResponse
    {
        $obituary = Obituary::findOrFail($id);

        $request->validate([
            'photo' => 'required|image|max:5120', // max 5MB
        ]);

        $path = $request->file('photo')
            ->store("obituaries/{$obituary->id}/photo", 's3');

        if ($obituary->deceased_photo_path) {
            $this->storage->delete($obituary->deceased_photo_path);
        }

        $obituary->update(['deceased_photo_path' => $path]);

        return response()->json([
            'success' => true,
            'message' => 'Foto almarhum berhasil diupload.',
            'data'    => [
                'deceased_photo_path' => $path,
                'deceased_photo_url'  => $this->storage->getSignedUrl($path),
            ],
        ]);
    }

    // POST /v1/admin/obituaries/from-order/{orderId}
    public function createFromOrder(Request $request, string $orderId): JsonResponse
    {
        $order = \App\Models\Order::findOrFail($orderId);

        // Cek apakah sudah ada obituary untuk order ini
        $existing = Obituary::where('order_id', $orderId)->first();
        if ($existing) {
            return response()->json([
                'success' => false,
                'message' => 'Berita duka untuk order ini sudah ada.',
                'data'    => $existing,
            ], 409);
        }

        // Ambil foto almarhum dari order photos
        $photo = \App\Models\OrderPhoto::where('order_id', $orderId)
            ->where('category', 'almarhum')
            ->whereNotNull('file_path')
            ->oldest('created_at')
            ->first();

        $obituary = Obituary::create([
            'deceased_name'     => $order->deceased_name,
            'deceased_dob'      => $order->deceased_dob,
            'deceased_dod'      => $order->deceased_dod,
            'deceased_religion' => $order->deceased_religion,
            'deceased_photo_path' => $photo?->file_path,
            'deceased_age'      => $order->deceased_dob && $order->deceased_dod
                ? \Carbon\Carbon::parse($order->deceased_dob)->diffInYears(\Carbon\Carbon::parse($order->deceased_dod))
                : null,
            'funeral_location'  => $order->destination_name ?? null,
            'funeral_address'   => $order->destination_address ?? null,
            'family_contact_name'  => $order->pic_name,
            'family_contact_phone' => $order->pic_phone,
            'order_id'          => $orderId,
            'created_by'        => $request->user()->id,
            'status'            => 'draft',
            'slug'              => Str::slug($order->deceased_name . '-' . $order->deceased_dod) . '-' . Str::random(6),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Berita duka berhasil dibuat dari data order.',
            'data'    => $obituary,
        ], 201);
    }

    // DELETE /v1/admin/obituaries/{id}
    public function destroy(string $id): JsonResponse
    {
        $obituary = Obituary::findOrFail($id);
        $obituary->delete(); // soft delete

        return response()->json([
            'success' => true,
            'message' => 'Berita duka berhasil dihapus.',
        ]);
    }
}
