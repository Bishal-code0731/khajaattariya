# Khaja Attariya

> Delicious food to your doorstep.

A food delivery app for Attariya, Kailali (Nepal). One Flutter codebase serves four roles — **customers**, **restaurant owners**, **delivery riders** and **admins** — each with its own screens and permissions.

## Features
- **Customers** — browse restaurants and menus, search and filter, apply coupons, pay with Khalti or cash on delivery, track the order on a map, rate orders, save addresses and favourites
- **Restaurants** — accept and prepare incoming orders, manage menu items, prices and photos, set opening hours, view sales
- **Riders** — go online, accept deliveries, update delivery status, share live location, track cash collected on COD orders
- **Admins** — approve restaurants and riders, manage users, coupons and support tickets
- Email sign-up with 6-digit OTP verification, role-based login and routing
- English and Nepali, light and dark mode

## Tech Stack
- **App** — Flutter (Android, iOS, Web)
- **Backend** — Supabase (Postgres with row-level security, Auth, Realtime, Storage, Edge Functions)
- **Push notifications** — Firebase Cloud Messaging
- **State management** — Riverpod with code generation
- **Navigation** — go_router with role guards
- **Structure** — feature-first folders with repository interfaces, so the backend can be swapped later
- **Payments** — Khalti and cash on delivery (eSewa planned)
- **Maps** — OpenStreetMap via flutter_map

Prices, totals, coupons, payment status and order status changes are decided on the server, never by the app.

## Status
Under active development. Ordering, Khalti and cash payments, the restaurant and rider flows and the admin panel are built and being tested on test data. eSewa, more automated tests and the store release are still to do.

## What I learned building this
Running four roles from one codebase pushed me to keep state cleanly separated with Riverpod and to design routing so each role only reaches its own screens. Moving business rules like pricing and order status into the database taught me to treat the app as untrusted and let the server have the final say.
