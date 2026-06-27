# Copyright (c) 2026 Alex313031 and gz83.

"""
This file is the equivalent of setup.sh in the parent folder, but only for
Windows builds.
"""

import os
import shutil
import subprocess
import sys


def fail(msg):
    # Print error message and exit.
    print(f"{sys.argv[0]}: {msg}", file=sys.stderr)
    sys.exit(111)


def try_run(command):
    # Execute a command and die on failure.
    try:
        subprocess.run(command, shell=True, check=True)
    except subprocess.CalledProcessError:
        fail(f"Failed {command}")


def copy(src, dst):
    # Copy a file and print verbose output like cp -v.
    try:
        print(f"Copying {src} to {dst}")
        shutil.copy(src, dst)
    except FileNotFoundError as e:
        fail(f"File copy failed: {e}")


def copy_directory(source_dir, destination_dir):
    if not os.path.exists(destination_dir):
        os.makedirs(destination_dir)
        print(f"Created directory {destination_dir}")
    for item in os.listdir(source_dir):
        s = os.path.join(source_dir, item)
        d = os.path.join(destination_dir, item)
        if os.path.isdir(s):
            print(f"Copying directory {s} to {d}")
            shutil.copytree(s, d, dirs_exist_ok=True)
        else:
            copy(s, d)


# --help
def display_help():
    print("\nScript to copy Thorium source files over the Chromium source tree\n")
    print("\nThis should be done AFTER running this setup.py\n")
    print("Use the --woa flag for Windows on ARM builds.")
    print("Use the --avx512 flag for AVX-512 Builds.")
    print("Use the --avx2 flag for AVX2 Builds.")
    print("Use the --sse4 flag for SSE4.1 Builds.")
    print("Use the --sse3 flag for SSE3 Builds.")
    print("Use the --sse2 flag for 32-bit SSE2 Builds.")
    print("\n")


if "--help" in sys.argv:
    display_help()
    sys.exit(0)

# Set chromium/src dir from Windows environment variable.
cr_src_dir = os.getenv("CR_DIR", r"C:/src/chromium/src")
# Set Thorium dir from Windows environment variable.
thor_src_dir = os.path.expandvars(
    os.getenv("THOR_DIR", r"%USERPROFILE%/thorium"))


print("\nCreating build output directory...\n")
os.makedirs(f"{cr_src_dir}/out/thorium/", exist_ok=True)

print("\nCopying Thorium source files over the Chromium tree\n")

# Copy Thorium sources.
thorium_sources = [
    "src/chrome",
    "src/components",
    "src/content",
    "src/third_party",
    "src/ui",
]

for source in thorium_sources:
    relative_path = source.replace("src/", "", 1)
    copy_directory(
        os.path.normpath(os.path.join(thor_src_dir, source)),
        os.path.normpath(os.path.join(cr_src_dir, relative_path)),
    )

copy_directory(
    os.path.normpath(os.path.join(thor_src_dir, "thorium_shell")),
    os.path.normpath(os.path.join(cr_src_dir, "out", "thorium")),
)
copy(
    os.path.normpath(os.path.join(thor_src_dir, "pak_src", "binaries", "pak")),
    os.path.normpath(os.path.join(cr_src_dir, "out", "thorium")),
)
copy_directory(
    os.path.normpath(os.path.join(
        thor_src_dir, "pak_src", "binaries", "pak-win")),
    os.path.normpath(os.path.join(cr_src_dir, "out", "thorium")),
)


def apply_patch_series():
    condition_args = []
    if "--woa" in sys.argv:
        condition_args.extend(["--condition", "woa"])
    if "--sse2" in sys.argv:
        condition_args.extend(["--condition", "sse2"])

    print("\nApplying Thorium patch series\n")
    script = os.path.join(
        thor_src_dir, "patch_scripts", "series", "apply_series.py")
    command = [
        sys.executable,
        script,
        "--thorium-root",
        thor_src_dir,
        "--source-tree",
        cr_src_dir,
        "--apply",
        *condition_args,
    ]
    try:
        subprocess.run(command, check=True)
    except subprocess.CalledProcessError:
        fail("Failed applying Thorium patch series")


