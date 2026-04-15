<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<title>Laporan Daftar Order</title>
<style>
    body { font-family: DejaVu Sans, Arial, sans-serif; font-size: 11px; color: #333; margin: 20px; }
    h1 { color: #1E3A5F; font-size: 18px; margin-bottom: 4px; }
    .subtitle { color: #555; font-size: 11px; margin-bottom: 16px; }
    table { width: 100%; border-collapse: collapse; margin-bottom: 12px; }
    th { background-color: #1E3A5F; color: #fff; padding: 7px 8px; text-align: left; font-size: 10px; }
    td { padding: 6px 8px; border-bottom: 1px solid #e0e0e0; font-size: 10px; }
    tr:nth-child(even) td { background-color: #f5f7fa; }
    .amount { text-align: right; }
    .footer { margin-top: 30px; font-size: 10px; color: #888; border-top: 1px solid #ddd; padding-top: 8px; }
</style>
</head>
<body>

<h1>Santa Maria Funeral Organizer</h1>
<div class="subtitle">
    Laporan Daftar Order<br>
    Digenerate: {{ $generated_at->format('d M Y H:i') }}
</div>

<table>
    <thead>
        <tr>
            <th style="width:4%;">No</th>
            <th style="width:14%;">Kode Order</th>
            <th style="width:18%;">Konsumen</th>
            <th style="width:18%;">Almarhum</th>
            <th style="width:14%;">Total</th>
            <th style="width:10%;">Status</th>
            <th style="width:12%;">Tgl Order</th>
        </tr>
    </thead>
    <tbody>
        @forelse ($data as $i => $order)
        <tr>
            <td>{{ $i + 1 }}</td>
            <td>{{ $order['order_code'] ?? '-' }}</td>
            <td>{{ $order['consumer']['name'] ?? '-' }}</td>
            <td>{{ $order['deceased_name'] ?? '-' }}</td>
            <td class="amount">Rp {{ number_format($order['total_amount'] ?? 0, 0, ',', '.') }}</td>
            <td>{{ $order['status'] ?? '-' }}</td>
            <td>{{ isset($order['created_at']) ? \Carbon\Carbon::parse($order['created_at'])->format('d/m/Y') : '-' }}</td>
        </tr>
        @empty
        <tr>
            <td colspan="7" style="text-align:center; color:#999;">Tidak ada data order.</td>
        </tr>
        @endforelse
    </tbody>
</table>

<div class="footer">
    Total: {{ count($data) }} order &mdash; Dokumen ini digenerate secara otomatis oleh sistem Santa Maria Funeral Organizer.
</div>
</body>
</html>
