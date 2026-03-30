-- Splitly Supabase Schema
-- Führe dieses SQL in deinem Supabase SQL Editor aus

-- Rooms (Gruppenentscheide)
create table rooms (
  id uuid default gen_random_uuid() primary key,
  code text not null unique,
  question text not null,
  options jsonb not null default '[]',
  votes jsonb not null default '{}',
  status text not null default 'open', -- open | closed
  created_at timestamp with time zone default now(),
  expires_at timestamp with time zone default (now() + interval '24 hours')
);

-- Bills (Abrechnungen)
create table bills (
  id uuid default gen_random_uuid() primary key,
  code text not null unique,
  title text not null,
  total numeric not null,
  method text not null default 'equal', -- equal | each | manual
  people jsonb not null default '[]',
  items jsonb not null default '[]',
  created_at timestamp with time zone default now()
);

-- Users (optional — für Pro-Nutzer)
create table profiles (
  id uuid references auth.users primary key,
  email text,
  is_pro boolean default false,
  pro_until timestamp with time zone,
  lang text default 'DE',
  decisions_today integer default 0,
  decisions_reset date default current_date,
  created_at timestamp with time zone default now()
);

-- Row Level Security
alter table rooms enable row level security;
alter table bills enable row level security;
alter table profiles enable row level security;

-- Policies — öffentlich lesbar, jeder kann erstellen
create policy "rooms_read" on rooms for select using (true);
create policy "rooms_insert" on rooms for insert with check (true);
create policy "rooms_update" on rooms for update using (true);

create policy "bills_read" on bills for select using (true);
create policy "bills_insert" on bills for insert with check (true);

create policy "profiles_own" on profiles for all using (auth.uid() = id);

-- Realtime für Live-Abstimmungen
alter publication supabase_realtime add table rooms;
