import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/entities/puzzle_color.dart';

/// Extension cung cấp nhãn và ký tự viết tắt chuẩn hóa theo đa ngôn ngữ (Localization) cho PuzzleColor.
extension LocalizedPuzzleColor on PuzzleColor {
  /// Ký tự viết tắt đại diện cho màu sắc theo ngôn ngữ người dùng:
  /// - Tiếng Anh: Red -> 'R', Blue -> 'B', Yellow -> 'Y', Green -> 'G', Purple -> 'P'.
  /// - Tiếng Việt: Đỏ -> 'Đ', Xanh dương -> 'X', Vàng -> 'V', Xanh lá -> 'L', Tím -> 'T'.
  String getLocalizedSymbol(AppLocalizations l10n) {
    switch (code) {
      case 'RED':
        return l10n.colorSymbolRed;
      case 'BLUE':
        return l10n.colorSymbolBlue;
      case 'YELLOW':
        return l10n.colorSymbolYellow;
      case 'GREEN':
        return l10n.colorSymbolGreen;
      case 'PURPLE':
        return l10n.colorSymbolPurple;
      default:
        return code.isNotEmpty ? code.substring(0, 1).toUpperCase() : '?';
    }
  }

  /// Tên đầy đủ của màu sắc đã được bản địa hóa.
  String getLocalizedName(AppLocalizations l10n) {
    switch (code) {
      case 'RED':
        return l10n.colorRed;
      case 'BLUE':
        return l10n.colorBlue;
      case 'YELLOW':
        return l10n.colorYellow;
      case 'GREEN':
        return l10n.colorGreen;
      case 'PURPLE':
        return l10n.colorPurple;
      default:
        return label;
    }
  }
}

/// Bảng màu hiển thị UI tương ứng với các mã màu logic trong Domain.
class PuzzleColorPalette {
  const PuzzleColorPalette._();

  // 5 màu logic cốt lõi của bài toán Graph Coloring (bảo toàn nguyên vẹn 100%)
  static const Color red = Color(0xFFE53935);
  static const Color blue = Color(0xFF1E88E5);
  static const Color yellow = Color(0xFFFBC02D);
  static const Color green = Color(0xFF43A047);
  static const Color purple = Color(0xFF8E24AA);

  // Đỉnh chưa tô: Dark navy interior (#111827), Emerald border (#00C995), Soft white text (#E5EDF5)
  static const Color emptyNode = AppColors.nodeUncolored; // #111827 Dark navy/slate
  static const Color emptyNodeBorder = AppColors.nodeBorder; // #00C995 Emerald outline
  static const Color emptyNodeText = AppColors.nodeText; // #E5EDF5 Soft white/off-white
  static const Color lockedBadge = Color(0xFF37474F);

  static Color getColor(PuzzleColor? color) {
    if (color == null) return emptyNode;
    switch (color.code) {
      case 'RED':
        return red;
      case 'BLUE':
        return blue;
      case 'YELLOW':
        return yellow;
      case 'GREEN':
        return green;
      case 'PURPLE':
        return purple;
      default:
        return Colors.grey;
    }
  }

  /// Trả về màu chữ tương phản phù hợp trên nền màu đã tô hoặc chưa tô.
  static Color getContrastTextColor(PuzzleColor? color) {
    if (color == null) return emptyNodeText;
    switch (color.code) {
      case 'YELLOW':
        return Colors.black87;
      default:
        return Colors.white;
    }
  }
}
