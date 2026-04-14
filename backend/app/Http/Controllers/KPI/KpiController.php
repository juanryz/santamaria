<?php

namespace App\Http\Controllers\KPI;

use App\Http\Controllers\Controller;
use App\Models\KpiMetricMaster;
use App\Models\KpiPeriod;
use App\Models\KpiScore;
use App\Models\KpiUserSummary;
use Illuminate\Http\Request;

class KpiController extends Controller
{
    // === Metrics (HRD/Super Admin) ===

    public function metricsIndex(Request $request)
    {
        $query = KpiMetricMaster::orderBy('applicable_role')->orderBy('sort_order');

        if ($request->has('role')) {
            $query->where('applicable_role', $request->role);
        }

        return response()->json(['success' => true, 'data' => $query->get()]);
    }

    public function metricsStore(Request $request)
    {
        $request->validate([
            'metric_code' => 'required|string|unique:kpi_metric_master,metric_code',
            'metric_name' => 'required|string',
            'applicable_role' => 'required|string',
            'data_source' => 'required|string',
            'calculation_type' => 'required|string',
            'calculation_query' => 'required|string',
            'unit' => 'required|string',
            'target_value' => 'required|numeric',
            'target_direction' => 'required|in:lower_is_better,higher_is_better',
            'weight' => 'required|numeric',
        ]);

        $metric = KpiMetricMaster::create($request->all());
        return response()->json(['success' => true, 'data' => $metric], 201);
    }

    public function metricsUpdate(Request $request, $id)
    {
        $metric = KpiMetricMaster::findOrFail($id);
        $metric->update($request->all());
        return response()->json(['success' => true, 'data' => $metric]);
    }

    // === Periods ===

    public function periodsIndex()
    {
        $periods = KpiPeriod::orderBy('start_date', 'desc')->get();
        return response()->json(['success' => true, 'data' => $periods]);
    }

    public function periodsStore(Request $request)
    {
        $request->validate([
            'period_name' => 'required|string',
            'period_type' => 'required|in:monthly,quarterly,yearly',
            'start_date' => 'required|date',
            'end_date' => 'required|date|after:start_date',
        ]);

        $period = KpiPeriod::create($request->all());
        return response()->json(['success' => true, 'data' => $period], 201);
    }

    // === Scores & Summaries ===

    public function scores(Request $request, $periodId)
    {
        $query = KpiScore::where('period_id', $periodId)->with(['user', 'metric']);

        if ($request->has('user_id')) {
            $query->where('user_id', $request->user_id);
        }

        return response()->json(['success' => true, 'data' => $query->get()]);
    }

    public function summaries(Request $request, $periodId)
    {
        $query = KpiUserSummary::where('period_id', $periodId)->with('user')->orderBy('total_score', 'desc');

        if ($request->has('role')) {
            $query->whereHas('user', fn($q) => $q->where('role', strtoupper($request->role)));
        }

        return response()->json(['success' => true, 'data' => $query->get()]);
    }

    public function rankings($periodId)
    {
        $summaries = KpiUserSummary::where('period_id', $periodId)
            ->with('user')
            ->orderBy('total_score', 'desc')
            ->get()
            ->groupBy(fn($s) => $s->user->role);

        return response()->json(['success' => true, 'data' => $summaries]);
    }

    // === Self KPI ===

    public function myKpi(Request $request)
    {
        $currentPeriod = KpiPeriod::where('status', 'open')
            ->orderBy('start_date', 'desc')
            ->first();

        if (!$currentPeriod) {
            return response()->json(['success' => true, 'data' => null, 'message' => 'No active period']);
        }

        $scores = KpiScore::where('period_id', $currentPeriod->id)
            ->where('user_id', $request->user()->id)
            ->with('metric')
            ->get();

        $summary = KpiUserSummary::where('period_id', $currentPeriod->id)
            ->where('user_id', $request->user()->id)
            ->first();

        return response()->json([
            'success' => true,
            'data' => [
                'period' => $currentPeriod,
                'scores' => $scores,
                'summary' => $summary,
            ],
        ]);
    }
}
