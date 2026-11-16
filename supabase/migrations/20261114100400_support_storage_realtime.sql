-- Khaja Attariya — 5/5 Support, storage, realtime, access rights, clean-up
begin;

create table public.support_tickets (
  id          uuid primary key default gen_random_uuid(),
  customer_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  order_id    uuid references public.orders (id) on delete set null,
  subject     text not null check (length(trim(subject)) between 3 and 200),
  message     text not null check (length(trim(message)) between 1 and 5000),
  status      text not null default 'open' check (status in ('open', 'in_progress', 'resolved', 'closed')),
  priority    text not null default 'normal' check (priority in ('low', 'normal', 'high', 'urgent')),
  assigned_to uuid references public.profiles (id) on delete set null,
  resolved_at timestamptz,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index support_tickets_customer_idx on public.support_tickets (customer_id, created_at desc);
create index support_tickets_status_idx on public.support_tickets (status, created_at desc);

create or replace function private.protect_ticket()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if not private.is_client_write() or private.is_admin() then
    return new;
  end if;
  new.customer_id := auth.uid();
  new.status      := 'open';
  new.priority    := 'normal';
  new.assigned_to := null;
  new.resolved_at := null;
  return new;
end;
$$;

create trigger support_tickets_protect before insert on public.support_tickets
  for each row execute function private.protect_ticket();
create trigger support_tickets_updated_at before update on public.support_tickets
  for each row execute function private.set_updated_at();

alter table public.support_tickets enable row level security;

create policy "tickets: own or admin reads" on public.support_tickets
  for select to authenticated
  using (customer_id = auth.uid() or private.is_admin());

create policy "tickets: users open their own" on public.support_tickets
  for insert to authenticated
  with check (customer_id = auth.uid());

create policy "tickets: admin updates" on public.support_tickets
  for update to authenticated
  using (private.is_admin())
  with check (private.is_admin());

create table public.support_replies (
  id          uuid primary key default gen_random_uuid(),
  ticket_id   uuid not null references public.support_tickets (id) on delete cascade,
  actor_id    uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  message     text not null check (length(trim(message)) between 1 and 5000),
  is_internal boolean not null default false,
  created_at  timestamptz not null default now()
);
create index support_replies_ticket_idx on public.support_replies (ticket_id, created_at);

alter table public.support_replies enable row level security;

create policy "replies: ticket owner (public replies) or admin reads" on public.support_replies
  for select to authenticated
  using (
    private.is_admin()
    or (not is_internal and exists (select 1 from public.support_tickets t
                                    where t.id = ticket_id and t.customer_id = auth.uid()))
  );

create policy "replies: ticket owner or admin writes" on public.support_replies
  for insert to authenticated
  with check (
    actor_id = auth.uid()
    and (private.is_admin()
         or (not is_internal and exists (select 1 from public.support_tickets t
                                         where t.id = ticket_id and t.customer_id = auth.uid())))
  );

-- Storage buckets (public images, size and type limited)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars', 'avatars', true, 2097152, array['image/jpeg', 'image/png', 'image/webp']),
  ('restaurant-media', 'restaurant-media', true, 1048576, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- Remove old and new policy names so this file can be re-run.
drop policy if exists "Avatar images are publicly accessible" on storage.objects;
drop policy if exists "Users upload own avatar" on storage.objects;
drop policy if exists "Users update own avatar" on storage.objects;
drop policy if exists "Users delete own avatar" on storage.objects;
drop policy if exists "Public read restaurant media" on storage.objects;
drop policy if exists "Restaurant owner manage own media" on storage.objects;
drop policy if exists "avatars: public read" on storage.objects;
drop policy if exists "avatars: owner writes own folder" on storage.objects;
drop policy if exists "avatars: owner updates own folder" on storage.objects;
drop policy if exists "avatars: owner deletes own folder" on storage.objects;
drop policy if exists "restaurant-media: public read" on storage.objects;
drop policy if exists "restaurant-media: owner writes" on storage.objects;
drop policy if exists "restaurant-media: owner updates" on storage.objects;
drop policy if exists "restaurant-media: owner deletes" on storage.objects;

-- avatars/<user_id>/avatar.<ext>
create policy "avatars: public read" on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'avatars');

create policy "avatars: owner writes own folder" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "avatars: owner updates own folder" on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "avatars: owner deletes own folder" on storage.objects
  for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

-- restaurant-media/logos/<owner_user_id>/...
create or replace function private.can_write_restaurant_media(p_name text)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select private.is_admin()
      or ((storage.foldername(p_name))[1] = 'logos'
          and (storage.foldername(p_name))[2] = auth.uid()::text)
      or ((storage.foldername(p_name))[1] = 'menu-items'
          and exists (select 1 from public.restaurants r
                      where r.id::text = (storage.foldername(p_name))[2]
                        and r.owner_id = auth.uid()));
$$;

create policy "restaurant-media: public read" on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'restaurant-media');

create policy "restaurant-media: owner writes" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'restaurant-media' and private.can_write_restaurant_media(name));

create policy "restaurant-media: owner updates" on storage.objects
  for update to authenticated
  using (bucket_id = 'restaurant-media' and private.can_write_restaurant_media(name))
  with check (bucket_id = 'restaurant-media' and private.can_write_restaurant_media(name));

create policy "restaurant-media: owner deletes" on storage.objects
  for delete to authenticated
  using (bucket_id = 'restaurant-media' and private.can_write_restaurant_media(name));

-- Realtime: only tables the app watches live
do $$
declare
  t text;
begin
  foreach t in array array['orders', 'order_timeline', 'notifications', 'favorites',
                           'addresses', 'delivery_tracking', 'riders']
  loop
    if not exists (select 1 from pg_publication_tables
                   where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end;
$$;

-- Access rights (S-24): RLS stays the main gate, but remove what no client ever needs.
revoke all on all tables in schema public from anon;
revoke truncate, references, trigger on all tables in schema public from authenticated;

grant select on public.restaurants, public.restaurant_hours, public.categories,
                public.menu_items, public.banners, public.ratings, public.platform_settings
  to anon;

-- Functions: only place_orders (and the legacy no-op) are callable by the app.
revoke execute on all functions in schema public from public, anon, authenticated;
grant execute on function public.place_orders(uuid, text, text, numeric, jsonb) to authenticated;
grant execute on function public.increment_coupon_uses(uuid) to authenticated;

grant execute on all functions in schema private to anon, authenticated, service_role;

-- Free-plan housekeeping (docs/05 §13 5.1).
create or replace function private.cleanup_old_rows()
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  v_tracking      integer;
  v_notifications integer;
begin
  delete from public.delivery_tracking dt
  using public.orders o
  where o.id = dt.order_id
    and o.status in ('delivered', 'cancelled')
    and o.updated_at < now() - interval '7 days';
  get diagnostics v_tracking = row_count;

  delete from public.notifications
  where is_read and created_at < now() - interval '90 days';
  get diagnostics v_notifications = row_count;

  return jsonb_build_object('delivery_tracking_deleted', v_tracking,
                            'notifications_deleted', v_notifications);
end;
$$;
revoke execute on function private.cleanup_old_rows() from public, anon, authenticated;

commit;
