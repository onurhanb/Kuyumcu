-- v1.6 pre-submit: RLS sıkılaştırma + RPC yetki kısıtlaması
--
-- v1.5 uyumluluk:
--   - Kayıt save-game-state edge function üzerinden (service_role) → yazma policy gerekmez
--   - Leaderboard daily_leaderboard_snapshots üzerinden → player_stats read-all kaldırılabilir
--   - Oyuncu kendi verisini okumaya devam eder (select own)

-- Eski gevşek policy'ler (client doğrudan yazma / herkesi okuma)
drop policy if exists "Users can manage own stats" on public.player_stats;
drop policy if exists "Users can manage own shops" on public.owned_shops;
drop policy if exists "Users can manage own lifestyle" on public.lifestyle_items;
drop policy if exists player_stats_read_all_authenticated on public.player_stats;

-- 015 select-own policy'leri (idempotent)
do $$
begin
  alter table public.player_stats enable row level security;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'player_stats' and policyname = 'player_stats_select_own'
  ) then
    create policy player_stats_select_own
      on public.player_stats for select to authenticated
      using (auth.uid() = user_id);
  end if;

  alter table public.owned_shops enable row level security;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'owned_shops' and policyname = 'owned_shops_select_own'
  ) then
    create policy owned_shops_select_own
      on public.owned_shops for select to authenticated
      using (auth.uid() = user_id);
  end if;

  alter table public.lifestyle_items enable row level security;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'lifestyle_items' and policyname = 'lifestyle_items_select_own'
  ) then
    create policy lifestyle_items_select_own
      on public.lifestyle_items for select to authenticated
      using (auth.uid() = user_id);
  end if;
end $$;

-- SECURITY DEFINER RPC'ler yalnızca service_role tarafından çağrılabilsin
revoke all on function public.save_game_state_v1(uuid, jsonb, jsonb, jsonb) from public, anon, authenticated;
grant execute on function public.save_game_state_v1(uuid, jsonb, jsonb, jsonb) to service_role;

revoke all on function public.refresh_daily_leaderboard_snapshot_v1(
  date, timestamp with time zone, double precision, double precision,
  double precision, double precision, double precision, double precision
) from public, anon, authenticated;
grant execute on function public.refresh_daily_leaderboard_snapshot_v1(
  date, timestamp with time zone, double precision, double precision,
  double precision, double precision, double precision, double precision
) to service_role;

-- delete_user_data 017 ile birlikte oluşturulur; varsa revoke uygula
do $$
begin
  if exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'delete_user_data'
  ) then
    revoke all on function public.delete_user_data(uuid) from public, anon, authenticated;
    grant execute on function public.delete_user_data(uuid) to service_role;
  end if;
end $$;
