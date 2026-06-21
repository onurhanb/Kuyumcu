-- v1.3 stable shop identity rollout
-- Adds stable key columns for owned shops and active shop restore.

alter table public.player_stats
  add column if not exists active_shop_key text;

alter table public.owned_shops
  add column if not exists shop_key text;

update public.owned_shops
set shop_key = case shop_name
  when 'Mahalle Kuyumcusu' then 'neighborhood_shop'
  when 'Çarşı Kuyumcusu' then 'bazaar_shop'
  when 'İlçe Kuyumcusu' then 'district_bazaar_shop'
  when 'Şehir Merkezi Kuyumcusu' then 'city_center_shop'
  when 'AVM Kuyumcusu' then 'mall_shop'
  when 'Kapalıçarşı Kuyumcusu' then 'grand_bazaar_shop'
  else shop_key
end
where shop_key is null;

update public.player_stats
set active_shop_key = 'neighborhood_shop'
where active_shop_key is null;

alter table public.owned_shops
  alter column shop_key set not null;
