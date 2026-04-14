<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Surat Penerimaan Layanan - {{ $letter->letter_number }}</title>
    <style>
        body { font-family: 'Helvetica', sans-serif; font-size: 11px; color: #333; line-height: 1.6; }
        .header { text-align: center; margin-bottom: 20px; border-bottom: 2px solid #1F3D7A; padding-bottom: 10px; }
        .header h1 { color: #1F3D7A; font-size: 16px; margin: 0; }
        .header h2 { font-size: 13px; margin: 4px 0 0; color: #666; }
        .section { margin-bottom: 16px; }
        .section-title { font-weight: bold; color: #1F3D7A; font-size: 12px; border-bottom: 1px solid #ddd; padding-bottom: 4px; margin-bottom: 8px; }
        .row { display: flex; margin-bottom: 4px; }
        .label { width: 180px; color: #666; }
        .value { flex: 1; }
        .terms { font-size: 10px; line-height: 1.5; background: #f9f9f9; padding: 12px; border-radius: 4px; margin: 10px 0; }
        .signature-row { display: flex; justify-content: space-between; margin-top: 40px; }
        .signature-box { width: 30%; text-align: center; }
        .signature-box .line { border-top: 1px solid #333; margin-top: 60px; padding-top: 4px; }
        .footer { text-align: center; font-size: 9px; color: #999; margin-top: 30px; border-top: 1px solid #eee; padding-top: 8px; }
        table.info { width: 100%; border-collapse: collapse; }
        table.info td { padding: 3px 0; vertical-align: top; }
        table.info td.lbl { width: 180px; color: #666; }
    </style>
</head>
<body>
    <div class="header">
        <h1>CV SANTA MARIA FUNERAL ORGANIZER</h1>
        <h2>SURAT PENERIMAAN LAYANAN KEMATIAN</h2>
        <p>No: {{ $letter->letter_number }}</p>
    </div>

    <div class="section">
        <div class="section-title">I. PENANGGUNG JAWAB (PIHAK PERTAMA)</div>
        <table class="info">
            <tr><td class="lbl">Nama Lengkap</td><td>: {{ $letter->pj_nama }}</td></tr>
            <tr><td class="lbl">Alamat</td><td>: {{ $letter->pj_alamat ?? '-' }}</td></tr>
            <tr><td class="lbl">No. Telepon</td><td>: {{ $letter->pj_no_telp ?? '-' }}</td></tr>
            <tr><td class="lbl">No. KTP</td><td>: {{ $letter->pj_no_ktp ?? '-' }}</td></tr>
            <tr><td class="lbl">Hubungan dengan Almarhum</td><td>: {{ $letter->pj_hubungan ?? '-' }}</td></tr>
        </table>
    </div>

    <div class="section">
        <div class="section-title">II. DATA ALMARHUM/ALMARHUMAH</div>
        <table class="info">
            <tr><td class="lbl">Nama</td><td>: {{ $letter->almarhum_nama }}</td></tr>
            <tr><td class="lbl">Tanggal Lahir</td><td>: {{ $letter->almarhum_tgl_lahir?->format('d F Y') ?? '-' }}</td></tr>
            <tr><td class="lbl">Tanggal Wafat</td><td>: {{ $letter->almarhum_tgl_wafat?->format('d F Y') ?? '-' }}</td></tr>
            <tr><td class="lbl">Agama</td><td>: {{ ucfirst($letter->almarhum_agama ?? '-') }}</td></tr>
            <tr><td class="lbl">Alamat Terakhir</td><td>: {{ $letter->almarhum_alamat_terakhir ?? '-' }}</td></tr>
        </table>
    </div>

    <div class="section">
        <div class="section-title">III. DETAIL LAYANAN</div>
        <table class="info">
            <tr><td class="lbl">Paket Layanan</td><td>: {{ $letter->paket_nama ?? '-' }}</td></tr>
            <tr><td class="lbl">Harga Paket</td><td>: Rp {{ number_format($letter->paket_harga ?? 0, 0, ',', '.') }}</td></tr>
            @if($letter->layanan_tambahan)
            <tr><td class="lbl">Layanan Tambahan</td><td>: {{ $letter->layanan_tambahan }}</td></tr>
            @endif
            <tr><td class="lbl"><strong>Total Biaya</strong></td><td>: <strong>Rp {{ number_format($letter->total_biaya ?? 0, 0, ',', '.') }}</strong></td></tr>
        </table>
    </div>

    <div class="section">
        <div class="section-title">IV. LOKASI & JADWAL</div>
        <table class="info">
            <tr><td class="lbl">Lokasi Prosesi</td><td>: {{ $letter->lokasi_prosesi ?? '-' }}</td></tr>
            <tr><td class="lbl">Lokasi Pemakaman</td><td>: {{ $letter->lokasi_pemakaman ?? '-' }}</td></tr>
            <tr><td class="lbl">Jadwal Mulai</td><td>: {{ $letter->jadwal_mulai?->format('d F Y, H:i') ?? '-' }} WIB</td></tr>
            <tr><td class="lbl">Estimasi Durasi</td><td>: {{ $letter->estimasi_durasi_jam ?? '-' }} jam</td></tr>
        </table>
    </div>

    @if($terms)
    <div class="section">
        <div class="section-title">V. SYARAT & KETENTUAN (Versi {{ $terms->version }})</div>
        <div class="terms">{!! nl2br(e($terms->content)) !!}</div>
    </div>
    @endif

    <div class="section">
        <div class="section-title">VI. TANDA TANGAN</div>
        <p>Dengan menandatangani surat ini, Pihak Pertama menyatakan telah membaca, memahami, dan menyetujui seluruh syarat dan ketentuan layanan pemakaman yang diselenggarakan oleh Pihak Kedua.</p>

        <table style="width: 100%; margin-top: 30px;">
            <tr>
                <td style="text-align: center; width: 33%;">
                    <p><strong>Pihak Pertama</strong></p>
                    <p style="font-size: 10px;">(Penanggung Jawab)</p>
                    <br><br><br>
                    <div style="border-top: 1px solid #333; display: inline-block; padding-top: 4px; min-width: 150px;">
                        {{ $letter->pj_nama }}
                    </div>
                    @if($letter->pj_signed_at)
                    <p style="font-size: 9px; color: #666;">{{ $letter->pj_signed_at->format('d/m/Y H:i') }}</p>
                    @endif
                </td>
                <td style="text-align: center; width: 33%;">
                    <p><strong>Saksi</strong></p>
                    <p style="font-size: 10px;">(Opsional)</p>
                    <br><br><br>
                    <div style="border-top: 1px solid #333; display: inline-block; padding-top: 4px; min-width: 150px;">
                        {{ $letter->saksi_nama ?? '________________' }}
                    </div>
                    @if($letter->saksi_signed_at)
                    <p style="font-size: 9px; color: #666;">{{ $letter->saksi_signed_at->format('d/m/Y H:i') }}</p>
                    @endif
                </td>
                <td style="text-align: center; width: 33%;">
                    <p><strong>Pihak Kedua</strong></p>
                    <p style="font-size: 10px;">(Santa Maria FO)</p>
                    <br><br><br>
                    <div style="border-top: 1px solid #333; display: inline-block; padding-top: 4px; min-width: 150px;">
                        {{ $letter->sm_officer_nama ?? '________________' }}
                    </div>
                    @if($letter->sm_signed_at)
                    <p style="font-size: 9px; color: #666;">{{ $letter->sm_signed_at->format('d/m/Y H:i') }}</p>
                    @endif
                </td>
            </tr>
        </table>
    </div>

    <div class="footer">
        Dokumen ini digenerate oleh sistem Santa Maria Funeral Organizer pada {{ now()->format('d F Y, H:i') }} WIB
    </div>
</body>
</html>
