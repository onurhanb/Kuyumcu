-- v1.6 social feed player metric snapshots
--
-- Social feed günlük özetinin gerçek günlük işlem/red değerleri üretmesi için
-- birikimli player_stats sayaçlarını her çalışma anında snapshot'lar.

create table if not exists public.social_feed_player_snapshots (
  snapshot_date date not null,
  user_id uuid not null,
  shop_name text not null,
  total_profit double precision not null default 0,
  daily_profit double precision not null default 0,
  total_transactions integer not null default 0,
  rejected_deals integer not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (snapshot_date, user_id)
);

alter table public.social_feed_player_snapshots enable row level security;

create index if not exists social_feed_player_snapshots_date_idx
  on public.social_feed_player_snapshots (snapshot_date desc);

create index if not exists social_feed_player_snapshots_user_date_idx
  on public.social_feed_player_snapshots (user_id, snapshot_date desc);
