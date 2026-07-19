#!/usr/bin/env python3

# Copyright (c) 2026 Alex313031 and gz83.

"""Build, test, and publish Thorium's chrome-pak-customizer binaries."""

from __future__ import annotations

import argparse
from contextlib import contextmanager
from datetime import datetime, timezone
import hashlib
import os
from pathlib import Path
import shutil
import socket
import struct
import subprocess
import sys
import tempfile
from typing import Iterator


MINIMUM_PYTHON = (3, 11)
PACKAGE_NAME = "chrome-pak-customizer"
SUPPORTED_TARGETS = (
    "x86_64-unknown-linux-gnu",
    "aarch64-unknown-linux-gnu",
    "x86_64-unknown-linux-musl",
    "aarch64-unknown-linux-musl",
    "x86_64-pc-windows-msvc",
    "i686-pc-windows-msvc",
    "x86_64-apple-darwin",
    "aarch64-apple-darwin",
)
PACKAGE_OUTPUTS = {
    "x86_64-unknown-linux-musl": Path("pak"),
    "aarch64-unknown-linux-musl": Path("pak_arm64"),
    "x86_64-pc-windows-msvc": Path("pak-win/pak_mingw64.exe"),
    "i686-pc-windows-msvc": Path("pak-win/pak_mingw32.exe"),
}


class PakBuildError(RuntimeError):
    """An expected build, test, or packaging failure."""


def require_python() -> None:
    if sys.version_info < MINIMUM_PYTHON:
        required = ".".join(map(str, MINIMUM_PYTHON))
        raise PakBuildError(f"Python {required} or newer is required")


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build and validate Thorium's PAK customization tool."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    build = subparsers.add_parser("build", help="build one release binary")
    add_target_argument(build)

    test = subparsers.add_parser("test", help="run unit and PAK round-trip tests")
    test.add_argument(
        "--fixture",
        action="append",
        type=Path,
        default=[],
        help="PAK file to round-trip; may be specified more than once",
    )
    test.add_argument(
        "--keep-going",
        action="store_true",
        help="continue testing remaining fixtures after a failure",
    )

    subparsers.add_parser("clean", help="remove only pak_src/target")

    package = subparsers.add_parser(
        "package", help="build and publish one Thorium integration binary"
    )
    add_target_argument(
        package,
        required=True,
        choices=tuple(PACKAGE_OUTPUTS),
    )
    package.add_argument(
        "--source",
        type=Path,
        help=(
            "publish this explicitly selected prebuilt binary instead of "
            "running Cargo"
        ),
    )

    return parser.parse_args()


def add_target_argument(
    parser: argparse.ArgumentParser,
    *,
    required: bool = False,
    choices: tuple[str, ...] = SUPPORTED_TARGETS,
) -> None:
    target_help = (
        "Rust target triple to publish"
        if required
        else (
            "Rust target triple (default: the rustc host target; GNU Linux "
            "targets are for local validation, not packaging)"
        )
    )
    parser.add_argument(
        "--target",
        choices=choices,
        required=required,
        help=target_help,
    )


def find_tool(name: str) -> str:
    executable = shutil.which(name)
    if executable is None:
        raise PakBuildError(f"required tool not found in PATH: {name}")
    return executable


def run(
    command: list[str],
    *,
    cwd: Path,
    capture_output: bool = False,
) -> subprocess.CompletedProcess[str]:
    try:
        return subprocess.run(
            command,
            cwd=cwd,
            check=True,
            text=True,
            capture_output=capture_output,
        )
    except subprocess.CalledProcessError as error:
        if capture_output and error.stderr:
            print(error.stderr.rstrip(), file=sys.stderr)
        raise PakBuildError(
            f"command failed with exit code {error.returncode}: "
            f"{' '.join(command)}"
        ) from error
    except OSError as error:
        raise PakBuildError(f"could not execute {command[0]}: {error}") from error


