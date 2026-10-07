-- ПОЛНЫЙ ОТКАТ данных стратсессии к снимку backup_20260930 (30.09.2026, ~09:00 МСК).
-- Часть А — «Потоки создания ценности» (8 потоков: шаги, роли, KPI, паспорта, справочник функций, горячие точки, переводы).
-- Часть Б — инструменты дней стратсессии в той же базе: деревья метрик (strat3_trees + история)
--           и реестр процессов/полномочий (strat3_d3_*: процессы, функции, связи, документы, история).
-- Пароли, PIN и ключи (vs_users, strat3_admin, strat3_*_secret) НЕ трогаются: входы остаются прежними.
-- Запуск: Supabase → SQL Editor → вставить целиком → Run. Одна транзакция: при ошибке ничего не изменится.
-- Нужна только одна часть? Удалите блок другой части между метками «-- А» и «-- Б».
begin;

-- А. Потоки создания ценности
truncate public.vs1_roles, public.vs2_roles, public.vs2c_roles, public.vs3_roles, public.vs4_roles, public.vs5_roles, public.vs6_roles, public.vs7_roles,
         public.vs1_steps, public.vs2_steps, public.vs2c_steps, public.vs3_steps, public.vs4_steps, public.vs5_steps, public.vs6_steps, public.vs7_steps,
         public.vs_functions, public.vs_hot_points, public.vs_i18n;
insert into public.vs_streams (id, team, tier, name, short_name, trigger_text, output, flow_object, recipient, value, kpi, industry_functions, handoff, sort, change_log, updated_at, code, origin) select id, team, tier, name, short_name, trigger_text, output, flow_object, recipient, value, kpi, industry_functions, handoff, sort, change_log, updated_at, code, origin from backup_20260930.vs_streams
  on conflict (id) do update set team = excluded.team, tier = excluded.tier, name = excluded.name, short_name = excluded.short_name, trigger_text = excluded.trigger_text, output = excluded.output, flow_object = excluded.flow_object, recipient = excluded.recipient, value = excluded.value, kpi = excluded.kpi, industry_functions = excluded.industry_functions, handoff = excluded.handoff, sort = excluded.sort, change_log = excluded.change_log, updated_at = excluded.updated_at, code = excluded.code, origin = excluded.origin;
