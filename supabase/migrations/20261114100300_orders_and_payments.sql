begin;

-- addresses
create table public.addresses (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  label        text not null,
  full_address text not null check (length(trim(full_address)) >= 5),
  landmark     text,
  latitude     double precision,
  longitude    double precision,
  is_default   boolean not null default false,
  created_at   timestamptz not null default now()
);
create index addresses_user_idx on public.addresses (user_id);

alter table public.addresses enable row level security;

create policy "addresses: own" on public.addresses
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- coupons (admin-managed)
create table public.coupons (
  id                    uuid primary key default gen_random_uuid(),
  code                  text not null unique,
  description           text,
  discount_type         text not null default 'percent' check (discount_type in ('percent', 'fixed')),
  discount_value        numeric(10, 2) not null check (discount_value > 0),
  min_order_amount      numeric(10, 2) not null default 0 check (min_order_amount >= 0),
  max_discount          numeric(10, 2) check (max_discount is null or max_discount > 0),
  max_uses              integer check (max_uses is null or max_uses > 0),
  max_uses_per_customer integer not null default 1 check (max_uses_per_customer > 0),
  uses_count            integer not null default 0,
  valid_from            timestamptz not null default now(),
  valid_until           timestamptz,
  is_active             boolean not null default true,
  created_at            timestamptz not null default now(),
  check (discount_type <> 'percent' or discount_value <= 100)
);

alter table public.coupons enable row level security;

create policy "coupons: signed-in users read active" on public.coupons
  for select to authenticated
  using (is_active or private.is_admin());

create policy "coupons: admin manages" on public.coupons
  for all to authenticated
  using (private.is_admin())
  with check (private.is_admin());

-- orders
create type public.order_status as enum
  ('pending', 'confirmed', 'preparing', 'ready', 'picked_up', 'delivered', 'cancelled');

create table public.orders (
  id               uuid primary key default gen_random_uuid(),
  checkout_id      uuid not null default gen_random_uuid(),  -- groups orders placed together
  customer_id      uuid not null references public.profiles (id) on delete cascade,
  restaurant_id    uuid not null references public.restaurants (id) on delete restrict,
  rider_id         uuid references public.profiles (id) on delete set null,
  status           public.order_status not null default 'pending',
  subtotal         numeric(10, 2) not null default 0 check (subtotal >= 0),
  delivery_fee     numeric(8, 2) not null default 0 check (delivery_fee >= 0),
  discount_amount  numeric(10, 2) not null default 0 check (discount_amount >= 0),
  total_amount     numeric(10, 2) not null default 0 check (total_amount >= 0),
  coupon_id        uuid references public.coupons (id) on delete set null,
  payment_method   text not null default 'cash' check (payment_method in ('cash', 'khalti', 'esewa')),
  payment_status   text not null default 'pending' check (payment_status in ('pending', 'paid', 'failed', 'refunded')),
  delivery_address text,
  notes            text,
  cancel_reason    text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);
create index orders_customer_idx   on public.orders (customer_id, created_at desc);
create index orders_restaurant_idx on public.orders (restaurant_id, status, created_at desc);
create index orders_rider_idx      on public.orders (rider_id, status);
create index orders_available_idx  on public.orders (status, created_at desc) where rider_id is null;
create index orders_checkout_idx   on public.orders (checkout_id);

alter table public.notifications
  add constraint notifications_order_id_fkey
  foreign key (order_id) references public.orders (id) on delete set null;
alter table public.rider_earnings
  add constraint rider_earnings_order_id_fkey
  foreign key (order_id) references public.orders (id) on delete cascade;
alter table public.rider_cash_ledger
  add constraint rider_cash_ledger_order_id_fkey
  foreign key (order_id) references public.orders (id) on delete set null;

create or replace function private.can_view_order(p_order_id uuid)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.orders o
    where o.id = p_order_id
      and (o.customer_id = auth.uid()
           or o.rider_id = auth.uid()
           or private.owns_restaurant(o.restaurant_id)
           or private.is_admin())
  );
$$;

create or replace function private.rider_can_accept(p_order_id uuid)
returns boolean
language plpgsql stable security definer
set search_path = ''
as $$
declare
  v_order public.orders%rowtype;
