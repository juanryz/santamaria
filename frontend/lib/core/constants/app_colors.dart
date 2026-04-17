import 'package:flutter/material.dart';

// Palet warna dari logo Santa Maria Funeral Organizer:
//   Navy    : #1F3D7A  (teks "SANTA MARIA", garis, teks alamat)
//   Blue    : #7BADD4  (latar ikon, elemen sekunder)

class AppColors {
  // ── Background ──────────────────────────────────────────
  static const Color background     = Color(0xFFFFFFFF); // putih murni
  static const Color backgroundSoft = Color(0xFFF0F4FA); // putih hint biru logo
  static const Color surfaceWhite   = Color(0xFFFFFFFF);

  // ── Brand Utama Santa Maria (dari Logo) ─────────────────
  static const Color brandPrimary   = Color(0xFF1F3D7A); // navy logo — utama
  static const Color brandSecondary = Color(0xFF7BADD4); // biru muda logo — sekunder
  static const Color brandAccent    = Color(0xFF4A6FA5); // biru tengah — aksen

  // ── Warna per Role (Turunan Palet Logo Navy + Blue) ─────
  static const Color roleConsumer   = Color(0xFF7BADD4); // biru muda logo
  static const Color roleSO         = Color(0xFF1F3D7A); // navy logo
  static const Color roleAdmin      = Color(0xFF4A6FA5); // biru medium
  static const Color roleGudang     = Color(0xFF2B5FA0); // biru tua sedang
  static const Color roleFinance    = Color(0xFF5B8CC8); // biru cerah
  static const Color roleDriver     = Color(0xFF162C5A); // navy gelap
  static const Color roleSupplier   = Color(0xFFA8C8E8); // biru pastel muda
  static const Color roleDekor      = Color(0xFF3B6EAD); // biru medium-terang
  static const Color roleKonsumsi   = Color(0xFF6B9EC8); // biru lembut
  static const Color roleOwner      = Color(0xFF1F3D7A); // navy logo (eksekutif)
  static const Color roleTukangAngkatPeti = Color(0xFF3A5E8C); // biru sedang — Koordinator Angkat Peti
  static const Color roleSuperAdmin = Color(0xFF0D2347); // navy paling gelap
  static const Color roleHrd        = Color(0xFF2E4A82); // navy medium — HRD
  static const Color rolePurchasing = Color(0xFF3D6DAE); // biru tua cerah — Purchasing
  static const Color roleTukangFoto = Color(0xFF5584B8); // biru medium — Tukang Foto
  static const Color roleViewer     = Color(0xFFB0C4D8); // biru abu — Viewer (read-only)
  static const Color roleSecurity   = Color(0xFF636E72); // abu — Security
  static const Color rolePemukaAgama = Color(0xFF4A6FA5); // biru medium — Pemuka Agama

  // ── Status Colors ────────────────────────────────────────
  static const Color statusSuccess  = Color(0xFF27AE60); // hijau netral
  static const Color statusWarning  = Color(0xFFF39C12); // kuning oranye
  static const Color statusDanger   = Color(0xFFE74C3C); // merah
  static const Color statusInfo     = Color(0xFF7BADD4); // biru muda logo
  static const Color statusPending  = Color(0xFFB0C4D8); // biru abu muda

  // ── Liquid Glass ─────────────────────────────────────────
  static const Color glassPrimary   = Color(0x1A1F3D7A); // navy 10%
  static const Color glassWhite     = Color(0xB3FFFFFF); // putih 70%
  static const Color glassWhiteSoft = Color(0x80FFFFFF); // putih 50%
  static const Color glassBorder    = Color(0x337BADD4); // biru logo 20%
  static const Color glassShadow    = Color(0x1A1F3D7A); // shadow navy tipis

  // ── Text ─────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFF1F3D7A); // navy logo
  static const Color textSecondary  = Color(0xFF4A6FA5); // biru medium
  static const Color textHint       = Color(0xFFB0C4D8); // biru abu
  static const Color textOnColor    = Color(0xFFFFFFFF); // teks di atas warna solid
  static const Color textOnGlass    = Color(0xFF1F3D7A); // teks di atas glass

  // Helper: warna aksen berdasarkan nama role
  static Color roleColor(String role) => switch (role) {
    'consumer'        => roleConsumer,
    'service_officer' => roleSO,
    'admin'           => roleAdmin,
    'gudang'          => roleGudang,
    'finance'         => roleFinance,
    'purchasing'      => rolePurchasing,
    'driver'          => roleDriver,
    'supplier'        => roleSupplier,
    'dekor'           => roleDekor,
    'konsumsi'        => roleKonsumsi,
    'owner'           => roleOwner,
    'tukang_angkat_peti' => roleTukangAngkatPeti,
    'super_admin'     => roleSuperAdmin,
    'pemuka_agama'    => rolePemukaAgama,
    'hrd'             => roleHrd,
    'tukang_foto'     => roleTukangFoto,
    'viewer'          => roleViewer,
    'security'        => roleSecurity,
    _                 => brandPrimary,
  };
}
