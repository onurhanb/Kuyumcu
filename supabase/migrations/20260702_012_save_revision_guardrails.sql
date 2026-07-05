alter table public.player_stats
  add column if not exists save_revision bigint not null default 0;

update public.player_stats
set save_revision = 0
where save_revision is null;

create or replace function public.save_game_state_v1(
  p_user_id uuid,
  p_stats jsonb,
  p_owned_shops jsonb,
  p_lifestyle_items jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  affected_rows integer;
begin
  insert into public.player_stats (
    user_id,
    shop_name,
    active_shop_key,
    player_cash,
    inventory_usd,
    inventory_eur,
    inventory_gram,
    inventory_quarter,
    inventory_half,
    inventory_full,
    total_profit,
    daily_profit,
    weekly_profit,
    monthly_revenue,
    current_day,
    passive_income_balance,
    passive_income_updated_at,
    total_transactions,
    accepted_deals,
    rejected_deals,
    lifestyle_score,
    yesterday_cash,
    daily_reward_day,
    daily_reward_claimed_at,
    entry_rights_remaining,
    entry_rights_refreshed_at,
    profit_day_anchor_at,
    spin_rights_remaining,
    save_revision
  )
  values (
    p_user_id,
    p_stats->>'shop_name',
    nullif(p_stats->>'active_shop_key', ''),
    coalesce((p_stats->>'player_cash')::double precision, 0),
    coalesce((p_stats->>'inventory_usd')::double precision, 0),
    coalesce((p_stats->>'inventory_eur')::double precision, 0),
    coalesce((p_stats->>'inventory_gram')::double precision, 0),
    coalesce((p_stats->>'inventory_quarter')::double precision, 0),
    coalesce((p_stats->>'inventory_half')::double precision, 0),
    coalesce((p_stats->>'inventory_full')::double precision, 0),
    coalesce((p_stats->>'total_profit')::double precision, 0),
    coalesce((p_stats->>'daily_profit')::double precision, 0),
    coalesce((p_stats->>'weekly_profit')::double precision, 0),
    coalesce((p_stats->>'monthly_revenue')::double precision, 0),
    greatest(coalesce((p_stats->>'current_day')::integer, 1), 1),
    coalesce((p_stats->>'passive_income_balance')::double precision, 0),
    nullif(p_stats->>'passive_income_updated_at', '')::timestamptz,
    coalesce((p_stats->>'total_transactions')::integer, 0),
    coalesce((p_stats->>'accepted_deals')::integer, 0),
    coalesce((p_stats->>'rejected_deals')::integer, 0),
    coalesce((p_stats->>'lifestyle_score')::integer, 0),
    coalesce((p_stats->>'yesterday_cash')::double precision, 0),
    least(greatest(coalesce((p_stats->>'daily_reward_day')::integer, 0), 0), 7),
    nullif(p_stats->>'daily_reward_claimed_at', '')::timestamptz,
    greatest(0, least(coalesce((p_stats->>'entry_rights_remaining')::integer, 3), 3)),
    nullif(p_stats->>'entry_rights_refreshed_at', '')::timestamptz,
    nullif(p_stats->>'profit_day_anchor_at', '')::timestamptz,
    greatest(0, coalesce((p_stats->>'spin_rights_remaining')::integer, 0)),
    greatest(0, coalesce((p_stats->>'save_revision')::bigint, 0))
  )
  on conflict (user_id) do update
  set
    shop_name = excluded.shop_name,
    active_shop_key = excluded.active_shop_key,
    player_cash = excluded.player_cash,
    inventory_usd = excluded.inventory_usd,
    inventory_eur = excluded.inventory_eur,
    inventory_gram = excluded.inventory_gram,
    inventory_quarter = excluded.inventory_quarter,
    inventory_half = excluded.inventory_half,
    inventory_full = excluded.inventory_full,
    total_profit = excluded.total_profit,
    daily_profit = excluded.daily_profit,
    weekly_profit = excluded.weekly_profit,
    monthly_revenue = excluded.monthly_revenue,
    current_day = excluded.current_day,
    passive_income_balance = excluded.passive_income_balance,
    passive_income_updated_at = excluded.passive_income_updated_at,
    total_transactions = excluded.total_transactions,
    accepted_deals = excluded.accepted_deals,
    rejected_deals = excluded.rejected_deals,
    lifestyle_score = excluded.lifestyle_score,
    yesterday_cash = excluded.yesterday_cash,
    daily_reward_day = excluded.daily_reward_day,
    daily_reward_claimed_at = excluded.daily_reward_claimed_at,
    entry_rights_remaining = excluded.entry_rights_remaining,
    entry_rights_refreshed_at = excluded.entry_rights_refreshed_at,
    profit_day_anchor_at = excluded.profit_day_anchor_at,
    spin_rights_remaining = excluded.spin_rights_remaining,
    save_revision = excluded.save_revision
  where excluded.save_revision >= public.player_stats.save_revision;

  get diagnostics affected_rows = row_count;
  if affected_rows = 0 then
    return;
  end if;

  delete from public.owned_shops
  where user_id = p_user_id;

  insert into public.owned_shops (
    user_id,
    shop_key,
    shop_name,
    employee_count
  )
  select
    p_user_id,
    item->>'shop_key',
    item->>'shop_name',
    coalesce((item->>'employee_count')::integer, 0)
  from jsonb_array_elements(coalesce(p_owned_shops, '[]'::jsonb)) as item;

  delete from public.lifestyle_items
  where user_id = p_user_id;

  insert into public.lifestyle_items (
    user_id,
    item_name
  )
  select
    p_user_id,
    item->>'item_name'
  from jsonb_array_elements(coalesce(p_lifestyle_items, '[]'::jsonb)) as item;
end;
$$;

grant execute on function public.save_game_state_v1(uuid, jsonb, jsonb, jsonb) to service_role;
