<?php

namespace App\Http\Controllers\Finance;

use App\Http\Controllers\Controller;
use App\Models\HrdViolation;
use App\Models\Order;
use App\Models\OrderFieldTeamPayment;
use App\Models\SystemThreshold;
use App\Services\NotificationService;
use App\Services\StorageService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FieldTeamController extends Controller
{
    // GET /finance/orders/{id}/field-team
    public function index(string $id): JsonResponse
    {
        Order::findOrFail($id);
        $members = OrderFieldTeamPayment::where('order_id', $id)->get();
        return response()->json($members);
    }

    // POST /finance/orders/{id}/field-team
    public function store(Request $request, string $id): JsonResponse
    {
        Order::findOrFail($id);

        $data = $request->validate([
            'name'             => 'required|string|max:255',
            'role_description' => 'required|string|max:255',
            'phone'            => 'nullable|string|max:20',
            'amount'           => 'required|numeric|min:0',
            'payment_method'   => 'required|in:cash,transfer',
            'notes'            => 'nullable|string',
            'is_absent'        => 'nullable|boolean',
        ]);

        $data['order_id'] = $id;

        $member = OrderFieldTeamPayment::create($data);

        // Jika ditandai tidak hadir, buat HRD violation
        if (!empty($data['is_absent']) && $data['is_absent']) {
            $this->createAbsenceViolation($member, $request->user()->id);
        }

        return response()->json($member, 201);
    }

    // PUT /finance/field-team/{memberId}/pay
    public function pay(Request $request, string $memberId): JsonResponse
    {
        $data = $request->validate([
            'method'         => 'required|in:cash,transfer',
            'amount'         => 'required|numeric|min:0',
            'receipt_photo'  => 'nullable|file|mimes:jpg,jpeg,png|max:10240',
        ]);

        $member = OrderFieldTeamPayment::where('payment_status', 'pending')->findOrFail($memberId);

        $receiptPath = null;
        if ($request->hasFile('receipt_photo')) {
            $receiptPath = StorageService::upload(
                $request->file('receipt_photo'),
                "field_team_receipts/{$member->order_id}"
            );
        }

        $member->update([
            'payment_method' => $data['method'],
            'amount'         => $data['amount'],
            'payment_status' => 'paid',
            'paid_at'        => now(),
            'paid_by'        => $request->user()->id,
            'receipt_path'   => $receiptPath,
        ]);

        return response()->json(['message' => 'Upah berhasil dibayarkan.', 'data' => $member]);
    }

    // DELETE /finance/field-team/{memberId}
    public function destroy(string $memberId): JsonResponse
    {
        $member = OrderFieldTeamPayment::where('payment_status', 'pending')->findOrFail($memberId);
        $member->delete();
        return response()->json(['message' => 'Anggota tim dihapus.']);
    }

    // GET /finance/field-team/pending
    public function pending(): JsonResponse
    {
        $members = OrderFieldTeamPayment::with(['order:id,order_number,status', 'paidByUser:id,name'])
            ->where('payment_status', 'pending')
            ->where('is_absent', false)
            ->orderBy('created_at')
            ->get();

        return response()->json($members);
    }

    private function createAbsenceViolation(OrderFieldTeamPayment $member, string $financeUserId): void
    {
        // Create a system user placeholder — we mark the violation against the field team member's name
        // Since field team is not in users table, we log it against the Finance user who reported it
        $violation = HrdViolation::create([
            'violated_by'     => $financeUserId,
            'order_id'        => $member->order_id,
            'violation_type'  => 'field_team_absent',
            'description'     => "Tim lapangan tidak hadir: {$member->name} ({$member->role_description}) pada order #{$member->order_id}",
            'severity'        => 'medium',
            'status'          => 'new',
        ]);

        NotificationService::sendHrdViolationAlert($violation);
    }
}
