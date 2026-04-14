<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Article;
use App\Models\Obituary;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function index(): View
    {
        return view('admin.dashboard', [
            'articleCount' => Article::count(),
            'obituaryCount' => Obituary::count(),
            'recentArticles' => Article::latest()->take(5)->get(),
            'recentObituaries' => Obituary::latest()->take(5)->get(),
        ]);
    }
}
