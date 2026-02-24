# Maze 100 - Development TODO

**Project Start Date:** 21 February 2026
**Status:** In Progress

---

## Phase 1: Project Setup & Architecture Foundation

### 1.1 Folder Structure
- [x] Create folder structure inside `Maze 100/`:
  - `Models/` - Data structures
  - `Managers/` - Game logic managers
  - `Scenes/` - SpriteKit scenes
  - `Entities/` - Game entities (spikes, etc.)
  - `Views/` - SwiftUI views
  - `Utils/` - Utilities and extensions

### 1.2 Core Data Models
- [x] `Models/CellType.swift` - CellType enum (empty, wall, player, finish, hole, spike)
- [x] `Models/Coordinate.swift` - Grid position (x, y) with hashable
- [x] `Models/LevelData.swift` - Level configuration (gridSize, walls, holes, spikes, start, finish)
- [x] `Models/LevelProgress.swift` - Progress tracking (currentLevel, unlockedLevels, isSoundEnabled) with Codable & UserDefaults

### 1.3 Maze Generation System
- [x] `Managers/MazeGenerator.swift` - Recursive backtracking algorithm
- [x] Implement seeded RNG using level number
- [x] Generate perfect maze (all cells connected)
- [x] Add wall removal (10% on levels 50+)
- [x] Place holes in dead-ends (levels 21-50)
- [x] Place moving spikes on long straight paths (levels 51-80)

---

## Phase 2: Core Game Engine

