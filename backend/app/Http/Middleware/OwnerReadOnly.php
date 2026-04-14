<?php

namespace App\Http\Middleware;

use App\Enums\UserRole;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * v1.27: Owner TIDAK bisa write ke master data — hanya Super Admin.
 * Owner bisa GET master data, tapi POST/PUT/DELETE diblokir.
 * Apply middleware ini ke route master data.
 */
class OwnerReadOnly
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (!$user) {
            return $next($request);
        }

        $isOwner = $user->role === UserRole::OWNER->value;

        if ($isOwner && in_array($request->method(), ['POST', 'PUT', 'PATCH', 'DELETE'])) {
            return response()->json([
                'success' => false,
                'message' => 'Owner hanya bisa melihat master data. Hubungi Super Admin untuk perubahan.',
            ], 403);
        }

        return $next($request);
    }
}
