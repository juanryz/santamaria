<?php

namespace App\Http\Controllers\Public;

use App\Http\Controllers\Controller;
use App\Models\Article;
use App\Services\StorageService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Public endpoints — no authentication required.
 * Read-only access to published articles for landing page & blog.
 */
class PublicArticleController extends Controller
{
    public function __construct(private readonly StorageService $storage) {}

    // GET /v1/public/articles
    public function index(Request $request): JsonResponse
    {
        $query = Article::published()
            ->with('author:id,name')
            ->select([
                'id', 'title', 'slug', 'excerpt', 'cover_image_path',
                'category', 'tags', 'published_at', 'author_id', 'is_featured', 'view_count',
            ]);

        if ($request->has('category')) {
            $query->byCategory($request->category);
        }

        if ($request->boolean('featured')) {
            $query->featured();
        }

        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('title', 'ilike', "%{$search}%")
                  ->orWhere('excerpt', 'ilike', "%{$search}%");
            });
        }

        $articles = $query->orderByDesc('published_at')
            ->paginate($request->input('per_page', 10));

        $articles->getCollection()->transform(function ($article) {
            $article->cover_image_url = $article->cover_image_path
                ? $this->storage->getSignedUrl($article->cover_image_path)
                : null;
            return $article;
        });

        return response()->json(['success' => true, 'data' => $articles]);
    }

    // GET /v1/public/articles/{slug}
    public function show(string $slug): JsonResponse
    {
        $article = Article::published()
            ->with('author:id,name')
            ->where('slug', $slug)
            ->firstOrFail();

        $article->increment('view_count');

        $article->cover_image_url = $article->cover_image_path
            ? $this->storage->getSignedUrl($article->cover_image_path)
            : null;

        return response()->json(['success' => true, 'data' => $article]);
    }

    // GET /v1/public/articles/categories
    public function categories(): JsonResponse
    {
        $categories = Article::published()
            ->select('category')
            ->distinct()
            ->orderBy('category')
            ->pluck('category');

        return response()->json(['success' => true, 'data' => $categories]);
    }
}
