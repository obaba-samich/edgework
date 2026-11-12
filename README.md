# Edgework

Off-ice hockey training app for iOS (SwiftUI, iOS 17+). Personal use, sideloaded.

- Daily workout generator that adapts to game/practice days, season phase, position and equipment
- 120+ hockey exercises with steps, cues, muscle maps
- Global intensity plus per-exercise −/+ that's remembered
- Guided player with timers, rest, haptics; history, streaks, charts, combine tests

Build: push to `main`; GitHub Actions (macOS) runs XcodeGen + xcodebuild unsigned and publishes `Edgework.ipa` on the `latest` release. Sideload with AltStore, Sideloadly or TrollStore.

Icon: `tools/make_icon.py` (needs numpy).
