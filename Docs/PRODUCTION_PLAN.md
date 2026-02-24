# Maze 100 Production Plan

Статус: `In Progress`

Этот файл является рабочим roadmap для доведения игры до production.
Исполнение ведется по фазам с приоритетом `P0 -> P1`.

## Фазы

- [x] Phase A (P0): Critical Stabilization
  - [x] A1. Исправить lifecycle таймера (`GameViewModel`)
  - [x] A2. Исправить flow смерти/респавна/`Game Over`
  - [x] A3. Исправить `Pause/Exit` behavior
- [x] Phase B (P0/P1): Gameplay State Architecture Refactor
- [~] Phase C (P0): Generator/Solver Correctness (in progress)
- [~] Phase D (P0/P1): Monetization/Store Consolidation (in progress)
- [~] Phase E (P1): Performance & Runtime Quality (in progress)
- [~] Phase F (P0/P1): Tests Strategy (in progress)
- [~] Phase G (P1): Swift 6 / Concurrency Readiness (in progress)
- [~] Phase H (P1): Production Features & LiveOps Foundation (in progress)
- [~] Phase I (P0): App Store Readiness (in progress)
- [~] Phase J (P1): CI/CD и релизный процесс (in progress)

## Definition of Done (release gate)

- Нет P0/P1 багов в gameplay state.
- Генератор не зависает, уровни валидны и проходимы.
- Монетизация работает в sandbox/TestFlight.
- Есть crash reporting и analytics.
- Есть unit + smoke UI tests в CI.
- Release build без критичных warning/error.

## Progress Log

