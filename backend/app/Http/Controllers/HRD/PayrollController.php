<?php

namespace App\Http\Controllers\HRD;

use App\Http\Controllers\Controller;
use App\Models\EmployeeSalary;
use App\Models\MonthlyPayroll;
use App\Models\Order;
use App\Models\OrderChecklist;
use App\Models\User;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PayrollController extends Controller
{
    // ─── Salary Config ─────────────────────────────────────────────

    /** GET /hrd/salaries */
    public function salaryIndex(Request $request): JsonResponse
    {
        $query = EmployeeSalary::with('user:id,name,role')
            ->orderByDesc('effective_date');

        if ($request->filled('user_id')) {
            $query->where('user_id', $request->user_id);
        }

        if ($request->filled('salary_type')) {
            $query->where('salary_type', $request->salary_type);
        }

        return response()->json($query->paginate(20));
    }

    /** POST /hrd/salaries */
    public function salaryStore(Request $request): JsonResponse
    {
        $data = $request->validate([
            'user_id'        => 'required|uuid|exists:users,id',
            'base_salary'    => 'required|numeric|min:0',
            'effective_date'  => 'required|date',
            'end_date'       => 'nullable|date|after:effective_date',
            'salary_type'    => 'required|in:fixed,performance_based',
            'notes'          => 'nullable|string|max:1000',
        ]);

        $data['created_by'] = $request->user()->id;

        $salary = EmployeeSalary::create($data);

        return response()->json([
            'message' => 'Konfigurasi gaji berhasil dibuat.',
            'data'    => $salary->load('user:id,name,role'),
        ], 201);
    }

    /** PUT /hrd/salaries/{id} */
    public function salaryUpdate(Request $request, string $id): JsonResponse
    {
        $salary = EmployeeSalary::findOrFail($id);

        $data = $request->validate([
            'base_salary'    => 'sometimes|numeric|min:0',
            'effective_date'  => 'sometimes|date',
            'end_date'       => 'nullable|date|after:effective_date',
            'salary_type'    => 'sometimes|in:fixed,performance_based',
            'notes'          => 'nullable|string|max:1000',
        ]);

        $salary->update($data);

        return response()->json([
            'message' => 'Konfigurasi gaji diperbarui.',
            'data'    => $salary->fresh()->load('user:id,name,role'),
        ]);
    }

    // ─── Payroll ───────────────────────────────────────────────────

    /** GET /hrd/payroll?year=2026&month=4 */
    public function payrollIndex(Request $request): JsonResponse
    {
        $request->validate([
            'year'  => 'required|integer|min:2020|max:2099',
            'month' => 'required|integer|min:1|max:12',
        ]);

        $payroll = MonthlyPayroll::with('user:id,name,role')
            ->where('period_year', $request->year)
            ->where('period_month', $request->month)
            ->orderBy('final_salary', 'desc')
            ->get();

        return response()->json(['data' => $payroll]);
    }

    /** POST /hrd/payroll/generate */
    public function payrollGenerate(Request $request): JsonResponse
    {
        $data = $request->validate([
            'year'  => 'required|integer|min:2020|max:2099',
            'month' => 'required|integer|min:1|max:12',
        ]);

        $year  = $data['year'];
        $month = $data['month'];

        $startDate = now()->setDate($year, $month, 1)->startOfMonth();
        $endDate   = $startDate->copy()->endOfMonth();

        // Get active users with salary config effective in this period
        $salaries = EmployeeSalary::with('user:id,name,role')
            ->where('effective_date', '<=', $endDate)
            ->where(function ($q) use ($startDate) {
                $q->whereNull('end_date')
                  ->orWhere('end_date', '>=', $startDate);
            })
            ->get()
            ->groupBy('user_id')
            ->map(fn ($group) => $group->sortByDesc('effective_date')->first());

        $generated = 0;

        DB::transaction(function () use ($salaries, $year, $month, $startDate, $endDate, &$generated) {
            foreach ($salaries as $salary) {
                $user = $salary->user;
                if (!$user || !$user->is_active) {
                    continue;
                }

                $baseSalary = (float) $salary->base_salary;
                $tasksAssigned  = 0;
                $tasksCompleted = 0;
                $completionRate = 0;
                $calculatedSalary = $baseSalary;

                if ($salary->salary_type === 'performance_based') {
                    [$tasksAssigned, $tasksCompleted] = $this->countTasks($user, $startDate, $endDate);

                    $completionRate = $tasksAssigned > 0
                        ? round(($tasksCompleted / $tasksAssigned) * 100, 2)
                        : 100; // No tasks = full pay (no penalty)

                    $calculatedSalary = round($baseSalary * $completionRate / 100, 2);
                }

                MonthlyPayroll::updateOrCreate(
                    [
                        'user_id'      => $user->id,
                        'period_year'  => $year,
                        'period_month' => $month,
                    ],
                    [
                        'base_salary'       => $baseSalary,
                        'tasks_assigned'    => $tasksAssigned,
                        'tasks_completed'   => $tasksCompleted,
                        'completion_rate'   => $completionRate,
                        'kpi_score'         => null,
                        'calculated_salary' => $calculatedSalary,
                        'adjustments'       => 0,
                        'final_salary'      => $calculatedSalary,
                        'status'            => 'draft',
                    ]
                );

                $generated++;
            }
        });

        return response()->json([
            'message' => "Payroll {$month}/{$year} di-generate untuk {$generated} karyawan.",
            'count'   => $generated,
        ]);
    }

    /** PUT /hrd/payroll/{id}/approve */
    public function payrollApprove(Request $request, string $id): JsonResponse
    {
        $payroll = MonthlyPayroll::where('status', 'draft')->findOrFail($id);

        $payroll->update([
            'status'      => 'approved',
            'approved_by' => $request->user()->id,
        ]);

        return response()->json([
            'message' => 'Slip gaji disetujui.',
            'data'    => $payroll->fresh()->load('user:id,name,role'),
        ]);
    }

    /** GET /hrd/payroll/export?year=2026&month=4 */
    public function payrollExport(Request $request)
    {
        $request->validate([
            'year'  => 'required|integer|min:2020|max:2099',
            'month' => 'required|integer|min:1|max:12',
        ]);

        $payrolls = MonthlyPayroll::with('user:id,name,role')
            ->where('period_year', $request->year)
            ->where('period_month', $request->month)
            ->orderBy('final_salary', 'desc')
            ->get();

        $period = sprintf('%s %d', now()->setMonth($request->month)->translatedFormat('F'), $request->year);

        $pdf = Pdf::loadView('reports.payroll_slip', [
            'payrolls' => $payrolls,
            'period'   => $period,
            'year'     => $request->year,
            'month'    => $request->month,
        ]);

        return $pdf->download("payroll_{$request->year}_{$request->month}.pdf");
    }

    // ─── Helpers ───────────────────────────────────────────────────

    /**
     * Count tasks assigned/completed for a user in a date range, based on their role.
     *
     * @return array [assigned, completed]
     */
    private function countTasks(User $user, $startDate, $endDate): array
    {
        $role = $user->role;

        // Service Officer: orders they confirmed
        if ($role === 'service_officer') {
            $assigned = Order::where('so_user_id', $user->id)
                ->whereBetween('created_at', [$startDate, $endDate])
                ->count();
            $completed = Order::where('so_user_id', $user->id)
                ->whereBetween('created_at', [$startDate, $endDate])
                ->where('status', 'completed')
                ->count();
            return [$assigned, $completed];
        }

        // Driver: orders assigned to them
        if ($role === 'driver') {
            $assigned = Order::where('assigned_driver_id', $user->id)
                ->whereBetween('created_at', [$startDate, $endDate])
                ->count();
            $completed = Order::where('assigned_driver_id', $user->id)
                ->whereBetween('created_at', [$startDate, $endDate])
                ->where('driver_overall_status', 'all_done')
                ->count();
            return [$assigned, $completed];
        }

        // Gudang, and roles with checklist items: count checklists
        if (in_array($role, ['gudang', 'dekor', 'konsumsi', 'pemuka_agama', 'tukang_foto', 'tukang_jaga'])) {
            $assigned = OrderChecklist::where('provider_role', $role)
                ->whereBetween('created_at', [$startDate, $endDate])
                ->count();
            $completed = OrderChecklist::where('provider_role', $role)
                ->whereBetween('created_at', [$startDate, $endDate])
                ->where('is_checked', true)
                ->count();
            return [$assigned, $completed];
        }

        // Default: no performance metric available — treat as fully completed
        return [0, 0];
    }
}
