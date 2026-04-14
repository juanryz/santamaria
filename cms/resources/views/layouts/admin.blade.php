<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title', 'Admin') — Santa Maria CMS</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600;700&family=Manrope:wght@400;500;600;700&display=swap" rel="stylesheet">
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        navy: '#1E3A5F',
                        gold: '#C5A55A',
                        cream: '#FAF8F5',
                    },
                    fontFamily: {
                        serif: ['"Playfair Display"', 'serif'],
                        sans: ['Manrope', 'sans-serif'],
                    },
                },
            },
        };
    </script>
    <style>body{font-family:'Manrope',sans-serif}</style>
</head>
<body class="bg-cream min-h-screen">
<div class="flex min-h-screen">
    <aside class="w-64 bg-navy text-white flex flex-col">
        <div class="p-6 border-b border-white/10">
            <h1 class="font-serif text-2xl text-gold">Santa Maria</h1>
            <p class="text-xs text-white/60 mt-1">CMS Admin</p>
        </div>
        <nav class="flex-1 p-4 space-y-1">
            @php $r = request()->path(); @endphp
            <a href="/dashboard" class="block px-4 py-2 rounded {{ str_starts_with($r,'dashboard')?'bg-gold text-navy font-semibold':'hover:bg-white/10' }}">Dashboard</a>
            <a href="/articles" class="block px-4 py-2 rounded {{ str_starts_with($r,'articles')?'bg-gold text-navy font-semibold':'hover:bg-white/10' }}">Artikel</a>
            <a href="/obituaries" class="block px-4 py-2 rounded {{ str_starts_with($r,'obituaries')?'bg-gold text-navy font-semibold':'hover:bg-white/10' }}">Berita Duka</a>
        </nav>
        <form method="POST" action="/logout" class="p-4 border-t border-white/10">
            @csrf
            <button class="w-full text-left px-4 py-2 rounded hover:bg-white/10 text-sm">Logout ({{ auth()->user()->name ?? '' }})</button>
        </form>
    </aside>
    <main class="flex-1 p-8 overflow-x-auto">
        @if(session('status'))
            <div class="mb-4 p-3 bg-green-100 text-green-800 rounded border border-green-200">{{ session('status') }}</div>
        @endif
        @if($errors->any())
            <div class="mb-4 p-3 bg-red-100 text-red-800 rounded border border-red-200">
                <ul class="list-disc list-inside text-sm">
                    @foreach($errors->all() as $e)<li>{{ $e }}</li>@endforeach
                </ul>
            </div>
        @endif
        @yield('content')
    </main>
</div>
</body>
</html>
