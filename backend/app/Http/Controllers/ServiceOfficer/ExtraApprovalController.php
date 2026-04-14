<?php

namespace App\Http\Controllers\ServiceOfficer;

use App\Http\Controllers\Controller;
use App\Models\OrderExtraApproval;
use App\Models\ExtraApprovalLine;
use App\Models\Order;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ExtraApprovalController extends Controller
{
    public function index($orderId)
    {
        $approvals = OrderExtraApproval::where('order_id', $orderId)
            ->with('lines')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json(['success' => true, 'data' => $approvals]);
    }

    public function store(Request $request, $orderId)
    {
        $request->validate([
            'nama_almarhum' => 'required|string|max:255',
            'pj_nama' => 'required|string|max:255',
            'tanggal' => 'required|date',
            'lines' => 'required|array|min:1',
            'lines.*.keterangan' => 'required|string|max:255',
            'lines.*.biaya' => 'required|numeric|min:0',
        ]);

        return DB::transaction(function () use ($request, $orderId) {
            $totalBiaya = collect($request->lines)->sum('biaya');

            $approval = OrderExtraApproval::create([
                'order_id' => $orderId,
                'nama_almarhum' => $request->nama_almarhum,
                'total_biaya' => $totalBiaya,
                'pj_nama' => $request->pj_nama,
                'pj_alamat' => $request->input('pj_alamat'),
                'pj_no_telp' => $request->input('pj_no_telp'),
                'pj_hub_alm' => $request->input('pj_hub_alm'),
                'tanggal' => $request->tanggal,
                'so_id' => $request->user()->id,
            ]);

            foreach ($request->lines as $i => $line) {
                ExtraApprovalLine::create([
                    'approval_id' => $approval->id,
                    'line_number' => $i + 1,
                    'keterangan' => $line['keterangan'],
                    'biaya' => $line['biaya'],
                    'notes' => $line['notes'] ?? null,
                ]);
            }

            // Update order extra_approval_total
            $order = Order::find($orderId);
            $order?->update([
                'extra_approval_total' => OrderExtraApproval::where('order_id', $orderId)->sum('total_biaya'),
            ]);

            return response()->json(['success' => true, 'data' => $approval->load('lines')], 201);
        });
    }

    public function update(Request $request, $orderId, $id)
    {
        $approval = OrderExtraApproval::where('order_id', $orderId)->findOrFail($id);

        return DB::transaction(function () use ($request, $approval, $orderId) {
            $approval->update($request->only(['notes', 'pj_alamat', 'pj_no_telp', 'pj_hub_alm']));

            if ($request->has('lines')) {
                $approval->lines()->delete();
                $totalBiaya = 0;
                foreach ($request->lines as $i => $line) {
                    ExtraApprovalLine::create([
                        'approval_id' => $approval->id,
                        'line_number' => $i + 1,
                        'keterangan' => $line['keterangan'],
                        'biaya' => $line['biaya'],
                        'notes' => $line['notes'] ?? null,
                    ]);
                    $totalBiaya += $line['biaya'];
                }
                $approval->update(['total_biaya' => $totalBiaya]);
            }

            return response()->json(['success' => true, 'data' => $approval->load('lines')]);
        });
    }

    public function sign(Request $request, $orderId, $id)
    {
        $approval = OrderExtraApproval::where('order_id', $orderId)->findOrFail($id);

        $approval->update([
            'pj_signed_at' => now(),
            'pj_signature_path' => $request->input('signature_path'),
            'approved' => true,
            'approved_at' => now(),
        ]);

        return response()->json(['success' => true, 'message' => 'Signed', 'data' => $approval]);
    }
}
