<?php

namespace App\Http\Controllers;

use App\Models\WaMessageTemplate;
use App\Models\Order;
use App\Services\WaMessageService;
use Illuminate\Http\Request;

class WaController extends Controller
{
    /**
     * GET /wa/templates — list all active templates.
     */
    public function templates()
    {
        $templates = WaMessageTemplate::where('is_active', true)->orderBy('template_name')->get();
        return response()->json(['success' => true, 'data' => $templates]);
    }

    /**
     * POST /wa/send — Generate WA deep link for a template.
     * Frontend opens this link → user sends via WhatsApp app.
     */
    public function send(Request $request)
    {
        $request->validate([
            'template_code' => 'required|string',
            'phone' => 'required|string',
            'data' => 'required|array',
            'order_id' => 'nullable|uuid',
        ]);

        $result = WaMessageService::generateMessage(
            $request->template_code,
            $request->phone,
            $request->data,
            $request->order_id,
            $request->user()->id
        );

        if (!$result) {
            return response()->json(['success' => false, 'message' => 'Template tidak ditemukan'], 404);
        }

        return response()->json(['success' => true, 'data' => $result]);
    }

    /**
     * POST /wa/send-order/{orderId} — Quick send order confirmation to consumer.
     */
    public function sendOrderConfirmation(Request $request, string $orderId)
    {
        $order = Order::with(['pic', 'package', 'soUser'])->findOrFail($orderId);

        $result = WaMessageService::orderConfirmedToConsumer($order, $request->user()->id);

        if (!$result) {
            return response()->json(['success' => false, 'message' => 'Gagal generate WA link'], 500);
        }

        return response()->json(['success' => true, 'data' => $result]);
    }

    /**
     * GET /wa/logs — WA message history.
     */
    public function logs(Request $request)
    {
        $query = \App\Models\WaMessageLog::with(['template', 'order'])
            ->orderBy('sent_at', 'desc');

        if ($request->has('order_id')) {
            $query->where('order_id', $request->order_id);
        }

        return response()->json(['success' => true, 'data' => $query->paginate(20)]);
    }
}
