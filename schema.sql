-- Superhot Rock Task Tracker — Supabase schema
-- Run this in Supabase: SQL Editor -> New query -> paste -> Run

create extension if not exists pgcrypto;

-- Team members. Passwords are stored as SHA-256 hashes computed in the browser.
-- NOTE: this is convenience-grade auth for an internal team tool, not hardened security.
create table if not exists members (
  id uuid primary key default gen_random_uuid(),
  username text unique not null,
  display_name text not null,
  password_hash text not null,
  color text default '#FF5C2B',
  created_at timestamptz default now()
);

-- Workstreams and subworkstreams (parent_id null = top-level workstream)
create table if not exists workstreams (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  parent_id uuid references workstreams(id) on delete cascade,
  created_at timestamptz default now()
);

create table if not exists tasks (
  id uuid primary key default gen_random_uuid(),
  workstream_id uuid not null references workstreams(id) on delete cascade,
  title text not null,
  assignee_id uuid references members(id) on delete set null,
  status text not null default 'not_started'
    check (status in ('not_started','in_progress','done','input_needed')),
  priority text not null default 'medium'
    check (priority in ('high','medium','low')),
  deadline date,
  mention_id uuid references members(id) on delete set null, -- @person for "input needed"
  notes text default '',
  created_by uuid references members(id) on delete set null,
  created_at timestamptz default now(),
  completed_at timestamptz
);

create table if not exists comments (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references tasks(id) on delete cascade,
  author_id uuid references members(id) on delete set null,
  body text not null,
  created_at timestamptz default now()
);

create table if not exists notifications (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references members(id) on delete cascade,
  task_id uuid references tasks(id) on delete cascade,
  body text not null,
  read boolean default false,
  created_at timestamptz default now()
);

-- SHR "bible" knowledge chunks used as context for AI task suggestions
create table if not exists knowledge (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  tags text default '',      -- comma-separated, e.g. "well construction, casing"
  content text not null,
  created_at timestamptz default now()
);

-- Enable realtime so everyone sees changes live
alter publication supabase_realtime add table tasks;
alter publication supabase_realtime add table comments;
alter publication supabase_realtime add table workstreams;
alter publication supabase_realtime add table notifications;
alter publication supabase_realtime add table members;

-- Row Level Security: open read/write to the anon key.
-- This is appropriate ONLY for a small internal tool whose Supabase URL/key
-- are shared within the team. See README "Security notes" before storing
-- anything sensitive.
alter table members enable row level security;
alter table workstreams enable row level security;
alter table tasks enable row level security;
alter table comments enable row level security;
alter table notifications enable row level security;
alter table knowledge enable row level security;

do $$
declare t text;
begin
  foreach t in array array['members','workstreams','tasks','comments','notifications','knowledge'] loop
    execute format('drop policy if exists "open access" on %I', t);
    execute format('create policy "open access" on %I for all using (true) with check (true)', t);
  end loop;
end $$;

-- Seed example structure (edit freely)
insert into workstreams (name) values
  ('Well Construction'), ('Sensors'), ('Materials'), ('Policy & Partnerships')
on conflict do nothing;
