// Every spacing value in Khaja Attariya comes from here.
// Based on a 4px base unit — all values are multiples of 4.
// Never write padding: EdgeInsets.all(13) or height: 47.
// Always use AppSpacing values — they keep everything aligned.

class AppSpacing {

  // ── Base Scale ────────────────────────────────────────
  // From smallest to largest.
  // xs  → tiny gaps between an icon and its label
  // sm  → gaps inside small components like chips and tags
  // md  → standard padding — the most used value
  // lg  → section spacing — between groups of content
  // xl  → large sections — hero areas, onboarding screens
  // xxl → very large — splash screen, empty states
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 16.0;
  static const double lg  = 24.0;
  static const double xl  = 32.0;
  static const double xxl = 48.0;

  // ── Screen Layout ─────────────────────────────────────
  // The horizontal padding on every screen's left and right edge.
  // Every screen uses this — it keeps content aligned across the app.
  static const double screenHorizontal = 16.0;

  // ── Components ────────────────────────────────────────
  // Fixed sizes for common components.
  // All primary buttons are the same height — 52px.
  // All text fields are the same height — 52px.
  // This makes the app feel consistent and professional.
  static const double buttonHeight     = 52.0;
  static const double inputHeight      = 52.0;
  static const double appBarHeight     = 56.0;
  static const double bottomNavHeight  = 64.0;
  static const double cardPadding      = 16.0;

  // ── Border Radius ─────────────────────────────────────
  // How rounded the corners are.
  // sm  → small elements like tags and chips
  // md  → buttons, text fields, most cards
  // lg  → bigger cards, bottom sheets
  // xl  → large image cards, restaurant covers
  // full → completely round — avatar circles, icon buttons
  static const double radiusSm   = 8.0;
  static const double radiusMd   = 12.0;
  static const double radiusLg   = 16.0;
  static const double radiusXl   = 24.0;
  static const double radiusFull = 999.0; // Use for circles

  // ── Icon Sizes ────────────────────────────────────────
  static const double iconSm  = 16.0; // Small inline icons
  static const double iconMd  = 24.0; // Standard icons
  static const double iconLg  = 32.0; // Large feature icons

  // ── Avatar Sizes ──────────────────────────────────────
  static const double avatarSm  = 32.0;  // In lists, comments
  static const double avatarMd  = 48.0;  // Profile headers
  static const double avatarLg  = 80.0;  // Profile page
  static const double avatarXl  = 120.0; // Onboarding, large profile

  // ── Restaurant Card ───────────────────────────────────
  static const double restaurantCardHeight      = 200.0; // Full card
  static const double restaurantImageHeight     = 140.0; // Image part of card
  static const double menuItemImageSize         = 80.0;  // Food item thumbnail
}