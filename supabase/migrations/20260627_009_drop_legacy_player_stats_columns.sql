-- Post-v1.3 rollout cleanup:
-- remove columns no longer used by app/runtime/save path.

alter table public.player_stats
  drop column if exists inventory_try,
  drop column if exists customer_satisfaction,
  drop column if exists trust_score;
