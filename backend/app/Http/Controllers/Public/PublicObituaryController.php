<?php

namespace App\Http\Controllers\Public;

use App\Http\Controllers\Controller;
use App\Models\Obituary;
use App\Services\StorageService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Public endpoints — no authentication required.
 * Read-only access to published obituaries (berita duka).
 */
class PublicObituaryController extends Controller
{
    public function __construct(private readonly StorageService $storage) {}

    // GET /v1/public/obituaries
    public function index(Request $request): JsonResponse
    {
        $query = Obituary::published()
            ->select([
                'id', 'slug', 'deceased_name', 'deceased_nickname', 'deceased_dod',
                'deceased_religion', 'deceased_photo_path', 'deceased_age',
                'funeral_location', 'funeral_datetime', 'funeral_address',
                'cemetery_name', 'family_message', 'published_at', 'is_featured',
            ]);

        if ($request->boolean('featured')) {
            $query->featured();
        }

        if ($request->has('search')) {
            $query->where('deceased_name', 'ilike', "%{$request->search}%");
        }

        $obituaries = $query->recent()
            ->paginate($request->input('per_page', 12));

        $obituaries->getCollection()->transform(function ($obit) {
            $obit->deceased_photo_url = $obit->deceased_photo_path
                ? $this->storage->getSignedUrl($obit->deceased_photo_path)
                : null;
            return $obit;
        });

        return response()->json(['success' => true, 'data' => $obituaries]);
    }

    // GET /v1/public/obituaries/{slug}
    public function show(string $slug): JsonResponse
    {
        $obituary = Obituary::published()
            ->where('slug', $slug)
            ->firstOrFail();

        $obituary->increment('view_count');

        $obituary->deceased_photo_url = $obituary->deceased_photo_path
            ? $this->storage->getSignedUrl($obituary->deceased_photo_path)
            : null;

        return response()->json(['success' => true, 'data' => $obituary]);
    }
}
