<?php

namespace App\Http\Controllers\ServiceOfficer;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\SoProspect;
use App\Models\SoVisitLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CrmController extends Controller
{
    // ── Prospects ─────────────────────────────────────────────────────

    public function prospectIndex(Request $request): JsonResponse
    {
        $query = SoProspect::where('so_user_id', $request->user()->id)
            ->withCount('visitLogs');

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'ilike', "%{$search}%")
                  ->orWhere('phone', 'ilike', "%{$search}%");
            });
        }

        $prospects = $query->orderByDesc('created_at')->paginate(20);

        return response()->json(['success' => true, 'data' => $prospects]);
    }

    public function prospectStore(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name'           => 'required|string|max:255',
            'phone'          => 'nullable|string|max:30',
            'address'        => 'nullable|string',
            'source'         => 'nullable|string|max:100',
            'notes'          => 'nullable|string',
            'follow_up_date' => 'nullable|date|after_or_equal:today',
        ]);

        $data['so_user_id'] = $request->user()->id;
        $data['status']     = 'new';

        $prospect = SoProspect::create($data);

        return response()->json(['success' => true, 'data' => $prospect], 201);
    }

    public function prospectUpdate(Request $request, string $id): JsonResponse
    {
        $prospect = SoProspect::where('so_user_id', $request->user()->id)->findOrFail($id);

        $data = $request->validate([
            'name'              => 'sometimes|string|max:255',
            'phone'             => 'nullable|string|max:30',
            'address'           => 'nullable|string',
            'source'            => 'nullable|string|max:100',
            'status'            => 'sometimes|string|in:new,contacted,interested,converted,lost',
            'notes'             => 'nullable|string',
            'follow_up_date'    => 'nullable|date',
            'converted_order_id'=> 'nullable|uuid|exists:orders,id',
        ]);

        $prospect->update($data);

        return response()->json(['success' => true, 'data' => $prospect->fresh()]);
    }

    // ── Visit Logs ───────────────────────────────────────────────────

    public function visitLogIndex(Request $request): JsonResponse
    {
        $query = SoVisitLog::where('so_user_id', $request->user()->id)
            ->with(['prospect:id,name,status', 'order:id,order_number']);

        if ($request->filled('date')) {
            $query->whereDate('visit_date', $request->date);
        }

        if ($request->filled('purpose')) {
            $query->where('purpose', $request->purpose);
        }

        $visits = $query->orderByDesc('visit_date')->orderByDesc('created_at')->paginate(20);

        return response()->json(['success' => true, 'data' => $visits]);
    }

    public function visitLogStore(Request $request): JsonResponse
    {
        $data = $request->validate([
            'prospect_id'       => 'nullable|uuid|exists:so_prospects,id',
            'order_id'          => 'nullable|uuid|exists:orders,id',
            'location'          => 'required|string|max:255',
            'purpose'           => 'required|string|max:255',
            'notes'             => 'nullable|string',
            'visit_date'        => 'required|date',
            'photo_evidence_id' => 'nullable|uuid|exists:photo_evidences,id',
        ]);

        $data['so_user_id'] = $request->user()->id;

        $visit = SoVisitLog::create($data);

        return response()->json(['success' => true, 'data' => $visit->load('prospect:id,name')], 201);
    }

    // ── Daily Report ─────────────────────────────────────────────────

    public function dailyReport(Request $request): JsonResponse
    {
        $date = $request->input('date', now()->toDateString());
        $userId = $request->user()->id;

        $ordersHandled = Order::where('so_user_id', $userId)
            ->whereDate('updated_at', $date)
            ->count();

        $ordersCreated = Order::where('so_user_id', $userId)
            ->whereDate('created_at', $date)
            ->count();

        $visitsDone = SoVisitLog::where('so_user_id', $userId)
            ->whereDate('visit_date', $date)
            ->count();

        $prospectsAdded = SoProspect::where('so_user_id', $userId)
            ->whereDate('created_at', $date)
            ->count();

        $followUpsToday = SoProspect::where('so_user_id', $userId)
            ->whereDate('follow_up_date', $date)
            ->where('status', '!=', 'converted')
            ->where('status', '!=', 'lost')
            ->get(['id', 'name', 'phone', 'status', 'follow_up_date']);

        return response()->json([
            'success' => true,
            'data' => [
                'date'             => $date,
                'orders_handled'   => $ordersHandled,
                'orders_created'   => $ordersCreated,
                'visits_done'      => $visitsDone,
                'prospects_added'  => $prospectsAdded,
                'total_activities' => $ordersHandled + $visitsDone + $prospectsAdded,
                'follow_ups_today' => $followUpsToday,
            ],
        ]);
    }
}
