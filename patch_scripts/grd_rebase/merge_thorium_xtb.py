#!/usr/bin/env python3
# Copyright (c) 2026 Alex313031 and gz83.
"""Merge Thorium-owned translation additions into Chromium XTB bundles."""

import argparse
import csv
from collections.abc import Iterable
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path, PurePosixPath
import re

TRANSLATION_RE = re.compile(
    r'<translation\b(?=[^>]*\bid="([^"]+)")[^>]*>.*?</translation>',
    re.DOTALL,
)
TRANSLATION_BUNDLE_END = "</translationbundle>"


@dataclass(frozen=True)
class XtbAddition:
    translation_id: str
    block: str


@dataclass(frozen=True)
class XtbMergeResult:
    target_path: str
    addition_count: int
    inserted_count: int
    skipped_count: int
    merged_text: str


def readable_directory(path: str) -> Path:
    resolved = Path(path).resolve()
    if not resolved.is_dir():
        raise argparse.ArgumentTypeError(f"not a directory: {path}")
    return resolved


def readable_file(path: str) -> Path:
    resolved = Path(path).resolve()
    if not resolved.is_file():
        raise argparse.ArgumentTypeError(f"not a readable file: {path}")
    return resolved


def load_inventory(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8-sig", newline="") as input_file:
        reader = csv.DictReader(input_file, delimiter="\t")
        required = {"target_path", "translation_id", "translation_block"}
        missing = required - set(reader.fieldnames or ())
        if missing:
            raise ValueError(
                f"inventory is missing columns: {', '.join(sorted(missing))}"
            )
        return list(reader)


def group_inventory(
    rows: list[dict[str, str]],
) -> dict[str, list[XtbAddition]]:
    grouped: dict[str, list[XtbAddition]] = defaultdict(list)
    seen_keys: set[tuple[str, str]] = set()
    for row in rows:
        target_path = row.get("target_path", "").replace("\\", "/").strip("/")
        target_parts = PurePosixPath(target_path).parts
        translation_id = row.get("translation_id", "").strip()
        block = row.get("translation_block", "")
        if (
            not target_path.endswith(".xtb")
            or not target_parts
            or ".." in target_parts
            or ":" in target_parts[0]
        ):
            raise ValueError(f"invalid inventory target: {target_path}")
        match = TRANSLATION_RE.fullmatch(block)
        if not match or match.group(1) != translation_id:
            raise ValueError(
                f"invalid translation block for {target_path}:{translation_id}"
            )
        key = (target_path, translation_id)
        if key in seen_keys:
            raise ValueError(
                f"duplicate inventory translation ID {translation_id} "
                f"for {target_path}"
            )
        seen_keys.add(key)
        grouped[target_path].append(
            XtbAddition(
                translation_id=translation_id,
                block=block,
            )
        )
    if not grouped:
        raise ValueError("inventory contains no XTB translations")
    return dict(grouped)


def parse_translation_blocks(text: str, source_name: str) -> list[XtbAddition]:
    """Parse and validate complete translation blocks from an add file."""
    additions: list[XtbAddition] = []
    seen_ids: set[str] = set()
    cursor = 0
    for match in TRANSLATION_RE.finditer(text):
        if text[cursor : match.start()].strip():
            raise ValueError(
                f"unexpected content outside translation blocks in {source_name}"
            )
        translation_id = match.group(1)
        if translation_id in seen_ids:
            raise ValueError(
                f"duplicate translation ID {translation_id} in {source_name}"
            )
        seen_ids.add(translation_id)
        additions.append(
            XtbAddition(
                translation_id=translation_id,
                block=match.group(0),
            )
        )
        cursor = match.end()
    if text[cursor:].strip():
        raise ValueError(
            f"unexpected content outside translation blocks in {source_name}"
        )
    if not additions:
        raise ValueError(f"no translation blocks in {source_name}")
    return additions


def target_path_for_addition(additions_root: Path, add_path: Path) -> str:
    """Return the Chromium-relative XTB target for one `.xtb.add` file."""
    relative_path = add_path.relative_to(additions_root).as_posix()
    if not relative_path.endswith(".xtb.add"):
        raise ValueError(f"not an XTB addition file: {relative_path}")
    return relative_path.removesuffix(".add")


def discover_addition_files(additions_root: Path) -> list[Path]:
    """Find all mirrored XTB addition files in stable path order."""
    return sorted(additions_root.rglob("*.xtb.add"))


def group_addition_files(additions_root: Path) -> list[tuple[str, list[XtbAddition]]]:
    """Load mirrored `.xtb.add` files in stable target path order."""
    grouped: list[tuple[str, list[XtbAddition]]] = []
    for add_path in discover_addition_files(additions_root):
        target_path = target_path_for_addition(additions_root, add_path)
        additions = parse_translation_blocks(
            add_path.read_text(encoding="utf-8"),
            add_path.as_posix(),
        )
        grouped.append((target_path, additions))
    return grouped


def merge_additions_into_text(
    target_text: str,
    additions: list[XtbAddition],
    target_path: str,
) -> tuple[str, int, int]:
    """Insert missing additions and reject conflicting existing IDs."""
    existing: dict[str, str] = {}
    for match in TRANSLATION_RE.finditer(target_text):
        translation_id = match.group(1)
        if translation_id in existing:
            raise ValueError(
                f"duplicate translation ID {translation_id} in {target_path}"
            )
        existing[translation_id] = match.group(0)

    pending: list[XtbAddition] = []
    skipped_count = 0
    for addition in additions:
        existing_block = existing.get(addition.translation_id)
        if existing_block is None:
            pending.append(addition)
            continue
        if existing_block != addition.block:
            raise ValueError(
                "translation ID already exists with different content: "
                f"{addition.translation_id} in {target_path}"
            )
        skipped_count += 1

    if not pending:
        return target_text, 0, skipped_count

    closing_index = target_text.rfind(TRANSLATION_BUNDLE_END)
    if closing_index < 0:
        raise ValueError(f"missing {TRANSLATION_BUNDLE_END} in {target_path}")

    prefix = target_text[:closing_index]
    suffix = target_text[closing_index:]
    separator = "" if not prefix or prefix.endswith("\n") else "\n"
    addition_text = "\n".join(addition.block for addition in pending)
    merged_text = f"{prefix}{separator}{addition_text}\n{suffix}"
    return merged_text, len(pending), skipped_count


def build_merge_results(
    chromium_root: Path,
    additions_by_target: Iterable[tuple[str, list[XtbAddition]]],
) -> list[XtbMergeResult]:
    """Prepare merged contents without writing Chromium files."""
    results: list[XtbMergeResult] = []
    for target_path, additions in additions_by_target:
        target_file = chromium_root / target_path
        if not target_file.is_file():
            raise FileNotFoundError(f"XTB target is missing: {target_path}")
        target_text = target_file.read_text(encoding="utf-8", errors="strict")
        merged_text, inserted_count, skipped_count = merge_additions_into_text(
            target_text,
            additions,
            target_path,
        )
        results.append(
            XtbMergeResult(
                target_path=target_path,
                addition_count=len(additions),
                inserted_count=inserted_count,
                skipped_count=skipped_count,
                merged_text=merged_text,
            )
        )
    return results


def write_merge_results(
    chromium_root: Path,
    results: list[XtbMergeResult],
) -> None:
    """Write prepared XTB contents using UTF-8 without newline conversion."""
    for result in results:
        if result.inserted_count == 0:
            continue
        (chromium_root / result.target_path).write_bytes(
            result.merged_text.encode("utf-8")
        )


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Merge Thorium translation additions into Chromium XTB files."
    )
    parser.add_argument(
        "chromium_root",
        type=readable_directory,
        help="Chromium source root containing the target XTB files.",
    )
    source_group = parser.add_mutually_exclusive_group()
    source_group.add_argument(
        "--inventory",
        type=readable_file,
        help="Normalized TSV inventory; defaults to the reviewed M150 inventory.",
    )
    source_group.add_argument(
        "--additions-root",
        type=readable_directory,
        help="Optional directory of generated mirrored `.xtb.add` files.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate and report additions without writing target files.",
    )
    return parser


def main() -> int:
    args = build_arg_parser().parse_args()
    if args.additions_root is not None:
        additions_by_target = group_addition_files(args.additions_root)
    else:
        inventory = args.inventory or (
            Path(__file__).resolve().parent / "config/m150_xtb_additions.tsv"
        )
        inventory_groups = group_inventory(load_inventory(inventory))
        additions_by_target = [
            (target_path, additions)
            for target_path, additions in sorted(inventory_groups.items())
        ]
    results = build_merge_results(args.chromium_root, additions_by_target)
    total_additions = sum(result.addition_count for result in results)
    inserted_count = sum(result.inserted_count for result in results)
    skipped_count = sum(result.skipped_count for result in results)
    touched_count = sum(result.inserted_count > 0 for result in results)
    if not args.dry_run:
        write_merge_results(args.chromium_root, results)
    mode = "validated" if args.dry_run else "merged"
    print(
        f"{mode} {total_additions} Thorium translations across "
        f"{len(results)} XTB files: {inserted_count} inserted, "
        f"{skipped_count} already present, {touched_count} files changed"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
