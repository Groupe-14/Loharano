-- À exécuter dans le projet Supabase gratuit, après création du projet.
-- L'application n'envoie rien tant que SUPABASE_URL et SUPABASE_ANON_KEY
-- ne sont pas passées au lancement. Les photos ne sont pas dans cette table.

create table if not exists public.measurements (
  id uuid primary key,
  created_at bigint not null,
  test_type text not null,
  source_type text,
  lat double precision,
  lng double precision,
  location_precision text,
  risk_level text not null check (risk_level in ('low', 'medium', 'high', 'unknown')),
  confidence double precision not null check (confidence >= 0 and confidence <= 1),
  reasons jsonb,
  actions jsonb,
  water_point_id text,
  is_demo boolean not null default false
);

alter table public.measurements enable row level security;

grant usage on schema public to anon;
grant insert on table public.measurements to anon;

create policy "anon_insert_measurements"
  on public.measurements
  for insert
  to anon
  with check (true);