def rust_host_target(root: Path) -> str:
    rustc = find_tool("rustc")
    result = run([rustc, "-vV"], cwd=root, capture_output=True)
    for line in result.stdout.splitlines():
        if line.startswith("host: "):
            return line.removeprefix("host: ").strip()
    raise PakBuildError("rustc -vV did not report a host target")


def resolve_target(root: Path, requested: str | None) -> str:
    target = requested or rust_host_target(root)
    if target not in SUPPORTED_TARGETS:
        supported = ", ".join(SUPPORTED_TARGETS)
        raise PakBuildError(
            f"unsupported Rust target {target!r}; supported targets: {supported}"
        )
    return target


def cargo_command(root: Path, action: str, target: str) -> list[str]:
    return [
        find_tool("cargo"),
        action,
        "--manifest-path",
        str(root / "Cargo.toml"),
        "--locked",
        "--release",
        "--target",
        target,
    ]


def build_release(root: Path, target: str) -> Path:
    run(cargo_command(root, "build", target), cwd=root)
    binary = release_binary(root, target)
    if not binary.is_file():
        raise PakBuildError(f"Cargo did not produce the expected binary: {binary}")
    return binary


def release_binary(root: Path, target: str) -> Path:
    suffix = ".exe" if "windows" in target else ""
    return root / "target" / target / "release" / f"{PACKAGE_NAME}{suffix}"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def round_trip(binary: Path, fixture: Path) -> None:
    fixture = fixture.resolve()
    if not fixture.is_file():
        raise PakBuildError(f"fixture does not exist: {fixture}")
    if fixture.suffix.lower() != ".pak":
        raise PakBuildError(f"fixture is not a .pak file: {fixture}")

    with tempfile.TemporaryDirectory(prefix="thorium-pak-test-") as temporary:
        working = Path(temporary)
        unpacked = working / "unpacked"
        repacked = working / "repacked.pak"
        run([str(binary), "-u", str(fixture), str(unpacked)], cwd=working)
        index = unpacked / "pak_index.ini"
        if not index.is_file():
            raise PakBuildError(f"unpacking did not produce {index.name}: {fixture}")
        run([str(binary), "-p", str(index), str(repacked)], cwd=working)
        if not repacked.is_file():
            raise PakBuildError(f"repacking did not produce an output: {fixture}")
        if sha256(fixture) != sha256(repacked):
            raise PakBuildError(f"round-trip SHA-256 mismatch: {fixture}")


def test_command(root: Path, fixtures: list[Path], keep_going: bool) -> None:
    target = rust_host_target(root)
    if target not in SUPPORTED_TARGETS:
        raise PakBuildError(f"tests are not configured for host target: {target}")

    run(cargo_command(root, "test", target), cwd=root)
    binary = build_release(root, target)

    selected = fixtures or sorted((root / "tests").glob("*.pak"))
    if not selected:
        print("Unit tests passed; no PAK round-trip fixtures were supplied.")
        return

    failures: list[str] = []
    for fixture in selected:
        try:
            round_trip(binary, fixture)
            print(f"Round-trip passed: {fixture}")
        except PakBuildError as error:
            if not keep_going:
                raise
            failures.append(str(error))
            print(f"Round-trip failed: {error}", file=sys.stderr)
    if failures:
        raise PakBuildError(f"{len(failures)} PAK round-trip test(s) failed")


def clean(root: Path) -> None:
    target = root / "target"
    if target.is_symlink():
        raise PakBuildError(
            f"refusing to remove symbolic-link build directory: {target}"
        )
    if target.exists():
        if not target.is_dir():
            raise PakBuildError(f"build output is not a directory: {target}")
        shutil.rmtree(target)
        print(f"Removed: {target}")
    else:
        print(f"Nothing to remove: {target}")


