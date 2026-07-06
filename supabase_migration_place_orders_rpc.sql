-- ============================================================
-- Khaja Attariya — place_orders RPC migration
-- Makes multi-restaurant checkout atomic: today the app inserts
-- one `orders` row + its `order_items` per restaurant group in a
-- loop from Dart, so a failure partway through (network blip,
-- RLS, bad menu_item_id) can leave an orphaned order with zero
-- items, or skip later restaurant groups entirely, while earlier
-- groups are already committed.
--
-- This wraps the whole multi-group placement in one Postgres
-- function call, which Postgres already treats as a single
-- transaction — any exception raised partway through rolls back
-- everything the call did, so it's all-or-nothing.
--
-- Safe to run once in the Supabase SQL Editor. Does not touch
-- existing data or existing RLS policies.
-- ============================================================

begin;

create or replace function place_orders(
  p_customer_id uuid,
  p_delivery_address text,
  p_notes text,
  p_delivery_fee numeric,
  -- p_groups shape: [{ "restaurant_id": uuid, "items": [{ "menu_item_id": uuid, "name": text, "price": numeric, "quantity": int, "subtotal": numeric }] }]
  p_groups jsonb
)
returns setof orders
language plpgsql
security invoker
as $$
declare
  group_rec jsonb;
  new_order orders%rowtype;
  group_subtotal numeric;
begin
  -- Defense in depth: the orders/order_items RLS policies should
  -- already enforce this, but security invoker means this function
  -- runs with the caller's own privileges, so RLS still applies to
  -- every insert below regardless of this check.
  if auth.uid() is distinct from p_customer_id then
    raise exception 'not authorized to place orders for this customer';
  end if;

  for group_rec in select * from jsonb_array_elements(p_groups)
  loop
    select coalesce(sum((item->>'subtotal')::numeric), 0)
      into group_subtotal
      from jsonb_array_elements(group_rec->'items') as item;

    insert into orders (
      customer_id, restaurant_id, total_amount, delivery_fee,
      delivery_address, notes, status
    )
    values (
      p_customer_id,
      (group_rec->>'restaurant_id')::uuid,
      group_subtotal + p_delivery_fee,
      p_delivery_fee,
      p_delivery_address,
      p_notes,
      'pending'
    )
    returning * into new_order;

    insert into order_items (order_id, menu_item_id, name, price, quantity, subtotal)
    select
      new_order.id,
      (item->>'menu_item_id')::uuid,
      item->>'name',
      (item->>'price')::numeric,
      (item->>'quantity')::int,
      (item->>'subtotal')::numeric
    from jsonb_array_elements(group_rec->'items') as item;

    return next new_order;
  end loop;

  return;
end;
$$;

grant execute on function place_orders(uuid, text, text, numeric, jsonb) to authenticated;

commit;
