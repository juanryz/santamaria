<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<title>Laporan Keuangan Bulanan</title>
<style>
    body { font-family: DejaVu Sans, Arial, sans-serif; font-size: 12px; color: #333; margin: 20px; }
    h1 { color: #1E3A5F; font-size: 18px; margin-bottom: 4px; }
    h2 { color: #1E3A5F; font-size: 14px; margin-top: 20px; margin-bottom: 6px; }
    .subtitle { color: #555; font-size: 11px; margin-bottom: 16px; }
    table { width: 100%; border-collapse: collapse; margin-bottom: 12px; }
    th { background-color: #1E3A5F; color: #fff; padding: 8px 10px; text-align: left; font-size: 11px; }
    td { padding: 7px 10px; border-bottom: 1px solid #e0e0e0; }
    tr:nth-child(even) td { background-color: #f5f7fa; }
    .amount { text-align: right; }
    .summary-label { font-weight: bold; }
    .profit { color: #1E3A5F; font-weight: bold; }
    .footer { margin-top: 30px; font-size: 10px; color: #888; border-top: 1px solid #ddd; padding-top: 8px; }
</style>
</head>
<body>

<h1>Santa Maria Funeral Organizer</h1>
<div class="subtitle">
    Laporan Keuangan Bulanan &mdash; Periode: {{ $data['period'] ?? '-' }}<br>
    Digenerate: {{ $generated_at->format('d M Y H:i') }}
</div>

<h2>Ringkasan Keuangan</h2>
<table>
    <thead>
        <tr>
            <th>Keterangan</th>
            <th style="text-align:right;">Nominal (IDR)</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td class="summary-label">Total Pendapatan</td>
            <td class="amount">Rp {{ number_format($data['income_total'] ?? 0, 0, ',', '.') }}</td>
        </tr>
        <tr>
            <td class="summary-label">Total Pengeluaran</td>
            <td class="amount">Rp {{ number_format($data['expense_total'] ?? 0, 0, ',', '.') }}</td>
        </tr>
        <tr>
            <td class="summary-label profit">Laba Bersih</td>
            <td class="amount profit">Rp {{ number_format($data['profit'] ?? 0, 0, ',', '.') }}</td>
        </tr>
        <tr>
            <td class="summary-label">Jumlah Order</td>
            <td class="amount">{{ $data['order_count'] ?? 0 }}</td>
        </tr>
        <tr>
            <td class="summary-label">Rata-rata Nilai Order</td>
            <td class="amount">Rp {{ number_format($data['avg_order_value'] ?? 0, 0, ',', '.') }}</td>
        </tr>
    </tbody>
</table>

@if (!empty($data['income_by_category']))
<h2>Pendapatan per Kategori</h2>
<table>
    <thead>
        <tr>
            <th>Kategori</th>
            <th style="text-align:right;">Nominal (IDR)</th>
        </tr>
    </thead>
    <tbody>
        @foreach ($data['income_by_category'] as $cat => $total)
        <tr>
            <td>{{ $cat }}</td>
            <td class="amount">Rp {{ number_format($total, 0, ',', '.') }}</td>
        </tr>
        @endforeach
    </tbody>
</table>
@endif

@if (!empty($data['expense_by_category']))
<h2>Pengeluaran per Kategori</h2>
<table>
    <thead>
        <tr>
            <th>Kategori</th>
            <th style="text-align:right;">Nominal (IDR)</th>
        </tr>
    </thead>
    <tbody>
        @foreach ($data['expense_by_category'] as $cat => $total)
        <tr>
            <td>{{ $cat }}</td>
            <td class="amount">Rp {{ number_format($total, 0, ',', '.') }}</td>
        </tr>
        @endforeach
    </tbody>
</table>
@endif

<div class="footer">
    Dokumen ini digenerate secara otomatis oleh sistem Santa Maria Funeral Organizer.
</div>
</body>
</html>
