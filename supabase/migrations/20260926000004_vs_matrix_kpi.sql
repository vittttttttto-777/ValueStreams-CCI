-- Матрица «функция × поток»: сколько шагов владельца уже с KPI (метрикой владельца)
create or replace view public.vs_matrix with (security_invoker = true) as
with r as (
  select ar.stream_id, ar.function_id, ar.role, s.members_confirmed,
         (s.owner_metric is not null and s.owner_metric <> '') as has_kpi
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
       count(r.role)                                                              as total_steps,
       count(r.role) filter (where r.role = 'owner' and r.has_kpi)                as owner_kpi_steps
from public.vs_functions f
cross join public.vs_streams st
left join r on r.function_id = f.id and r.stream_id = st.id
where f.active
group by f.grp, f.sort, f.id, f.name, f.name_en, st.id, st.team;
grant select on public.vs_matrix to anon, authenticated;
