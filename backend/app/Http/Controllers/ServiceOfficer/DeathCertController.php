<?php

namespace App\Http\Controllers\ServiceOfficer;

use App\Http\Controllers\Controller;
use App\Models\OrderDeathCertificateDoc;
use App\Models\OrderDeathCertDocItem;
use App\Models\DeathCertDocMaster;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DeathCertController extends Controller
{
    public function store(Request $request, $orderId)
    {
        $request->validate([
            'nama_almarhum' => 'required|string|max:255',
        ]);

        return DB::transaction(function () use ($request, $orderId) {
            $doc = OrderDeathCertificateDoc::create([
                'order_id' => $orderId,
                'nama_almarhum' => $request->nama_almarhum,
                'catatan' => $request->input('catatan'),
                'penerima_sm_id' => $request->user()->id,
            ]);

            $masters = DeathCertDocMaster::where('is_active', true)->orderBy('sort_order')->get();
            foreach ($masters as $master) {
                OrderDeathCertDocItem::create([
                    'death_cert_id' => $doc->id,
                    'doc_master_id' => $master->id,
                ]);
            }

            return response()->json(['success' => true, 'data' => $doc->load('items.docMaster')], 201);
        });
    }

    public function show($orderId)
    {
        $doc = OrderDeathCertificateDoc::where('order_id', $orderId)
            ->with('items.docMaster')
            ->first();

        return response()->json(['success' => true, 'data' => $doc]);
    }

    public function update(Request $request, $orderId)
    {
        $doc = OrderDeathCertificateDoc::where('order_id', $orderId)->firstOrFail();

        if ($request->has('items')) {
            foreach ($request->items as $itemData) {
                OrderDeathCertDocItem::where('id', $itemData['id'])->update([
                    'diterima_sm' => $itemData['diterima_sm'] ?? false,
                    'diterima_keluarga' => $itemData['diterima_keluarga'] ?? false,
                    'notes' => $itemData['notes'] ?? null,
                ]);
            }
        }

        $doc->update($request->only(['catatan', 'diterima_sm_tanggal', 'yang_menyerahkan_name',
            'penerima_sm_signed_at', 'diterima_keluarga_tanggal', 'penerima_keluarga_name',
            'penerima_keluarga_signed_at']));

        return response()->json(['success' => true, 'data' => $doc->load('items.docMaster')]);
    }
}
