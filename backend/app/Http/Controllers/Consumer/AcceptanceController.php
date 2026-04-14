<?php

namespace App\Http\Controllers\Consumer;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\TermsAndConditions;
use App\Services\OrderStateMachine;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class AcceptanceController extends Controller
{
    /**
     * GET /consumer/orders/{id}/acceptance — Get T&C and order summary for signing.
     */
    public function show(Request $request, string $orderId)
    {
        $order = Order::with('package')
            ->where('pic_user_id', $request->user()->id)
            ->findOrFail($orderId);

        $terms = TermsAndConditions::current();

        return response()->json([
            'success' => true,
            'data' => [
                'order' => [
                    'order_number' => $order->order_number,
                    'deceased_name' => $order->deceased_name,
                    'package_name' => $order->package?->name,
                    'final_price' => $order->final_price,
                    'scheduled_at' => $order->scheduled_at,
                ],
                'terms' => $terms ? [
                    'version' => $terms->version,
                    'title' => $terms->title,
                    'content' => $terms->content,
                ] : null,
                'already_signed' => $order->acceptance_signed_at !== null,
            ],
        ]);
    }

    /**
     * POST /consumer/orders/{id}/acceptance/sign — Consumer signs T&C.
     * Accepts: signature image (base64 or upload), agreement checkbox.
     */
    public function sign(Request $request, string $orderId)
    {
        $request->validate([
            'agreed' => 'required|boolean|accepted',
            'signature_path' => 'nullable|string',
            'pj_name' => 'required|string|max:255',
            'pj_relation' => 'required|string|max:100',
        ]);

        $order = Order::where('pic_user_id', $request->user()->id)
            ->findOrFail($orderId);

        if ($order->acceptance_signed_at) {
            return response()->json(['success' => false, 'message' => 'Order sudah ditandatangani'], 422);
        }

        $currentTerms = TermsAndConditions::current();

        $order->update([
            'acceptance_signed_at' => now(),
            'acceptance_signed_by_name' => $request->pj_name,
            'acceptance_signed_relation' => $request->pj_relation,
            'acceptance_signature_path' => $request->signature_path,
            'acceptance_terms_version' => $currentTerms?->version,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Surat Penerimaan Layanan berhasil ditandatangani',
            'data' => $order->fresh(),
        ]);
    }
}
