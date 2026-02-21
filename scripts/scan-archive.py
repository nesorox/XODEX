#!/usr/bin/env python3
"""Colemak-style immutable archive deviation scanner."""

import hashlib
import os
import subprocess
import sys

MANIFEST = "archive/.manifest.sha256"
ROOT = "archive"


def hash_dir(root: str) -> dict[str, str]:
    hashes: dict[str, str] = {}
    for dirpath, _, files in os.walk(root):
        for filename in files:
            if filename in {".immutable", ".manifest.sha256"}:
                continue
            path = os.path.join(dirpath, filename)
            with open(path, "rb") as file_descriptor:
                digest = hashlib.sha256(file_descriptor.read()).hexdigest()
            hashes[path] = digest
    return hashes


def read_manifest(path: str) -> dict[str, str]:
    stored: dict[str, str] = {}
    with open(path, "r", encoding="utf-8") as manifest:
        for line in manifest:
            line = line.strip()
            if "  " not in line:
                continue
            digest, filepath = line.split("  ", 1)
            stored[filepath] = digest
    return stored


def write_manifest(path: str, entries: dict[str, str]) -> None:
    with open(path, "w", encoding="utf-8") as manifest:
        for filepath, digest in sorted(entries.items()):
            manifest.write(f"{digest}  {filepath}\n")


if __name__ == "__main__":
    current = hash_dir(ROOT)

    if os.path.exists(MANIFEST):
        stored = read_manifest(MANIFEST)
        if current != stored:
            print("DEVIATION DETECTED — running rock()")
            subprocess.run(["./scripts/rock-archive.sh"], check=False)
            sys.exit(1)

    write_manifest(MANIFEST, current)
    print("✓ archive/ manifest updated")
