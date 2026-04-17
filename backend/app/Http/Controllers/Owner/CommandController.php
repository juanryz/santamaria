<?php

namespace App\Http\Controllers\Owner;

use App\Events\OwnerCommandDispatched;
use App\Http\Controllers\Controller;
use App\Models\OwnerCommand;
use App\Models\OwnerCommandLog;
use App\Models\OwnerCommandReceipt;
use App\Models\User;
use Illuminate\Http\Request;

/**
 * v1.36 — Owner Command Controller
 *
 * POST   /owner/commands                      — Kirim perintah baru
 * GET    /owner/commands                      — Daftar semua perintah
 * GET    /owner/commands/{id}                 — Detail perintah + receipts + logs
 * DELETE /owner/commands/{id}                 — Batalkan perintah (jika belum ada yg acknowledge)
 *
 * GET    /commands/my                         — Karyawan: perintah masuk (belum di-acknowledge)
 * POST   /commands/{id}/acknowledge           — Karyawan: tandai sudah diterima
 */
class CommandController extends Controller
{
    // ── Owner ───────────────────────────────────────────────────────────────

    public function index(Request $request)
    {
        $commands = OwnerCommand::where('owner_id', $request->user()->id)
            ->with(['targetUser:id,name,role', 'receipts.user:id,name,role'])
            ->withCount(['receipts', 'receipts as acknowledged_count' => fn($q) => $q->whereNotNull('acknowledged_at')])
            ->orderByDesc('created_at')
            ->paginate(20);

        return response()->json(['success' => true, 'data' => $commands]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'title'          => 'required|string|max:255',
            'message'        => 'required|string|max:2000',
            'priority'       => 'required|in:normal,high,urgent',
            'target_user_id' => 'nullable|uuid|exists:users,id',
            'target_role'    => 'nullable|string',
            // Harus ada salah satu target
        ]);

        if (!$request->target_user_id && !$request->target_role) {
            return response()->json(['success' => false, 'message' => 'Pilih target karyawan atau role.'], 422);
        }

        $owner = $request->user();

        $command = OwnerCommand::create([
            'owner_id'       => $owner->id,
            'title'          => $request->title,
            'message'        => $request->message,
            'priority'       => $request->priority,
            'target_user_id' => $request->target_user_id,
            'target_role'    => $request->target_role,
            'status'         => 'sent',
        ]);

        // Tentukan daftar penerima
        if ($request->target_user_id) {
            $recipients = User::where('id', $request->target_user_id)->where('is_active', true)->get();
        } else {
            $recipients = User::where('role', $request->target_role)->where('is_active', true)->get();
        }

        // Buat receipt + broadcast alarm ke setiap penerima
        foreach ($recipients as $recipient) {
            OwnerCommandReceipt::create([
                'command_id'   => $command->id,
                'user_id'      => $recipient->id,
                'delivered_at' => now(),
            ]);

            broadcast(new OwnerCommandDispatched($command, $recipient->id));
        }

        // Log
        OwnerCommandLog::create([
            'command_id' => $command->id,
            'actor_id'   => $owner->id,
            'action'     => 'sent',
            'note'       => "Dikirim ke {$recipients->count()} penerima.",
        ]);

        return response()->json([
            'success'         => true,
            'data'            => $command,
            'recipients_count'=> $recipients->count(),
            'message'         => "Perintah dikirim ke {$recipients->count()} karyawan.",
        ], 201);
    }

    public function show(string $id)
    {
        $command = OwnerCommand::with([
            'targetUser:id,name,role',
            'receipts.user:id,name,role',
            'logs.actor:id,name,role',
        ])->findOrFail($id);

        return response()->json(['success' => true, 'data' => $command]);
    }

    public function cancel(string $id, Request $request)
    {
        $command = OwnerCommand::where('owner_id', $request->user()->id)->findOrFail($id);

        if ($command->receipts()->whereNotNull('acknowledged_at')->exists()) {
            return response()->json(['success' => false, 'message' => 'Tidak dapat dibatalkan — sudah ada yang acknowledge.'], 422);
        }

        OwnerCommandLog::create([
            'command_id' => $command->id,
            'actor_id'   => $request->user()->id,
            'action'     => 'cancelled',
        ]);

        $command->delete();

        return response()->json(['success' => true, 'message' => 'Perintah dibatalkan.']);
    }

    // ── Karyawan ────────────────────────────────────────────────────────────

    /**
     * GET /commands/my — Perintah yang belum di-acknowledge oleh karyawan ini.
     */
    public function myCommands(Request $request)
    {
        $userId = $request->user()->id;

        $receipts = OwnerCommandReceipt::where('user_id', $userId)
            ->whereNull('acknowledged_at')
            ->with(['command' => fn($q) => $q->with('owner:id,name')])
            ->orderByDesc('delivered_at')
            ->get();

        $data = $receipts->map(fn($r) => [
            'receipt_id'  => $r->id,
            'command_id'  => $r->command_id,
            'title'       => $r->command->title,
            'message'     => $r->command->message,
            'priority'    => $r->command->priority,
            'owner_name'  => $r->command->owner->name ?? 'Owner',
            'delivered_at'=> $r->delivered_at?->toIso8601String(),
        ]);

        return response()->json(['success' => true, 'data' => $data]);
    }

    /**
     * GET /commands/history — Semua perintah (termasuk yang sudah di-acknowledge).
     */
    public function myHistory(Request $request)
    {
        $userId = $request->user()->id;

        $receipts = OwnerCommandReceipt::where('user_id', $userId)
            ->with(['command' => fn($q) => $q->with('owner:id,name')])
            ->orderByDesc('delivered_at')
            ->paginate(30);

        return response()->json(['success' => true, 'data' => $receipts]);
    }

    /**
     * POST /commands/{id}/acknowledge — Karyawan acknowledge perintah.
     */
    public function acknowledge(string $commandId, Request $request)
    {
        $request->validate(['note' => 'nullable|string|max:500']);

        $userId  = $request->user()->id;
        $receipt = OwnerCommandReceipt::where('command_id', $commandId)
            ->where('user_id', $userId)
            ->firstOrFail();

        if ($receipt->acknowledged_at) {
            return response()->json(['success' => false, 'message' => 'Sudah di-acknowledge sebelumnya.'], 422);
        }

        $receipt->update([
            'acknowledged_at' => now(),
            'note'            => $request->note,
        ]);

        // Log
        OwnerCommandLog::create([
            'command_id' => $commandId,
            'actor_id'   => $userId,
            'action'     => 'acknowledged',
            'note'       => $request->note,
        ]);

        // Cek apakah semua penerima sudah acknowledge
        $command = OwnerCommand::find($commandId);
        if ($command) {
            $allAcked = !$command->receipts()->whereNull('acknowledged_at')->exists();
            $command->update(['status' => $allAcked ? 'all_acknowledged' : 'partial']);
        }

        return response()->json(['success' => true, 'message' => 'Perintah diterima.']);
    }
}
