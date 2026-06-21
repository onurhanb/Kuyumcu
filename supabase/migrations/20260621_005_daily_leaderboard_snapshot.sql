-- v1.3 daily leaderboard snapshot
-- Stores one leaderboard snapshot per day, refreshed with daily rates.

create table if not exists public.daily_leaderboard_snapshots (
  snapshot_date date not null,
  user_id uuid not null,
  shop_name text not null,
  total_net_worth double precision not null,
  total_cash double precision not null,
  lifestyle_score integer not null,
  updated_at timestamptz not null default timezone('utc', now()),
  primary key (snapshot_date, user_id)
);

alter table public.daily_leaderboard_snapshots enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'daily_leaderboard_snapshots'
      and policyname = 'daily_leaderboard_snapshots_read_all'
  ) then
    create policy daily_leaderboard_snapshots_read_all
      on public.daily_leaderboard_snapshots
      for select
      using (true);
  end if;
end $$;

create index if not exists daily_leaderboard_snapshots_date_networth_idx
  on public.daily_leaderboard_snapshots (snapshot_date desc, total_net_worth desc);

create or replace function public.refresh_daily_leaderboard_snapshot_v1(
  p_snapshot_date date,
  p_updated_at timestamptz,
  p_gram_buy double precision,
  p_quarter_buy double precision,
  p_half_buy double precision,
  p_full_buy double precision,
  p_usd_buy double precision,
  p_eur_buy double precision
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.daily_leaderboard_snapshots
  where snapshot_date = p_snapshot_date;

  insert into public.daily_leaderboard_snapshots (
    snapshot_date,
    user_id,
    shop_name,
    total_net_worth,
    total_cash,
    lifestyle_score,
    updated_at
  )
  select
    p_snapshot_date,
    ps.user_id,
    ps.shop_name,
    ps.player_cash
      + (ps.inventory_gram * p_gram_buy)
      + (ps.inventory_quarter * p_quarter_buy)
      + (ps.inventory_half * p_half_buy)
      + (ps.inventory_full * p_full_buy)
      + (ps.inventory_usd * p_usd_buy)
      + (ps.inventory_eur * p_eur_buy),
    ps.player_cash,
    ps.lifestyle_score,
    p_updated_at
  from public.player_stats ps;
end;
$$;

grant execute on function public.refresh_daily_leaderboard_snapshot_v1(
  date,
  timestamptz,
  double precision,
  double precision,
  double precision,
  double precision,
  double precision,
  double precision
) to service_role;

do $$
declare
  rates_row record;
  snapshot_date_tr date;
begin
  select *
  into rates_row
  from public.gold_rates
  where id = 1;

  if found then
    snapshot_date_tr := (timezone('Europe/Istanbul', now()))::date;

    perform public.refresh_daily_leaderboard_snapshot_v1(
      snapshot_date_tr,
      now(),
      rates_row.gram_buy,
      rates_row.quarter_buy,
      rates_row.half_buy,
      rates_row.full_buy,
      rates_row.usd_buy,
      rates_row.eur_buy
    );
  end if;
end $$;
