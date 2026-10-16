-- Khaja Attariya — 3/5 Riders Rider profiles, earnings, COD cash-in-hand ledger (D-11).
begin;

-- riders (one row per rider account, id = profiles.id)
create table public.riders (
  id               uuid primary key references public.profiles (id) on delete cascade,
  vehicle_type     text not null default 'motorcycle'
                   check (vehicle_type in ('motorcycle', 'scooter', 'bicycle', 'car', 'other')),
  vehicle_number   text,
  is_online        boolean not null default false,
  is_approved      boolean not null default false,
  approval_note    text,
  current_lat      double precision,
  current_lng      double precision,
  total_deliveries integer not null default 0,
  total_earnings   numeric(12, 2) not null default 0,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);
create index riders_online_idx on public.riders (is_online) where is_online;

-- Riders can register and go online/offline, but never approve themselves or change their totals.
create or replace function private.protect_rider()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if not private.is_client_write() or private.is_admin() then
    return new;
  end if;
  if tg_op = 'INSERT' then
    new.id               := auth.uid();
    new.is_approved      := false;
    new.approval_note    := null;
    new.is_online        := false;
    new.total_deliveries := 0;
    new.total_earnings   := 0;
  else
    new.id               := old.id;
    new.is_approved      := old.is_approved;
    new.approval_note    := old.approval_note;
    new.total_deliveries := old.total_deliveries;
    new.total_earnings   := old.total_earnings;
    new.created_at       := old.created_at;
    if new.is_online and not old.is_approved then
      raise exception 'Your rider account is not approved yet.' using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;

create trigger riders_protect before insert or update on public.riders
  for each row execute function private.protect_rider();
create trigger riders_updated_at before update on public.riders
  for each row execute function private.set_updated_at();

alter table public.riders enable row level security;

create policy "riders: own or admin reads" on public.riders
  for select to authenticated
  using (id = auth.uid() or private.is_admin());

create policy "riders: rider accounts register" on public.riders
  for insert to authenticated
  with check ((id = auth.uid() and private.has_role('rider')) or private.is_admin());

create policy "riders: own or admin updates" on public.riders
  for update to authenticated
  using (id = auth.uid() or private.is_admin())
  with check (id = auth.uid() or private.is_admin());

create policy "riders: admin deletes" on public.riders
  for delete to authenticated
  using (private.is_admin());

create or replace function private.is_approved_rider()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select private.has_role('rider')
     and exists (select 1 from public.riders where id = auth.uid() and is_approved);
$$;

create table public.rider_earnings (
  id         uuid primary key default gen_random_uuid(),
  rider_id   uuid not null references public.riders (id) on delete cascade,
  order_id   uuid not null unique,
  amount     numeric(10, 2) not null check (amount >= 0),
  status     text not null default 'pending' check (status in ('pending', 'paid')),
  paid_at    timestamptz,
  created_at timestamptz not null default now()
);
create index rider_earnings_rider_idx on public.rider_earnings (rider_id, created_at desc);

alter table public.rider_earnings enable row level security;

create policy "earnings: own or admin reads" on public.rider_earnings
  for select to authenticated
  using (rider_id = auth.uid() or private.is_admin());

create policy "earnings: admin updates (mark paid)" on public.rider_earnings
  for update to authenticated
  using (private.is_admin())
  with check (private.is_admin());

create table public.rider_cash_ledger (
  id           uuid primary key default gen_random_uuid(),
  rider_id     uuid not null references public.riders (id) on delete cascade,
  order_id     uuid,  -- FK added in migration 4
  entry_type   text not null check (entry_type in ('cod_collected', 'settlement')),
  amount       numeric(10, 2) not null check (amount > 0),
  status       text not null default 'confirmed' check (status in ('pending', 'confirmed', 'rejected')),
  note         text,
  confirmed_by uuid references public.profiles (id) on delete set null,
  confirmed_at timestamptz,
  created_at   timestamptz not null default now()
);
create index rider_cash_ledger_rider_idx on public.rider_cash_ledger (rider_id, created_at desc);
create unique index rider_cash_ledger_one_per_order
  on public.rider_cash_ledger (order_id) where entry_type = 'cod_collected';

alter table public.rider_cash_ledger enable row level security;

create policy "cash: own or admin reads" on public.rider_cash_ledger
  for select to authenticated
  using (rider_id = auth.uid() or private.is_admin());

create policy "cash: rider requests a settlement" on public.rider_cash_ledger
  for insert to authenticated
  with check (
    (rider_id = auth.uid() and entry_type = 'settlement' and status = 'pending'
     and confirmed_by is null and order_id is null)
    or private.is_admin()
  );

create policy "cash: admin confirms or rejects" on public.rider_cash_ledger
  for update to authenticated
  using (private.is_admin())
  with check (private.is_admin());

create or replace function private.rider_cash_in_hand(p_rider uuid)
returns numeric
language sql stable security definer
set search_path = ''
as $$
  select coalesce(sum(case
           when entry_type = 'cod_collected' then amount
           when entry_type = 'settlement'    then -amount
         end), 0)
  from public.rider_cash_ledger
  where rider_id = p_rider and status = 'confirmed';
$$;

-- Cash each rider currently holds (respects ledger RLS: rider sees own, admin all).
create view public.rider_cash_balances
with (security_invoker = true) as
select
  rider_id,
  coalesce(sum(case
    when entry_type = 'cod_collected' then amount
    when entry_type = 'settlement'    then -amount
  end), 0)::numeric(12, 2) as cash_in_hand
from public.rider_cash_ledger
where status = 'confirmed'
group by rider_id;

commit;