def checksum_manifest(binaries: Path, replacement: tuple[Path, Path]) -> bytes:
    destination, staged = replacement
    entries: list[tuple[str, Path]] = []
    for relative in sorted(
        set(PACKAGE_OUTPUTS.values()), key=lambda item: item.as_posix()
    ):
        path = binaries / relative
        if path == destination:
            path = staged
        if path.is_symlink():
            raise PakBuildError(
                f"refusing to include symbolic-link output in manifest: {path}"
            )
        if path.is_file():
            entries.append((relative.as_posix(), path))
    return "".join(f"{sha256(path)}  {name}\n" for name, path in entries).encode()


def ensure_directory(path: Path) -> None:
    if path.is_symlink():
        raise PakBuildError(f"refusing to use symbolic-link output directory: {path}")
    path.mkdir(exist_ok=True)
    if path.is_symlink() or not path.is_dir():
        raise PakBuildError(f"output path is not a regular directory: {path}")


def validate_binary_architecture(binary: Path, target: str) -> None:
    try:
        with binary.open("rb") as source:
            header = source.read(64)
            if target.endswith("linux-musl"):
                if len(header) < 20 or header[:4] != b"\x7fELF":
                    raise PakBuildError(
                        f"expected an ELF binary for {target}: {binary}"
                    )
                if header[4] != 2 or header[5] != 1:
                    raise PakBuildError(
                        f"expected a little-endian 64-bit ELF binary for {target}: "
                        f"{binary}"
                    )
                machine = struct.unpack_from("<H", header, 18)[0]
                expected = 62 if target.startswith("x86_64-") else 183
            elif target.endswith("windows-msvc"):
                if len(header) < 64 or header[:2] != b"MZ":
                    raise PakBuildError(f"expected a PE binary for {target}: {binary}")
                pe_offset = struct.unpack_from("<I", header, 0x3C)[0]
                source.seek(pe_offset)
                pe_header = source.read(6)
                if len(pe_header) != 6 or pe_header[:4] != b"PE\0\0":
                    raise PakBuildError(f"invalid PE header for {target}: {binary}")
                machine = struct.unpack_from("<H", pe_header, 4)[0]
                expected = 0x8664 if target.startswith("x86_64-") else 0x014C
            else:
                raise PakBuildError(f"cannot validate publish architecture: {target}")
    except OSError as error:
        raise PakBuildError(
            f"could not inspect release binary {binary}: {error}"
        ) from error
    if machine != expected:
        raise PakBuildError(
            f"release binary architecture does not match {target}: {binary}"
        )


@contextmanager
def packaging_lock(binaries: Path) -> Iterator[None]:
    lock = binaries / ".pak-build.lock"
    try:
        lock.mkdir()
    except FileExistsError as error:
        owner = lock / "owner.txt"
        detail = ""
        try:
            if not lock.is_symlink() and owner.is_file() and not owner.is_symlink():
                detail = f" ({owner.read_text(encoding='utf-8').strip()})"
        except OSError:
            pass
        raise PakBuildError(
            f"another PAK packaging process holds {lock}{detail}"
        ) from error
    except OSError as error:
        raise PakBuildError(
            f"could not create packaging lock {lock}: {error}"
        ) from error

    try:
        (lock / "owner.txt").write_text(
            " ".join(
                (
                    f"pid={os.getpid()}",
                    f"host={socket.gethostname()}",
                    f"started={datetime.now(timezone.utc).isoformat()}",
                )
            ),
            encoding="utf-8",
        )
    except OSError as error:
        try:
            shutil.rmtree(lock)
        except OSError as cleanup_error:
            raise PakBuildError(
                f"could not initialize packaging lock {lock}: {error}; "
                f"cleanup failed: {cleanup_error}"
            ) from error
        raise PakBuildError(
            f"could not initialize packaging lock {lock}: {error}"
        ) from error

    try:
        yield
    finally:
        try:
            shutil.rmtree(lock)
        except OSError as error:
            if sys.exc_info()[0] is None:
                raise PakBuildError(f"could not remove packaging lock {lock}: {error}")
            print(
                f"warning: could not remove packaging lock {lock}: {error}",
                file=sys.stderr,
            )