begin
  if not private.has_role('rider') then
    return false;
  end if;
  if not exists (select 1 from public.riders r
                 where r.id = auth.uid() and r.is_approved and r.is_online) then
    return false;
  end if;
  select * into v_order from public.orders where id = p_order_id;
  if not found or v_order.status <> 'ready' or v_order.rider_id is not null then
    return false;
  end if;
  if v_order.payment_method = 'cash'
     and private.rider_cash_in_hand(auth.uid()) + v_order.total_amount
         > private.setting_numeric('cod_cash_limit', 5000) then
    return false;
  end if;
  return true;
end;
$$;

-- Guards every client update of an order.
create or replace function private.validate_order_update()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_uid         uuid;
  v_is_customer boolean;
  v_is_owner    boolean;
  v_is_rider    boolean;
  v_change      text;
begin
  if not private.is_client_write() or private.is_admin() then
    return new;
  end if;
  v_uid         := auth.uid();
  v_is_customer := old.customer_id = v_uid;
  v_is_owner    := private.owns_restaurant(old.restaurant_id);
  v_is_rider    := old.rider_id is not null and old.rider_id = v_uid;
  v_change      := old.status::text || '>' || new.status::text;

  if new.checkout_id      is distinct from old.checkout_id
     or new.customer_id   is distinct from old.customer_id
     or new.restaurant_id is distinct from old.restaurant_id
     or new.subtotal      is distinct from old.subtotal
     or new.delivery_fee  is distinct from old.delivery_fee
     or new.discount_amount is distinct from old.discount_amount
     or new.total_amount  is distinct from old.total_amount
     or new.coupon_id     is distinct from old.coupon_id
     or new.payment_method is distinct from old.payment_method
     or new.payment_status is distinct from old.payment_status
     or new.delivery_address is distinct from old.delivery_address
     or new.created_at    is distinct from old.created_at then
    raise exception 'These order details can only be changed by the server.'
      using errcode = '42501';
  end if;

  -- Rider takes a delivery: ready + unassigned → picked_up, assigned to self.
  if new.rider_id is distinct from old.rider_id then
    if old.rider_id is null and new.rider_id = v_uid
       and old.status = 'ready' and new.status = 'picked_up'
       and private.rider_can_accept(old.id) then
      return new;
    end if;
    raise exception 'You cannot take this delivery.' using errcode = '42501';
  end if;

  if new.status is distinct from old.status then
    if v_is_owner and v_change in ('pending>confirmed', 'pending>cancelled',
                                   'confirmed>preparing', 'confirmed>cancelled',
                                   'preparing>ready') then
      null;
    elsif v_is_customer and v_change = 'pending>cancelled' then
      null;
    elsif v_is_rider and v_change = 'picked_up>delivered' then
      null;
    else
      raise exception 'This order cannot move from % to %.', old.status, new.status
        using errcode = '42501';
    end if;
  end if;

  if new.notes is distinct from old.notes
     and not (v_is_customer and old.status = 'pending') then
    raise exception 'Notes can only be changed by the customer before the order is accepted.'
      using errcode = '42501';
  end if;

  if new.cancel_reason is distinct from old.cancel_reason and new.status <> 'cancelled' then
    raise exception 'A cancel reason is only allowed when cancelling.' using errcode = '42501';
  end if;

  return new;
end;
$$;

create trigger orders_validate before update on public.orders
  for each row execute function private.validate_order_update();
create trigger orders_updated_at before update on public.orders
  for each row execute function private.set_updated_at();

alter table public.orders enable row level security;

create policy "orders: involved parties read; approved riders see open deliveries" on public.orders
  for select to authenticated
  using (
    customer_id = auth.uid()
    or rider_id = auth.uid()
    or private.owns_restaurant(restaurant_id)
    or private.is_admin()
    or (status = 'ready' and rider_id is null and private.is_approved_rider())
  );

-- Who may attempt an update; what they may change is decided by orders_validate.
create policy "orders: involved parties update" on public.orders
  for update to authenticated
  using (
    customer_id = auth.uid()
    or rider_id = auth.uid()
    or private.owns_restaurant(restaurant_id)
    or private.is_admin()
    or (status = 'ready' and rider_id is null and private.is_approved_rider())
  )
  with check (
    customer_id = auth.uid()
    or rider_id = auth.uid()
    or private.owns_restaurant(restaurant_id)
    or private.is_admin()
  );
-- No INSERT/DELETE policies: orders are created only by place_orders().

