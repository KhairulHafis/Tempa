# Tempa: Pull-Up Workout Tracker

Tempa is an iOS app that tracks pull-up workouts using your iPhone’s camera and Apple’s Vision framework. Set a rep goal, align your pull-up bar during setup, and let the app count reps automatically while you train....

## Features

- **Pull-up goal setting**: Set a target number of reps before each session.
- **Bar setup with camera**: Mark the pull-up bar position for consistent, accurate tracking.
- **Automatic rep counting**: Uses computer vision to track movement and count completed pull-ups.
- **Workout summary**: Review reps, duration, and whether you hit your goal right after the session.
- **Stats and history**: Track progress over time with charts, streaks, and workout history.

## How it works

1. **Set your goal**: Enter the number of pull-ups you want to complete.
2. **Bar setup**: Take a photo and tap both ends of your pull-up bar.
3. **Get ready**: The app tracks your wrists and waits for you to align with the bar.
4. **Start pull-ups**: The timer starts and reps are counted automatically.
5. **View results**: See your session summary and updated stats.

## Tech stack

- **SwiftUI**: UI and navigation
- **AVFoundation**: Camera capture
- **Vision**: Body pose detection
- **Charts**: Data visualization
- **Supabase Auth + PostgREST**: User auth and cloud workout history
- **Keychain + UserDefaults**: Secure session storage and per-user local cache

## Getting started

### 1) Clone the repo

```bash
git clone https://github.com/KhairulHafis/Tempa.git
```

### 2) Configure Supabase auth

The app now requires two configuration values for authentication:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

You can set these either:

- In your Xcode scheme environment variables, or
- As Info.plist keys (`SUPABASE_URL`, `SUPABASE_ANON_KEY`)

### 3) Create Supabase table + RLS policies

Run the SQL in `supabase/workout_sessions.sql` inside your Supabase SQL editor.

This creates `public.workout_sessions` and enables row-level security so users can only read/write their own sessions.

### 4) Run in Xcode

Open `Tempa.xcodeproj`, choose an iOS Simulator, and run the `Tempa` scheme.

## Supabase auth flow implemented

- Email/password sign up
- Email/password sign in
- Session persistence across app launches
- Access-token refresh when session is expired
- Sign out from app

## Data persistence implemented

- Auth session stored in iOS Keychain
- Workout sessions cached locally per user ID
- Workout sessions synced to Supabase table per authenticated user
