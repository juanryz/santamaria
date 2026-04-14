<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Berita Duka — {{ $obituary->deceased_name }} | Santa Maria Funeral Organizer</title>
  <meta name="description" content="Turut berduka cita atas wafatnya {{ $obituary->deceased_name }}. {{ $obituary->family_message ? \Illuminate\Support\Str::limit($obituary->family_message, 140) : 'Semoga arwah beliau diterima di sisi-Nya.' }}">
  <meta property="og:title" content="Turut Berduka Cita — {{ $obituary->deceased_name }}">
  <meta property="og:description" content="{{ $obituary->family_message ? \Illuminate\Support\Str::limit($obituary->family_message, 200) : 'Semoga arwah beliau diterima di sisi-Nya.' }}">
  <meta property="og:type" content="article">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;500;600;700;800&family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
  <style>
    *, *::before, *::after { margin: 0; padding: 0; box-sizing: border-box; }
    :root {
      --navy: #1E3A5F; --navy-dark: #142C4A; --navy-deep: #0F2139;
      --steel-blue: #4A7BA7; --ice-blue: #D6E6F2; --cream: #FAF8F5;
      --warm-white: #FEFDFB; --gold-soft: #C5A55A;
      --text-dark: #1A2A3A; --text-body: #3D4F5F; --text-muted: #7A8D9C;
    }
    html { scroll-behavior: smooth; }
    body { font-family: 'Inter', sans-serif; color: var(--text-body); background: var(--warm-white); line-height: 1.7; }
    h1, h2, h3 { font-family: 'Playfair Display', Georgia, serif; color: var(--navy); }
    a { color: var(--steel-blue); }

    .back-link { display: inline-flex; align-items: center; gap: 6px; text-decoration: none; color: var(--text-muted); font-size: 0.85rem; margin-bottom: 32px; transition: color 0.2s; }
    .back-link:hover { color: var(--navy); }
    .back-link svg { width: 16px; height: 16px; }

    .obit-container { max-width: 720px; margin: 0 auto; padding: 60px 24px 80px; }

    .obit-header { text-align: center; margin-bottom: 40px; }
    .obit-cross { font-size: 0.8rem; color: var(--gold-soft); letter-spacing: 4px; margin-bottom: 16px; }
    .obit-photo { width: 180px; height: 180px; border-radius: 50%; object-fit: cover; margin: 0 auto 24px; display: block; border: 4px solid var(--ice-blue); }
    .obit-photo-placeholder { width: 180px; height: 180px; border-radius: 50%; margin: 0 auto 24px; background: linear-gradient(135deg, var(--navy-deep), var(--steel-blue)); display: flex; align-items: center; justify-content: center; }
    .obit-photo-placeholder svg { width: 64px; height: 64px; opacity: 0.3; }
    .obit-name { font-size: 2rem; font-weight: 700; margin-bottom: 8px; }
    .obit-dates { font-size: 1rem; color: var(--text-muted); margin-bottom: 8px; }
    .obit-age { font-size: 0.9rem; color: var(--text-muted); }
    .obit-religion { display: inline-block; background: rgba(74,123,167,0.08); color: var(--steel-blue); padding: 4px 14px; border-radius: 4px; font-size: 0.78rem; font-weight: 600; margin-top: 12px; }

    .gold-divider { width: 48px; height: 2px; background: var(--gold-soft); margin: 32px auto; }

    .obit-message { text-align: center; font-style: italic; font-size: 1.05rem; color: var(--text-body); line-height: 1.8; max-width: 560px; margin: 0 auto 32px; }

    .obit-section { margin-bottom: 28px; }
    .obit-section-title { font-size: 0.75rem; font-weight: 600; letter-spacing: 2px; text-transform: uppercase; color: var(--steel-blue); margin-bottom: 12px; font-family: 'Inter', sans-serif; }
    .obit-info { background: #fff; border: 1px solid rgba(30,58,95,0.06); border-radius: 10px; padding: 20px 24px; }
    .obit-info-row { display: flex; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid rgba(30,58,95,0.04); font-size: 0.9rem; }
    .obit-info-row:last-child { border-bottom: none; }
    .obit-info-label { color: var(--text-muted); }
    .obit-info-value { color: var(--navy); font-weight: 500; text-align: right; }

    .obit-survived { font-size: 0.92rem; color: var(--text-body); line-height: 1.8; }

    .obit-share { text-align: center; margin-top: 40px; padding-top: 32px; border-top: 1px solid rgba(30,58,95,0.06); }
    .obit-share p { font-size: 0.82rem; color: var(--text-muted); margin-bottom: 12px; }
    .share-btn { display: inline-flex; align-items: center; gap: 8px; padding: 10px 24px; border-radius: 6px; text-decoration: none; font-size: 0.85rem; font-weight: 600; background: #25D366; color: #fff; transition: background 0.2s; }
    .share-btn:hover { background: #1DA855; }
    .share-btn svg { width: 18px; height: 18px; fill: #fff; }

    @media (max-width: 480px) {
      .obit-name { font-size: 1.5rem; }
      .obit-container { padding: 40px 16px 60px; }
    }
  </style>
</head>
<body>
  <div class="obit-container">
    <a href="/" class="back-link">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="15 18 9 12 15 6"/></svg>
      Kembali ke Beranda
    </a>

    <div class="obit-header">
      <div class="obit-cross">&#10013; TURUT BERDUKA CITA &#10013;</div>

      @if($obituary->deceased_photo_path)
        <img class="obit-photo" src="{{ app(\App\Services\StorageService::class)->getSignedUrl($obituary->deceased_photo_path) }}" alt="{{ $obituary->deceased_name }}">
      @else
        <div class="obit-photo-placeholder">
          <svg viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="1"><circle cx="12" cy="8" r="5"/><path d="M20 21a8 8 0 10-16 0"/></svg>
        </div>
      @endif

      <h1 class="obit-name">{{ $obituary->deceased_name }}</h1>

      @if($obituary->deceased_nickname)
        <div class="obit-dates">"{{ $obituary->deceased_nickname }}"</div>
      @endif

      <div class="obit-dates">
        @if($obituary->deceased_dob)
          {{ $obituary->deceased_dob->translatedFormat('d F Y') }} —
        @endif
        {{ $obituary->deceased_dod->translatedFormat('d F Y') }}
      </div>

      @if($obituary->deceased_age)
        <div class="obit-age">Meninggal dalam usia {{ $obituary->deceased_age }} tahun</div>
      @endif

      @if($obituary->deceased_religion)
        <span class="obit-religion">{{ $obituary->deceased_religion }}</span>
      @endif
    </div>

    @if($obituary->family_message)
      <div class="gold-divider"></div>
      <p class="obit-message">"{{ $obituary->family_message }}"</p>
    @endif

    @if($obituary->survived_by)
      <div class="obit-section">
        <div class="obit-section-title">Duka Mendalam Dirasakan Oleh</div>
        <p class="obit-survived">{{ $obituary->survived_by }}</p>
      </div>
    @endif

    @if($obituary->funeral_location || $obituary->funeral_datetime || $obituary->funeral_address || $obituary->cemetery_name)
      <div class="obit-section">
        <div class="obit-section-title">Informasi Pemakaman</div>
        <div class="obit-info">
          @if($obituary->funeral_location)
            <div class="obit-info-row"><span class="obit-info-label">Lokasi</span><span class="obit-info-value">{{ $obituary->funeral_location }}</span></div>
          @endif
          @if($obituary->funeral_address)
            <div class="obit-info-row"><span class="obit-info-label">Alamat</span><span class="obit-info-value">{{ $obituary->funeral_address }}</span></div>
          @endif
          @if($obituary->funeral_datetime)
            <div class="obit-info-row"><span class="obit-info-label">Waktu</span><span class="obit-info-value">{{ $obituary->funeral_datetime->translatedFormat('l, d F Y — H:i') }} WIB</span></div>
          @endif
          @if($obituary->cemetery_name)
            <div class="obit-info-row"><span class="obit-info-label">Pemakaman</span><span class="obit-info-value">{{ $obituary->cemetery_name }}</span></div>
          @endif
        </div>
      </div>
    @endif

    @if($obituary->prayer_location || $obituary->prayer_datetime)
      <div class="obit-section">
        <div class="obit-section-title">Informasi Doa / Upacara</div>
        <div class="obit-info">
          @if($obituary->prayer_location)
            <div class="obit-info-row"><span class="obit-info-label">Lokasi</span><span class="obit-info-value">{{ $obituary->prayer_location }}</span></div>
          @endif
          @if($obituary->prayer_datetime)
            <div class="obit-info-row"><span class="obit-info-label">Waktu</span><span class="obit-info-value">{{ $obituary->prayer_datetime->translatedFormat('l, d F Y — H:i') }} WIB</span></div>
          @endif
          @if($obituary->prayer_notes)
            <div class="obit-info-row"><span class="obit-info-label">Catatan</span><span class="obit-info-value">{{ $obituary->prayer_notes }}</span></div>
          @endif
        </div>
      </div>
    @endif

    <div class="obit-share">
      <p>Bagikan berita duka ini kepada keluarga dan kerabat</p>
      <a href="https://wa.me/?text={{ urlencode('Turut berduka cita atas wafatnya ' . $obituary->deceased_name . '. ' . ($obituary->family_message ? '"' . \Illuminate\Support\Str::limit($obituary->family_message, 100) . '" ' : '') . url('/berita-duka/' . $obituary->slug)) }}" target="_blank" rel="noopener" class="share-btn">
        <svg viewBox="0 0 24 24"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/></svg>
        Bagikan via WhatsApp
      </a>
    </div>
  </div>
</body>
</html>
