begin;

-- restaurants
create table public.restaurants (
  id                uuid primary key default gen_random_uuid(),
  owner_id          uuid not null references public.profiles (id) on delete cascade,
  name              text not null check (length(trim(name)) >= 2),
  image_url         text,
  cuisine_type      text not null default '',
  rating            numeric(2, 1) not null default 0,
  review_count      integer not null default 0,
  delivery_time_min integer not null default 30 check (delivery_time_min between 5 and 240),
  delivery_fee      numeric(8, 2) not null default 0 check (delivery_fee >= 0),
  is_open           boolean not null default true,
  is_featured       boolean not null default false,
  is_active         boolean not null default true,
  is_approved       boolean not null default false,
  approval_note     text,
  offer             text,
  address           text,
  phone             text,
  latitude          double precision,
  longitude         double precision,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);
create index restaurants_owner_idx on public.restaurants (owner_id);
create index restaurants_public_idx on public.restaurants (is_active, is_approved, is_featured, rating desc);

create or replace function private.owns_restaurant(p_restaurant_id uuid)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.restaurants
    where id = p_restaurant_id and owner_id = auth.uid()
  );
$$;

create or replace function private.restaurant_is_public(p_restaurant_id uuid)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.restaurants
    where id = p_restaurant_id and is_active and is_approved
  );
$$;

create or replace function private.protect_restaurant()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if not private.is_client_write() or private.is_admin() then
    return new;
  end if;
  if tg_op = 'INSERT' then
    new.owner_id      := auth.uid();
    new.is_approved   := false;
    new.is_featured   := false;
    new.is_active     := true;
    new.rating        := 0;
    new.review_count  := 0;
    new.approval_note := null;
  else
    new.owner_id      := old.owner_id;
    new.is_approved   := old.is_approved;
    new.is_featured   := old.is_featured;
    new.is_active     := old.is_active;
    new.rating        := old.rating;
    new.review_count  := old.review_count;
    new.approval_note := old.approval_note;
    new.created_at    := old.created_at;
  end if;
  return new;
end;
$$;

create trigger restaurants_protect before insert or update on public.restaurants
  for each row execute function private.protect_restaurant();
create trigger restaurants_updated_at before update on public.restaurants
  for each row execute function private.set_updated_at();

alter table public.restaurants enable row level security;

create policy "restaurants: public sees approved, owner sees own" on public.restaurants
  for select to anon, authenticated
  using ((is_active and is_approved) or owner_id = auth.uid() or private.is_admin());

create policy "restaurants: restaurant accounts register" on public.restaurants
  for insert to authenticated
  with check ((owner_id = auth.uid() and private.has_role('restaurant')) or private.is_admin());

create policy "restaurants: owner or admin updates" on public.restaurants
  for update to authenticated
  using (owner_id = auth.uid() or private.is_admin())
  with check (owner_id = auth.uid() or private.is_admin());

create policy "restaurants: admin deletes" on public.restaurants
  for delete to authenticated
  using (private.is_admin());

-- restaurant_hours (weekday 1 = Monday … 7 = Sunday)
create table public.restaurant_hours (
  id            uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants (id) on delete cascade,
  weekday       integer not null check (weekday between 1 and 7),
  is_open       boolean not null default true,
  open_time     text check (open_time is null or open_time ~ '^[0-2][0-9]:[0-5][0-9]$'),
  close_time    text check (close_time is null or close_time ~ '^[0-2][0-9]:[0-5][0-9]$'),
  unique (restaurant_id, weekday)
);

alter table public.restaurant_hours enable row level security;

create policy "hours: anyone reads" on public.restaurant_hours
  for select to anon, authenticated
  using (true);

create policy "hours: owner or admin manages" on public.restaurant_hours
  for all to authenticated
  using (private.owns_restaurant(restaurant_id) or private.is_admin())
  with check (private.owns_restaurant(restaurant_id) or private.is_admin());

-- categories (admin-managed).
create table public.categories (
  id         uuid primary key default gen_random_uuid(),
  name       text not null unique,
  emoji      text,
  icon_name  text,
  sort_order integer not null default 0,
  is_active  boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.categories enable row level security;

create policy "categories: anyone reads active" on public.categories
  for select to anon, authenticated
  using (is_active or private.is_admin());

create policy "categories: admin manages" on public.categories
  for all to authenticated
  using (private.is_admin())
  with check (private.is_admin());

-- menu_items
create table public.menu_items (
  id            uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants (id) on delete cascade,
  category_id   uuid references public.categories (id) on delete set null,
  name          text not null check (length(trim(name)) >= 1),
  description   text,
  image_url     text,
  price         numeric(8, 2) not null check (price > 0),
  is_veg        boolean not null default false,
  is_available  boolean not null default true,
  offer         text,
  sort_order    integer not null default 0,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create index menu_items_restaurant_idx on public.menu_items (restaurant_id, sort_order);
create index menu_items_category_idx on public.menu_items (category_id);

create trigger menu_items_updated_at before update on public.menu_items
  for each row execute function private.set_updated_at();

alter table public.menu_items enable row level security;

create policy "menu: public sees available items of approved restaurants" on public.menu_items
  for select to anon, authenticated
  using (
    (is_available and private.restaurant_is_public(restaurant_id))
    or private.owns_restaurant(restaurant_id)
    or private.is_admin()
  );

create policy "menu: owner or admin inserts" on public.menu_items
  for insert to authenticated
  with check (private.owns_restaurant(restaurant_id) or private.is_admin());

create policy "menu: owner or admin updates" on public.menu_items
  for update to authenticated
  using (private.owns_restaurant(restaurant_id) or private.is_admin())
  with check (private.owns_restaurant(restaurant_id) or private.is_admin());

create policy "menu: owner or admin deletes" on public.menu_items
  for delete to authenticated
  using (private.owns_restaurant(restaurant_id) or private.is_admin());

-- banners (admin-managed promos)
create table public.banners (
  id            uuid primary key default gen_random_uuid(),
  title         text not null,
  subtitle      text not null default '',
  emoji         text,
  color_hex     text not null default '#C0392B',
  image_url     text,
  restaurant_id uuid references public.restaurants (id) on delete set null,
  sort_order    integer not null default 0,
  is_active     boolean not null default true,
  created_at    timestamptz not null default now()
);

alter table public.banners enable row level security;

create policy "banners: anyone reads active" on public.banners
  for select to anon, authenticated
  using (is_active or private.is_admin());

create policy "banners: admin manages" on public.banners
  for all to authenticated
  using (private.is_admin())
  with check (private.is_admin());

-- favorites
create table public.favorites (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  restaurant_id uuid not null references public.restaurants (id) on delete cascade,
  created_at    timestamptz not null default now(),
  unique (user_id, restaurant_id)
);

alter table public.favorites enable row level security;

create policy "favorites: own" on public.favorites
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create table public.daily_sales (
  id                 uuid primary key default gen_random_uuid(),
  date               date not null,
  restaurant_id      uuid not null references public.restaurants (id) on delete cascade,
  total_orders       integer not null default 0,
  total_revenue      numeric(12, 2) not null default 0,
  total_platform_fee numeric(12, 2) not null default 0,
  created_at         timestamptz not null default now(),
  unique (date, restaurant_id)
);

alter table public.daily_sales enable row level security;

create policy "sales: owner or admin reads" on public.daily_sales
  for select to authenticated
  using (private.owns_restaurant(restaurant_id) or private.is_admin());

commit;
