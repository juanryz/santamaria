<?php

namespace App\Services\AI;

use App\Models\AiLog;
use OpenAI\Laravel\Facades\OpenAI;

class BaseAiService
{
    protected function callOpenAI(string $feature, array $messages, array $tools = [], ?string $orderId = null): array
    {
        $startTime = microtime(true);
        try {
            $params = [
                'model' => config('services.openai.model', 'gpt-4o-mini'),
                'messages' => $messages,
                'max_tokens' => (int) config('services.openai.max_tokens', 2000),
            ];
            
            if (!empty($tools)) {
                $params['tools'] = $tools;
            }

            $response = OpenAI::chat()->create($params);
            $elapsed = (int)((microtime(true) - $startTime) * 1000);

            AiLog::create([
                'feature' => $feature,
                'order_id' => $orderId,
                'user_id' => auth()->id(),
                'prompt_tokens' => $response->usage->promptTokens,
                'completion_tokens' => $response->usage->completionTokens,
                'total_tokens' => $response->usage->totalTokens,
                'estimated_cost_usd' => $response->usage->totalTokens * 0.00000015,
                'response_time_ms' => $elapsed,
                'status' => 'success',
            ]);

            return [
                'success' => true,
                'content' => $response->choices[0]->message->content
            ];
        } catch (\Exception $e) {
            AiLog::create([
                'feature' => $feature,
                'order_id' => $orderId,
                'user_id' => auth()->id(),
                'status' => 'failed',
                'error_message' => $e->getMessage(),
            ]);
            return [
                'success' => false,
                'error' => $e->getMessage()
            ];
        }
    }
}
