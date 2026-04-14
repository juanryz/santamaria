<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Obituary;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\View\View;

class ObituaryController extends Controller
{
    public function index(): View
    {
        $obituaries = Obituary::latest()->paginate(15);
        return view('admin.obituaries.index', compact('obituaries'));
    }

    public function create(): View
    {
        return view('admin.obituaries.create');
    }

    public function store(Request $request): RedirectResponse
    {
        $data = $this->validateData($request);
        $data['created_by'] = $request->user()->id;

        if ($request->hasFile('photo')) {
            $data['deceased_photo_path'] = $request->file('photo')->store('obituaries', 'public');
        }

        if (($data['status'] ?? 'draft') === 'published' && empty($data['published_at'])) {
            $data['published_at'] = now();
        }

        Obituary::create($data);

        return redirect('/obituaries')->with('status', 'Berita duka berhasil dibuat.');
    }

    public function edit(string $id): View
    {
        $obituary = Obituary::findOrFail($id);
        return view('admin.obituaries.edit', compact('obituary'));
    }

    public function update(Request $request, string $id): RedirectResponse
    {
        $obituary = Obituary::findOrFail($id);
        $data = $this->validateData($request);

        if ($request->hasFile('photo')) {
            if ($obituary->deceased_photo_path) {
                Storage::disk('public')->delete($obituary->deceased_photo_path);
            }
            $data['deceased_photo_path'] = $request->file('photo')->store('obituaries', 'public');
        }

        if (($data['status'] ?? $obituary->status) === 'published' && !$obituary->published_at && empty($data['published_at'])) {
            $data['published_at'] = now();
        }

        $obituary->update($data);

        return redirect('/obituaries')->with('status', 'Berita duka diperbarui.');
    }

    public function destroy(string $id): RedirectResponse
    {
        Obituary::findOrFail($id)->delete();
        return redirect('/obituaries')->with('status', 'Berita duka dihapus.');
    }

    private function validateData(Request $request): array
    {
        $validated = $request->validate([
            'deceased_name' => ['required', 'string', 'max:255'],
            'deceased_nickname' => ['nullable', 'string', 'max:255'],
            'deceased_dob' => ['nullable', 'date'],
            'deceased_dod' => ['required', 'date'],
            'deceased_place_of_birth' => ['nullable', 'string', 'max:255'],
            'deceased_religion' => ['nullable', 'string', 'max:100'],
            'family_contact_name' => ['nullable', 'string', 'max:255'],
            'family_contact_phone' => ['nullable', 'string', 'max:50'],
            'family_message' => ['nullable', 'string'],
            'survived_by' => ['nullable', 'string'],
            'funeral_location' => ['nullable', 'string', 'max:255'],
            'funeral_datetime' => ['nullable', 'date'],
            'funeral_address' => ['nullable', 'string', 'max:255'],
            'cemetery_name' => ['nullable', 'string', 'max:255'],
            'prayer_location' => ['nullable', 'string', 'max:255'],
            'prayer_datetime' => ['nullable', 'date'],
            'prayer_notes' => ['nullable', 'string'],
            'status' => ['required', 'in:draft,published,archived'],
            'photo' => ['nullable', 'image', 'max:4096'],
        ]);
        $validated['is_featured'] = $request->boolean('is_featured');
        return $validated;
    }
}
