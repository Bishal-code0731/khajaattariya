-- ============================================================
-- Khaja Attariya — fix payment_logs RLS gap + missing realtime tables
--
-- Found by cross-checking a full schema dump against the app code:
--
-- 1. payment_logs has RLS enabled but only an admin-only SELECT
--    policy — no INSERT policy exists. The app inserts into this
--    table as the CUSTOMER during checkout (payment_provider.dart's
--    _logEvent), so every one of those writes has been silently
--    failing (caught, logged, swallowed) for every real payment.
--
-- 2. addresses and favorites are queried via .stream() in the app
--    (address_provider.dart, favorites_provider.dart) but are not in
--    the supabase_realtime publication — the initial fetch works,
--    but live change events never arrive, so those screens go stale
--    until manually reloaded.
--
-- Safe to run once in the Supabase SQL Editor.
-- ============================================================

begin;

-- ------------------------------------------------------------
-- 1. Allow a customer to insert a payment_logs row for a payment
-- they own. Mirrors the existing "Customer insert payment" pattern
-- already used on the payments table itself.
-- ------------------------------------------------------------
create policy "Customer insert own payment log" on public.payment_logs
  for insert
  with check (
    payment_id in (select id from public.payments where customer_id = auth.uid())
  );

-- ------------------------------------------------------------
-- 2. Add the two missing tables to the realtime publication so
-- .stream() subscriptions on them actually receive live updates.
-- ------------------------------------------------------------
alter publication supabase_realtime add table public.addresses;
alter publication supabase_realtime add table public.favorites;

commit;