-- order_items
create table public.order_items (
  id           uuid primary key default gen_random_uuid(),
  order_id     uuid not null references public.orders (id) on delete cascade,
  menu_item_id uuid not null references public.menu_items (id) on delete restrict,
  name         text not null,
  price        numeric(8, 2) not null check (price >= 0),
  quantity     integer not null check (quantity between 1 and 50),
  subtotal     numeric(10, 2) not null check (subtotal >= 0),
  created_at   timestamptz not null default now()
);
create index order_items_order_idx on public.order_items (order_id);
create index order_items_menu_idx on public.order_items (menu_item_id);

alter table public.order_items enable row level security;

create policy "order items: same visibility as the order" on public.order_items
  for select to authenticated
  using (private.can_view_order(order_id) or exists (
    select 1 from public.orders o
    where o.id = order_id and o.status = 'ready' and o.rider_id is null
      and private.is_approved_rider()));

-- order_timeline (written only by triggers)
create table public.order_timeline (
  id         uuid primary key default gen_random_uuid(),
  order_id   uuid not null references public.orders (id) on delete cascade,
  status     text not null,
  note       text,
  actor_id   uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now()
);
create index order_timeline_order_idx on public.order_timeline (order_id, created_at);

alter table public.order_timeline enable row level security;

create policy "timeline: same visibility as the order" on public.order_timeline
  for select to authenticated
  using (private.can_view_order(order_id));

-- place_orders(): the ONLY way to create orders.
create or replace function public.place_orders(
  p_customer_id      uuid,
  p_delivery_address text,
  p_notes            text,
  p_delivery_fee     numeric default null,  -- ignored (server setting default_delivery_fee)
  p_groups           jsonb default '[]'::jsonb
)
returns setof public.orders
language plpgsql security definer
set search_path = ''
as $$
declare
  v_uid        uuid := auth.uid();
  v_checkout   uuid := gen_random_uuid();
  v_fee        numeric(8, 2);
  v_group      jsonb;
  v_item       jsonb;
  v_restaurant public.restaurants%rowtype;
  v_menu       public.menu_items%rowtype;
  v_order      public.orders%rowtype;
  v_qty        integer;
  v_subtotal   numeric(10, 2);
begin
  if v_uid is null or v_uid is distinct from p_customer_id then
    raise exception 'Not allowed.' using errcode = '42501';
  end if;
  if not private.has_role('customer') then
    raise exception 'Only customer accounts can place orders.' using errcode = '42501';
  end if;
  if p_delivery_address is null or length(trim(p_delivery_address)) < 5 then
    raise exception 'Please enter a delivery address.';
  end if;
  if p_groups is null or jsonb_typeof(p_groups) <> 'array' then
    raise exception 'Your cart is empty.';
  end if;
  if jsonb_array_length(p_groups) = 0 then
    raise exception 'Your cart is empty.';
  end if;

  v_fee := private.setting_numeric('default_delivery_fee', 30);

  for v_group in select value from jsonb_array_elements(p_groups)
  loop
    select * into v_restaurant
    from public.restaurants
    where id = (v_group ->> 'restaurant_id')::uuid;

    if not found or not v_restaurant.is_active or not v_restaurant.is_approved then
      raise exception 'A restaurant in your cart is not available.';
    end if;
    if not v_restaurant.is_open then
      raise exception '% is closed right now.', v_restaurant.name;
    end if;

    insert into public.orders (checkout_id, customer_id, restaurant_id, delivery_address, notes, delivery_fee)
    values (v_checkout, v_uid, v_restaurant.id, trim(p_delivery_address),
            nullif(trim(coalesce(p_notes, '')), ''), v_fee)
    returning * into v_order;

    v_subtotal := 0;
    for v_item in select value from jsonb_array_elements(coalesce(v_group -> 'items', '[]'::jsonb))
    loop
      v_qty := (v_item ->> 'quantity')::integer;
      if v_qty is null or v_qty < 1 or v_qty > 50 then
        raise exception 'Invalid quantity in your cart.';
      end if;

      select * into v_menu
      from public.menu_items
      where id = (v_item ->> 'menu_item_id')::uuid
        and restaurant_id = v_restaurant.id;

      if not found or not v_menu.is_available then
        raise exception 'An item in your cart is no longer available.';
      end if;

      insert into public.order_items (order_id, menu_item_id, name, price, quantity, subtotal)
      values (v_order.id, v_menu.id, v_menu.name, v_menu.price, v_qty, v_menu.price * v_qty);

      v_subtotal := v_subtotal + v_menu.price * v_qty;
    end loop;

    if v_subtotal = 0 then
      raise exception 'Your cart is empty.';
    end if;

    update public.orders
    set subtotal = v_subtotal, total_amount = v_subtotal + v_fee
    where id = v_order.id
    returning * into v_order;

    return next v_order;
  end loop;
