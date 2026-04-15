<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<title>Laporan Transaksi Keuangan</title>
<style>
    body { font-family: DejaVu Sans, Arial, sans-serif; font-size: 11px; color: #333; margin: 20px; }
    h1 { color: #1E3A5F; font-size: 18px; margin-bottom: 4px; }
    .subtitle { color: #555; font-size: 11px; margin-bottom: 16px; }
    table { width: 100%; border-collapse: collapse; margin-bottom: 12px; }
    th { background-color: #1E3A5F; color: #fff; padding: 7px 8px; text-align: left; font-size: 10px; }
    td { padding: 6px 8px; border-bottom: 1px solid #e0e0e0; font-size: 10px; }
    tr:nth-child(even) td { background-color: #f5f7fa; }
    .amount { text-align: right; }
    .in { color: #1a7a3c; }
    .out { color: #b91c1c; }
    .footer { margin-top: 30px; font-size: 10px; color: #888; border-top: 1px solid #ddd; padding-top: 8px; }
</style>
</head>
<body>

<h1>Santa Maria Funeral Organizer</h1>
<div class="subtitle">
    Laporan Transaksi Keuangan<br>
    Digenerate: {{ $generated_at->format('d M Y H:i') }}
</div>

<table>
    <thead>
        <tr>
            <th style="width:10%;">Tanggal</th>
            <th style="width:16%;">Tipe</th>
            <th style="width:16%;">Kategori</th>
            <th style="width:8%;">Arah</th>
            <th style="width:14%;">Nominal (IDR)</th>
            <th style="width:36%;">Deskripsi</th>
        </tr>
    </thead>
    <tbody>
        @forelse ($data as $tx)
        @php
            $dir = $tx['direction'] ?? 'out';
            $dirLabel = $dir === 'in' ? 'Masuk' : 'Keluar';
        @endphp
        <tr>
            <td>{{ isset($tx['transaction_date']) ? \Carbon\Carbon::parse($tx['transaction_date'])->format('d/m/Y') : '-' }}</td>
            <td>{{ $tx['transaction_type'] ?? '-' }}</td>
            <td>{{ $tx['category'] ?? '-' }}</td>
            <td class="{{ $dir }}">{{ $dirLabel }}</td>
            <td class="amount {{ $dir }}">Rp {{ number_format($tx['amount'] ?? 0, 0, ',', '.') }}</td>
            <td>{{ $tx['description'] ?? '-' }}</td>
        </tr>
        @empty
        <tr>
            <td colspan="6" style="text-align:center; color:#999;">Tidak ada data transaksi.</td>
        </tr>
        @endforelse
    </tbody>
</table>

<div class="footer">
    Total: {{ count($data) }} transaksi &mdash; Dokumen ini digenerate secara otomatis oleh sistem Santa Maria Funeral Organizer.
</div>
</body>
</html>
