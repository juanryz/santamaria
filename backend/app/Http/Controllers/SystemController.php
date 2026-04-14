<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Order;
use App\Services\AI\BaseAiService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use OpenAI\Laravel\Facades\OpenAI;

class SystemController extends Controller
{
    public function health()
    {
        $dbStatus = 'ok';
        try {
            DB::connection()->getPdo();
        } catch (\Exception $e) {
            $dbStatus = 'error: ' . $e->getMessage();
        }

        $aiStatus = 'ok';
        try {
            // Simple model list check to verify API key
            OpenAI::models()->list();
        } catch (\Exception $e) {
            $aiStatus = 'error: ' . $e->getMessage();
        }

        return response()->json([
            'success' => true,
            'status' => 'healthy',
            'checks' => [
                'database' => $dbStatus,
                'openai' => $aiStatus,
                'storage' => config('filesystems.disks.r2.key') ? 'r2' : 'local_fallback',
            ]
        ]);
    }

    public function seedMetadata()
    {
        // One-time check for system settings
        return response()->json([
            'success' => true,
            'settings' => \App\Models\SystemSetting::all()
        ]);
    }
}
