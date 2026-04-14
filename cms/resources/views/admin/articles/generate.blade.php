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
            <button type="submit" id="submit-btn" class="bg-navy text-white px-6 py-3 rounded font-semibold hover:bg-navy/90 disabled:opacity-60 disabled:cursor-not-allowed">
                ✨ Generate Artikel
            </button>
            <a href="/articles" class="text-gray-600 hover:text-navy">Batal</a>
        </div>
    </form>

    {{-- PROGRESS OVERLAY --}}
    <div id="ai-progress" class="hidden fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
        <div class="bg-white rounded-2xl shadow-2xl max-w-md w-full p-8">
            <div class="flex items-center gap-3 mb-6">
                <div class="w-10 h-10 bg-gold/20 rounded-full flex items-center justify-center text-2xl animate-pulse">✨</div>
                <div>
                    <h3 class="font-serif text-xl text-navy">Generating Artikel</h3>
                    <p id="progress-label" class="text-sm text-gray-500">Memulai...</p>
                </div>
            </div>

            <div class="w-full bg-gray-200 rounded-full h-3 overflow-hidden mb-2">
                <div id="progress-bar" class="bg-gradient-to-r from-navy via-steel to-gold h-3 rounded-full transition-all duration-500 ease-out" style="width: 0%"></div>
            </div>
            <div class="flex justify-between text-xs text-gray-500 mb-6">
                <span id="progress-pct">0%</span>
                <span id="progress-eta">~60 detik</span>
            </div>

            <ul class="space-y-3 text-sm">
                <li id="step-1" class="flex items-center gap-3 text-gray-400">
                    <span class="step-icon w-5 h-5 rounded-full border-2 border-gray-300 flex items-center justify-center text-xs shrink-0"></span>
                    <span>Mengirim prompt ke GPT-4o-mini</span>
                </li>
                <li id="step-2" class="flex items-center gap-3 text-gray-400">
                    <span class="step-icon w-5 h-5 rounded-full border-2 border-gray-300 flex items-center justify-center text-xs shrink-0"></span>
                    <span>Menulis konten SEO 1000-1500 kata</span>
                </li>
                <li id="step-3" class="flex items-center gap-3 text-gray-400">
                    <span class="step-icon w-5 h-5 rounded-full border-2 border-gray-300 flex items-center justify-center text-xs shrink-0"></span>
                    <span>Menyusun meta tags & tags SEO</span>
                </li>
                <li id="step-4" class="flex items-center gap-3 text-gray-400">
                    <span class="step-icon w-5 h-5 rounded-full border-2 border-gray-300 flex items-center justify-center text-xs shrink-0"></span>
                    <span id="step-4-label">Generate cover image (DALL-E 3)</span>
                </li>
                <li id="step-5" class="flex items-center gap-3 text-gray-400">
                    <span class="step-icon w-5 h-5 rounded-full border-2 border-gray-300 flex items-center justify-center text-xs shrink-0"></span>
                    <span>Menyimpan ke database</span>
                </li>
            </ul>

            <p class="text-xs text-gray-400 mt-6 text-center">Jangan tutup halaman ini. Proses berjalan di server.</p>
        </div>
    </div>

    <style>
        .step-active .step-icon {
            border-color: #C5A55A;
            background: #C5A55A;
            color: white;
        }
        .step-active .step-icon::before { content: '●'; animation: pulse 1s infinite; }
        .step-active { color: #1E3A5F !important; font-weight: 600; }
        .step-done .step-icon {
            border-color: #10B981;
            background: #10B981;
            color: white;
        }
        .step-done .step-icon::before { content: '✓'; font-weight: bold; }
        .step-done { color: #047857 !important; }
        @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.4; } }
    </style>

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
    const form = document.querySelector('form');
    const withImage = () => form.querySelector('input[name=generate_image]').checked;

    form.addEventListener('submit', function() {
        document.getElementById('submit-btn').disabled = true;
        document.getElementById('submit-btn').textContent = 'Generating...';
        document.getElementById('ai-progress').classList.remove('hidden');
        document.getElementById('ai-progress').classList.add('flex');

        if (!withImage()) {
            document.getElementById('step-4-label').textContent = 'Skip cover image (tidak dicentang)';
        }

        const totalDuration = withImage() ? 60000 : 35000;
        const steps = withImage()
            ? [
                { id: 1, at: 0,     label: 'Mengirim prompt ke GPT-4o-mini...' },
                { id: 2, at: 3000,  label: 'AI sedang menulis artikel...' },
                { id: 3, at: 20000, label: 'Menyusun meta SEO & tags...' },
                { id: 4, at: 28000, label: 'DALL-E 3 sedang melukis cover...' },
                { id: 5, at: 55000, label: 'Menyimpan artikel ke database...' },
              ]
            : [
                { id: 1, at: 0,     label: 'Mengirim prompt ke GPT-4o-mini...' },
                { id: 2, at: 3000,  label: 'AI sedang menulis artikel...' },
                { id: 3, at: 20000, label: 'Menyusun meta SEO & tags...' },
                { id: 5, at: 30000, label: 'Menyimpan artikel ke database...' },
              ];

        const bar = document.getElementById('progress-bar');
        const pct = document.getElementById('progress-pct');
        const eta = document.getElementById('progress-eta');
        const label = document.getElementById('progress-label');

        const start = Date.now();
        const tick = setInterval(() => {
            const elapsed = Date.now() - start;
            let progress = Math.min((elapsed / totalDuration) * 100, 95);
            bar.style.width = progress.toFixed(1) + '%';
            pct.textContent = Math.floor(progress) + '%';
            const remaining = Math.max(0, Math.ceil((totalDuration - elapsed) / 1000));
            eta.textContent = remaining > 0 ? `~${remaining} detik` : 'hampir selesai...';

            steps.forEach((s, idx) => {
                const el = document.getElementById('step-' + s.id);
                if (!el) return;
                if (elapsed >= s.at) {
                    const next = steps[idx + 1];
                    if (next && elapsed >= next.at) {
                        el.classList.remove('step-active');
                        el.classList.add('step-done');
                    } else {
                        el.classList.add('step-active');
                        label.textContent = s.label;
                    }
                }
            });
        }, 250);

        window.addEventListener('beforeunload', () => clearInterval(tick));
    });
</script>
@endsection
