-- Unnamed Band — Supabase schema
-- Run this once in your project's SQL Editor (Supabase Dashboard → SQL Editor → New query → Run).

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------
-- profiles: links a Supabase Auth account to one of the four fixed
-- band-member identities. One account per member.
-- ---------------------------------------------------------------------
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  member_key text not null unique check (member_key in ('sol','daeseong','linda','matthew')),
  created_at timestamptz not null default now()
);

alter table profiles enable row level security;

create policy "profiles are readable by anyone"
  on profiles for select
  using (true);

create policy "users can create their own profile"
  on profiles for insert
  with check (auth.uid() = id);

-- ---------------------------------------------------------------------
-- availability: one row per date + half-day + member who marked
-- themselves free. Toggling in the UI = insert or delete a row.
-- ---------------------------------------------------------------------
create table if not exists availability (
  id bigint generated always as identity primary key,
  date date not null,
  half text not null check (half in ('am','pm')),
  member_key text not null references profiles(member_key) on delete cascade,
  created_at timestamptz not null default now(),
  unique (date, half, member_key)
);

alter table availability enable row level security;

create policy "availability readable by signed-in members"
  on availability for select
  using (auth.role() = 'authenticated');

create policy "members mark their own availability"
  on availability for insert
  with check (member_key = (select member_key from profiles where id = auth.uid()));

create policy "members remove their own availability"
  on availability for delete
  using (member_key = (select member_key from profiles where id = auth.uid()));

-- ---------------------------------------------------------------------
-- rehearsals: one planned rehearsal per date (date/time/location/note).
-- Any signed-in member can plan or cancel one.
-- ---------------------------------------------------------------------
create table if not exists rehearsals (
  date date primary key,
  time time,
  location text,
  note text,
  created_by text references profiles(member_key),
  updated_at timestamptz not null default now()
);

alter table rehearsals enable row level security;

create policy "rehearsals readable by signed-in members"
  on rehearsals for select
  using (auth.role() = 'authenticated');

create policy "signed-in members can plan rehearsals"
  on rehearsals for insert
  with check (auth.role() = 'authenticated');

create policy "signed-in members can update rehearsals"
  on rehearsals for update
  using (auth.role() = 'authenticated');

create policy "signed-in members can cancel rehearsals"
  on rehearsals for delete
  using (auth.role() = 'authenticated');

-- ---------------------------------------------------------------------
-- board_posts: links / notes shared on the board. Only the author can
-- delete their own post.
-- ---------------------------------------------------------------------
create table if not exists board_posts (
  id uuid primary key default gen_random_uuid(),
  author_member_key text not null references profiles(member_key) on delete cascade,
  title text not null,
  url text,
  note text,
  created_at timestamptz not null default now()
);

alter table board_posts enable row level security;

create policy "board readable by signed-in members"
  on board_posts for select
  using (auth.role() = 'authenticated');

create policy "members post as themselves"
  on board_posts for insert
  with check (author_member_key = (select member_key from profiles where id = auth.uid()));

create policy "members delete their own posts"
  on board_posts for delete
  using (author_member_key = (select member_key from profiles where id = auth.uid()));

-- ---------------------------------------------------------------------
-- Realtime: broadcast changes so every open tab updates live.
-- ---------------------------------------------------------------------
alter publication supabase_realtime add table availability, rehearsals, board_posts;
