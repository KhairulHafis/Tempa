create extension if not exists pgcrypto;

create table if not exists public.workout_sessions (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
    reps_completed integer not null check (reps_completed >= 0),
    time_taken integer not null check (time_taken >= 0),
    goal integer not null check (goal > 0),
    date timestamptz not null default timezone('utc', now()),
    created_at timestamptz not null default timezone('utc', now())
);

create index if not exists workout_sessions_user_date_idx
    on public.workout_sessions (user_id, date desc);

alter table public.workout_sessions enable row level security;

drop policy if exists "Users can read own sessions" on public.workout_sessions;
create policy "Users can read own sessions"
    on public.workout_sessions
    for select
    using (auth.uid() = user_id);

drop policy if exists "Users can insert own sessions" on public.workout_sessions;
create policy "Users can insert own sessions"
    on public.workout_sessions
    for insert
    with check (auth.uid() = user_id);

drop policy if exists "Users can update own sessions" on public.workout_sessions;
create policy "Users can update own sessions"
    on public.workout_sessions
    for update
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);
