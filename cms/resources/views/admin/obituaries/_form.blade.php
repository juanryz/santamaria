@csrf
@php $o = $obituary ?? null; @endphp
<div class="grid grid-cols-1 md:grid-cols-3 gap-6">
    <div class="md:col-span-2 space-y-6">
        <fieldset class="space-y-4">
            <legend class="font-serif text-lg text-navy">Data Almarhum/ah</legend>
            <div class="grid grid-cols-2 gap-3">
                <div>
                    <label class="block text-sm">Nama Lengkap</label>
                    <input type="text" name="deceased_name" value="{{ old('deceased_name', $o->deceased_name ?? '') }}" required class="w-full px-3 py-2 border rounded">
                </div>
                <div>
                    <label class="block text-sm">Nama Panggilan</label>
                    <input type="text" name="deceased_nickname" value="{{ old('deceased_nickname', $o->deceased_nickname ?? '') }}" class="w-full px-3 py-2 border rounded">
                </div>
                <div>
                    <label class="block text-sm">Tgl Lahir</label>
                    <input type="date" name="deceased_dob" value="{{ old('deceased_dob', optional($o->deceased_dob ?? null)->format('Y-m-d')) }}" class="w-full px-3 py-2 border rounded">
                </div>
                <div>
                    <label class="block text-sm">Tgl Wafat</label>
                    <input type="date" name="deceased_dod" value="{{ old('deceased_dod', optional($o->deceased_dod ?? null)->format('Y-m-d')) }}" required class="w-full px-3 py-2 border rounded">
                </div>
                <div>
                    <label class="block text-sm">Tempat Lahir</label>
                    <input type="text" name="deceased_place_of_birth" value="{{ old('deceased_place_of_birth', $o->deceased_place_of_birth ?? '') }}" class="w-full px-3 py-2 border rounded">
                </div>
                <div>
                    <label class="block text-sm">Agama</label>
                    <input type="text" name="deceased_religion" value="{{ old('deceased_religion', $o->deceased_religion ?? '') }}" class="w-full px-3 py-2 border rounded">
                </div>
            </div>
        </fieldset>

        <fieldset class="space-y-4">
            <legend class="font-serif text-lg text-navy">Pemakaman</legend>
            <div class="grid grid-cols-2 gap-3">
                <div>
                    <label class="block text-sm">Lokasi</label>
                    <input type="text" name="funeral_location" value="{{ old('funeral_location', $o->funeral_location ?? '') }}" class="w-full px-3 py-2 border rounded">
                </div>
                <div>
                    <label class="block text-sm">Waktu</label>
                    <input type="datetime-local" name="funeral_datetime" value="{{ old('funeral_datetime', optional($o->funeral_datetime ?? null)->format('Y-m-d\TH:i')) }}" class="w-full px-3 py-2 border rounded">
                </div>
                <div class="col-span-2">
                    <label class="block text-sm">Alamat</label>
                    <input type="text" name="funeral_address" value="{{ old('funeral_address', $o->funeral_address ?? '') }}" class="w-full px-3 py-2 border rounded">
                </div>
                <div class="col-span-2">
                    <label class="block text-sm">Nama Pemakaman</label>
                    <input type="text" name="cemetery_name" value="{{ old('cemetery_name', $o->cemetery_name ?? '') }}" class="w-full px-3 py-2 border rounded">
                </div>
            </div>
        </fieldset>

        <fieldset class="space-y-4">
            <legend class="font-serif text-lg text-navy">Ibadah / Doa</legend>
            <div class="grid grid-cols-2 gap-3">
                <div>
                    <label class="block text-sm">Lokasi</label>
                    <input type="text" name="prayer_location" value="{{ old('prayer_location', $o->prayer_location ?? '') }}" class="w-full px-3 py-2 border rounded">
                </div>
                <div>
                    <label class="block text-sm">Waktu</label>
                    <input type="datetime-local" name="prayer_datetime" value="{{ old('prayer_datetime', optional($o->prayer_datetime ?? null)->format('Y-m-d\TH:i')) }}" class="w-full px-3 py-2 border rounded">
                </div>
                <div class="col-span-2">
                    <label class="block text-sm">Catatan</label>
                    <textarea name="prayer_notes" rows="2" class="w-full px-3 py-2 border rounded">{{ old('prayer_notes', $o->prayer_notes ?? '') }}</textarea>
                </div>
            </div>
        </fieldset>

        <fieldset class="space-y-4">
            <legend class="font-serif text-lg text-navy">Keluarga & Pesan</legend>
            <div class="grid grid-cols-2 gap-3">
                <div>
                    <label class="block text-sm">Kontak Keluarga</label>
                    <input type="text" name="family_contact_name" value="{{ old('family_contact_name', $o->family_contact_name ?? '') }}" class="w-full px-3 py-2 border rounded">
                </div>
                <div>
                    <label class="block text-sm">No. Telp Keluarga</label>
                    <input type="text" name="family_contact_phone" value="{{ old('family_contact_phone', $o->family_contact_phone ?? '') }}" class="w-full px-3 py-2 border rounded">
                </div>
                <div class="col-span-2">
                    <label class="block text-sm">Meninggalkan (survived_by)</label>
                    <textarea name="survived_by" rows="2" class="w-full px-3 py-2 border rounded">{{ old('survived_by', $o->survived_by ?? '') }}</textarea>
                </div>
                <div class="col-span-2">
                    <label class="block text-sm">Pesan Keluarga</label>
                    <textarea name="family_message" rows="3" class="w-full px-3 py-2 border rounded">{{ old('family_message', $o->family_message ?? '') }}</textarea>
                </div>
            </div>
        </fieldset>
    </div>

    <div class="space-y-4">
        <div>
            <label class="block text-sm font-medium text-navy">Status</label>
            <select name="status" class="mt-1 w-full px-3 py-2 border rounded">
                @foreach(['draft','published','archived'] as $s)
                    <option value="{{ $s }}" @selected(old('status', $o->status ?? 'draft')===$s)>{{ ucfirst($s) }}</option>
                @endforeach
            </select>
        </div>
        <label class="flex items-center text-sm">
            <input type="checkbox" name="is_featured" value="1" @checked(old('is_featured', $o->is_featured ?? false)) class="mr-2">
            Featured
        </label>
        <div>
            <label class="block text-sm font-medium text-navy">Foto Almarhum/ah</label>
            @if($o && $o->deceased_photo_path)
                <img src="{{ $o->deceased_photo_url }}" class="my-2 w-full h-48 object-cover rounded">
            @endif
            <input type="file" name="photo" accept="image/*" class="mt-1 w-full text-sm">
        </div>
    </div>
</div>
<div class="mt-6 flex gap-3">
    <button class="bg-navy text-white px-6 py-2 rounded hover:bg-navy/90 font-semibold">Simpan</button>
    <a href="/obituaries" class="px-6 py-2 rounded border hover:bg-gray-50">Batal</a>
</div>