- 2026-02-23: План сохранен. Начато исполнение с Phase A.
- 2026-02-23: Phase A (первая итерация) выполнена: таймер/пауза/выход/notifications смерти-рэспавна исправлены, сборка успешна.
- 2026-02-23: Phase B (итерация 1) начата: введен `GameSessionState`, `GameScene` -> `GameViewModel` callbacks, `GameView` переведен с gameplay `NotificationCenter` на state-driven flow, сборка успешна.
- 2026-02-23: Phase C (итерация 1) начата: генератор ограничен по попыткам, добавлен fallback-уровень и диагностика seed/attempts, `Solver` синхронизирован с `key/gate` state (`hasKey`), сборка успешна.
- 2026-02-23: Phase B завершена: удалены legacy gameplay `NotificationCenter` публикации (`GameScene`, `LevelCompleteView` fallback), основной flow полностью state/callback-driven.
- 2026-02-23: Phase F начата: добавлены unit/smoke tests для `LevelProgress` и `MazeGenerator`; запуск `xcodebuild test` для `Maze 100Tests` требует отдельной стабилизации test-runner (схема зависает после сборки).
- 2026-02-23: Phase G начата: data models (`GridCoordinate`, `LevelData`, `MovingSpikeData`, `LevelProgress`, `Direction`) помечены `nonisolated`, warning по actor-isolated `Hashable` conformance в `LevelData` убран; build проходит.
- 2026-02-23: Phase D (итерация 1) начата: `StoreManager` стал источником истины для purchased products / ad-free, `AdManager` переведен на чтение из `StoreManager`, `IAPManager` оставлен как legacy callback-adapter поверх `StoreManager`.
- 2026-02-23: Phase E (итерация 1) начата: `FogOfWarManager` получил защиту `UIGraphicsEndImageContext()` на раннем выходе и переиспользование `SKSpriteNode`/кэш render key; `AudioManager` получил idempotent `setMuted(_:)`, `SettingsViewModel` исправлен от toggle-багов при инициализации.
- 2026-02-23: Phase F (итерация 2): добавлена shared-схема `Maze 100 UnitTests` и скрипт `Scripts/run_unit_tests.sh`; unit tests стабильно запускаются через новую схему и проходят (`TEST SUCCEEDED`).
- 2026-02-23: Phase C (итерация 2): исправлен дефект генератора — порталы больше не размещаются на `start`/`finish`/primary path; тест инвариантов порталов проходит.
- 2026-02-23: Phase E (итерация 2): исправлен lifecycle камеры/нод при `renderLevel()` после `removeAllChildren()` — камера переattachивается через `CameraController.ensureCameraAttached()`, очищаются `fogOfWar`/moving spikes transient state.
- 2026-02-23: Phase F (итерация 3): добавлены дополнительные unit tests генератора (детерминизм seed-level и portal endpoint invariants), тесты проходят через `Maze 100 UnitTests`.
- 2026-02-23: Phase D (итерация 2): `StoreManager` переведен на реальный `StoreKit 2` flow (`Product.products`, `purchase()`, `Transaction.updates`, verification handling) с безопасным mock fallback при отсутствии StoreKit config.
- 2026-02-23: Phase C (итерация 3): добавлен diagnostics API генератора (`generateLevelDataWithDiagnostics`) и batch-metrics unit test по уровням 1...100; текущие метрики стабильны (`avgAttempts=17.7`, `maxAttempts=109`, `fallbackCount=0`).
- 2026-02-23: Phase D (итерация 3): `SettingsView` подключен к StoreKit metadata (`displayPrice`, loading/error/busy state) через `StoreManager`, убран hardcoded-only pricing path.
- 2026-02-23: Phase E (итерация 3): добавлен auto-cleanup одноразовых particle nodes в `GameScene` (wall-hit sparks, death explosion, victory confetti) для снижения риска роста `node count` в длинной сессии.
- 2026-02-23: Phase H (итерация 1) начата: добавлен `AnalyticsManager` (lightweight facade + buffered events + console logging), подключены ключевые события gameplay (`level_start` с generator diagnostics, `pause/resume`, `player_death`, `level_complete`, rewarded placeholder) и события монетизации/restore/progress reset.
- 2026-02-23: Phase E (итерация 4): `AudioManager` и `HapticManager` получили app lifecycle hooks (`didBecomeActive`) для повторной подготовки audio session/haptics после возврата приложения.
- 2026-02-23: Phase F/J (итерация 4): `Scripts/run_unit_tests.sh` переведен на `build-for-testing + test-without-building`, добавлен `-derivedDataPath` и portable destination (`IOS_TEST_DESTINATION` / `iPhone 16`), подтверждено `TEST EXECUTE SUCCEEDED`.
- 2026-02-23: Phase G (итерация 2): `CellType` помечен `nonisolated` + `Sendable`, устранены warnings `LevelData -> CellType.isWalkable/isDeadly` в nonisolated context (в build остается только benign AppIntents metadata warning).
- 2026-02-23: Phase J (итерация 1) начата: добавлен GitHub Actions workflow `.github/workflows/ios-ci.yml` (build + unit tests через `Scripts/run_unit_tests.sh`).
- 2026-02-23: Phase G/E (итерация 3): генерация уровня вынесена с main thread в `Task.detached` с отменой/anti-race (`sceneSetupRequestID`), `GameView` получил loading overlay во время `sessionState == .loading`.
- 2026-02-23: Phase G (итерация 3): генераторный engine (`MazeGenerator.swift`) системно помечен `nonisolated` (generator helpers, solver, RNG, `LevelData.also`) для совместимости с `default-isolation=MainActor`; warning filter снова чистый кроме AppIntents metadata warning.
- 2026-02-23: Phase I (итерация 1) начата: `SettingsView` показывает версию/билд из `Bundle` вместо хардкода, добавлен `.gitignore` для `.codex-derived-data` (создаётся test runner'ом).
- 2026-02-23: Phase J (итерация 2): `Scripts/run_unit_tests.sh` получил auto-detect iOS Simulator destination через `xcodebuild -showdestinations`; убран хрупкий name-only simulator destination из CI workflow.
- 2026-02-23: Phase J/I (итерация 3): исправлен root-cause с test-runner compatibility — `IPHONEOS_DEPLOYMENT_TARGET` у `Maze 100Tests`/`Maze 100UITests` снижен до `18.6` (вместо `26.2`), `run_unit_tests.sh` подтверждено работает без аргументов (`TEST EXECUTE SUCCEEDED`).
- 2026-02-24: Phase H (итерация 2): добавлен `CrashReportingManager` (facade + breadcrumbs + error recording), подключены breadcrumbs для `app lifecycle` и `GameSessionState` transitions, ошибки `StoreManager` (`loadProducts/purchase/restore/transactionUpdates`) отправляются в crash/diagnostics слой.
- 2026-02-24: Phase F/J (итерация 5): добавлены UI smoke tests (`Settings` open/close, `Level 1 -> pause/resume`) с accessibility identifiers в `MainMenuView/SettingsView/GameView/PauseView`; добавлена shared-схема `Maze 100 UITests`, скрипт `Scripts/run_ui_smoke_tests.sh` и CI job `ui-smoke` в `.github/workflows/ios-ci.yml`. Локальный прогон UI tests подтвержден (`TEST EXECUTE SUCCEEDED`), затем script ограничен только на 2 smoke-теста (без template launch/performance tests).
- 2026-02-24: Phase D/I (итерация 4): `StoreManager` mock purchase fallback/persisted mock entitlements ограничены `DEBUG`-режимом (`allowsMockStoreFallback`), в release при отсутствии StoreKit metadata возвращается `StoreError.productNotFound` + diagnostics/analytics instead of silent mock purchase.
- 2026-02-24: Phase E/F (итерация 5): gameplay HUD actions (`pause`, rewarded buttons) отключены вне `.playing` state (устранен edge-case interaction during level loading), `GameViewModel.stopSession()` теперь освобождает `gameScene`; из `Maze_100UITests` удален шаблонный `testLaunchPerformance` для ускорения ручных UI test прогонов.
