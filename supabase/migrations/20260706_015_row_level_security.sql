-- v1.4 Row Level Security hardening
--
-- Bağlam: player_stats / owned_shops / lifestyle_items tablolarında RLS yoktu;
-- publishable (anon) key ile REST API'ye erişen herkes TÜM oyuncuların verisini
-- okuyabiliyordu. Bu migration RLS'i açar ve yalnızca "kendi satırını okuma"
-- policy'si ekler.
--
-- Yazma (INSERT/UPDATE/DELETE) için BİLEREK policy verilmez:
--   - Oyun verisi yalnızca `save_game_state_v1` (SECURITY DEFINER, service_role)
--     RPC'si üzerinden yazılır; service_role RLS'i bypass eder.
--   - Böylece client, RPC'yi atlayıp tablolara doğrudan yazamaz (cheat koruması).
--
-- gold_rates / game_events kullanıcıya bağlı değildir; herkese açık okuma (public read)
-- kalır, yazma yine service_role edge function'larından yapılır.

-- Yardımcı: policy'yi yalnızca yoksa oluştur (idempotent, tekrar çalıştırılabilir)
do $$
begin
  ---------------------------------------------------------------------------
  -- player_stats: sadece kendi satırını okuma
  ---------------------------------------------------------------------------
  alter table public.player_stats enable row level security;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'player_stats'
      and policyname = 'player_stats_select_own'
  ) then
    create policy player_stats_select_own
      on public.player_stats
      for select
      to authenticated
      using (auth.uid() = user_id);
  end if;

  ---------------------------------------------------------------------------
  -- owned_shops: sadece kendi satırlarını okuma
  ---------------------------------------------------------------------------
  alter table public.owned_shops enable row level security;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'owned_shops'
      and policyname = 'owned_shops_select_own'
  ) then
    create policy owned_shops_select_own
      on public.owned_shops
      for select
      to authenticated
      using (auth.uid() = user_id);
  end if;

  ---------------------------------------------------------------------------
  -- lifestyle_items: sadece kendi satırlarını okuma
  ---------------------------------------------------------------------------
  alter table public.lifestyle_items enable row level security;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'lifestyle_items'
      and policyname = 'lifestyle_items_select_own'
  ) then
    create policy lifestyle_items_select_own
      on public.lifestyle_items
      for select
      to authenticated
      using (auth.uid() = user_id);
  end if;

  ---------------------------------------------------------------------------
  -- gold_rates: herkese açık okuma (kur bilgisi kamuya açık)
  ---------------------------------------------------------------------------
  alter table public.gold_rates enable row level security;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'gold_rates'
      and policyname = 'gold_rates_select_all'
  ) then
    create policy gold_rates_select_all
      on public.gold_rates
      for select
      using (true);
  end if;

  ---------------------------------------------------------------------------
  -- game_events: herkese açık okuma (aktif etkinlikler herkes için aynı)
  ---------------------------------------------------------------------------
  alter table public.game_events enable row level security;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'game_events'
      and policyname = 'game_events_select_all'
  ) then
    create policy game_events_select_all
      on public.game_events
      for select
      using (true);
  end if;
end $$;
