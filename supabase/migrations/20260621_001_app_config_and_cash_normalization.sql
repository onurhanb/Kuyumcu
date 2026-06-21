-- v1.3 rollout prep
-- 1. Adds app_config table for forced updates.
-- 2. Normalizes legacy inventory_try values to player_cash.
-- 3. Keeps inventory_try column alive temporarily for rollback compatibility.

create table if not exists public.app_config (
  id bigint primary key,
  minimum_supported_version text not null,
  latest_version text not null,
  update_message text not null,
  app_store_url text not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.app_config enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'app_config'
      and policyname = 'app_config_read_all'
  ) then
    create policy app_config_read_all
      on public.app_config
      for select
      using (true);
  end if;
end $$;

insert into public.app_config (
  id,
  minimum_supported_version,
  latest_version,
  update_message,
  app_store_url
)
values (
  1,
  '1.3',
  '1.3',
  'Veri güvenliği ve kayıt kararlılığı geliştirmeleri için uygulamayı güncelle.',
  'https://apps.apple.com/app/id0000000000'
)
on conflict (id) do nothing;

-- Audit query: run before the update below if you want to inspect mismatches.
-- select user_id, player_cash, inventory_try
-- from public.player_stats
-- where inventory_try is distinct from player_cash;

update public.player_stats
set inventory_try = player_cash
where inventory_try is distinct from player_cash;
