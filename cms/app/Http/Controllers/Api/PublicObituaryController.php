<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Obituary;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PublicObituaryController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $perPage = min((int) $request->input('per_page', 10), 50);

        $q = Obituary::query()->where('status', 'published');

        if ($request->filled('featured')) {
            $q->where('is_featured', $request->boolean('featured'));
        }
        if ($request->filled('search')) {
            $s = $request->string('search');
            $q->where(function ($w) use ($s) {
                $w->where('deceased_name', 'like', "%$s%")
                    ->orWhere('deceased_nickname', 'like', "%$s%");
            });
        }

        $paginated = $q->orderByDesc('published_at')->paginate($perPage);

        return response()->json(['success' => true, 'data' => $paginated]);
    }

    public function show(string $slug): JsonResponse
    {
        $o = Obituary::where('slug', $slug)->where('status', 'published')->firstOrFail();
        $o->increment('view_count');

        return response()->json(['success' => true, 'data' => $o]);
    }
}
