<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Article;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\View\View;

class ArticleController extends Controller
{
    public function index(): View
    {
        $articles = Article::with('author')->latest()->paginate(15);
        return view('admin.articles.index', compact('articles'));
    }

    public function create(): View
    {
        return view('admin.articles.create');
    }

    public function store(Request $request): RedirectResponse
    {
        $data = $this->validateData($request);
        $data['author_id'] = $request->user()->id;

        if ($request->hasFile('cover')) {
            $data['cover_image_path'] = $request->file('cover')->store('articles', 'public');
        }

        if (($data['status'] ?? 'draft') === 'published' && empty($data['published_at'])) {
            $data['published_at'] = now();
        }

        Article::create($data);

        return redirect('/articles')->with('status', 'Artikel berhasil dibuat.');
    }

    public function edit(string $id): View
    {
        $article = Article::findOrFail($id);
        return view('admin.articles.edit', compact('article'));
    }

    public function update(Request $request, string $id): RedirectResponse
    {
        $article = Article::findOrFail($id);
        $data = $this->validateData($request);

        if ($request->hasFile('cover')) {
            if ($article->cover_image_path) {
                Storage::disk('public')->delete($article->cover_image_path);
            }
            $data['cover_image_path'] = $request->file('cover')->store('articles', 'public');
        }

        if (($data['status'] ?? $article->status) === 'published' && !$article->published_at && empty($data['published_at'])) {
            $data['published_at'] = now();
        }

        $article->update($data);

        return redirect('/articles')->with('status', 'Artikel diperbarui.');
    }

    public function destroy(string $id): RedirectResponse
    {
        Article::findOrFail($id)->delete();
        return redirect('/articles')->with('status', 'Artikel dihapus.');
    }

    private function validateData(Request $request): array
    {
        return $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'excerpt' => ['nullable', 'string', 'max:500'],
            'body' => ['required', 'string'],
            'category' => ['nullable', 'string', 'max:100'],
            'status' => ['required', 'in:draft,published,archived'],
            'is_featured' => ['nullable', 'boolean'],
            'cover' => ['nullable', 'image', 'max:4096'],
        ]) + ['is_featured' => $request->boolean('is_featured')];
    }
}
