<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Article;
use App\Services\StorageService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

/**
 * CRUD Artikel / Blog — dikelola oleh Super Admin & Service Officer.
 */
class ArticleController extends Controller
{
    public function __construct(private readonly StorageService $storage) {}

    // GET /v1/admin/articles
    public function index(Request $request): JsonResponse
    {
        $query = Article::with('author:id,name')
            ->select([
                'id', 'title', 'slug', 'excerpt', 'category', 'status',
                'published_at', 'author_id', 'is_featured', 'view_count', 'created_at',
            ]);

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        if ($request->has('category')) {
            $query->where('category', $request->category);
        }

        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('title', 'ilike', "%{$search}%")
                  ->orWhere('excerpt', 'ilike', "%{$search}%");
            });
        }

        $articles = $query->orderByDesc('created_at')
            ->paginate($request->input('per_page', 15));

        return response()->json(['success' => true, 'data' => $articles]);
    }

    // GET /v1/admin/articles/{id}
    public function show(string $id): JsonResponse
    {
        $article = Article::with('author:id,name')->findOrFail($id);

        $article->cover_image_url = $article->cover_image_path
            ? $this->storage->getSignedUrl($article->cover_image_path)
            : null;

        return response()->json(['success' => true, 'data' => $article]);
    }

    // POST /v1/admin/articles
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'title'            => 'required|string|max:255',
            'excerpt'          => 'nullable|string|max:500',
            'body'             => 'required|string',
            'category'         => 'nullable|string|max:100',
            'tags'             => 'nullable|array',
            'tags.*'           => 'string|max:50',
            'status'           => 'nullable|in:draft,published',
            'is_featured'      => 'nullable|boolean',
            'meta_title'       => 'nullable|string|max:255',
            'meta_description' => 'nullable|string|max:500',
        ]);

        $validated['author_id'] = $request->user()->id;
        $validated['slug'] = Str::slug($validated['title']) . '-' . Str::random(6);

        if (($validated['status'] ?? 'draft') === 'published') {
            $validated['published_at'] = now();
        }

        $article = Article::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'Artikel berhasil dibuat.',
            'data'    => $article,
        ], 201);
    }

    // PUT /v1/admin/articles/{id}
    public function update(Request $request, string $id): JsonResponse
    {
        $article = Article::findOrFail($id);

        $validated = $request->validate([
            'title'            => 'sometimes|string|max:255',
            'excerpt'          => 'nullable|string|max:500',
            'body'             => 'sometimes|string',
            'category'         => 'nullable|string|max:100',
            'tags'             => 'nullable|array',
            'tags.*'           => 'string|max:50',
            'status'           => 'nullable|in:draft,published,archived',
            'is_featured'      => 'nullable|boolean',
            'meta_title'       => 'nullable|string|max:255',
            'meta_description' => 'nullable|string|max:500',
        ]);

        // Auto-set published_at saat pertama kali dipublish
        if (
            isset($validated['status']) &&
            $validated['status'] === 'published' &&
            $article->status !== 'published'
        ) {
            $validated['published_at'] = now();
        }

        $article->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Artikel berhasil diperbarui.',
            'data'    => $article->fresh(),
        ]);
    }

    // POST /v1/admin/articles/{id}/cover
    public function uploadCover(Request $request, string $id): JsonResponse
    {
        $article = Article::findOrFail($id);

        $request->validate([
            'cover_image' => 'required|image|max:5120', // max 5MB
        ]);

        // v1.40: upload via StorageService → R2 (resolve disk via env).
        $file = $request->file('cover_image');
        $path = $this->storage->putPhoto(
            $file,
            "articles/{$article->id}/cover/" . uniqid('cover_') . '.' . $file->extension()
        );

        // Hapus cover lama jika ada
        if ($article->cover_image_path) {
            $this->storage->delete($article->cover_image_path);
        }

        $article->update(['cover_image_path' => $path]);

        return response()->json([
            'success' => true,
            'message' => 'Cover berhasil diupload.',
            'data'    => [
                'cover_image_path' => $path,
                'cover_image_url'  => $this->storage->getSignedUrl($path),
            ],
        ]);
    }

    // DELETE /v1/admin/articles/{id}
    public function destroy(string $id): JsonResponse
    {
        $article = Article::findOrFail($id);
        $article->delete(); // soft delete

        return response()->json([
            'success' => true,
            'message' => 'Artikel berhasil dihapus.',
        ]);
    }
}
