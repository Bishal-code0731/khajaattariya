-- ============================================================
-- Khaja Attariya — Restaurant/menu image upload migration
--
-- Adds the storage bucket the app needs for restaurant logo and
-- menu-item photo uploads (previously only an `avatars` bucket
-- existed — restaurant/menu images were URL-string fields only,
-- with no in-app upload path).
--
-- Path convention (enforced by the RLS policies below):
--   logos/<owner_user_id>/logo.jpg        (keyed by the auth user, not
--                                           the restaurant row, because
--                                           the logo is uploaded during
--                                           registration BEFORE the
--                                           restaurants row exists)
--   menu-items/<restaurant_id>/<file>.jpg (keyed by restaurant, since
--                                           menu items are only ever
--                                           added to an existing one)
-- Both file_size_limit and the client-side flutter_image_compress
-- step keep uploads small and within the 1GB free-tier budget.
--
-- Safe to run once in the Supabase SQL Editor.
-- ============================================================

begin;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'restaurant-media',
  'restaurant-media',
  true, -- public read, same model as the existing avatars bucket
  1048576, -- 1MB cap per file — compression happens client-side first
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do nothing;

-- Anyone can view restaurant/menu photos (they're shown to all
-- customers browsing the app, same as the avatars bucket's read policy).
create policy "Public read restaurant media" on storage.objects
  for select using (bucket_id = 'restaurant-media');

-- Logo uploads: only the authenticated user can write into their own
-- logos/<their_user_id>/ folder — checked against auth.uid() directly
-- since this happens before any restaurants row exists.
-- Menu-item uploads: only the owner of the restaurant matching the
-- menu-items/<restaurant_id>/ folder can write there.
create policy "Restaurant owner manage own media" on storage.objects
  for all
  using (
    bucket_id = 'restaurant-media'
    and (
      ((storage.foldername(name))[1] = 'logos' and (storage.foldername(name))[2] = auth.uid()::text)
      or (
        (storage.foldername(name))[1] = 'menu-items'
        and (storage.foldername(name))[2] in (
          select id::text from public.restaurants where owner_id = auth.uid()
        )
      )
    )
  )
  with check (
    bucket_id = 'restaurant-media'
    and (
      ((storage.foldername(name))[1] = 'logos' and (storage.foldername(name))[2] = auth.uid()::text)
      or (
        (storage.foldername(name))[1] = 'menu-items'
        and (storage.foldername(name))[2] in (
          select id::text from public.restaurants where owner_id = auth.uid()
        )
      )
    )
  );

commit;
