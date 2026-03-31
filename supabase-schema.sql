-- ============================================================
-- Splitly – Supabase Database Schema
-- Run this in: Supabase Dashboard → SQL Editor → Run
-- ============================================================

-- 1. PROFILES (auto-created on signup via trigger)
create table if not exists public.profiles (
  id          uuid references auth.users on delete cascade primary key,
  email       text,
  is_pro      boolean default false,
  pro_until   timestamptz,
  lang        text default 'DE',
  decisions_today  int default 0,
  decisions_reset  date default current_date,
  created_at  timestamptz default now()
);

alter table public.profiles enable row level security;

create policy "Users read own profile"
  on public.profiles for select using (auth.uid() = id);

create policy "Users update own profile"
  on public.profiles for update using (auth.uid() = id);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();


-- 2. ROOMS (Splithead voting sessions)
create table if not exists public.rooms (
  id          uuid default gen_random_uuid() primary key,
  code        text unique not null,
  question    text not null,
  options     jsonb not null default '[]',
  votes       jsonb not null default '{}',
  status      text default 'open',  -- 'open' | 'closed'
  created_by  uuid references auth.users,
  created_at  timestamptz default now(),
  expires_at  timestamptz default (now() + interval '24 hours')
);

alter table public.rooms enable row level security;

create policy "Rooms are publicly readable"
  on public.rooms for select using (true);

create policy "Authenticated users can create rooms"
  on public.rooms for insert with check (auth.uid() is not null);

-- Anyone with the room code can vote (code acts as the access token)
create policy "Anyone can vote in a room"
  on public.rooms for update using (true) with check (true);

-- Enable realtime for live voting
alter publication supabase_realtime add table public.rooms;


-- 3. BILLS (Bill Split sessions)
create table if not exists public.bills (
  id          uuid default gen_random_uuid() primary key,
  code        text unique not null,
  title       text,
  total       numeric(10,2),
  method      text default 'equal',  -- 'equal' | 'each' | 'manual'
  people      jsonb,
  items       jsonb,
  created_by  uuid references auth.users,
  created_at  timestamptz default now()
);

alter table public.bills enable row level security;

create policy "Bills are publicly readable"
  on public.bills for select using (true);

create policy "Authenticated users can create bills"
  on public.bills for insert with check (auth.uid() is not null);

create policy "Bill creator can update"
  on public.bills for update using (auth.uid() = created_by);
