<?php

namespace App\Services;

use App\Enums\UserRole;
use App\Models\User;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class NotificationService
{
    private const TOKEN_CACHE_KEY = 'fcm_access_token';
    private const TOKEN_CACHE_TTL = 55 * 60; // 55 min — access tokens expire at 60 min

    /**
     * Send a cross-platform notification.
     *
     * $target can be:
     *   - a User model instance       → notify that specific user
     *   - a UUID string (user id)     → resolved to User, then notified
     *   - a role string / UserRole    → notify all users with that role
     */
    public static function send(User|UserRole|string $target, string $priority, string $title, string $body, array $data = [])
    {
        if ($target instanceof UserRole) {
            $target = $target->value;
        }

        // Resolve a UUID string to a User model.
        if (is_string($target) && strlen($target) === 36 && str_contains($target, '-')) {
            $target = User::find($target);
            if (!$target) {
                Log::warning("NotificationService: user not found for given id.");
                return;
            }
        }

        Log::info("Notification Triggered: [$title] -> " . ($target instanceof User ? $target->name : $target));

        // Collect FCM tokens.
        $tokens = [];
        if ($target instanceof User) {
            if ($target->device_fcm_token) {
                $tokens[] = $target->device_fcm_token;
            }
        } else {
            $tokens = User::where('role', $target)
                ->whereNotNull('device_fcm_token')
                ->pluck('device_fcm_token')
                ->toArray();
        }

        if (empty($tokens)) {
            Log::warning("No FCM tokens for target: " . ($target instanceof User ? $target->id : $target));
            return;
        }

        return self::dispatch($tokens, $title, $body, $priority, $data);
    }

    public static function sendToRole(string $role, string $priority, string $title, string $body, array $data = [])
    {
        return self::send($role, $priority, $title, $body, $data);
    }

    /**
     * Send HRD violation alert to HRD role + Owner.
     * Severity determines priority level.
     */
    public static function sendHrdViolationAlert(\App\Models\HrdViolation $violation): void
    {
        $user = User::find($violation->violated_by);
        if (!$user) return;

        $severityLabel = match ($violation->severity) {
            'high'   => '🔴 URGENT',
            'medium' => '🟡 PERHATIAN',
            default  => '🔵 INFO',
        };

        $hrdPriority   = $violation->severity === 'high' ? 'ALARM' : 'HIGH';
        $ownerPriority = $violation->severity === 'high' ? 'HIGH'  : 'NORMAL';

        // Alarm ke HRD
        self::sendToRole('hrd', $hrdPriority,
            "{$severityLabel} Pelanggaran Ketentuan",
            "{$user->name} ({$user->role}): {$violation->description}",
            ['violation_id' => $violation->id, 'action' => 'hrd_review']
        );

        // Notif ke Owner
        self::sendToRole('owner', $ownerPriority,
            "Catatan HRD: {$user->name}",
            $violation->description,
            ['violation_id' => $violation->id]
        );
    }

    // -------------------------------------------------------------------------
    // FCM v1 HTTP API
    // -------------------------------------------------------------------------

    private static function dispatch(array $tokens, string $title, string $body, string $priority, array $data): void
    {
        $projectId = config('services.fcm.project_id');

        if (empty($projectId)) {
            // FCM not yet configured — fall back to log only.
            self::logFallback($tokens, $title, $body, $priority);
            return;
        }

        $accessToken = self::getAccessToken();
        if (!$accessToken) {
            Log::error("FCM: could not obtain access token.");
            return;
        }

        $androidPriority = in_array($priority, ['HIGH', 'VERY_HIGH', 'ALARM'], true) ? 'high' : 'normal';
        $sound           = in_array($priority, ['HIGH', 'VERY_HIGH', 'ALARM'], true) ? 'alarm_sound' : 'default';
        $channelId       = match (true) {
            in_array($priority, ['ALARM', 'VERY_HIGH'], true) => 'santa_maria_alarm',
            $priority === 'HIGH'                              => 'santa_maria_high',
            default                                           => 'santa_maria_normal',
        };

        // FCM v1 sends one message per token (multicast via batch is deprecated).
        foreach ($tokens as $token) {
            $payload = [
                'message' => [
                    'token'        => $token,
                    'notification' => [
                        'title' => $title,
                        'body'  => $body,
                    ],
                    'data'    => array_map('strval', $data),
                    'android' => [
                        'priority'     => $androidPriority,
                        'notification' => [
                            'sound'      => $sound,
                            'channel_id' => $channelId,
                        ],
                    ],
                    'apns' => [
                        'payload' => [
                            'aps' => [
                                'sound'             => $sound . '.wav',
                                'content-available' => 1,
                            ],
                        ],
                        'headers' => [
                            'apns-priority' => $androidPriority === 'high' ? '10' : '5',
                        ],
                    ],
                ],
            ];

            $response = Http::withToken($accessToken)
                ->post("https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send", $payload);

            if (!$response->successful()) {
                Log::error("FCM send failed for token [{$token}]: " . $response->body());
            }
        }
    }

    /**
     * Obtain a short-lived OAuth2 access token using the service-account JSON key.
     * The token is cached for 55 minutes to avoid unnecessary round-trips.
     */
    private static function getAccessToken(): ?string
    {
        return Cache::remember(self::TOKEN_CACHE_KEY, self::TOKEN_CACHE_TTL, function () {
            $credentialsPath = config('services.fcm.credentials_path');

            if (!$credentialsPath || !file_exists($credentialsPath)) {
                Log::error("FCM: credentials file not found at [{$credentialsPath}].");
                return null;
            }

            $credentials = json_decode(file_get_contents($credentialsPath), true);
            if (empty($credentials['private_key']) || empty($credentials['client_email'])) {
                Log::error("FCM: invalid credentials JSON.");
                return null;
            }

            // Build and sign the JWT for the Google OAuth2 token endpoint.
            $now    = time();
            $header = base64_encode(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
            $claim  = base64_encode(json_encode([
                'iss'   => $credentials['client_email'],
                'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
                'aud'   => 'https://oauth2.googleapis.com/token',
                'exp'   => $now + 3600,
                'iat'   => $now,
            ]));

            $unsigned = "{$header}.{$claim}";
            openssl_sign($unsigned, $signature, $credentials['private_key'], OPENSSL_ALGO_SHA256);
            $jwt = $unsigned . '.' . base64_encode($signature);

            $response = Http::asForm()->post('https://oauth2.googleapis.com/token', [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion'  => $jwt,
            ]);

            if (!$response->successful()) {
                Log::error("FCM: OAuth2 token request failed: " . $response->body());
                return null;
            }

            return $response->json('access_token');
        });
    }

    /** Log-only fallback used when FCM_PROJECT_ID is not set (local dev). */
    private static function logFallback(array $tokens, string $title, string $body, string $priority): void
    {
        Log::debug("[FCM mock] Would send to " . count($tokens) . " device(s).", [
            'title'    => $title,
            'body'     => $body,
            'priority' => $priority,
        ]);
    }
}
