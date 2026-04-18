<?php

namespace App\Http\Controllers\Finance;

use App\Http\Controllers\Controller;
use App\Models\ConsumerPaymentReminder;
use App\Models\Order;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * v1.40 — Log Reminder Pembayaran Consumer (H+4..H+10).
 *
 * Rule:
 * - Deadline bayar: 3 hari setelah prosesi (order completed).
 * - Toleransi: 7 hari tambahan (total 10 hari max).
 * - Reminder harian via WA template PAYMENT_REMINDER_CONSUMER.
 * - Lewat H+10 → alarm Purchasing + Owner.
 */
class ConsumerPaymentReminderController extends Controller
{
    /**
     * Log reminder yang sudah dikirim untuk 1 order.
     */
    public function index(string $orderId)
    {
        $reminders = ConsumerPaymentReminder::where('order_id', $orderId)
            ->orderBy('reminder_day')
            ->get();

        return response()->json(['success' => true, 'data' => $reminders]);
    }

    /**
     * Catat bahwa reminder hari ini sudah dikirim.
     * Idempotent: 1 reminder per (order, day).
     */
    public function store(Request $request, string $orderId)
    {
        $request->validate([
            'reminder_day'      => 'required|integer|between:4,10',
            'sent_via'          => 'required|in:whatsapp,sms,phone,app_notif',
            'recipient_phone'   => 'nullable|string|max:30',
            'template_used'     => 'nullable|string|max:50',
            'message_content'   => 'nullable|string',
        ]);

        $order = Order::findOrFail($orderId);

        $reminder = ConsumerPaymentReminder::firstOrCreate(
            [
                'order_id'     => $order->id,
                'reminder_day' => $request->reminder_day,
            ],
            [
                'reminder_date'   => now()->toDateString(),
                'sent_via'        => $request->sent_via,
                'sent_by'         => $request->user()->id,
                'recipient_phone' => $request->recipient_phone ?? $order->pic_phone,
                'template_used'   => $request->template_used ?? 'PAYMENT_REMINDER_CONSUMER',
                'message_content' => $request->message_content,
            ]
        );

        return response()->json([
            'success' => true,
            'data' => $reminder,
            'created' => $reminder->wasRecentlyCreated,
        ], $reminder->wasRecentlyCreated ? 201 : 200);
    }

    /**
     * Catat response consumer ke reminder.
     */
    public function logResponse(Request $request, string $orderId, string $reminderId)
    {
        $request->validate([
            'response_notes' => 'required|string',
        ]);

        $reminder = ConsumerPaymentReminder::where('order_id', $orderId)
            ->findOrFail($reminderId);

        $reminder->update([
            'consumer_responded' => true,
            'response_notes'     => $request->response_notes,
        ]);

        return response()->json(['success' => true, 'data' => $reminder->fresh()]);
    }

    /**
     * List order yang masih butuh reminder (overdue payments).
     * Dashboard Purchasing.
     */
    public function overdueOrders(Request $request)
    {
        $orders = Order::query()
            ->where('status', 'completed')
            ->where('payment_status', '!=', 'paid')
            ->whereNotNull('completed_at')
            ->where('completed_at', '<=', now()->subDays(3))
            ->with(['pic:id,name,phone'])
            ->get()
            ->map(function ($order) {
                $daysSinceComplete = $order->completed_at->diffInDays(now());
                $daysOverdueGrace = max(0, $daysSinceComplete - 3); // H+4 = day 1 of grace

                return [
                    'order_id'         => $order->id,
                    'order_number'     => $order->order_number,
                    'consumer_name'    => $order->pic?->name ?? $order->pic_name,
                    'consumer_phone'   => $order->pic?->phone ?? $order->pic_phone,
                    'completed_at'     => $order->completed_at,
                    'days_overdue'     => $daysOverdueGrace,
                    'escalation_level' => match (true) {
                        $daysOverdueGrace >= 8 => 'critical', // > H+10
                        $daysOverdueGrace >= 5 => 'high',     // H+8..H+10
                        $daysOverdueGrace >= 1 => 'normal',   // H+4..H+7
                        default => 'none',
                    },
                    'reminder_count'   => ConsumerPaymentReminder::where('order_id', $order->id)->count(),
                ];
            })
            ->filter(fn ($o) => $o['days_overdue'] > 0)
            ->values();

        return response()->json([
            'success' => true,
            'data'    => $orders,
            'total'   => $orders->count(),
        ]);
    }
}