def verify_checksum_manifest(binaries: Path, manifest: Path) -> dict[str, str]:
    if manifest.is_symlink() or not manifest.is_file():
        raise PakBuildError(f"checksum manifest is not a regular file: {manifest}")
    allowed = {path.as_posix() for path in PACKAGE_OUTPUTS.values()}
    actual: set[str] = set()
    for name in allowed:
        output = binaries / Path(name)
        if output.is_symlink():
            raise PakBuildError(f"manifest output is a symbolic link: {output}")
        if output.is_file():
            actual.add(name)
        elif output.exists():
            raise PakBuildError(f"manifest output is not a regular file: {output}")
    entries: dict[str, str] = {}
    try:
        lines = manifest.read_text(encoding="ascii").splitlines()
    except (OSError, UnicodeError) as error:
        raise PakBuildError(
            f"could not read checksum manifest {manifest}: {error}"
        ) from error
    for line in lines:
        digest, separator, name = line.partition("  ")
        if (
            not separator
            or len(digest) != 64
            or any(character not in "0123456789abcdef" for character in digest)
            or name not in allowed
            or name in entries
        ):
            raise PakBuildError(f"invalid checksum manifest entry: {line!r}")
        output = binaries / Path(name)
        if output.is_symlink() or not output.is_file():
            raise PakBuildError(f"manifest output is not a regular file: {output}")
        if sha256(output) != digest:
            raise PakBuildError(f"checksum mismatch for manifest output: {output}")
        entries[name] = digest
    if not entries:
        raise PakBuildError(f"checksum manifest is empty: {manifest}")
    if entries.keys() != actual:
        missing = sorted(actual - entries.keys())
        extra = sorted(entries.keys() - actual)
        detail = []
        if missing:
            detail.append(f"missing: {', '.join(missing)}")
        if extra:
            detail.append(f"unexpected: {', '.join(extra)}")
        raise PakBuildError(
            f"checksum manifest inventory mismatch ({'; '.join(detail)})"
        )
    return entries


def recover_completed_transaction(
    binaries: Path,
    relative: Path,
    destination: Path,
    manifest: Path,
    backups: tuple[Path, Path],
) -> None:
    existing = [path for path in backups if path.exists() or path.is_symlink()]
    if not existing:
        return
    for backup in existing:
        if backup.is_symlink() or not backup.is_file():
            raise PakBuildError(
                f"stale packaging backup is not a regular file: {backup}"
            )
    entries = verify_checksum_manifest(binaries, manifest)
    backup_binary, _ = backups
    if backup_binary in existing:
        name = relative.as_posix()
        if destination.is_symlink() or not destination.is_file() or name not in entries:
            raise PakBuildError(
                "incomplete PAK packaging transaction requires manual recovery"
            )
    try:
        for path in existing:
            path.unlink()
    except OSError as error:
        raise PakBuildError(
            f"could not remove completed packaging backup {path}: {error}"
        ) from error


