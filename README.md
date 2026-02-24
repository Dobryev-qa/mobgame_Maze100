# Maze 100 (iOS / SwiftUI + SpriteKit)

Maze 100 is an iOS puzzle game with 100 levels where the player slides through maze grids, avoids hazards, and reaches the finish.
## Application Preview


  <img src="https://github.com/Dobryev-qa/mobgame_Maze100/blob/main/App_preview/maze100.gif" width="280"/>

## Tech Stack

- Swift
- SwiftUI
- SpriteKit
- Xcode project (`.xcodeproj`)
- XCTest / XCUITest

## Current Status

Project is in active production-hardening phase.

Already improved:
- game state flow (pause/resume/level complete)
- timer lifecycle
- generator stability (bounded retries + fallback)
- generator diagnostics
- StoreKit 2 foundation
- analytics/crash-reporting facades
- unit tests + UI smoke tests + CI workflow
- Swift 6 readiness fixes (actor-isolation warnings cleanup)

## Features

- Swipe-based movement (slide until obstacle)
- Procedural level generation
- Hazards (holes/spikes)
- Keys / gates
- Portals
- Moving spikes
- Fog of war (high levels)
- Rewarded actions (foundation)
- Audio + haptics
- Progress tracking

## Project Structure

- `Maze 100/Views` - SwiftUI screens and HUD
- `Maze 100/Scenes` - SpriteKit gameplay scene and camera
- `Maze 100/Managers` - generator, store, audio, analytics, etc.
- `Maze 100/Models` - game models and level data
- `Maze 100Tests` - unit tests
- `Maze 100UITests` - UI tests
- `Scripts` - local test runners
- `Docs` - production plan and notes

## Build

Open in Xcode and run the `Maze 100` scheme.

CLI build example:

```bash
xcodebuild -project "Maze 100.xcodeproj" \
  -scheme "Maze 100" \
  -destination "generic/platform=iOS Simulator" \
  CODE_SIGNING_ALLOWED=NO build
```

## Notes

This repository currently focuses on gameplay/core stability and production readiness.
UI redesign is planned for a later phase after core systems are fully stabilized.

## License

TBD
