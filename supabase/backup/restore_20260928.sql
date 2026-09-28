-- ОТКАТ инструмента «Потоки создания ценности» к снимку vs_backup_20260928 (28.09.2026, ~21:20 МСК).
-- Возвращает: шаги и роли всех 5 потоков, KPI, справочник функций, горячие точки, паспорта потоков
-- (включая журнал изменений) и переводы. Пароли и сессии интеграторов не трогает.
-- Запуск: Supabase → SQL Editor → вставить целиком → Run. Всё выполняется одной транзакцией:
-- при любой ошибке ничего не изменится.
begin;
truncate public.vs1_roles, public.vs2_roles, public.vs3_roles, public.vs4_roles, public.vs5_roles,
         public.vs1_steps, public.vs2_steps, public.vs3_steps, public.vs4_steps, public.vs5_steps,
         public.vs_functions, public.vs_hot_points, public.vs_i18n;
update public.vs_streams s set (team, tier, name, short_name, trigger_text, output, flow_object, recipient, value, kpi, industry_functions, handoff, sort, change_log, updated_at) = (select team, tier, name, short_name, trigger_text, output, flow_object, recipient, value, kpi, industry_functions, handoff, sort, change_log, updated_at from vs_backup_20260928.vs_streams b where b.id = s.id)
  where exists (select 1 from vs_backup_20260928.vs_streams b where b.id = s.id);
insert into public.vs_functions (id, name, name_en, grp, sort, is_custom, active, created_at, updated_at, fn_type, fn_type_note) select id, name, name_en, grp, sort, is_custom, active, created_at, updated_at, fn_type, fn_type_note from vs_backup_20260928.vs_functions;
insert into public.vs_hot_points (id, description) select id, description from vs_backup_20260928.vs_hot_points;
insert into public.vs1_steps (id, stream_id, position, name, content, result, is_custom, active, members_confirmed, hot_points, gap_note, owner_metric, metric_target, fixed_until, successor_id, swap_rule, note, history, updated_at) select id, stream_id, position, name, content, result, is_custom, active, members_confirmed, hot_points, gap_note, owner_metric, metric_target, fixed_until, successor_id, swap_rule, note, history, updated_at from vs_backup_20260928.vs1_steps;
insert into public.vs2_steps (id, stream_id, position, name, content, result, is_custom, active, members_confirmed, hot_points, gap_note, owner_metric, metric_target, fixed_until, successor_id, swap_rule, note, history, updated_at) select id, stream_id, position, name, content, result, is_custom, active, members_confirmed, hot_points, gap_note, owner_metric, metric_target, fixed_until, successor_id, swap_rule, note, history, updated_at from vs_backup_20260928.vs2_steps;
insert into public.vs3_steps (id, stream_id, position, name, content, result, is_custom, active, members_confirmed, hot_points, gap_note, owner_metric, metric_target, fixed_until, successor_id, swap_rule, note, history, updated_at) select id, stream_id, position, name, content, result, is_custom, active, members_confirmed, hot_points, gap_note, owner_metric, metric_target, fixed_until, successor_id, swap_rule, note, history, updated_at from vs_backup_20260928.vs3_steps;
insert into public.vs4_steps (id, stream_id, position, name, content, result, is_custom, active, members_confirmed, hot_points, gap_note, owner_metric, metric_target, fixed_until, successor_id, swap_rule, note, history, updated_at) select id, stream_id, position, name, content, result, is_custom, active, members_confirmed, hot_points, gap_note, owner_metric, metric_target, fixed_until, successor_id, swap_rule, note, history, updated_at from vs_backup_20260928.vs4_steps;
insert into public.vs5_steps (id, stream_id, position, name, content, result, is_custom, active, members_confirmed, hot_points, gap_note, owner_metric, metric_target, fixed_until, successor_id, swap_rule, note, history, updated_at) select id, stream_id, position, name, content, result, is_custom, active, members_confirmed, hot_points, gap_note, owner_metric, metric_target, fixed_until, successor_id, swap_rule, note, history, updated_at from vs_backup_20260928.vs5_steps;
insert into public.vs1_roles (step_id, function_id, role, updated_at) select step_id, function_id, role, updated_at from vs_backup_20260928.vs1_roles;
insert into public.vs2_roles (step_id, function_id, role, updated_at) select step_id, function_id, role, updated_at from vs_backup_20260928.vs2_roles;
insert into public.vs3_roles (step_id, function_id, role, updated_at) select step_id, function_id, role, updated_at from vs_backup_20260928.vs3_roles;
insert into public.vs4_roles (step_id, function_id, role, updated_at) select step_id, function_id, role, updated_at from vs_backup_20260928.vs4_roles;
insert into public.vs5_roles (step_id, function_id, role, updated_at) select step_id, function_id, role, updated_at from vs_backup_20260928.vs5_roles;
insert into public.vs_i18n (src, en, ru, updated_at) select src, en, ru, updated_at from vs_backup_20260928.vs_i18n;
commit;

-- Проверка после отката (должно быть: 5 потоков, 36 функций, 81 шаг, 263 роли):
-- select (select count(*) from vs_streams) streams, (select count(*) from vs_functions) fns, (select count(*) from vs_all_steps) steps, (select count(*) from vs_all_roles) roles;
