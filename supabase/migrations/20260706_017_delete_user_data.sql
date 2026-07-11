-- v1.6 delete-account: kullanıcı verisini tek transaction'da sil
--
-- Bağlam: delete-account edge function'ı 4 ayrı DELETE'i Promise.all ile çalıştırıyordu.
-- Ortada biri başarısız olursa hesap YARIM silinir ("zombi kayıtlar"). Bu RPC tüm
-- silmeleri tek plpgsql gövdesinde (= tek transaction) yapar: ya hepsi, ya hiçbiri.
--
-- Not: Auth kullanıcısı (GoTrue) ayrı bir sistemdir, aynı DB transaction'ına dahil
-- edilemez. Edge function önce bu RPC'yi (oyun verisi), sonra auth kullanıcısını siler.
-- Böylece KVKK/GDPR "silme hakkı" için oyun verisi kesin temizlenir.

create or replace function public.delete_user_data(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.lifestyle_items               where user_id = p_user_id;
  delete from public.owned_shops                   where user_id = p_user_id;
  delete from public.push_tokens                   where user_id = p_user_id;
  delete from public.daily_leaderboard_snapshots   where user_id = p_user_id;
  delete from public.social_feed_player_snapshots  where user_id = p_user_id;
  delete from public.player_stats                  where user_id = p_user_id;
end;
$$;

grant execute on function public.delete_user_data(uuid) to service_role;
