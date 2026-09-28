-- =====================================================================
-- Новые потоки из предложения «Модель потоков v0.4» (28.09.2026):
--   VS2C — Клиентский спрос (потребитель), VS6 — Партнёрский бизнес, VS7 — Бренд и доверие.
-- Существующие потоки и их данные не меняются. VS2 остаётся в базе с id 'VS2',
-- в приложении показывается как VS2D «Клиентский спрос (дистрибьютор)».
-- Интеграторов у новых потоков нет: редактирует администратор (vs_can_edit).
-- =====================================================================
alter table public.vs_streams drop constraint if exists vs_streams_id_check;
alter table public.vs_streams add constraint vs_streams_id_check
  check (id in ('VS1','VS2','VS2C','VS3','VS4','VS5','VS6','VS7'));
alter table public.vs_streams add column if not exists code   text;   -- код для показа (VS2 → VS2D)
alter table public.vs_streams add column if not exists origin text;   -- источник потока: null = команда, 'v0.4' = предложение
update public.vs_streams set code = id where code is null and id <> 'VS2';
update public.vs_streams set code = 'VS2D' where id = 'VS2';
comment on table public.vs_streams is 'Потоки создания ценности и закреплённые за ними команды';


-- ---------- VS2C: шаги ----------
create table if not exists public.vs2c_steps (
  id                text primary key check (id like 'VS2C.%'),
  stream_id         text not null default 'VS2C' references public.vs_streams(id) check (stream_id = 'VS2C'),
  position          int  not null,
  name              text not null,
  content           text,
  result            text,
  is_custom         boolean not null default false,
  active            boolean not null default true,
  members_confirmed boolean not null default false,
  hot_points        int[]  not null default '{}',
  gap_note          text,
  owner_metric      text,
  metric_target     text,
  fixed_until       date,
  successor_id      text references public.vs_functions(id) on update cascade on delete set null,
  swap_rule         text,
  note              text,
  history           jsonb not null default '[]'::jsonb,
  updated_at        timestamptz not null default now()
);
create index if not exists vs2c_steps_pos on public.vs2c_steps(active, position);
create table if not exists public.vs2c_roles (
  step_id     text not null references public.vs2c_steps(id) on delete cascade,
  function_id text not null references public.vs_functions(id) on update cascade on delete cascade,
  role        text not null default 'none' check (role in ('owner','helper','claimant','none')),
  updated_at  timestamptz not null default now(),
  primary key (step_id, function_id),
  constraint vs2c_one_owner exclude using btree (step_id with =) where (role = 'owner') deferrable initially deferred
);
create index if not exists vs2c_roles_fn on public.vs2c_roles(function_id);
comment on table public.vs2c_steps is 'Шаги потока VS2C';
comment on table public.vs2c_roles is 'Функции на шагах потока VS2C: owner = владелец, helper = помощник, claimant = претендент, none = участвует без роли';
drop trigger if exists vs2c_steps_touch on public.vs2c_steps;
create trigger vs2c_steps_touch before update on public.vs2c_steps for each row execute function public.vs_touch();
drop trigger if exists vs2c_roles_touch on public.vs2c_roles;
create trigger vs2c_roles_touch before update on public.vs2c_roles for each row execute function public.vs_touch();
alter table public.vs2c_steps enable row level security;
alter table public.vs2c_roles enable row level security;
drop policy if exists vs2c_steps_read on public.vs2c_steps;
drop policy if exists vs2c_steps_insert on public.vs2c_steps;
drop policy if exists vs2c_steps_update on public.vs2c_steps;
create policy vs2c_steps_read   on public.vs2c_steps for select to anon, authenticated using (true);
create policy vs2c_steps_insert on public.vs2c_steps for insert to anon, authenticated with check (stream_id = 'VS2C' and (select public.vs_can_edit('VS2C')));
create policy vs2c_steps_update on public.vs2c_steps for update to anon, authenticated using ((select public.vs_can_edit('VS2C'))) with check (stream_id = 'VS2C' and (select public.vs_can_edit('VS2C')));
drop policy if exists vs2c_roles_read on public.vs2c_roles;
drop policy if exists vs2c_roles_insert on public.vs2c_roles;
drop policy if exists vs2c_roles_update on public.vs2c_roles;
drop policy if exists vs2c_roles_delete on public.vs2c_roles;
create policy vs2c_roles_read   on public.vs2c_roles for select to anon, authenticated using (true);
create policy vs2c_roles_insert on public.vs2c_roles for insert to anon, authenticated with check ((select public.vs_can_edit('VS2C')));
create policy vs2c_roles_update on public.vs2c_roles for update to anon, authenticated using ((select public.vs_can_edit('VS2C'))) with check ((select public.vs_can_edit('VS2C')));
create policy vs2c_roles_delete on public.vs2c_roles for delete to anon, authenticated using ((select public.vs_can_edit('VS2C')));
revoke all on public.vs2c_steps, public.vs2c_roles from anon, authenticated;
grant select, insert, update on public.vs2c_steps to anon, authenticated;
grant select, insert, update, delete on public.vs2c_roles to anon, authenticated;


