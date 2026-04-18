<?php

namespace App\Http\Controllers;

use App\Models\EmployeeLeave;
use App\Services\NotificationService;
use Carbon\Carbon;
use Illuminate\Http\Request;

/**
 * v1.39 PART 8 — Employee leave request + HRD approval.
 *
 * Self-service: karyawan request cuti/sakit/izin via /me/leaves.
 * HRD: approve/reject via /hrd/leaves.
 */
class EmployeeLeaveController extends Controller
{
    private const TYPES = ['cuti_tahunan', 'sakit', 'izin', 'thr', 'cuti_khusus'];

    // ── Self-service (karyawan) ─────────────────────────────────────────

    public function myLeaves(Request $request)
    {
        $leaves = EmployeeLeave::with('approver:id,name')
            ->where('user_id', $request->user()->id)
            ->orderByDesc('start_date')
            ->paginate(30);

        return $this->success($leaves);
    }

    public function requestLeave(Request $request)
    {
        $validated = $request->validate([
            'leave_type' => 'required|string|in:' . implode(',', self::TYPES),
            'start_date' => 'required|date',
            'end_date' => 'required|date|after_or_equal:start_date',
            'reason' => 'nullable|string|max:500',
            'medical_cert_photo' => 'nullable|string|max:500',
        ]);

        $start = Carbon::parse($validated['start_date']);
        $end = Carbon::parse($validated['end_date']);
        $days = $start->diffInDays($end) + 1;

        // Sakit wajib ada surat dokter jika > 1 hari
        if ($validated['leave_type'] === 'sakit' && $days > 1 && empty($validated['medical_cert_photo'])) {
            return $this->error('Surat dokter wajib untuk sakit > 1 hari.', 422);
        }

        $leave = EmployeeLeave::create([
            'user_id' => $request->user()->id,
            'leave_type' => $validated['leave_type'],
            'start_date' => $validated['start_date'],
            'end_date' => $validated['end_date'],
            'days_count' => $days,
            'reason' => $validated['reason'] ?? null,
            'medical_cert_photo' => $validated['medical_cert_photo'] ?? null,
            'status' => 'requested',
        ]);

        // Notify HRD
        NotificationService::sendToRole(
            'hrd',
            'HIGH',
            'Request Cuti/Izin Baru',
            "{$request->user()->name} request {$validated['leave_type']} " .
            "({$days} hari dari " . $start->format('d M') . ")"
        );

        return $this->created($leave);
    }

    public function cancelLeave(Request $request, string $id)
    {
        $leave = EmployeeLeave::where('user_id', $request->user()->id)
            ->findOrFail($id);

        if ($leave->status !== 'requested') {
            return $this->error('Hanya request berstatus "requested" yang bisa dibatalkan.', 422);
        }

        $leave->update(['status' => 'cancelled']);
        return $this->success($leave);
    }

    // ── HRD approval ────────────────────────────────────────────────────

    public function hrdIndex(Request $request)
    {
        $q = EmployeeLeave::with(['user:id,name,role', 'approver:id,name']);

        if ($request->filled('status')) {
            $q->where('status', $request->status);
        }
        if ($request->filled('leave_type')) {
            $q->where('leave_type', $request->leave_type);
        }
        if ($request->filled('user_id')) {
            $q->where('user_id', $request->user_id);
        }

        return $this->success($q->orderByDesc('created_at')->paginate(30));
    }

    public function approve(Request $request, string $id)
    {
        $leave = EmployeeLeave::findOrFail($id);
        if ($leave->status !== 'requested') {
            return $this->error('Request bukan status "requested".', 422);
        }

        $leave->update([
            'status' => 'approved',
            'approved_by' => $request->user()->id,
            'approved_at' => now(),
        ]);

        NotificationService::send(
            $leave->user_id,
            'HIGH',
            'Cuti/Izin Disetujui',
            "Request {$leave->leave_type} tanggal " .
            $leave->start_date->format('d M') . ' – ' .
            $leave->end_date->format('d M Y') . ' disetujui.'
        );

        return $this->success($leave->fresh('user:id,name', 'approver:id,name'));
    }

    public function reject(Request $request, string $id)
    {
        $validated = $request->validate([
            'reason' => 'required|string|max:500',
        ]);

        $leave = EmployeeLeave::findOrFail($id);
        if ($leave->status !== 'requested') {
            return $this->error('Request bukan status "requested".', 422);
        }

        $leave->update([
            'status' => 'rejected',
            'approved_by' => $request->user()->id,
            'approved_at' => now(),
            'rejection_reason' => $validated['reason'],
        ]);

        NotificationService::send(
            $leave->user_id,
            'HIGH',
            'Cuti/Izin Ditolak',
            "Request {$leave->leave_type} ditolak. Alasan: {$validated['reason']}"
        );

        return $this->success($leave->fresh('user:id,name', 'approver:id,name'));
    }

    public function summary(Request $request)
    {
        $userId = $request->input('user_id', $request->user()->id);
        $year = $request->input('year', now()->year);

        $leaves = EmployeeLeave::where('user_id', $userId)
            ->where('status', 'approved')
            ->whereYear('start_date', $year)
            ->get();

        $byType = $leaves->groupBy('leave_type')->map(fn($g) => [
            'count' => $g->count(),
            'days_total' => $g->sum('days_count'),
        ]);

        return $this->success([
            'user_id' => $userId,
            'year' => $year,
            'total_days' => $leaves->sum('days_count'),
            'total_requests' => $leaves->count(),
            'by_type' => $byType,
        ]);
    }
}
