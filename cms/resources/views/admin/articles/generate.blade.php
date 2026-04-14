@extends('layouts.admin')
@section('title', 'Generate Artikel AI')
@section('content')
<div class="max-w-3xl">
    <div class="flex items-center gap-3 mb-2">
        <a href="/articles" class="text-gray-500 hover:text-navy">&larr;</a>
        <h2 class="font-serif text-3xl text-navy">Generate Artikel dengan AI</h2>
    </div>
    <p class="text-gray-600 mb-6">Otomatis menghasilkan artikel SEO-friendly lengkap dengan cover image via DALL-E 3. Hasil akan disimpan sebagai draft — review sebelum publish.</p>

    @if(!$configured)
        <div class="bg-red-50 border border-red-200 text-red-800 p-4 rounded mb-6">
            <strong>OpenAI belum dikonfigurasi.</strong> Tambahkan <code>OPENAI_API_KEY=...</code> di file <code>.env</code> lalu jalankan <code>php artisan config:clear</code>.
        </div>
    @endif

    @if(session('error'))
        <div class="bg-red-50 border border-red-200 text-red-800 p-4 rounded mb-6">{{ session('error') }}</div>
    @endif
    @if(session('warning'))
        <div class="bg-yellow-50 border border-yellow-200 text-yellow-800 p-4 rounded mb-6">{{ session('warning') }}</div>
    @endif

    <form method="POST" action="{{ route('ai.generate.article.store') }}" class="bg-white rounded-lg shadow p-6 space-y-5">
        @csrf

        <div>
            <label class="block text-sm font-semibold text-navy mb-2">Topik / Judul Kasar <span class="text-red-500">*</span></label>
            <textarea name="topic" rows="3" required minlength="10" maxlength="300"
                class="w-full border border-gray-300 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-gold"
                placeholder="Contoh: Panduan lengkap tradisi pemakaman Katolik di Indonesia">{{ old('topic') }}</textarea>
            <p class="text-xs text-gray-500 mt-1">Jelaskan topik sejelas mungkin. AI akan menulis 1000-1500 kata lengkap dengan H2, H3, dan struktur SEO.</p>
        </div>

        <div>
            <label class="block text-sm font-semibold text-navy mb-2">Kategori <span class="text-gray-400 font-normal">(opsional)</span></label>
            <select name="category" class="w-full border border-gray-300 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-gold">
                <option value="">-- AI yang pilih --</option>
                <option value="umum">Umum</option>
                <option value="panduan">Panduan</option>
                <option value="tradisi">Tradisi</option>
                <option value="tips">Tips</option>
                <option value="edukasi">Edukasi</option>
            </select>
        </div>

        <div class="space-y-3 border-t pt-4">
            <label class="flex items-start gap-3 cursor-pointer">
                <input type="checkbox" name="generate_image" value="1" checked class="mt-1">
                <div>
                    <div class="font-semibold text-navy">Generate cover image via DALL-E 3</div>
                    <div class="text-xs text-gray-500">Menambah ~10-20 detik. Estimasi biaya ~$0.04 per gambar.</div>
                </div>
            </label>

            <label class="flex items-start gap-3 cursor-pointer">
                <input type="checkbox" name="auto_publish" value="1" class="mt-1">
                <div>
                    <div class="font-semibold text-navy">Langsung publish</div>
                    <div class="text-xs text-gray-500">Jika tidak dicentang, artikel disimpan sebagai draft.</div>
                </div>
            </label>
        </div>

        <div class="pt-4 border-t flex items-center gap-3">
            <button type="submit" id="submit-btn" class="bg-navy text-white px-6 py-3 rounded font-semibold hover:bg-navy/90">
                ✨ Generate Artikel
            </button>
            <a href="/articles" class="text-gray-600 hover:text-navy">Batal</a>
            <span id="loading" class="hidden text-sm text-gray-500">Sedang memproses... (30-60 detik)</span>
        </div>
    </form>

    <div class="mt-8">
        <h3 class="font-serif text-xl text-navy mb-3">Ide Topik</h3>
        <div class="flex flex-wrap gap-2">
            @foreach($suggestions as $s)
                <button type="button" onclick="document.querySelector('textarea[name=topic]').value=this.textContent.trim()"
                    class="bg-white border border-gray-300 hover:border-gold hover:bg-gold/10 text-sm px-3 py-2 rounded-full text-left">
                    {{ $s }}
                </button>
            @endforeach
        </div>
    </div>
</div>

<script>
    document.querySelector('form').addEventListener('submit', function() {
        document.getElementById('submit-btn').disabled = true;
        document.getElementById('submit-btn').textContent = 'Generating...';
        document.getElementById('loading').classList.remove('hidden');
    });
</script>
@endsection
