-- ════════════════════════════════════════════════════════════════════
--  Superhot Rock Task Tracker — Supabase schema
--  HOW TO RUN: copy EVERYTHING in this file (Ctrl/Cmd-A, Ctrl/Cmd-C),
--  paste into Supabase -> SQL Editor -> New query, then click Run.
--  Do NOT paste the file's name or path — paste its contents.
--  Safe to run more than once.
-- ════════════════════════════════════════════════════════════════════

create extension if not exists pgcrypto;

-- ── Tables ──────────────────────────────────────────────────────────

-- Team members. Passwords are SHA-256 hashed in the browser.
-- Convenience-grade auth for an internal team tool, not hardened security.
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

-- ── Indexes (speed up the app's common lookups) ─────────────────────
create index if not exists tasks_ws_idx        on tasks(workstream_id);
create index if not exists tasks_assignee_idx  on tasks(assignee_id);
create index if not exists tasks_deadline_idx  on tasks(deadline);
create index if not exists comments_task_idx   on comments(task_id);
create index if not exists notifs_member_idx   on notifications(member_id, read);
create index if not exists ws_parent_idx       on workstreams(parent_id);

-- ── Realtime: push every change to all open browsers ────────────────
-- Idempotent: skips any table already in the publication.
do $$
declare t text;
begin
  foreach t in array array['members','workstreams','tasks','comments','notifications','knowledge'] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;

-- ── Row Level Security ──────────────────────────────────────────────
-- Open read/write to the anon key. Appropriate ONLY for a small internal
-- tool whose Supabase URL/key are shared within the team.
-- See README "Security notes" before storing anything sensitive.
do $$
declare t text;
begin
  foreach t in array array['members','workstreams','tasks','comments','notifications','knowledge'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "open access" on public.%I', t);
    execute format('create policy "open access" on public.%I for all using (true) with check (true)', t);
  end loop;
end $$;

-- ── Seed starter workstreams (only if the table is empty) ───────────
insert into workstreams (name)
select * from (values ('Well Construction'), ('Sensors'), ('Materials'), ('Policy & Partnerships')) as v(name)
where not exists (select 1 from workstreams);

-- ── Done. Verify: ───────────────────────────────────────────────────
select table_name from information_schema.tables
where table_schema = 'public'
  and table_name in ('members','workstreams','tasks','comments','notifications','knowledge')
order by table_name;
