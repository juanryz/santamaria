<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('landing');
});

// Berita Duka detail page (SEO-friendly)
Route::get('/berita-duka/{slug}', function (string $slug) {
    $obituary = \App\Models\Obituary::published()->where('slug', $slug)->firstOrFail();
    $obituary->increment('view_count');
    return view('obituary-detail', compact('obituary'));
});

// Blog article detail page (SEO-friendly)
Route::get('/blog/{slug}', function (string $slug) {
    $article = \App\Models\Article::published()->where('slug', $slug)->firstOrFail();
    $article->increment('view_count');
    return view('article-detail', compact('article'));
});
