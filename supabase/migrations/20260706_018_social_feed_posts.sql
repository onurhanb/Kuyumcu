-- v1.6 social feed posts
--
-- Oyun içi sosyal medya akışı. Otomatik postlar service_role edge function ile
-- üretilir; manuel duyurular Supabase SQL editor üzerinden eklenebilir.

create table if not exists public.social_feed_posts (
  id uuid primary key default gen_random_uuid(),
  post_type text not null,
  author_name text not null,
  author_handle text not null,
  author_avatar_key text not null default 'kuyumcu_guncel',
  body text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  published_at timestamptz not null default timezone('utc', now()),
  expires_at timestamptz
);

alter table public.social_feed_posts enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'social_feed_posts'
      and policyname = 'social_feed_posts_read_published'
  ) then
    create policy social_feed_posts_read_published
      on public.social_feed_posts
      for select
      using (
        published_at <= timezone('utc', now())
        and (expires_at is null or expires_at > timezone('utc', now()))
      );
  end if;
end $$;

create index if not exists social_feed_posts_published_idx
  on public.social_feed_posts (published_at desc);

create unique index if not exists social_feed_posts_daily_recap_date_idx
  on public.social_feed_posts (post_type, ((metadata->>'feed_date')))
  where post_type = 'daily_recap' and metadata ? 'feed_date';