def apply_grd_rebase():
    print("\nApplying Thorium GRD/XTB rebase\n")
    grd_rebase_dir = os.path.join(thor_src_dir, "patch_scripts", "grd_rebase")
    config_dir = os.path.join(grd_rebase_dir, "config")
    sync_script = os.path.join(grd_rebase_dir, "sync_grd_strings.py")
    merge_script = os.path.join(grd_rebase_dir, "merge_thorium_xtb.py")

    try:
        subprocess.run([
            sys.executable,
            sync_script,
            cr_src_dir,
            "--file-allowlist",
            os.path.join(config_dir, "file_allowlist.csv"),
            "--message-allowlist",
            os.path.join(config_dir, "message_allowlist.csv"),
            "--feature-message-ownership",
            os.path.join(config_dir, "feature_patch_message_ownership.csv"),
        ], check=True)
        subprocess.run([
            sys.executable,
            merge_script,
            cr_src_dir,
        ], check=True)
    except subprocess.CalledProcessError:
        fail("Failed applying Thorium GRD/XTB rebase")


apply_patch_series()
apply_grd_rebase()

print("\nCopying other files to out/thorium\n")
# Copying additional files.
copy(
    os.path.normpath(os.path.join(thor_src_dir, "infra", "thor_ver")),
    os.path.normpath(os.path.join(cr_src_dir, "out", "thorium")),
)

flags_to_check = ["--woa", "--avx512", "--avx2", "--sse4", "--sse3", "--sse2"]
if not any(flag in sys.argv for flag in flags_to_check):
    os.chdir(cr_src_dir)
    print("\nDownloading PGO Profiles for Windows x64\n")
    try_run(
        "python3 tools/update_pgo_profiles.py --target=win64 "
        "update --gs-url-base=chromium-optimization-profiles/pgo_profiles"
    )
    print("\nDownloading PGO Profile for V8\n")
    try_run(
        "python3 v8/tools/builtins-pgo/download_profiles.py "
        "--depot-tools=third_party/depot_tools --force download"
    )
else:
    print(
        "\nFor non-AVX builds, please pass the appropriate arguments to ensure the command is executed correctly.\n"
    )


# Copy Windows on Arm files.
def copy_woa():
    print("\nCopying Windows on Arm build files\n")
    copy(
        os.path.normpath(os.path.join(thor_src_dir, "arm", "thorium_version.txt")),
        os.path.normpath(os.path.join(cr_src_dir, "ui", "webui", "resources", "text")),
    )
    os.chdir(cr_src_dir)
    print("\nDownloading PGO Profiles for Windows on Arm\n")
    try_run(
        "python3 tools/update_pgo_profiles.py --target=win-arm64 "
        "update --gs-url-base=chromium-optimization-profiles/pgo_profiles"
    )
    print("\nDownloading PGO Profile for V8\n")
    try_run(
        "python3 v8/tools/builtins-pgo/download_profiles.py "
        "--depot-tools=third_party/depot_tools --force download"
    )


if "--woa" in sys.argv:
    copy_woa()


# Copy AVX512 build files.
def copy_avx512():
    print("\nCopying AVX-512 build files\n")
    copy(
        os.path.normpath(os.path.join(
            thor_src_dir, "other", "AVX512", "thor_ver")),
        os.path.normpath(os.path.join(cr_src_dir, "out", "thorium")),
    )
    copy(
        os.path.normpath(os.path.join(thor_src_dir, "other", "AVX512", "thorium_version.txt")),
        os.path.normpath(os.path.join(cr_src_dir, "ui", "webui", "resources", "text")),
    )
    os.chdir(cr_src_dir)
    print("\nDownloading PGO Profiles for Windows x64\n")
    try_run(
        "python3 tools/update_pgo_profiles.py --target=win64 "
        "update --gs-url-base=chromium-optimization-profiles/pgo_profiles"
    )
    print("\nDownloading PGO Profile for V8\n")
    try_run(
        "python3 v8/tools/builtins-pgo/download_profiles.py "
        "--depot-tools=third_party/depot_tools --force download"
    )


if "--avx512" in sys.argv:
    copy_avx512()


