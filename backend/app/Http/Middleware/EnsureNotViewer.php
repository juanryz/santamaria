<?php

namespace App\Http\Middleware;

use App\Enums\UserRole;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureNotViewer
{
    /**
     * Block write operations for Viewer role and is_viewer flag.
     * Viewer = read-only. Tidak boleh POST/PUT/PATCH/DELETE apapun.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (!$user) {
            return $next($request);
        }

        $isViewer = $user->is_viewer || $user->role === UserRole::VIEWER->value;

        if ($isViewer && in_array($request->method(), ['POST', 'PUT', 'PATCH', 'DELETE'])) {
            return response()->json([
                'success' => false,
                'message' => 'Akses ditolak. Akun Viewer hanya bisa melihat data (read-only).',
            ], 403);
        }

        return $next($request);
    }
}