insert into public.vs_functions (id, name, name_en, grp, sort, is_custom, active, created_at, updated_at, fn_type, fn_type_note) select id, name, name_en, grp, sort, is_custom, active, created_at, updated_at, fn_type, fn_type_note from backup_20260930.vs_functions;
insert into public.vs_hot_points (id, description) select id, description from backup_20260930.vs_hot_points;
insert into public.vs1_steps (id, stream_id, position, name, content, result, is_custom, active, members_confirmed, hot_points, gap_note, owner_metric, metric_target, fixed_until, successor_id, swap_rule, note, history, updated_at) select id, stream_id, position, name, content, result, is_custom, active, members_confirmed, hot_points, gap_note, owner_metric, metric_target, fixed_until, successor_id, swap_rule, note, history, updated_at from backup_20260930.vs1_steps;
insert into public.vs2_steps (id, stream_id, position, name, content, result, is_custom, active, members_confirmed, hot_points, gap_note, owner_metric, metric_target, fixed_until, successor_id, swap_rule, note, history, updated_at) select id, stream_id, position, name, content, result, is_custom, active, members_confirmed, hot_points, gap_note, owner_metric, metric_target, fixed_until, successor_id, swap_rule, note, history, updated_at from backup_20260930.vs2_steps;
insert into public.vs2c_steps (id, stream_id, position, name, content, result, is_custom, active, members_confirmed, hot_points, gap_note, owner_metric, metric_target, fixed_until, successor_id, swap_rule, note, history, updated_at) select id, stream_id, position, name, content, result, is_custom, active, members_confirmed, hot_points, gap_note, owner_metric, metric_target, fixed_until, successor_id, swap_rule, note, history, updated_at from backup_20260930.vs2c_steps;
insert into public.vs3_steps (id, stream_id, position, name, content, result, is_custom, active, members_confirmed, hot_points, gap_note, owner_metric, metric_target, fixed_until, successor_id, swap_rule, note, history, updated_at) select id, stream_id, position, name, content, result, is_custom, active, members_confirmed, hot_points, gap_note, owner_metric, metric_target, fixed_until, successor_id, swap_rule, note, history, updated_at from backup_20260930.vs3_steps;
insert into public.vs4_steps (id, stream_id, position, name, content, result, is_custom, active, members_confirmed, hot_points, gap_note, owner_metric, metric_target, fixed_until, successor_id, swap_rule, note, history, updated_at) select id, stream_id, position, name, content, result, is_custom, active, members_confirmed, hot_points, gap_note, owner_metric, metric_target, fixed_until, successor_id, swap_rule, note, history, updated_at from backup_20260930.vs4_steps;
insert into public.vs5_steps (id, stream_id, position, name, content, result, is_custom, active, members_confirmed, hot_points, gap_note, owner_metric, metric_target, fixed_until, successor_id, swap_rule, note, history, updated_at) select id, stream_id, position, name, content, result, is_custom, active, members_confirmed, hot_points, gap_note, owner_metric, metric_target, fixed_until, successor_id, swap_rule, note, history, updated_at from backup_20260930.vs5_steps;
insert into public.vs6_steps (id, stream_id, position, name, content, result, is_custom, active, members_confirmed, hot_points, gap_note, owner_metric, metric_target, fixed_until, successor_id, swap_rule, note, history, updated_at) select id, stream_id, position, name, content, result, is_custom, active, members_confirmed, hot_points, gap_note, owner_metric, metric_target, fixed_until, successor_id, swap_rule, note, history, updated_at from backup_20260930.vs6_steps;
insert into public.vs7_steps (id, stream_id, position, name, content, result, is_custom, active, members_confirmed, hot_points, gap_note, owner_metric, metric_target, fixed_until, successor_id, swap_rule, note, history, updated_at) select id, stream_id, position, name, content, result, is_custom, active, members_confirmed, hot_points, gap_note, owner_metric, metric_target, fixed_until, successor_id, swap_rule, note, history, updated_at from backup_20260930.vs7_steps;
insert into public.vs1_roles (step_id, function_id, role, updated_at) select step_id, function_id, role, updated_at from backup_20260930.vs1_roles;
insert into public.vs2_roles (step_id, function_id, role, updated_at) select step_id, function_id, role, updated_at from backup_20260930.vs2_roles;
insert into public.vs2c_roles (step_id, function_id, role, updated_at) select step_id, function_id, role, updated_at from backup_20260930.vs2c_roles;
insert into public.vs3_roles (step_id, function_id, role, updated_at) select step_id, function_id, role, updated_at from backup_20260930.vs3_roles;
insert into public.vs4_roles (step_id, function_id, role, updated_at) select step_id, function_id, role, updated_at from backup_20260930.vs4_roles;
insert into public.vs5_roles (step_id, function_id, role, updated_at) select step_id, function_id, role, updated_at from backup_20260930.vs5_roles;
insert into public.vs6_roles (step_id, function_id, role, updated_at) select step_id, function_id, role, updated_at from backup_20260930.vs6_roles;
insert into public.vs7_roles (step_id, function_id, role, updated_at) select step_id, function_id, role, updated_at from backup_20260930.vs7_roles;
insert into public.vs_i18n (src, en, ru, updated_at) select src, en, ru, updated_at from backup_20260930.vs_i18n;

-- Б. Деревья метрик и реестр процессов
alter table public.strat3_d3_docs disable trigger strat3_d3_log_trg;
truncate public.strat3_trees, public.strat3_tree_history, public.strat3_state, public.strat3_d3_docs, public.strat3_d3_history, public.strat3_d3_functions, public.strat3_d3_processes, public.strat3_d3_process_functions;
insert into public.strat3_trees select * from backup_20260930.strat3_trees;
insert into public.strat3_tree_history select * from backup_20260930.strat3_tree_history;
insert into public.strat3_state select * from backup_20260930.strat3_state;
insert into public.strat3_d3_docs select * from backup_20260930.strat3_d3_docs;
insert into public.strat3_d3_history select * from backup_20260930.strat3_d3_history;
insert into public.strat3_d3_functions select * from backup_20260930.strat3_d3_functions;
insert into public.strat3_d3_processes select * from backup_20260930.strat3_d3_processes;
insert into public.strat3_d3_process_functions select * from backup_20260930.strat3_d3_process_functions;
select setval('public.strat3_d3_history_id_seq', greatest((select coalesce(max(id),0) from public.strat3_d3_history), 1));
select setval('public.strat3_tree_history_id_seq', greatest((select coalesce(max(id),0) from public.strat3_tree_history), 1));
alter table public.strat3_d3_docs enable trigger strat3_d3_log_trg;
commit;

-- Проверка: 8 потоков, 114 шагов, 476 ролей, 221 перевод; 5 деревьев, 127 процессов, 28 функций, 142 связи.
-- select (select count(*) from vs_all_steps), (select count(*) from vs_all_roles), (select count(*) from strat3_trees), (select count(*) from strat3_d3_processes);
