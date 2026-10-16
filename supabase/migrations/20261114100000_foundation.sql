begin;

-- Private schema: helper + trigger functions.
create schema if not exists private;
grant usage on schema private to anon, authenticated, service_role;

create or replace function private.is_client_write()
returns boolean
language sql stable
set search_path = ''
as $$
  select current_user in ('anon', 'authenticated');
$$;

create or replace function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- profiles
create table public.profiles (
  id                uuid primary key references auth.users (id) on delete cascade,
  full_name         text not null default '',
  phone             text,
  role              text not null default 'customer'
                    check (role in ('customer', 'restaurant', 'rider', 'admin')),
  avatar_url        text,
  is_active         boolean not null default true,
  fcm_token         text,
  terms_version     text,
  terms_accepted_at timestamptz,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);
create index profiles_role_idx on public.profiles (role);

-- Role helpers (SECURITY DEFINER so they can read profiles without tripping over profiles' own RLS).
create or replace function private.is_admin()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin' and is_active
  );
$$;

create or replace function private.has_role(p_role text)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = p_role and is_active
  );
$$;

create or replace function private.is_active_user()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (select 1 from public.profiles where id = auth.uid() and is_active);
$$;

-- Signup: create the profile.
create or replace function private.handle_new_user()
returns trigger
language plpgsql security definer
set search_path = ''
as $$
declare
  v_role text := new.raw_user_meta_data ->> 'role';
begin
  insert into public.profiles (id, full_name, phone, role, terms_version, terms_accepted_at)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''), ''),
    nullif(trim(new.raw_user_meta_data ->> 'phone'), ''),
    case when v_role in ('customer', 'restaurant', 'rider') then v_role else 'customer' end,
    new.raw_user_meta_data ->> 'terms_version',
    case when new.raw_user_meta_data ? 'terms_version' then now() end
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();

-- Users can edit their own profile, but never their role or active flag.
create or replace function private.protect_profile()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if not private.is_client_write() or private.is_admin() then
    return new;
  end if;
  new.id         := old.id;
  new.role       := old.role;
  new.is_active  := old.is_active;
  new.created_at := old.created_at;
  return new;
end;
$$;

create trigger profiles_protect before update on public.profiles
  for each row execute function private.protect_profile();
create trigger profiles_updated_at before update on public.profiles
  for each row execute function private.set_updated_at();

alter table public.profiles enable row level security;

create policy "profiles: read own or admin" on public.profiles
  for select to authenticated
  using (id = auth.uid() or private.is_admin());

create policy "profiles: update own or admin" on public.profiles
  for update to authenticated
  using (id = auth.uid() or private.is_admin())
  with check (id = auth.uid() or private.is_admin());

-- platform_settings (key/value, non-secret configuration only)
create table public.platform_settings (
  key        text primary key,
  value      text not null,
  updated_by uuid references public.profiles (id) on delete set null,
  updated_at timestamptz not null default now()
);

create trigger platform_settings_updated_at before update on public.platform_settings
  for each row execute function private.set_updated_at();

alter table public.platform_settings enable row level security;

create policy "settings: anyone can read" on public.platform_settings
  for select to anon, authenticated
  using (true);

create policy "settings: admin manages" on public.platform_settings
  for all to authenticated
  using (private.is_admin())
  with check (private.is_admin());

-- Numeric setting with a fallback when missing or not a number.
create or replace function private.setting_numeric(p_key text, p_default numeric)
returns numeric
language plpgsql stable security definer
set search_path = ''
as $$
declare
  v_value text;
begin
  select value into v_value from public.platform_settings where key = p_key;
  if v_value is null or v_value !~ '^\s*-?[0-9]+(\.[0-9]+)?\s*$' then
    return p_default;
  end if;
  return trim(v_value)::numeric;
end;
$$;

-- audit_logs (admin actions)
create table public.audit_logs (
  id           uuid primary key default gen_random_uuid(),
  actor_id     uuid default auth.uid() references public.profiles (id) on delete set null,
  action       text not null,
  target_table text,
  target_id    text,
  old_data     jsonb,
  new_data     jsonb,
  ip_address   text,
  created_at   timestamptz not null default now()
);
create index audit_logs_actor_idx on public.audit_logs (actor_id);
create index audit_logs_created_idx on public.audit_logs (created_at desc);

alter table public.audit_logs enable row level security;

create policy "audit: admin reads" on public.audit_logs
  for select to authenticated
  using (private.is_admin());

create policy "audit: admin writes own entries" on public.audit_logs
  for insert to authenticated
  with check (private.is_admin() and actor_id = auth.uid());

-- notifications (written only by the server — triggers / functions)
create table public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  title      text not null,
  body       text not null,
  type       text not null default 'system',
  order_id   uuid,  -- FK added in migration 4 (orders)
  is_read    boolean not null default false,
  created_at timestamptz not null default now()
);
create index notifications_user_idx on public.notifications (user_id, created_at desc);

-- Users may only flip is_read on their own notifications.
create or replace function private.protect_notification()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if not private.is_client_write() then
    return new;
  end if;
  new.id         := old.id;
  new.user_id    := old.user_id;
  new.title      := old.title;
  new.body       := old.body;
  new.type       := old.type;
  new.order_id   := old.order_id;
  new.created_at := old.created_at;
  return new;
end;
$$;

create trigger notifications_protect before update on public.notifications
  for each row execute function private.protect_notification();

alter table public.notifications enable row level security;

create policy "notifications: read own" on public.notifications
  for select to authenticated
  using (user_id = auth.uid());

create policy "notifications: mark own read" on public.notifications
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "notifications: delete own" on public.notifications
  for delete to authenticated
  using (user_id = auth.uid());

-- Server-side helper used by triggers to notify a user.
create or replace function private.notify(p_user uuid, p_title text, p_body text, p_type text, p_order uuid)
returns void
language sql security definer
set search_path = ''
as $$
  insert into public.notifications (user_id, title, body, type, order_id)
  select p_user, p_title, p_body, p_type, p_order
  where p_user is not null;
$$;

commit;
