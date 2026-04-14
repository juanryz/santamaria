<?php

namespace App\Http\Controllers\HRD;

use App\Http\Controllers\Controller;
use App\Models\FieldAttendance;
use Illuminate\Http\Request;

class AttendanceController extends Controller
{
    public function index(Request $request)
    {
        $query = FieldAttendance::with(['user', 'order'])->orderBy('attendance_date', 'desc');

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }
        if ($request->has('role')) {
            $query->where('role', $request->role);
        }

        return response()->json(['success' => true, 'data' => $query->paginate(20)]);
    }
}
