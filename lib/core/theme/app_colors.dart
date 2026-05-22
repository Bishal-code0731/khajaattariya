import 'package:flutter/material.dart';

// Every color used in Khaja Attariya lives here.
// Never write Color(0xFF...) anywhere else in the app.
// Always use AppColors.something instead.

class AppColors {

  // ── Primary Brand Colors ───────────────────────────────
  // The warm deep red is Khaja Attariya's identity.
  // Seen on buttons, icons, active states, the app bar.
  static const Color primary      = Color(0xFFC0392B); // Warm deep red
  static const Color primaryLight = Color(0xFFE74C3C); // Lighter red — hover states
  static const Color primaryDark  = Color(0xFF922B21); // Darker red — pressed states

  // ── Accent Color ──────────────────────────────────────
  // Golden yellow — used sparingly for highlights,
  // badges, special tags, promotional banners.
  // Like ghee on dal bhat — used carefully, not everywhere.
  static const Color accent       = Color(0xFFF39C12);
  static const Color accentLight  = Color(0xFFF8C471); // Lighter yellow for backgrounds

  // ── Background Colors ─────────────────────────────────
  // Warm white backgrounds — not cold bright white.
  // Makes the app feel like home, not a hospital.
  static const Color background   = Color(0xFFFFFDF9); // Main screen background
  static const Color surface      = Color(0xFFFFF8F5); // Cards, bottom sheets, dialogs

  // ── Text Colors ───────────────────────────────────────
  // Three levels of text — primary, secondary, hint.
  // Use the right level for the right context:
  // primary → headings, important info
  // secondary → descriptions, subtitles
  // hint → placeholder text, disabled labels
  static const Color textPrimary   = Color(0xFF2C2C2A); // Near black — main text
  static const Color textSecondary = Color(0xFF6D6D6A); // Warm grey — subtitles
  static const Color textHint      = Color(0xFFA8A8A5); // Light grey — placeholders

  // ── Border & Divider Colors ───────────────────────────
  static const Color border   = Color(0xFFE8E4E0); // Soft grey borders
  static const Color divider  = Color(0xFFF0EDE9); // Even softer for dividers

  // ── Semantic Colors ───────────────────────────────────
  // These communicate meaning — not decoration.
  // Always use these for their intended purpose:
  // success → order confirmed, payment done, delivered
  // error   → failed payment, wrong password, network error
  // warning → restaurant closing soon, item running low
  // info    → general tips, neutral information
  static const Color success = Color(0xFF27AE60);
  static const Color successLight = Color(0xFFD5F5E3); // Light green background
  static const Color error   = Color(0xFFE74C3C);
  static const Color errorLight = Color(0xFFFDEDEB);   // Light red background
  static const Color warning = Color(0xFFF39C12);
  static const Color warningLight = Color(0xFFFEF9E7); // Light yellow background
  static const Color info    = Color(0xFF2980B9);
  static const Color infoLight = Color(0xFFEBF5FB);    // Light blue background

  // ── Order Status Colors ───────────────────────────────
  // Every order goes through these stages.
  // Each stage has its own color so users understand
  // the status instantly without reading the text.
  static const Color statusPending    = Color(0xFFF39C12); // Yellow  — waiting for restaurant
  static const Color statusConfirmed  = Color(0xFF2980B9); // Blue    — restaurant accepted
  static const Color statusPreparing  = Color(0xFF8E44AD); // Purple  — being cooked
  static const Color statusReady      = Color(0xFF27AE60); // Green   — ready for pickup
  static const Color statusDelivering = Color(0xFFC0392B); // Red     — rider on the way
  static const Color statusDelivered  = Color(0xFF1E8449); // Dark green — completed
  static const Color statusCancelled  = Color(0xFF7F8C8D); // Grey    — cancelled

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
}