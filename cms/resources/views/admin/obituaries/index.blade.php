@extends('layouts.admin')
@section('title', 'Berita Duka')
@section('content')
<div class="flex justify-between items-center mb-6">
    <h2 class="font-serif text-3xl text-navy">Berita Duka</h2>
    <a href="/obituaries/create" class="bg-gold text-navy px-4 py-2 rounded font-semibold hover:bg-gold/90">+ Berita Duka Baru</a>
</div>
<div class="bg-white rounded-lg shadow overflow-hidden">
    <table class="w-full text-sm">
        <thead class="bg-navy text-white">
            <tr>
                <th class="text-left p-3">Nama Almarhum/ah</th>
                <th class="text-left p-3">Tgl Wafat</th>
                <th class="text-left p-3">Status</th>
                <th class="text-left p-3">Views</th>
                <th class="p-3"></th>
            </tr>
        </thead>
        <tbody class="divide-y">
            @forelse($obituaries as $o)
                <tr>
                    <td class="p-3">{{ $o->deceased_name }} @if($o->is_featured)<span class="text-gold text-xs">★</span>@endif</td>
                    <td class="p-3">{{ optional($o->deceased_dod)->format('d M Y') }}</td>
                    <td class="p-3"><span class="px-2 py-1 rounded text-xs {{ $o->status==='published'?'bg-green-100 text-green-800':'bg-gray-100' }}">{{ $o->status }}</span></td>
                    <td class="p-3">{{ $o->view_count }}</td>
                    <td class="p-3 text-right space-x-2 whitespace-nowrap">
                        <a href="/obituaries/{{ $o->id }}/edit" class="text-navy hover:underline">Edit</a>
                        <form action="/obituaries/{{ $o->id }}" method="POST" class="inline" onsubmit="return confirm('Hapus?')">
                            @csrf @method('DELETE')
                            <button class="text-red-600 hover:underline">Hapus</button>
                        </form>
                    </td>
                </tr>
            @empty
                <tr><td colspan="5" class="p-6 text-center text-gray-400">Belum ada berita duka.</td></tr>
            @endforelse
        </tbody>
    </table>
</div>
<div class="mt-4">{{ $obituaries->links() }}</div>
@endsection
