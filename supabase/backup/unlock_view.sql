-- Снять пароль на просмотр (вернуть чтение без входа). Заставка в приложении останется,
-- но данные снова будут читаться из базы без пароля.
drop policy if exists vs_streams_read on public.vs_streams;
create policy vs_streams_read on public.vs_streams for select to anon, authenticated using (true);
drop policy if exists vs_hot_points_read on public.vs_hot_points;
create policy vs_hot_points_read on public.vs_hot_points for select to anon, authenticated using (true);
drop policy if exists vs_i18n_read on public.vs_i18n;
create policy vs_i18n_read on public.vs_i18n for select to anon, authenticated using (true);
do $$
declare n text;
begin
  foreach n in array array['vs1','vs2','vs2c','vs3','vs4','vs5','vs6','vs7'] loop
    execute format('drop policy if exists %I on public.%I', n||'_steps_read', n||'_steps');
    execute format('create policy %I on public.%I for select to anon, authenticated using (true)', n||'_steps_read', n||'_steps');
    execute format('drop policy if exists %I on public.%I', n||'_roles_read', n||'_roles');
    execute format('create policy %I on public.%I for select to anon, authenticated using (true)', n||'_roles_read', n||'_roles');
  end loop;
end $$;
