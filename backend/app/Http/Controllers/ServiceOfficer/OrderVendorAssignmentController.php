<?php

namespace App\Http\Controllers\ServiceOfficer;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderVendorAssignment;
use App\Models\VendorRoleMaster;
use App\Services\VendorAssignmentValidator;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * v1.24/v1.40 — Kelola vendor assignments per order.
 *
 * SO assign vendor internal (dari pool SM) atau external (consumer bawa sendiri).
 * Enforcement v1.40:
 * - Vendor dengan is_paid_by_sm=false → fee di-force 0
 * - Pemuka agama → source di-force external_consumer + user_id null
 *
 * Double-layer protection:
 * - VendorAssignmentValidator (service) — input normalization
 * - OrderVendorAssignment model booted() — database-level safety
 */
class OrderVendorAssignmentController extends Controller
{
    public function __construct(private VendorAssignmentValidator $validator)
    {
    }

    /**
     * List semua vendor assignment untuk 1 order.
     */
    public function index(string $orderId)
    {
        $order = Order::findOrFail($orderId);

        $assignments = OrderVendorAssignment::where('order_id', $order->id)
            ->with([
                'vendorRole:id,role_code,role_name,category,is_paid_by_sm,icon',
                'user:id,name,phone,role',
                'assignedByUser:id,name',
            ])
            ->orderBy('created_at')
            ->get();

        return response()->json(['success' => true, 'data' => $assignments]);
    }

    /**
     * Assign vendor baru ke order.
     */
    public function store(Request $request, string $orderId)
    {
        $request->validate([
            'vendor_role_id'       => 'required|uuid|exists:vendor_role_master,id',
            'source'               => 'required|in:internal,external_consumer,external_so',
            'user_id'              => 'nullable|uuid|exists:users,id',
            'ext_name'             => 'nullable|string|max:255',
            'ext_phone'            => 'nullable|string|max:30',
            'ext_whatsapp'         => 'nullable|string|max:30',
            'ext_email'            => 'nullable|email|max:255',
            'ext_organization'     => 'nullable|string|max:255',
            'ext_notes'            => 'nullable|string',
            'scheduled_date'       => 'nullable|date',
            'scheduled_time'       => 'nullable|date_format:H:i',
            'activity_description' => 'nullable|string',
            'estimated_duration_hours' => 'nullable|numeric|min:0|max:24',
            'fee'                  => 'nullable|numeric|min:0',
            'fee_source'           => 'nullable|in:package,addon,amendment,manual',
            'requested_by_consumer'=> 'nullable|boolean',
            'notes'                => 'nullable|string',
        ]);

        $order = Order::findOrFail($orderId);

        // Apply v1.40 normalization: fee=0 untuk vendor yg tidak dibayar SM, dll.
        $input = $this->validator->normalize($request->all());

        $assignment = OrderVendorAssignment::create(array_merge($input, [
            'order_id'    => $order->id,
            'assigned_by' => $request->user()->id,
            'assigned_at' => now(),
            'status'      => 'assigned',
        ]));

        $rule = $this->validator->getRuleForRole($request->vendor_role_id);

        return response()->json([
            'success' => true,
            'data'    => $assignment->load(['vendorRole', 'user']),
            'enforcement' => $rule, // transparan ke UI: apa yg di-force oleh v1.40
        ], 201);
    }

    /**
     * Update assignment (schedule, status, notes, dll).
     * Fee/source tidak bisa diubah untuk pemuka_agama — booted() model protect.
     */
    public function update(Request $request, string $orderId, string $assignmentId)
    {
        $request->validate([
            'scheduled_date'       => 'nullable|date',
            'scheduled_time'       => 'nullable|date_format:H:i',
            'activity_description' => 'nullable|string',
            'estimated_duration_hours' => 'nullable|numeric|min:0|max:24',
            'fee'                  => 'nullable|numeric|min:0',
            'fee_source'           => 'nullable|in:package,addon,amendment,manual',
            'notes'                => 'nullable|string',
        ]);

        $assignment = OrderVendorAssignment::where('order_id', $orderId)
            ->findOrFail($assignmentId);

        $input = $request->only([
            'scheduled_date', 'scheduled_time', 'activity_description',
            'estimated_duration_hours', 'fee', 'fee_source', 'notes',
        ]);

        // Re-apply normalization kalau user coba update fee
        if (isset($input['fee'])) {
            $input['vendor_role_id'] = $assignment->vendor_role_id;
            $input = $this->validator->normalize($input);
            unset($input['vendor_role_id']);
        }

        $assignment->update($input);

        return response()->json(['success' => true, 'data' => $assignment->fresh()]);
    }

    /**
     * Vendor confirm bisa hadir (untuk internal vendor yang punya app).
     */
    public function confirm(Request $request, string $orderId, string $assignmentId)
    {
        $assignment = OrderVendorAssignment::where('order_id', $orderId)
            ->findOrFail($assignmentId);

        if ($assignment->status !== 'assigned') {
            return response()->json([
                'success' => false,
                'message' => "Hanya status 'assigned' yang bisa dikonfirmasi.",
            ], 422);
        }

        $assignment->update([
            'status' => 'confirmed',
            'confirmed_at' => now(),
        ]);

        return response()->json(['success' => true, 'data' => $assignment->fresh()]);
    }

    /**
     * Vendor tolak assignment (dengan alasan).
     */
    public function decline(Request $request, string $orderId, string $assignmentId)
    {
        $request->validate([
            'reason' => 'required|string|max:500',
        ]);

        $assignment = OrderVendorAssignment::where('order_id', $orderId)
            ->findOrFail($assignmentId);

        $assignment->update([
            'status' => 'declined',
            'declined_reason' => $request->reason,
        ]);

        return response()->json(['success' => true, 'data' => $assignment->fresh()]);
    }

    /**
     * SO mark sudah hubungi vendor external via WA.
     */
    public function markWaContacted(Request $request, string $orderId, string $assignmentId)
    {
        $assignment = OrderVendorAssignment::where('order_id', $orderId)
            ->findOrFail($assignmentId);

        $assignment->update([
            'wa_contacted' => true,
            'wa_contacted_at' => now(),
            'wa_contacted_by' => $request->user()->id,
        ]);

        return response()->json(['success' => true, 'data' => $assignment->fresh()]);
    }

    /**
     * Hapus assignment (jika salah assign).
     */
    public function destroy(string $orderId, string $assignmentId)
    {
        $assignment = OrderVendorAssignment::where('order_id', $orderId)
            ->findOrFail($assignmentId);

        // Hanya hapus jika belum confirmed / present / completed
        if (in_array($assignment->status, ['present', 'completed'])) {
            return response()->json([
                'success' => false,
                'message' => "Tidak bisa hapus vendor yang sudah hadir / selesai.",
            ], 422);
        }

        $assignment->delete();

        return response()->json(['success' => true, 'message' => 'Assignment dihapus.']);
    }

    /**
     * List vendor roles yg tersedia — untuk dropdown di form.
     * Include info is_paid_by_sm untuk show enforcement di UI.
     */
    public function availableRoles()
    {
        $roles = VendorRoleMaster::where('is_active', true)
            ->orderBy('sort_order')
            ->get([
                'id', 'role_code', 'role_name', 'description',
                'category', 'app_role', 'is_paid_by_sm',
                'requires_attendance', 'requires_bukti_foto', 'icon',
            ]);

        return response()->json(['success' => true, 'data' => $roles]);
    }
}
