@csrf
<div class="grid grid-cols-1 md:grid-cols-3 gap-6">
    <div class="md:col-span-2 space-y-4">
        <div>
            <label class="block text-sm font-medium text-navy">Judul</label>
            <input type="text" name="title" value="{{ old('title', $article->title ?? '') }}" required
                   class="mt-1 w-full px-3 py-2 border rounded">
        </div>
        <div>
            <label class="block text-sm font-medium text-navy">Excerpt (ringkasan, maks 500 char)</label>
            <textarea name="excerpt" rows="3" maxlength="500" class="mt-1 w-full px-3 py-2 border rounded">{{ old('excerpt', $article->excerpt ?? '') }}</textarea>
        </div>
        <div>
            <label class="block text-sm font-medium text-navy">Isi</label>
            <textarea name="body" rows="16" required class="mt-1 w-full px-3 py-2 border rounded font-mono text-sm">{{ old('body', $article->body ?? '') }}</textarea>
        </div>
    </div>
    <div class="space-y-4">
        <div>
            <label class="block text-sm font-medium text-navy">Status</label>
            <select name="status" class="mt-1 w-full px-3 py-2 border rounded">
                @foreach(['draft','published','archived'] as $s)
                    <option value="{{ $s }}" @selected(old('status', $article->status ?? 'draft')===$s)>{{ ucfirst($s) }}</option>
                @endforeach
            </select>
        </div>
        <div>
            <label class="block text-sm font-medium text-navy">Kategori</label>
            <input type="text" name="category" value="{{ old('category', $article->category ?? 'umum') }}"
                   class="mt-1 w-full px-3 py-2 border rounded">
        </div>
        <label class="flex items-center text-sm">
            <input type="checkbox" name="is_featured" value="1" @checked(old('is_featured', $article->is_featured ?? false)) class="mr-2">
            Featured
        </label>
        <div>
            <label class="block text-sm font-medium text-navy">Cover Image</label>
            @if(!empty($article) && $article->cover_image_path)
                <img src="{{ $article->cover_image_url }}" class="my-2 w-full h-32 object-cover rounded">
            @endif
            <input type="file" name="cover" accept="image/*" class="mt-1 w-full text-sm">
        </div>
    </div>
</div>
<div class="mt-6 flex gap-3">
    <button class="bg-navy text-white px-6 py-2 rounded hover:bg-navy/90 font-semibold">Simpan</button>
    <a href="/articles" class="px-6 py-2 rounded border hover:bg-gray-50">Batal</a>
</div>
