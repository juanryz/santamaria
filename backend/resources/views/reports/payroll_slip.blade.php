<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<title>Slip Gaji - {{ $period }}</title>
<style>
    body { font-family: DejaVu Sans, Arial, sans-serif; font-size: 12px; color: #333; margin: 20px; }
    h1 { color: #1E3A5F; font-size: 18px; margin-bottom: 4px; }
    .subtitle { color: #555; font-size: 11px; margin-bottom: 16px; }
    table { width: 100%; border-collapse: collapse; margin-bottom: 12px; }
    th { background-color: #1E3A5F; color: #fff; padding: 8px 10px; text-align: left; font-size: 11px; }
    td { padding: 7px 10px; border-bottom: 1px solid #e0e0e0; }
    tr:nth-child(even) td { background-color: #f5f7fa; }
    .amount { text-align: right; }
    .footer { margin-top: 30px; font-size: 10px; color: #888; border-top: 1px solid #ddd; padding-top: 8px; }
    .page-break { page-break-after: always; }
    .slip-header { margin-bottom: 16px; }
    .label { font-weight: bold; width: 180px; }
    .detail-table td { border: none; padding: 4px 10px; }
</style>
</head>
<body>

<h1>Santa Maria Funeral Organizer</h1>
<div class="subtitle">Slip Gaji Karyawan &mdash; Periode: {{ $period }}</div>

@forelse ($payrolls as $i => $payroll)
<div class="slip-header">
    <table class="detail-table">
        <tr>
            <td class="label">Nama Karyawan</td>
            <td>: {{ $payroll->user->name ?? '-' }}</td>
        </tr>
        <tr>
            <td class="label">Role</td>
            <td>: {{ ucfirst(str_replace('_', ' ', $payroll->user->role ?? '-')) }}</td>
        </tr>
        <tr>
            <td class="label">Periode</td>
            <td>: {{ $period }}</td>
        </tr>
        <tr>
            <td class="label">Status</td>
            <td>: {{ ucfirst($payroll->status) }}</td>
        </tr>
    </table>
</div>

<table>
    <thead>
        <tr>
            <th>Komponen</th>
            <th class="amount">Nilai</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>Gaji Pokok</td>
            <td class="amount">Rp {{ number_format($payroll->base_salary, 0, ',', '.') }}</td>
        </tr>
        <tr>
            <td>Tugas Ditugaskan</td>
            <td class="amount">{{ $payroll->tasks_assigned }}</td>
        </tr>
        <tr>
            <td>Tugas Diselesaikan</td>
            <td class="amount">{{ $payroll->tasks_completed }}</td>
        </tr>
        <tr>
            <td>Completion Rate</td>
            <td class="amount">{{ number_format($payroll->completion_rate, 1) }}%</td>
        </tr>
        <tr>
            <td>Gaji Terhitung</td>
            <td class="amount">Rp {{ number_format($payroll->calculated_salary, 0, ',', '.') }}</td>
        </tr>
        <tr>
            <td>Penyesuaian</td>
            <td class="amount">Rp {{ number_format($payroll->adjustments, 0, ',', '.') }}</td>
        </tr>
        <tr style="font-weight: bold; background-color: #e8f0fe;">
            <td>Gaji Final</td>
            <td class="amount">Rp {{ number_format($payroll->final_salary, 0, ',', '.') }}</td>
        </tr>
        @if ($payroll->adjustment_notes)
        <tr>
            <td colspan="2" style="font-style: italic; color: #666;">Catatan: {{ $payroll->adjustment_notes }}</td>
        </tr>
        @endif
    </tbody>
</table>

@if (!$loop->last)
<div class="page-break"></div>
@endif

@empty
<p>Tidak ada data payroll untuk periode ini.</p>
@endforelse

<div class="footer">
    Dokumen ini digenerate otomatis oleh sistem Santa Maria pada {{ now()->format('d M Y H:i') }} WIB.
</div>

</body>
</html>
