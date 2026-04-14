<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Santa Maria Funeral Organizer — Layanan Pemakaman Profesional Semarang</title>
  <meta name="description" content="Santa Maria Funeral Organizer Semarang — Layanan pemakaman profesional, terpadu, dan penuh empati. Transportasi jenazah, dekorasi, konsumsi, pemuka agama. Hubungi 024-3560444.">
  <meta name="keywords" content="funeral organizer semarang, layanan pemakaman semarang, jasa pemakaman, rumah duka semarang, transportasi jenazah, dekorasi pemakaman, katering duka, pemuka agama, Santa Maria Funeral Organizer">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;500;600;700;800&family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
  <style>
    *, *::before, *::after { margin: 0; padding: 0; box-sizing: border-box; }

    :root {
      /* Warna sesuai logo Santa Maria — biru navy & steel blue */
      --navy: #1E3A5F;
      --navy-dark: #142C4A;
      --navy-deep: #0F2139;
      --steel-blue: #4A7BA7;
      --steel-light: #6B9CC5;
      --ice-blue: #D6E6F2;
      --cream: #FAF8F5;
      --warm-white: #FEFDFB;
      --gold-soft: #C5A55A;
      --gold-muted: #B8975C;
      --text-dark: #1A2A3A;
      --text-body: #3D4F5F;
      --text-muted: #7A8D9C;
      --border-light: rgba(30,58,95,0.08);
    }

    html { scroll-behavior: smooth; }

    body {
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
      color: var(--text-body);
      background: var(--warm-white);
      line-height: 1.7;
      overflow-x: hidden;
    }

    h1, h2, h3, h4 { font-family: 'Playfair Display', Georgia, serif; color: var(--navy); }

    /* ── Navigation ── */
    .navbar {
      position: fixed; top: 0; left: 0; right: 0; z-index: 100;
      background: rgba(254,253,251,0.92);
      backdrop-filter: blur(16px); -webkit-backdrop-filter: blur(16px);
      border-bottom: 1px solid var(--border-light);
      transition: box-shadow 0.3s;
    }
    .navbar.scrolled { box-shadow: 0 2px 20px rgba(30,58,95,0.08); }
    .nav-inner {
      max-width: 1140px; margin: 0 auto;
      display: flex; align-items: center; justify-content: space-between;
      padding: 14px 24px;
    }
    .nav-logo {
      display: flex; align-items: center; gap: 12px;
      text-decoration: none; color: var(--navy);
    }
    .nav-logo img { height: 44px; width: auto; }
    .nav-logo-text { display: flex; flex-direction: column; line-height: 1.2; }
    .nav-logo-text .brand { font-family: 'Playfair Display', serif; font-weight: 700; font-size: 1.15rem; color: var(--navy); letter-spacing: 0.5px; }
    .nav-logo-text .sub { font-size: 0.65rem; color: var(--text-muted); letter-spacing: 2px; text-transform: uppercase; }
    .nav-links { display: flex; gap: 28px; list-style: none; }
    .nav-links a {
      text-decoration: none; color: var(--text-muted);
      font-weight: 500; font-size: 0.85rem; transition: color 0.2s; letter-spacing: 0.3px;
    }
    .nav-links a:hover { color: var(--navy); }
    .nav-cta {
      background: var(--navy); color: #fff !important;
      padding: 10px 24px; border-radius: 6px; font-weight: 600;
      text-decoration: none; font-size: 0.85rem; transition: background 0.2s;
      letter-spacing: 0.3px;
    }
    .nav-cta:hover { background: var(--navy-dark); }
    .mobile-toggle { display: none; background: none; border: none; cursor: pointer; padding: 8px; }
    .mobile-toggle span { display: block; width: 22px; height: 2px; background: var(--navy); margin: 5px 0; transition: 0.3s; border-radius: 1px; }

    /* ── Hero ── */
    .hero {
      min-height: 100vh; display: flex; align-items: center;
      background: linear-gradient(170deg, var(--navy-deep) 0%, var(--navy) 40%, var(--steel-blue) 100%);
      padding: 100px 24px 80px;
      position: relative; overflow: hidden;
    }
    .hero::before {
      content: ''; position: absolute; inset: 0;
      background: url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='0.02'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E");
    }
    /* Decorative candle glow */
    .hero::after {
      content: ''; position: absolute; bottom: -20%; right: 5%;
      width: 500px; height: 500px; border-radius: 50%;
      background: radial-gradient(circle, rgba(197,165,90,0.08) 0%, transparent 70%);
    }
    .hero-inner {
      max-width: 1140px; margin: 0 auto; width: 100%;
      display: grid; grid-template-columns: 1fr 1fr; gap: 60px; align-items: center;
      position: relative; z-index: 1;
    }
    .hero-content { color: #fff; }
    .hero-divider {
      width: 48px; height: 2px; background: var(--gold-soft); margin-bottom: 24px;
    }
    .hero h1 {
      font-size: 3rem; font-weight: 700; line-height: 1.15;
      margin-bottom: 20px; color: #fff;
      letter-spacing: -0.5px;
    }
    .hero h1 em { font-style: italic; color: var(--gold-soft); }
    .hero p {
      font-size: 1.05rem; color: rgba(255,255,255,0.75); margin-bottom: 36px;
      max-width: 480px; line-height: 1.8;
    }
    .hero-buttons { display: flex; gap: 14px; flex-wrap: wrap; }
    .btn-gold {
      background: var(--gold-soft); color: var(--navy-deep);
      padding: 14px 32px; border-radius: 6px; font-weight: 600;
      text-decoration: none; font-size: 0.9rem; border: none; cursor: pointer;
      transition: background 0.2s; display: inline-flex; align-items: center; gap: 8px;
      letter-spacing: 0.3px;
    }
    .btn-gold:hover { background: #D4B76A; }
    .btn-outline-light {
      background: transparent; color: rgba(255,255,255,0.9);
      padding: 14px 32px; border-radius: 6px; font-weight: 500;
      text-decoration: none; font-size: 0.9rem;
      border: 1px solid rgba(255,255,255,0.25); cursor: pointer;
      transition: border-color 0.2s, color 0.2s;
    }
    .btn-outline-light:hover { border-color: rgba(255,255,255,0.5); color: #fff; }

    /* Hero illustration */
    .hero-visual { display: flex; justify-content: center; align-items: center; }
    .hero-illustration {
      width: 100%; max-width: 440px; position: relative;
    }
    .hero-scene {
      width: 100%; aspect-ratio: 4/3; border-radius: 16px; overflow: hidden;
      position: relative;
      background: linear-gradient(180deg, rgba(255,255,255,0.05) 0%, rgba(255,255,255,0.02) 100%);
      border: 1px solid rgba(255,255,255,0.08);
    }
    .hero-scene svg { width: 100%; height: 100%; }

    .hero-info-card {
      position: absolute; bottom: -20px; left: -20px; right: 40px;
      background: rgba(255,255,255,0.95); backdrop-filter: blur(12px);
      border-radius: 12px; padding: 20px 24px;
      box-shadow: 0 12px 40px rgba(15,33,57,0.2);
      display: flex; gap: 24px;
    }
    .hero-info-item { text-align: center; flex: 1; }
    .hero-info-item .num { font-family: 'Playfair Display', serif; font-size: 1.5rem; font-weight: 700; color: var(--navy); }
    .hero-info-item .label { font-size: 0.7rem; color: var(--text-muted); margin-top: 2px; letter-spacing: 0.5px; text-transform: uppercase; }

    /* ── Section Common ── */
    section { padding: 100px 24px; }
    .section-inner { max-width: 1140px; margin: 0 auto; }
    .section-label {
      display: inline-block; font-size: 0.7rem; font-weight: 600; letter-spacing: 3px;
      text-transform: uppercase; color: var(--steel-blue); margin-bottom: 12px;
      font-family: 'Inter', sans-serif;
    }
    .section-title { font-size: 2.3rem; font-weight: 700; margin-bottom: 16px; line-height: 1.25; }
    .section-subtitle { font-size: 1rem; color: var(--text-muted); max-width: 560px; margin-bottom: 56px; line-height: 1.8; }
    .text-center { text-align: center; }
    .text-center .section-subtitle { margin-left: auto; margin-right: auto; }
    .gold-line { width: 40px; height: 2px; background: var(--gold-soft); margin-bottom: 20px; }
    .text-center .gold-line { margin-left: auto; margin-right: auto; }

    /* ── Layanan ── */
    #layanan { background: var(--cream); }
    .services-grid {
      display: grid; grid-template-columns: repeat(3, 1fr); gap: 24px;
    }
    .service-card {
      background: #fff; border: 1px solid var(--border-light);
      border-radius: 12px; padding: 36px 28px;
      transition: transform 0.3s, box-shadow 0.3s;
    }
    .service-card:hover {
      transform: translateY(-4px);
      box-shadow: 0 12px 36px rgba(30,58,95,0.08);
    }
    .service-icon-wrap {
      width: 60px; height: 60px; border-radius: 12px;
      display: flex; align-items: center; justify-content: center;
      margin-bottom: 20px; position: relative;
    }
    .service-icon-wrap svg { width: 32px; height: 32px; }
    .service-card h3 { font-size: 1.1rem; font-weight: 600; margin-bottom: 12px; }
    .service-card p { font-size: 0.88rem; color: var(--text-muted); line-height: 1.7; }

    /* ── Image Section (Ilustrasi keluarga Indonesia) ── */
    .image-section {
      background: var(--warm-white); padding: 80px 24px;
    }
    .image-grid {
      max-width: 1140px; margin: 0 auto;
      display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 20px;
    }
    .image-card {
      border-radius: 12px; overflow: hidden; position: relative;
      aspect-ratio: 3/4;
    }
    .image-card svg { width: 100%; height: 100%; display: block; }
    .image-card .overlay {
      position: absolute; bottom: 0; left: 0; right: 0;
      background: linear-gradient(to top, rgba(15,33,57,0.85), transparent);
      padding: 24px 20px 20px; color: #fff;
    }
    .image-card .overlay h4 { color: #fff; font-size: 1rem; margin-bottom: 4px; }
    .image-card .overlay p { font-size: 0.78rem; color: rgba(255,255,255,0.7); }

    /* ── Keunggulan ── */
    #keunggulan { background: var(--navy-deep); color: rgba(255,255,255,0.8); padding: 100px 24px; }
    #keunggulan .section-label { color: var(--gold-soft); }
    #keunggulan .section-title { color: #fff; }
    #keunggulan .section-subtitle { color: rgba(255,255,255,0.55); }
    .advantages-grid {
      display: grid; grid-template-columns: repeat(3, 1fr); gap: 32px;
    }
    .advantage-item {
      padding: 32px; border-radius: 12px;
      background: rgba(255,255,255,0.04);
      border: 1px solid rgba(255,255,255,0.06);
      transition: background 0.3s;
    }
    .advantage-item:hover { background: rgba(255,255,255,0.07); }
    .advantage-icon {
      width: 48px; height: 48px; border-radius: 10px;
      background: rgba(197,165,90,0.12);
      display: flex; align-items: center; justify-content: center;
      margin-bottom: 20px;
    }
    .advantage-icon svg { width: 24px; height: 24px; }
    .advantage-item h4 { color: #fff; font-weight: 600; margin-bottom: 10px; font-size: 1rem; font-family: 'Inter', sans-serif; }
    .advantage-item p { font-size: 0.85rem; color: rgba(255,255,255,0.5); line-height: 1.7; }

    /* ── Alur Layanan ── */
    #alur { background: var(--cream); }
    .process-steps { position: relative; max-width: 680px; }
    .process-steps::before {
      content: ''; position: absolute; left: 23px; top: 48px; bottom: 48px;
      width: 1px; background: var(--ice-blue);
    }
    .process-step {
      display: flex; gap: 28px; align-items: flex-start; padding: 20px 0;
      position: relative;
    }
    .step-number {
      flex-shrink: 0; width: 48px; height: 48px; border-radius: 50%;
      display: flex; align-items: center; justify-content: center;
      font-size: 0.85rem; font-weight: 700; color: #fff;
      background: var(--navy);
      z-index: 1;
      font-family: 'Inter', sans-serif;
    }
    .step-content h3 { font-size: 1.05rem; font-weight: 600; margin-bottom: 6px; font-family: 'Inter', sans-serif; }
    .step-content p { font-size: 0.88rem; color: var(--text-muted); max-width: 480px; }

    /* ── Paket ── */
    #paket { background: var(--warm-white); }
    .packages-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 24px; }
    .package-card {
      border-radius: 12px; padding: 40px 28px; text-align: center;
      border: 1px solid var(--border-light); background: #fff;
      transition: transform 0.3s, box-shadow 0.3s;
      position: relative;
    }
    .package-card:hover { transform: translateY(-6px); box-shadow: 0 16px 48px rgba(30,58,95,0.1); }
    .package-card.featured {
      border-color: var(--navy);
      box-shadow: 0 4px 24px rgba(30,58,95,0.1);
    }
    .package-card.featured::before {
      content: 'Pilihan Terbaik'; position: absolute; top: 0; left: 50%;
      transform: translateX(-50%) translateY(-50%);
      background: var(--navy); color: #fff; padding: 6px 20px;
      font-size: 0.7rem; font-weight: 600; border-radius: 50px;
      letter-spacing: 0.5px;
    }
    .package-name { font-size: 1.25rem; font-weight: 700; margin-bottom: 8px; font-family: 'Inter', sans-serif; color: var(--navy); }
    .package-price { font-size: 0.85rem; color: var(--text-muted); margin-bottom: 28px; }
    .package-features { list-style: none; text-align: left; margin-bottom: 32px; }
    .package-features li {
      padding: 10px 0; font-size: 0.85rem; color: var(--text-body);
      display: flex; align-items: flex-start; gap: 12px;
      border-bottom: 1px solid rgba(30,58,95,0.04);
    }
    .package-features li:last-child { border-bottom: none; }
    .check-icon { flex-shrink: 0; width: 20px; height: 20px; color: var(--steel-blue); }
    .btn-navy {
      display: inline-block; width: 100%; text-align: center;
      background: var(--navy); color: #fff;
      padding: 14px 24px; border-radius: 6px; font-weight: 600;
      text-decoration: none; font-size: 0.88rem;
      transition: background 0.2s;
    }
    .btn-navy:hover { background: var(--navy-dark); }
    .btn-navy-outline {
      display: inline-block; width: 100%; text-align: center;
      background: transparent; color: var(--navy);
      padding: 14px 24px; border-radius: 6px; font-weight: 600;
      text-decoration: none; font-size: 0.88rem;
      border: 1px solid var(--navy); transition: background 0.2s, color 0.2s;
    }
    .btn-navy-outline:hover { background: var(--navy); color: #fff; }

    /* ── Testimoni ── */
    #testimoni { background: var(--cream); }
    .testimonials-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 24px; }
    .testimonial-card {
      background: #fff; border-radius: 12px; padding: 32px;
      border: 1px solid var(--border-light);
    }
    .testimonial-card .quote-mark {
      font-size: 2.5rem; color: var(--ice-blue); font-family: Georgia, serif;
      line-height: 1; margin-bottom: 12px; display: block;
    }
    .testimonial-card p { font-size: 0.9rem; color: var(--text-body); margin-bottom: 24px; line-height: 1.8; font-style: italic; }
    .testimonial-author { display: flex; align-items: center; gap: 12px; }
    .testimonial-avatar {
      width: 44px; height: 44px; border-radius: 50%;
      overflow: hidden; flex-shrink: 0;
    }
    .testimonial-avatar svg { width: 100%; height: 100%; }
    .testimonial-name { font-weight: 600; font-size: 0.88rem; color: var(--navy); }
    .testimonial-role { font-size: 0.75rem; color: var(--text-muted); }
    .stars { color: var(--gold-soft); font-size: 0.8rem; margin-bottom: 16px; letter-spacing: 2px; }

    /* ── FAQ ── */
    #faq { background: var(--warm-white); }
    .faq-list { max-width: 700px; margin: 0 auto; }
    .faq-item { border-bottom: 1px solid var(--border-light); }
    .faq-question {
      width: 100%; background: none; border: none; cursor: pointer;
      padding: 22px 0; font-size: 0.95rem; font-weight: 600;
      text-align: left; color: var(--navy);
      display: flex; justify-content: space-between; align-items: center;
      font-family: 'Inter', sans-serif;
    }
    .faq-question .icon { font-size: 1.2rem; color: var(--steel-blue); transition: transform 0.3s; font-weight: 300; }
    .faq-item.open .faq-question .icon { transform: rotate(45deg); }
    .faq-answer { max-height: 0; overflow: hidden; transition: max-height 0.3s ease; }
    .faq-item.open .faq-answer { max-height: 300px; padding-bottom: 20px; }
    .faq-answer p { font-size: 0.88rem; color: var(--text-muted); line-height: 1.8; }

    /* ── CTA ── */
    .cta-section {
      background: var(--navy-deep); text-align: center; color: #fff;
      position: relative; overflow: hidden;
    }
    .cta-section::before {
      content: ''; position: absolute; top: -50%; left: 50%; transform: translateX(-50%);
      width: 800px; height: 800px; border-radius: 50%;
      background: radial-gradient(circle, rgba(197,165,90,0.06) 0%, transparent 60%);
    }
    .cta-section .section-inner { position: relative; z-index: 1; }
    .cta-section h2 { color: #fff; font-size: 2.2rem; margin-bottom: 16px; }
    .cta-section p { color: rgba(255,255,255,0.6); font-size: 1rem; margin-bottom: 36px; max-width: 480px; margin-left: auto; margin-right: auto; line-height: 1.8; }
    .cta-phones { display: flex; gap: 20px; justify-content: center; flex-wrap: wrap; margin-bottom: 32px; }
    .cta-phone {
      display: flex; align-items: center; gap: 10px;
      color: rgba(255,255,255,0.8); font-size: 1rem; font-weight: 500;
    }
    .cta-phone svg { width: 20px; height: 20px; color: var(--gold-soft); }

    /* ── Footer ── */
    footer {
      background: var(--navy-deep); color: rgba(255,255,255,0.5);
      padding: 60px 24px 30px; border-top: 1px solid rgba(255,255,255,0.06);
    }
    .footer-inner {
      max-width: 1140px; margin: 0 auto;
      display: grid; grid-template-columns: 2fr 1fr 1fr 1fr; gap: 40px;
    }
    .footer-brand { }
    .footer-brand .logo-row { display: flex; align-items: center; gap: 10px; margin-bottom: 16px; }
    .footer-brand .logo-row img { height: 36px; filter: brightness(0) invert(1) opacity(0.8); }
    .footer-brand h3 { color: rgba(255,255,255,0.9); font-size: 1.1rem; }
    .footer-brand p { font-size: 0.82rem; line-height: 1.7; }
    .footer-col h4 { color: rgba(255,255,255,0.8); font-size: 0.82rem; margin-bottom: 16px; font-weight: 600; letter-spacing: 1px; text-transform: uppercase; font-family: 'Inter', sans-serif; }
    .footer-col ul { list-style: none; }
    .footer-col li { margin-bottom: 10px; }
    .footer-col a { color: rgba(255,255,255,0.45); text-decoration: none; font-size: 0.82rem; transition: color 0.2s; }
    .footer-col a:hover { color: rgba(255,255,255,0.8); }
    .footer-address { font-size: 0.82rem; line-height: 1.7; margin-top: 8px; color: rgba(255,255,255,0.45); }
    .footer-bottom {
      max-width: 1140px; margin: 36px auto 0; padding-top: 20px;
      border-top: 1px solid rgba(255,255,255,0.06);
      display: flex; justify-content: space-between; align-items: center;
      font-size: 0.75rem;
    }

    /* ── WhatsApp Float ── */
    .wa-float {
      position: fixed; bottom: 28px; right: 28px; z-index: 99;
      width: 56px; height: 56px; border-radius: 50%;
      background: #25D366; display: flex; align-items: center; justify-content: center;
      box-shadow: 0 4px 16px rgba(37,211,102,0.35);
      text-decoration: none; transition: transform 0.2s;
    }
    .wa-float:hover { transform: scale(1.08); }
    .wa-float svg { width: 28px; height: 28px; fill: #fff; }

    /* ── Responsive ── */
    @media (max-width: 968px) {
      .hero-inner { grid-template-columns: 1fr; text-align: center; }
      .hero h1 { font-size: 2.2rem; }
      .hero p { margin-left: auto; margin-right: auto; }
      .hero-buttons { justify-content: center; }
      .hero-visual { display: none; }
      .services-grid, .packages-grid, .testimonials-grid, .advantages-grid { grid-template-columns: 1fr; max-width: 480px; margin-left: auto; margin-right: auto; }
      .image-grid { grid-template-columns: 1fr; max-width: 360px; margin-left: auto; margin-right: auto; }
      .footer-inner { grid-template-columns: 1fr 1fr; }
      .nav-links { display: none; }
      .mobile-toggle { display: block; }
      .nav-links.active {
        display: flex; flex-direction: column; position: absolute;
        top: 100%; left: 0; right: 0; background: rgba(254,253,251,0.97);
        backdrop-filter: blur(16px); padding: 20px 24px; gap: 14px;
        border-bottom: 1px solid var(--border-light);
      }
      .hero-divider { margin-left: auto; margin-right: auto; }
    }
    @media (max-width: 480px) {
      .hero h1 { font-size: 1.8rem; }
      section { padding: 64px 16px; }
      .hero { padding: 100px 16px 60px; }
      .footer-inner { grid-template-columns: 1fr; }
      .cta-phones { flex-direction: column; align-items: center; }
    }

    /* ── Obituaries (Berita Duka) ── */
    #berita-duka { background: var(--warm-white); }
    .obituaries-grid {
      display: grid; grid-template-columns: repeat(3, 1fr); gap: 24px;
      text-align: left;
    }
    .obituary-card {
      background: #fff; border: 1px solid var(--border-light); border-radius: 12px;
      overflow: hidden; transition: transform 0.3s, box-shadow 0.3s;
    }
    .obituary-card:hover { transform: translateY(-4px); box-shadow: 0 12px 36px rgba(30,58,95,0.08); }
    .obituary-card a { text-decoration: none; color: inherit; }
    .obituary-photo {
      width: 100%; aspect-ratio: 1/1; object-fit: cover; background: var(--ice-blue);
      display: flex; align-items: center; justify-content: center;
    }
    .obituary-photo-placeholder {
      width: 100%; aspect-ratio: 1/1; background: linear-gradient(135deg, var(--navy-deep), var(--steel-blue));
      display: flex; align-items: center; justify-content: center;
    }
    .obituary-photo-placeholder svg { width: 48px; height: 48px; opacity: 0.3; }
    .obituary-body { padding: 20px; }
    .obituary-cross { font-size: 0.8rem; color: var(--gold-soft); margin-bottom: 8px; letter-spacing: 2px; }
    .obituary-name { font-family: 'Playfair Display', serif; font-size: 1.1rem; font-weight: 700; color: var(--navy); margin-bottom: 4px; }
    .obituary-dates { font-size: 0.78rem; color: var(--text-muted); margin-bottom: 12px; }
    .obituary-location { font-size: 0.82rem; color: var(--text-body); display: flex; align-items: flex-start; gap: 6px; }
    .obituary-location svg { width: 14px; height: 14px; flex-shrink: 0; margin-top: 2px; }
    .obituary-message { font-size: 0.82rem; color: var(--text-muted); font-style: italic; margin-top: 12px; line-height: 1.6; }
    .obituaries-loading, .obituaries-empty, .articles-loading, .articles-empty {
      text-align: center; padding: 40px; color: var(--text-muted); font-size: 0.9rem;
    }
    @media (max-width: 968px) {
      .obituaries-grid, .articles-grid { grid-template-columns: 1fr; max-width: 400px; margin-left: auto; margin-right: auto; }
    }

    /* ── Blog / Articles ── */
    .articles-grid {
      display: grid; grid-template-columns: repeat(3, 1fr); gap: 24px;
      text-align: left;
    }
    .article-card {
      background: #fff; border: 1px solid var(--border-light); border-radius: 12px;
      overflow: hidden; transition: transform 0.3s, box-shadow 0.3s;
    }
    .article-card:hover { transform: translateY(-4px); box-shadow: 0 12px 36px rgba(30,58,95,0.08); }
    .article-card a { text-decoration: none; color: inherit; }
    .article-cover {
      width: 100%; aspect-ratio: 16/9; object-fit: cover; background: var(--ice-blue);
    }
    .article-cover-placeholder {
      width: 100%; aspect-ratio: 16/9; background: linear-gradient(135deg, var(--ice-blue), var(--cream));
      display: flex; align-items: center; justify-content: center;
    }
    .article-cover-placeholder svg { width: 32px; height: 32px; color: var(--steel-blue); opacity: 0.3; }
    .article-body { padding: 20px; }
    .article-category {
      display: inline-block; font-size: 0.68rem; font-weight: 600; letter-spacing: 1px;
      text-transform: uppercase; color: var(--steel-blue); margin-bottom: 8px;
      background: rgba(74,123,167,0.08); padding: 3px 10px; border-radius: 4px;
    }
    .article-title { font-family: 'Playfair Display', serif; font-size: 1.05rem; font-weight: 700; color: var(--navy); margin-bottom: 8px; line-height: 1.4; }
    .article-excerpt { font-size: 0.82rem; color: var(--text-muted); line-height: 1.7; margin-bottom: 12px; }
    .article-meta { font-size: 0.72rem; color: var(--text-hint); display: flex; gap: 12px; }
  </style>
</head>
<body>

<!-- Navigation -->
<nav class="navbar" id="navbar">
  <div class="nav-inner">
    <a href="#" class="nav-logo">
      <img src="frontend/assets/images/logo.png" alt="Santa Maria Logo">
    </a>
    <ul class="nav-links" id="navLinks">
      <li><a href="#layanan">Layanan</a></li>
      <li><a href="#keunggulan">Keunggulan</a></li>
      <li><a href="#alur">Alur Layanan</a></li>
      <li><a href="#paket">Paket</a></li>
      <li><a href="#testimoni">Testimoni</a></li>
      <li><a href="#berita-duka">Berita Duka</a></li>
      <li><a href="#blog">Blog</a></li>
      <li><a href="#faq">FAQ</a></li>
    </ul>
    <a href="tel:0243560444" class="nav-cta">024-3560444</a>
    <button class="mobile-toggle" id="mobileToggle" aria-label="Menu">
      <span></span><span></span><span></span>
    </button>
  </div>
</nav>

<!-- Hero -->
<section class="hero">
  <div class="hero-inner">
    <div class="hero-content">
      <div class="hero-divider"></div>
      <h1>Mendampingi dengan <em>Penuh Hormat</em> di Saat Tersulit</h1>
      <p>Santa Maria Funeral Organizer menangani seluruh koordinasi pemakaman secara profesional dan terpadu — transportasi jenazah, dekorasi, konsumsi, hingga upacara keagamaan. Biarkan kami meringankan beban Anda.</p>
      <div class="hero-buttons">
        <a href="https://wa.me/6281128288286?text=Halo%20Santa%20Maria%2C%20saya%20ingin%20konsultasi%20layanan%20pemakaman." class="btn-gold">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07 19.5 19.5 0 01-6-6 19.79 19.79 0 01-3.07-8.67A2 2 0 014.11 2h3a2 2 0 012 1.72 12.84 12.84 0 00.7 2.81 2 2 0 01-.45 2.11L8.09 9.91a16 16 0 006 6l1.27-1.27a2 2 0 012.11-.45 12.84 12.84 0 002.81.7A2 2 0 0122 16.92z"/></svg>
          Hubungi Sekarang
        </a>
        <a href="#layanan" class="btn-outline-light">Lihat Layanan Kami</a>
      </div>
    </div>
    <div class="hero-visual">
      <div class="hero-illustration">
        <div class="hero-scene">
          <!-- Photo illustration: keluarga Indonesia di upacara pemakaman -->
          <img src="images/hero_image.png" alt="Santa Maria Funeral Service" style="width: 100%; height: 100%; object-fit: cover;">
        </div>
        <div class="hero-info-card">
          <div class="hero-info-item">
            <div class="num">500+</div>
            <div class="label">Keluarga Terlayani</div>
          </div>
          <div class="hero-info-item">
            <div class="num">24/7</div>
            <div class="label">Siaga Darurat</div>
          </div>
          <div class="hero-info-item">
            <div class="num">15+</div>
            <div class="label">Tahun Pengalaman</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</section>

<!-- Image Gallery Section -->
<section class="image-section">
  <div class="image-grid">
    <!-- Card 1: Tim koordinasi pemakaman -->
    <div class="image-card">
      <img src="images/professional_team.png" alt="Tim Profesional" style="width: 100%; height: 100%; object-fit: cover;">
      <div class="overlay">
        <h4>Tim Profesional</h4>
        <p>Koordinasi terpadu oleh tim berpengalaman</p>
      </div>
    </div>
    <!-- Card 2: Dekorasi ruang duka -->
    <div class="image-card">
      <img src="images/room_decoration.png" alt="Dekorasi Penuh Penghormatan" style="width: 100%; height: 100%; object-fit: cover;">
      <div class="overlay">
        <h4>Dekorasi Penuh Penghormatan</h4>
        <p>Rangkaian bunga dan ruang duka yang khidmat</p>
      </div>
    </div>
    <!-- Card 3: Keluarga mendapatkan pendampingan -->
    <div class="image-card">
      <img src="images/family_assistance.png" alt="Pendampingan Penuh Empati" style="width: 100%; height: 100%; object-fit: cover;">
      <div class="overlay">
        <h4>Pendampingan Penuh Empati</h4>
        <p>Menemani keluarga di setiap langkah</p>
      </div>
    </div>
  </div>
</section>

<!-- Layanan -->
<section id="layanan">
  <div class="section-inner text-center">
    <span class="section-label">Layanan Kami</span>
    <div class="gold-line"></div>
    <h2 class="section-title">Seluruh Kebutuhan Pemakaman dalam Satu Genggaman</h2>
    <p class="section-subtitle">Kami menangani setiap detail dengan penuh perhatian dan profesionalisme, sehingga Anda dan keluarga dapat berduka dengan tenang.</p>
    <div class="services-grid">
      <div class="service-card">
        <div class="service-icon-wrap" style="background:rgba(30,58,95,0.06);">
          <svg viewBox="0 0 24 24" fill="none" stroke="var(--navy)" stroke-width="1.5"><rect x="1" y="6" width="15" height="12" rx="2"/><path d="M16 10l5-3v10l-5-3z"/></svg>
        </div>
        <h3>Transportasi Jenazah</h3>
        <p>Armada kendaraan khusus dengan GPS tracking real-time. Keluarga dapat memantau posisi dan estimasi waktu kedatangan langsung dari aplikasi.</p>
      </div>
      <div class="service-card">
        <img src="images/flower_arrangement.png" alt="Rangkaian Bunga" style="width: 100%; aspect-ratio: 1/1; object-fit: cover; border-radius: 12px; margin-bottom: 20px;">
        <h3>Dekorasi & Rangkaian Bunga</h3>
        <p>Tim dekorasi La Fiore menyiapkan rangkaian bunga dan dekorasi ruang duka sesuai adat dan preferensi keluarga dengan penuh penghormatan.</p>
      </div>
      <div class="service-card">
        <div class="service-icon-wrap" style="background:rgba(74,123,167,0.08);">
          <svg viewBox="0 0 24 24" fill="none" stroke="var(--steel-blue)" stroke-width="1.5"><path d="M18 8h1a4 4 0 010 8h-1M2 8h16v9a4 4 0 01-4 4H6a4 4 0 01-4-4V8z"/><path d="M6 1v3M10 1v3M14 1v3"/></svg>
        </div>
        <h3>Konsumsi & Katering</h3>
        <p>Penyediaan makanan dan minuman untuk pelayat dan keluarga. Menu disesuaikan dengan jumlah tamu, tradisi keluarga, dan kebutuhan khusus.</p>
      </div>
      <div class="service-card">
        <div class="service-icon-wrap" style="background:rgba(109,76,65,0.06);">
          <svg viewBox="0 0 24 24" fill="none" stroke="#6D4C41" stroke-width="1.5"><path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z"/><line x1="4" y1="22" x2="4" y2="15"/></svg>
        </div>
        <h3>Pemuka Agama</h3>
        <p>Koordinasi langsung dengan pemuka agama untuk upacara keagamaan — doa, sembahyang, atau ibadah sesuai keyakinan almarhum dan keluarga.</p>
      </div>
      <div class="service-card">
        <div class="service-icon-wrap" style="background:rgba(30,58,95,0.06);">
          <svg viewBox="0 0 24 24" fill="none" stroke="var(--navy)" stroke-width="1.5"><path d="M21 16V8a2 2 0 00-1-1.73l-7-4a2 2 0 00-2 0l-7 4A2 2 0 003 8v8a2 2 0 001 1.73l7 4a2 2 0 002 0l7-4A2 2 0 0021 16z"/><polyline points="3.27 6.96 12 12.01 20.73 6.96"/><line x1="12" y1="22.08" x2="12" y2="12"/></svg>
        </div>
        <h3>Perlengkapan Pemakaman</h3>
        <p>Seluruh kebutuhan perlengkapan tersedia dari gudang kami — mulai dari kain kafan, peti, bunga papan, hingga kebutuhan upacara lainnya.</p>
      </div>
      <div class="service-card">
        <img src="images/app_monitoring.png" alt="Monitoring Aplikasi" style="width: 100%; aspect-ratio: 4/3; object-fit: cover; border-radius: 12px; margin-bottom: 20px;">
        <h3>Monitoring via Aplikasi</h3>
        <p>Pantau seluruh progres layanan secara real-time melalui aplikasi Santa Maria. Dari persiapan gudang hingga kedatangan tim di lokasi.</p>
      </div>
    </div>
  </div>
</section>

<!-- Keunggulan -->
<section id="keunggulan">
  <div class="section-inner text-center">
    <span class="section-label">Mengapa Memilih Kami</span>
    <div class="gold-line"></div>
    <h2 class="section-title">Kepedulian yang Terukur, Layanan yang Terpercaya</h2>
    <p class="section-subtitle">Pengalaman bertahun-tahun melayani keluarga Indonesia, kini didukung teknologi modern untuk koordinasi yang lebih baik.</p>
    <div class="advantages-grid">
      <div class="advantage-item">
        <div class="advantage-icon">
          <svg viewBox="0 0 24 24" fill="none" stroke="var(--gold-soft)" stroke-width="1.5"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
        </div>
        <h4>Respons Cepat 24/7</h4>
        <p>Tim siaga kami siap melayani kapan saja. Alarm otomatis memastikan setiap pesanan langsung direspon oleh seluruh tim terkait secara simultan.</p>
      </div>
      <div class="advantage-item">
        <div class="advantage-icon">
          <svg viewBox="0 0 24 24" fill="none" stroke="var(--gold-soft)" stroke-width="1.5"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>
        </div>
        <h4>GPS Tracking Real-Time</h4>
        <p>Pantau posisi kendaraan dan tim lapangan langsung dari smartphone. Transparansi penuh untuk ketenangan pikiran keluarga.</p>
      </div>
      <div class="advantage-item">
        <div class="advantage-icon">
          <svg viewBox="0 0 24 24" fill="none" stroke="var(--gold-soft)" stroke-width="1.5"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>
        </div>
        <h4>Koordinasi Terpadu</h4>
        <p>Satu pesanan, satu pusat koordinasi. Semua pihak — driver, dekorasi, konsumsi, pemuka agama — bergerak bersamaan tanpa miskomunikasi.</p>
      </div>
      <div class="advantage-item">
        <div class="advantage-icon">
          <svg viewBox="0 0 24 24" fill="none" stroke="var(--gold-soft)" stroke-width="1.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><path d="M9 12l2 2 4-4"/></svg>
        </div>
        <h4>Terpercaya & Berpengalaman</h4>
        <p>Lebih dari 500 keluarga telah mempercayakan momen tersulit mereka kepada Santa Maria. Pengalaman panjang adalah jaminan kami.</p>
      </div>
      <div class="advantage-item">
        <div class="advantage-icon">
          <svg viewBox="0 0 24 24" fill="none" stroke="var(--gold-soft)" stroke-width="1.5"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>
        </div>
        <h4>Pembayaran Transparan</h4>
        <p>Rincian biaya tercatat jelas di sistem. Upload bukti pembayaran langsung dari aplikasi dengan verifikasi resmi dari tim keuangan.</p>
      </div>
      <div class="advantage-item">
        <div class="advantage-icon">
          <svg viewBox="0 0 24 24" fill="none" stroke="var(--gold-soft)" stroke-width="1.5"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>
        </div>
        <h4>Dokumentasi Lengkap</h4>
        <p>Seluruh bukti lapangan — foto dekorasi, kedatangan tim, dan layanan — terdokumentasi dan dapat diakses keluarga kapan saja.</p>
      </div>
    </div>
  </div>
</section>

<!-- Alur Layanan -->
<section id="alur">
  <div class="section-inner">
    <span class="section-label">Cara Kerja</span>
    <div class="gold-line"></div>
    <h2 class="section-title">Alur Layanan yang Mudah & Terkoordinasi</h2>
    <p class="section-subtitle">Dari kontak pertama hingga layanan selesai, seluruh proses ditangani secara profesional dan transparan.</p>
    <div class="process-steps">
      <div class="process-step">
        <div class="step-number">1</div>
        <div class="step-content">
          <h3>Hubungi Kami</h3>
          <p>Hubungi via WhatsApp, telepon (024-3560444), atau langsung melalui aplikasi. Service Officer kami siap menerima informasi kebutuhan Anda kapan saja.</p>
        </div>
      </div>
      <div class="process-step">
        <div class="step-number">2</div>
        <div class="step-content">
          <h3>Konsultasi & Pilih Paket</h3>
          <p>Service Officer membantu Anda memilih paket yang sesuai dengan kebutuhan dan budget. Semua detail — jadwal, lokasi, tambahan layanan — dikonfirmasi di satu tempat.</p>
        </div>
      </div>
      <div class="process-step">
        <div class="step-number">3</div>
        <div class="step-content">
          <h3>Seluruh Tim Bergerak Bersamaan</h3>
          <p>Setelah dikonfirmasi, seluruh tim otomatis menerima notifikasi — gudang menyiapkan perlengkapan, driver berangkat, dekorasi dan konsumsi dikoordinasikan secara simultan.</p>
        </div>
      </div>
      <div class="process-step">
        <div class="step-number">4</div>
        <div class="step-content">
          <h3>Pantau Progres Real-Time</h3>
          <p>Ikuti perkembangan layanan melalui aplikasi. Posisi kendaraan (GPS), status persiapan, dan konfirmasi setiap tahapan — semuanya transparan.</p>
        </div>
      </div>
      <div class="process-step">
        <div class="step-number">5</div>
        <div class="step-content">
          <h3>Layanan Selesai & Pembayaran</h3>
          <p>Setelah semua layanan tuntas, lakukan pembayaran via transfer atau tunai. Upload bukti langsung dari aplikasi untuk diverifikasi tim keuangan kami.</p>
        </div>
      </div>
    </div>
  </div>
</section>

<!-- Paket Layanan -->
<section id="paket">
  <div class="section-inner text-center">
    <span class="section-label">Paket Layanan</span>
    <div class="gold-line"></div>
    <h2 class="section-title">Pilihan Paket Sesuai Kebutuhan Keluarga</h2>
    <p class="section-subtitle">Setiap paket dapat disesuaikan dengan tambahan layanan (add-on). Konsultasikan dengan Service Officer untuk detail dan penyesuaian.</p>
    <div class="packages-grid">
      <div class="package-card">
        <div class="package-name">Paket Dasar</div>
        <p class="package-price">Layanan esensial pemakaman</p>
        <ul class="package-features">
          <li><svg class="check-icon" viewBox="0 0 20 20" fill="var(--steel-blue)"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"/></svg> Transportasi jenazah</li>
          <li><svg class="check-icon" viewBox="0 0 20 20" fill="var(--steel-blue)"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"/></svg> Perlengkapan dasar pemakaman</li>
          <li><svg class="check-icon" viewBox="0 0 20 20" fill="var(--steel-blue)"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"/></svg> Koordinasi pemuka agama</li>
          <li><svg class="check-icon" viewBox="0 0 20 20" fill="var(--steel-blue)"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"/></svg> Koordinasi pemakaman</li>
          <li><svg class="check-icon" viewBox="0 0 20 20" fill="var(--steel-blue)"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"/></svg> Monitoring via aplikasi</li>
        </ul>
        <a href="https://wa.me/6281128288286?text=Halo%20Santa%20Maria%2C%20saya%20ingin%20informasi%20Paket%20Dasar." class="btn-navy-outline">Konsultasi Paket Ini</a>
      </div>
      <div class="package-card featured">
        <div class="package-name">Paket Premium</div>
        <p class="package-price">Layanan lengkap & terkoordinasi</p>
        <ul class="package-features">
          <li><svg class="check-icon" viewBox="0 0 20 20" fill="var(--steel-blue)"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"/></svg> Semua layanan Paket Dasar</li>
          <li><svg class="check-icon" viewBox="0 0 20 20" fill="var(--steel-blue)"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"/></svg> Dekorasi ruang duka La Fiore</li>
          <li><svg class="check-icon" viewBox="0 0 20 20" fill="var(--steel-blue)"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"/></svg> Katering untuk pelayat</li>
          <li><svg class="check-icon" viewBox="0 0 20 20" fill="var(--steel-blue)"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"/></svg> Dokumentasi foto</li>
          <li><svg class="check-icon" viewBox="0 0 20 20" fill="var(--steel-blue)"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"/></svg> Bunga papan & karangan</li>
          <li><svg class="check-icon" viewBox="0 0 20 20" fill="var(--steel-blue)"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"/></svg> Tim koordinator lapangan</li>
        </ul>
        <a href="https://wa.me/6281128288286?text=Halo%20Santa%20Maria%2C%20saya%20ingin%20informasi%20Paket%20Premium." class="btn-navy">Konsultasi Paket Ini</a>
      </div>
      <div class="package-card">
        <div class="package-name">Paket Eksklusif</div>
        <p class="package-price">Layanan premium penuh perhatian</p>
        <ul class="package-features">
          <li><svg class="check-icon" viewBox="0 0 20 20" fill="var(--steel-blue)"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"/></svg> Semua layanan Paket Premium</li>
          <li><svg class="check-icon" viewBox="0 0 20 20" fill="var(--steel-blue)"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"/></svg> Dekorasi premium eksklusif</li>
          <li><svg class="check-icon" viewBox="0 0 20 20" fill="var(--steel-blue)"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"/></svg> Konsumsi premium multi-sesi</li>
          <li><svg class="check-icon" viewBox="0 0 20 20" fill="var(--steel-blue)"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"/></svg> Musisi / paduan suara</li>
          <li><svg class="check-icon" viewBox="0 0 20 20" fill="var(--steel-blue)"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"/></svg> Videografi upacara</li>
          <li><svg class="check-icon" viewBox="0 0 20 20" fill="var(--steel-blue)"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"/></svg> Koordinator pribadi keluarga</li>
        </ul>
        <a href="https://wa.me/6281128288286?text=Halo%20Santa%20Maria%2C%20saya%20ingin%20informasi%20Paket%20Eksklusif." class="btn-navy-outline">Konsultasi Paket Ini</a>
      </div>
    </div>
  </div>
</section>

<!-- Testimoni -->
<section id="testimoni">
  <div class="section-inner text-center">
    <span class="section-label">Testimoni</span>
    <div class="gold-line"></div>
    <h2 class="section-title">Dipercaya oleh Keluarga Indonesia</h2>
    <p class="section-subtitle">Kepercayaan keluarga adalah bukti nyata komitmen kami dalam memberikan layanan terbaik di saat-saat tersulit.</p>
    <div class="testimonials-grid">
      <div class="testimonial-card">
        <span class="quote-mark">&ldquo;</span>
        <div class="stars">&#9733; &#9733; &#9733; &#9733; &#9733;</div>
        <p>Di saat kami kebingungan mengurus segalanya, Santa Maria hadir dan menangani semuanya dengan sangat profesional. Dari transportasi hingga upacara, semuanya berjalan lancar.</p>
        <div class="testimonial-author">
          <div class="testimonial-avatar">
            <svg viewBox="0 0 44 44"><rect width="44" height="44" fill="var(--navy)"/><circle cx="22" cy="16" r="8" fill="rgba(255,255,255,0.3)"/><ellipse cx="22" cy="38" rx="14" ry="10" fill="rgba(255,255,255,0.3)"/></svg>
          </div>
          <div style="text-align:left">
            <div class="testimonial-name">Keluarga Bpk. Suharto</div>
            <div class="testimonial-role">Semarang Selatan</div>
          </div>
        </div>
      </div>
      <div class="testimonial-card">
        <span class="quote-mark">&ldquo;</span>
        <div class="stars">&#9733; &#9733; &#9733; &#9733; &#9733;</div>
        <p>Respon yang sangat cepat, bahkan di tengah malam. Tim koordinator penuh empati dan sabar mendampingi kami. Bisa memantau posisi mobil dari HP sangat menenangkan hati.</p>
        <div class="testimonial-author">
          <div class="testimonial-avatar">
            <svg viewBox="0 0 44 44"><rect width="44" height="44" fill="var(--steel-blue)"/><circle cx="22" cy="16" r="8" fill="rgba(255,255,255,0.3)"/><ellipse cx="22" cy="38" rx="14" ry="10" fill="rgba(255,255,255,0.3)"/></svg>
          </div>
          <div style="text-align:left">
            <div class="testimonial-name">Keluarga Ibu Maria L.</div>
            <div class="testimonial-role">Ungaran, Kab. Semarang</div>
          </div>
        </div>
      </div>
      <div class="testimonial-card">
        <span class="quote-mark">&ldquo;</span>
        <div class="stars">&#9733; &#9733; &#9733; &#9733; &#9733;</div>
        <p>Dekorasi dan rangkaian bunga yang sangat indah dan khidmat. Semua pelayat merasa tersentuh. Terima kasih Santa Maria atas pendampingan yang luar biasa.</p>
        <div class="testimonial-author">
          <div class="testimonial-avatar">
            <svg viewBox="0 0 44 44"><rect width="44" height="44" fill="var(--gold-muted)"/><circle cx="22" cy="16" r="8" fill="rgba(255,255,255,0.3)"/><ellipse cx="22" cy="38" rx="14" ry="10" fill="rgba(255,255,255,0.3)"/></svg>
          </div>
          <div style="text-align:left">
            <div class="testimonial-name">Keluarga Bpk. Wibowo</div>
            <div class="testimonial-role">Demak</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</section>

<!-- FAQ -->
<section id="faq">
  <div class="section-inner text-center">
    <span class="section-label">Pertanyaan Umum</span>
    <div class="gold-line"></div>
    <h2 class="section-title">Hal yang Sering Ditanyakan</h2>
    <p class="section-subtitle">Temukan jawaban atas pertanyaan umum tentang layanan Santa Maria Funeral Organizer.</p>
    <div class="faq-list" style="text-align:left;">
      <div class="faq-item">
        <button class="faq-question">Apakah layanan tersedia 24 jam? <span class="icon">+</span></button>
        <div class="faq-answer"><p>Ya, Santa Maria beroperasi 24/7 termasuk hari libur dan hari besar. Tim Service Officer kami siap menerima pesanan dan memberikan konsultasi kapan saja Anda membutuhkan. Hubungi kami di 024-3560444 atau WA 081.128.8286.</p></div>
      </div>
      <div class="faq-item">
        <button class="faq-question">Berapa lama waktu respons setelah menghubungi? <span class="icon">+</span></button>
        <div class="faq-answer"><p>Tim kami merespon dalam waktu kurang dari 30 menit. Setelah order dikonfirmasi, seluruh tim — gudang, driver, dekorasi, konsumsi, dan pemuka agama — langsung menerima notifikasi dan bergerak secara bersamaan.</p></div>
      </div>
      <div class="faq-item">
        <button class="faq-question">Apakah paket bisa disesuaikan? <span class="icon">+</span></button>
        <div class="faq-answer"><p>Tentu. Setiap paket dapat disesuaikan dengan menambah atau mengurangi layanan (add-on). Service Officer akan membantu menyesuaikan paket sesuai kebutuhan, tradisi, dan budget keluarga Anda.</p></div>
      </div>
      <div class="faq-item">
        <button class="faq-question">Bagaimana cara memantau status layanan? <span class="icon">+</span></button>
        <div class="faq-answer"><p>Anda dapat memantau seluruh progres melalui aplikasi Santa Maria. Dari posisi kendaraan (GPS tracking), status persiapan gudang, hingga konfirmasi kehadiran pemuka agama — semuanya real-time dan transparan.</p></div>
      </div>
      <div class="faq-item">
        <button class="faq-question">Apakah melayani semua agama? <span class="icon">+</span></button>
        <div class="faq-answer"><p>Ya, Santa Maria melayani pemakaman untuk semua agama dan kepercayaan. Kami berkoordinasi langsung dengan pemuka agama sesuai keyakinan almarhum untuk memastikan upacara berjalan sesuai tradisi yang dihormati.</p></div>
      </div>
      <div class="faq-item">
        <button class="faq-question">Metode pembayaran apa saja yang diterima? <span class="icon">+</span></button>
        <div class="faq-answer"><p>Kami menerima pembayaran via transfer bank dan tunai. Bukti pembayaran dapat diunggah langsung melalui aplikasi Santa Maria, dan akan diverifikasi oleh tim keuangan kami secara transparan.</p></div>
      </div>
    </div>
  </div>
</section>

<!-- Berita Duka (Dynamic from API) -->
<section id="berita-duka">
  <div class="section-inner text-center">
    <span class="section-label">Berita Duka</span>
    <div class="gold-line"></div>
    <h2 class="section-title">Mengenang yang Telah Berpulang</h2>
    <p class="section-subtitle">Kiriman doa dan penghormatan terakhir untuk almarhum/almarhumah yang telah mendahului kita.</p>
    <div id="obituaries-grid" class="obituaries-grid">
      <div class="obituaries-loading">Memuat berita duka...</div>
    </div>
    <div id="obituaries-empty" class="obituaries-empty" style="display:none;">
      <p>Belum ada berita duka yang dipublikasikan.</p>
    </div>
    <a href="#" id="obituaries-more" class="btn-navy-outline" style="display:none;margin-top:32px;">Lihat Semua Berita Duka</a>
  </div>
</section>

<!-- Blog / Artikel (Dynamic from API) -->
<section id="blog" style="background:var(--cream);">
  <div class="section-inner text-center">
    <span class="section-label">Artikel & Informasi</span>
    <div class="gold-line"></div>
    <h2 class="section-title">Panduan & Pengetahuan Pemakaman</h2>
    <p class="section-subtitle">Artikel informatif seputar layanan pemakaman, tradisi, dan panduan bagi keluarga yang berduka.</p>
    <div id="articles-grid" class="articles-grid">
      <div class="articles-loading">Memuat artikel...</div>
    </div>
    <div id="articles-empty" class="articles-empty" style="display:none;">
      <p>Belum ada artikel yang dipublikasikan.</p>
    </div>
    <a href="#" id="articles-more" class="btn-navy-outline" style="display:none;margin-top:32px;">Lihat Semua Artikel</a>
  </div>
</section>

<!-- CTA -->
<section class="cta-section" id="kontak">
  <div class="section-inner">
    <span class="section-label" style="color:var(--gold-soft);">Hubungi Kami</span>
    <div class="gold-line" style="margin:0 auto 20px;"></div>
    <h2>Kami Siap Mendampingi Anda</h2>
    <p>Di saat tersulit, Anda tidak perlu mengurus segalanya sendiri. Hubungi Santa Maria — kami akan meringankan beban Anda dengan penuh hormat.</p>
    <div class="cta-phones">
      <div class="cta-phone">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07 19.5 19.5 0 01-6-6 19.79 19.79 0 01-3.07-8.67A2 2 0 014.11 2h3a2 2 0 012 1.72c.127.96.361 1.903.7 2.81a2 2 0 01-.45 2.11L8.09 9.91a16 16 0 006 6l1.27-1.27a2 2 0 012.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0122 16.92z"/></svg>
        <a href="tel:0243560444" style="color:rgba(255,255,255,0.9);text-decoration:none;">024-3560444</a>
      </div>
      <div class="cta-phone">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07 19.5 19.5 0 01-6-6 19.79 19.79 0 01-3.07-8.67A2 2 0 014.11 2h3a2 2 0 012 1.72c.127.96.361 1.903.7 2.81a2 2 0 01-.45 2.11L8.09 9.91a16 16 0 006 6l1.27-1.27a2 2 0 012.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0122 16.92z"/></svg>
        <a href="https://wa.me/6281128288286" style="color:rgba(255,255,255,0.9);text-decoration:none;">081.128.8286 (WhatsApp)</a>
      </div>
    </div>
    <a href="https://wa.me/6281128288286?text=Halo%20Santa%20Maria%2C%20saya%20ingin%20konsultasi%20layanan%20pemakaman." class="btn-gold" style="font-size:0.95rem;padding:16px 40px;">
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 11.5a8.38 8.38 0 01-.9 3.8 8.5 8.5 0 01-7.6 4.7 8.38 8.38 0 01-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 01-.9-3.8 8.5 8.5 0 014.7-7.6 8.38 8.38 0 013.8-.9h.5a8.48 8.48 0 018 8v.5z"/></svg>
          Chat via WhatsApp
        </a>
  </div>
</section>

<!-- Footer -->
<footer>
  <div class="footer-inner">
    <div class="footer-brand">
      <div class="logo-row">
        <img src="frontend/assets/images/logo.png" alt="Santa Maria">
      </div>
      <p>Funeral Organizer profesional yang menangani seluruh koordinasi pemakaman secara terpadu. Dipercaya oleh ratusan keluarga di Semarang dan sekitarnya.</p>
      <p class="footer-address" style="margin-top:16px;">
        Jl. Citarum Tengah E-1<br>
        Semarang 50126<br>
        Jawa Tengah, Indonesia
      </p>
    </div>
    <div class="footer-col">
      <h4>Layanan</h4>
      <ul>
        <li><a href="#layanan">Transportasi Jenazah</a></li>
        <li><a href="#layanan">Dekorasi & Bunga</a></li>
        <li><a href="#layanan">Konsumsi & Katering</a></li>
        <li><a href="#layanan">Pemuka Agama</a></li>
        <li><a href="#layanan">Perlengkapan</a></li>
      </ul>
    </div>
    <div class="footer-col">
      <h4>Informasi</h4>
      <ul>
        <li><a href="#keunggulan">Tentang Kami</a></li>
        <li><a href="#alur">Alur Layanan</a></li>
        <li><a href="#paket">Paket Layanan</a></li>
        <li><a href="#faq">FAQ</a></li>
        <li><a href="#testimoni">Testimoni</a></li>
      </ul>
    </div>
    <div class="footer-col">
      <h4>Hubungi</h4>
      <ul>
        <li><a href="tel:0243560444">024-3560444</a></li>
        <li><a href="https://wa.me/6281128288286">081.128.8286</a></li>
        <li><a href="mailto:info@santamaria.co.id">info@santamaria.co.id</a></li>
      </ul>
    </div>
  </div>
  <div class="footer-bottom">
    <span>&copy; 2026 Santa Maria Funeral Organizer. Semarang, Jawa Tengah.</span>
  </div>
</footer>

<!-- WhatsApp Float Button -->
<a href="https://wa.me/6281128288286?text=Halo%20Santa%20Maria%2C%20saya%20ingin%20konsultasi%20layanan%20pemakaman." class="wa-float" target="_blank" rel="noopener" aria-label="Chat WhatsApp">
  <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/></svg>
</a>

<script>
  // Navbar scroll effect
  window.addEventListener('scroll', () => {
    document.getElementById('navbar').classList.toggle('scrolled', window.scrollY > 20);
  });

  // Mobile menu toggle
  document.getElementById('mobileToggle').addEventListener('click', () => {
    document.getElementById('navLinks').classList.toggle('active');
  });

  // FAQ accordion
  document.querySelectorAll('.faq-question').forEach(btn => {
    btn.addEventListener('click', () => {
      const item = btn.parentElement;
      document.querySelectorAll('.faq-item').forEach(i => { if (i !== item) i.classList.remove('open'); });
      item.classList.toggle('open');
    });
  });

  // Close mobile menu on link click
  document.querySelectorAll('.nav-links a').forEach(a => {
    a.addEventListener('click', () => document.getElementById('navLinks').classList.remove('active'));
  });

  // ── API Configuration ──────────────────────────────────────────────
  const API_BASE = window.location.origin + '/api/v1/public';

  // ── Fetch & Render Obituaries (Berita Duka) ────────────────────────
  async function loadObituaries() {
    const grid = document.getElementById('obituaries-grid');
    const empty = document.getElementById('obituaries-empty');
    const more = document.getElementById('obituaries-more');

    try {
      const res = await fetch(`${API_BASE}/obituaries?per_page=6`);
      const json = await res.json();

      if (!json.success || !json.data.data || json.data.data.length === 0) {
        grid.innerHTML = '';
        empty.style.display = 'block';
        return;
      }

      const obituaries = json.data.data;
      grid.innerHTML = obituaries.map(obit => {
        const dod = new Date(obit.deceased_dod).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' });
        const age = obit.deceased_age ? ` (${obit.deceased_age} tahun)` : '';
        const photoHtml = obit.deceased_photo_url
          ? `<img class="obituary-photo" src="${obit.deceased_photo_url}" alt="${obit.deceased_name}" loading="lazy">`
          : `<div class="obituary-photo-placeholder"><svg viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="1"><circle cx="12" cy="8" r="5"/><path d="M20 21a8 8 0 10-16 0"/></svg></div>`;
        const locationHtml = obit.funeral_location
          ? `<div class="obituary-location"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>${obit.funeral_location}</div>`
          : '';
        const messageHtml = obit.family_message
          ? `<p class="obituary-message">"${obit.family_message.substring(0, 100)}${obit.family_message.length > 100 ? '...' : ''}"</p>`
          : '';

        return `
          <div class="obituary-card">
            <a href="#berita-duka/${obit.slug}">
              ${photoHtml}
              <div class="obituary-body">
                <div class="obituary-cross">&#10013; Turut Berduka Cita</div>
                <div class="obituary-name">${obit.deceased_name}</div>
                <div class="obituary-dates">${dod}${age}</div>
                ${locationHtml}
                ${messageHtml}
              </div>
            </a>
          </div>`;
      }).join('');

      if (json.data.last_page > 1) {
        more.style.display = 'inline-block';
        more.style.width = 'auto';
      }
    } catch (e) {
      grid.innerHTML = '';
      empty.style.display = 'block';
      console.warn('Obituaries API not available:', e.message);
    }
  }

  // ── Fetch & Render Articles (Blog) ─────────────────────────────────
  async function loadArticles() {
    const grid = document.getElementById('articles-grid');
    const empty = document.getElementById('articles-empty');
    const more = document.getElementById('articles-more');

    try {
      const res = await fetch(`${API_BASE}/articles?per_page=6`);
      const json = await res.json();

      if (!json.success || !json.data.data || json.data.data.length === 0) {
        grid.innerHTML = '';
        empty.style.display = 'block';
        return;
      }

      const articles = json.data.data;
      grid.innerHTML = articles.map(art => {
        const date = new Date(art.published_at).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' });
        const coverHtml = art.cover_image_url
          ? `<img class="article-cover" src="${art.cover_image_url}" alt="${art.title}" loading="lazy">`
          : `<div class="article-cover-placeholder"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/></svg></div>`;
        const authorName = art.author ? art.author.name : 'Santa Maria';
        const excerpt = art.excerpt ? art.excerpt.substring(0, 120) + (art.excerpt.length > 120 ? '...' : '') : '';

        return `
          <div class="article-card">
            <a href="#blog/${art.slug}">
              ${coverHtml}
              <div class="article-body">
                <span class="article-category">${art.category || 'Umum'}</span>
                <h3 class="article-title">${art.title}</h3>
                <p class="article-excerpt">${excerpt}</p>
                <div class="article-meta">
                  <span>${authorName}</span>
                  <span>${date}</span>
                </div>
              </div>
            </a>
          </div>`;
      }).join('');

      if (json.data.last_page > 1) {
        more.style.display = 'inline-block';
        more.style.width = 'auto';
      }
    } catch (e) {
      grid.innerHTML = '';
      empty.style.display = 'block';
      console.warn('Articles API not available:', e.message);
    }
  }

  // Load dynamic content on page load
  document.addEventListener('DOMContentLoaded', () => {
    loadObituaries();
    loadArticles();
  });
</script>
</body>
</html>
