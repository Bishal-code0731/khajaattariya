begin;

insert into public.platform_settings (key, value) values
  ('cash_enabled',          'true'),
  ('khalti_enabled',        'true'),
  ('esewa_enabled',         'false'),
  ('stripe_enabled',        'false'),   -- Stripe is being removed (D-09)
  ('default_delivery_fee',  '30'),      -- NPR per restaurant order
  ('commission_percent',    '20'),      -- BR-04 (proposed)
  ('rider_share_percent',   '80'),      -- BR-12: rider gets this % of the delivery fee
  ('cod_cash_limit',        '5000'),    -- D-11: max cash a rider may hold
  ('min_app_version',       '1.0.0'),   -- D-16
  ('latest_app_version',    '1.0.0'),   -- D-16
  ('terms_version',         '1')        -- D-15
on conflict (key) do nothing;

insert into public.categories (name, emoji, sort_order) values
  ('Momo',         '🥟', 1),
  ('Dal Bhat',     '🍛', 2),
  ('Fast Food',    '🍔', 3),
  ('Chinese',      '🍜', 4),
  ('Indian',       '🍲', 5),
  ('Bakery',       '🧁', 6),
  ('Drinks',       '🥤', 7)
on conflict (name) do nothing;

commit;
