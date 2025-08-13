-- Outbox table for transactional event publishing
create table if not exists outbox_events (
  id uuid primary key default gen_random_uuid(),
  aggregate_type text not null,
  aggregate_id uuid not null,
  event_type text not null,
  event_version int not null default 1,
  payload jsonb not null,
  metadata jsonb not null default '{}'::jsonb,
  tenant_id uuid not null,
  published boolean not null default false,
  created_at timestamptz not null default now(),
  published_at timestamptz
);

create index if not exists idx_outbox_unpublished on outbox_events (published, created_at);