# Copy AVX2 build files.
def copy_avx2():
    print("\nCopying AVX2 build files\n")
    copy(
        os.path.normpath(os.path.join(
            thor_src_dir, "other", "AVX2", "thor_ver")),
        os.path.normpath(os.path.join(cr_src_dir, "out", "thorium")),
    )
    copy(
        os.path.normpath(os.path.join(thor_src_dir, "other", "AVX2", "thorium_version.txt")),
        os.path.normpath(os.path.join(cr_src_dir, "ui", "webui", "resources", "text")),
    )
    os.chdir(cr_src_dir)
    print("\nDownloading PGO Profiles for Windows x64\n")
    try_run(
        "python3 tools/update_pgo_profiles.py --target=win64 "
        "update --gs-url-base=chromium-optimization-profiles/pgo_profiles"
    )
    print("\nDownloading PGO Profile for V8\n")
    try_run(
        "python3 v8/tools/builtins-pgo/download_profiles.py "
        "--depot-tools=third_party/depot_tools --force download"
    )


if "--avx2" in sys.argv:
    copy_avx2()


# Copy SSE4.1 build files.
def copy_sse4():
    print("\nCopying SSE4.1 build files\n")
    copy(
        os.path.normpath(os.path.join(
            thor_src_dir, "other", "SSE4.1", "thor_ver")),
        os.path.normpath(os.path.join(cr_src_dir, "out", "thorium")),
    )
    copy(
        os.path.normpath(os.path.join(thor_src_dir, "other", "SSE4.1", "thorium_version.txt")),
        os.path.normpath(os.path.join(cr_src_dir, "ui", "webui", "resources", "text")),
    )
    os.chdir(cr_src_dir)
    print("\nDownloading PGO Profiles for Windows x64\n")
    try_run(
        "python3 tools/update_pgo_profiles.py --target=win64 "
        "update --gs-url-base=chromium-optimization-profiles/pgo_profiles"
    )
    print("\nDownloading PGO Profile for V8\n")
    try_run(
        "python3 v8/tools/builtins-pgo/download_profiles.py "
        "--depot-tools=third_party/depot_tools --force download"
    )


if "--sse4" in sys.argv:
    copy_sse4()


# Copy SSE3 build files.
def copy_sse3():
    print("\nCopying SSE3 build files\n")
    copy(
        os.path.normpath(os.path.join(
            thor_src_dir, "other", "SSE3", "thor_ver")),
        os.path.normpath(os.path.join(cr_src_dir, "out", "thorium")),
    )
    copy(
        os.path.normpath(os.path.join(thor_src_dir, "other", "SSE3", "thorium_version.txt")),
        os.path.normpath(os.path.join(cr_src_dir, "ui", "webui", "resources", "text")),
    )
    os.chdir(cr_src_dir)
    print("\nDownloading PGO Profiles for Windows x64\n")
    try_run(
        "python3 tools/update_pgo_profiles.py --target=win64 "
        "update --gs-url-base=chromium-optimization-profiles/pgo_profiles"
    )
    print("\nDownloading PGO Profiles for Windows x86\n")
    try_run(
        "python3 tools/update_pgo_profiles.py --target=win32 "
        "update --gs-url-base=chromium-optimization-profiles/pgo_profiles"
    )
    print("\nDownloading PGO Profile for V8\n")
    try_run(
        "python3 v8/tools/builtins-pgo/download_profiles.py "
        "--depot-tools=third_party/depot_tools --force download"
    )


if "--sse3" in sys.argv:
    copy_sse3()


# Copy SSE2 build files.
def copy_sse2():
    print("\nCopying SSE2 build files\n")
    copy(
        os.path.normpath(os.path.join(
            thor_src_dir, "other", "SSE2", "thor_ver")),
        os.path.normpath(os.path.join(cr_src_dir, "out", "thorium")),
    )
    copy(
        os.path.normpath(os.path.join(thor_src_dir, "other", "SSE2", "thorium_version.txt")),
        os.path.normpath(os.path.join(cr_src_dir, "ui", "webui", "resources", "text")),
    )
    os.chdir(cr_src_dir)
    print("\nDownloading PGO Profiles for Windows x86\n")
    try_run(
        "python3 tools/update_pgo_profiles.py --target=win32 "
        "update --gs-url-base=chromium-optimization-profiles/pgo_profiles"
    )
    print("\nDownloading PGO Profile for V8\n")
    try_run(
        "python3 v8/tools/builtins-pgo/download_profiles.py "
        "--depot-tools=third_party/depot_tools --force download"
    )


if "--sse2" in sys.argv:
    copy_sse2()


print("\nDone!\n")
print("\nEnjoy Thorium!\n")
