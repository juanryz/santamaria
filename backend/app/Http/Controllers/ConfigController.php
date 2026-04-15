<?php

namespace App\Http\Controllers;

use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Enums\CoffinStatus;
use App\Enums\AttendanceStatus;
use App\Enums\EquipmentItemStatus;
use App\Enums\ProcurementStatus;
use App\Enums\ViolationType;
use App\Enums\NotificationPriority;
use App\Enums\UserRole;
use App\Models\OrderStatusLabel;
use App\Models\TripLegMaster;
use App\Models\VendorRoleMaster;
use App\Models\TermsAndConditions;
use App\Models\SystemThreshold;
use App\Models\SystemSetting;
use App\Services\OrderStateMachine;
use Illuminate\Http\Request;

class ConfigController extends Controller
{
    /**
     * GET /config — Frontend fetches all dynamic config on app start.
     * NO hardcoded values in frontend — semua dari sini.
     */
    public function index(Request $request)
    {
        return response()->json([
            'success' => true,
            'data' => [
                // Thresholds (dynamic, editable by HRD/Owner)
                'thresholds' => SystemThreshold::all()->pluck('value', 'key'),

                // Settings
                'settings' => SystemSetting::all()->pluck('value', 'key'),

                // Enum labels — frontend gunakan ini untuk badge/status display
                'enums' => [
                    'order_status' => collect(OrderStatus::cases())->map(fn($s) => [
                        'value' => $s->value,
                        'label' => $s->label(),
                    ])->values(),

                    'payment_status' => collect(PaymentStatus::cases())->map(fn($s) => [
                        'value' => $s->value,
                        'label' => $s->label(),
                    ])->values(),

                    'coffin_status' => collect(CoffinStatus::cases())->map(fn($s) => [
                        'value' => $s->value,
                        'label' => $s->label(),
                    ])->values(),

                    'attendance_status' => collect(AttendanceStatus::cases())->map(fn($s) => [
                        'value' => $s->value,
                        'label' => $s->label(),
                        'color' => $s->color(),
                    ])->values(),

                    'equipment_status' => collect(EquipmentItemStatus::cases())->map(fn($s) => [
                        'value' => $s->value,
                        'label' => $s->label(),
                    ])->values(),

                    'procurement_status' => collect(ProcurementStatus::cases())->map(fn($s) => [
                        'value' => $s->value,
                        'label' => $s->label(),
                    ])->values(),

                    'violation_type' => collect(ViolationType::cases())->map(fn($v) => [
                        'value' => $v->value,
                        'label' => $v->label(),
                        'severity' => $v->severity(),
                        'threshold_key' => $v->thresholdKey(),
                    ])->values(),

                    'user_roles' => collect(UserRole::cases())->map(fn($r) => [
                        'value' => $r->value,
                    ])->values(),
                ],

                // DB-driven labels (from master tables — editable by Super Admin)
                'status_labels' => OrderStatusLabel::where('is_active', true)
                    ->orderBy('sort_order')
                    ->get(['status_code', 'consumer_label', 'consumer_description', 'internal_label', 'icon', 'color', 'show_to_consumer', 'show_map_tracking']),

                'trip_legs' => TripLegMaster::where('is_active', true)
                    ->orderBy('sort_order')
                    ->get(['leg_code', 'leg_name', 'category', 'requires_proof_photo', 'triggers_gate', 'icon']),

                'vendor_roles' => VendorRoleMaster::where('is_active', true)
                    ->orderBy('sort_order')
                    ->get(['role_code', 'role_name', 'category', 'app_role', 'requires_attendance', 'requires_bukti_foto', 'icon']),

                'terms_and_conditions' => TermsAndConditions::current()?->only(['version', 'title', 'content', 'effective_date']),

                'order_state_machine' => OrderStateMachine::transitionMap(),

                // Dynamic roles — full list so Flutter never needs to hardcode
                'roles' => \App\Models\Role::where('is_active', true)
                    ->orderBy('sort_order')
                    ->get(['slug', 'label', 'description', 'can_have_inventory', 'is_vendor',
                           'is_viewer_only', 'can_manage_orders', 'receives_order_alarm',
                           'color_hex', 'icon_name', 'sort_order'])
                    ->toArray(),
            ],
        ]);
    }

    /**
     * GET /config/thresholds — lightweight, just thresholds
     */
    public function thresholds()
    {
        return response()->json([
            'success' => true,
            'data' => SystemThreshold::all()->pluck('value', 'key'),
        ]);
    }
}
