<?php

use App\Http\Controllers\Admin\AiGenerateController;
use App\Http\Controllers\Admin\ArticleController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\ObituaryController;
use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\Auth\LogoutController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return redirect('/dashboard');
});

Route::middleware('guest')->group(function () {
    Route::get('/login', [LoginController::class, 'showLogin'])->name('login');
    Route::post('/login', [LoginController::class, 'login']);
});

Route::middleware('auth')->group(function () {
    Route::post('/logout', [LogoutController::class, 'logout'])->name('logout');

    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');

    Route::get('/articles', [ArticleController::class, 'index'])->name('articles.index');
    Route::get('/articles/ai-generate', [AiGenerateController::class, 'form'])->name('ai.generate.article');
    Route::post('/articles/ai-generate', [AiGenerateController::class, 'generate'])->name('ai.generate.article.store');
    Route::get('/articles/create', [ArticleController::class, 'create'])->name('articles.create');
    Route::post('/articles', [ArticleController::class, 'store'])->name('articles.store');
    Route::get('/articles/{id}/edit', [ArticleController::class, 'edit'])->name('articles.edit');
    Route::put('/articles/{id}', [ArticleController::class, 'update'])->name('articles.update');
    Route::delete('/articles/{id}', [ArticleController::class, 'destroy'])->name('articles.destroy');

    Route::get('/obituaries', [ObituaryController::class, 'index'])->name('obituaries.index');
    Route::get('/obituaries/create', [ObituaryController::class, 'create'])->name('obituaries.create');
    Route::post('/obituaries', [ObituaryController::class, 'store'])->name('obituaries.store');
    Route::get('/obituaries/{id}/edit', [ObituaryController::class, 'edit'])->name('obituaries.edit');
    Route::put('/obituaries/{id}', [ObituaryController::class, 'update'])->name('obituaries.update');
    Route::delete('/obituaries/{id}', [ObituaryController::class, 'destroy'])->name('obituaries.destroy');
});
