<?php

namespace App\Http\Controllers\SuperAdmin;

use App\Http\Controllers\Controller;
use App\Models\Role;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class RoleController extends Controller
{
    /**
     * GET /super-admin/roles — list all roles ordered by sort_order.
     */
    public function index(): JsonResponse
    {
        $roles = Role::orderBy('sort_order')->orderBy('label')->get();

        // Append user_count to each role
        $slugCounts = User::selectRaw('role, COUNT(*) as cnt')
            ->groupBy('role')
            ->pluck('cnt', 'role');

        $roles = $roles->map(function ($role) use ($slugCounts) {
            $role->user_count = $slugCounts[$role->slug] ?? 0;
            return $role;
        });

        return response()->json(['success' => true, 'data' => $roles]);
    }

    /**
     * POST /super-admin/roles — create a new custom role.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'slug'                 => ['required', 'string', 'max:100', 'unique:roles,slug', 'regex:/^[a-z0-9_]+$/'],
            'label'                => 'required|string|max:255',
            'description'          => 'nullable|string',
            'can_have_inventory'   => 'boolean',
            'is_vendor'            => 'boolean',
            'is_viewer_only'       => 'boolean',
            'can_manage_orders'    => 'boolean',
            'receives_order_alarm' => 'boolean',
            'color_hex'            => ['nullable', 'string', 'regex:/^#[0-9A-Fa-f]{6}$/'],
            'icon_name'            => 'nullable|string|max:100',
            'sort_order'           => 'nullable|integer|min:0',
        ]);

        // Custom roles cannot be system roles
        $validated['is_system'] = false;
        $validated['is_active'] = true;

        $role = Role::create($validated);

        return response()->json([
            'success' => true,
            'data'    => $role,
            'message' => 'Role berhasil dibuat.',
        ], 201);
    }

    /**
     * PUT /super-admin/roles/{id} — update a role.
     * System roles: label, description, flags, color, icon can be updated but NOT slug.
     */
    public function update(Request $request, string $id): JsonResponse
    {
        $role = Role::findOrFail($id);

        $rules = [
            'label'                => 'sometimes|string|max:255',
            'description'          => 'nullable|string',
            'is_active'            => 'sometimes|boolean',
            'can_have_inventory'   => 'sometimes|boolean',
            'is_vendor'            => 'sometimes|boolean',
            'is_viewer_only'       => 'sometimes|boolean',
            'can_manage_orders'    => 'sometimes|boolean',
            'receives_order_alarm' => 'sometimes|boolean',
            'color_hex'            => ['nullable', 'string', 'regex:/^#[0-9A-Fa-f]{6}$/'],
            'icon_name'            => 'nullable|string|max:100',
            'sort_order'           => 'sometimes|integer|min:0',
        ];

        // Allow slug change only for non-system roles
        if (!$role->is_system) {
            $rules['slug'] = ['sometimes', 'string', 'max:100', Rule::unique('roles', 'slug')->ignore($role->id), 'regex:/^[a-z0-9_]+$/'];
        }

        $validated = $request->validate($rules);

        // Cannot change is_system flag via API
        unset($validated['is_system']);

        $role->update($validated);

        return response()->json([
            'success' => true,
            'data'    => $role->fresh(),
            'message' => 'Role berhasil diperbarui.',
        ]);
    }

    /**
     * DELETE /super-admin/roles/{id} — delete a custom role.
     * Cannot delete system roles or roles that still have users.
     */
    public function destroy(string $id): JsonResponse
    {
        $role = Role::findOrFail($id);

        if ($role->is_system) {
            return response()->json([
                'success' => false,
                'message' => 'Role sistem tidak dapat dihapus.',
            ], 403);
        }

        $userCount = User::where('role', $role->slug)->count();
        if ($userCount > 0) {
            return response()->json([
                'success' => false,
                'message' => "Role tidak dapat dihapus karena masih digunakan oleh {$userCount} pengguna. Pindahkan pengguna ke role lain terlebih dahulu.",
            ], 422);
        }

        $role->delete();

        return response()->json([
            'success' => true,
            'message' => 'Role berhasil dihapus.',
        ]);
    }

    /**
     * GET /super-admin/roles/{slug}/users — list users with this role.
     */
    public function users(string $slug): JsonResponse
    {
        $role = Role::where('slug', $slug)->firstOrFail();

        $users = User::where('role', $slug)
            ->select('id', 'name', 'email', 'phone', 'is_active', 'created_at')
            ->orderBy('name')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => [
                'role'  => $role,
                'users' => $users,
                'total' => $users->count(),
            ],
        ]);
    }
}
