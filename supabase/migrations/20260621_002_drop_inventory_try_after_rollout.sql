-- Run only after v1.3 is fully rolled out and save-game-state has been stable in production.

alter table public.player_stats
  drop column if exists inventory_try;
