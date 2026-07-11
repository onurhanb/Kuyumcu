-- 30-day price history for inventory trend chart

create table if not exists public.gold_rate_history (
  snapshot_date date primary key,
  gram_buy double precision not null,
  quarter_buy double precision not null,
  half_buy double precision not null,
  full_buy double precision not null,
  usd_buy double precision not null,
  eur_buy double precision not null,
  source_name text not null default 'truncgil.com',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.touch_gold_rate_history_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_touch_gold_rate_history_updated_at on public.gold_rate_history;

create trigger trg_touch_gold_rate_history_updated_at
before update on public.gold_rate_history
for each row execute function public.touch_gold_rate_history_updated_at();

alter table public.gold_rate_history enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'gold_rate_history'
      and policyname = 'gold_rate_history_select_all'
  ) then
    create policy gold_rate_history_select_all
      on public.gold_rate_history
      for select
      using (true);
  end if;
end $$;