-- ---------- VS6: шаги ----------
create table if not exists public.vs6_steps (
  id                text primary key check (id like 'VS6.%'),
  stream_id         text not null default 'VS6' references public.vs_streams(id) check (stream_id = 'VS6'),
  position          int  not null,
  name              text not null,
  content           text,
  result            text,
  is_custom         boolean not null default false,
  active            boolean not null default true,
  members_confirmed boolean not null default false,
  hot_points        int[]  not null default '{}',
  gap_note          text,
  owner_metric      text,
  metric_target     text,
  fixed_until       date,
  successor_id      text references public.vs_functions(id) on update cascade on delete set null,
  swap_rule         text,
  note              text,
  history           jsonb not null default '[]'::jsonb,
  updated_at        timestamptz not null default now()
);
create index if not exists vs6_steps_pos on public.vs6_steps(active, position);
create table if not exists public.vs6_roles (
  step_id     text not null references public.vs6_steps(id) on delete cascade,
  function_id text not null references public.vs_functions(id) on update cascade on delete cascade,
  role        text not null default 'none' check (role in ('owner','helper','claimant','none')),
  updated_at  timestamptz not null default now(),
  primary key (step_id, function_id),
  constraint vs6_one_owner exclude using btree (step_id with =) where (role = 'owner') deferrable initially deferred
);
create index if not exists vs6_roles_fn on public.vs6_roles(function_id);
comment on table public.vs6_steps is 'Шаги потока VS6';
comment on table public.vs6_roles is 'Функции на шагах потока VS6: owner = владелец, helper = помощник, claimant = претендент, none = участвует без роли';
drop trigger if exists vs6_steps_touch on public.vs6_steps;
create trigger vs6_steps_touch before update on public.vs6_steps for each row execute function public.vs_touch();
drop trigger if exists vs6_roles_touch on public.vs6_roles;
create trigger vs6_roles_touch before update on public.vs6_roles for each row execute function public.vs_touch();
alter table public.vs6_steps enable row level security;
alter table public.vs6_roles enable row level security;
drop policy if exists vs6_steps_read on public.vs6_steps;
drop policy if exists vs6_steps_insert on public.vs6_steps;
drop policy if exists vs6_steps_update on public.vs6_steps;
create policy vs6_steps_read   on public.vs6_steps for select to anon, authenticated using (true);
create policy vs6_steps_insert on public.vs6_steps for insert to anon, authenticated with check (stream_id = 'VS6' and (select public.vs_can_edit('VS6')));
create policy vs6_steps_update on public.vs6_steps for update to anon, authenticated using ((select public.vs_can_edit('VS6'))) with check (stream_id = 'VS6' and (select public.vs_can_edit('VS6')));
drop policy if exists vs6_roles_read on public.vs6_roles;
drop policy if exists vs6_roles_insert on public.vs6_roles;
drop policy if exists vs6_roles_update on public.vs6_roles;
drop policy if exists vs6_roles_delete on public.vs6_roles;
create policy vs6_roles_read   on public.vs6_roles for select to anon, authenticated using (true);
create policy vs6_roles_insert on public.vs6_roles for insert to anon, authenticated with check ((select public.vs_can_edit('VS6')));
create policy vs6_roles_update on public.vs6_roles for update to anon, authenticated using ((select public.vs_can_edit('VS6'))) with check ((select public.vs_can_edit('VS6')));
create policy vs6_roles_delete on public.vs6_roles for delete to anon, authenticated using ((select public.vs_can_edit('VS6')));
revoke all on public.vs6_steps, public.vs6_roles from anon, authenticated;
grant select, insert, update on public.vs6_steps to anon, authenticated;
grant select, insert, update, delete on public.vs6_roles to anon, authenticated;


