# Khaja Attariya — Project Summary

A Flutter food-delivery app for Attariya, Sudurpashchim, serving four roles from one codebase: **customers**, **restaurant owners**, **delivery riders**, and **platform admins**. Backend is entirely [Supabase](https://supabase.com) (Postgres + Auth + Realtime + Storage + Edge Functions).

## 1. Architecture

- **Pattern**: Feature-first folders (`lib/features/<feature>/{domain,data,application,presentation}`), state managed with **Riverpod**. Most features keep a thin `application/` layer (Riverpod providers/notifiers) talking to Supabase directly; a few (`auth`, `home`, `orders`) have a full `data/` repository layer behind a `domain/repositories` interface.
- **State management**: Riverpod only — `StateNotifierProvider` for mutations, `StreamProvider`/`FutureProvider` for reads, `AsyncValue` for loading/error/success everywhere.
- **Routing**: `go_router`, centralized in `lib/core/router/app_router.dart`. A single `redirect` callback handles: splash → role-based home, auth-route bouncing when already logged in, protected-route login gating, and **role-exclusive route guarding** (a customer can't open `/admin-dashboard` etc.).
- **Design system**: `lib/core/theme/` (`AppColors`, `AppTypography`, `AppSpacing`, `AppTheme`) + `lib/shared/widgets/` (`AppButton`, `AppTextField`, `AppLoader`, `AppErrorState`, `AppEmptyState`, `AppSnackbar`, `AsyncValueView`, `AppShimmer`, `GlassCard`, `GlassBottomNav`). Every screen is expected to use these rather than one-off `CircularProgressIndicator`/`SnackBar` calls.
- **Roles**: `lib/core/enums/user_role.dart` is the single source of truth for `customer | restaurant | rider | admin` — their labels, colors, home routes, and exclusive route prefixes.

## 2. Features

| Feature | What it does |
|---|---|
| `auth` | Signup/login/logout/password reset via Supabase Auth. `profiles` row created by a DB trigger (`handle_new_user`) on signup; role-based routing on login/signup. |
| `home` | Restaurant/food discovery, banners, categories, search entry point. |
| `restaurant` | Restaurant detail page: menu (filterable by veg/offers), info, and **customer reviews**. |
| `cart` | Local cart state (Riverpod), checkout hand-off to `orders`. |
| `orders` | Placing orders, live order list/detail (Supabase Realtime), order timeline, rating prompt, refund request. |
| `payments` | Khalti/Stripe (sandbox-style, real edge functions) and Cash on Delivery; platform-fee/coupon logic. |
| `reviews` | Star rating + text review per delivered order (`ratings` table), shown on the restaurant page. |
| `support` | Customer/rider/restaurant support tickets with a reply thread; admin has a matching inbox. |
| `address`, `favorites`, `notifications`, `profile`, `search` | Standard customer account features, all realtime where the table supports it. |
| `restaurant_dashboard` | Order queue with status progression, menu management, **7-day sales trend from `daily_sales`**. |
| `rider_dashboard` / `rider` | Online/offline toggle, available-pickup list, active delivery, earnings, registration/approval flow, **live location broadcast** while delivering. |
| `tracking` | Customer-facing live map (OpenStreetMap via `flutter_map` — no API key/billing) showing the rider's last-known position. |
| `admin_dashboard` | Analytics, users, restaurant/rider approval, coupons, orders, support tickets, refunds, audit log, platform settings — 10 tabs total. |

## 3. Data Flow (golden path)

1. **Signup** → Supabase Auth creates the user → `handle_new_user` trigger inserts a `profiles` row with the chosen role → app polls briefly for that row → routes to the role's home.
2. **Browse & order** → customer adds items to cart → `placeOrder` inserts `orders` + `order_items` → restaurant dashboard sees it instantly via Realtime → owner progresses status (`pending → confirmed → preparing → ready`).
3. **Payment** → Khalti/Stripe edge function initiates → customer completes on the gateway → verify/confirm step marks the `payments` row `completed` and the order `payment_status: paid`. Cash orders are recorded directly with `status: pending`.
4. **Delivery** → an online rider accepts a `ready` order (`assignRider`, sets `rider_id` + `picked_up`) → rider's device broadcasts location every ~25s to `delivery_tracking` → customer's tracking screen shows it live → rider marks `delivered`, which fires two DB triggers: `handle_order_delivered` and the new `update_daily_sales`.
5. **After delivery** → customer can rate the order (`ratings`) or request a refund (`refunds`, admin-approved) or open a support ticket (`support_tickets`/`support_replies`).
6. **Admin** oversees all of the above plus platform settings (commission %, gateway toggles) and an audit trail of approval/setting-change actions.

## 4. Color System

Defined in `lib/core/theme/app_colors.dart`. Warm brand red (`primary #C0392B`) with a **fixed** semantic palette — `error`, `warning`, and the decorative `accent` are now deliberately distinct hex values (previously `error`/`primaryLight` and `accent`/`warning`/`statusPending` were pixel-identical, which was fixed). Dark mode has its own named surface/text colors (`darkBackground`, `darkSurface`, `darkTextSecondary`, etc.) instead of inline hex scattered through the theme file. Light and dark `ThemeData` are built from one shared parameterized function with full parity (inputs, bottom nav, checkboxes, switches).

## 5. Supabase Schema & Security Model

26 tables, all with **RLS enabled**. Ownership is enforced with policies like `auth.uid() = customer_id`/`owner_id`/`rider_id`, plus `is_admin()`/`is_rider()` helper functions for role-wide access. Key points fixed during this work:

- `addresses`, `favorites`, `notifications`, `restaurant_hours` had RLS enabled with **zero policies** (fully locked) — fixed.
- No `avatars` storage bucket existed — created with a 2MB file-size cap (mindful of the free tier's 1GB storage limit).
- `profiles` admin-view policy checked a JWT claim that was never actually set — fixed to use `is_admin()`.
- `menu_items` had no policy letting an owner see their own *unavailable* items — fixed.
- `support_replies` allowed any authenticated user to reply to *any* ticket — restricted to the ticket owner or an admin.
- `refunds` had no customer-facing insert policy at all — added, scoped to the customer's own order/payment.
- `daily_sales` existed but nothing populated it — added `update_daily_sales()` trigger, fired alongside the existing `handle_order_delivered` trigger.

**Storage budget awareness** (free tier: 500MB DB, 1GB file storage): `daily_sales` is a small aggregated table, not a growing log; `delivery_tracking` writes are throttled to ~1 row per rider per 25 seconds during an active delivery only (not continuous), not an unbounded ping stream.

## 6. What's Genuinely Out of Scope

- **Firebase/FCM**: `firebase_options.dart` still needs `flutterfire configure` run against a real Firebase project (deferred by request — do this last).
- **Production payment gateways**: Khalti/Stripe remain sandbox-style (manual pidx paste, test-card dialog) per explicit decision — going live needs your production API keys and PCI/compliance work with `flutter_stripe`.
- **Android release signing**: scaffolding is in place (`android/key.properties` pattern), but you must generate and supply a real keystore — see the comment at the top of `android/app/build.gradle.kts` for the exact `keytool` command.
- **Google Maps**: intentionally avoided in favor of free OpenStreetMap tiles via `flutter_map`, per your budget constraint.

## 7. Full Audit & Cleanup Pass (latest session)

A full-app audit (architecture, UI/component duplication, TODO/stub inventory, Supabase/Firebase usage, `flutter analyze`) was run end-to-end, followed by a design-system/gap-finding plan, then several small verified batches of fixes. `flutter analyze` went from **191 issues → 135 issues, 0 errors/0 warnings throughout** (the remaining 135 are all cosmetic `prefer_const_constructors`-style infos).

**Bugs fixed:**
- Silent `catch (_) {}` in `payment_provider.dart` (`_logEvent`) was swallowing payment-audit-log failures with zero visibility — now logs via `AppLogger.warning`.
- 4 `use_build_context_synchronously` async-gap risks fixed in `address_book_screen.dart` and `payment_screen.dart` (stale `BuildContext` reused after an `await` with only an unrelated `mounted` check guarding it).
- Removed a genuinely unused import (`rider_model.dart` in `rider_dashboard_screen.dart`) and an unnecessary cast (`order_timeline_provider.dart`) — the only 2 real analyzer warnings found.
- Migrated every `withOpacity()` call (45 occurrences, theme + all shared widgets + 13 feature screens) to `.withValues(alpha:)`, and `AuthRepositoryRef`/`AuthStateRef` to plain `Ref` (regenerated via `build_runner`) — both deprecated ahead of a future Flutter/Riverpod breaking change.

**Duplicate widgets consolidated** (one canonical version each, old private classes deleted):
- `AppStatusBadge` (`lib/shared/widgets/app_status_badge.dart`) — replaces 3 independent order-status-pill implementations (`orders_screen.dart`, `restaurant_dashboard_screen.dart`, and admin's string-keyed `_OStatusBadge`).
- `AppStatTile` (`lib/shared/widgets/app_stat_tile.dart`) — replaces the admin dashboard's `_ACard`/`_Mini` and the restaurant dashboard's `_StatCard` (icon/value/label stat tiles), with a `large` flag covering the two visual sizes.
- `OrderItemsList` (`lib/shared/widgets/order_items_list.dart`) — replaces duplicated "qty × item name" row-rendering in the restaurant and rider order cards.
- `AppButton` adoption — replaced 4 raw `ElevatedButton` + hand-rolled `CircularProgressIndicator` loading-spinner reimplementations (3 in `rider_dashboard_screen.dart`, 1 in `restaurant_dashboard_screen.dart`) with `AppButton`'s existing `isLoading` support.
- `AppEmptyState` adoption — replaced `search_screen.dart`'s hand-rolled `_EmptySearch`/`_NoResults` (near-byte-for-byte duplicates) with direct calls to the shared component.
- Centralized `AppColors.khaltiPurple` / `AppColors.stripeIndigo` — replaced 5 scattered hardcoded hex literals in `payment_screen.dart`, closing the one real hex-color gap found in the audit.

**Deliberate scope decision:** the 4 order-card classes (`_OrderCard`, `_RestaurantOrderCard`, `_ActiveDeliveryCard`, `_AvailableOrderCard`) were *not* merged into one monolithic `AppOrderCard`. Their layouts genuinely diverge (different headers, different conditional sections, different gated actions) — forcing them into one variant-branching widget would trade 4 small readable classes for one large branchy one without reducing real duplication. Instead, only the parts that were actually byte-for-byte duplicated (status badge, loading button, item list) were extracted into shared components; each card's overall composition stays in its own file.

## 8. Remaining Work / Open Decisions

Not yet started — each needs either your explicit go-ahead (bigger risk/scope) or your input (business/legal/design call) before work begins:

- **Riverpod provider-style consolidation**: the codebase currently mixes 3 provider styles (code-gen `@riverpod` Notifier/AsyncNotifier, legacy `StateNotifierProvider`, and manual `Provider`/`FutureProvider`) across ~36 files. You approved standardizing on `@riverpod` code-gen everywhere, but this is the single largest and riskiest remaining change — not yet started; should be migrated one feature at a time with `flutter analyze` + a manual flow re-trace after each, never in one batch.
- **MVVM folder restructuring**: `lib/shared/` → `lib/design_system/` with atomic (tokens/atoms/molecules/organisms) subfolders, and giving every feature its own `data/`+`domain/` layer instead of borrowing a sibling feature's (currently `profile`, `restaurant`, `rider_dashboard`, `search`, and `admin_dashboard` don't have their own). Planned in the design-system doc, not yet executed.
- **Gantt chart** (customer-approved to build in all 3 locations: restaurant order-prep pipeline, rider delivery scheduling, admin cross-role order timeline) — approach agreed (custom widget built on the existing `fl_chart` dependency, no new package), not yet implemented.
- **Restaurant/menu-item image upload** — approved to add; currently only avatar upload exists. Needs a new `restaurant-media` Supabase Storage bucket, `flutter_image_compress` for client-side compression, and RLS policies scoped to the owning restaurant. Not yet implemented.
- **App icon** — confirmed missing/placeholder on both Android (no adaptive icon configured either) and iOS. Agreed I'll generate the artwork and wire up `flutter_launcher_icons`; not yet done.
- **Gap-finding checklist items still awaiting your decision** (flagged, not silently added): email verification flow, Terms of Service/Privacy Policy screens (need real legal copy from you), analytics/crash-reporting vendor choice, English/Nepali localization (is Nepali actually required?), app force-update/versioning via `platform_settings`.
- **Smaller deferred items** noted during the audit but not yet actioned: 3 dead-end "coming soon" side-menu stubs (Language/Rate the App/About), several silent `catch (_) {}` blocks without logging in `tracking_provider.dart`/`restaurant_provider.dart`/`address_provider.dart`/`local_store.dart`, no shared `AppScaffoldBar` (20 screens still build `AppBar` inline) or `RoleDashboardScaffold` (restaurant/rider/admin each configure their own independent `TabController`/`TabBar`), no cart out-of-stock/price-change re-check at checkout, no "browse all reviews" screen (only submission), no reorder-from-history action.
