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
    # Print error message and exit
    print(f"{sys.argv[0]}: {msg}", file=sys.stderr)
    sys.exit(111)


def try_run(command):
    # Execute a command and die on failure
    try:
        subprocess.run(command, shell=True, check=True)
    except subprocess.CalledProcessError:
        fail(f"Failed {command}")


def copy(src, dst):
    # Copy a file and print verbose output like cp -v
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

# Set chromium/src dir from Windows environment variable
cr_src_dir = os.getenv("CR_DIR", r"C:/src/chromium/src")
# Set Thorium dir from Windows environment variable
thor_src_dir = os.path.expandvars(
    os.getenv("THOR_DIR", r"%USERPROFILE%/thorium"))


print("\nCreating build output directory...\n")
os.makedirs(f"{cr_src_dir}/out/thorium/", exist_ok=True)

print("\nCopying Thorium source files over the Chromium tree\n")

# Copy src/BUILD.gn
copy(
    os.path.normpath(os.path.join(thor_src_dir, "src", "BUILD.gn")),
    os.path.normpath(os.path.join(cr_src_dir)),
)

# Copy Thorium sources
thorium_sources = [
    "src/ash",
    "src/build",
    "src/chrome",
    "src/chromeos",
    "src/components",
    "src/content",
    "src/extensions",
    "src/google_apis",
    "src/media",
    "src/net",
    "src/sandbox",
    "src/services",
    "src/third_party",
    "src/tools",
    "src/ui",
    "src/v8",
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


patches = [
    "other/enable-hevc-ffmpeg-decoding.patch",
    "other/fix-policy-templates.patch",
    "other/ftp-support-thorium.patch",
    "other/thorium-2024-ui.patch",
    "other/GPC.patch",
    "other/mini_installer.patch",
    "other/open_in_same_tab.patch",
    "other/add-flag-for-close-confirmation.patch",
    "other/add-flag-to-close-window-with-last-tab.patch",
    "other/add-flag-to-scroll-tabs.patch",
    "other/add-flag-for-custom-ntp.patch",
    "other/force-disable-tab-outlines.patch",
    "other/disable-thorium-dns-config.patch",
    "other/reduce-doh-request-headers.patch",
    "other/add-flag-to-keep-all-history.patch",
    "other/allow-insecure-downloads.patch",
    "other/disable-download-quarantine.patch",
    "other/disable-vulkan-gpu-log-warnings.patch",
    "other/add-flag-for-auto-dark-mode.patch",
    "other/disable-thorium-icons.patch",
    "other/always-enable-reload-menu.patch",
    "other/thorium_webui.patch",
    "other/keep-expired-flags.patch",
    "other/disable-privacy-sandbox.patch",
    "other/disable-encryption.patch",
    "other/disable-feature-promos.patch",
    "other/thorium-install-static-branding.patch",
    "other/win_updater.patch",
    "other/keyboard_shortcuts.patch",
    "other/disable-aero.patch",
    "other/restore_download_shelf.patch",
    "other/allow_manifest_v2_extensions.patch",
    "other/android-disable-signin-without-account-manager.patch",
    "other/android-extensions-support.patch",
    "other/chrome-web-store-protection.patch",
    "other/enable-extension-in-incognito.patch",
]
for patch in patches:
    relative_path = patch.replace("other/", "", 1)
    os.path.normpath(os.path.join(cr_src_dir, os.path.dirname(relative_path)))
    copy(
        os.path.normpath(os.path.join(thor_src_dir, patch)),
        os.path.normpath(os.path.join(cr_src_dir, relative_path)),
    )


print("\nPatching FFMPEG for HEVC\n")
copy(
    os.path.normpath(
        os.path.join(thor_src_dir, "other",
                     "add-hevc-ffmpeg-decoder-parser.patch")
    ),
    os.path.normpath(os.path.join(cr_src_dir, "third_party", "ffmpeg")),
)
copy(
    os.path.normpath(
        os.path.join(thor_src_dir, "other", "change-libavcodec-header.patch")
    ),
    os.path.normpath(os.path.join(cr_src_dir, "third_party", "ffmpeg")),
)
copy(
    os.path.normpath(
        os.path.join(thor_src_dir, "other", "fix-ffmpeg-android-x86-disable-hevc-nasm.patch")
    ),
    os.path.normpath(os.path.join(cr_src_dir, "third_party", "ffmpeg")),
)
# Change directory to ffmpeg_dir and run commands
ffmpeg_dir = os.path.join(cr_src_dir, "third_party", "ffmpeg")
os.chdir(ffmpeg_dir)
try_run(f"git apply --reject add-hevc-ffmpeg-decoder-parser.patch")
try_run(f"git apply --reject change-libavcodec-header.patch")
try_run(f"git apply --reject fix-ffmpeg-android-x86-disable-hevc-nasm.patch")


print("\nEnabling HEVC FFmpeg decoding\n")
# Change directory to cr_src_dir and run commands
os.chdir(cr_src_dir)
try_run(f"git apply --reject enable-hevc-ffmpeg-decoding.patch")


print("\nPatching policy templates\n")
# Change directory to cr_src_dir and run commands
os.chdir(cr_src_dir)
try_run(f"git apply --reject fix-policy-templates.patch")


print("\nPatching FTP support\n")
# Change directory to cr_src_dir and run commands
os.chdir(cr_src_dir)
try_run(f"git apply --reject ftp-support-thorium.patch")


print("\nPatching in GPC support\n")
# Change directory to cr_src_dir and run commands
os.chdir(cr_src_dir)
try_run(f"git apply --reject GPC.patch")


print("\nPatching for Thorium 2024 UI\n")
# Change directory to cr_src_dir and run commands
os.chdir(cr_src_dir)
try_run(f"git apply --reject thorium-2024-ui.patch")


print("\nDownload Shelf patch...\n")
# Change directory to cr_src_dir and run commands
os.chdir(cr_src_dir)
try_run(f"git apply --reject restore_download_shelf.patch")


print("\nPatching for mini_installer\n")
# Change directory to cr_src_dir and run commands
os.chdir(cr_src_dir)
try_run(f"git apply --reject mini_installer.patch")


print("\nApplying other Misc. patches...\n")
# Change directory to cr_src_dir and run commands
os.chdir(cr_src_dir)
try_run(f"git apply --reject open_in_same_tab.patch")
try_run(f"git apply --reject add-flag-for-close-confirmation.patch")
try_run(f"git apply --reject add-flag-to-close-window-with-last-tab.patch")
try_run(f"git apply --reject add-flag-to-scroll-tabs.patch")
try_run(f"git apply --reject add-flag-for-custom-ntp.patch")
try_run(f"git apply --reject force-disable-tab-outlines.patch")
try_run(f"git apply --reject disable-thorium-dns-config.patch")
try_run(f"git apply --reject reduce-doh-request-headers.patch")
try_run(f"git apply --reject add-flag-to-keep-all-history.patch")
try_run(f"git apply --reject allow-insecure-downloads.patch")
try_run(f"git apply --reject disable-download-quarantine.patch")
try_run(f"git apply --reject disable-vulkan-gpu-log-warnings.patch")
try_run(f"git apply --reject add-flag-for-auto-dark-mode.patch")
try_run(f"git apply --reject disable-thorium-icons.patch")
try_run(f"git apply --reject always-enable-reload-menu.patch")
try_run(f"git apply --reject allow_manifest_v2_extensions.patch")
try_run(f"git apply --reject thorium_webui.patch")
try_run(f"git apply --reject win_updater.patch")
try_run(f"git apply --reject keyboard_shortcuts.patch")
try_run(f"git apply --reject keep-expired-flags.patch")
try_run(f"git apply --reject disable-privacy-sandbox.patch")
try_run(f"git apply --reject disable-encryption.patch")
try_run(f"git apply --reject disable-feature-promos.patch")
try_run(f"git apply --reject thorium-install-static-branding.patch")


print("\nApplying crash fixes patches...\n")
# Change directory to cr_src_dir and run commands
os.chdir(cr_src_dir)
try_run(f"git apply --reject disable-aero.patch")
try_run(f"git apply --reject android-disable-signin-without-account-manager.patch")


print("\nApplying extension support and protection patches...\n")
# Change directory to cr_src_dir and run commands
os.chdir(cr_src_dir)
try_run(f"git apply --reject android-extensions-support.patch")
try_run(f"git apply --reject chrome-web-store-protection.patch")
try_run(f"git apply --reject enable-extension-in-incognito.patch")


print("\nCopying other files to out/thorium\n")
# Copying additional files
os.makedirs(f"{cr_src_dir}/out/thorium/default_apps", exist_ok=True)
copy_directory(
    os.path.normpath(os.path.join(thor_src_dir, "infra", "default_apps")),
    os.path.normpath(os.path.join(
        cr_src_dir, "out", "thorium", "default_apps")),
)
copy(
    os.path.normpath(os.path.join(
        thor_src_dir, "infra", "initial_preferences")),
    os.path.normpath(os.path.join(cr_src_dir, "out", "thorium")),
)
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


# Copy Windows on Arm files
def copy_woa():
    print("\nCopying Windows on Arm build files\n")
    copy_directory(
        os.path.normpath(os.path.join(thor_src_dir, "arm", "third_party")),
        os.path.normpath(os.path.join(cr_src_dir, "third_party")),
    )
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


# Copy AVX512 build files
def copy_avx512():
    print("\nCopying AVX-512 build files\n")
    copy_directory(
        os.path.normpath(os.path.join(
            thor_src_dir, "other", "AVX2", "third_party")),
        os.path.normpath(os.path.join(cr_src_dir, "third_party")),
    )
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


# Copy AVX2 build files
def copy_avx2():
    print("\nCopying AVX2 build files\n")
    copy_directory(
        os.path.normpath(os.path.join(
            thor_src_dir, "other", "AVX2", "third_party")),
        os.path.normpath(os.path.join(cr_src_dir, "third_party")),
    )
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


# Copy SSE4.1 build files
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


# Copy SSE3 build files
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


# Copy SSE2 build files
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

    print("\nPatching ANGLE for SSE2\n")
    copy(
        os.path.normpath(
            os.path.join(thor_src_dir, "other", "SSE2", "angle-lockfree.patch")
        ),
        os.path.normpath(os.path.join(
            cr_src_dir, "third_party", "angle", "src")),
    )

    # Change directory to angle_dir and run commands
    angle_dir = os.path.join(cr_src_dir, "third_party", "angle", "src")
    os.chdir(angle_dir)
    try_run(f"git apply --reject angle-lockfree.patch")


print("\nDone!\n")
print("\nEnjoy Thorium!\n")
