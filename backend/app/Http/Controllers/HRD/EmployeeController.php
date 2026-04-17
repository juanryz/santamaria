<?php

namespace App\Http\Controllers\HRD;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\UserLocationConsent;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/**
 * v1.35 — HRD Employee Management
 * HR dapat melihat, membuat, mengedit, dan menonaktifkan akun karyawan.
 * Tidak dapat mengakses role consumer, owner, dan super_admin.
 */
class EmployeeController extends Controller
{
    // Role yang tidak boleh dikelola HR
    private const RESTRICTED_ROLES = ['consumer', 'owner', 'super_admin'];

    public function index(Request $request)
    {
        $query = User::whereNotIn('role', self::RESTRICTED_ROLES);

        if ($request->has('role')) {
            $query->where('role', $request->role);
        }

        if ($request->has('is_active')) {
            $query->where('is_active', filter_var($request->is_active, FILTER_VALIDATE_BOOLEAN));
        }

        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhere('phone', 'like', "%{$search}%");
            });
        }

        $employees = $query->orderBy('name')->paginate(20);

        return response()->json(['success' => true, 'data' => $employees]);
    }

    public function store(Request $request)
    {
        $allowedSlugs = \App\Models\Role::where('is_active', true)
            ->whereNotIn('slug', self::RESTRICTED_ROLES)
            ->pluck('slug')
            ->toArray();

        $request->validate([
            'name'             => 'required|string|max:255',
            'phone'            => 'required|string|max:20|unique:users',
            'email'            => 'required|email|unique:users',
            'role'             => ['required', Rule::in($allowedSlugs)],
            'password'         => 'required|string|min:8',
            'religion'         => 'nullable|string|max:50',
            'location_consent' => 'nullable|boolean',
        ]);

        $user = User::create([
            'name'       => $request->name,
            'phone'      => $request->phone,
            'email'      => $request->email,
            'role'       => $request->role,
            'password'   => $request->password,
            'is_active'  => true,
            'is_viewer'  => (\App\Models\Role::findBySlug($request->role)?->is_viewer_only ?? false),
            'religion'   => $request->religion,
            'created_by' => $request->user()->id,
        ]);

        // Simpan consent lokasi jika HR mencentang persetujuan
        if ($request->boolean('location_consent')) {
            UserLocationConsent::create([
                'user_id'    => $user->id,
                'agreed'     => true,
                'agreed_at'  => now(),
                'ip_address' => $request->ip(),
            ]);
        }

        return response()->json([
            'success' => true,
            'data'    => $user,
            'message' => 'Akun karyawan berhasil dibuat.',
        ], 201);
    }

    public function show(string $id)
    {
        $user = User::whereNotIn('role', self::RESTRICTED_ROLES)->findOrFail($id);
        return response()->json(['success' => true, 'data' => $user]);
    }

    public function update(Request $request, string $id)
    {
        $user = User::whereNotIn('role', self::RESTRICTED_ROLES)->findOrFail($id);

        $allowedSlugs = \App\Models\Role::where('is_active', true)
            ->whereNotIn('slug', self::RESTRICTED_ROLES)
            ->pluck('slug')
            ->toArray();

        $request->validate([
            'name'      => 'sometimes|string|max:255',
            'phone'     => ['sometimes', 'string', 'max:20', Rule::unique('users')->ignore($user->id)],
            'email'     => ['sometimes', 'email', Rule::unique('users')->ignore($user->id)],
            'role'      => ['sometimes', Rule::in($allowedSlugs)],
            'is_active' => 'sometimes|boolean',
            'religion'  => 'nullable|string|max:50',
        ]);

        $data = $request->only(['name', 'phone', 'email', 'role', 'is_active', 'religion']);

        if (isset($data['role'])) {
            $roleModel = \App\Models\Role::findBySlug($data['role']);
            $data['is_viewer'] = $roleModel?->is_viewer_only ?? false;
        }

        $user->update($data);

        return response()->json([
            'success' => true,
            'data'    => $user->fresh(),
            'message' => 'Data karyawan berhasil diperbarui.',
        ]);
    }

    public function resetPassword(Request $request, string $id)
    {
        $user = User::whereNotIn('role', self::RESTRICTED_ROLES)->findOrFail($id);

        $request->validate(['password' => 'required|string|min:8']);
        $user->update(['password' => $request->password]);

        return response()->json(['success' => true, 'message' => 'Password berhasil direset.']);
    }

    public function deactivate(string $id)
    {
        $user = User::whereNotIn('role', self::RESTRICTED_ROLES)->findOrFail($id);
        $user->update(['is_active' => false]);
        return response()->json(['success' => true, 'message' => 'Karyawan berhasil dinonaktifkan.']);
    }

    public function activate(string $id)
    {
        $user = User::whereNotIn('role', self::RESTRICTED_ROLES)->findOrFail($id);
        $user->update(['is_active' => true]);
        return response()->json(['success' => true, 'message' => 'Karyawan berhasil diaktifkan.']);
    }
}
