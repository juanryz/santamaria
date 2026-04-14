<?php

namespace App\Http\Controllers\ServiceOfficer;

use App\Http\Controllers\Controller;
use App\Models\FieldAttendance;
use Illuminate\Http\Request;

class AttendanceController extends Controller
{
    public function confirm(Request $request, $id)
    {
        $attendance = FieldAttendance::findOrFail($id);

        $attendance->update([
            'pic_confirmed' => true,
            'pic_confirmed_by' => $request->user()->id,
            'pic_confirmed_at' => now(),
        ]);

        return response()->json(['success' => true, 'message' => 'Attendance confirmed', 'data' => $attendance]);
    }

    public function orderAttendances($orderId)
    {
        $attendances = FieldAttendance::where('order_id', $orderId)
            ->with('user')
            ->orderBy('attendance_date')
            ->get();

        return response()->json(['success' => true, 'data' => $attendances]);
    }
}
