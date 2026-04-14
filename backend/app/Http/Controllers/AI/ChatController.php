<?php

namespace App\Http\Controllers\AI;

use App\Http\Controllers\Controller;
use App\Services\AI\ChatbotService;
use Illuminate\Http\Request;

class ChatController extends Controller
{
    protected $chatbotService;

    public function __construct(ChatbotService $chatbotService)
    {
        $this->chatbotService = $chatbotService;
    }

    public function chat(Request $request)
    {
        $request->validate([
            'messages' => 'required|array',
            'messages.*.role' => 'required|in:user,assistant',
            'messages.*.content' => 'required|string',
        ]);

        $result = $this->chatbotService->chat($request->messages);

        if ($result['success']) {
            // Attempt to decode JSON if AI returned JSON
            $content = $result['content'];
            $decoded = json_decode($content, true);

            return response()->json([
                'success' => true,
                'data' => $decoded ?: $content
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => $result['error']
        ], 500);
    }
}
