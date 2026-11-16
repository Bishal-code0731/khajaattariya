begin;

create or replace function private.on_support_reply()
returns trigger
language plpgsql security definer
set search_path = ''
as $$
begin
  update public.support_tickets t
  set updated_at = now(),
      status = case
                 when t.status = 'resolved' and new.actor_id = t.customer_id then 'open'
                 else t.status
               end,
      resolved_at = case
                      when t.status = 'resolved' and new.actor_id = t.customer_id then null
                      else t.resolved_at
                    end
  where t.id = new.ticket_id;
  return new;
end;
$$;

drop trigger if exists support_replies_touch_ticket on public.support_replies;
create trigger support_replies_touch_ticket after insert on public.support_replies
  for each row execute function private.on_support_reply();

grant execute on function private.on_support_reply() to anon, authenticated, service_role;

commit;
