<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{{ $article->meta_title ?? $article->title }} | Santa Maria Funeral Organizer</title>
  <meta name="description" content="{{ $article->meta_description ?? $article->excerpt ?? \Illuminate\Support\Str::limit(strip_tags($article->body), 160) }}">
  <meta property="og:title" content="{{ $article->title }}">
  <meta property="og:description" content="{{ $article->excerpt ?? \Illuminate\Support\Str::limit(strip_tags($article->body), 200) }}">
  <meta property="og:type" content="article">
  @if($article->cover_image_path)
    <meta property="og:image" content="{{ app(\App\Services\StorageService::class)->getSignedUrl($article->cover_image_path) }}">
  @endif
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;500;600;700;800&family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
  <style>
    *, *::before, *::after { margin: 0; padding: 0; box-sizing: border-box; }
    :root {
      --navy: #1E3A5F; --navy-dark: #142C4A; --navy-deep: #0F2139;
      --steel-blue: #4A7BA7; --ice-blue: #D6E6F2; --cream: #FAF8F5;
      --warm-white: #FEFDFB; --gold-soft: #C5A55A;
      --text-dark: #1A2A3A; --text-body: #3D4F5F; --text-muted: #7A8D9C;
    }
    body { font-family: 'Inter', sans-serif; color: var(--text-body); background: var(--warm-white); line-height: 1.7; }
    h1, h2, h3 { font-family: 'Playfair Display', Georgia, serif; color: var(--navy); }

    .back-link { display: inline-flex; align-items: center; gap: 6px; text-decoration: none; color: var(--text-muted); font-size: 0.85rem; margin-bottom: 32px; transition: color 0.2s; }
    .back-link:hover { color: var(--navy); }
    .back-link svg { width: 16px; height: 16px; }

    .article-container { max-width: 760px; margin: 0 auto; padding: 60px 24px 80px; }

    .article-category { display: inline-block; font-size: 0.7rem; font-weight: 600; letter-spacing: 2px; text-transform: uppercase; color: var(--steel-blue); background: rgba(74,123,167,0.08); padding: 4px 14px; border-radius: 4px; margin-bottom: 16px; }

    .article-header h1 { font-size: 2.2rem; font-weight: 700; line-height: 1.25; margin-bottom: 16px; }
    .article-meta { font-size: 0.82rem; color: var(--text-muted); display: flex; gap: 16px; margin-bottom: 32px; }
    .article-cover { width: 100%; border-radius: 12px; margin-bottom: 36px; aspect-ratio: 16/9; object-fit: cover; }

    .article-content { font-size: 1rem; line-height: 1.9; color: var(--text-body); }
    .article-content h2 { font-size: 1.5rem; margin: 32px 0 16px; }
    .article-content h3 { font-size: 1.2rem; margin: 24px 0 12px; }
    .article-content p { margin-bottom: 16px; }
    .article-content ul, .article-content ol { margin: 0 0 16px 24px; }
    .article-content li { margin-bottom: 8px; }
    .article-content blockquote { border-left: 3px solid var(--gold-soft); padding: 12px 20px; margin: 24px 0; background: var(--cream); border-radius: 0 8px 8px 0; font-style: italic; color: var(--text-body); }
    .article-content img { max-width: 100%; border-radius: 8px; margin: 16px 0; }
    .article-content a { color: var(--steel-blue); }

    .article-tags { margin-top: 32px; padding-top: 24px; border-top: 1px solid rgba(30,58,95,0.06); display: flex; gap: 8px; flex-wrap: wrap; }
    .article-tag { font-size: 0.75rem; color: var(--text-muted); background: var(--cream); padding: 4px 12px; border-radius: 4px; }

    .article-share { text-align: center; margin-top: 40px; padding-top: 24px; border-top: 1px solid rgba(30,58,95,0.06); }
    .article-share p { font-size: 0.82rem; color: var(--text-muted); margin-bottom: 12px; }
    .share-btn { display: inline-flex; align-items: center; gap: 8px; padding: 10px 24px; border-radius: 6px; text-decoration: none; font-size: 0.85rem; font-weight: 600; background: #25D366; color: #fff; transition: background 0.2s; }
    .share-btn:hover { background: #1DA855; }
    .share-btn svg { width: 18px; height: 18px; fill: #fff; }

    @media (max-width: 480px) {
      .article-header h1 { font-size: 1.6rem; }
      .article-container { padding: 40px 16px 60px; }
    }
  </style>
</head>
<body>
  <div class="article-container">
    <a href="/" class="back-link">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="15 18 9 12 15 6"/></svg>
      Kembali ke Beranda
    </a>

    <div class="article-header">
      <span class="article-category">{{ $article->category ?? 'Umum' }}</span>
      <h1>{{ $article->title }}</h1>
      <div class="article-meta">
        <span>{{ $article->author?->name ?? 'Santa Maria' }}</span>
        <span>{{ $article->published_at->translatedFormat('d F Y') }}</span>
        <span>{{ $article->view_count }} kali dibaca</span>
      </div>
    </div>

    @if($article->cover_image_path)
      <img class="article-cover" src="{{ app(\App\Services\StorageService::class)->getSignedUrl($article->cover_image_path) }}" alt="{{ $article->title }}">
    @endif

    <div class="article-content">
      {!! $article->body !!}
    </div>

    @if($article->tags && count($article->tags) > 0)
      <div class="article-tags">
        @foreach($article->tags as $tag)
          <span class="article-tag">#{{ $tag }}</span>
        @endforeach
      </div>
    @endif

    <div class="article-share">
      <p>Bagikan artikel ini</p>
      <a href="https://wa.me/?text={{ urlencode($article->title . ' — ' . url('/blog/' . $article->slug)) }}" target="_blank" rel="noopener" class="share-btn">
        <svg viewBox="0 0 24 24"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/></svg>
        Bagikan via WhatsApp
      </a>
    </div>
  </div>
</body>
</html>
