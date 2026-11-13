# Edgework

A training app for iOS (SwiftUI, iOS 17+) for hockey and track & field. It covers general fitness, running, shooting and stickhandling, track events, and nutrition. Sideloaded, not on the App Store.

## Features

**Two sports**
- Pick Hockey (ice blue) or Track & Field (red) from the menu at the top of Today or Train.
- Each sport keeps its own settings, calendar, day marks, required and priority exercises. Your name, nutrition profile and feature toggles are shared between them.

**Today**
- Daily workout generator. It picks whatever you've trained least recently and adapts to game or meet days, the day after, and practices.
- Optional "keep my normal workouts" mode: you train after the event and the workout is lighter when you're sore.
- Track meets: separate plans for the day before, meet day and the day after (activation, light, recovery, rest or normal), a meet-day checklist, and a warm-up reminder.
- Readiness check-in, daily goals, next event, coach's notes that cycle on their own.

**Workouts**
- 285 exercises, each with steps, cues, a muscle map and a **3D figure you can drag around**. Stickhandling drills use a **top-down view** of the stick, blade and puck.
- Structure: walking warm-up, static stretches, main set, required items, finisher or run, cool-down.
- Review before starting: reorder, swap, refresh, add or remove exercises.
- Global intensity plus per-exercise − / +. Line mode for travelling moves.
- From the Library: set an exercise's **priority** (it shows up more often) or make it **required** in every workout. Long-press a row, or use the card on the exercise's page.
- Guided player with timers, rest countdowns and haptics. The current set or rest timer also shows on the **Lock Screen and Dynamic Island**.

**Hockey tools**: Shot Tracker, Puck Counter (shot type can change each round), Aim Trainer, Hands Caller, Stickhandling timer, Shift Timer, Combine tests.

**Track tools**: PRs per event (your events first, hand-timed marks), Stopwatch, Pace Calculator, Interval Timer.

**Running**
- GPS runs: live route map, distance, current and average pace, auto-pause, spoken splits, saved history with maps. The run also shows in the Dynamic Island.
- Weekly distance goal and manual run logging.

**Fuel**
- 154 built-in foods plus Open Food Facts search.
- **Scan barcode** and **Scan nutrition facts**: each asks camera or photo library, and the result is saved to My Foods.
- Type any amount of servings, or step with − / +.
- Drinks are logged by volume. Water-like drinks count toward the water goal, and sugary drinks are flagged.
- **Customize** any food and save it as your own (e.g. a plain donut becomes "Lau's maple long john").
- **Diet notes** from the last week: what to eat more of, what to cut back on, and foods to try.
- Meal generator built from your pantry, calorie and macro targets, water and weight tracking.

**Schedule & reminders**
- Calendar from an `.ics` file (e.g. Crossbar) or a subscription link. Events are sorted by four editable word lists: games/meets, practices, meetings and ignore. Each sport has its own defaults.
- Workout time for each weekday, plus run, water, game/meet and streak reminders.

**Progress**: streaks, charts, muscle heat map, history, achievements, JSON backup.

## Building

There's no Xcode on the dev machine, so builds run on GitHub Actions macOS runners:

- `build.yml`: on every push to `main`, generates the project with XcodeGen (`project.yml`), builds unsigned for `iphoneos`, and publishes `Edgework.ipa` on the `latest` release. The IPA includes the `EdgeworkWidgets` extension, which provides the Live Activity.
- `screenshots.yml` (manual): builds for the simulator, seeds demo data, and captures screens. Launch arguments:
  - `-demoData YES`
  - `-startTab N`
  - `-sport track`
  - `-autoStart YES`
  - `-showScreen <exercise-id | today | settings | calendar | routine | log | shots | pucks | aim | addfood | food | diet | drink | editfood | gps | trackmeet | hockeysettings | mealgen | scan | prs | pace>`

```bash
gh workflow run screenshots.yml
```

Sideload the IPA with AltStore, Sideloadly, a signing service or TrollStore. Bundle IDs: `com.pizza.edgework` and `com.pizza.edgework.widgets`. Your certificate's profile has to allow both (a wildcard profile does).

## Layout

```
Edgework/
  App/        entry point, tabs, debug launch hooks
  Models/     exercises, workouts, settings, sport profiles, daily logs, food
  Data/       exercise library, track library, programs, food database + Open Food Facts
  Engine/     workout generator
  Store/      persistence, scheduling, calendar (.ics), notifications, daily tracking, Live Activity
  UI/         theme, components, body map, 2D and 3D figures, top-down stickhandling
  Views/      screens
EdgeworkWidgets/  Lock Screen + Dynamic Island Live Activity
Shared/           code used by the app and the widget extension
tools/make_icon.py   renders the app icon (needs numpy)
```
