<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Invoice - Santa Maria</title>
    <style>
        body { font-family: 'Helvetica', sans-serif; color: #333; line-height: 1.6; }
        .invoice-box { max-width: 800px; margin: auto; padding: 30px; }
        .header { border-bottom: 2px solid #5a189a; padding-bottom: 20px; margin-bottom: 20px; }
        .logo { font-size: 28px; font-weight: bold; color: #5a189a; }
        .invoice-details { text-align: right; }
        .section-title { font-weight: bold; margin-top: 20px; border-bottom: 1px solid #eee; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th { background: #f8f9fa; text-align: left; padding: 10px; border-bottom: 2px solid #eee; }
        td { padding: 10px; border-bottom: 1px solid #eee; }
        .total { font-size: 20px; font-weight: bold; text-align: right; margin-top: 30px; color: #5a189a; }
        .footer { margin-top: 50px; font-size: 12px; text-align: center; color: #999; }
    </style>
</head>
<body>
    <div class="invoice-box">
        <div class="header">
            <table style="border:0">
                <tr>
                    <td style="border:0"><div class="logo">SANTA MARIA</div></td>
                    <td style="border:0; text-align:right">
                        <strong>Invoice: {{ $invoice_number }}</strong><br>
                        Tanggal: {{ $issued_date }}
                    </td>
                </tr>
            </table>
        </div>

        <table style="border:0">
            <tr>
                <td style="border:0">
                    <strong>Penerima:</strong><br>
                    {{ $order->pic_name }}<br>
                    {{ $order->pic_address }}<br>
                    {{ $order->pic_phone }}
                </td>
                <td style="border:0; text-align:right">
                    <strong>Layanan Untuk:</strong><br>
                    Almarhum: {{ $order->deceased_name }}<br>
                    Agama: {{ ucfirst($order->deceased_religion) }}<br>
                    Wafat: {{ $order->deceased_dod->format('d/m/Y') }}
                </td>
            </tr>
        </table>

        <div class="section-title">RINCIAN LAYANAN</div>
        <table>
            <thead>
                <tr>
                    <th>Item / Layanan</th>
                    <th style="text-align:right">Harga</th>
                </tr>
            </thead>
            <tbody>
                @foreach($items as $item)
                <tr>
                    <td>{{ $item['name'] }}</td>
                    <td style="text-align:right">Rp {{ number_format($item['price'], 0, ',', '.') }}</td>
                </tr>
                @endforeach
            </tbody>
        </table>

        <div class="total">
            TOTAL PEMBAYARAN: Rp {{ number_format($total, 0, ',', '.') }}
        </div>

        <div class="footer">
            Terima kasih telah mempercayakan Santa Maria Funeral Organizer.<br>
            Jl. Raya Santa Maria No. 88, Kota Harapan.<br>
            <em>"Melayani dengan Hati di Saat Terberat"</em>
        </div>
    </div>
</body>
</html>
