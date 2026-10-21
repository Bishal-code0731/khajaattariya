import 'package:flutter/material.dart';

/// Raw brand colours.
class AppColors {
  AppColors._();

  // Brand
  static const Color pine = Color(0xFF0B6E4F);
  static const Color pineDeep = Color(0xFF07513A);
  static const Color pineBright =
      Color(0xFF3DD39B); // brand on dark backgrounds
  static const Color marigold = Color(0xFFF5A524);
  static const Color marigoldDeep = Color(0xFFB86E00);

  // Light neutrals
  static const Color lightBackground = Color(0xFFF7F6F3);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF1EFEB);
  static const Color lightBorder = Color(0xFFE4E1DB);
  static const Color lightTextPrimary = Color(0xFF14171A);
  static const Color lightTextSecondary = Color(0xFF555C66);
  static const Color lightTextHint = Color(0xFF858B94);

  // Dark neutrals
  static const Color darkBackground = Color(0xFF0C110F);
  static const Color darkSurface = Color(0xFF151C19);
  static const Color darkSurfaceAlt = Color(0xFF1E2723);
  static const Color darkBorder = Color(0xFF2C3632);
  static const Color darkTextPrimary = Color(0xFFF1F4F2);
  static const Color darkTextSecondary = Color(0xFFAAB4AF);
  static const Color darkTextHint = Color(0xFF7D8884);

  // Meaning (light / dark)
  static const Color success = Color(0xFF15803D);
  static const Color successOnDark = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFB45309);
  static const Color warningOnDark = Color(0xFFFBBF24);
  static const Color error = Color(0xFFDC2626);
  static const Color errorOnDark = Color(0xFFF87171);
  static const Color info = Color(0xFF1D4ED8);
  static const Color infoOnDark = Color(0xFF60A5FA);

  // Order status (single source — badges, timelines, charts)
  static const Color statusPending = Color(0xFFD97706);
  static const Color statusConfirmed = Color(0xFF2563EB);
  static const Color statusPreparing = Color(0xFF7C3AED);
  static const Color statusReady = Color(0xFF0891B2);
  static const Color statusDelivering = Color(0xFFEA580C);
  static const Color statusDelivered = Color(0xFF16A34A);
  static const Color statusCancelled = Color(0xFF6B7280);

  // Payment brands
  static const Color khaltiPurple = Color(0xFF5C2D91);
  static const Color esewaGreen = Color(0xFF60BB46);

  // Roles
  static const Color customerColor = pine;
  static const Color restaurantColor = Color(0xFF7C3AED);
  static const Color riderColor = Color(0xFFEA580C);
  static const Color adminColor = Color(0xFF334155);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);
  static const Color scrim = Color(0x99000000);

  // Legacy names (old screens).
  static const Color primary = pine;
  static const Color primaryLight = Color(0xFF168A64);
  static const Color primaryDark = pineDeep;
  static const Color accent = marigold;
  static const Color accentLight = Color(0xFFFEF0D6);
  static const Color background = lightBackground;
  static const Color surface = lightSurface;
  static const Color textPrimary = lightTextPrimary;
  static const Color textSecondary = lightTextSecondary;
  static const Color textHint = lightTextHint;
  static const Color border = lightBorder;
  static const Color divider = lightBorder;
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color overlay30 = Color(0x4D000000);
  static const Color overlay60 = scrim;
  static const Color glassLight = lightSurface;
  static const Color glassDark = darkSurface;
  static const Color glassBorderLight = lightBorder;
  static const Color glassBorderDark = darkBorder;
  static const Color darkDivider = darkBorder;
}
