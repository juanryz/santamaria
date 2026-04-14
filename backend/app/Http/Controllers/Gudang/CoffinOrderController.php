<?php

namespace App\Http\Controllers\Gudang;

use App\Http\Controllers\Controller;
use App\Models\CoffinOrder;
use App\Models\CoffinOrderStage;
use App\Models\CoffinQcResult;
use App\Models\CoffinStageMaster;
use App\Models\CoffinQcCriteriaMaster;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CoffinOrderController extends Controller
{
    public function index(Request $request)
    {
        $query = CoffinOrder::with(['order', 'pemberiOrder'])
            ->orderBy('created_at', 'desc');

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        return response()->json(['success' => true, 'data' => $query->paginate(20)]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'kode_peti' => 'required|string|max:100',
            'finishing_type' => 'required|string|max:50',
            'order_id' => 'nullable|uuid|exists:orders,id',
            'nama_pemesan' => 'nullable|string|max:255',
            'ukuran' => 'nullable|string|max:50',
            'warna' => 'nullable|string|max:100',
        ]);

        return DB::transaction(function () use ($request) {
            $number = 'PTI-' . now()->format('Ymd') . '-' . str_pad(
                CoffinOrder::whereDate('created_at', today())->count() + 1, 4, '0', STR_PAD_LEFT
            );

            $coffinOrder = CoffinOrder::create(array_merge($request->all(), [
                'coffin_order_number' => $number,
                'pemberi_order_id' => $request->user()->id,
                'status' => 'draft',
            ]));

            // Auto-generate stages from master
            $stages = CoffinStageMaster::where('finishing_type', $request->finishing_type)
                ->where('is_active', true)
                ->orderBy('stage_number')
                ->get();

            foreach ($stages as $stage) {
                CoffinOrderStage::create([
                    'coffin_order_id' => $coffinOrder->id,
                    'stage_master_id' => $stage->id,
                    'stage_number' => $stage->stage_number,
                    'stage_name' => $stage->stage_name,
                ]);
            }

            return response()->json([
                'success' => true,
                'message' => 'Coffin order created',
                'data' => $coffinOrder->load('stages'),
            ], 201);
        });
    }

    public function show($id)
    {
        $coffinOrder = CoffinOrder::with(['stages', 'qcResults.criteriaMaster', 'order', 'pemberiOrder', 'qcOfficer'])
            ->findOrFail($id);

        return response()->json(['success' => true, 'data' => $coffinOrder]);
    }

    public function updateStatus(Request $request, $id)
    {
        $request->validate(['status' => 'required|string']);

        $coffinOrder = CoffinOrder::findOrFail($id);
        $coffinOrder->update(['status' => $request->status]);

        return response()->json(['success' => true, 'message' => 'Status updated', 'data' => $coffinOrder]);
    }

    public function completeStage(Request $request, $id, $stageId)
    {
        $stage = CoffinOrderStage::where('coffin_order_id', $id)->findOrFail($stageId);

        $stage->update([
            'is_completed' => true,
            'completed_at' => now(),
            'completed_by_name' => $request->input('completed_by_name'),
            'notes' => $request->input('notes'),
        ]);

        return response()->json(['success' => true, 'message' => 'Stage completed', 'data' => $stage]);
    }

    public function submitQc(Request $request, $id)
    {
        $request->validate([
            'results' => 'required|array',
            'results.*.criteria_master_id' => 'required|uuid|exists:coffin_qc_criteria_master,id',
            'results.*.is_passed' => 'required|boolean',
        ]);

        $coffinOrder = CoffinOrder::findOrFail($id);

        return DB::transaction(function () use ($request, $coffinOrder) {
            foreach ($request->results as $result) {
                CoffinQcResult::updateOrCreate(
                    ['coffin_order_id' => $coffinOrder->id, 'criteria_master_id' => $result['criteria_master_id']],
                    ['is_passed' => $result['is_passed'], 'notes' => $result['notes'] ?? null]
                );
            }

            $allPassed = CoffinQcResult::where('coffin_order_id', $coffinOrder->id)
                ->where('is_passed', false)->doesntExist();

            $coffinOrder->update([
                'status' => $allPassed ? 'qc_passed' : 'qc_failed',
                'qc_date' => now(),
                'qc_officer_id' => $request->user()->id,
                'qc_notes' => $request->input('qc_notes'),
            ]);

            return response()->json([
                'success' => true,
                'message' => $allPassed ? 'QC passed' : 'QC failed',
                'data' => $coffinOrder->load('qcResults'),
            ]);
        });
    }
}
