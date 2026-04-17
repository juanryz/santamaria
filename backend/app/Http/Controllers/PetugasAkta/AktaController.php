<?php

namespace App\Http\Controllers\PetugasAkta;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderDeathCertificateDoc;
use Illuminate\Http\Request;

class AktaController extends Controller
{
    /**
     * Valid akta processing statuses.
     */
    private const STATUSES = [
        'collecting_docs',
        'submitted_to_civil',
        'processing',
        'completed',
        'handed_to_family',
    ];

    /**
     * List orders that need death certificate processing.
     */
    public function index(Request $request)
    {
        $docs = OrderDeathCertificateDoc::with(['order:id,order_number,status,payment_status,completed_at', 'items'])
            ->orderByDesc('created_at')
            ->paginate(20);

        return $this->success($docs);
    }

    /**
     * Show death cert progress for a specific order.
     */
    public function show(string $orderId)
    {
        $doc = OrderDeathCertificateDoc::where('order_id', $orderId)
            ->with(['order:id,order_number,status,payment_status,completed_at', 'items', 'penerimaSm:id,name'])
            ->first();

        if (! $doc) {
            return $this->error('Dokumen akta kematian belum dibuat untuk order ini.', 404);
        }

        return $this->success($doc);
    }

    /**
     * Update akta processing progress.
     * Uses the `catatan` field on OrderDeathCertificateDoc to store structured progress.
     */
    public function updateProgress(Request $request, string $orderId)
    {
        $request->validate([
            'status' => 'required|string|in:' . implode(',', self::STATUSES),
            'notes' => 'nullable|string|max:2000',
            'visit_location' => 'nullable|string|max:500',
        ]);

        $doc = OrderDeathCertificateDoc::where('order_id', $orderId)->firstOrFail();

        // Build progress log entry and append to catatan as structured text
        $timestamp = now()->format('Y-m-d H:i');
        $userName = $request->user()->name;
        $entry = "[{$timestamp}] Status: {$request->status}";
        if ($request->visit_location) {
            $entry .= " | Lokasi: {$request->visit_location}";
        }
        if ($request->notes) {
            $entry .= " | Catatan: {$request->notes}";
        }
        $entry .= " | Oleh: {$userName}";

        $existingNotes = $doc->catatan ?? '';
        $doc->catatan = trim($existingNotes . "\n" . $entry);

        // If completed, update SM receipt date
        if ($request->status === 'completed' && ! $doc->diterima_sm_tanggal) {
            $doc->diterima_sm_tanggal = now()->toDateString();
            $doc->penerima_sm_id = $request->user()->id;
            $doc->penerima_sm_signed_at = now();
        }

        $doc->save();

        return $this->success($doc, 'Progress akta kematian diperbarui.');
    }

    /**
     * Hand over completed certificate to family.
     * Only allowed if order payment is confirmed.
     */
    public function handOver(Request $request, string $orderId)
    {
        $doc = OrderDeathCertificateDoc::where('order_id', $orderId)
            ->with('order:id,payment_status,death_cert_submitted')
            ->firstOrFail();

        $order = $doc->order;

        if (! in_array($order->payment_status, ['paid', 'verified'])) {
            return $this->error('Serah terima akta hanya bisa dilakukan setelah pembayaran dikonfirmasi.', 422);
        }

        $request->validate([
            'penerima_keluarga_name' => 'required|string|max:255',
            'notes' => 'nullable|string|max:2000',
        ]);

        $doc->diterima_keluarga_tanggal = now()->toDateString();
        $doc->penerima_keluarga_name = $request->penerima_keluarga_name;
        $doc->penerima_keluarga_signed_at = now();

        // Append handover log to catatan
        $timestamp = now()->format('Y-m-d H:i');
        $entry = "[{$timestamp}] Status: handed_to_family | Penerima: {$request->penerima_keluarga_name}";
        if ($request->notes) {
            $entry .= " | Catatan: {$request->notes}";
        }
        $entry .= " | Oleh: {$request->user()->name}";
        $doc->catatan = trim(($doc->catatan ?? '') . "\n" . $entry);

        $doc->save();

        // Mark order death cert as submitted
        $order->update(['death_cert_submitted' => true]);

        return $this->success($doc, 'Akta kematian berhasil diserahkan ke keluarga.');
    }
}
