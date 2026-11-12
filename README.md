# Edgework

A personal training app for iOS (SwiftUI, iOS 17+). It started as off-ice hockey training and now covers general fitness, running, shooting and stickhandling work, and nutrition. Sideloaded, not on the App Store.

## Features

**Today**
- Daily workout generator. Picks whatever you've trained least recently, and adapts to game days (short activation), the day after a game (recovery) and practice days.
- Readiness check-in (sleep, soreness, energy). On a rough day you can lighten the workout by 15% or switch to recovery.
- Daily goals: shots, stickhandling minutes, water, weekly running distance.
- Next game/practice from your team calendar, and your planned workout time.

**Workouts**
- 249 exercises: strength, power, speed, conditioning, core, balance, mobility, walking warm-ups, standing stretches, running, stickhandling, shooting and goalie work. Every one has steps, coaching cues, a front/back muscle map and an animated demo figure.
- Structure: walking dynamic warm-up → static stretches → main set → must-dos → finisher/run → cool-down.
- Review before starting: reorder, swap, refresh blocks, add or remove exercises, change sets.
- Difficulty: global intensity (40–200%) plus per-exercise − / + that the app remembers. "Too easy/too hard" after a workout nudges intensity ±5%.
- Line mode: travelling moves (high knees, carioca, side lunges…) can count line to line instead of time or reps. Global switch, lines-per-set setting and per-exercise override.
- Focuses: Full Body, Upper, Legs, Abs, HIIT, Run Day, Strength, Power, Speed, Conditioning, Core, Hands, Goalie, Mobility, Recovery, Pre-Game Activation.
- 13 built-in programs, a custom workout builder, and your own team warm-up routine.
- Must-dos: mandatory items (e.g. a 2 km run, 100 shots) added to every generated workout.
- Guided player: timers, rest countdowns, set tracking, haptics, sounds, animated figure, easier/harder buttons mid-workout.

**Hockey skills**
- Shot Tracker (by shot type, on-target count, 14-day chart).
- Puck Counter: set your shot goal and how many pucks you own. It runs rounds, counts every puck you pick up, flags missing ones, and logs the shots.
- Aim Trainer: net graphic with random target calls (corners, five hole, bar down), hit/miss accuracy.
- Hands Caller: random stickhandling moves called out on a timer.
- Stickhandling timer, Shift Timer (work/rest intervals), combine tests (vertical, broad jump, sprint, 5-10-5, plank…).

**Fuel**
- 154 built-in foods with macros and what each helps (energy, recovery, hydration, immunity, bones, iron…).
- Online search and barcode scanning through Open Food Facts.
- Meals: breakfast, lunch, dinner, snacks, pre-game, post-workout, drinks.
- Calorie and macro targets from your profile (Mifflin-St Jeor), water tracker, weight log, fuel ideas.

**Schedule & reminders**
- Team calendar: open an `.ics` export (e.g. from Crossbar) with Edgework or paste a webcal/https subscription link. Events are guessed as game/practice and can be corrected.
- Workout time for each weekday, run reminders, water reminders, game-day activation reminder, streak saver, shot-goal nudge.

**Progress**
- Streaks, minutes chart, 15-week consistency grid, weekly muscle heat map, training mix, achievements, full history, manual activity logging (runs, skates, games, gym…).
- JSON backup export/import (worth doing now and then, since sideloaded apps can lose data).

## Building

There's no Xcode on the dev machine, so builds run on GitHub Actions macOS runners:

- `build.yml`: on every push to `main`, generates the project with XcodeGen (`project.yml`), builds unsigned for `iphoneos`, and publishes `Edgework.ipa` on the `latest` release.
- `screenshots.yml` (manual): builds for the simulator, seeds demo data, and captures screens. Launch arguments: `-demoData YES`, `-startTab N`, `-showScreen <exercise-id | today | settings | calendar | routine | log | shots | pucks | aim | addfood | food>`, `-autoStart YES`.

```bash
gh workflow run screenshots.yml
```

Sideload the IPA with AltStore, Sideloadly or TrollStore. Bundle ID: `com.pizza.edgework`.

## Layout

```
Edgework/
  App/        entry point, tabs, debug launch hooks
  Models/     exercises, workouts, settings, daily logs, food
  Data/       exercise library (Library, GeneralLibrary, SkillLibrary), programs, food database + Open Food Facts
  Engine/     workout generator
  Store/      persistence, scheduling, calendar (.ics), notifications, daily tracking
  UI/         theme, components, body map, animated figures
  Views/      screens
tools/make_icon.py   renders the app icon (needs numpy)
```

## Planned

- Track & field mode (events, sprint/jump/throw work, meet schedule).
