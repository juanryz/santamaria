<?php

namespace App\Http\Middleware;

use App\Models\ActivityLog;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class ActivityLogger
{
    /**
     * Routes to skip logging (high frequency, low value).
     */
    private const SKIP_PATHS = [
        'v1/config',
        'v1/config/thresholds',
        'v1/health',
        'v1/api-docs',
    ];

    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);

        // Only log authenticated requests
        $user = $request->user();
        if (!$user) {
            return $response;
        }

        // Skip high-frequency / low-value endpoints
        $path = $request->path();
        foreach (self::SKIP_PATHS as $skip) {
            if ($path === $skip || str_starts_with($path, $skip . '/')) {
                return $response;
            }
        }

        try {
            ActivityLog::create([
                'user_id'   => $user->id,
                'action'    => $request->method() . ' ' . ($request->route()?->getName() ?? $path),
                'screen'    => $request->header('X-Screen'),
                'metadata'  => $request->route()?->parameters() ?: [],
                'ip_address'=> $request->ip(),
                'device_id' => $request->header('X-Device-Id'),
            ]);
        } catch (\Throwable $e) {
            // Never let logging break the request
            \Illuminate\Support\Facades\Log::warning('ActivityLogger failed: ' . $e->getMessage());
        }

        return $response;
    }
}
