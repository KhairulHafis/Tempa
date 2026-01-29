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
- **UserDefaults**: Local persistence

## Getting started

### 1) Clone the repo

```bash
git clone https://github.com/KhairulHafis/autumnFall.git

