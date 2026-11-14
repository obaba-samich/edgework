# Edgework

**A free training app for hockey players, track & field athletes and anyone who wants a real workout every day.** It generates a daily workout that fits your schedule, your equipment and your events, with step-by-step instructions and video demos for every exercise, plus food logging and GPS runs. SwiftUI, iOS 17+.

<p>
  <img src="docs/screenshots/onboarding.png" width="200" alt="Onboarding">
  <img src="docs/screenshots/today.png" width="200" alt="Today">
  <img src="docs/screenshots/exercise.png" width="200" alt="Exercise instructions">
  <img src="docs/screenshots/how-to.png" width="200" alt="How-to during a workout">
</p>
<p>
  <img src="docs/screenshots/track.png" width="200" alt="Track mode">
  <img src="docs/screenshots/library.png" width="200" alt="Library">
  <img src="docs/screenshots/fuel.png" width="200" alt="Food log">
  <img src="docs/screenshots/diet-notes.png" width="200" alt="Diet notes">
</p>

## Install

Edgework isn't on the App Store. Download `Edgework.ipa` from the [latest release](../../releases/latest) and sideload it with one of these:

- [AltStore](https://altstore.io) or [Sideloadly](https://sideloadly.io) with a free Apple ID. You have to re-sign every 7 days.
- A paid Apple Developer account or a signing service.
- [TrollStore](https://github.com/opa334/TrollStore), on supported iOS versions.

The app includes a small widget extension (`com.pizza.edgework.widgets`) for the Lock Screen and Dynamic Island timers. A wildcard provisioning profile covers it. If your signer drops it, the app still works, just without Live Activities.

## What's inside

**Daily workouts**
- A generator that rotates strength, power, speed, conditioning, core and mobility, picking whatever you've trained least recently.
- Adapts to game and meet days (short activation), the day after (recovery), practices and rest days. Or keep your normal workouts and train after the event, with less volume when you're sore.
- Review before starting: reorder, swap, refresh or remove anything. Global intensity slider plus −/+ on any single exercise, which the app remembers.
- Set any exercise's **priority** on a 7-step scale from Rarely to Max, with Normal in the middle, or make it **required** (in every workout), from the Library.
- Line mode for travelling warm-ups (high knees, carioca, side lunges) instead of time.

**290+ exercises with instructions**
- Every exercise has written steps, coaching cues, a muscle map and why it helps.
- "Watch a demo" opens real form videos for that exercise on YouTube.
- Hill workouts (jog up & down, repeats, sprints, power walks, bounds) show up when you add Hill / Ramp to your equipment. They count trips, not time: up builds endurance, down trains you to catch yourself. Every climb is timed so you can see your uphill speed change, rep to rep and against last time.
- In the guided player, "How to" opens the steps without leaving your workout. The current set or rest timer shows on the Lock Screen and Dynamic Island.

**Hockey**
- Shot tracker and a puck counter that plans rounds for the pucks you own and catches lost ones.
- Aim trainer with random or custom shot lists (shot type + target), using the same puck rounds as the counter. Every called shot counts toward today's shots.
- Hands caller, shift timer and combine tests.
- Position-aware training for forwards, defense and goalies.

**Track & field**
- Pick your events in setup. Daily workouts and drill priorities are built around them: sprints, hurdles, distance, jumps, throws.
- Plans for the day before, the day of and the day after a meet, a meet-day checklist and a warm-up reminder.
- PRs per event, stopwatch, pace calculator, interval timer.

**Running**
- GPS runs with a live route map, pace, auto-pause, spoken splits and saved history.

**Fuel**
- 150+ built-in foods with what each helps (energy, recovery, iron and so on), plus Open Food Facts search.
- Scan a barcode or a nutrition label, from the camera or a photo. Scans are saved to My Foods.
- Customize any food and save your own version.
- Drinks are logged by volume, and water-like drinks count toward your water goal.
- Diet notes from your last week: what to eat more of, what to cut back on, and foods to try.
- A meal generator that uses your pantry.

**Schedule & reminders**
- Import any team calendar (TeamSnap, Crossbar, SportsEngine, Google…) by link or `.ics` file.
- Events are sorted with editable keyword lists (Settings › Schedule › Keywords) for games or meets, practices, meetings and things to ignore.
- Reminders for workout times by day, streak saver, water (your hours), runs, game lead time and meet warm-up.

**Progress**: streaks, charts, muscle heat map, history, benchmarks, JSON backup.

## Privacy

Everything stays on your phone, and there's no account and no analytics. The only network requests are food searches to Open Food Facts and the calendar link you add. "Watch a demo" just opens YouTube in your browser.

## Building

The project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen
xcodegen generate
open Edgework.xcodeproj
```

CI (`.github/workflows/build.yml`) builds an unsigned IPA on every push to `main` and publishes it to the `latest` release. `screenshots.yml` runs the app in the simulator with demo data (`-demoData YES`, `-startTab N`, `-sport track`, `-showScreen <exercise-id | settings | howto | diet | …>`).

## Layout

```
Edgework/
  App/        entry point, tabs, debug launch hooks
  Models/     exercises, workouts, settings, sport profiles, food
  Data/       exercise library, track and hill libraries, programs, foods
  Engine/     workout generator
  Store/      persistence, scheduling, calendar, notifications, Live Activity
  UI/         theme, components, body map
  Views/      screens
EdgeworkWidgets/  Lock Screen + Dynamic Island
Shared/           code shared with the widget
tools/            icon renderer
```

## Credits & license

- Food data: [Open Food Facts](https://world.openfoodfacts.org), available under the [ODbL](https://opendatacommons.org/licenses/odbl/1-0/).
- Not medical advice. Warm up, and stop if something hurts.
- MIT licensed. See [LICENSE](LICENSE).
