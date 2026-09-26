-- =====================================================================
-- Доступ по ролевой матрице: интегратор команды редактирует только свой поток,
-- администратор — всё, без входа — только просмотр.
-- Пароли в репозитории НЕ хранятся: их задают отдельным запросом (см. README).
-- =====================================================================
create extension if not exists pgcrypto with schema extensions;

create table if not exists public.vs_users (
  id         text primary key,                 -- vs1…vs5, admin
  label      text not null,                    -- что показывать в шапке приложения
  stream_id  text references public.vs_streams(id),   -- поток интегратора, null у администратора
  is_admin   boolean not null default false,
  salt       text not null default encode(extensions.gen_random_bytes(12), 'hex'),
  pass_hash  text not null,
  updated_at timestamptz not null default now()
);
create table if not exists public.vs_sessions (
  token      text primary key,
  user_id    text not null references public.vs_users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.vs_users    enable row level security;   -- без политик: из браузера не читаются
alter table public.vs_sessions enable row level security;
revoke all on public.vs_users, public.vs_sessions from anon, authenticated;

-- Хэш пароля: регистр и пробелы по краям не важны
create or replace function public.vs_hash(p_pass text, p_salt text) returns text
language sql immutable set search_path = '' as $$
  select encode(extensions.digest(lower(btrim(coalesce(p_pass, ''))) || ':' || p_salt, 'sha256'), 'hex')
$$;

-- Задать пароль (вызывается только из SQL Editor под владельцем базы)
create or replace function public.vs_set_password(p_user text, p_pass text) returns void
language sql security definer set search_path = '' as $$
  update public.vs_users set pass_hash = public.vs_hash(p_pass, salt), updated_at = now() where id = p_user;
  delete from public.vs_sessions where user_id = p_user;
$$;
revoke execute on function public.vs_set_password(text, text) from public, anon, authenticated;

-- Вход: проверяет пароль, выдаёт токен сессии на 14 дней
create or replace function public.vs_login(p_pass text)
returns table(token text, id text, label text, stream_id text, is_admin boolean)
language plpgsql volatile security definer set search_path = '' as $$
declare u public.vs_users; t text;
begin
  select * into u from public.vs_users x where x.pass_hash = public.vs_hash(p_pass, x.salt) limit 1;
  if u.id is null then perform pg_sleep(0.7); return; end if;   -- пауза против перебора
  delete from public.vs_sessions s where s.created_at < now() - interval '14 days';
  t := encode(extensions.gen_random_bytes(24), 'hex');
  insert into public.vs_sessions(token, user_id) values (t, u.id);
  return query select t, u.id, u.label, u.stream_id, u.is_admin;
end $$;

-- Текущий пользователь по заголовку x-vs-token
create or replace function public.vs_whoami()
returns table(id text, label text, stream_id text, is_admin boolean)
language sql stable security definer set search_path = '' as $$
  select u.id, u.label, u.stream_id, u.is_admin
  from public.vs_sessions s join public.vs_users u on u.id = s.user_id
  where s.token = coalesce(current_setting('request.headers', true)::json->>'x-vs-token', '')
    and s.created_at > now() - interval '14 days'
  limit 1
$$;

create or replace function public.vs_logout() returns void
language sql security definer set search_path = '' as $$
  delete from public.vs_sessions where token = coalesce(current_setting('request.headers', true)::json->>'x-vs-token', '')
$$;

create or replace function public.vs_can_edit(p_stream text) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.vs_whoami() w where w.is_admin or w.stream_id = p_stream)
$$;
create or replace function public.vs_is_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.vs_whoami() w where w.is_admin)
$$;

revoke execute on function public.vs_login(text), public.vs_whoami(), public.vs_logout(), public.vs_can_edit(text), public.vs_is_admin() from public;
grant  execute on function public.vs_login(text), public.vs_whoami(), public.vs_logout(), public.vs_can_edit(text), public.vs_is_admin() to anon, authenticated;

-- ---------- Политики записи: только свой поток ----------
drop policy if exists vs_functions_insert on public.vs_functions;
drop policy if exists vs_functions_update on public.vs_functions;
create policy vs_functions_insert on public.vs_functions for insert to anon, authenticated
  with check (is_custom and (select public.vs_is_admin()));
create policy vs_functions_update on public.vs_functions for update to anon, authenticated
  using (is_custom and (select public.vs_is_admin())) with check (is_custom and (select public.vs_is_admin()));

drop policy if exists vs_streams_update on public.vs_streams;
create policy vs_streams_update on public.vs_streams for update to anon, authenticated
  using (public.vs_can_edit(id)) with check (public.vs_can_edit(id));

do $$
declare n text; s text;
begin
  foreach n in array array['vs1','vs2','vs3','vs4','vs5'] loop
    s := upper(n);
    execute format('drop policy if exists %I on public.%I', n||'_steps_insert', n||'_steps');
    execute format('drop policy if exists %I on public.%I', n||'_steps_update', n||'_steps');
    execute format('create policy %I on public.%I for insert to anon, authenticated with check (stream_id = %L and (select public.vs_can_edit(%L)))', n||'_steps_insert', n||'_steps', s, s);
    execute format('create policy %I on public.%I for update to anon, authenticated using ((select public.vs_can_edit(%L))) with check (stream_id = %L and (select public.vs_can_edit(%L)))', n||'_steps_update', n||'_steps', s, s, s);
    execute format('drop policy if exists %I on public.%I', n||'_roles_insert', n||'_roles');
    execute format('drop policy if exists %I on public.%I', n||'_roles_update', n||'_roles');
    execute format('drop policy if exists %I on public.%I', n||'_roles_delete', n||'_roles');
    execute format('create policy %I on public.%I for insert to anon, authenticated with check ((select public.vs_can_edit(%L)))', n||'_roles_insert', n||'_roles', s);
    execute format('create policy %I on public.%I for update to anon, authenticated using ((select public.vs_can_edit(%L))) with check ((select public.vs_can_edit(%L)))', n||'_roles_update', n||'_roles', s, s);
    execute format('create policy %I on public.%I for delete to anon, authenticated using ((select public.vs_can_edit(%L)))', n||'_roles_delete', n||'_roles', s);
  end loop;
end $$;

-- ---------- Учётные записи (пароль задаётся отдельно, до этого вход невозможен) ----------
insert into public.vs_users (id, label, stream_id, is_admin, pass_hash) values
  ('vs1',   'Интегратор VS1 · CoralEVO',    'VS1', false, '-'),
  ('vs2',   'Интегратор VS2 · PrimeGrowth', 'VS2', false, '-'),
  ('vs3',   'Интегратор VS3 · ITModel',     'VS3', false, '-'),
  ('vs4',   'Интегратор VS4 · HealthOS',    'VS4', false, '-'),
  ('vs5',   'Интегратор VS5 · GrowthModel', 'VS5', false, '-'),
  ('admin', 'Администратор',                null,  true,  '-')
on conflict (id) do nothing;
