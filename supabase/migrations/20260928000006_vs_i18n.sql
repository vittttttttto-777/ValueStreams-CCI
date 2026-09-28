-- Переводы текстов, которые вводят команды (названия шагов, содержание, результат, KPI, заметки).
-- Ключ — исходный текст (обрезанный по краям). Если команда меняет текст, старый перевод просто
-- перестаёт совпадать, и приложение показывает исходник, пока не появится новый перевод.
-- en — перевод на английский (для русских/смешанных исходников), ru — на русский (для английских).
create table if not exists public.vs_i18n (
  src        text primary key,
  en         text,
  ru         text,
  updated_at timestamptz not null default now()
);

alter table public.vs_i18n enable row level security;

drop policy if exists vs_i18n_read   on public.vs_i18n;
drop policy if exists vs_i18n_insert on public.vs_i18n;
drop policy if exists vs_i18n_update on public.vs_i18n;
drop policy if exists vs_i18n_delete on public.vs_i18n;
create policy vs_i18n_read   on public.vs_i18n for select to anon, authenticated using (true);
create policy vs_i18n_insert on public.vs_i18n for insert to anon, authenticated with check ((select public.vs_is_admin()));
create policy vs_i18n_update on public.vs_i18n for update to anon, authenticated
  using ((select public.vs_is_admin())) with check ((select public.vs_is_admin()));
create policy vs_i18n_delete on public.vs_i18n for delete to anon, authenticated using ((select public.vs_is_admin()));

grant select on public.vs_i18n to anon, authenticated;
grant insert, update, delete on public.vs_i18n to anon, authenticated;

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'vs_i18n') then
    alter publication supabase_realtime add table public.vs_i18n;
  end if;
end $$;

-- Какие тексты шагов ещё не переведены (удобно для администратора и для регулярного перевода).
create or replace view public.vs_i18n_missing with (security_invoker = true) as
with t as (
  select s.id step_id, f.field, trim(f.val) src
  from (
    select id, name, content, result, owner_metric, metric_target, note, active from public.vs1_steps union all
    select id, name, content, result, owner_metric, metric_target, note, active from public.vs2_steps union all
    select id, name, content, result, owner_metric, metric_target, note, active from public.vs3_steps union all
    select id, name, content, result, owner_metric, metric_target, note, active from public.vs4_steps union all
    select id, name, content, result, owner_metric, metric_target, note, active from public.vs5_steps
  ) s
  cross join lateral (values ('name', s.name), ('content', s.content), ('result', s.result),
                             ('owner_metric', s.owner_metric), ('metric_target', s.metric_target), ('note', s.note)) f(field, val)
  where s.active and coalesce(trim(f.val), '') <> ''
)
select t.* , case when t.src ~ '[А-Яа-яЁё]' then 'en' else 'ru' end as need
from t left join public.vs_i18n i on i.src = t.src
where (t.src ~ '[А-Яа-яЁё]' and i.en is null)
   or (t.src !~ '[А-Яа-яЁё]' and t.src ~ '[A-Za-z]{3}' and i.ru is null);

grant select on public.vs_i18n_missing to anon, authenticated;
