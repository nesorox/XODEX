# XODEX (BURZEN Tower Defense) - AI Context Reference

This repository has been optimized to minimize context usage for AI-assisted development. Non-essential files, documentation, web modules, and external simulations have been removed to keep the token footprint as small as possible.

## Project Overview
- **Engine**: Godot 4.6.1.stable
- **Language**: GDScript (Strict static typing expected)
- **Root Path**: `android/BurzenTD/`
- **Core Game**: BURZEN Tower Defense - a mobile-first tower defense game featuring deterministic thermal mechanics, procedural waves, and a residue based "protein tower" system.

## Core Directives for AI Assistants
To ensure efficient and accurate assistance, adhere to the following rules when working in this repository:

1. **Minimize File Reads**: Only read files directly relevant to the current user prompt. Avoid recursive grepping or listing of directories unless strictly necessary to locate a specific component.
2. **Key Architecture Locations**:
   - `android/BurzenTD/scripts/` - Core GDScript logic.
     - *Simulation/State*: `ResidueEngine.gd`, `HeatEngine.gd`, `AffinityTable.gd`, `TowerGraph.gd`.
     - *Flow/Loop*: `level_scene.gd`, `level_manager.gd`, `main.gd`.
   - `android/BurzenTD/scenes/` - Base Godot scene files (`.tscn`).
   - `android/BurzenTD/ui/` - UI components (menus, overlays, campaigns).
   - `android/BurzenTD/towers/` - Tower specific logic and visuals.
3. **GDScript Strict Typing Requirements**: The project enforces strict typing with `Treat warnings as errors`. 
   - All script edits must preserve and utilize static typing (e.g., `var count: int = 5`, `func initialize() -> void:`). 
   - Ensure typed arrays are used where appropriate (`Array[Node]`).
   - Leave no `Variant` inference warnings.
4. **Godot 4.x Conventions**: Rely on modern Godot 4.x semantics: `Callable` for signals, `await` for coroutines, heavily use `@export` annotations, and scene-tree integration over singletons where appropriate.
5. **Precise Modifications**: When asked to make a change, modify the minimal amount of code necessary. Do not rewrite functions simply to change formatting, this saves generation tokens and keeps the diff clean.

## Quick Start (Human/Developer View)
1. Open `android/BurzenTD/project.godot` in Godot 4.6.1.
2. Build via Android export presets (`android/BurzenTD/export_presets.cfg`) or run locally.
3. Keep **Treat warnings as errors** enabled in Project Settings.
