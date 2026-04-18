<?php

namespace App\Http\Controllers\PetugasAkta;

use App\Http\Controllers\Controller;
use App\Models\DeathCertStageLog;
use App\Models\Order;
use App\Models\OrderDeathCertProgress;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * v1.40 — Akta kematian progress tracking (granular per tahap).
 * Flow:
 *   not_started → source_doc_received → submitted_to_dukcapil → processing_dukcapil
 *     → cert_issued → waiting_payment → waiting_ktp_kk_pickup → handed_to_family
 *
 * Biaya admin akta INCLUDE di paket (bukan ditagih keluarga).
 * Serah terima WAJIB: consumer lunas + keluarga bawa KTP+KK.
 */
class DeathCertProgressController extends Controller
{
    private const STAGES = [
        'not_started',
        'source_doc_received',
        'submitted_to_dukcapil',
        'processing_dukcapil',
        'cert_issued',
        'waiting_payment',
        'waiting_ktp_kk_pickup',
        'handed_to_family',
    ];

    /**
     * Progress untuk 1 order. Buat record jika belum ada.
     */
    public function show(Request $request, string $orderId)
    {
        $progress = OrderDeathCertProgress::where('order_id', $orderId)
            ->with(['stageLogs' => fn ($q) => $q->orderByDesc('visited_at'), 'petugasAkta:id,name'])
            ->first();

        if (!$progress) {
            return $this->error('Progress belum dibuat untuk order ini.', 404);
        }

        $progress->days_elapsed = $progress->started_at
            ? (int) $progress->started_at->diffInDays(now())
            : 0;

        return $this->success($progress);
    }

    /**
     * Initialize progress — dipanggil saat petugas akta mulai handle order.
     */
    public function start(Request $request, string $orderId)
    {
        $validated = $request->validate([
            'death_location_type' => 'required|string|in:rumah_sakit,rumah,tempat_lain',
            'death_certificate_source' => 'required|string|max:255',
        ]);

        Order::findOrFail($orderId);

        $progress = OrderDeathCertProgress::firstOrCreate(
            ['order_id' => $orderId],
            array_merge($validated, [
                'petugas_akta_id' => $request->user()->id,
                'current_stage' => 'not_started',
                'started_at' => now(),
            ])
        );

        return $this->success($progress, 'Progress akta dimulai.');
    }

    /**
     * Advance stage + log kunjungan instansi (opsional).
     */
    public function advanceStage(Request $request, string $orderId)
    {
        $validated = $request->validate([
            'to_stage' => 'required|string|in:' . implode(',', self::STAGES),
            'institution_name' => 'nullable|string|max:255',
            'photo_evidence_id' => 'nullable|uuid',
            'fee_paid' => 'nullable|numeric|min:0',
            'receipt_photo_evidence_id' => 'nullable|uuid',
            'notes' => 'nullable|string|max:1000',
            'source_document_photo_evidence_id' => 'nullable|uuid',
        ]);

        $progress = OrderDeathCertProgress::where('order_id', $orderId)->firstOrFail();

        DB::transaction(function () use ($progress, $validated, $request) {
            $newStage = $validated['to_stage'];
            $progress->current_stage = $newStage;

            // Handle timestamps & dokumen sumber
            if ($newStage === 'source_doc_received') {
                $progress->source_document_received_at = now();
                if (!empty($validated['source_document_photo_evidence_id'])) {
                    $progress->source_document_photo_evidence_id = $validated['source_document_photo_evidence_id'];
                }
            }

            if ($newStage === 'cert_issued') {
                $progress->cert_issued_at = now();
            }

            // Akumulasi biaya admin internal
            if (!empty($validated['fee_paid'])) {
                $progress->total_admin_fees = (float) $progress->total_admin_fees + (float) $validated['fee_paid'];
                $breakdown = $progress->admin_fees_breakdown ?? [];
                $breakdown[$validated['institution_name'] ?? 'unknown'] =
                    ($breakdown[$validated['institution_name'] ?? 'unknown'] ?? 0) + (float) $validated['fee_paid'];
                $progress->admin_fees_breakdown = $breakdown;
            }

            $progress->save();

            DeathCertStageLog::create([
                'progress_id' => $progress->id,
                'stage' => $newStage,
                'institution_name' => $validated['institution_name'] ?? null,
                'visited_at' => now(),
                'photo_evidence_id' => $validated['photo_evidence_id'] ?? null,
                'fee_paid' => $validated['fee_paid'] ?? null,
                'receipt_photo_evidence_id' => $validated['receipt_photo_evidence_id'] ?? null,
                'notes' => $validated['notes'] ?? null,
            ]);
        });

        return $this->success($progress->fresh('stageLogs'), 'Stage diperbarui.');
    }

    /**
     * Serah terima akta ke keluarga.
     * WAJIB: order sudah lunas + foto KTP + foto KK diterima.
     */
    public function handToFamily(Request $request, string $orderId)
    {
        $validated = $request->validate([
            'family_ktp_photo_evidence_id' => 'required|uuid',
            'family_kk_photo_evidence_id' => 'required|uuid',
            'notes' => 'nullable|string|max:1000',
        ]);

        $progress = OrderDeathCertProgress::where('order_id', $orderId)->firstOrFail();
        $order = Order::findOrFail($orderId);

        if (!in_array($order->payment_status, ['paid', 'verified'])) {
            return $this->error('Akta hanya dapat diserahkan setelah pembayaran lunas.', 422);
        }

        if (!in_array($progress->current_stage, ['waiting_ktp_kk_pickup', 'cert_issued', 'waiting_payment'])) {
            return $this->error('Stage saat ini belum siap untuk serah terima.', 422);
        }

        DB::transaction(function () use ($progress, $validated, $order, $request) {
            $progress->update([
                'current_stage' => 'handed_to_family',
                'family_ktp_photo_evidence_id' => $validated['family_ktp_photo_evidence_id'],
                'family_kk_photo_evidence_id' => $validated['family_kk_photo_evidence_id'],
                'family_ktp_received' => true,
                'family_kk_received' => true,
                'handed_to_family_at' => now(),
                'notes' => trim(($progress->notes ?? '') . "\n" . ($validated['notes'] ?? '')),
            ]);

            DeathCertStageLog::create([
                'progress_id' => $progress->id,
                'stage' => 'handed_to_family',
                'visited_at' => now(),
                'notes' => 'Serah terima ke keluarga (KTP + KK diterima)',
            ]);

            $order->update(['death_cert_submitted' => true]);
        });

        return $this->success($progress->fresh(), 'Akta berhasil diserahkan ke keluarga.');
    }

    /**
     * Overview — semua progress yang sedang berjalan (Owner/HRD view).
     */
    public function overview(Request $request)
    {
        $items = OrderDeathCertProgress::with(['order:id,order_number,status,payment_status', 'petugasAkta:id,name'])
            ->whereNotIn('current_stage', ['handed_to_family'])
            ->orderBy('started_at')
            ->paginate(30);

        return $this->success($items);
    }
}
