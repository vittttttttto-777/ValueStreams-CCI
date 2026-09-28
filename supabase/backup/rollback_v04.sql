-- ОТКАТ добавления потоков из предложения v0.4 (VS2C, VS6, VS7).
-- Удаляет три новых потока со всеми их шагами и ролями, возвращает VS2 прежнее название.
-- Потоки VS1–VS5 и их данные не трогает. Запуск: Supabase → SQL Editor → Run.
begin;
create or replace view public.vs_all_steps with (security_invoker = true) as
  select * from public.vs1_steps union all select * from public.vs2_steps union all select * from public.vs3_steps
  union all select * from public.vs4_steps union all select * from public.vs5_steps;
create or replace view public.vs_all_roles with (security_invoker = true) as
  select 'VS1'::text as stream_id, r.* from public.vs1_roles r
  union all select 'VS2'::text, r.* from public.vs2_roles r
  union all select 'VS3'::text, r.* from public.vs3_roles r
  union all select 'VS4'::text, r.* from public.vs4_roles r
  union all select 'VS5'::text, r.* from public.vs5_roles r;
drop table if exists public.vs2c_roles, public.vs2c_steps, public.vs6_roles, public.vs6_steps, public.vs7_roles, public.vs7_steps;
delete from public.vs_streams where id in ('VS2C','VS6','VS7');
update public.vs_streams set name = 'Формировать клиентский спрос', short_name = 'Спрос', code = 'VS2' where id = 'VS2';
update public.vs_users set label = 'Интегратор VS2 · PrimeGrowth' where id = 'vs2';
commit;
-- После отката верните на сайт прежнюю версию index.html и i18n-en.js (архив backup_code_20260928.zip).
