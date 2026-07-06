# Khaja Attariya — Full App Overview & Feature Flows

A food delivery app for Attariya, Sudurpashchim (Nepal). One Flutter codebase, one Supabase backend, four user roles. This document covers every feature and its flow, not just the high points.

## 1. Tech Stack

| Layer | Choice |
|---|---|
| App framework | Flutter 3.32 / Dart 3.8 |
| State management | Riverpod 2 (mix of `@riverpod` codegen and classic providers) |
| Navigation | go_router, with role-based redirect guards |
| Backend | Supabase (Postgres + Auth + Realtime + Storage) |
| Push notifications | Firebase Cloud Messaging |
| Maps / rider tracking | flutter_map (OpenStreetMap) + geolocator |
| Charts | fl_chart |
| Offline cache | shared_preferences (disk) + an in-memory TTL cache |
| Connectivity | connectivity_plus |
| Payments | Khalti + Stripe (sandbox/test-mode only) + Cash on Delivery |

## 2. Project Structure

Feature-first folders under `lib/features/<feature>/`:
```
domain/         → models + repository interfaces (pure Dart, no Supabase)
data/           → repository implementations (talk to Supabase)
application/    → Riverpod providers/notifiers (state + business logic)
presentation/   → screens and widgets
```
Shared building blocks: `lib/core/` (theme, router, caching, validators, responsive helpers, connectivity, retry queue) and `lib/shared/widgets/` (buttons, cards, loaders, empty/error states, offline banner, side menu — used everywhere so screens stay visually consistent).

`auth`, `home`, and `orders` follow the four-layer split strictly. `payments`, `favorites`, and `notifications` call Supabase directly from their `application/` providers without a separate `data/` layer — works fine, just less uniform.

## 3. Roles & Access Model

One app binary, gated by a single `profiles.role` column (`customer` / `restaurant` / `rider` / `admin`). `go_router`'s redirect logic sends each role to its own home on login and blocks it from every other role's routes.

**The role gate in the app is a navigation convenience, not the real security boundary.** Enforcement is Supabase Row-Level Security — every table check happens in Postgres against `auth.uid()`, independent of what the Flutter UI shows or hides.

---

## 4. Authentication Flow (all roles)

