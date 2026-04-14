<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\Route;

class ApiDocController extends Controller
{
    /**
     * GET /api-docs — Auto-generated API documentation summary.
     * Lists all registered API routes with method, URI, and middleware.
     */
    public function index()
    {
        $routes = collect(Route::getRoutes())
            ->filter(fn($route) => str_starts_with($route->uri(), 'api/v1'))
            ->map(fn($route) => [
                'method' => implode('|', $route->methods()),
                'uri' => '/' . $route->uri(),
                'middleware' => collect($route->middleware())->filter(fn($m) => str_starts_with($m, 'role:'))->values(),
                'action' => $route->getActionName() !== 'Closure' ? $route->getActionName() : 'Closure',
            ])
            ->values();

        $grouped = $routes->groupBy(function ($route) {
            $parts = explode('/', $route['uri']);
            return $parts[3] ?? 'root'; // group by first path segment after /api/v1/
        });

        return response()->json([
            'success' => true,
            'total_endpoints' => $routes->count(),
            'data' => $grouped,
        ]);
    }
}
