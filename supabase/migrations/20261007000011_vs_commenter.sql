-- =====================================================================
-- Роль «Комментатор» и комментарии к модулям, потокам и шагам.
-- Пять учётных записей комментаторов commenter1…commenter5 (по паролю на каждую), каждая пишет
-- в свою таблицу vs_c1_comments … vs_c5_comments — записи разных людей физически не пересекаются.
-- Общая таблица для администратора — представление vs_comments (объединение всех пяти).
-- Комментатор называет имя и фамилию,
-- видит все разделы, ничего не меняет, но оставляет комментарии.
-- Текст комментариев читает только администратор; остальным видно лишь,
-- где есть новые комментарии (счётчики без текста) — для подсветки разделов.
-- Пароль комментатора в репозитории не хранится:
--   select public.vs_set_password('commenter1', '<пароль>');  … и так до commenter5
-- Миграция совместима со старой версией сайта: прежние поля vs_login / vs_whoami сохранены.
-- =====================================================================

-- 1. Учётная запись и имя в сессии
alter table public.vs_users    add column if not exists is_commenter boolean not null default false;
alter table public.vs_sessions add column if not exists display_name text;

insert into public.vs_users (id, label, stream_id, is_admin, is_commenter, pass_hash)
select 'commenter' || i, 'Комментатор ' || i, null, false, true, '-' from generate_series(1, 5) i
on conflict (id) do update set is_commenter = true, is_admin = false, stream_id = null, label = excluded.label;

-- 2. Вход и «кто я» теперь возвращают признак комментатора и имя
drop function if exists public.vs_login(text);
create function public.vs_login(p_pass text)
returns table(token text, id text, label text, stream_id text, is_admin boolean, is_commenter boolean, display_name text)
language plpgsql security definer set search_path = '' as $$
declare u public.vs_users; t text;
begin
  select * into u from public.vs_users x where x.pass_hash = public.vs_hash(p_pass, x.salt) limit 1;
  if u.id is null then perform pg_sleep(0.7); return; end if;
  delete from public.vs_sessions s where s.created_at < now() - interval '14 days';
  t := encode(extensions.gen_random_bytes(24), 'hex');
  insert into public.vs_sessions(token, user_id) values (t, u.id);
  return query select t, u.id, u.label, u.stream_id, u.is_admin, u.is_commenter, null::text;
end $$;

drop function if exists public.vs_whoami();
create function public.vs_whoami()
returns table(id text, label text, stream_id text, is_admin boolean, is_commenter boolean, display_name text)
language sql stable security definer set search_path = '' as $$
  select u.id, u.label, u.stream_id, u.is_admin, u.is_commenter, s.display_name
  from public.vs_sessions s join public.vs_users u on u.id = s.user_id
  where s.token = coalesce(current_setting('request.headers', true)::json->>'x-vs-token', '')
    and s.created_at > now() - interval '14 days'
  limit 1
$$;

create or replace function public.vs_is_commenter() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.vs_whoami() w where w.is_commenter)
$$;

-- Имя и фамилия комментатора записываются в его сессию (не в общую учётную запись:
-- одним паролем пользуются несколько человек)
create or replace function public.vs_set_display_name(p_name text) returns text
language plpgsql security definer set search_path = '' as $$
declare n text := btrim(regexp_replace(coalesce(p_name, ''), '\s+', ' ', 'g'));
begin
  if not public.vs_is_commenter() then raise exception 'Имя задаёт только комментатор' using errcode = '42501'; end if;
  if char_length(n) < 3 or char_length(n) > 80 or position(' ' in n) = 0 then
    raise exception 'Укажите имя и фамилию' using errcode = '22023';
  end if;
  update public.vs_sessions set display_name = n
  where token = coalesce(current_setting('request.headers', true)::json->>'x-vs-token', '');
  return n;
end $$;

-- 3. Комментарии: своя таблица у каждого комментатора + общее представление
do $$
declare i int; t text;
begin
  for i in 1..5 loop
    t := 'vs_c' || i || '_comments';
    execute format($f$
      create table if not exists public.%1$I (
        id          bigint generated always as identity primary key,
        created_at  timestamptz not null default now(),
        author      text not null,                       -- имя и фамилия из сессии
        user_id     text not null default %2$L check (user_id = %2$L),   -- только своя учётная запись
        author_ref  text not null,                       -- sha256 токена сессии: «мои комментарии»
        module      text not null check (module in ('portfolio','stream','map','chain','guide','functions','dict','register')),
        stream_id   text references public.vs_streams(id) on delete set null,
        step_id     text,                                -- шаг вида VS1.3 (связь логическая)
        context     text,                                -- подпись места на момент комментария
        body        text not null check (char_length(btrim(body)) between 1 and 2000),
        status      text not null default 'new' check (status in ('new','done')),
        done_at     timestamptz,
        done_by     text
      )$f$, t, 'commenter' || i);
    execute format('create index if not exists %I on public.%I (module, stream_id, step_id) where status = ''new''', t || '_open', t);
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists %I on public.%I', t || '_admin_read', t);
    execute format('drop policy if exists %I on public.%I', t || '_admin_update', t);
    execute format('drop policy if exists %I on public.%I', t || '_admin_delete', t);
    execute format('create policy %I on public.%I for select to anon, authenticated using ((select public.vs_is_admin()))', t || '_admin_read', t);
    execute format('create policy %I on public.%I for update to anon, authenticated using ((select public.vs_is_admin())) with check ((select public.vs_is_admin()))', t || '_admin_update', t);
    execute format('create policy %I on public.%I for delete to anon, authenticated using ((select public.vs_is_admin()))', t || '_admin_delete', t);
    execute format('revoke all on public.%I from anon, authenticated', t);
    execute format('grant select, update, delete on public.%I to anon, authenticated', t);   -- строки видит только администратор
    execute format('drop trigger if exists %I on public.%I', t || '_signal', t);
    execute format('create trigger %I after insert or update or delete on public.%I for each statement execute function public.vs_signal_change()', t || '_signal', t);
  end loop;
