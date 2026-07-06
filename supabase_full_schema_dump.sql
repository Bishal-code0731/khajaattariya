-- ============================================================
-- Khaja Attariya — full Supabase schema/config dump
--
-- Paste this into the Supabase SQL Editor and run it. It returns ONE
-- row with a single JSON column containing everything needed to
-- cross-verify the database against the app code: every table +
-- column + type, every RLS policy, every storage bucket + its
-- policies, every trigger, and every custom function.
--
-- Copy the JSON result and paste it back — that's enough to check it
-- against what the Dart models/providers/migrations expect.
-- ============================================================

select jsonb_build_object(

  'tables', (
    select jsonb_agg(jsonb_build_object(
      'table', t.table_name,
      'columns', (
        select jsonb_agg(jsonb_build_object(
          'name', c.column_name,
          'type', c.data_type,
          'nullable', c.is_nullable,
          'default', c.column_default
        ) order by c.ordinal_position)
        from information_schema.columns c
        where c.table_schema = 'public' and c.table_name = t.table_name
      ),
      'row_count_estimate', (
        select reltuples::bigint
        from pg_class
        where relname = t.table_name
      )
    ) order by t.table_name)
    from information_schema.tables t
    where t.table_schema = 'public' and t.table_type = 'BASE TABLE'
  ),

  'rls_enabled', (
    select jsonb_object_agg(c.relname, c.relrowsecurity)
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind = 'r'
  ),

  'rls_policies', (
    select jsonb_agg(jsonb_build_object(
      'table', tablename,
      'policy', policyname,
      'command', cmd,
      'roles', roles,
      'using', qual,
      'with_check', with_check
    ) order by tablename, policyname)
    from pg_policies
    where schemaname = 'public'
  ),

  'storage_buckets', (
    select jsonb_agg(jsonb_build_object(
      'id', id,
      'public', public,
      'file_size_limit', file_size_limit,
      'allowed_mime_types', allowed_mime_types
    ) order by id)
    from storage.buckets
  ),

  'storage_policies', (
    select jsonb_agg(jsonb_build_object(
      'policy', policyname,
      'command', cmd,
      'using', qual,
      'with_check', with_check
    ) order by policyname)
    from pg_policies
    where schemaname = 'storage' and tablename = 'objects'
  ),

  'functions', (
    select jsonb_agg(jsonb_build_object(
      'name', p.proname,
      'returns', pg_get_function_result(p.oid),
      'args', pg_get_function_arguments(p.oid)
    ) order by p.proname)
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
  ),

  'triggers', (
    select jsonb_agg(jsonb_build_object(
      'table', event_object_table,
      'trigger', trigger_name,
      'event', event_manipulation,
      'timing', action_timing
    ) order by event_object_table, trigger_name)
    from information_schema.triggers
    where trigger_schema = 'public'
  ),

  'realtime_publications', (
    select jsonb_agg(tablename order by tablename)
    from pg_publication_tables
    where pubname = 'supabase_realtime'
  )

) as full_schema_dump;
