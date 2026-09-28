-- =====================================================================
-- Пароль на просмотр, шаг 1 (подготовка): учётная запись участника, проверка сессии,
-- сигнал об изменениях для живой синхронизации. Сами таблицы закрывает миграция 0010.
-- Сессию выдаёт vs_login по паролю участника (учётная запись viewer),
-- интегратора или администратора. Без входа из браузера видно только
-- справочник функций и сигнал об изменениях (без содержания).
-- Пароль viewer задаётся отдельно и в репозитории не хранится:
--   select public.vs_set_password('viewer', '<пароль>');
-- =====================================================================

create or replace function public.vs_has_session() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.vs_whoami())
$$;
revoke execute on function public.vs_has_session() from public;
grant  execute on function public.vs_has_session() to anon, authenticated;

-- Учётная запись участника стратсессии: только просмотр
insert into public.vs_users (id, label, stream_id, is_admin, pass_hash)
values ('viewer', 'Участник стратсессии', null, false, '-')
on conflict (id) do nothing;

-- Сигнал об изменениях для живой синхронизации: сами таблицы теперь закрыты,
-- а живое обновление слушает только эту таблицу (имя таблицы и время, без данных).
create table if not exists public.vs_changes (
  tbl text primary key,
  at  timestamptz not null default now()
);
alter table public.vs_changes enable row level security;
drop policy if exists vs_changes_read on public.vs_changes;
create policy vs_changes_read on public.vs_changes for select to anon, authenticated using (true);
revoke all on public.vs_changes from anon, authenticated;
grant select on public.vs_changes to anon, authenticated;

create or replace function public.vs_signal_change() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.vs_changes(tbl, at) values (tg_table_name, now())
  on conflict (tbl) do update set at = excluded.at;
  return null;
end $$;
revoke execute on function public.vs_signal_change() from public, anon, authenticated;

do $$
declare t text;
begin
  foreach t in array array['vs_functions','vs_streams','vs_i18n',
    'vs1_steps','vs1_roles','vs2_steps','vs2_roles','vs2c_steps','vs2c_roles','vs3_steps','vs3_roles',
    'vs4_steps','vs4_roles','vs5_steps','vs5_roles','vs6_steps','vs6_roles','vs7_steps','vs7_roles'] loop
    execute format('drop trigger if exists %I on public.%I', t||'_signal', t);
    execute format('create trigger %I after insert or update or delete on public.%I for each statement execute function public.vs_signal_change()', t||'_signal', t);
  end loop;
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'vs_changes') then
    alter publication supabase_realtime add table public.vs_changes;
  end if;
end $$;
