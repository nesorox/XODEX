# burzen-td-prototype

Open-source Android prototype for **BURZEN Tower Defense v0.00.2**.

## What this is

A geometry-first, touch-first prototype that now includes a replayable shell around the BURZEN core loop:

- Landing page / main menu entry flow
- Procedural multi-level gameplay routing
- Tap-based tower placement and thermal overheat behavior
- Triangle enemies that follow generated paths
- Wave/lives loop with win/lose state transitions

## What this is not

- Not a polished game
- Not content complete
- Not narrative-enabled
- Not monetized
- Not tutorialized with in-game explanatory text

## Android Install

1. Download the latest APK from GitHub Releases.
2. Enable "Install unknown apps" on your Android device.
3. Install and launch in portrait orientation.

APK artifacts are tracked under `builds/` for release packaging.

## Build release APK from source

1. Install Godot 4 with Android export templates.
2. Configure Android release keystore fields in `android/BurzenTD/export_presets.cfg`.
3. Run:

```bash
./scripts/build_apk.sh
```

## Validate simulation + release checks

Run the consolidated test gate:

```bash
./scripts/run_tests.sh
```

This runs thermal model regression checks and validates release export metadata via dry-run.

## Controls

### Menu
- **Play:** starts a seeded procedural run from Level 0 and advances through Level 1000 before cycling
- **Seed field:** enter text or a number to generate a deterministic, shareable run
- **Settings:** placeholder status text
- **Quit:** exits app

### Gameplay
- **Tap (empty space):** place tower (up to max count)
- **Long-press tower:** heat highlight pulse
- **Two-finger tap:** retry current level seed

## Prototype features in v0.00.2

- Main menu as project entry scene (`MainMenu.tscn`)
- Level manager singleton for run state/progression
- Generated path variants (straight, zig-zag, S-curve, bends, stepped)
- Wave counter, lives, score, and win/loss actions
- Return-to-menu and next/retry flow

## Design docs

- WebSim module-level creator spec: `docs/websim_module_level_creator.md`

## Roadmap

- **v0.00.3:** vector flow visualization polish + improved route readability
- **v0.00.4:** adaptive enemies
- **v0.01.0:** WASMUTABLE rule shifts
