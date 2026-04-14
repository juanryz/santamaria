<?php

namespace App\Http\Controllers\Dekor;

use App\Http\Controllers\Controller;
use App\Models\DekorDailyPackage;
use App\Models\DekorDailyPackageLine;
use App\Models\DekorItemMaster;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DailyPackageController extends Controller
{
    public function index($orderId)
    {
        $packages = DekorDailyPackage::where('order_id', $orderId)
            ->with('lines.dekorMaster')
            ->orderBy('form_date')
            ->get();

        return response()->json(['success' => true, 'data' => $packages]);
    }

    public function store(Request $request, $orderId)
    {
        $request->validate([
            'form_date' => 'required|date',
            'lines' => 'required|array',
            'lines.*.dekor_master_id' => 'required|uuid|exists:dekor_item_master,id',
        ]);

        return DB::transaction(function () use ($request, $orderId) {
            $package = DekorDailyPackage::create([
                'order_id' => $orderId,
                'form_date' => $request->form_date,
                'rumah_duka' => $request->input('rumah_duka'),
                'supplier_1_name' => $request->input('supplier_1_name'),
                'supplier_2_name' => $request->input('supplier_2_name'),
                'supplier_3_name' => $request->input('supplier_3_name'),
                'total_anggaran' => $request->input('total_anggaran', 0),
                'div_dekorasi_id' => $request->user()->id,
            ]);

            $totalAktual = 0;
            foreach ($request->lines as $line) {
                DekorDailyPackageLine::create([
                    'package_id' => $package->id,
                    'dekor_master_id' => $line['dekor_master_id'],
                    'anggaran_pendapatan' => $line['anggaran_pendapatan'] ?? 0,
                    'qty' => $line['qty'] ?? 1,
                    'biaya_supplier_1' => $line['biaya_supplier_1'] ?? null,
                    'biaya_supplier_2' => $line['biaya_supplier_2'] ?? null,
                    'biaya_supplier_3' => $line['biaya_supplier_3'] ?? null,
                    'notes' => $line['notes'] ?? null,
                ]);

                $selected = $package->selected_supplier ?? 1;
                $totalAktual += $line["biaya_supplier_{$selected}"] ?? 0;
            }

            $package->update([
                'total_biaya_aktual' => $totalAktual,
                'selisih' => $package->total_anggaran - $totalAktual,
            ]);

            return response()->json(['success' => true, 'data' => $package->load('lines.dekorMaster')], 201);
        });
    }
}
