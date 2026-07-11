-- Prevent creation of new placeholder shop names while keeping legacy
-- placeholder accounts functional until the v1.7 forced rename flow ships.

create or replace function public.guard_player_stats_shop_name()
returns trigger
language plpgsql
as $$
begin
  new.shop_name := btrim(coalesce(new.shop_name, ''));

  if new.shop_name = '' then
    raise exception 'shop_name_required' using errcode = '23514';
  end if;

  if lower(new.shop_name) = lower('Misafir') then
    if tg_op = 'INSERT' then
      raise exception 'reserved_shop_name' using errcode = '23514';
    end if;

    -- Allow legacy placeholder accounts to keep saving with the same
    -- placeholder name until they rename in v1.7.
    if tg_op = 'UPDATE'
       and lower(coalesce(old.shop_name, '')) <> lower('Misafir') then
      raise exception 'reserved_shop_name' using errcode = '23514';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_guard_player_stats_shop_name on public.player_stats;

create trigger trg_guard_player_stats_shop_name
before insert or update of shop_name on public.player_stats
for each row execute function public.guard_player_stats_shop_name();
