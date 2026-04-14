<?php

namespace App\Traits;

use Illuminate\Http\JsonResponse;

/**
 * Standardized API response trait — semua controller harus mengembalikan format yang konsisten.
 * Tidak ada respons yang di-hardcode formatnya di controller — gunakan trait ini.
 */
trait ApiResponse
{
    protected function success($data = null, string $message = 'Success', int $code = 200): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => $data,
        ], $code);
    }

    protected function created($data = null, string $message = 'Created'): JsonResponse
    {
        return $this->success($data, $message, 201);
    }

    protected function error(string $message = 'Error', int $code = 400, $errors = null): JsonResponse
    {
        $response = [
            'success' => false,
            'message' => $message,
        ];

        if ($errors !== null) {
            $response['errors'] = $errors;
        }

        return response()->json($response, $code);
    }

    protected function notFound(string $message = 'Data tidak ditemukan'): JsonResponse
    {
        return $this->error($message, 404);
    }

    protected function forbidden(string $message = 'Akses ditolak'): JsonResponse
    {
        return $this->error($message, 403);
    }

    protected function validationError(string $message = 'Data tidak valid', $errors = null): JsonResponse
    {
        return $this->error($message, 422, $errors);
    }

    protected function paginated($query, int $perPage = 20): JsonResponse
    {
        $paginated = $query->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => $paginated->items(),
            'meta' => [
                'current_page' => $paginated->currentPage(),
                'last_page' => $paginated->lastPage(),
                'per_page' => $paginated->perPage(),
                'total' => $paginated->total(),
            ],
        ]);
    }
}