end;
$$;

-- Order events: timeline, notifications, delivery settlement.
create or replace function private.on_order_created()
returns trigger
language plpgsql security definer
set search_path = ''
as $$
declare
  v_owner uuid;
begin
  insert into public.order_timeline (order_id, status, actor_id)
  values (new.id, new.status::text, auth.uid());

  select owner_id into v_owner from public.restaurants where id = new.restaurant_id;
  perform private.notify(v_owner, 'New order',
    'Order #' || upper(left(new.id::text, 8)) || ' is waiting for you.', 'new_order', new.id);
  return new;
end;
$$;

create trigger orders_created after insert on public.orders
  for each row execute function private.on_order_created();

create or replace function private.on_order_status_changed()
returns trigger
language plpgsql security definer
set search_path = ''
as $$
declare
  v_code        text := upper(left(new.id::text, 8));
  v_share       numeric;
  v_commission  numeric;
  v_rider_cut   numeric(10, 2);
begin
  if new.status is not distinct from old.status then
    return new;
  end if;

  insert into public.order_timeline (order_id, status, actor_id)
  values (new.id, new.status::text, auth.uid());

  perform private.notify(new.customer_id,
    case new.status
      when 'confirmed' then 'Order confirmed'
      when 'preparing' then 'Being prepared'
      when 'ready'     then 'Ready for pickup'
      when 'picked_up' then 'On the way'
      when 'delivered' then 'Delivered'
      when 'cancelled' then 'Order cancelled'
      else 'Order update'
    end,
    'Order #' || v_code || ' is now ' || replace(new.status::text, '_', ' ') || '.',
    'order_status', new.id);

  if new.status = 'cancelled' then
    update public.payments set status = 'failed', updated_at = now()
    where order_id = new.id and status = 'pending';
  end if;

  if new.status = 'delivered' then
    v_share      := private.setting_numeric('rider_share_percent', 80);
    v_commission := private.setting_numeric('commission_percent', 20);

    -- Rider earnings (BR-12: share of the delivery fee, configurable)
    if new.rider_id is not null and exists (select 1 from public.riders where id = new.rider_id) then
      v_rider_cut := round(new.delivery_fee * v_share / 100, 2);
      insert into public.rider_earnings (rider_id, order_id, amount)
      values (new.rider_id, new.id, v_rider_cut)
      on conflict (order_id) do nothing;
      update public.riders
      set total_deliveries = total_deliveries + 1,
          total_earnings   = total_earnings + v_rider_cut
      where id = new.rider_id;
    end if;

    -- Cash on delivery: the rider collected the money
    if new.payment_method = 'cash' and new.payment_status <> 'paid' then
      update public.payments set status = 'completed', updated_at = now()
      where order_id = new.id and method = 'cash' and status = 'pending';
      if not found then
        insert into public.payments (order_id, customer_id, method, status, amount)
        values (new.id, new.customer_id, 'cash', 'completed', new.total_amount);
      end if;
      update public.orders set payment_status = 'paid' where id = new.id;
      if new.rider_id is not null and exists (select 1 from public.riders where id = new.rider_id) then
        insert into public.rider_cash_ledger (rider_id, order_id, entry_type, amount, status)
        values (new.rider_id, new.id, 'cod_collected', new.total_amount, 'confirmed')
        on conflict do nothing;
      end if;
    end if;

    -- Daily sales summary (date in Nepal time)
    insert into public.daily_sales (date, restaurant_id, total_orders, total_revenue, total_platform_fee)
    values ((now() at time zone 'Asia/Kathmandu')::date, new.restaurant_id, 1, new.total_amount,
            round(new.subtotal * v_commission / 100, 2))
    on conflict (date, restaurant_id) do update
      set total_orders       = public.daily_sales.total_orders + 1,
          total_revenue      = public.daily_sales.total_revenue + excluded.total_revenue,
          total_platform_fee = public.daily_sales.total_platform_fee + excluded.total_platform_fee;
  end if;

  return new;