```
Splash (waits for auth state) 
  → not logged in  → Home (public browsing allowed) or Login (if a protected route was hit)
  → logged in       → role's home route (Home / Restaurant Dashboard / Rider Dashboard / Admin Dashboard)
```
- **Sign up**: email, password, phone, full name, and a role picker limited to Customer / Restaurant / Rider (Admin is never offered — and the `handle_new_user` DB trigger now whitelists roles server-side too, so it can't be forced via a raw API call either). A Postgres trigger creates the matching `profiles` row automatically the moment `auth.users` gets the new record; the client polls briefly to tolerate replication lag.
- **Log in**: email + password against Supabase Auth. On success, the router's own listener (not the login screen) handles navigation — this avoids the double-navigation race that used to exist.
- **Forgot password**: sends a Supabase reset email; no in-app password reset form (handled by Supabase's hosted flow).
- **Log out**: available from the side menu (customer) or the app bar (restaurant/rider/admin dashboards).
- **Session persistence**: handled entirely by `supabase_flutter`'s SDK — no custom token storage code.

---

## 5. Customer Features & Flows

### 5.1 Home / Browse
```
Home → Category chips (tap = no-op today, not wired to filtering)
     → Promo banner carousel
     → Nearby Restaurants (paginated list, grid on tablet/desktop)
     → Popular Foods (horizontal carousel, "+" adds straight to cart)
```
Restaurants/categories/popular-items are **offline-first**: cached data shows instantly, then silently refreshes from the network. Infinite-scroll loads more restaurants as you approach the bottom of the list.

### 5.2 Search
Reached via the search bar or bottom-nav search icon. Debounced (400ms) query against restaurant name and food name in parallel; stale results are dropped if a newer keystroke supersedes them mid-flight.

### 5.3 Restaurant Detail
```
Restaurant card tap → Restaurant Detail (hero image, info, hours, menu list, reviews)
                    → "+" on a menu item → adds to Cart
                    → different restaurant already in cart → "clear cart & start over" prompt
```

### 5.4 Cart & Checkout
```
Cart → review items (qty +/-) → delivery address (validated, required) → notes (optional)
     → apply coupon (optional, validated against min order / active window)
     → Proceed to Payment → Payment screen
```
Cart is single-restaurant only by design. Checkout is blocked by form validation until the address passes.

### 5.5 Payments (sandbox — see §10)
```
Payment screen → pick Khalti / Stripe / Cash → pay
  Khalti: opens Khalti checkout in browser → user pastes back the pidx to verify
  Stripe: test-mode dialog with hardcoded test card info, no real card entry
  Cash:   inserts a "pending" payment row immediately, no gateway involved
→ success → Orders screen
```

### 5.6 Orders & Tracking
```
Orders (realtime list, capped at 100 most recent) → Order Detail
  → live status timeline (pending → confirmed → preparing → ready → picked up → delivered)
  → "Track Order" (only while active) → Order Tracking (live map, rider position via Supabase Realtime)
  → after delivery → "Rate Order" bottom sheet
  → "Request Refund" (if eligible) → goes to admin's Refunds tab as pending
  
```

### 5.7 Favorites
Heart icon on any restaurant → toggles a row in `favorites`. Guarded against offline: if you toggle while offline, the action is queued and replayed automatically once connectivity returns (see §9.3). Favorites screen shows saved restaurants with a shimmer skeleton on first load.

### 5.8 Address Book
Reached from the side menu. Full CRUD: add/edit/delete an address, mark one as default (used to prefill checkout). Real form validation on the full-address field.

### 5.9 Notifications
```
FCM push arrives (order status changes, promos) → device token saved to profiles.fcm_token
   → in-app Notifications screen also shows a live list (Supabase Realtime)
   → tap a notification with an order_id → jumps to that Order Detail
   → "Mark all read" / swipe-to-delete
```
*Known inconsistency*: `saveFcmToken()` exists as a proper function in `notification_provider.dart` but isn't actually called — `main.dart` duplicates the same logic inline instead. Harmless (both do the same update), just dead code worth cleaning up later.

### 5.10 Support Tickets
```
Support screen → "New Ticket" → subject + message → submitted
  → appears in the admin's Support tab → admin replies (conversation thread) → admin marks Resolved
  → customer sees replies + status update on their Ticket Detail screen
```

### 5.11 Reviews / Ratings
After an order reaches `delivered`, a "Rate Order" bottom sheet becomes available: star rating + optional text review. A trigger recalculates the restaurant's average rating and review count automatically.

### 5.12 Profile
Edit full name, phone (validated), and avatar (via `image_picker` → Supabase Storage). Email is read-only (managed by Supabase Auth, not editable here).

### 5.13 Side Menu (drawer)
Slide-in panel (width-capped on tablets) with: Home, My Orders, Notifications, My Profile, My Addresses, Saved Restaurants, theme switcher (light/dark), Language & Rate the App (placeholders — "coming soon"), Help & Support, Logout. Content differs for guests (shows a "Login / Sign Up" prompt instead of the account section).

---

## 6. Restaurant Owner Features & Flows

```
Restaurant Dashboard
 ├─ Orders tab: incoming orders (realtime) grouped Active / Completed
 │    → "Confirm" → "Start Preparing" → "Mark Ready" (each a one-tap status push)
 │    → "Manage Menu" shortcut
 ├─ Analytics tab: this week / this month revenue, 30-day revenue line chart,
 │    peak order-hours bar chart, order-outcome pie chart (delivered/cancelled/other),
 │    cancellation rate, unique/repeat customers (30d), top 5 foods by units sold,
 │    CSV export via the OS share sheet
 └─ (wide screens: both tabs render side-by-side instead of behind tabs)

Menu Management (from the shortcut) → add/edit/delete items, toggle Available/Hidden per item
Restaurant Hours (separate screen) → per-weekday open/close toggle + time pickers
```
A brand-new restaurant owner sees "Your restaurant profile is not set up yet" until an admin approves their restaurant (see §7).

---

## 7. Rider Features & Flows

Three tabs:
```
Deliveries: online/offline toggle → see available "ready" orders with no rider assigned
  → Accept → order moves to "my active delivery" → live location broadcast starts (every 25s)
  → Deliver → order marked delivered, broadcast stops
Earnings: running total + per-delivery earnings history
Profile: if not yet registered as a rider → registration form (vehicle type/number)
  → submission goes to admin's Riders tab for approval before the rider can go online
```

---

## 8. Admin Features & Flows

Ten tabs in one dashboard:

| Tab | What it does |
|---|---|
| Analytics | Platform-wide order count, delivered count, total revenue |
| Users | List every profile; ban/unban (toggles `is_active`) |
| Restaurants | Approve a pending restaurant or deactivate/reactivate an existing one |
| Riders | Approve a pending rider, or reject with an optional note |
| Orders | Read-only feed of the 50 most recent orders platform-wide |
| Coupons | Create a coupon (code, percent/fixed discount, min order — all validated), toggle active/inactive |
| Support | See every ticket, open one to reply or mark resolved |
| Refunds | Approve or reject a customer's refund request |
| Audit Log | Read-only history of admin actions |
| Settings | Edit platform key/value config (Khalti/Stripe/Cash enabled flags, commission %, default delivery fee) |

Every mutating action here (ban, approve, toggle, reply, resolve) has its own per-row loading state — acting on one row never disables the others.

---

## 9. Cross-Cutting Systems (not tied to one screen)

### 9.1 Realtime
Orders, notifications, favorites, and live delivery position all stream via Supabase Realtime (`StreamProvider`), not polling. Streams are `autoDispose` — they close when you leave the screen instead of running for the whole app session.

### 9.2 Offline-First Caching
Restaurants (first page), categories, popular items, per-restaurant menus, and the signed-in user's profile are all cached to disk. On load: cached data renders instantly (no spinner), then a network fetch runs silently and replaces it if it succeeds. If the network fails, the cached version just keeps showing — the orange "You're offline" banner explains why it might be stale. Food images are disk-cached automatically via `cached_network_image`.

### 9.3 Retry Queue
If a write fails while offline (currently wired up for favorite-toggling as the reference case), it's queued to disk instead of just erroring. The moment connectivity flips back online, the queue replays automatically. Extending this to another mutation is a small addition in `retry_queue_flusher_provider.dart`.

### 9.4 Navigation Safety
Every routed screen is wrapped so the Android back button (or a bad deep link) never exits the app unexpectedly or shows a blank screen: pop if there's something to pop, otherwise return to the role's home; on a true home screen, "press back again to exit." Unknown routes show a proper "Page not found → Go home" screen instead of a raw error.

### 9.5 Validation
A central `Validators` class (email format, password strength, Nepali phone format, address length, price/number sanity) is used across every auth screen, checkout, address book, profile, menu management, and the admin coupon dialog — so error copy and rules stay consistent everywhere instead of each form inventing its own.

### 9.6 Responsive Layer
A `Responsive` utility defines phone/tablet/desktop breakpoints; used for the Home restaurant grid and the Restaurant Dashboard's side-by-side desktop layout. App-wide text-scale clamping prevents an OS "huge font" accessibility setting from overflowing fixed-height cards anywhere in the app.

---

## 10. Payments — Current State (sandbox only)

- **Khalti**: initiate → external browser checkout → manual `pidx` paste-in to verify. No real callback/webhook.
- **Stripe**: initiate → test-mode dialog with hardcoded test card fields, no real `flutter_stripe` card UI.
- **Cash**: fully functional (just inserts a `pending` payment row).
- Edge functions already exist (`supabase/functions/khalti-initiate`, `khalti-verify`, `stripe-initiate`) but aren't wired into a production callback flow yet.
- **This is the next piece of work.**

## 11. Data Model (Supabase/Postgres)

Core tables: `profiles`, `restaurants`, `menu_items`, `categories`, `orders`, `order_items`, `order_timeline`, `payments`, `refunds`, `coupons`, `coupon_usage`, `addresses`, `favorites`, `notifications`, `ratings`, `riders`, `rider_earnings`, `delivery_tracking`, `restaurant_hours`, `support_tickets`, `support_replies`, `daily_sales`, `platform_settings`, `audit_logs`, `banners`.

Server-side automation:
- `handle_new_user` — creates a `profiles` row on signup; role whitelisted to customer/restaurant/rider.
- `orders_timeline_trigger` / `record_order_timeline` — logs every order status change.
- `orders_delivered_trigger` / `handle_order_delivered` — side effects on delivery.
- `orders_daily_sales_trigger` / `update_daily_sales` — feeds the `daily_sales` table the Analytics tab reads from.
- `on_new_rating` / `update_restaurant_rating` — recalculates restaurant rating.
- `is_admin()` / `is_rider()` — RLS helper functions.
- `prevent_self_role_escalation` — blocks a non-admin from changing their own `role`/`is_active` via a normal profile update.

## 12. Security Fixes Applied to the Live Database

1. `handle_new_user` used to trust client-supplied `role` metadata verbatim at signup — closed via a server-side whitelist.
2. The "Users can update own profile" RLS policy checked row ownership only, not which columns changed, so any user could self-promote to admin — closed via the `prevent_self_role_escalation` trigger.

## 13. Known Gaps (deliberately not done yet)

- Real Khalti/Stripe callback-based payment confirmation (up next).
- Responsive/grid layouts across every screen — only Home and Restaurant Dashboard got the full treatment.
- Category filter tap and the notification-bell no-op on Home aren't wired to anything yet.
- `saveFcmToken()` dead code (duplicated inline in `main.dart` instead).
- No separate `data/` repository layer for payments/favorites/notifications.
