with item_points(item_name, lifestyle_points) as (
  values
    ('Espresso Makinesi', 2),
    ('Kulaklık', 2),
    ('PS6', 3),
    ('Drone', 3),
    ('Akıllı Telefon', 4),
    ('Fotoğraf Makinesi', 4),
    ('Akıllı TV (85")', 4),
    ('Laptop', 5),
    ('Akıllı Ev Sistemi', 6),
    ('Kol Saati', 7),
    ('Bisiklet', 1),
    ('Motosiklet', 2),
    ('Bütçe Araç', 3),
    ('Orta Sınıf Araç', 4),
    ('SUV', 6),
    ('Tekne', 10),
    ('Lüks Sedan', 9),
    ('Spor Araba', 12),
    ('Yat', 22),
    ('Helikopter', 32),
    ('Stüdyo Daire', 2),
    ('1+1 Daire', 3),
    ('2+1 Apartman Dairesi', 4),
    ('3+1 Geniş Daire', 5),
    ('Lüks Site Dairesi', 6),
    ('Villa', 8),
    ('Tripleks', 10),
    ('Villa Sitesi', 13),
    ('Köşk', 17),
    ('Malikane', 24),
    ('Tasarım Güneş Gözlüğü', 1),
    ('Özel Takım Elbise', 3),
    ('Lüks El Çantası', 3),
    ('Kürk Kaban', 4),
    ('Pırlanta Kolye', 5),
    ('Özel Şarap Koleksiyonu', 6),
    ('VIP Kulüp Üyeliği', 7),
    ('İsviçre Saati', 9),
    ('Sanat Eseri', 12),
    ('Private Jet Payı', 32),
    ('Yurt İçi Tatil', 2),
    ('Dalış Kursu', 3),
    ('Michelin Yıldızlı Akşam', 3),
    ('Özel Konser Koltuğu', 4),
    ('Avrupa Turu', 5),
    ('Dubai Tatili', 7),
    ('F1 Yarışı', 8),
    ('Maldivler', 10),
    ('Dünya Turu', 19),
    ('Uzay Yolculuğu', 250)
),
score_totals as (
  select
    ps.user_id,
    coalesce(sum(ip.lifestyle_points), 0) as repaired_score
  from public.player_stats ps
  left join public.lifestyle_items li
    on li.user_id = ps.user_id
  left join item_points ip
    on ip.item_name = li.item_name
  group by ps.user_id
)
update public.player_stats ps
set lifestyle_score = st.repaired_score
from score_totals st
where ps.user_id = st.user_id;

update public.daily_leaderboard_snapshots dls
set lifestyle_score = ps.lifestyle_score
from public.player_stats ps
where dls.user_id = ps.user_id;
