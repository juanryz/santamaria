<?php

namespace App\Http\Controllers\Vendor;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\OrderBuktiLapangan;
use App\Models\PemukaAgamaAssignment;
use App\Services\StorageService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BuktiController extends Controller
{
    // POST /vendor/assignments/{id}/bukti
    public function store(Request $request, string $assignmentId): JsonResponse
    {
        $data = $request->validate([
            'photo' => 'required|file|mimes:jpg,jpeg,png|max:15360',
            'notes' => 'nullable|string',
        ]);

        // Resolve assignment — works for dekor, konsumsi via vendor_performance or pemuka_agama_assignments
        $orderId  = $this->resolveOrderId($assignmentId, $request->user());
        $role     = $request->user()->role;
        $buktiType = match ($role) {
            UserRole::DEKOR->value    => 'dekorasi_selesai',
            UserRole::KONSUMSI->value => 'konsumsi_selesai',
            default                   => 'lainnya',
        };

        $path = StorageService::upload(
            $request->file('photo'),
            "bukti_lapangan/{$orderId}/{$role}"
        );

        $bukti = OrderBuktiLapangan::create([
            'order_id'        => $orderId,
            'uploaded_by'     => $request->user()->id,
            'role'            => $role,
            'bukti_type'      => $buktiType,
            'file_path'       => $path,
            'file_size_bytes' => $request->file('photo')->getSize(),
            'notes'           => $data['notes'] ?? null,
            'created_at'      => now(),
        ]);

        return response()->json(['message' => 'Bukti berhasil diunggah.', 'data' => $bukti], 201);
    }

    private function resolveOrderId(string $assignmentId, $user): string
    {
        // Try vendor_performance (dekor/konsumsi)
        $vp = \App\Models\VendorPerformance::where('id', $assignmentId)
            ->where('vendor_user_id', $user->id)
            ->first();

        if ($vp) {
            return $vp->order_id;
        }

        // Try pemuka_agama_assignments
        $pa = PemukaAgamaAssignment::where('id', $assignmentId)
            ->where('pemuka_agama_user_id', $user->id)
            ->first();

        if ($pa) {
            return $pa->order_id;
        }

        abort(404, 'Assignment tidak ditemukan.');
    }
}
