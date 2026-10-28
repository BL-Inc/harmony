-- Apply to a fresh Supabase project, after reviewing your tenancy requirements.
create extension if not exists pgcrypto;

create table if not exists public.harmony_spaces (
  space_id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (length(trim(name)) between 1 and 120),
  created_at timestamptz not null default now()
);

create table if not exists public.harmony_space_members (
  space_id uuid not null references public.harmony_spaces(space_id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('owner','admin','member')),
  created_at timestamptz not null default now(),
  primary key (space_id, user_id)
);

create table if not exists public.harmony_rooms (
  room_id uuid primary key default gen_random_uuid(),
  cf_room_id text,
  space_id uuid references public.harmony_spaces(space_id) on delete set null,
  host_user_id uuid not null references auth.users(id) on delete cascade,
  room_type text not null check (room_type in ('video','audio','screen')),
  duration_secs integer check (duration_secs is null or duration_secs >= 0),
  created_at timestamptz not null default now(),
  ended_at timestamptz
);

create index if not exists harmony_rooms_host_created_idx
  on public.harmony_rooms (host_user_id, created_at desc);
create index if not exists harmony_rooms_space_created_idx
  on public.harmony_rooms (space_id, created_at desc);

alter table public.harmony_spaces enable row level security;
alter table public.harmony_space_members enable row level security;
alter table public.harmony_rooms enable row level security;

create policy "space owner can read" on public.harmony_spaces
  for select to authenticated using (owner_id = auth.uid());
create policy "space owner can create" on public.harmony_spaces
  for insert to authenticated with check (owner_id = auth.uid());
create policy "space owner can update" on public.harmony_spaces
  for update to authenticated using (owner_id = auth.uid())
  with check (owner_id = auth.uid());
create policy "space owner can delete" on public.harmony_spaces
  for delete to authenticated using (owner_id = auth.uid());

create policy "members can read own membership" on public.harmony_space_members
  for select to authenticated using (user_id = auth.uid());

create policy "host can read own rooms" on public.harmony_rooms
  for select to authenticated using (host_user_id = auth.uid());
create policy "host can create own rooms" on public.harmony_rooms
  for insert to authenticated with check (host_user_id = auth.uid());
create policy "host can update own rooms" on public.harmony_rooms
  for update to authenticated using (host_user_id = auth.uid())
  with check (host_user_id = auth.uid());
create policy "host can delete own rooms" on public.harmony_rooms
  for delete to authenticated using (host_user_id = auth.uid());

-- Membership and invite management should be implemented through reviewed RPCs
-- or a trusted server, with authorization checks and rate limiting.
