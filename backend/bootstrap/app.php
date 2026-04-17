<?php

use Illuminate\Database\QueryException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->alias([
            'role' => \App\Http\Middleware\EnsureRole::class,
            'not_viewer' => \App\Http\Middleware\EnsureNotViewer::class,
            'owner_readonly' => \App\Http\Middleware\OwnerReadOnly::class,
        ]);

        // Global: block write ops for viewer accounts on ALL API routes
        $middleware->appendToGroup('api', \App\Http\Middleware\EnsureNotViewer::class);

        // Log every authenticated API request to activity_logs
        $middleware->appendToGroup('api', \App\Http\Middleware\ActivityLogger::class);
    })
    ->withExceptions(function (Exceptions $exceptions): void {

        // Semua error API dikembalikan sebagai JSON yang ramah pengguna
        $exceptions->render(function (\Throwable $e, Request $request) {
            if (! $request->is('api/*')) {
                return null; // biarkan handler default untuk non-API
            }

            // Validasi form
            if ($e instanceof ValidationException) {
                return response()->json([
                    'success' => false,
                    'message' => 'Data yang dikirim tidak lengkap atau tidak valid.',
                    'errors'  => $e->errors(),
                ], 422);
            }

            // Resource tidak ditemukan
            if ($e instanceof NotFoundHttpException) {
                return response()->json([
                    'success' => false,
                    'message' => 'Data yang diminta tidak ditemukan.',
                ], 404);
            }

            // Error HTTP umum (403, 401, dll)
            if ($e instanceof HttpException) {
                $msg = match ($e->getStatusCode()) {
                    401 => 'Sesi Anda sudah berakhir. Silakan login kembali.',
                    403 => 'Anda tidak memiliki akses untuk melakukan tindakan ini.',
                    405 => 'Metode permintaan tidak diizinkan.',
                    429 => 'Terlalu banyak permintaan. Mohon tunggu sebentar.',
                    default => 'Terjadi kesalahan pada server.',
                };
                return response()->json([
                    'success' => false,
                    'message' => $msg,
                ], $e->getStatusCode());
            }

            // Error database — jangan tampilkan SQL mentah ke pengguna
            if ($e instanceof QueryException) {
                $msg = 'Terjadi masalah saat menyimpan data. Mohon coba lagi.';

                // Deteksi tipe constraint untuk pesan yang lebih spesifik
                $errMsg = $e->getMessage();
                if (str_contains($errMsg, 'not-null constraint')) {
                    $msg = 'Beberapa data wajib belum terisi. Mohon lengkapi semua field yang diperlukan.';
                } elseif (str_contains($errMsg, 'unique constraint') || str_contains($errMsg, 'duplicate key')) {
                    $msg = 'Data ini sudah terdaftar sebelumnya. Pastikan tidak ada duplikasi.';
                } elseif (str_contains($errMsg, 'foreign key constraint')) {
                    $msg = 'Data terkait tidak ditemukan. Pastikan referensi data sudah benar.';
                } elseif (str_contains($errMsg, 'value too long')) {
                    $msg = 'Salah satu isian terlalu panjang. Mohon periksa kembali.';
                }

                \Illuminate\Support\Facades\Log::error('QueryException: ' . $e->getMessage(), [
                    'sql'      => $e->getSql(),
                    'bindings' => $e->getBindings(),
                    'file'     => $e->getFile(),
                    'line'     => $e->getLine(),
                ]);

                return response()->json([
                    'success' => false,
                    'message' => $msg,
                ], 500);
            }

            // Error umum lainnya — log detail, tampilkan pesan ramah
            \Illuminate\Support\Facades\Log::error('Unhandled exception: ' . $e->getMessage(), [
                'file'  => $e->getFile(),
                'line'  => $e->getLine(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'success' => false,
                'message' => app()->isLocal()
                    ? $e->getMessage() // tampilkan detail hanya di mode development
                    : 'Terjadi kesalahan tak terduga. Tim teknis kami sudah diberitahu.',
            ], 500);
        });

    })->create();