end;
$$;

create trigger orders_status_changed after update of status on public.orders
  for each row execute function private.on_order_status_changed();

create table public.coupon_usage (
  id               uuid primary key default gen_random_uuid(),
  coupon_id        uuid not null references public.coupons (id) on delete cascade,
  customer_id      uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  order_id         uuid not null references public.orders (id) on delete cascade,
  discount_applied numeric(10, 2) not null default 0,
  used_at          timestamptz not null default now(),
  unique (order_id)
);
create index coupon_usage_coupon_customer_idx on public.coupon_usage (coupon_id, customer_id);

create or replace function private.apply_coupon()
returns trigger
language plpgsql security definer
set search_path = ''
as $$
declare
  v_coupon       public.coupons%rowtype;
  v_order        public.orders%rowtype;
  v_checkout_sum numeric(10, 2);
  v_discount     numeric(10, 2);
  v_share        numeric(10, 2);
  v_prev_uses    integer;
  v_cust_uses    integer;
begin
  select * into v_order from public.orders where id = new.order_id for update;
  if not found or v_order.customer_id is distinct from auth.uid() then
    raise exception 'Not allowed.' using errcode = '42501';
  end if;
  if v_order.status <> 'pending' or v_order.payment_status <> 'pending' or v_order.coupon_id is not null then
    raise exception 'A coupon can only be added to a new, unpaid order.';
  end if;
  if exists (select 1 from public.payments where order_id = v_order.id and status in ('pending', 'completed')) then
    raise exception 'Add the coupon before choosing a payment method.';
  end if;

  select * into v_coupon from public.coupons where id = new.coupon_id;
  if not found or not v_coupon.is_active
     or now() < v_coupon.valid_from
     or (v_coupon.valid_until is not null and now() > v_coupon.valid_until) then
    raise exception 'This coupon is not valid.';
  end if;

  -- Uses are counted per checkout (one checkout may contain several orders).
  select count(distinct o.checkout_id) into v_prev_uses
  from public.coupon_usage cu join public.orders o on o.id = cu.order_id
  where cu.coupon_id = v_coupon.id and o.checkout_id <> v_order.checkout_id and o.status <> 'cancelled';
  if v_coupon.max_uses is not null and v_prev_uses >= v_coupon.max_uses then
    raise exception 'This coupon has reached its usage limit.';
  end if;

  select count(distinct o.checkout_id) into v_cust_uses
  from public.coupon_usage cu join public.orders o on o.id = cu.order_id
  where cu.coupon_id = v_coupon.id and cu.customer_id = v_order.customer_id
    and o.checkout_id <> v_order.checkout_id and o.status <> 'cancelled';
  if v_cust_uses >= v_coupon.max_uses_per_customer then
    raise exception 'You have already used this coupon.';
  end if;

  select coalesce(sum(subtotal), 0) into v_checkout_sum
  from public.orders where checkout_id = v_order.checkout_id;
  if v_checkout_sum < v_coupon.min_order_amount then
    raise exception 'Minimum order for this coupon is Rs %.', v_coupon.min_order_amount;
  end if;

  if v_coupon.discount_type = 'percent' then
    v_discount := round(v_checkout_sum * v_coupon.discount_value / 100, 2);
  else
    v_discount := v_coupon.discount_value;
  end if;
  if v_coupon.max_discount is not null then
    v_discount := least(v_discount, v_coupon.max_discount);
  end if;
  v_discount := least(v_discount, v_checkout_sum);

  -- This order's share, proportional to its food subtotal.
  v_share := case when v_checkout_sum > 0
                  then round(v_discount * v_order.subtotal / v_checkout_sum, 2) else 0 end;

  update public.orders
  set coupon_id = v_coupon.id,
      discount_amount = v_share,
      total_amount = greatest(subtotal + delivery_fee - v_share, 0)
  where id = v_order.id;

  update public.coupons set uses_count = v_prev_uses + 1 where id = v_coupon.id;

  new.customer_id      := v_order.customer_id;
  new.discount_applied := v_share;
  new.used_at          := now();
  return new;
end;
$$;

create trigger coupon_usage_apply before insert on public.coupon_usage
  for each row execute function private.apply_coupon();

alter table public.coupon_usage enable row level security;

create policy "coupon usage: own or admin reads" on public.coupon_usage
  for select to authenticated
  using (customer_id = auth.uid() or private.is_admin());

