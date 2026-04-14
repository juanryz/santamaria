<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login — Santa Maria CMS</title>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600;700&family=Manrope:wght@400;500;600;700&display=swap" rel="stylesheet">
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = { theme: { extend: { colors: { navy: '#1E3A5F', gold: '#C5A55A', cream: '#FAF8F5' } } } };
    </script>
    <style>body{font-family:'Manrope',sans-serif}.serif{font-family:'Playfair Display',serif}</style>
</head>
<body class="min-h-screen bg-cream flex items-center justify-center p-4">
<div class="w-full max-w-md bg-white rounded-xl shadow-xl p-8 border-t-4 border-gold">
    <div class="text-center mb-6">
        <h1 class="serif text-3xl text-navy">Santa Maria</h1>
        <p class="text-sm text-gray-500">CMS Admin Login</p>
    </div>
    @if($errors->any())
        <div class="mb-4 p-3 bg-red-50 text-red-700 rounded text-sm">{{ $errors->first() }}</div>
    @endif
    <form method="POST" action="/login" class="space-y-4">
        @csrf
        <div>
            <label class="text-sm font-medium text-navy">Email</label>
            <input type="email" name="email" value="{{ old('email') }}" required
                   class="mt-1 w-full px-3 py-2 border rounded-md focus:border-gold focus:outline-none">
        </div>
        <div>
            <label class="text-sm font-medium text-navy">Password</label>
            <input type="password" name="password" required
                   class="mt-1 w-full px-3 py-2 border rounded-md focus:border-gold focus:outline-none">
        </div>
        <label class="flex items-center text-sm text-gray-600">
            <input type="checkbox" name="remember" class="mr-2"> Remember me
        </label>
        <button type="submit" class="w-full bg-navy text-white py-2 rounded-md hover:bg-navy/90 font-medium">Masuk</button>
    </form>
</div>
</body>
</html>