def publish_locked(
    binaries: Path,
    target: str,
    relative: Path,
    destination: Path,
    manifest: Path,
    source: Path,
) -> Path:
    staged_binary = destination.with_name(f".{destination.name}.new")
    staged_manifest = manifest.with_name(f".{manifest.name}.new")
    backup_binary = destination.with_name(f".{destination.name}.previous")
    backup_manifest = manifest.with_name(f".{manifest.name}.previous")
    staged_paths = (staged_binary, staged_manifest)
    if any(path.exists() or path.is_symlink() for path in staged_paths):
        raise PakBuildError(
            "stale PAK packaging transaction files must be removed first"
        )
    backups = (backup_binary, backup_manifest)
    recover_completed_transaction(
        binaries, relative, destination, manifest, backups
    )

    had_binary = destination.is_file()
    had_manifest = manifest.is_file()
    installed_binary = False
    installed_manifest = False
    try:
        shutil.copy2(source, staged_binary)
        if "windows" not in target:
            staged_binary.chmod(0o755)
        staged_manifest.write_bytes(
            checksum_manifest(binaries, (destination, staged_binary))
        )
        if destination.exists() and not had_binary:
            raise PakBuildError(f"output is not a regular file: {destination}")
        if manifest.exists() and not had_manifest:
            raise PakBuildError(f"checksum manifest is not a regular file: {manifest}")
        if had_binary:
            destination.replace(backup_binary)
        if had_manifest:
            manifest.replace(backup_manifest)
        staged_binary.replace(destination)
        installed_binary = True
        staged_manifest.replace(manifest)
        installed_manifest = True
    except (OSError, PakBuildError) as error:
        rollback_errors: list[str] = []
        for installed, output, backup, existed in (
            (installed_manifest, manifest, backup_manifest, had_manifest),
            (installed_binary, destination, backup_binary, had_binary),
        ):
            try:
                if installed and output.exists():
                    output.unlink()
                if existed and backup.exists():
                    backup.replace(output)
            except OSError as rollback_error:
                rollback_errors.append(str(rollback_error))
        detail = (
            f"; rollback errors: {'; '.join(rollback_errors)}"
            if rollback_errors
            else ""
        )
        raise PakBuildError(
            f"could not publish {destination}: {error}{detail}"
        ) from error
    finally:
        cleanup_errors: list[str] = []
        for path in staged_paths:
            try:
                path.unlink(missing_ok=True)
            except OSError as error:
                cleanup_errors.append(f"{path}: {error}")
        if cleanup_errors:
            detail = "; ".join(cleanup_errors)
            if sys.exc_info()[0] is None:
                raise PakBuildError(
                    f"could not clean packaging transaction files: {detail}"
                )
            print(
                f"warning: could not clean packaging transaction files: {detail}",
                file=sys.stderr,
            )

    for backup in backups:
        try:
            backup.unlink(missing_ok=True)
        except OSError as error:
            print(
                f"warning: could not remove packaging backup {backup}: {error}",
                file=sys.stderr,
            )
    return destination


def publish(root: Path, target: str, source: Path) -> Path:
    relative = PACKAGE_OUTPUTS.get(target)
    if relative is None:
        raise PakBuildError(
            f"{target} has no bundled Thorium output; macOS binaries are build-only"
        )
    if source.is_symlink() or not source.is_file():
        raise PakBuildError(f"release binary is not a regular file: {source}")
    source = source.resolve()
    validate_binary_architecture(source, target)

    binaries = root / "binaries"
    destination = binaries / relative
    ensure_directory(binaries)
    if destination.parent != binaries:
        ensure_directory(destination.parent)
    if destination.is_symlink():
        raise PakBuildError(f"refusing to replace symbolic-link output: {destination}")
    manifest = binaries / "SHA256SUMS"
    if manifest.is_symlink():
        raise PakBuildError(f"refusing to replace symbolic-link manifest: {manifest}")
    with packaging_lock(binaries):
        return publish_locked(
            binaries, target, relative, destination, manifest, source
        )


def main() -> int:
    try:
        require_python()
        root = Path(__file__).resolve().parent
        arguments = parse_arguments()

        if arguments.command == "clean":
            clean(root)
        elif arguments.command == "test":
            test_command(root, arguments.fixture, arguments.keep_going)
        else:
            target = resolve_target(root, arguments.target)
            if arguments.command == "build":
                output = build_release(root, target)
                print(f"Built: {output}")
            elif arguments.command == "package":
                source = (
                    arguments.source
                    if arguments.source is not None
                    else build_release(root, target)
                )
                output = publish(root, target, source)
                print(f"Published: {output}")
        return 0
    except (PakBuildError, OSError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
