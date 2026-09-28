-- =====================================================================
-- Пароль на просмотр, шаг 2: данные потоков читаются только с действующей сессией
-- (пароль участника, интегратора или администратора). Применять ПОСЛЕ того, как
-- на сайт выложена версия приложения с заставкой и паролем, иначе старая версия
-- сайта увидит пустые таблицы.
-- Откат шага 2: supabase/backup/unlock_view.sql
-- =====================================================================
-- Чтение только с сессией
drop policy if exists vs_streams_read on public.vs_streams;
create policy vs_streams_read on public.vs_streams for select to anon, authenticated using ((select public.vs_has_session()));
drop policy if exists vs_hot_points_read on public.vs_hot_points;
create policy vs_hot_points_read on public.vs_hot_points for select to anon, authenticated using ((select public.vs_has_session()));
drop policy if exists vs_i18n_read on public.vs_i18n;
create policy vs_i18n_read on public.vs_i18n for select to anon, authenticated using ((select public.vs_has_session()));

do $$
declare n text;
begin
  foreach n in array array['vs1','vs2','vs2c','vs3','vs4','vs5','vs6','vs7'] loop
    execute format('drop policy if exists %I on public.%I', n||'_steps_read', n||'_steps');
    execute format('create policy %I on public.%I for select to anon, authenticated using ((select public.vs_has_session()))', n||'_steps_read', n||'_steps');
    execute format('drop policy if exists %I on public.%I', n||'_roles_read', n||'_roles');
    execute format('create policy %I on public.%I for select to anon, authenticated using ((select public.vs_has_session()))', n||'_roles_read', n||'_roles');
  end loop;
end $$;

