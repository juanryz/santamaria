<?php

use App\Http\Controllers\Api\PublicArticleController;
use App\Http\Controllers\Api\PublicObituaryController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1/public')->group(function () {
    Route::get('articles/categories', [PublicArticleController::class, 'categories']);
    Route::get('articles', [PublicArticleController::class, 'index']);
    Route::get('articles/{slug}', [PublicArticleController::class, 'show']);

    Route::get('obituaries', [PublicObituaryController::class, 'index']);
    Route::get('obituaries/{slug}', [PublicObituaryController::class, 'show']);
});
