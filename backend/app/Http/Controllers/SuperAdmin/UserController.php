<?php

namespace App\Http\Controllers\SuperAdmin;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    /**
     * Daftar semua user (semua role kecuali super_admin lain).
     */
    public function index(Request $request)
    {
        $query = User::query()->where('role', '!=', UserRole::SUPER_ADMIN->value);

        if ($request->has('role')) {
            $query->where('role', $request->role);
        }

        if ($request->has('is_active')) {
            $query->where('is_active', filter_var($request->is_active, FILTER_VALIDATE_BOOLEAN));
        }

        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'ilike', "%{$search}%")
                  ->orWhere('email', 'ilike', "%{$search}%")
                  ->orWhere('phone', 'ilike', "%{$search}%");
            });
        }

        $users = $query->orderBy('created_at', 'desc')->paginate(20);

        return response()->json(['success' => true, 'data' => $users]);
    }

    /**
     * Buat akun baru untuk role apapun (kecuali consumer dan super_admin).
     * Super admin menentukan email dan password awal.
     */
    public function store(Request $request)
    {
        $allowedRoles = array_filter(UserRole::values(), fn($r) => !in_array($r, [
            UserRole::CONSUMER->value,
            UserRole::SUPER_ADMIN->value,
        ]));

        $request->validate([
            'name'     => 'required|string|max:255',
            'phone'    => 'required|string|max:20|unique:users',
            'email'    => 'required|email|unique:users',
            'role'     => ['required', Rule::in($allowedRoles)],
            'password' => 'required|string|min:8',
            'religion' => 'nullable|string|max:50',
        ]);

        $user = User::create([
            'name'                 => $request->name,
            'phone'                => $request->phone,
            'email'                => $request->email,
            'role'                 => $request->role,
            'password'             => $request->password,
            'is_active'            => true,
            'is_viewer'            => $request->role === UserRole::VIEWER->value,
            'is_verified_supplier' => $request->role === UserRole::SUPPLIER->value,
            'religion'             => $request->religion,
            'created_by'           => $request->user()->id,
        ]);

        return response()->json([
            'success' => true,
            'data'    => $user,
            'message' => 'Akun berhasil dibuat.',
        ], 201);
    }

    /**
     * Detail user.
     */
    public function show(string $id)
    {
        $user = User::where('role', '!=', UserRole::SUPER_ADMIN->value)->findOrFail($id);
        return response()->json(['success' => true, 'data' => $user]);
    }

    /**
     * Update data user (nama, email, phone, role, status aktif).
     */
    public function update(Request $request, string $id)
    {
        $user = User::where('role', '!=', UserRole::SUPER_ADMIN->value)->findOrFail($id);

        $allowedRoles = array_filter(UserRole::values(), fn($r) => !in_array($r, [
            UserRole::CONSUMER->value,
            UserRole::SUPER_ADMIN->value,
        ]));

        $request->validate([
            'name'      => 'sometimes|string|max:255',
            'phone'     => ['sometimes', 'string', 'max:20', Rule::unique('users')->ignore($user->id)],
            'email'     => ['sometimes', 'email', Rule::unique('users')->ignore($user->id)],
            'role'      => ['sometimes', Rule::in($allowedRoles)],
            'is_active' => 'sometimes|boolean',
            'religion'  => 'nullable|string|max:50',
        ]);

        $data = $request->only(['name', 'phone', 'email', 'role', 'is_active', 'religion']);

        // Jika role berubah ke viewer, set is_viewer = true; sebaliknya false
        if (isset($data['role'])) {
            $data['is_viewer'] = $data['role'] === UserRole::VIEWER->value;
        }

        $user->update($data);

        return response()->json([
            'success' => true,
            'data'    => $user->fresh(),
            'message' => 'Akun berhasil diperbarui.',
        ]);
    }

    /**
     * Reset password user oleh super admin.
     */
    public function resetPassword(Request $request, string $id)
    {
        $user = User::where('role', '!=', UserRole::SUPER_ADMIN->value)->findOrFail($id);
        $isConsumer = $user->role === UserRole::CONSUMER->value;

        if ($isConsumer) {
            $request->validate([
                'password' => 'nullable|string|min:4|max:6',
            ]);
            $newPin = $request->password ?? '1234';
            $user->update(['pin' => $newPin]);
            $msg = "PIN berhasil direset ke " . ($request->password ? "PIN baru pilihan Anda." : "default (1234).");
        } else {
            $request->validate([
                'password' => 'nullable|string|min:8',
            ]);
            $newPassword = $request->password ?? 'santa123';
            $user->update(['password' => $newPassword]);
            $msg = "Password berhasil direset ke " . ($request->password ? "password baru pilihan Anda." : "default (santa123).");
        }

        return response()->json([
            'success' => true,
            'message' => $msg,
        ]);
    }

    /**
     * Nonaktifkan user (soft disable, bukan hapus).
     */
    public function deactivate(string $id)
    {
        $user = User::where('role', '!=', UserRole::SUPER_ADMIN->value)->findOrFail($id);
        $user->update(['is_active' => false]);

        return response()->json([
            'success' => true,
            'message' => 'Akun berhasil dinonaktifkan.',
        ]);
    }

    /**
     * Aktifkan kembali user.
     */
    public function activate(string $id)
    {
        $user = User::where('role', '!=', UserRole::SUPER_ADMIN->value)->findOrFail($id);
        $user->update(['is_active' => true]);

        return response()->json([
            'success' => true,
            'message' => 'Akun berhasil diaktifkan kembali.',
        ]);
    }

    /**
     * Verifikasi supplier (set is_verified_supplier = true).
     */
    public function verifySupplier(string $id)
    {
        $user = User::where('role', UserRole::SUPPLIER->value)->findOrFail($id);
        $user->update(['is_verified_supplier' => true]);

        return response()->json([
            'success' => true,
            'message' => 'Supplier berhasil diverifikasi.',
        ]);
    }
}
