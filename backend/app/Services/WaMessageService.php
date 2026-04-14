<?php

namespace App\Services;

use App\Models\WaMessageTemplate;
use App\Models\WaMessageLog;
use App\Models\Order;
use App\Models\SystemSetting;
use Illuminate\Support\Facades\Log;

/**
 * WhatsApp message service — renders templates from DB and generates deep links.
 * Template TIDAK di-hardcode — semua dari wa_message_templates.
 */
class WaMessageService
{
    /**
     * Send a WA message by template code.
     * Returns the deep link URL (tidak kirim otomatis — user klik link).
     */
    public static function generateMessage(
        string $templateCode,
        string $phone,
        array $data,
        ?string $orderId = null,
        ?string $sentBy = null
    ): ?array {
        $template = WaMessageTemplate::where('template_code', $templateCode)
            ->where('is_active', true)
            ->first();

        if (!$template) {
            Log::warning("WA template not found: {$templateCode}");
            return null;
        }

        // Add system-level placeholders
        $data['office_phone'] = SystemSetting::getValue('office_phone', '024-1234567');
        $data['playstore_url'] = SystemSetting::getValue('playstore_url', '-');
        $data['appstore_url'] = SystemSetting::getValue('appstore_url', '-');

        // Render template
        $message = $template->render($data);

        // Normalize phone
        $normalized = preg_replace('/[^0-9]/', '', $phone);
        if (str_starts_with($normalized, '0')) {
            $normalized = '62' . substr($normalized, 1);
        } elseif (!str_starts_with($normalized, '62')) {
            $normalized = '62' . $normalized;
        }

        // Generate deep link
        $deepLink = 'https://wa.me/' . $normalized . '?text=' . urlencode($message);

        // Log
        if ($sentBy) {
            WaMessageLog::create([
                'template_id' => $template->id,
                'order_id' => $orderId,
                'sent_by' => $sentBy,
                'recipient_phone' => $phone,
                'recipient_name' => $data['consumer_name'] ?? $data['vendor_name'] ?? $phone,
                'message_content' => $message,
                'sent_at' => now(),
            ]);
        }

        return [
            'deep_link' => $deepLink,
            'message' => $message,
            'template_code' => $templateCode,
            'recipient_phone' => $normalized,
        ];
    }

    /**
     * Generate WA message for order confirmation to consumer.
     */
    public static function orderConfirmedToConsumer(Order $order, string $sentBy): ?array
    {
        $data = [
            'consumer_name' => $order->pic_name ?? $order->pic?->name ?? 'Bapak/Ibu',
            'almarhum_name' => $order->deceased_name ?? '-',
            'order_number' => $order->order_number,
            'package_name' => $order->package?->name ?? '-',
            'scheduled_date' => $order->scheduled_at?->format('d F Y') ?? '-',
            'scheduled_time' => $order->scheduled_at?->format('H:i') ?? '-',
            'location' => $order->destination_address ?? '-',
            'so_name' => $order->soUser?->name ?? '-',
        ];

        return self::generateMessage(
            'ORDER_CONFIRMED_CONSUMER',
            $order->pic_phone ?? $order->pic?->phone ?? '',
            $data,
            $order->id,
            $sentBy
        );
    }
}
