import 'package:flutter/material.dart';

/// Central color palette for TailorTrack. Keep all raw color values here so
/// the rest of the app never hardcodes a hex value.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0F8A5F);
  static const Color primaryDark = Color(0xFF0B6B49);
  static const Color primaryLight = Color(0xFFE6F4EE);

  static const Color background = Color(0xFFF8F9FB);
  static const Color backgroundDark = Color(0xFF111417);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1B1F23);

  static const Color textPrimary = Color(0xFF12181A);
  static const Color textSecondary = Color(0xFF6B7680);
  static const Color textPrimaryDark = Color(0xFFF2F4F5);
  static const Color textSecondaryDark = Color(0xFF9AA4AC);

  static const Color border = Color(0xFFE9ECEF);
  static const Color borderDark = Color(0xFF2A2F34);

  // Status colors
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusStitching = Color(0xFF8B5CF6);
  static const Color statusReady = Color(0xFF22C55E);
  static const Color statusDelivered = Color(0xFF3B82F6);
  static const Color statusOverdue = Color(0xFFEF4444);

  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return statusPending;
      case 'stitching':
        return statusStitching;
      case 'ready':
        return statusReady;
      case 'delivered':
        return statusDelivered;
      case 'overdue':
        return statusOverdue;
      default:
        return statusPending;
    }
  }
}
