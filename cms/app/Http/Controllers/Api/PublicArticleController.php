<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Article;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PublicArticleController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $perPage = min((int) $request->input('per_page', 10), 50);

        $q = Article::query()->where('status', 'published');

        if ($request->filled('category')) {
            $q->where('category', $request->string('category'));
        }
        if ($request->filled('featured')) {
            $q->where('is_featured', $request->boolean('featured'));
        }
        if ($request->filled('search')) {
            $s = $request->string('search');
            $q->where(function ($w) use ($s) {
                $w->where('title', 'like', "%$s%")
                    ->orWhere('excerpt', 'like', "%$s%");
            });
        }

        $paginated = $q->orderByDesc('published_at')->paginate($perPage);

        return response()->json(['success' => true, 'data' => $paginated]);
    }

    public function show(string $slug): JsonResponse
    {
        $article = Article::where('slug', $slug)->where('status', 'published')->firstOrFail();
        $article->increment('view_count');

        return response()->json(['success' => true, 'data' => $article]);
    }

    public function categories(): JsonResponse
    {
        $categories = Article::where('status', 'published')
            ->select('category')
            ->distinct()
            ->pluck('category');

        return response()->json(['success' => true, 'data' => $categories]);
    }
}
