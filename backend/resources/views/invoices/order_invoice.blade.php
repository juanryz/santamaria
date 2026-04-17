<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Invoice - {{ $order->order_number }}</title>
    <style>
        body { font-family: 'Helvetica', sans-serif; font-size: 12px; color: #333; margin: 0; padding: 30px; }
        .header { text-align: center; margin-bottom: 24px; border-bottom: 3px solid #1E3A5F; padding-bottom: 16px; }
        .header h1 { color: #1E3A5F; margin: 0 0 4px 0; font-size: 20px; letter-spacing: 1px; }
        .header .address { margin: 2px 0; color: #666; font-size: 10px; }
        .invoice-title { text-align: center; margin-bottom: 20px; }
        .invoice-title h2 { color: #1E3A5F; font-size: 16px; margin: 0 0 4px 0; }
        .invoice-title .inv-number { font-size: 13px; color: #555; }
        .info-grid { width: 100%; margin-bottom: 20px; }
        .info-grid td { padding: 3px 0; vertical-align: top; font-size: 11px; }
        .info-label { color: #888; width: 140px; }
        .info-value { color: #333; }
        .section-label { font-size: 11px; color: #1E3A5F; font-weight: bold; margin-bottom: 6px; text-transform: uppercase; letter-spacing: 0.5px; }
        table.items { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
        table.items th { background: #1E3A5F; color: white; padding: 8px 6px; text-align: left; font-size: 10px; text-transform: uppercase; letter-spacing: 0.3px; }
        table.items td { padding: 6px; border-bottom: 1px solid #e8e8e8; font-size: 11px; }
        table.items tr:nth-child(even) { background: #fafafa; }
        .text-right { text-align: right; }
        .text-center { text-align: center; }
        .summary-box { float: right; width: 280px; margin-top: 10px; }
        .summary-box table { width: 100%; }
        .summary-box td { padding: 5px 0; font-size: 12px; }
        .summary-box .label { color: #666; }
        .summary-box .value { text-align: right; color: #333; }
        .grand-total td { font-size: 15px; font-weight: bold; color: #1E3A5F; border-top: 2px solid #1E3A5F; padding-top: 10px; }
        .payment-box { margin-top: 30px; padding: 14px; background: #f4f7fa; border: 1px solid #d0dbe6; border-radius: 6px; font-size: 11px; clear: both; }
        .payment-box .title { font-weight: bold; color: #1E3A5F; margin-bottom: 6px; font-size: 12px; }
        .status-badge { display: inline-block; padding: 3px 10px; border-radius: 10px; font-size: 10px; font-weight: bold; color: white; }
        .status-paid { background: #27ae60; }
        .status-unpaid { background: #e74c3c; }
        .status-proof { background: #f39c12; }
        .footer { margin-top: 50px; font-size: 9px; color: #aaa; text-align: center; border-top: 1px solid #eee; padding-top: 10px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>SANTA MARIA FUNERAL ORGANIZER</h1>
        <p class="address">Jl. Citarum Tengah E-1, Semarang 50126</p>
        <p class="address">Telp: 024-3560444 | WA: 081.128.8286</p>
    </div>

    <div class="invoice-title">
        <h2>INVOICE / TAGIHAN</h2>
        <div class="inv-number">No: INV-{{ $order->order_number }}</div>
        <div style="font-size: 11px; color: #888; margin-top: 2px;">Tanggal: {{ $generatedAt }}</div>
    </div>

    {{-- Recipient & Order Info --}}
    <table class="info-grid">
        <tr>
            <td colspan="2"><div class="section-label">Kepada</div></td>
            <td colspan="2"><div class="section-label">Detail Order</div></td>
        </tr>
        <tr>
            <td class="info-label">Nama</td>
            <td class="info-value">: {{ $order->pic_name ?? $order->pic?->name ?? '-' }}</td>
            <td class="info-label">No. Order</td>
            <td class="info-value">: {{ $order->order_number }}</td>
        </tr>
        <tr>
            <td class="info-label">Alamat</td>
            <td class="info-value">: {{ $order->pic_address ?? '-' }}</td>
            <td class="info-label">Paket</td>
            <td class="info-value">: {{ $order->package?->name ?? $order->custom_package_name ?? '-' }}</td>
        </tr>
        <tr>
            <td class="info-label">Telepon</td>
            <td class="info-value">: {{ $order->pic_phone ?? $order->pic?->phone ?? '-' }}</td>
            <td class="info-label">Almarhum/ah</td>
            <td class="info-value">: {{ $order->deceased_name ?? '-' }}</td>
        </tr>
        <tr>
            <td></td>
            <td></td>
            <td class="info-label">Tanggal Layanan</td>
            <td class="info-value">: {{ $order->scheduled_at ? $order->scheduled_at->format('d M Y') : '-' }}</td>
        </tr>
    </table>

    {{-- Billing Items Table --}}
    <table class="items">
        <thead>
            <tr>
                <th style="width:30px">No</th>
                <th>Uraian</th>
                <th class="text-center" style="width:45px">Qty</th>
                <th class="text-center" style="width:50px">Satuan</th>
                <th class="text-right" style="width:100px">Harga Satuan</th>
                <th class="text-right" style="width:110px">Total</th>
            </tr>
        </thead>
        <tbody>
            @foreach($items as $index => $item)
            <tr>
                <td class="text-center">{{ $index + 1 }}</td>
                <td>{{ $item->billingMaster?->item_name ?? $item->notes ?? '-' }}</td>
                <td class="text-center">{{ number_format($item->qty, 0) }}</td>
                <td class="text-center">{{ $item->unit ?? '-' }}</td>
                <td class="text-right">Rp {{ number_format($item->unit_price, 0, ',', '.') }}</td>
                <td class="text-right">Rp {{ number_format($item->total_price, 0, ',', '.') }}</td>
            </tr>
            @endforeach
        </tbody>
    </table>

    {{-- Summary --}}
    <div class="summary-box">
        <table>
            <tr>
                <td class="label">Subtotal</td>
                <td class="value">Rp {{ number_format($subtotal, 0, ',', '.') }}</td>
            </tr>
            @if($totalTambahan > 0)
            <tr>
                <td class="label">Tambahan</td>
                <td class="value">Rp {{ number_format($totalTambahan, 0, ',', '.') }}</td>
            </tr>
            @endif
            @if($totalKembali > 0)
            <tr>
                <td class="label">Potongan (retur)</td>
                <td class="value">- Rp {{ number_format($totalKembali, 0, ',', '.') }}</td>
            </tr>
            @endif
            <tr class="grand-total">
                <td>GRAND TOTAL</td>
                <td class="text-right">Rp {{ number_format($grandTotal, 0, ',', '.') }}</td>
            </tr>
        </table>
    </div>

    <div style="clear:both"></div>

    {{-- Payment Info --}}
    <div class="payment-box">
        <div class="title">Informasi Pembayaran</div>
        <table style="width:100%">
            <tr>
                <td style="width:140px; color:#666;">Metode Pembayaran</td>
                <td>: {{ $paymentMethod }}</td>
            </tr>
            <tr>
                <td style="color:#666;">Status</td>
                <td>: <span class="status-badge {{ $paymentStatusClass }}">{{ $paymentStatusLabel }}</span></td>
            </tr>
        </table>
        @if($order->payment_method !== 'cash')
        <div style="margin-top: 10px; padding-top: 8px; border-top: 1px solid #d0dbe6;">
            <strong>Transfer ke:</strong><br>
            BCA 1234567890 a.n. CV Santa Maria Funeral Organizer
        </div>
        @endif
    </div>

    {{-- Signatures --}}
    <div style="margin-top: 50px;">
        <table style="width: 100%;">
            <tr>
                <td style="text-align: center; width: 33%;">
                    <p style="margin-bottom: 60px;">Keluarga</p>
                    <p>( ________________ )</p>
                </td>
                <td style="text-align: center; width: 33%;">
                    <p style="margin-bottom: 60px;">Finance</p>
                    <p>( ________________ )</p>
                </td>
                <td style="text-align: center; width: 33%;">
                    <p style="margin-bottom: 60px;">Direktur</p>
                    <p>( ________________ )</p>
                </td>
            </tr>
        </table>
    </div>

    <div class="footer">
        Dokumen ini dicetak oleh sistem Santa Maria pada {{ $generatedAt }}. | INV-{{ $order->order_number }}
    </div>
</body>
</html>
