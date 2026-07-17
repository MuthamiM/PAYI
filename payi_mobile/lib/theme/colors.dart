import 'package:flutter/material.dart';

class AppColors {
  // ── Primary Brand Colors ──
  static const Color primaryTeal = Color(0xFF00C9A7);
  static const Color primaryTealLight = Color(0xFF33D4B9);
  static const Color primaryTealDark = Color(0xFF009B82);

  // ── Secondary Accents ──
  static const Color accentGold = Color(0xFFFFD700);
  static const Color accentViolet = Color(0xFF8B5CF6);
  static const Color accentCoral = Color(0xFFFF6B6B);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentCyan = Color(0xFF06B6D4);

  // ── Backgrounds (Dark) ──
  static const Color backgroundDark = Color(0xFF0B0E14);
  static const Color backgroundDarkAlt = Color(0xFF0F1318);
  static const Color cardDark = Color(0xFF151A23);
  static const Color cardDarker = Color(0xFF0D1117);
  static const Color surfaceGrey = Color(0xFF1E2631);
  static const Color surfaceGreyLight = Color(0xFF252D3A);

  // ── Backgrounds (Light) ──
  static const Color backgroundLight = Color(0xFFF5F6FA);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF1F5F9);
  static const Color surfaceLightBorder = Color(0xFFE2E8F0);

  // ── Text Colors ──
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textDarkMuted = Color(0xFF64748B);

  // ── Status Colors ──
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFCA5A5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color info = Color(0xFF3B82F6);

  // ── Glassmorphism ──
  static const Color glassDark = Color(0x33FFFFFF);     // 20% white
  static const Color glassDarkBorder = Color(0x1AFFFFFF); // 10% white
  static const Color glassLight = Color(0x80FFFFFF);     // 50% white
  static const Color glassLightBorder = Color(0x33FFFFFF);

  // ── Border Colors ──
  static const Color borderDark = Color(0xFF2C3544);
  static const Color borderLight = Color(0xFFE2E8F0);

  // ── Gradient Definitions ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00C9A7), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4), Color(0xFF00C9A7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0B0E14), Color(0xFF151A23)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sendGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient receiveGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    colors: [Color(0xFF1A1F2E), Color(0xFF151A23)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroCardLightGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
