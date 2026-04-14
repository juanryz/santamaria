<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Article;
use App\Services\AiContentService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AiGenerateController extends Controller
{
    public function __construct(protected AiContentService $ai) {}

    public function form()
    {
        return view('admin.articles.generate', [
            'configured' => $this->ai->isConfigured(),
            'suggestions' => [
                'Panduan lengkap tradisi pemakaman Katolik di Indonesia',
                'Cara mendukung keluarga yang sedang berduka',
                'Perbedaan tata cara pemakaman Kristen Protestan dan Katolik',
                'Etika dan adab menghadiri rumah duka',
                'Mengatasi kesedihan setelah kehilangan orang terkasih',
                'Apa saja yang perlu disiapkan keluarga saat anggota keluarga meninggal',
                'Tradisi tahlilan dan peringatan 40 hari dalam budaya Indonesia',
                'Panduan memilih peti jenazah yang bermartabat',
                'Peran funeral organizer modern dalam pemakaman terpadu',
                'Tips bijak memilih rangkaian bunga duka cita',
            ],
        ]);
    }

    public function generate(Request $request)
    {
        $data = $request->validate([
            'topic' => 'required|string|min:10|max:300',
            'category' => 'nullable|string|max:100',
            'generate_image' => 'nullable|boolean',
            'auto_publish' => 'nullable|boolean',
        ]);

        if (! $this->ai->isConfigured()) {
            return back()->with('error', 'OPENAI_API_KEY belum dikonfigurasi di .env');
        }

        try {
            $content = $this->ai->generateArticle($data['topic'], $data['category'] ?? null);
        } catch (\Throwable $e) {
            return back()->with('error', 'Gagal generate konten: '.$e->getMessage())->withInput();
        }

        $coverPath = null;
        if (! empty($data['generate_image']) && ! empty($content['image_prompt'])) {
            try {
                $coverPath = $this->ai->generateImage($content['image_prompt']);
            } catch (\Throwable $e) {
                session()->flash('warning', 'Artikel berhasil dibuat, tapi gambar gagal dibuat: '.$e->getMessage());
            }
        }

        $autoPublish = ! empty($data['auto_publish']);

        $article = Article::create([
            'title' => $content['title'],
            'excerpt' => $content['excerpt'],
            'body' => $content['body_html'],
            'category' => $content['category'],
            'tags' => $content['tags'],
            'meta_title' => $content['meta_title'],
            'meta_description' => $content['meta_description'],
            'cover_image_path' => $coverPath,
            'status' => $autoPublish ? 'published' : 'draft',
            'published_at' => $autoPublish ? now() : null,
            'author_id' => Auth::id(),
        ]);

        return redirect()->route('articles.edit', $article->id)
            ->with('success', 'Artikel berhasil di-generate dengan AI! Review sebelum publish.');
    }
}
