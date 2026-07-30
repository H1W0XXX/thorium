#!/usr/bin/env python3
"""Record and validate an append-only Thorium patch-series transition."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import tempfile
from pathlib import Path

from apply_series import parse_series, selected


STATE_VERSION = 1


def patch_digest(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def current_state(
    thorium_root: Path, series: Path, conditions: set[str]
) -> dict[str, object]:
    entries = [
        entry
        for entry in parse_series(series)
        if selected(entry, conditions)
    ]
    return {
        "version": STATE_VERSION,
        "conditions": sorted(conditions),
        "entries": [
            {
                "apply_root": entry.apply_root,
                "patch_path": entry.patch_path,
                "sha256": patch_digest(thorium_root / entry.patch_path),
            }
            for entry in entries
        ],
    }


def write_state(path: Path, state: dict[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        mode="w",
        encoding="utf-8",
        dir=path.parent,
        prefix=f"{path.name}.",
        suffix=".tmp",
        delete=False,
    ) as output:
        json.dump(state, output, indent=2, sort_keys=True)
        output.write("\n")
        temporary = Path(output.name)
    os.replace(temporary, path)


def write_text(path: Path, value: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        mode="w",
        encoding="utf-8",
        dir=path.parent,
        prefix=f"{path.name}.",
        suffix=".tmp",
        delete=False,
    ) as output:
        output.write(value)
        temporary = Path(output.name)
    os.replace(temporary, path)


def appended_start_index(
    previous: dict[str, object], current: dict[str, object]
) -> int | None:
    if previous.get("version") != STATE_VERSION:
        print("incremental patch state has an unsupported version")
        return None
    if previous.get("conditions") != current["conditions"]:
        print("patch conditions changed")
        return None

    previous_entries = previous.get("entries")
    current_entries = current["entries"]
    if not isinstance(previous_entries, list):
        print("incremental patch state has no entry list")
        return None
    if len(current_entries) <= len(previous_entries):
        print("patch series was not extended")
        return None
    if current_entries[: len(previous_entries)] != previous_entries:
        print("an existing patch changed, moved, or was removed")
        return None

    print(
        f"append-only patch transition: "
        f"{len(previous_entries)} -> {len(current_entries)} entries"
    )
    return len(previous_entries)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("check-appended", "write"))
    parser.add_argument("--thorium-root", required=True, type=Path)
    parser.add_argument("--series", required=True, type=Path)
    parser.add_argument("--state-file", required=True, type=Path)
    parser.add_argument("--start-index-file", type=Path)
    parser.add_argument("--condition", action="append", default=[])
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    thorium_root = args.thorium_root.resolve()
    series = args.series.resolve()
    state_file = args.state_file.resolve()
    conditions = {condition.lower() for condition in args.condition}
    state = current_state(thorium_root, series, conditions)

    if args.command == "write":
        write_state(state_file, state)
        print(f"wrote incremental patch state: {state_file}")
        return 0

    if not state_file.is_file():
        print(f"incremental patch state does not exist: {state_file}")
        return 1
    try:
        previous = json.loads(state_file.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        print(f"could not read incremental patch state: {error}")
        return 1
    start_index = appended_start_index(previous, state)
    if start_index is None:
        return 1
    if args.start_index_file is not None:
        write_text(args.start_index_file.resolve(), f"{start_index}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
