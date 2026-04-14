@extends('layouts.admin')
@section('title', 'Artikel')
@section('content')
<div class="flex justify-between items-center mb-6">
    <h2 class="font-serif text-3xl text-navy">Artikel</h2>
    <div class="flex gap-2">
        <a href="/articles/ai-generate" class="bg-navy text-white px-4 py-2 rounded font-semibold hover:bg-navy/90">✨ Generate AI</a>
        <a href="/articles/create" class="bg-gold text-navy px-4 py-2 rounded font-semibold hover:bg-gold/90">+ Artikel Baru</a>
    </div>
</div>
@if(session('success'))<div class="bg-green-50 border border-green-200 text-green-800 p-3 rounded mb-4">{{ session('success') }}</div>@endif
<div class="bg-white rounded-lg shadow overflow-hidden">
    <table class="w-full text-sm">
        <thead class="bg-navy text-white">
            <tr>
                <th class="text-left p-3">Judul</th>
                <th class="text-left p-3">Kategori</th>
                <th class="text-left p-3">Status</th>
                <th class="text-left p-3">Views</th>
                <th class="p-3"></th>
            </tr>
        </thead>
        <tbody class="divide-y">
            @forelse($articles as $a)
                <tr>
                    <td class="p-3">{{ $a->title }} @if($a->is_featured)<span class="text-gold text-xs">★</span>@endif</td>
                    <td class="p-3">{{ $a->category }}</td>
                    <td class="p-3"><span class="px-2 py-1 rounded text-xs {{ $a->status==='published'?'bg-green-100 text-green-800':($a->status==='draft'?'bg-gray-100':'bg-yellow-100') }}">{{ $a->status }}</span></td>
                    <td class="p-3">{{ $a->view_count }}</td>
                    <td class="p-3 text-right space-x-2 whitespace-nowrap">
                        <a href="/articles/{{ $a->id }}/edit" class="text-navy hover:underline">Edit</a>
                        <form action="/articles/{{ $a->id }}" method="POST" class="inline" onsubmit="return confirm('Hapus artikel ini?')">
                            @csrf @method('DELETE')
                            <button class="text-red-600 hover:underline">Hapus</button>
                        </form>
                    </td>
                </tr>
            @empty
                <tr><td colspan="5" class="p-6 text-center text-gray-400">Belum ada artikel.</td></tr>
            @endforelse
        </tbody>
    </table>
</div>
<div class="mt-4">{{ $articles->links() }}</div>
@endsection
