-- =====================================================================
-- Потоки создания ценности · Coral Club · схема базы
-- Префикс vs: таблицы не пересекаются с другими приложениями в проекте.
--   Справочники:   vs_functions, vs_streams, vs_hot_points
--   По потокам:    vs1_steps / vs1_roles … vs5_steps / vs5_roles
--   Сводные (view): vs_all_steps, vs_all_roles, vs_step_status, vs_matrix, vs_disputes
-- =====================================================================

create or replace function public.vs_touch() returns trigger
language plpgsql set search_path = '' as $$
begin new.updated_at := now(); return new; end $$;

-- ---------- Справочник функций ----------
create table if not exists public.vs_functions (
  id          text primary key,
  name        text not null,
  name_en     text,
  grp         text not null default 'Добавлено на сессии',
  sort        int  not null default 9000,
  is_custom   boolean not null default false,   -- добавлена командой на сессии
  active      boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
comment on table public.vs_functions is 'Справочник функций компании (версия 25.09.2026) и функции, добавленные на сессии';

-- ---------- Потоки ----------
create table if not exists public.vs_streams (
  id          text primary key check (id in ('VS1','VS2','VS3','VS4','VS5')),
  team        text not null,          -- команда трека
  tier        int  not null,          -- 1 = создать готовность, 2 = реализовать ценность
  name        text not null,
  short_name  text,
  trigger_text text,
  output      text,
  flow_object text,
  recipient   text,
  value       text,
  kpi         text[] not null default '{}',
  industry_functions text,
  handoff     text,
  sort        int not null default 0,
  change_log  jsonb not null default '[]'::jsonb,   -- журнал правок шагов потока
  updated_at  timestamptz not null default now()
);
comment on table public.vs_streams is 'Пять потоков создания ценности и закреплённые за ними команды';

-- ---------- Точки накала из свода анкет 17.09.2026 ----------
create table if not exists public.vs_hot_points (
  id          int primary key,
  description text not null
);

-- ---------- VS1: шаги ----------
create table if not exists public.vs1_steps (
  id                text primary key check (id like 'VS1.%'),
  stream_id         text not null default 'VS1' references public.vs_streams(id) check (stream_id = 'VS1'),
  position          int  not null,
  name              text not null,
  content           text,
  result            text,
  is_custom         boolean not null default false,  -- шаг добавлен командой
  active            boolean not null default true,   -- false = шаг удалён командой (можно вернуть)
  members_confirmed boolean not null default false,  -- false = состав функций пока гипотеза из свода
  hot_points        int[]  not null default '{}',   -- номера точек накала (vs_hot_points)
  gap_note          text,
  owner_metric      text,
  metric_target     text,
  fixed_until       date,                            -- роль владельца закреплена до
  successor_id      text references public.vs_functions(id) on update cascade on delete set null,
  swap_rule         text,
  note              text,
  history           jsonb not null default '[]'::jsonb,
  updated_at        timestamptz not null default now()
);
create index if not exists vs1_steps_pos on public.vs1_steps(active, position);

-- ---------- VS1: функции на шагах и их роли ----------
create table if not exists public.vs1_roles (
  step_id     text not null references public.vs1_steps(id) on delete cascade,
  function_id text not null references public.vs_functions(id) on update cascade on delete cascade,
  role        text not null default 'none' check (role in ('owner','helper','claimant','none')),
  updated_at  timestamptz not null default now(),
  primary key (step_id, function_id),
  -- у шага не больше одного владельца (проверка в конце транзакции)
  constraint vs1_one_owner exclude using btree (step_id with =) where (role = 'owner') deferrable initially deferred
);
create index if not exists vs1_roles_fn on public.vs1_roles(function_id);
comment on table public.vs1_steps is 'Шаги потока VS1';
comment on table public.vs1_roles is 'Функции на шагах потока VS1: owner = владелец, helper = помощник, claimant = претендент, none = участвует без роли';

drop trigger if exists vs1_steps_touch on public.vs1_steps;
create trigger vs1_steps_touch before update on public.vs1_steps for each row execute function public.vs_touch();
drop trigger if exists vs1_roles_touch on public.vs1_roles;
create trigger vs1_roles_touch before update on public.vs1_roles for each row execute function public.vs_touch();

-- ---------- VS2: шаги ----------
create table if not exists public.vs2_steps (
  id                text primary key check (id like 'VS2.%'),
  stream_id         text not null default 'VS2' references public.vs_streams(id) check (stream_id = 'VS2'),
  position          int  not null,
  name              text not null,
  content           text,
  result            text,
  is_custom         boolean not null default false,  -- шаг добавлен командой
  active            boolean not null default true,   -- false = шаг удалён командой (можно вернуть)
  members_confirmed boolean not null default false,  -- false = состав функций пока гипотеза из свода
  hot_points        int[]  not null default '{}',   -- номера точек накала (vs_hot_points)
  gap_note          text,
  owner_metric      text,
  metric_target     text,
  fixed_until       date,                            -- роль владельца закреплена до
  successor_id      text references public.vs_functions(id) on update cascade on delete set null,
  swap_rule         text,
  note              text,
  history           jsonb not null default '[]'::jsonb,
  updated_at        timestamptz not null default now()
);
create index if not exists vs2_steps_pos on public.vs2_steps(active, position);

-- ---------- VS2: функции на шагах и их роли ----------
create table if not exists public.vs2_roles (
  step_id     text not null references public.vs2_steps(id) on delete cascade,
  function_id text not null references public.vs_functions(id) on update cascade on delete cascade,
  role        text not null default 'none' check (role in ('owner','helper','claimant','none')),
  updated_at  timestamptz not null default now(),
  primary key (step_id, function_id),
  -- у шага не больше одного владельца (проверка в конце транзакции)
  constraint vs2_one_owner exclude using btree (step_id with =) where (role = 'owner') deferrable initially deferred
);
create index if not exists vs2_roles_fn on public.vs2_roles(function_id);
comment on table public.vs2_steps is 'Шаги потока VS2';
comment on table public.vs2_roles is 'Функции на шагах потока VS2: owner = владелец, helper = помощник, claimant = претендент, none = участвует без роли';

drop trigger if exists vs2_steps_touch on public.vs2_steps;
create trigger vs2_steps_touch before update on public.vs2_steps for each row execute function public.vs_touch();
drop trigger if exists vs2_roles_touch on public.vs2_roles;
create trigger vs2_roles_touch before update on public.vs2_roles for each row execute function public.vs_touch();

-- ---------- VS3: шаги ----------
create table if not exists public.vs3_steps (
  id                text primary key check (id like 'VS3.%'),
  stream_id         text not null default 'VS3' references public.vs_streams(id) check (stream_id = 'VS3'),
  position          int  not null,
  name              text not null,
  content           text,
  result            text,
  is_custom         boolean not null default false,  -- шаг добавлен командой
  active            boolean not null default true,   -- false = шаг удалён командой (можно вернуть)
  members_confirmed boolean not null default false,  -- false = состав функций пока гипотеза из свода
  hot_points        int[]  not null default '{}',   -- номера точек накала (vs_hot_points)
  gap_note          text,
  owner_metric      text,
  metric_target     text,
  fixed_until       date,                            -- роль владельца закреплена до
  successor_id      text references public.vs_functions(id) on update cascade on delete set null,
  swap_rule         text,
  note              text,
  history           jsonb not null default '[]'::jsonb,
  updated_at        timestamptz not null default now()
);
create index if not exists vs3_steps_pos on public.vs3_steps(active, position);

-- ---------- VS3: функции на шагах и их роли ----------
create table if not exists public.vs3_roles (
  step_id     text not null references public.vs3_steps(id) on delete cascade,
  function_id text not null references public.vs_functions(id) on update cascade on delete cascade,
  role        text not null default 'none' check (role in ('owner','helper','claimant','none')),
  updated_at  timestamptz not null default now(),
  primary key (step_id, function_id),
  -- у шага не больше одного владельца (проверка в конце транзакции)
  constraint vs3_one_owner exclude using btree (step_id with =) where (role = 'owner') deferrable initially deferred
);
create index if not exists vs3_roles_fn on public.vs3_roles(function_id);
comment on table public.vs3_steps is 'Шаги потока VS3';
comment on table public.vs3_roles is 'Функции на шагах потока VS3: owner = владелец, helper = помощник, claimant = претендент, none = участвует без роли';

drop trigger if exists vs3_steps_touch on public.vs3_steps;
create trigger vs3_steps_touch before update on public.vs3_steps for each row execute function public.vs_touch();
drop trigger if exists vs3_roles_touch on public.vs3_roles;
create trigger vs3_roles_touch before update on public.vs3_roles for each row execute function public.vs_touch();

-- ---------- VS4: шаги ----------
create table if not exists public.vs4_steps (
  id                text primary key check (id like 'VS4.%'),
  stream_id         text not null default 'VS4' references public.vs_streams(id) check (stream_id = 'VS4'),
  position          int  not null,
  name              text not null,
  content           text,
  result            text,
  is_custom         boolean not null default false,  -- шаг добавлен командой
  active            boolean not null default true,   -- false = шаг удалён командой (можно вернуть)
  members_confirmed boolean not null default false,  -- false = состав функций пока гипотеза из свода
  hot_points        int[]  not null default '{}',   -- номера точек накала (vs_hot_points)
  gap_note          text,
  owner_metric      text,
  metric_target     text,
  fixed_until       date,                            -- роль владельца закреплена до
  successor_id      text references public.vs_functions(id) on update cascade on delete set null,
  swap_rule         text,
  note              text,
  history           jsonb not null default '[]'::jsonb,
  updated_at        timestamptz not null default now()
);
create index if not exists vs4_steps_pos on public.vs4_steps(active, position);

-- ---------- VS4: функции на шагах и их роли ----------
create table if not exists public.vs4_roles (
  step_id     text not null references public.vs4_steps(id) on delete cascade,
  function_id text not null references public.vs_functions(id) on update cascade on delete cascade,
  role        text not null default 'none' check (role in ('owner','helper','claimant','none')),
  updated_at  timestamptz not null default now(),
  primary key (step_id, function_id),
  -- у шага не больше одного владельца (проверка в конце транзакции)
  constraint vs4_one_owner exclude using btree (step_id with =) where (role = 'owner') deferrable initially deferred
);
create index if not exists vs4_roles_fn on public.vs4_roles(function_id);
comment on table public.vs4_steps is 'Шаги потока VS4';
comment on table public.vs4_roles is 'Функции на шагах потока VS4: owner = владелец, helper = помощник, claimant = претендент, none = участвует без роли';

drop trigger if exists vs4_steps_touch on public.vs4_steps;
create trigger vs4_steps_touch before update on public.vs4_steps for each row execute function public.vs_touch();
drop trigger if exists vs4_roles_touch on public.vs4_roles;
create trigger vs4_roles_touch before update on public.vs4_roles for each row execute function public.vs_touch();

-- ---------- VS5: шаги ----------
create table if not exists public.vs5_steps (
  id                text primary key check (id like 'VS5.%'),
  stream_id         text not null default 'VS5' references public.vs_streams(id) check (stream_id = 'VS5'),
  position          int  not null,
  name              text not null,
  content           text,
  result            text,
  is_custom         boolean not null default false,  -- шаг добавлен командой
  active            boolean not null default true,   -- false = шаг удалён командой (можно вернуть)
  members_confirmed boolean not null default false,  -- false = состав функций пока гипотеза из свода
  hot_points        int[]  not null default '{}',   -- номера точек накала (vs_hot_points)
  gap_note          text,
  owner_metric      text,
  metric_target     text,
  fixed_until       date,                            -- роль владельца закреплена до
  successor_id      text references public.vs_functions(id) on update cascade on delete set null,
  swap_rule         text,
  note              text,
  history           jsonb not null default '[]'::jsonb,
  updated_at        timestamptz not null default now()
);
create index if not exists vs5_steps_pos on public.vs5_steps(active, position);

-- ---------- VS5: функции на шагах и их роли ----------
create table if not exists public.vs5_roles (
  step_id     text not null references public.vs5_steps(id) on delete cascade,
  function_id text not null references public.vs_functions(id) on update cascade on delete cascade,
  role        text not null default 'none' check (role in ('owner','helper','claimant','none')),
  updated_at  timestamptz not null default now(),
  primary key (step_id, function_id),
  -- у шага не больше одного владельца (проверка в конце транзакции)
  constraint vs5_one_owner exclude using btree (step_id with =) where (role = 'owner') deferrable initially deferred
);
create index if not exists vs5_roles_fn on public.vs5_roles(function_id);
comment on table public.vs5_steps is 'Шаги потока VS5';
comment on table public.vs5_roles is 'Функции на шагах потока VS5: owner = владелец, helper = помощник, claimant = претендент, none = участвует без роли';

drop trigger if exists vs5_steps_touch on public.vs5_steps;
create trigger vs5_steps_touch before update on public.vs5_steps for each row execute function public.vs_touch();
drop trigger if exists vs5_roles_touch on public.vs5_roles;
create trigger vs5_roles_touch before update on public.vs5_roles for each row execute function public.vs_touch();

drop trigger if exists vs_functions_touch on public.vs_functions;
create trigger vs_functions_touch before update on public.vs_functions for each row execute function public.vs_touch();
drop trigger if exists vs_streams_touch on public.vs_streams;
create trigger vs_streams_touch before update on public.vs_streams for each row execute function public.vs_touch();

-- =====================================================================
-- Сводные представления для матрицы всех потоков
-- =====================================================================
create or replace view public.vs_all_steps with (security_invoker = true) as
  select * from public.vs1_steps
union all
  select * from public.vs2_steps
union all
  select * from public.vs3_steps
union all
  select * from public.vs4_steps
union all
  select * from public.vs5_steps;

create or replace view public.vs_all_roles with (security_invoker = true) as
  select 'VS1'::text as stream_id, r.* from public.vs1_roles r
union all
  select 'VS2'::text as stream_id, r.* from public.vs2_roles r
union all
  select 'VS3'::text as stream_id, r.* from public.vs3_roles r
union all
  select 'VS4'::text as stream_id, r.* from public.vs4_roles r
union all
  select 'VS5'::text as stream_id, r.* from public.vs5_roles r;

-- Статус каждого шага: владелец, помощники, претенденты, спор
create or replace view public.vs_step_status with (security_invoker = true) as
with r as (
  select ar.step_id, ar.role, f.name as fn_name
  from public.vs_all_roles ar join public.vs_functions f on f.id = ar.function_id
),
agg as (
  select s.id as step_id,
         max(r.fn_name) filter (where r.role = 'owner')                          as owner,
         string_agg(r.fn_name, ', ' order by r.fn_name) filter (where r.role = 'helper')   as helpers,
         string_agg(r.fn_name, ', ' order by r.fn_name) filter (where r.role = 'claimant') as claimants,
         count(*) filter (where r.role = 'owner')    as owner_cnt,
         count(*) filter (where r.role = 'claimant') as claimant_cnt,
         count(r.role)                               as functions_cnt
  from public.vs_all_steps s left join r on r.step_id = s.id
  group by s.id
)
select s.stream_id, st.team, s.position, s.id as step_id, s.name as step,
       s.result, a.owner, a.helpers, a.claimants, a.functions_cnt,
       case when a.claimant_cnt >= 2 or (a.owner_cnt >= 1 and a.claimant_cnt >= 1) then 'Спор'
            when a.owner_cnt = 0 then 'Нет владельца'
            when s.owner_metric is not null and s.owner_metric <> '' and s.fixed_until is not null then 'Закреплено'
            else 'Владелец назначен' end as status,
       s.members_confirmed, s.owner_metric, s.metric_target, s.fixed_until,
       (s.fixed_until is not null and s.fixed_until < current_date) as review_overdue,
       sf.name as successor, s.swap_rule, s.note, s.hot_points, s.is_custom, s.updated_at
from public.vs_all_steps s
join agg a on a.step_id = s.id
join public.vs_streams st on st.id = s.stream_id
left join public.vs_functions sf on sf.id = s.successor_id
where s.active;

-- Матрица «функция × поток»: сколько шагов функция ведёт, поддерживает, оспаривает
create or replace view public.vs_matrix with (security_invoker = true) as
with r as (
  select ar.stream_id, ar.function_id, ar.role, s.members_confirmed
  from public.vs_all_roles ar join public.vs_all_steps s on s.id = ar.step_id
  where s.active
)
select f.grp, f.sort, f.id as function_id, f.name as function, f.name_en,
       st.id as stream_id, st.team,
       count(r.role) filter (where r.role = 'owner')                              as owner_steps,
       count(r.role) filter (where r.role = 'helper')                             as helper_steps,
       count(r.role) filter (where r.role = 'claimant')                           as claimant_steps,
       count(r.role) filter (where r.role = 'none' and r.members_confirmed)       as no_role_steps,
       count(r.role) filter (where r.role = 'none' and not r.members_confirmed)   as hypothesis_steps,
       count(r.role)                                                              as total_steps
from public.vs_functions f
cross join public.vs_streams st
left join r on r.function_id = f.id and r.stream_id = st.id
where f.active
group by f.grp, f.sort, f.id, f.name, f.name_en, st.id, st.team;

-- Реестр «на дорешение»: шаги со спором за владение
create or replace view public.vs_disputes with (security_invoker = true) as
select stream_id, team, position, step_id, step, owner, claimants, helpers, note
from public.vs_step_status where status = 'Спор';

-- =====================================================================
-- Доступ: по ссылке на приложение (роль anon). Удалять можно только
-- функции с шага; шаги удаляются мягко (active = false).
-- =====================================================================
alter table public.vs_functions  enable row level security;
alter table public.vs_streams    enable row level security;
alter table public.vs_hot_points enable row level security;

drop policy if exists vs_functions_read   on public.vs_functions;
drop policy if exists vs_functions_insert on public.vs_functions;
drop policy if exists vs_functions_update on public.vs_functions;
create policy vs_functions_read   on public.vs_functions for select to anon, authenticated using (true);
create policy vs_functions_insert on public.vs_functions for insert to anon, authenticated with check (is_custom);
create policy vs_functions_update on public.vs_functions for update to anon, authenticated using (is_custom) with check (is_custom);

drop policy if exists vs_streams_read   on public.vs_streams;
drop policy if exists vs_streams_update on public.vs_streams;
create policy vs_streams_read   on public.vs_streams for select to anon, authenticated using (true);
create policy vs_streams_update on public.vs_streams for update to anon, authenticated using (true) with check (true);

drop policy if exists vs_hot_points_read on public.vs_hot_points;
create policy vs_hot_points_read on public.vs_hot_points for select to anon, authenticated using (true);

alter table public.vs1_steps enable row level security;
alter table public.vs1_roles enable row level security;
drop policy if exists vs1_steps_read   on public.vs1_steps;
drop policy if exists vs1_steps_insert on public.vs1_steps;
drop policy if exists vs1_steps_update on public.vs1_steps;
create policy vs1_steps_read   on public.vs1_steps for select to anon, authenticated using (true);
create policy vs1_steps_insert on public.vs1_steps for insert to anon, authenticated with check (stream_id = 'VS1');
create policy vs1_steps_update on public.vs1_steps for update to anon, authenticated using (true) with check (stream_id = 'VS1');
drop policy if exists vs1_roles_read   on public.vs1_roles;
drop policy if exists vs1_roles_insert on public.vs1_roles;
drop policy if exists vs1_roles_update on public.vs1_roles;
drop policy if exists vs1_roles_delete on public.vs1_roles;
create policy vs1_roles_read   on public.vs1_roles for select to anon, authenticated using (true);
create policy vs1_roles_insert on public.vs1_roles for insert to anon, authenticated with check (true);
create policy vs1_roles_update on public.vs1_roles for update to anon, authenticated using (true) with check (true);
create policy vs1_roles_delete on public.vs1_roles for delete to anon, authenticated using (true);

alter table public.vs2_steps enable row level security;
alter table public.vs2_roles enable row level security;
drop policy if exists vs2_steps_read   on public.vs2_steps;
drop policy if exists vs2_steps_insert on public.vs2_steps;
drop policy if exists vs2_steps_update on public.vs2_steps;
create policy vs2_steps_read   on public.vs2_steps for select to anon, authenticated using (true);
create policy vs2_steps_insert on public.vs2_steps for insert to anon, authenticated with check (stream_id = 'VS2');
create policy vs2_steps_update on public.vs2_steps for update to anon, authenticated using (true) with check (stream_id = 'VS2');
drop policy if exists vs2_roles_read   on public.vs2_roles;
drop policy if exists vs2_roles_insert on public.vs2_roles;
drop policy if exists vs2_roles_update on public.vs2_roles;
drop policy if exists vs2_roles_delete on public.vs2_roles;
create policy vs2_roles_read   on public.vs2_roles for select to anon, authenticated using (true);
create policy vs2_roles_insert on public.vs2_roles for insert to anon, authenticated with check (true);
create policy vs2_roles_update on public.vs2_roles for update to anon, authenticated using (true) with check (true);
create policy vs2_roles_delete on public.vs2_roles for delete to anon, authenticated using (true);

alter table public.vs3_steps enable row level security;
alter table public.vs3_roles enable row level security;
drop policy if exists vs3_steps_read   on public.vs3_steps;
drop policy if exists vs3_steps_insert on public.vs3_steps;
drop policy if exists vs3_steps_update on public.vs3_steps;
create policy vs3_steps_read   on public.vs3_steps for select to anon, authenticated using (true);
create policy vs3_steps_insert on public.vs3_steps for insert to anon, authenticated with check (stream_id = 'VS3');
create policy vs3_steps_update on public.vs3_steps for update to anon, authenticated using (true) with check (stream_id = 'VS3');
drop policy if exists vs3_roles_read   on public.vs3_roles;
drop policy if exists vs3_roles_insert on public.vs3_roles;
drop policy if exists vs3_roles_update on public.vs3_roles;
drop policy if exists vs3_roles_delete on public.vs3_roles;
create policy vs3_roles_read   on public.vs3_roles for select to anon, authenticated using (true);
create policy vs3_roles_insert on public.vs3_roles for insert to anon, authenticated with check (true);
create policy vs3_roles_update on public.vs3_roles for update to anon, authenticated using (true) with check (true);
create policy vs3_roles_delete on public.vs3_roles for delete to anon, authenticated using (true);

alter table public.vs4_steps enable row level security;
alter table public.vs4_roles enable row level security;
drop policy if exists vs4_steps_read   on public.vs4_steps;
drop policy if exists vs4_steps_insert on public.vs4_steps;
drop policy if exists vs4_steps_update on public.vs4_steps;
create policy vs4_steps_read   on public.vs4_steps for select to anon, authenticated using (true);
create policy vs4_steps_insert on public.vs4_steps for insert to anon, authenticated with check (stream_id = 'VS4');
create policy vs4_steps_update on public.vs4_steps for update to anon, authenticated using (true) with check (stream_id = 'VS4');
drop policy if exists vs4_roles_read   on public.vs4_roles;
drop policy if exists vs4_roles_insert on public.vs4_roles;
drop policy if exists vs4_roles_update on public.vs4_roles;
drop policy if exists vs4_roles_delete on public.vs4_roles;
create policy vs4_roles_read   on public.vs4_roles for select to anon, authenticated using (true);
create policy vs4_roles_insert on public.vs4_roles for insert to anon, authenticated with check (true);
create policy vs4_roles_update on public.vs4_roles for update to anon, authenticated using (true) with check (true);
create policy vs4_roles_delete on public.vs4_roles for delete to anon, authenticated using (true);

alter table public.vs5_steps enable row level security;
alter table public.vs5_roles enable row level security;
drop policy if exists vs5_steps_read   on public.vs5_steps;
drop policy if exists vs5_steps_insert on public.vs5_steps;
drop policy if exists vs5_steps_update on public.vs5_steps;
create policy vs5_steps_read   on public.vs5_steps for select to anon, authenticated using (true);
create policy vs5_steps_insert on public.vs5_steps for insert to anon, authenticated with check (stream_id = 'VS5');
create policy vs5_steps_update on public.vs5_steps for update to anon, authenticated using (true) with check (stream_id = 'VS5');
drop policy if exists vs5_roles_read   on public.vs5_roles;
drop policy if exists vs5_roles_insert on public.vs5_roles;
drop policy if exists vs5_roles_update on public.vs5_roles;
drop policy if exists vs5_roles_delete on public.vs5_roles;
create policy vs5_roles_read   on public.vs5_roles for select to anon, authenticated using (true);
create policy vs5_roles_insert on public.vs5_roles for insert to anon, authenticated with check (true);
create policy vs5_roles_update on public.vs5_roles for update to anon, authenticated using (true) with check (true);
create policy vs5_roles_delete on public.vs5_roles for delete to anon, authenticated using (true);

revoke delete on public.vs_functions, public.vs_streams, public.vs_hot_points from anon, authenticated;
revoke delete on public.vs1_steps, public.vs2_steps, public.vs3_steps, public.vs4_steps, public.vs5_steps from anon, authenticated;
grant select on public.vs_all_steps, public.vs_all_roles, public.vs_step_status, public.vs_matrix, public.vs_disputes to anon, authenticated;

-- Живое обновление у всех участников
do $$
declare t text;
begin
  foreach t in array array['vs_functions','vs_streams','vs1_steps','vs1_roles','vs2_steps','vs2_roles','vs3_steps','vs3_roles','vs4_steps','vs4_roles','vs5_steps','vs5_roles'] loop
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;
