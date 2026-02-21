# XODEX Immutable Archive

The `archive/` tree is the immutable reference layer for XODEX.

- Content is frozen after landing and treated as deterministic source material.
- Changes should be introduced only through an explicit release/update process.
- Daily and CI checks should run `scripts/rock-archive.sh` and `scripts/scan-archive.py`.

If deviation is detected, restore to canonical state before continuing.
