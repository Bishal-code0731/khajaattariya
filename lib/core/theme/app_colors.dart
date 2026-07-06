import 'package:flutter/material.dart';

// Every color used in Khaja Attariya lives here.
// Never write Color(0xFF...) anywhere else in the app.
// Always use AppColors.something instead.
//
// Each color has exactly one meaning. Decorative, semantic, and
// order-status colors are kept visually distinct on purpose so two
// unrelated concepts never render pixel-identical by accident.

class AppColors {
  // ── Primary Brand Colors ───────────────────────────────
  // The warm deep red is Khaja Attariya's identity.
  // Seen on buttons, icons, active states, the app bar.
  static const Color primary      = Color(0xFFC0392B); // Warm deep red
  static const Color primaryLight = Color(0xFFE74C3C); // Lighter red — hover states
  static const Color primaryDark  = Color(0xFF922B21); // Darker red — pressed states

  // ── Accent Color ──────────────────────────────────────
  // Warm gold — used sparingly for highlights, badges,
  // special tags, promotional banners. Decorative only,
  // never used to convey success/warning/error meaning.
  static const Color accent       = Color(0xFFE8A33D);
  static const Color accentLight  = Color(0xFFF6DDB0); // Lighter gold for backgrounds

  // ── Background Colors ─────────────────────────────────
  // Warm white backgrounds — not cold bright white.
  // Makes the app feel like home, not a hospital.
  static const Color background   = Color(0xFFFFFDF9); // Main screen background
  static const Color surface      = Color(0xFFFFF8F5); // Cards, bottom sheets, dialogs

  // ── Text Colors (light mode) ───────────────────────────
  // Three levels of text — primary, secondary, hint.
  // Use the right level for the right context:
  // primary → headings, important info
  // secondary → descriptions, subtitles
  // hint → placeholder text, disabled labels
  static const Color textPrimary   = Color(0xFF2C2C2A); // Near black — main text
  static const Color textSecondary = Color(0xFF6D6D6A); // Warm grey — subtitles
  static const Color textHint      = Color(0xFFA8A8A5); // Light grey — placeholders

  // ── Border & Divider Colors (light mode) ──────────────
  static const Color border   = Color(0xFFE8E4E0); // Soft grey borders
  static const Color divider  = Color(0xFFF0EDE9); // Even softer for dividers

  // ── Semantic Colors ───────────────────────────────────
  // These communicate meaning — not decoration.
  // Always use these for their intended purpose:
  // success → order confirmed, payment done, delivered
  // error   → failed payment, wrong password, network error
  // warning → restaurant closing soon, item running low, action pending
  // info    → general tips, neutral information
  // Deliberately distinct from `primaryLight` and `accent` so a hover
  // state and an error banner never look identical.
  static const Color success = Color(0xFF27AE60);
  static const Color successLight = Color(0xFFD5F5E3); // Light green background
  static const Color error   = Color(0xFFE0333F);
  static const Color errorLight = Color(0xFFFDEDEB);   // Light red background
  static const Color warning = Color(0xFFDC8A1E);
  static const Color warningLight = Color(0xFFFEF3E0); // Light amber background
  static const Color info    = Color(0xFF2980B9);
  static const Color infoLight = Color(0xFFEBF5FB);    // Light blue background

  // ── Order Status Colors ───────────────────────────────
  // Every order goes through these stages.
  // Each stage has its own color so users understand
  // the status instantly without reading the text.
  // `statusPending` intentionally reuses `warning` — pending really
  // does mean "needs attention," so this is deliberate reuse, not a
  // naming collision.
  static const Color statusPending    = warning;            // Amber   — waiting for restaurant
  static const Color statusConfirmed  = Color(0xFF2980B9);  // Blue    — restaurant accepted
  static const Color statusPreparing  = Color(0xFF8E44AD);  // Purple  — being cooked
  static const Color statusReady      = Color(0xFF27AE60);  // Green   — ready for pickup
  static const Color statusDelivering = Color(0xFFC0392B);  // Red     — rider on the way
  static const Color statusDelivered  = Color(0xFF1E8449);  // Dark green — completed
  static const Color statusCancelled  = Color(0xFF7F8C8D);  // Grey    — cancelled

  // ── Payment Brand Colors ──────────────────────────────
  // Third-party payment providers' own brand colors, used only on
  // their respective payment-method rows/buttons.
  static const Color khaltiPurple = Color(0xFF5C2D91);
  static const Color stripeIndigo = Color(0xFF635BFF);

  // ── Role Colors ───────────────────────────────────────
  // Each user type has its own color.
  // Used in the admin panel and role badges.
  static const Color customerColor   = Color(0xFFC0392B); // Red — matches brand
  static const Color restaurantColor = Color(0xFF8E44AD); // Purple
  static const Color riderColor      = Color(0xFF1ABC9C); // Teal
  static const Color adminColor      = Color(0xFF2C3E50); // Dark navy

  // ── Utility ───────────────────────────────────────────
  static const Color white       = Color(0xFFFFFFFF);
  static const Color black       = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  // ── Overlay ───────────────────────────────────────────
  // Semi-transparent black used over images and maps.
  // Like the dark layer over a restaurant's cover photo.
  static const Color overlay30 = Color(0x4D000000); // 30% black
  static const Color overlay60 = Color(0x99000000); // 60% black

  // ── Glass Colors ──────────────────────────────────────
  static const Color glassLight = Color(0xCCFFFFFF);   // light mode glass
  static const Color glassDark  = Color(0x1AFFFFFF);   // dark mode glass
  static const Color glassBorderLight = Color(0xB3FFFFFF);
  static const Color glassBorderDark  = Color(0x26FFFFFF);

  // ── Dark Mode Surfaces & Text ──────────────────────────
  // Named here (instead of inline Color(0xFF...) in app_theme.dart)
  // so dark mode is a real part of the palette, not an afterthought.
  static const Color darkBackground   = Color(0xFF121212);
  static const Color darkSurface      = Color(0xFF1E1E1E);
  static const Color darkSurfaceAlt   = Color(0xFF2A2A2A); // snackbars, elevated sheets
  static const Color darkBorder       = Color(0x1FFFFFFF); // 12% white
  static const Color darkDivider      = Color(0x14FFFFFF); // 8% white
  static const Color darkTextPrimary   = Color(0xFFF5F5F3);
  static const Color darkTextSecondary = Color(0xB3FFFFFF); // 70% white
  static const Color darkTextHint      = Color(0x66FFFFFF); // 40% white
}
