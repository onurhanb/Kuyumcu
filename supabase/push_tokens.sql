create table if not exists public.push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null unique,
  platform text not null default 'ios',
  environment text not null check (environment in ('development', 'production')),
  is_active boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists push_tokens_user_id_idx
  on public.push_tokens(user_id);

create index if not exists push_tokens_active_platform_idx
  on public.push_tokens(platform, is_active);

alter table public.push_tokens enable row level security;
