<?php

namespace App\Http\Controllers\ServiceOfficer;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\ServiceAcceptanceLetter;
use App\Models\TermsAndConditions;
use App\Services\WaMessageService;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Request;

class AcceptanceLetterController extends Controller
{
    /**
     * POST /so/orders/{orderId}/acceptance-letter — Create draft.
     */
    public function store(Request $request, string $orderId)
    {
        $order = Order::with('package')->findOrFail($orderId);

        if (ServiceAcceptanceLetter::where('order_id', $orderId)->exists()) {
            return $this->error('Surat sudah dibuat untuk order ini', 422);
        }

        $terms = TermsAndConditions::current();
        $letterNumber = 'SAL-' . now()->format('Ymd') . '-' . str_pad(
            ServiceAcceptanceLetter::whereDate('created_at', today())->count() + 1, 4, '0', STR_PAD_LEFT
        );

        $letter = ServiceAcceptanceLetter::create([
            'order_id' => $orderId,
            'letter_number' => $letterNumber,
            'status' => 'draft',
            'pj_nama' => $order->pic_name ?? '',
            'pj_no_telp' => $order->pic_phone ?? '',
            'pj_hubungan' => $order->pic_relation ?? '',
            'pj_alamat' => $order->pic_address ?? '',
            'almarhum_nama' => $order->deceased_name ?? '',
            'almarhum_tgl_wafat' => $order->deceased_dod,
            'almarhum_agama' => $order->deceased_religion,
            'paket_nama' => $order->package?->name,
            'paket_harga' => $order->package?->base_price,
            'total_biaya' => $order->final_price,
            'lokasi_prosesi' => $order->destination_address,
            'jadwal_mulai' => $order->scheduled_at,
            'estimasi_durasi_jam' => $order->estimated_duration_hours,
            'terms_version' => $terms?->version,
            'created_by' => $request->user()->id,
        ]);

        return $this->created($letter, 'Surat penerimaan layanan dibuat');
    }

    /**
     * GET /so/orders/{orderId}/acceptance-letter
     */
    public function show(string $orderId)
    {
        $letter = ServiceAcceptanceLetter::where('order_id', $orderId)->first();
        $terms = $letter?->terms_version
            ? TermsAndConditions::where('version', $letter->terms_version)->first()
            : TermsAndConditions::current();

        return $this->success(['letter' => $letter, 'terms' => $terms]);
    }

    /**
     * PUT /so/orders/{orderId}/acceptance-letter — Update draft.
     */
    public function update(Request $request, string $orderId)
    {
        $letter = ServiceAcceptanceLetter::where('order_id', $orderId)->firstOrFail();

        if ($letter->status !== 'draft') {
            return $this->error('Surat sudah tidak bisa diubah (status: ' . $letter->status . ')', 422);
        }

        $letter->update($request->only([
            'pj_nama', 'pj_alamat', 'pj_no_telp', 'pj_no_ktp', 'pj_hubungan',
            'almarhum_nama', 'almarhum_alamat_terakhir',
            'lokasi_prosesi', 'lokasi_pemakaman',
            'layanan_tambahan', 'total_biaya', 'notes',
        ]));

        // Move to pending_signature when all required fields filled
        if ($letter->pj_nama && $letter->almarhum_nama) {
            $letter->update(['status' => 'pending_signature']);
        }

        return $this->success($letter, 'Surat diperbarui');
    }

    /**
     * POST /so/orders/{orderId}/acceptance-letter/sign-pj — Family signature.
     */
    public function signPj(Request $request, string $orderId)
    {
        $request->validate(['signature_path' => 'nullable|string']);

        $letter = ServiceAcceptanceLetter::where('order_id', $orderId)->firstOrFail();
        $letter->update([
            'pj_signed_at' => now(),
            'pj_signature_path' => $request->signature_path,
        ]);

        $this->checkAndFinalize($letter);
        return $this->success($letter->fresh(), 'Tanda tangan PJ berhasil');
    }

    /**
     * POST /so/orders/{orderId}/acceptance-letter/sign-sm — SM Officer signature.
     */
    public function signSm(Request $request, string $orderId)
    {
        $letter = ServiceAcceptanceLetter::where('order_id', $orderId)->firstOrFail();
        $letter->update([
            'sm_officer_id' => $request->user()->id,
            'sm_officer_nama' => $request->user()->name,
            'sm_signed_at' => now(),
            'sm_signature_path' => $request->signature_path,
        ]);

        $this->checkAndFinalize($letter);
        return $this->success($letter->fresh(), 'Tanda tangan SM berhasil');
    }

    /**
     * POST /so/orders/{orderId}/acceptance-letter/sign-saksi — Witness signature.
     */
    public function signSaksi(Request $request, string $orderId)
    {
        $request->validate([
            'saksi_nama' => 'required|string',
            'saksi_no_ktp' => 'nullable|string',
            'signature_path' => 'nullable|string',
        ]);

        $letter = ServiceAcceptanceLetter::where('order_id', $orderId)->firstOrFail();
        $letter->update([
            'saksi_nama' => $request->saksi_nama,
            'saksi_no_ktp' => $request->saksi_no_ktp,
            'saksi_signed_at' => now(),
            'saksi_signature_path' => $request->signature_path,
        ]);

        return $this->success($letter->fresh(), 'Tanda tangan saksi berhasil');
    }

    /**
     * GET /so/orders/{orderId}/acceptance-letter/pdf — Download PDF.
     */
    public function exportPdf(string $orderId)
    {
        $letter = ServiceAcceptanceLetter::where('order_id', $orderId)->firstOrFail();
        $terms = $letter->terms_version
            ? TermsAndConditions::where('version', $letter->terms_version)->first()
            : TermsAndConditions::current();

        $pdf = Pdf::loadView('pdf.acceptance-letter', [
            'letter' => $letter,
            'terms' => $terms,
        ]);
        $pdf->setPaper('A4', 'portrait');

        return $pdf->download("Surat-Penerimaan-{$letter->letter_number}.pdf");
    }

    /**
     * POST /so/orders/{orderId}/acceptance-letter/send-wa — Send via WhatsApp.
     */
    public function sendWa(Request $request, string $orderId)
    {
        $letter = ServiceAcceptanceLetter::where('order_id', $orderId)->firstOrFail();

        $result = WaMessageService::generateMessage(
            'ORDER_CONFIRMED_CONSUMER',
            $letter->pj_no_telp ?? '',
            [
                'consumer_name' => $letter->pj_nama,
                'almarhum_name' => $letter->almarhum_nama,
                'order_number' => $letter->order?->order_number ?? '',
                'package_name' => $letter->paket_nama ?? '',
                'scheduled_date' => $letter->jadwal_mulai?->format('d F Y') ?? '-',
                'scheduled_time' => $letter->jadwal_mulai?->format('H:i') ?? '-',
                'location' => $letter->lokasi_prosesi ?? '-',
                'so_name' => $request->user()->name,
            ],
            $orderId,
            $request->user()->id
        );

        return $this->success($result, 'WA deep link generated');
    }

    private function checkAndFinalize(ServiceAcceptanceLetter $letter): void
    {
        $letter->refresh();
        if ($letter->isFullySigned() && $letter->status === 'pending_signature') {
            $letter->update(['status' => 'signed']);
        }
    }
}