-- ---------- VS7: шаги ----------
create table if not exists public.vs7_steps (
  id                text primary key check (id like 'VS7.%'),
  stream_id         text not null default 'VS7' references public.vs_streams(id) check (stream_id = 'VS7'),
  position          int  not null,
  name              text not null,
  content           text,
  result            text,
  is_custom         boolean not null default false,
  active            boolean not null default true,
  members_confirmed boolean not null default false,
  hot_points        int[]  not null default '{}',
  gap_note          text,
  owner_metric      text,
  metric_target     text,
  fixed_until       date,
  successor_id      text references public.vs_functions(id) on update cascade on delete set null,
  swap_rule         text,
  note              text,
  history           jsonb not null default '[]'::jsonb,
  updated_at        timestamptz not null default now()
);
create index if not exists vs7_steps_pos on public.vs7_steps(active, position);
create table if not exists public.vs7_roles (
  step_id     text not null references public.vs7_steps(id) on delete cascade,
  function_id text not null references public.vs_functions(id) on update cascade on delete cascade,
  role        text not null default 'none' check (role in ('owner','helper','claimant','none')),
  updated_at  timestamptz not null default now(),
  primary key (step_id, function_id),
  constraint vs7_one_owner exclude using btree (step_id with =) where (role = 'owner') deferrable initially deferred
);
create index if not exists vs7_roles_fn on public.vs7_roles(function_id);
comment on table public.vs7_steps is 'Шаги потока VS7';
comment on table public.vs7_roles is 'Функции на шагах потока VS7: owner = владелец, helper = помощник, claimant = претендент, none = участвует без роли';
drop trigger if exists vs7_steps_touch on public.vs7_steps;
create trigger vs7_steps_touch before update on public.vs7_steps for each row execute function public.vs_touch();
drop trigger if exists vs7_roles_touch on public.vs7_roles;
create trigger vs7_roles_touch before update on public.vs7_roles for each row execute function public.vs_touch();
alter table public.vs7_steps enable row level security;
alter table public.vs7_roles enable row level security;
drop policy if exists vs7_steps_read on public.vs7_steps;
drop policy if exists vs7_steps_insert on public.vs7_steps;
drop policy if exists vs7_steps_update on public.vs7_steps;
create policy vs7_steps_read   on public.vs7_steps for select to anon, authenticated using (true);
create policy vs7_steps_insert on public.vs7_steps for insert to anon, authenticated with check (stream_id = 'VS7' and (select public.vs_can_edit('VS7')));
create policy vs7_steps_update on public.vs7_steps for update to anon, authenticated using ((select public.vs_can_edit('VS7'))) with check (stream_id = 'VS7' and (select public.vs_can_edit('VS7')));
drop policy if exists vs7_roles_read on public.vs7_roles;
drop policy if exists vs7_roles_insert on public.vs7_roles;
drop policy if exists vs7_roles_update on public.vs7_roles;
drop policy if exists vs7_roles_delete on public.vs7_roles;
create policy vs7_roles_read   on public.vs7_roles for select to anon, authenticated using (true);
create policy vs7_roles_insert on public.vs7_roles for insert to anon, authenticated with check ((select public.vs_can_edit('VS7')));
create policy vs7_roles_update on public.vs7_roles for update to anon, authenticated using ((select public.vs_can_edit('VS7'))) with check ((select public.vs_can_edit('VS7')));
create policy vs7_roles_delete on public.vs7_roles for delete to anon, authenticated using ((select public.vs_can_edit('VS7')));
revoke all on public.vs7_steps, public.vs7_roles from anon, authenticated;
grant select, insert, update on public.vs7_steps to anon, authenticated;
grant select, insert, update, delete on public.vs7_roles to anon, authenticated;

-- ---------- Сводные представления: все потоки ----------
create or replace view public.vs_all_steps with (security_invoker = true) as
  select * from public.vs1_steps
union all
  select * from public.vs2_steps
union all
  select * from public.vs2c_steps
union all
  select * from public.vs3_steps
union all
  select * from public.vs4_steps
union all
  select * from public.vs5_steps
union all
  select * from public.vs6_steps
union all
  select * from public.vs7_steps;
create or replace view public.vs_all_roles with (security_invoker = true) as
  select 'VS1'::text as stream_id, r.* from public.vs1_roles r
union all
  select 'VS2'::text as stream_id, r.* from public.vs2_roles r
union all
  select 'VS2C'::text as stream_id, r.* from public.vs2c_roles r
union all
  select 'VS3'::text as stream_id, r.* from public.vs3_roles r
union all
  select 'VS4'::text as stream_id, r.* from public.vs4_roles r
union all
  select 'VS5'::text as stream_id, r.* from public.vs5_roles r
union all
  select 'VS6'::text as stream_id, r.* from public.vs6_roles r
union all
  select 'VS7'::text as stream_id, r.* from public.vs7_roles r;
create or replace view public.vs_i18n_missing with (security_invoker = true) as
with t as (
  select s.id step_id, f.field, trim(f.val) src
  from public.vs_all_steps s
  cross join lateral (values ('name', s.name), ('content', s.content), ('result', s.result),
                             ('owner_metric', s.owner_metric), ('metric_target', s.metric_target), ('note', s.note)) f(field, val)
  where s.active and coalesce(trim(f.val), '') <> ''
)
select t.* , case when t.src ~ '[А-Яа-яЁё]' then 'en' else 'ru' end as need
from t left join public.vs_i18n i on i.src = t.src
where (t.src ~ '[А-Яа-яЁё]' and i.en is null)
   or (t.src !~ '[А-Яа-яЁё]' and t.src ~ '[A-Za-z]{3}' and i.ru is null);
grant select on public.vs_i18n_missing to anon, authenticated;

do $$
declare t text;
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    foreach t in array array['vs2c_steps','vs2c_roles','vs6_steps','vs6_roles','vs7_steps','vs7_roles'] loop
      if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t) then
        execute format('alter publication supabase_realtime add table public.%I', t);
      end if;
    end loop;
  end if;
end $$;
