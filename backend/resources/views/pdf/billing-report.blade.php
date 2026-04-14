<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Laporan Tagihan - {{ $order->order_number }}</title>
    <style>
        body { font-family: 'Helvetica', sans-serif; font-size: 12px; color: #333; }
        .header { text-align: center; margin-bottom: 20px; border-bottom: 2px solid #1F3D7A; padding-bottom: 15px; }
        .header h1 { color: #1F3D7A; margin: 0; font-size: 18px; }
        .header p { margin: 2px 0; color: #666; font-size: 10px; }
        .info-table { width: 100%; margin-bottom: 20px; }
        .info-table td { padding: 3px 0; vertical-align: top; }
        .info-label { color: #666; width: 150px; }
        table.items { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
        table.items th { background: #1F3D7A; color: white; padding: 8px 6px; text-align: left; font-size: 11px; }
        table.items td { padding: 6px; border-bottom: 1px solid #eee; font-size: 11px; }
        table.items tr:nth-child(even) { background: #f9f9f9; }
        .text-right { text-align: right; }
        .text-center { text-align: center; }
        .summary { float: right; width: 300px; }
        .summary table { width: 100%; }
        .summary td { padding: 4px 0; }
        .summary .grand-total { font-size: 16px; font-weight: bold; color: #1F3D7A; border-top: 2px solid #1F3D7A; padding-top: 8px; }
        .badge { display: inline-block; padding: 2px 6px; border-radius: 4px; font-size: 9px; color: white; }
        .badge-package { background: #1F3D7A; }
        .badge-addon { background: #7BADD4; }
        .badge-manual { background: #F39C12; }
        .footer { margin-top: 40px; font-size: 10px; color: #999; text-align: center; }
    </style>
</head>
<body>
    <div class="header">
        <h1>SANTA MARIA FUNERAL ORGANIZER</h1>
        <p>Laporan Tagihan Pelayanan</p>
    </div>

    <table class="info-table">
        <tr>
            <td class="info-label">No. Order</td>
            <td>: {{ $order->order_number }}</td>
            <td class="info-label">Tanggal</td>
            <td>: {{ $generatedAt }}</td>
        </tr>
        <tr>
            <td class="info-label">Nama Almarhum</td>
            <td>: {{ $order->deceased_name ?? '-' }}</td>
            <td class="info-label">Paket</td>
            <td>: {{ $order->package?->name ?? '-' }}</td>
        </tr>
        <tr>
            <td class="info-label">PIC Keluarga</td>
            <td>: {{ $order->pic?->name ?? '-' }}</td>
            <td class="info-label">Telepon</td>
            <td>: {{ $order->pic?->phone ?? '-' }}</td>
        </tr>
    </table>

    <table class="items">
        <thead>
            <tr>
                <th style="width:30px">No</th>
                <th>Uraian</th>
                <th class="text-center" style="width:50px">Qty</th>
                <th class="text-center" style="width:50px">Satuan</th>
                <th class="text-right" style="width:100px">Harga Satuan</th>
                <th class="text-right" style="width:100px">Total</th>
                <th class="text-right" style="width:80px">Tambahan</th>
                <th class="text-right" style="width:80px">Kembali</th>
            </tr>
        </thead>
        <tbody>
            @foreach($items as $index => $item)
            <tr>
                <td class="text-center">{{ $index + 1 }}</td>
                <td>
                    {{ $item->billingMaster?->item_name ?? '-' }}
                    <span class="badge badge-{{ $item->source }}">{{ $item->source }}</span>
                </td>
                <td class="text-center">{{ number_format($item->qty, 0) }}</td>
                <td class="text-center">{{ $item->unit }}</td>
                <td class="text-right">{{ number_format($item->unit_price, 0, ',', '.') }}</td>
                <td class="text-right">{{ number_format($item->total_price, 0, ',', '.') }}</td>
                <td class="text-right">{{ $item->tambahan > 0 ? number_format($item->tambahan, 0, ',', '.') : '-' }}</td>
                <td class="text-right">{{ $item->kembali > 0 ? number_format($item->kembali, 0, ',', '.') : '-' }}</td>
            </tr>
            @endforeach
        </tbody>
    </table>

    <div class="summary">
        <table>
            <tr>
                <td>Total Layanan</td>
                <td class="text-right">Rp {{ number_format($total, 0, ',', '.') }}</td>
            </tr>
            <tr>
                <td>Tambahan</td>
                <td class="text-right">Rp {{ number_format($totalTambahan, 0, ',', '.') }}</td>
            </tr>
            <tr>
                <td>Kembali</td>
                <td class="text-right">(Rp {{ number_format($totalKembali, 0, ',', '.') }})</td>
            </tr>
            <tr>
                <td class="grand-total">GRAND TOTAL</td>
                <td class="text-right grand-total">Rp {{ number_format($grandTotal, 0, ',', '.') }}</td>
            </tr>
        </table>
    </div>

    <div style="clear:both"></div>

    <div style="margin-top: 60px;">
        <table style="width: 100%;">
            <tr>
                <td style="text-align: center; width: 33%;">
                    <p>Keluarga</p>
                    <br><br><br>
                    <p>( ________________ )</p>
                </td>
                <td style="text-align: center; width: 33%;">
                    <p>Purchasing</p>
                    <br><br><br>
                    <p>( ________________ )</p>
                </td>
                <td style="text-align: center; width: 33%;">
                    <p>Direktur</p>
                    <br><br><br>
                    <p>( ________________ )</p>
                </td>
            </tr>
        </table>
    </div>

    <div class="footer">
        Dicetak oleh sistem Santa Maria pada {{ $generatedAt }}
    </div>
</body>
</html>
