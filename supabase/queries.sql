-- Полезные запросы (Supabase → SQL Editor)

-- 1. Сводная матрица «функция × поток»
select grp, function, stream_id, team, owner_steps, helper_steps, claimant_steps, no_role_steps, hypothesis_steps
from vs_matrix order by sort, stream_id;

-- 2. Матрица в развороте: одна строка на функцию, владение по потокам
select function,
  sum(owner_steps) filter (where stream_id='VS1') as vs1_owner,
  sum(owner_steps) filter (where stream_id='VS2') as vs2_owner,
  sum(owner_steps) filter (where stream_id='VS3') as vs3_owner,
  sum(owner_steps) filter (where stream_id='VS4') as vs4_owner,
  sum(owner_steps) filter (where stream_id='VS5') as vs5_owner,
  sum(total_steps) as all_steps
from vs_matrix group by sort, function order by sort;

-- 3. Все шаги со статусом ролей
select stream_id, team, position, step, owner, helpers, claimants, status, owner_metric, fixed_until
from vs_step_status order by stream_id, position;

-- 4. Реестр споров
select * from vs_disputes order by stream_id, position;

-- 5. Закреплённые роли, у которых наступила дата пересмотра
select stream_id, step, owner, owner_metric, metric_target, fixed_until, successor
from vs_step_status where review_overdue order by fixed_until;

-- 6. Шаги без владельца по потокам
select stream_id, team, count(*) as steps_without_owner
from vs_step_status where status = 'Нет владельца' group by stream_id, team order by stream_id;

-- 7. Шаги и функции, добавленные командами
select stream_id, position, step from vs_step_status where is_custom order by stream_id, position;
select id, name from vs_functions where is_custom;

-- ---------------------------------------------------------------
-- Сброс ролей перед новой сессией (осознанно, необратимо):
--   update vs1_steps set members_confirmed=false, owner_metric=null, metric_target=null,
--     fixed_until=null, successor_id=null, swap_rule=null, note=null, history='[]';   -- и так для vs2…vs5
--   delete from vs1_roles;  -- и так для vs2…vs5, затем повторить seed-миграцию
