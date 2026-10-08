-- Esquema de la app de reservas de sala.
-- Ejecutar en el SQL Editor de Supabase.

create table if not exists public.reservas (
  id          uuid primary key default gen_random_uuid(),
  sala_id     text not null,
  usuario_id  uuid not null references auth.users (id),
  inicio      timestamptz not null,
  fin         timestamptz not null,
  creada_en   timestamptz not null default now(),
  constraint fin_despues_de_inicio check (fin > inicio)
);

create index if not exists reservas_usuario_sala_idx
  on public.reservas (usuario_id, sala_id);

-- Defensa en la base: también impide solapamientos por solicitudes concurrentes
-- o llamadas que no pasen por el caso de uso Flutter. Los intervalos son [inicio, fin).
-- Si ya existen solapamientos, PostgreSQL rechazará esta restricción sin borrar datos.
create extension if not exists btree_gist;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'reservas_sala_intervalo_sin_solape'
      and conrelid = 'public.reservas'::regclass
  ) then
    alter table public.reservas
      add constraint reservas_sala_intervalo_sin_solape
      exclude using gist (
        sala_id with =,
        tstzrange(inicio, fin, '[)') with &&
      );
  end if;
end $$;

alter table public.reservas enable row level security;

-- La API pública no necesita permisos anónimos ni permisos de modificación
-- distintos de crear reservas. El service_role conserva sus privilegios de
-- servidor, pero nunca debe usarse desde Flutter.
revoke all on table public.reservas from anon, public;
grant select, insert on table public.reservas to authenticated;

drop policy if exists "ver reservas" on public.reservas;

create policy "ver reservas"
  on public.reservas for select
  to authenticated
  using ((select auth.uid()) = usuario_id);

drop policy if exists "crear reservas" on public.reservas;

create policy "crear reservas"
  on public.reservas for insert
  to authenticated
  with check ((select auth.uid()) = usuario_id);
