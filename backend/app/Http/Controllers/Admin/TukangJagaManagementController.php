<?php
namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\TukangJagaShift;
use App\Models\TukangJagaWageConfig;
use App\Models\Order;
use App\Models\User;
use App\Services\NotificationService;
use Illuminate\Http\Request;

class TukangJagaManagementController extends Controller
{
    // GET /admin/tukang-jaga/wage-configs
    public function wageConfigs()
    {
        return response()->json(['success' => true, 'data' => TukangJagaWageConfig::where('is_active', true)->get()]);
    }

    // POST /admin/tukang-jaga/wage-configs
    public function storeWageConfig(Request $request)
    {
        $data = $request->validate([
            'label'      => 'required|string|max:100',
            'shift_type' => 'required|in:pagi,siang,malam,full_day',
            'rate'       => 'required|numeric|min:0',
        ]);
        $config = TukangJagaWageConfig::create($data);
        return response()->json(['success' => true, 'data' => $config], 201);
    }

    // PUT /admin/tukang-jaga/wage-configs/{id}
    public function updateWageConfig(Request $request, string $id)
    {
        $config = TukangJagaWageConfig::findOrFail($id);
        $config->update($request->validate([
            'label'     => 'sometimes|string|max:100',
            'rate'      => 'sometimes|numeric|min:0',
            'is_active' => 'sometimes|boolean',
        ]));
        return response()->json(['success' => true, 'data' => $config]);
    }

    // GET /admin/orders/{orderId}/shifts — lihat shift untuk 1 order
    public function orderShifts(string $orderId)
    {
        $shifts = TukangJagaShift::where('order_id', $orderId)
            ->with(['assignedUser:id,name,phone', 'wageConfig', 'deliveries.items'])
            ->orderBy('shift_number')
            ->get();
        return response()->json(['success' => true, 'data' => $shifts]);
    }

    // POST /admin/orders/{orderId}/shifts/generate — auto-generate shifts berdasarkan durasi order
    public function generateShifts(Request $request, string $orderId)
    {
        $order = Order::findOrFail($orderId);
        $request->validate([
            'days'           => 'required|integer|min:1|max:30',
            'shifts_per_day' => 'required|integer|min:1|max:4',
            'shift_types'    => 'required|array', // ['pagi','siang','malam'] sesuai shifts_per_day
            'shift_types.*'  => 'in:pagi,siang,malam,full_day',
            'start_date'     => 'required|date',
        ]);

        // Hapus shift lama yang belum checkin
        TukangJagaShift::where('order_id', $orderId)
            ->where('status', 'scheduled')
            ->delete();

        $shiftDurations = [
            'pagi'     => ['start' => '06:00', 'end' => '14:00'],
            'siang'    => ['start' => '14:00', 'end' => '22:00'],
            'malam'    => ['start' => '22:00', 'end' => '06:00'], // +1 day
            'full_day' => ['start' => '00:00', 'end' => '23:59'],
        ];

        $startDate = \Carbon\Carbon::parse($request->start_date);
        $shiftNumber = TukangJagaShift::where('order_id', $orderId)->max('shift_number') ?? 0;
        $created = [];

        for ($day = 0; $day < $request->days; $day++) {
            $currentDate = $startDate->copy()->addDays($day);
            foreach ($request->shift_types as $shiftType) {
                $shiftNumber++;
                $dur = $shiftDurations[$shiftType];
                $shiftStart = $currentDate->copy()->setTimeFromTimeString($dur['start']);
                $shiftEnd   = $shiftType === 'malam'
                    ? $currentDate->copy()->addDay()->setTimeFromTimeString($dur['end'])
                    : $currentDate->copy()->setTimeFromTimeString($dur['end']);

                // Default wage config
                $wageConfig = TukangJagaWageConfig::where('shift_type', $shiftType)
                    ->where('is_active', true)->first();

                $shift = TukangJagaShift::create([
                    'order_id'        => $orderId,
                    'shift_number'    => $shiftNumber,
                    'shift_type'      => $shiftType,
                    'scheduled_start' => $shiftStart,
                    'scheduled_end'   => $shiftEnd,
                    'wage_config_id'  => $wageConfig?->id,
                    'status'          => 'scheduled',
                ]);
                $created[] = $shift;
            }
        }

        return response()->json(['success' => true, 'data' => $created, 'message' => count($created) . ' shift berhasil dibuat.'], 201);
    }

    // PUT /admin/shifts/{id}/assign — assign tukang jaga ke shift
    public function assignShift(Request $request, string $id)
    {
        $shift = TukangJagaShift::findOrFail($id);
        $request->validate([
            'user_id'        => 'required|uuid|exists:users,id',
            'wage_config_id' => 'nullable|uuid|exists:tukang_jaga_wage_configs,id',
        ]);

        $user = User::where('role', 'tukang_jaga')->findOrFail($request->user_id);

        $shift->update([
            'assigned_to'    => $user->id,
            'wage_config_id' => $request->wage_config_id ?? $shift->wage_config_id,
        ]);

        // Notif ke tukang jaga
        app(NotificationService::class)->sendToUser(
            $user->id,
            'SHIFT_ASSIGNED',
            ['shift_number' => $shift->shift_number, 'scheduled_start' => $shift->scheduled_start->format('d M Y H:i'), 'order_number' => $shift->order?->order_number],
            $shift->order_id
        );

        return response()->json(['success' => true, 'data' => $shift->fresh('assignedUser'), 'message' => 'Tukang jaga berhasil di-assign.']);
    }
}
