<?php

namespace App\Http\Controllers\Auth;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\User;
use App\Models\ConsumerStorageQuota;
use App\Models\SystemSetting;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class AuthController extends Controller
{
    public function registerConsumer(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'phone' => 'required|string|max:20|unique:users',
            'pin' => 'required|string|min:4|max:6',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = User::create([
            'name' => $request->name,
            'phone' => $request->phone,
            'role' => UserRole::CONSUMER->value,
            'pin' => $request->pin,
            'is_active' => true,
        ]);

        // Create storage quota
        $quotaGb = (int) SystemSetting::getValue('consumer_storage_quota_gb', 1);
        ConsumerStorageQuota::create([
            'user_id' => $user->id,
            'quota_bytes' => $quotaGb * 1024 * 1024 * 1024,
            'used_bytes' => 0
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'data' => [
                'user' => $user,
                'access_token' => $token,
                'token_type' => 'Bearer',
            ],
            'message' => 'Consumer registered successfully'
        ], 201);
    }

    public function loginConsumer(Request $request)
    {
        $request->validate([
            'phone' => 'required|string',
            'pin' => 'required|string',
        ]);

        $user = User::where('phone', $request->phone)
            ->where('role', UserRole::CONSUMER->value)
            ->first();

        if (!$user || !Hash::check($request->pin, $user->pin)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid phone or PIN'
            ], 401);
        }

        if (!$user->is_active) {
            return response()->json([
                'success' => false,
                'message' => 'Account is inactive'
            ], 403);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'data' => [
                'user' => $user,
                'access_token' => $token,
                'token_type' => 'Bearer',
            ],
            'message' => 'Login successful'
        ]);
    }

    public function loginInternal(Request $request)
    {
        $request->validate([
            'identifier' => 'required|string', // phone or email
            'password' => 'required|string',
        ]);

        $user = User::where(function($query) use ($request) {
                $query->where('phone', $request->identifier)
                      ->orWhere('email', $request->identifier);
            })
            ->where('role', '!=', UserRole::CONSUMER->value)
            ->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid credentials'
            ], 401);
        }

        if (!$user->is_active) {
            return response()->json([
                'success' => false,
                'message' => 'Account is inactive'
            ], 403);
        }

        if ($user->role === UserRole::SUPPLIER->value && !$user->is_verified_supplier) {
            return response()->json([
                'success' => false,
                'message' => 'Akun supplier belum diverifikasi. Hubungi administrator.'
            ], 403);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'data' => [
                'user' => $user,
                'access_token' => $token,
                'token_type' => 'Bearer',
            ],
            'message' => 'Login successful'
        ]);
    }

    /**
     * Reset consumer PIN using the name of their most recent deceased.
     * QA 1.1: POST /auth/reset-pin
     */
    public function resetPin(Request $request)
    {
        $request->validate([
            'phone'         => 'required|string',
            'deceased_name' => 'required|string',
            'new_pin'       => 'required|string|min:4|max:6',
        ]);

        $user = User::where('phone', $request->phone)
            ->where('role', UserRole::CONSUMER->value)
            ->first();

        if (!$user) {
            return response()->json(['success' => false, 'message' => 'Nomor HP tidak ditemukan.'], 404);
        }

        $lastOrder = Order::where('pic_user_id', $user->id)
            ->orderBy('created_at', 'desc')
            ->first();

        if (!$lastOrder || strcasecmp(trim($lastOrder->deceased_name), trim($request->deceased_name)) !== 0) {
            return response()->json(['success' => false, 'message' => 'Nama almarhum tidak cocok.'], 422);
        }

        $user->update(['pin' => $request->new_pin]);

        return response()->json(['success' => true, 'message' => 'PIN berhasil direset.']);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logged out successfully'
        ]);
    }

    public function me(Request $request)
    {
        return response()->json([
            'success' => true,
            'data' => [
                'user' => $request->user()
            ]
        ]);
    }

    public function updateFcmToken(Request $request)
    {
        $request->validate([
            'fcm_token' => 'required|string',
        ]);

        $request->user()->update([
            'device_fcm_token' => $request->fcm_token
        ]);

        return response()->json([
            'success' => true,
            'message' => 'FCM token updated successfully'
        ]);
    }
    /**
     * Biometric login — re-authenticate using a stored token.
     * The Flutter app stores the auth token when biometric is enabled,
     * and sends it back here to get a fresh session.
     */
    public function loginBiometric(Request $request)
    {
        $request->validate([
            'biometric_token' => 'required|string',
        ]);

        // Find user by their existing token
        $tokenRecord = \Laravel\Sanctum\PersonalAccessToken::findToken($request->biometric_token);

        if (!$tokenRecord) {
            return response()->json([
                'success' => false,
                'message' => 'Token biometrik tidak valid. Silakan login ulang.',
            ], 401);
        }

        $user = $tokenRecord->tokenable;

        if (!$user || !$user->is_active) {
            return response()->json([
                'success' => false,
                'message' => 'Akun tidak aktif.',
            ], 403);
        }

        // Create fresh token
        $newToken = $user->createToken('biometric_auth')->plainTextToken;

        return response()->json([
            'success' => true,
            'data' => [
                'user' => $user,
                'access_token' => $newToken,
                'token_type' => 'Bearer',
            ],
            'message' => 'Biometric login successful',
        ]);
    }

    public function updatePassword(Request $request)
    {
        $user = $request->user();
        $isConsumer = $user->role === UserRole::CONSUMER->value;

        $request->validate([
            'current_password' => 'required|string',
            'new_password' => $isConsumer ? 'required|string|min:4|max:6' : 'required|string|min:8',
        ]);

        $currentField = $isConsumer ? 'pin' : 'password';

        if (!Hash::check($request->current_password, $user->$currentField)) {
            return response()->json([
                'success' => false,
                'message' => 'Password/PIN saat ini salah.'
            ], 422);
        }

        $user->update([
            $currentField => $request->new_password
        ]);

        return response()->json([
            'success' => true,
            'message' => ($isConsumer ? 'PIN' : 'Password') . ' berhasil diperbarui.'
        ]);
    }
}
