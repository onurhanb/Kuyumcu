with ranked_events as (
    select
        id,
        row_number() over (
            order by id desc
        ) as row_num
    from public.game_events
    where is_active = true
)
update public.game_events as ge
set is_active = false
from ranked_events
where ge.id = ranked_events.id
  and ranked_events.row_num > 1;

create unique index if not exists game_events_single_active_idx
on public.game_events ((is_active))
where is_active = true;
