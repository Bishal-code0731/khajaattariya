-- ============================================================
-- Khaja Attariya — Module 5 migration
-- Fixes/additions needed before the reviews/support/refunds/
-- analytics features can work. Additive only — does not touch
-- any existing data, and does not repeat the RLS/avatar-bucket
-- fixes already applied earlier.
--
-- Safe to run once in the Supabase SQL Editor.
-- ============================================================

begin;

-- ------------------------------------------------------------
-- 1. support_replies: tighten a real security gap.
-- Today ANY authenticated user can insert a reply into ANY
-- ticket just by knowing/guessing its id, because the existing
-- "Auth insert reply" policy only checks actor_id = auth.uid()
-- with no ownership/admin check. Replace it with a policy that
-- only allows the ticket's own customer or an admin to reply.
-- ------------------------------------------------------------
drop policy if exists "Auth insert reply" on public.support_replies;

create policy "Ticket owner or admin insert reply" on public.support_replies
  for insert
  with check (
    actor_id = auth.uid()
    and (
      is_admin()
      or ticket_id in (select id from public.support_tickets where customer_id = auth.uid())
    )
  );

-- ------------------------------------------------------------
-- 2. refunds: customers currently have no way to request a
-- refund — only SELECT (own) and admin ALL exist, no INSERT.
-- Allow a customer to request a refund for their own order's
-- payment; status always starts as 'pending' so it still needs
-- admin approval via the existing "Admin manage refunds" policy.
-- ------------------------------------------------------------
create policy "Customer request refund" on public.refunds
  for insert
  with check (
    status = 'pending'
    and order_id in (select id from public.orders where customer_id = auth.uid())
    and payment_id in (
      select id from public.payments
      where order_id = refunds.order_id and customer_id = auth.uid()
    )
  );

-- ------------------------------------------------------------
-- 3. daily_sales: table exists but nothing populates it today.
-- New trigger upserts the (date, restaurant_id) row whenever an
-- order transitions into 'delivered', alongside the existing
-- handle_order_delivered trigger (this is a separate trigger,
-- so it doesn't touch/replace that function).
-- ------------------------------------------------------------
create or replace function public.update_daily_sales()
returns trigger
language plpgsql
security definer
as $$
begin
  if new.status = 'delivered' and old.status is distinct from 'delivered' then
    insert into public.daily_sales (date, restaurant_id, total_orders, total_revenue, total_platform_fee)
    values (
      current_date,
      new.restaurant_id,
      1,
      new.total_amount,
      coalesce(new.delivery_fee, 0)
    )
    on conflict (date, restaurant_id) do update
    set total_orders = public.daily_sales.total_orders + 1,
        total_revenue = public.daily_sales.total_revenue + excluded.total_revenue,
        total_platform_fee = public.daily_sales.total_platform_fee + excluded.total_platform_fee;
  end if;
  return new;
end;
$$;

drop trigger if exists orders_daily_sales_trigger on public.orders;

create trigger orders_daily_sales_trigger
  after update on public.orders
  for each row
  execute function public.update_daily_sales();

commit;
