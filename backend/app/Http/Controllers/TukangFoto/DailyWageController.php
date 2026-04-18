<?php

namespace App\Http\Controllers\TukangFoto;

use App\Http\Controllers\Controller;
use App\Models\PhotographerDailyWage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * v1.40 — Upah Tukang Foto per HARI (bukan per order).
 * Fotografer check-in → record draft dibuat.
 * Setiap order baru dihandle → session_count++, order_ids append.
 * Akhir hari Purchasing finalize + bayar.
 */
class DailyWageController extends Controller
{
    /**
     * List my daily wages (as photographer).
     */
    public function myWages(Request $request)
    {
        $wages = PhotographerDailyWage::where('photographer_user_id', $request->user()->id)
            ->orderByDesc('work_date')
            ->paginate(30);

        return $this->success($wages);
    }

    /**
     * Show detail of one wage record.
     */
    public function show(string $id)
    {
        $wage = PhotographerDailyWage::with(['photographer:id,name', 'paidByUser:id,name'])
            ->findOrFail($id);

        return $this->success($wage);
    }

    /**
     * Attach current order to today's wage record.
     * Called automatically when photographer accepts new order assignment.
     */
    public function attachOrder(Request $request)
    {
        $request->validate([
            'order_id' => 'required|uuid',
            'daily_rate' => 'nullable|numeric|min:0',
        ]);

        $photographer = $request->user();
        $today = now()->toDateString();

        DB::transaction(function () use ($photographer, $request, $today) {
            $wage = PhotographerDailyWage::firstOrCreate(
                [
                    'photographer_user_id' => $photographer->id,
                    'work_date' => $today,
                ],
                [
                    'session_count' => 0,
                    'order_ids' => [],
                    'daily_rate' => $request->daily_rate ?? 0,
                    'total_wage' => 0,
                    'status' => 'draft',
                ]
            );

            $orderIds = $wage->order_ids ?? [];
            if (!in_array($request->order_id, $orderIds)) {
                $orderIds[] = $request->order_id;
                $wage->order_ids = $orderIds;
                $wage->session_count = count($orderIds);
                // Recalculate total wage
                $wage->total_wage = (float) $wage->daily_rate
                    + ((int) $wage->session_count > 1
                        ? ((int) $wage->session_count - 1) * (float) $wage->bonus_per_extra_session
                        : 0);
                $wage->save();
            }
        });

        return $this->success(null, 'Order attached ke upah harian.');
    }

    /**
     * Purchasing/HRD finalize wage at end of day.
     */
    public function finalize(Request $request, string $id)
    {
        $wage = PhotographerDailyWage::findOrFail($id);
        if ($wage->status !== 'draft') {
            return $this->error('Upah sudah tidak dapat difinalisasi (status: ' . $wage->status . ').', 422);
        }

        $wage->status = 'finalized';
        $wage->finalized_at = now();
        $wage->save();

        return $this->success($wage, 'Upah harian difinalisasi.');
    }

    /**
     * Purchasing mark wage as paid.
     */
    public function markPaid(Request $request, string $id)
    {
        $request->validate([
            'payment_receipt_path' => 'nullable|string|max:500',
            'notes' => 'nullable|string|max:500',
        ]);

        $wage = PhotographerDailyWage::findOrFail($id);
        if ($wage->status !== 'finalized') {
            return $this->error('Upah harus difinalisasi dulu sebelum dibayar.', 422);
        }

        $wage->status = 'paid';
        $wage->paid_at = now();
        $wage->paid_by = $request->user()->id;
        $wage->payment_receipt_path = $request->payment_receipt_path;
        if ($request->notes) {
            $wage->notes = trim(($wage->notes ?? '') . "\n" . $request->notes);
        }
        $wage->save();

        return $this->success($wage, 'Pembayaran upah harian tercatat.');
    }

    /**
     * List wages to be paid (Purchasing dashboard).
     */
    public function pending(Request $request)
    {
        $wages = PhotographerDailyWage::with('photographer:id,name')
            ->where('status', 'finalized')
            ->orderBy('work_date')
            ->paginate(50);

        return $this->success($wages);
    }
}
