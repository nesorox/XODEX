# CODEX Instruction Set — v0.002

## Version
- Instruction set version: **v0.002**
- Applies to: **XODEX / BURZEN TD prototype workflow**

## Purpose & justification
This document is the authoritative engineering governance baseline for implementation, contribution discipline, simulation behavior, and release readiness.

## Input / output behavior
- **Inputs:** code changes, documentation updates, build/test scripts, release tags.
- **Outputs:** semver-aligned artifacts, traceable commits, reproducible simulation behavior.

## Core policy summary
1. Scope is limited to the geometry-only Android prototype and core simulation loop.
2. Semantic versioning progression: v0.00.1 → v0.00.2 → v0.00.3 → v0.01.0.
3. Branch conventions: `main`, `feature/*`, `fix/*`, `release/*`.
4. Canonical simulation rules (tower placement, enemy movement, thermal behavior, breach loss, reset) remain stable unless explicitly versioned.
5. Scripts must validate release correctness and exit nonzero on errors.
6. Tests must be runnable via one script and cover simulation behavior + release validation.
7. Documentation in `docs/` must include version header, purpose, I/O behavior, examples (where applicable), and changelog.
8. Release readiness requires passing tests, updated docs, tagged versioning, and generated artifacts.

## Examples
- `./scripts/run_tests.sh` validates thermal behavior and release metadata checks before staging release work.
- `./scripts/build_release_apk.sh --dry-run` validates configuration without requiring a local Godot install.

## Change log
- **v0.002:** Initial repository codification of the provided CODEX instruction set.