end $$;

-- Общая таблица комментариев: объединение пяти таблиц (src = c1…c5 показывает, откуда строка)
create or replace view public.vs_comments with (security_invoker = true) as
          select 'c1'::text as src, c.* from public.vs_c1_comments c
union all select 'c2', c.* from public.vs_c2_comments c
union all select 'c3', c.* from public.vs_c3_comments c
union all select 'c4', c.* from public.vs_c4_comments c
union all select 'c5', c.* from public.vs_c5_comments c;
revoke all on public.vs_comments from anon, authenticated;
grant select on public.vs_comments to anon, authenticated;

-- Добавить комментарий: пишет только в таблицу своей учётной записи; имя — из сессии
create or replace function public.vs_add_comment(p_module text, p_stream text, p_step text, p_context text, p_body text)
returns bigint language plpgsql security definer set search_path = '' as $$
declare w record; tok text := coalesce(current_setting('request.headers', true)::json->>'x-vs-token', ''); nid bigint; n text;
begin
  select * into w from public.vs_whoami() limit 1;
  if w.id is null or not w.is_commenter then
    raise exception 'Комментарии оставляет комментатор' using errcode = '42501';
  end if;
  if coalesce(w.display_name, '') = '' then
    raise exception 'Сначала укажите имя и фамилию' using errcode = '42501';
  end if;
  n := substring(w.id from '^commenter([1-5])$');
  if n is null then raise exception 'Нет таблицы для учётной записи %', w.id using errcode = '42501'; end if;
  execute format('insert into public.%I(author, user_id, author_ref, module, stream_id, step_id, context, body)
                  values ($1, $2, $3, $4, $5, $6, $7, $8) returning id', 'vs_c' || n || '_comments')
    into nid
    using w.display_name, w.id, encode(extensions.digest(tok, 'sha256'), 'hex'),
          p_module, nullif(p_stream, ''), nullif(p_step, ''), left(p_context, 300), btrim(p_body);
  return nid;
end $$;

-- Где есть новые комментарии (без текста) — для подсветки разделов у всех вошедших
create or replace function public.vs_comment_counts()
returns table(module text, stream_id text, step_id text, n integer)
language sql stable security definer set search_path = '' as $$
  select c.module, c.stream_id, c.step_id, count(*)::int
  from public.vs_comments c
  where c.status = 'new' and public.vs_has_session()
  group by 1, 2, 3
$$;

-- Комментарии, оставленные в текущей сессии (комментатор видит свои)
create or replace function public.vs_my_comments()
returns table(id bigint, created_at timestamptz, module text, stream_id text, step_id text, context text, body text, status text)
language sql stable security definer set search_path = '' as $$
  select c.id, c.created_at, c.module, c.stream_id, c.step_id, c.context, c.body, c.status
  from public.vs_comments c
  where c.author_ref = encode(extensions.digest(coalesce(current_setting('request.headers', true)::json->>'x-vs-token', ''), 'sha256'), 'hex')
  order by c.created_at desc
$$;

-- 4. Права на функции
revoke execute on function public.vs_login(text)              from public, anon, authenticated;
revoke execute on function public.vs_whoami()                 from public, anon, authenticated;
revoke execute on function public.vs_is_commenter()           from public, anon, authenticated;
revoke execute on function public.vs_set_display_name(text)   from public, anon, authenticated;
revoke execute on function public.vs_add_comment(text,text,text,text,text) from public, anon, authenticated;
revoke execute on function public.vs_comment_counts()         from public, anon, authenticated;
revoke execute on function public.vs_my_comments()            from public, anon, authenticated;
grant  execute on function public.vs_login(text)              to anon, authenticated;
grant  execute on function public.vs_whoami()                 to anon, authenticated;
grant  execute on function public.vs_is_commenter()           to anon, authenticated;
grant  execute on function public.vs_set_display_name(text)   to anon, authenticated;
grant  execute on function public.vs_add_comment(text,text,text,text,text) to anon, authenticated;
grant  execute on function public.vs_comment_counts()         to anon, authenticated;
grant  execute on function public.vs_my_comments()            to anon, authenticated;