create policy "coupon usage: customer applies to own order" on public.coupon_usage
  for insert to authenticated
  with check (customer_id = auth.uid());

-- Kept so the current app's call doesn't fail; counting now happens in apply_coupon().
create or replace function public.increment_coupon_uses(coupon_id uuid)
returns void
language plpgsql
set search_path = ''
as $$
begin
  return;
end;
$$;

-- payments — clients create a pending payment for their own order; the server sets the amount.
create table public.payments (
  id              uuid primary key default gen_random_uuid(),
  order_id        uuid not null references public.orders (id) on delete cascade,
  customer_id     uuid not null references public.profiles (id) on delete cascade,
  method          text not null check (method in ('cash', 'khalti', 'esewa')),
  status          text not null default 'pending'
                  check (status in ('pending', 'completed', 'failed', 'expired', 'refunded')),
  amount          numeric(10, 2) not null check (amount >= 0),
  currency        text not null default 'NPR' check (currency = 'NPR'),
  gateway_ref     text,
  gateway_payload jsonb,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index payments_order_idx on public.payments (order_id);
create index payments_customer_idx on public.payments (customer_id, created_at desc);
create index payments_gateway_ref_idx on public.payments (gateway_ref) where gateway_ref is not null;
create unique index payments_one_active_per_order
  on public.payments (order_id) where status in ('pending', 'completed');

create or replace function private.prepare_payment_for_order(p_order_id uuid, p_method text)
returns numeric
language plpgsql security definer
set search_path = ''
as $$
declare
  v_order public.orders%rowtype;
begin
  select * into v_order from public.orders where id = p_order_id for update;
  if not found or v_order.customer_id is distinct from auth.uid() then
    raise exception 'Not allowed.' using errcode = '42501';
  end if;
  if v_order.payment_status = 'paid' then
    raise exception 'This order is already paid.';
  end if;
  if v_order.status = 'cancelled' then
    raise exception 'This order was cancelled.';
  end if;

  update public.payments
  set status = 'expired', updated_at = now()
  where order_id = v_order.id and status = 'pending'
    and (created_at < now() - interval '15 minutes' or p_method = 'cash');

  update public.orders set payment_method = p_method where id = v_order.id;

  return v_order.total_amount;
end;
$$;

create or replace function private.prepare_payment()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if not private.is_client_write() or private.is_admin() then
    return new;
  end if;
  new.amount      := private.prepare_payment_for_order(new.order_id, new.method);
  new.customer_id := auth.uid();
  new.status      := 'pending';
  new.currency    := 'NPR';
  return new;
end;
$$;

create trigger payments_prepare before insert on public.payments
  for each row execute function private.prepare_payment();
create trigger payments_updated_at before update on public.payments
  for each row execute function private.set_updated_at();

alter table public.payments enable row level security;

create policy "payments: own or admin reads" on public.payments
  for select to authenticated
  using (customer_id = auth.uid() or private.is_admin());

create policy "payments: customer starts a payment for own order" on public.payments
  for insert to authenticated
  with check (customer_id = auth.uid());

create policy "payments: admin updates" on public.payments
  for update to authenticated
  using (private.is_admin())
  with check (private.is_admin());

-- payment_logs
create table public.payment_logs (
  id         uuid primary key default gen_random_uuid(),
  payment_id uuid not null references public.payments (id) on delete cascade,
  event      text not null,
  payload    jsonb,
  created_at timestamptz not null default now()
);
create index payment_logs_payment_idx on public.payment_logs (payment_id);

alter table public.payment_logs enable row level security;

create policy "payment logs: admin reads" on public.payment_logs
  for select to authenticated
  using (private.is_admin());

create policy "payment logs: customer logs own payment" on public.payment_logs
  for insert to authenticated
  with check (exists (select 1 from public.payments p
                      where p.id = payment_id and p.customer_id = auth.uid()));

-- refunds
create table public.refunds (
  id           uuid primary key default gen_random_uuid(),
  payment_id   uuid not null references public.payments (id) on delete cascade,
  order_id     uuid not null references public.orders (id) on delete cascade,
  amount       numeric(10, 2) not null check (amount > 0),
  reason       text,
  status       text not null default 'pending'
               check (status in ('pending', 'approved', 'rejected', 'processed')),
  gateway_ref  text,
  processed_at timestamptz,
  created_at   timestamptz not null default now()
);
create index refunds_order_idx on public.refunds (order_id);
create unique index refunds_one_open_per_payment
  on public.refunds (payment_id) where status in ('pending', 'approved');

create or replace function private.prepare_refund()
returns trigger
language plpgsql security definer
set search_path = ''
as $$
declare
  v_payment public.payments%rowtype;
begin
  if auth.uid() is null or private.is_admin() then
    return new;
  end if;
  select * into v_payment from public.payments where id = new.payment_id;
  if not found or v_payment.customer_id <> auth.uid() or v_payment.order_id <> new.order_id then
    raise exception 'Not allowed.' using errcode = '42501';
  end if;
  if v_payment.status <> 'completed' then
    raise exception 'This order has no completed payment to refund.';
  end if;
  new.status       := 'pending';
  new.amount       := least(new.amount, v_payment.amount);
  new.gateway_ref  := null;
  new.processed_at := null;
  return new;
end;
$$;

create trigger refunds_prepare before insert on public.refunds
  for each row execute function private.prepare_refund();

alter table public.refunds enable row level security;

create policy "refunds: own or admin reads" on public.refunds
  for select to authenticated
  using (private.is_admin() or exists (
    select 1 from public.orders o where o.id = order_id and o.customer_id = auth.uid()));

create policy "refunds: customer requests for own order" on public.refunds
  for insert to authenticated
  with check (exists (
    select 1 from public.orders o where o.id = order_id and o.customer_id = auth.uid()));

create policy "refunds: admin decides" on public.refunds
  for update to authenticated
  using (private.is_admin())
  with check (private.is_admin());

-- ratings — one per delivered order, by its customer
create table public.ratings (
  id            uuid primary key default gen_random_uuid(),
  order_id      uuid not null unique references public.orders (id) on delete cascade,
  customer_id   uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  restaurant_id uuid not null references public.restaurants (id) on delete cascade,
  rating        integer not null check (rating between 1 and 5),
  review        text check (review is null or length(review) <= 1000),
  created_at    timestamptz not null default now()
);
create index ratings_restaurant_idx on public.ratings (restaurant_id, created_at desc);

create or replace function private.update_restaurant_rating()
returns trigger
language plpgsql security definer
set search_path = ''
as $$
declare
  v_restaurant uuid := coalesce(new.restaurant_id, old.restaurant_id);
begin
  update public.restaurants r
  set rating       = coalesce((select round(avg(x.rating)::numeric, 1) from public.ratings x
                               where x.restaurant_id = v_restaurant), 0),
      review_count = (select count(*) from public.ratings x where x.restaurant_id = v_restaurant)
  where r.id = v_restaurant;
  return null;
end;
$$;

create trigger ratings_changed after insert or update or delete on public.ratings
  for each row execute function private.update_restaurant_rating();

alter table public.ratings enable row level security;

create policy "ratings: anyone reads" on public.ratings
  for select to anon, authenticated
  using (true);

create policy "ratings: customer rates own delivered order" on public.ratings
  for insert to authenticated
  with check (
    customer_id = auth.uid()
    and exists (select 1 from public.orders o
                where o.id = order_id
                  and o.customer_id = auth.uid()
                  and o.restaurant_id = ratings.restaurant_id
                  and o.status = 'delivered')
  );

create policy "ratings: admin moderates" on public.ratings
  for delete to authenticated
  using (private.is_admin());

-- delivery_tracking — assigned rider only, while delivering
create table public.delivery_tracking (
  id          uuid primary key default gen_random_uuid(),
  order_id    uuid not null references public.orders (id) on delete cascade,
  rider_id    uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  lat         double precision not null check (lat between -90 and 90),
  lng         double precision not null check (lng between -180 and 180),
  recorded_at timestamptz not null default now()
);
create index delivery_tracking_order_idx on public.delivery_tracking (order_id, recorded_at desc);

alter table public.delivery_tracking enable row level security;

create policy "tracking: same visibility as the order" on public.delivery_tracking
  for select to authenticated
  using (private.can_view_order(order_id));

create policy "tracking: assigned rider while delivering" on public.delivery_tracking
  for insert to authenticated
  with check (
    rider_id = auth.uid()
    and exists (select 1 from public.orders o
                where o.id = order_id and o.rider_id = auth.uid() and o.status = 'picked_up')
  );

commit;
