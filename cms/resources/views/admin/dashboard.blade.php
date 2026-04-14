@extends('layouts.admin')
@section('title', 'Dashboard')
@section('content')
<h2 class="font-serif text-3xl text-navy mb-6">Dashboard</h2>
<div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
    <div class="bg-white p-6 rounded-lg shadow border-l-4 border-gold">
        <p class="text-sm text-gray-500">Total Artikel</p>
        <p class="text-4xl font-bold text-navy mt-2">{{ $articleCount }}</p>
        <a href="/articles" class="text-sm text-gold mt-3 inline-block">Lihat semua →</a>
    </div>
    <div class="bg-white p-6 rounded-lg shadow border-l-4 border-navy">
        <p class="text-sm text-gray-500">Total Berita Duka</p>
        <p class="text-4xl font-bold text-navy mt-2">{{ $obituaryCount }}</p>
        <a href="/obituaries" class="text-sm text-gold mt-3 inline-block">Lihat semua →</a>
    </div>
</div>
<div class="grid grid-cols-1 md:grid-cols-2 gap-6">
    <div class="bg-white p-6 rounded-lg shadow">
        <h3 class="font-serif text-xl text-navy mb-4">Artikel Terbaru</h3>
        <ul class="divide-y">
            @forelse($recentArticles as $a)
                <li class="py-2 flex justify-between"><span class="truncate">{{ $a->title }}</span><span class="text-xs text-gray-400">{{ $a->status }}</span></li>
            @empty
                <li class="py-2 text-gray-400 text-sm">Belum ada artikel.</li>
            @endforelse
        </ul>
    </div>
    <div class="bg-white p-6 rounded-lg shadow">
        <h3 class="font-serif text-xl text-navy mb-4">Berita Duka Terbaru</h3>
        <ul class="divide-y">
            @forelse($recentObituaries as $o)
                <li class="py-2 flex justify-between"><span class="truncate">{{ $o->deceased_name }}</span><span class="text-xs text-gray-400">{{ $o->status }}</span></li>
            @empty
                <li class="py-2 text-gray-400 text-sm">Belum ada berita duka.</li>
            @endforelse
        </ul>
    </div>
</div>
@endsection
