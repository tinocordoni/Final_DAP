begin;

create table public.books (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  title text not null check (btrim(title) <> ''),
  author text not null check (btrim(author) <> ''),
  year bigint not null,
  description text not null check (btrim(description) <> ''),
  cover_url text not null check (cover_url ~ '^https://[^[:space:]]+$')
);

create index books_owner_title_idx on public.books (owner_id, title);

alter table public.books enable row level security;

-- RLS verifica el dueño de cada fila aunque se consulte directamente por la API.
revoke all on table public.books from public, anon, authenticated;
grant select, insert, update, delete on table public.books to authenticated;

create policy "Leer libros propios" on public.books
  for select to authenticated
  using ((select auth.uid()) = owner_id);

create policy "Crear libros propios" on public.books
  for insert to authenticated
  with check ((select auth.uid()) = owner_id);

create policy "Editar libros propios" on public.books
  for update to authenticated
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);

create policy "Eliminar libros propios" on public.books
  for delete to authenticated
  using ((select auth.uid()) = owner_id);

alter publication supabase_realtime add table public.books;

commit;
