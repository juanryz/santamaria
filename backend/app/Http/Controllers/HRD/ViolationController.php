<?php

namespace App\Http\Controllers\HRD;

use App\Http\Controllers\Controller;
use App\Models\HrdViolation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ViolationController extends Controller
{
    // GET /hrd/violations
    public function index(Request $request): JsonResponse
    {
        $query = HrdViolation::with([
            'violatedByUser:id,name,role',
            'order:id,order_number',
        ]);

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('severity')) {
            $query->where('severity', $request->severity);
        }

        if ($request->filled('violation_type')) {
            $query->where('violation_type', $request->violation_type);
        }

        $violations = $query->orderByDesc('created_at')->paginate(20);
        return response()->json($violations);
    }

    // GET /hrd/violations/{id}
    public function show(string $id): JsonResponse
    {
        $violation = HrdViolation::with([
            'violatedByUser:id,name,role,phone',
            'order:id,order_number,status,scheduled_at',
            'acknowledgedByUser:id,name',
            'resolvedByUser:id,name',
        ])->findOrFail($id);

        return response()->json($violation);
    }

    // PUT /hrd/violations/{id}/acknowledge
    public function acknowledge(Request $request, string $id): JsonResponse
    {
        $data = $request->validate([
            'hrd_notes' => 'nullable|string',
        ]);

        $violation = HrdViolation::where('status', 'new')->findOrFail($id);
        $violation->update([
            'status'           => 'acknowledged',
            'hrd_notes'        => $data['hrd_notes'] ?? $violation->hrd_notes,
            'acknowledged_by'  => $request->user()->id,
            'acknowledged_at'  => now(),
        ]);

        return response()->json(['message' => 'Pelanggaran di-acknowledge.', 'data' => $violation]);
    }

    // PUT /hrd/violations/{id}/resolve
    public function resolve(Request $request, string $id): JsonResponse
    {
        $data = $request->validate([
            'hrd_notes' => 'required|string',
        ]);

        $violation = HrdViolation::whereIn('status', ['new', 'acknowledged'])->findOrFail($id);
        $violation->update([
            'status'      => 'resolved',
            'hrd_notes'   => $data['hrd_notes'],
            'resolved_by' => $request->user()->id,
            'resolved_at' => now(),
        ]);

        return response()->json(['message' => 'Pelanggaran ditandai selesai.', 'data' => $violation]);
    }

    // PUT /hrd/violations/{id}/escalate
    public function escalate(Request $request, string $id): JsonResponse
    {
        $data = $request->validate([
            'hrd_notes' => 'required|string',
        ]);

        $violation = HrdViolation::whereIn('status', ['new', 'acknowledged'])->findOrFail($id);
        $violation->update([
            'status'    => 'escalated',
            'hrd_notes' => $data['hrd_notes'],
        ]);

        // Notif Owner
        \App\Services\NotificationService::sendToRole('owner', 'ALARM',
            '⚠ Pelanggaran Dieskalasi ke Owner',
            "HRD: {$violation->description}. Perlu tindakan Owner.",
            ['violation_id' => $violation->id, 'action' => 'view_violation']
        );

        return response()->json(['message' => 'Pelanggaran dieskalasi ke Owner.']);
    }

    // GET /hrd/violations/by-user/{userId}
    public function byUser(string $userId): JsonResponse
    {
        $violations = HrdViolation::with(['order:id,order_number'])
            ->where('violated_by', $userId)
            ->orderByDesc('created_at')
            ->get();

        return response()->json($violations);
    }

    // GET /hrd/reports/monthly
    public function monthlyReport(Request $request): JsonResponse
    {
        $month = $request->input('month', now()->format('Y-m'));
        [$year, $mon] = explode('-', $month);

        $violations = HrdViolation::whereYear('created_at', $year)
            ->whereMonth('created_at', $mon)
            ->selectRaw('violation_type, severity, COUNT(*) as count')
            ->groupBy('violation_type', 'severity')
            ->get();

        return response()->json(['month' => $month, 'summary' => $violations]);
    }
}
