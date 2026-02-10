# burzen-td-prototype

Open-source Android prototype for **BURZEN Tower Defense v0.00.1**.

## What this is

A geometry-only, touch-first prototype that proves the BURZEN core loop:

- Place towers with tap
- Enemies move left → right
- Tower firing generates heat
- Overheated towers disable
- WASMUTABLE pressure cycles continuously mutate thermal coefficients
- Enemy breach causes loss
- Tap or two-finger reset restarts simulation

## What this is not

- Not a polished game
- Not content complete
- Not narrative-enabled
- Not monetized
- Not tutorialized with in-game explanatory text

## Install APK

1. Download `BurzenTD_v0.00.1.apk` from GitHub Releases.
2. Enable installation from unknown sources on your Android device.
3. Install and launch in portrait orientation.

APK artifacts are tracked in `builds/v0.00.1/` for release packaging.

## Controls

- **Tap (empty space):** place tower (up to max count)
- **Long-press tower:** heat highlight pulse
- **Two-finger tap:** hard reset run

## Known limitations (v0.00.1)

- One map only
- No UI text overlays during gameplay
- No settings/menu shell
- Placeholder geometry and flat colors only
- Straight-path enemy routing baseline

## Roadmap

- **v0.00.2:** vector flow visualization
- **v0.00.3:** adaptive enemies
- **v0.01.0:** WASMUTABLE rule shifts

## Repository layout

```
burzen-td-prototype/
├── README.md
├── LICENSE
├── docs/
│   ├── vision.md
│   ├── v0_scope.md
│   ├── thermal_model.md
│   └── roadmap.md
├── android/
│   └── BurzenTD/
├── simulation/
│   └── thermal_reference.py
└── builds/
    └── v0.00.1/
```
