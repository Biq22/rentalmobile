import 'dart:ui';

class ApiConfig {
  // Backend PHP API (XAMPP). Ganti localhost dengan IP LAN bila diakses dari HP.
  static const String baseUrl = 'http://localhost/rentalmobile-api';
  static const String uploadsUrl = 'http://localhost/uploads';
}

/// Warna brand + status
class AppColors {
  static const brand = Color(0xFF0B6BCB);
  static const brandDark = Color(0xFF084A8F);
  static const brandLight = Color(0xFFE8F2FC);
  static const accent = Color(0xFFF59E0B);
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const line = Color(0xFFEAECF0);
  static const surface = Color(0xFFF6F8FB);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFDC2626);
  static const info = Color(0xFF0284C7);
}
