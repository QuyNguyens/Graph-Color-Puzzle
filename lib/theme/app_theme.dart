import 'package:flutter/material.dart';

/// Bảng mã màu chuẩn của giao diện Midnight Slate / Deep Navy.
/// Trích xuất trực tiếp từ màn chơi Gameplay đã được phê duyệt.
class AppColors {
  const AppColors._();

  // Nền (Backgrounds)
  static const Color backgroundPrimary = Color(0xFF0F172A); // Slate 900
  static const Color backgroundSecondary = Color(0xFF131D33); // Deep Midnight Blue
  static const Color backgroundTertiary = Color(0xFF0B1120); // Obsidian Slate 950

  // Bề mặt (Surfaces & Cards)
  static const Color surface = Color(0xFF1E293B); // Slate 800 - Card chuẩn
  static const Color surfaceElevated = Color(0xFF334155); // Slate 700 - Chip / Nổi
  static const Color surfaceDark = Color(0xFF0F172A); // Slate 900 - Nền input / panel con
  static final Color surfaceTranslucent = const Color(0xFF1E293B).withValues(alpha: 0.75);

  // Đường viền (Borders)
  static const Color border = Color(0xFF334155); // Slate 700
  static final Color borderHairline = Colors.white.withValues(alpha: 0.08);
  static final Color borderSubtle = Colors.white.withValues(alpha: 0.14);
  static const Color borderFocus = Color(0xFF38BDF8); // Sky 400

  // Chữ & Biểu tượng (Typography & Icons)
  static const Color textPrimary = Color(0xFFF8FAFC); // Slate 50 - Trắng sáng
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400 - Xám xanh
  static const Color textMuted = Color(0xFF64748B); // Slate 500 - Chú thích mờ

  // Điểm nhấn & Chức năng (Accents & Semantics)
  static const Color accent = Color(0xFF38BDF8); // Sky 400 - Điểm nhấn chính
  static const Color accentDark = Color(0xFF0284C7); // Sky 600

  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color successText = Color(0xFF4ADE80); // Emerald 400
  static const Color successSurface = Color(0xFF064E3B); // Emerald 900

  static const Color warning = Color(0xFFFBBF24); // Amber 400
  static const Color warningText = Color(0xFFFDE68A); // Amber 200
  static const Color warningSurface = Color(0xFF78350F); // Amber 900

  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color errorText = Color(0xFFFCA5A5); // Red 300
  static const Color errorSurface = Color(0xFF7F1D1D); // Red 900

  static const Color energy = Color(0xFFA855F7); // Purple 500
  static const Color energySurface = Color(0xFF3B0764); // Purple 950

  static const Color locked = Color(0xFF475569); // Slate 600
  static final Color lockedSurface = const Color(0xFF131D33).withValues(alpha: 0.5);

  // Bàn cờ đồ thị (Gameplay Board - Ball Lab Puzzle Reference)
  static const Color boardSurface = Color(0xFF152238); // Subtle deep navy
  static const Color nodeUncolored = Color(0xFF111827); // Dark navy/slate interior
  static const Color nodeBorder = Color(0xFF00C995); // Emerald green outline
  static const Color nodeText = Color(0xFFE5EDF5); // Soft white/off-white text
  static const Color nodeSelected = Color(0xFF00E5AA); // Brighter emerald/cyan selection
  static const Color graphEdge = Color(0xFF52657D); // Muted blue-gray edge
  static const Color graphEdgeHighlight = Color(0xFF758CA8); // Restrained edge highlight
}

/// Hệ thống Theme tập trung cho toàn bộ ứng dụng Graph Coloring.
class AppTheme {
  const AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundPrimary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accentDark,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Colors.white70),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: AppColors.borderSubtle,
            width: 1.2,
          ),
        ),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(
          color: Color(0xFFCBD5E1),
          fontSize: 14,
          height: 1.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColors.borderHairline),
        ),
      ),
    );
  }
}
