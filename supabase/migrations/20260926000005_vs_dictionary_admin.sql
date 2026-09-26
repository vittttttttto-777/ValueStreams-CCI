-- Справочник функций ведёт администратор: добавляет, переименовывает, меняет группу и порядок, скрывает.
-- Удалять строки нельзя (на функцию могут ссылаться шаги) — вместо удаления active = false.
drop policy if exists vs_functions_insert on public.vs_functions;
drop policy if exists vs_functions_update on public.vs_functions;
create policy vs_functions_insert on public.vs_functions for insert to anon, authenticated
  with check ((select public.vs_is_admin()));
create policy vs_functions_update on public.vs_functions for update to anon, authenticated
  using ((select public.vs_is_admin())) with check ((select public.vs_is_admin()));
