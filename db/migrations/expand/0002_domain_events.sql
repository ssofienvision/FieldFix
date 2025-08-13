-- Immutable domain events log (append-only)
create table if not exists domain_events (
  event_id uuid primary key,
  event_type text not null,
  event_version int not null default 1,
  aggregate_id uuid not null,
  aggregate_type text not null,
  event_number bigserial not null,
  event_data jsonb not null,
  event_metadata jsonb not null default '{}'::jsonb,
  occurred_at timestamptz not null default now(),
  tenant_id uuid not null,
  created_at timestamptz not null default now()
);

create unique index if not exists uq_domain_event_number on domain_events (event_number);
create index if not exists idx_domain_events_aggregate on domain_events (aggregate_id);