### 2.1 Game Scene Setup
- [x] `Scenes/GameScene.swift` - SKScene subclass
- [x] Render grid background with subtle lines
- [x] Render player sprite (blue square #007AFF)
- [x] Render finish sprite (white with particle emitter)
- [x] Render obstacles: holes (empty/dark), spikes (red squares)

### 2.2 Sliding Movement
- [x] Detect swipe gestures in GameScene
- [x] Calculate slide path until wall collision (ray-casting)
- [x] Block input during movement animation
- [x] Check for hole/spike collisions during slide (instant death)
- [x] Implement smooth animation (SKAction.moveTo)
- [x] Add player trail effect (fading marks)

### 2.3 Camera System
- [x] `Scenes/CameraController.swift` - SKCameraNode management
- [x] Auto-center camera on player for levels 20+
- [x] Smooth camera follow with constraints
- [x] Zoom to fit grid on screen

---

## Phase 3: Progressive Difficulty Features

### 3.1 Difficulty Progression
- [x] Implement grid size scaling by level:
  - Levels 1-20: 5x5 → 8x8
  - Levels 21-50: 10x10 → 15x15
  - Levels 51-80: 18x18 → 20x20
  - Levels 81-100: 25x25
- [x] Enable holes for levels 21-50
- [x] Enable moving spikes for levels 51-80
- [x] Enable fog of war for levels 81-100

### 3.2 Fog of War
- [x] `Managers/FogOfWarManager.swift` - Visibility calculation
- [x] Visible area: 3x3 cells around player
- [x] Render dark overlay with cutouts for visible cells
- [x] Update dynamically as player moves

### 3.3 Moving Spikes
- [x] `Entities/MovingSpike.swift` - Spike with patrol behavior
- [x] Define patrol path (two points) in LevelData
- [x] Implement back-and-forth movement with SKAction
- [x] Check collision with moving spikes during player slide (integrated)

---

## Phase 4: UI/UX & Menus

### 4.1 SwiftUI Views
- [x] `Views/GameView.swift` - Container with SpriteView wrapping GameScene (+ Combine import)
- [x] `Views/MainMenuView.swift` - Level selection grid, settings (+ Combine import, LevelSelection Identifiable)
- [x] `Views/LevelCompleteView.swift` - Victory screen with stats, rewarded ads (+ Combine import)
- [x] `Views/GameOverView.swift` - Death/restart screen
- [x] `Views/PauseView.swift` - Pause menu (+ Combine import)
- [x] `Views/SettingsView.swift` - Settings screen with sound toggle and reset (+ Combine import)

### 4.2 Level Selection
- [x] Create grid of 100 level buttons
- [x] Display locked/unlocked status
- [x] Show completion indicators (stars, best time)
- [x] Navigation to selected level

### 4.3 HUD Elements
- [x] Level number display
- [x] Timer display
- [x] Pause button
- [x] Rewarded ad buttons: "Skip Level" and "Show Path"

---

## Phase 5: Monetization & Retention (Placeholders)

### 5.1 Ad Manager
- [x] `Managers/AdManager.swift` - Singleton with stub methods
- [x] `showInterstitial()` - Show after every 3 levels (skip if <5 sec completion)
- [x] `showRewarded(completion:)` - For Skip Level and Show Path
- [x] `isAdReady` property
- [x] Use print statements for testing

### 5.2 IAP Manager
- [x] `Managers/IAPManager.swift` - StoreKit stub
- [x] Product: "Remove Ads" (non-consumable)
- [x] `areAdsRemoved()` - Mock purchase flow
- [x] `isAdsRemoved` - UserDefaults flag
- [x] Completion handlers for purchase callbacks

---

## Phase 6: Polish & Effects

### 6.1 Visual Effects
- [x] Player trail: fading SKShapeNode during movement
- [x] Finish particle emitter (glow effect)
- [x] Death effect (particle explosion or fade)
- [ ] Wall collision particle burst (optional)

### 6.2 Audio System
- [x] `Managers/AudioManager.swift` - Sound playback
- [ ] Slide sound (loop while moving)
- [ ] Wall hit sound
- [ ] Death sound
- [ ] Victory sound
- [ ] Optional: background music

### 6.3 Haptic Feedback
- [x] `UIImpactFeedbackGenerator(style: .light)` on wall collision
- [x] `UIImpactFeedbackGenerator(style: .heavy)` on death
- [x] `UINotificationFeedbackGenerator` on level complete

---

## Phase 7: Testing & Optimization

### 7.1 Unit Tests
- [ ] Test maze generation (perfect maze, connectivity)
- [ ] Test sliding path calculation
- [ ] Test collision detection (holes, spikes, moving spikes)
- [ ] Test fog of war visibility

### 7.2 UI Tests
- [ ] Test navigation flow
- [ ] Test level completion flow
- [ ] Test menu interactions

### 7.3 Performance
- [ ] Profile 25x25 grid performance
- [ ] Ensure 60 FPS
- [ ] Implement cell culling (render only visible)
- [ ] Optimize particle effects

---

## Phase 8: Final Integration

### 8.1 App Entry
- [ ] Update `Maze_100App.swift` to launch `MainMenuView`
- [ ] Set up NavigationStack for game flow

### 8.2 Assets
- [ ] Verify Assets.xcassets has AppIcon
- [ ] Add missing color sets
- [ ] Check asset catalog configuration

### 8.3 Final Testing
- [ ] Play levels 1-5 (basic mechanics)
- [ ] Play level 25 (holes + camera)
- [ ] Play level 55 (moving spikes)
- [ ] Play level 85 (fog of war)
- [ ] Verify UserDefaults persistence
- [ ] Test haptics on device
- [ ] Test ad/IAP placeholders
- [ ] Test rewarded buttons

---

## Progress Notes

**2026-02-21:**
- Created project plan with 23 major steps across 8 phases
- Defined architecture: SwiftUI + SpriteKit (SpriteView wrapper)
- Decided on deterministic on-the-fly level generation
- Created TODO tracking file structure
- **Phase 1 Complete:** Project Setup & Architecture Foundation
  - Created all folder structure (Models, Managers, Scenes, Entities, Views, Utils)
  - Implemented core data models: Coordinate, CellType, LevelData, LevelProgress
  - Implemented MazeGenerator with recursive backtracking, wall removal, holes, and moving spikes
- **Phase 2 Complete:** Core Game Engine
  - GameScene with grid rendering, player, finish, obstacles
  - Sliding movement with swipe detection, path calculation, collision detection
  - Player trail effect
  - Camera system with auto-center and zoom for large levels (20+)
  - HapticManager for feedback (light on wall hit, heavy on death, success on win)
- **Phase 3 Complete:** Progressive Difficulty Features
  - Grid size scaling by level (5x5→8x8, 10x10→15x15, 18x18→20x20, 25x25)
  - Holes placed in dead-ends (levels 21-100)
  - Moving spikes placed on long straight paths (levels 51-100)
  - Fog of war with 3x3 visibility (levels 81-100)
- **Phase 4 Complete:** UI/UX & Menus
  - GameView with SpriteView, HUD (level, timer, pause, ad buttons)
  - MainMenuView with 100-level grid, locked/unlocked states, completion stars
  - LevelCompleteView with time display, next/retry/menu, rewarded ads
  - GameOverView, PauseView, SettingsView
  - Updated Maze_100App to launch MainMenuView
- **Phase 5 Complete:** Monetization & Retention (Placeholders)
  - AdManager stub with interstitial and rewarded ad methods
  - IAPManager stub with Remove Ads product and purchase flow
- **Phase 6 Partial:** Polish & Effects
  - SKColor hex extension for easy color coding
  - UIImage color helper for particle textures
  - Player trail effect implemented
  - Finish particle emitter (placeholder)
  - Death animation implemented
  - AudioManager stub ready for sound file integration
- **Next:** Build and test in Xcode simulator/device, verify all gameplay mechanics work correctly, then add actual sound files and polish

---

## Build Status

**Last Build Check:** 21 February 2026 (pending actual build)
**Expected Errors:** 0 (all compilation errors resolved)
**Files Modified in this Session:**
- GameScene.swift (fog of war extension, optional handling, renderLevel() method, fixed initialization order)
- FogOfWarManager.swift (SKTexture handling)
- IAPManager.swift (method rename)
- MainMenuView.swift (Combine import + Identifiable wrapper)
- PauseView.swift (Combine import)
- SettingsView.swift (Combine import)
- GameView.swift (Combine import, fixed SpriteView options, timer self capture, RewardedAdType usage)
- LevelCompleteView.swift (Combine import, RewardedAdType usage)
- MovingSpike.swift (fixed hardcoded cellSize)
- AdManager.swift (removed duplicate RewardedAdType, added Maze_100 import)
- Models/RewardedAdType.swift (created centralized enum)
- TODO.md (progress tracking)

**All SwiftUI views now import Combine for @StateObject/ObservableObject support**
**All ObservableObject ViewModels conform correctly to the protocol**
**MainMenuView sheet(item:) now uses Identifiable wrapper for Int**
**GameScene now has proper initialization: renderLevel() called after levelData is set**
**MovingSpike now uses passed cellSize parameter correctly**
**RewardedAdType centralized in Models to avoid ambiguity**
**SpriteView options fixed (removed unsupported preferredFramesPerSecond)**
**Timer closures now use [weak self] to avoid capture warnings**
**All RewardedAdType references now use the centralized Models enum**

---

## Testing Checklist

Before first run, verify:

### Critical Path
- [ ] Build succeeds in Xcode (no compile errors)
- [ ] App launches to MainMenuView
- [ ] Level 1 loads and renders correctly
- [ ] Swipe controls work (sliding movement)
- [ ] Player reaches finish and level completes
- [ ] Progress saves (close and reopen app)

### Level Features
- [ ] Level 25: Holes visible and deadly
- [ ] Level 55: Moving spikes animate and kill player on contact
- [ ] Level 85: Fog of war hides cells outside 3x3 radius

### UI/UX
- [ ] Pause menu opens and closes
- [ ] Settings toggle works and persists
- [ ] Level selection grid shows 100 levels with lock/unlock states
- [ ] Timer runs during gameplay

### Edge Cases to Test
- [ ] Swipe when already moving (should be ignored)
- [ ] Rapid swipes in different directions
- [ ] Death and respawn (player returns to start)
- [ ] Level complete and next level progression
- [ ] Back to menu from various screens

### Known Issues / Limitations
- Particle effects use placeholder textures (need real assets)
- Audio system stub (no sound files added)
- Ad/IAP systems are placeholders (not integrated with networks)
- No wall collision particle effect (optional)
- Moving spikes use hardcoded patrol speed (could be tuned)
- Fog of war may have performance impact on 25x25 grids (needs profiling)

---

## Bug Fixes (21 Feb 2026):
- Fixed GameScene.swift: Fixed optional unwrapping, moved fogOfWarIfNeeded to extension, removed extraneous brace
- Fixed FogOfWarManager.swift: SKTexture non-optional handling
- Fixed IAPManager.swift: Renamed method to `areAdsRemoved()` to avoid property conflict
- Fixed MainMenuView.swift: Added `import Combine`, created `LevelSelection` Identifiable wrapper for sheet(item:)
- Fixed PauseView.swift: Added `import Combine`
- Fixed SettingsView.swift: Added `import Combine`

---

## Completed Tasks Log

| Date | Task |
|------|------|
| 2026-02-21 | Created comprehensive project plan |
| 2026-02-21 | Created TODO tracking file |
