#!/bin/bash

# Copyright (c) 2026 Alex313031.

YEL='\033[1;33m' # Yellow
CYA='\033[1;96m' # Cyan
RED='\033[1;31m' # Red
GRE='\033[1;32m' # Green
c0='\033[0m' # Reset Text
bold='\033[1m' # Bold Text
underline='\033[4m' # Underline Text

# Error handling
yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "${RED}Failed $*"; }

# --help
displayHelp () {
	printf "\n" &&
	printf "${bold}${GRE}Script to copy Thorium source files over the Chromium source tree.${c0}\n" &&
	printf "${bold}${YEL}  Use the --mac flag for MacOS builds.${c0}\n" &&
	printf "${bold}${YEL}  Use the --raspi or --arm64 flag for Raspberry Pi builds.${c0}\n" &&
	printf "${bold}${YEL}  Use the --woa flag for Windows on ARM builds.${c0}\n" &&
	printf "${bold}${YEL}  Use the --avx512 flag for AVX-512 Builds.${c0}\n" &&
	printf "${bold}${YEL}  Use the --avx2 flag for AVX2 Builds.${c0}\n" &&
	printf "${bold}${YEL}  Use the --sse4 flag for SSE4.1 Builds.${c0}\n" &&
	printf "${bold}${YEL}  Use the --sse3 flag for SSE3 Builds.${c0}\n" &&
	printf "${bold}${YEL}  Use the --sse2 flag for 32 bit SSE2 Builds.${c0}\n" &&
	printf "${bold}${YEL}  Use the --android flag for Android Builds.${c0}\n" &&
	printf "${bold}${YEL}  Use the --cros flag for ChromiumOS Builds.${c0}\n" &&
	printf "${bold}${YEL}  --help or -h shows this help.${c0}\n" &&
	printf "${bold}${YEL}  IMPORTANT: For Polly builds, first run build_polly.sh in ./infra before building.${c0}\n" &&
	printf "${bold}${YEL}   This should be done AFTER running this setup.sh script!${c0}\n" &&
	printf "\n"
	printf "${bold}${YEL}  NOTE: The \`CR_DIR\` env variable can be used to override the location of \"chromium/src\".${c0}\n" &&
	printf "${bold}${YEL}   The default is $HOME/chromium/src${c0}\n" &&
	printf "\n"
}
case $1 in
	--help) displayHelp; exit 0;;
esac
case $1 in
	-h) displayHelp; exit 0;;
esac

# chromium/src dir env variable
if [ -z "${CR_DIR}" ]; then 
    CR_SRC_DIR="$HOME/chromium/src"
    export CR_SRC_DIR
else 
    CR_SRC_DIR="${CR_DIR}"
    export CR_SRC_DIR
fi

printf "\n" &&
printf "${YEL}Creating build output directory...${c0}\n" &&

mkdir -v -p ${CR_SRC_DIR}/out/thorium/ &&

printf "\n" &&
printf "${YEL}Copying Thorium source files over the Chromium tree...${c0}\n" &&
cd ~/thorium &&
printf "\n" &&

# Copy Thorium sources
cp -r -v src/build ${CR_SRC_DIR}/ &&
cp -r -v src/chrome ${CR_SRC_DIR}/ &&
cp -r -v src/chromeos ${CR_SRC_DIR}/ &&
cp -r -v src/components ${CR_SRC_DIR}/ &&
cp -r -v src/media ${CR_SRC_DIR}/ &&
cp -r -v src/net ${CR_SRC_DIR}/ &&
cp -r -v src/services ${CR_SRC_DIR}/ &&
cp -r -v src/third_party ${CR_SRC_DIR}/ &&
cp -r -v src/ui ${CR_SRC_DIR}/ &&

cp -v src/content/shell/app/thorium_shell.ico ${CR_SRC_DIR}/content/shell/app/ &&
cp -r -v thorium_shell/. ${CR_SRC_DIR}/out/thorium/ &&
cp -r -v pak_src/binaries/pak ${CR_SRC_DIR}/out/thorium/ &&
cp -r -v pak_src/binaries/pak-win/. ${CR_SRC_DIR}/out/thorium/ &&

patchThor () {
	cp -v other/add-hevc-ffmpeg-decoder-parser.patch ${CR_SRC_DIR}/third_party/ffmpeg/ &&
	cp -v other/change-libavcodec-header.patch ${CR_SRC_DIR}/third_party/ffmpeg/ &&
	cp -v other/fix-ffmpeg-android-x86-disable-hevc-nasm.patch ${CR_SRC_DIR}/third_party/ffmpeg/ &&
	cp -v other/ffmpeg-branding.patch ${CR_SRC_DIR}/third_party/ffmpeg/ &&
	cp -v other/widevine-cdm-support.patch ${CR_SRC_DIR}/third_party/widevine/ &&
	cp -v other/enable-hevc-ffmpeg-decoding.patch ${CR_SRC_DIR}/ &&
	cp -v other/enable-mpeg2-ac3-eac3-decoding.patch ${CR_SRC_DIR}/ &&
	cp -v other/thorium-media-switches.patch ${CR_SRC_DIR}/ &&
	cp -v other/widevine-cdm-host-verification.patch ${CR_SRC_DIR}/ &&
	cp -v other/thorium-default-api-keys.patch ${CR_SRC_DIR}/ &&
	cp -v other/disable-fetching-field-trials.patch ${CR_SRC_DIR}/ &&
	cp -v other/thorium-search-engines-data.patch ${CR_SRC_DIR}/third_party/search_engines_data/resources/ &&
	cp -v other/thorium-blink-feature-defaults.patch ${CR_SRC_DIR}/ &&
	cp -v other/allow-webaudio-autoplay.patch ${CR_SRC_DIR}/ &&
	cp -v other/enable-saving-pages-from-all-schemes.patch ${CR_SRC_DIR}/ &&
	cp -v other/content-gpu-vaapi-libva-config.patch ${CR_SRC_DIR}/ &&
	cp -v other/thorium-content-shell-branding.patch ${CR_SRC_DIR}/ &&
	cp -v other/bookmark-default-prefs.patch ${CR_SRC_DIR}/ &&
	cp -v other/dom-distiller-reader-mode.patch ${CR_SRC_DIR}/ &&
	cp -v other/thorium-root-build-targets.patch ${CR_SRC_DIR}/ &&
	cp -v other/thorium-v8-simd-opts.patch ${CR_SRC_DIR}/ &&
	cp -v other/llvm-optimized-avx2-build.patch ${CR_SRC_DIR}/ &&
	cp -v other/v8-context-snapshot-rpath.patch ${CR_SRC_DIR}/ &&
	cp -v other/linux-disable-custom-titlebar-default.patch ${CR_SRC_DIR}/ &&
	cp -v other/thorium-ui-debug-shell.patch ${CR_SRC_DIR}/ &&
	cp -v other/thorium-webui-image-resources.patch ${CR_SRC_DIR}/ &&
	cp -v other/thorium-chrome-urls-page.patch ${CR_SRC_DIR}/ &&
	cp -v other/thorium-flags-page-branding.patch ${CR_SRC_DIR}/ &&
	cp -v other/thorium-version-page-branding.patch ${CR_SRC_DIR}/ &&
	cp -v other/thorium-vector-icons.patch ${CR_SRC_DIR}/ &&
	cp -v other/fix-policy-templates.patch ${CR_SRC_DIR}/ &&
	cp -v other/ftp-support-thorium.patch ${CR_SRC_DIR}/ &&
	cp -v other/restore_download_shelf.patch ${CR_SRC_DIR}/ &&
	cp -v other/thorium-2024-ui.patch ${CR_SRC_DIR}/ &&
	cp -v other/GPC.patch ${CR_SRC_DIR}/ &&
	cp -v other/mini_installer.patch ${CR_SRC_DIR}/ &&
	cp -v other/open_in_same_tab.patch ${CR_SRC_DIR}/ &&
	cp -v other/add-flag-for-close-confirmation.patch ${CR_SRC_DIR}/ &&
	cp -v other/add-flag-to-close-window-with-last-tab.patch ${CR_SRC_DIR}/ &&
	cp -v other/add-flag-to-scroll-tabs.patch ${CR_SRC_DIR}/ &&
	cp -v other/add-flag-for-custom-ntp.patch ${CR_SRC_DIR}/ &&
	cp -v other/force-disable-tab-outlines.patch ${CR_SRC_DIR}/ &&
	cp -v other/disable-thorium-dns-config.patch ${CR_SRC_DIR}/ &&
	cp -v other/reduce-doh-request-headers.patch ${CR_SRC_DIR}/ &&
	cp -v other/add-flag-to-keep-all-history.patch ${CR_SRC_DIR}/ &&
	cp -v other/enable-parallel-downloading-by-default.patch ${CR_SRC_DIR}/ &&
	cp -v other/thorium-dino-game.patch ${CR_SRC_DIR}/ &&
	cp -v other/allow-insecure-downloads.patch ${CR_SRC_DIR}/ &&
	cp -v other/disable-download-quarantine.patch ${CR_SRC_DIR}/ &&
	cp -v other/disable-vulkan-gpu-log-warnings.patch ${CR_SRC_DIR}/ &&
	cp -v other/thorium-sandbox-compat.patch ${CR_SRC_DIR}/ &&
	cp -v other/thoriumos-ash-vector-icons.patch ${CR_SRC_DIR}/ &&
	cp -v other/thoriumos-help-app-discovery.patch ${CR_SRC_DIR}/ &&
	cp -v other/thoriumos-sample-system-web-app.patch ${CR_SRC_DIR}/ &&
	cp -v other/add-flag-for-auto-dark-mode.patch ${CR_SRC_DIR}/ &&
	cp -v other/disable-thorium-icons.patch ${CR_SRC_DIR}/ &&
	cp -v other/always-enable-reload-menu.patch ${CR_SRC_DIR}/ &&
	cp -v other/thorium_webui.patch ${CR_SRC_DIR}/ &&
	cp -v other/keep-expired-flags.patch ${CR_SRC_DIR}/ &&
	cp -v other/disable-privacy-sandbox.patch ${CR_SRC_DIR}/ &&
	cp -v other/disable-encryption.patch ${CR_SRC_DIR}/ &&
	cp -v other/disable-feature-promos.patch ${CR_SRC_DIR}/ &&
	cp -v other/thorium-install-static-branding.patch ${CR_SRC_DIR}/ &&
	cp -v other/win_updater.patch ${CR_SRC_DIR}/ &&
	cp -v other/keyboard_shortcuts.patch ${CR_SRC_DIR}/ &&

	# The following patch could not be fixed upstream because it
	# is related to our custom flags
	cp -v other/disable-aero.patch ${CR_SRC_DIR}/ &&
	
	cp -v other/allow_manifest_v2_extensions.patch ${CR_SRC_DIR}/ &&
	cp -v other/increase-dnr-limits.patch ${CR_SRC_DIR}/ &&
	cp -v other/show-hosted-apps-in-extensions.patch ${CR_SRC_DIR}/ &&
	
	cp -v other/android-disable-signin-without-account-manager.patch ${CR_SRC_DIR}/ &&
	cp -v other/android-extensions-support.patch ${CR_SRC_DIR}/ &&
	cp -v other/chrome-web-store-protection.patch ${CR_SRC_DIR}/ &&
	cp -v other/enable-extension-in-incognito.patch ${CR_SRC_DIR}/ &&

	printf "\n" &&
	printf "${YEL}Patching FFMPEG for HEVC...${c0}\n" &&
	cd ${CR_SRC_DIR}/third_party/ffmpeg &&
	git apply --reject ./add-hevc-ffmpeg-decoder-parser.patch &&
    printf "${YEL}libavcodec header patch for HEVC...${c0}\n" &&
	git apply --reject ./change-libavcodec-header.patch &&
	printf "${YEL}Fix FFMPEG Android x86 HEVC NASM disable patch...${c0}\n" &&
	git apply --reject ./fix-ffmpeg-android-x86-disable-hevc-nasm.patch &&
	printf "${YEL}FFmpeg branding patch...${c0}\n" &&
	git apply --reject ./ffmpeg-branding.patch &&
	printf "${YEL}Enable HEVC FFMPEG decoding patch...${c0}\n" &&
	cd ${CR_SRC_DIR} &&
	git apply --reject ./enable-hevc-ffmpeg-decoding.patch &&
	printf "${YEL}Enable MPEG2 and AC3/EAC3 decoding patch...${c0}\n" &&
	git apply --reject ./enable-mpeg2-ac3-eac3-decoding.patch &&
	printf "${YEL}Thorium media switches patch...${c0}\n" &&
	git apply --reject ./thorium-media-switches.patch &&
	printf "${YEL}Widevine CDM support patch...${c0}\n" &&
	git apply --reject --directory=third_party/widevine ./third_party/widevine/widevine-cdm-support.patch &&
	printf "${YEL}Widevine CDM host verification patch...${c0}\n" &&
	git apply --reject ./widevine-cdm-host-verification.patch &&
	printf "${YEL}Thorium default Google API keys patch...${c0}\n" &&
	git apply --reject ./thorium-default-api-keys.patch &&
	printf "${YEL}Disable fetching field trials patch...${c0}\n" &&
	git apply --reject ./disable-fetching-field-trials.patch &&
	printf "${YEL}Thorium search engines data patch...${c0}\n" &&
	cd ${CR_SRC_DIR}/third_party/search_engines_data/resources &&
	git apply --reject ./thorium-search-engines-data.patch &&
	cd ${CR_SRC_DIR} &&
	printf "${YEL}Thorium Blink feature defaults patch...${c0}\n" &&
	git apply --reject ./thorium-blink-feature-defaults.patch &&
	printf "${YEL}Allow WebAudio autoplay patch...${c0}\n" &&
	git apply --reject ./allow-webaudio-autoplay.patch &&
	printf "${YEL}Enable saving pages from all schemes patch...${c0}\n" &&
	git apply --reject ./enable-saving-pages-from-all-schemes.patch &&
	printf "${YEL}Content GPU VAAPI libva config patch...${c0}\n" &&
	git apply --reject ./content-gpu-vaapi-libva-config.patch &&
	printf "${YEL}Thorium content shell branding patch...${c0}\n" &&
	git apply --reject ./thorium-content-shell-branding.patch &&
	printf "${YEL}Bookmark default prefs patch...${c0}\n" &&
	git apply --reject ./bookmark-default-prefs.patch &&
	printf "${YEL}Dom Distiller reader mode patch...${c0}\n" &&
	git apply --reject ./dom-distiller-reader-mode.patch &&
	printf "${YEL}Thorium root build targets patch...${c0}\n" &&
	git apply --reject ./thorium-root-build-targets.patch &&
	printf "${YEL}Thorium V8 SIMD opts patch...${c0}\n" &&
	cd ${CR_SRC_DIR}/v8 &&
	git apply --reject ../thorium-v8-simd-opts.patch &&
	cd ${CR_SRC_DIR} &&
	printf "${YEL}LLVM optimized AVX2 build patch...${c0}\n" &&
	git apply --reject ./llvm-optimized-avx2-build.patch &&
	printf "${YEL}V8 context snapshot rpath patch...${c0}\n" &&
	git apply --reject ./v8-context-snapshot-rpath.patch &&
	printf "${YEL}Linux disable custom titlebar default patch...${c0}\n" &&
	git apply --reject ./linux-disable-custom-titlebar-default.patch &&
	printf "${YEL}Thorium UI debug shell patch...${c0}\n" &&
	git apply --reject ./thorium-ui-debug-shell.patch &&
	printf "${YEL}Thorium WebUI image resources patch...${c0}\n" &&
	git apply --reject ./thorium-webui-image-resources.patch &&
	printf "${YEL}Thorium chrome:// URLs page patch...${c0}\n" &&
	git apply --reject ./thorium-chrome-urls-page.patch &&
	printf "${YEL}Thorium flags page branding patch...${c0}\n" &&
	git apply --reject ./thorium-flags-page-branding.patch &&
	printf "${YEL}Thorium version page branding patch...${c0}\n" &&
	git apply --reject ./thorium-version-page-branding.patch &&
	printf "${YEL}Thorium vector icons patch...${c0}\n" &&
	git apply --reject ./thorium-vector-icons.patch &&

	printf "\n" &&
	printf "${YEL}Patching policy templates...${c0}\n" &&
	cd ${CR_SRC_DIR} &&
	git apply --reject ./fix-policy-templates.patch &&

	printf "\n" &&
	printf "${YEL}Patching FTP support...${c0}\n" &&
	cd ${CR_SRC_DIR} &&
	git apply --reject ./ftp-support-thorium.patch &&

	printf "\n" &&
	printf "${YEL}Patching in GPC support...${c0}\n" &&
	cd ${CR_SRC_DIR} &&
	git apply --reject ./GPC.patch &&

	printf "\n" &&
	printf "${YEL}Patching for Thorium 2024 UI...${c0}\n" &&
	cd ${CR_SRC_DIR} &&
	git apply --reject ./thorium-2024-ui.patch &&
	printf "${YEL}Download Shelf patch...${c0}\n" &&
	git apply --reject ./restore_download_shelf.patch &&

	printf "${YEL}Patching mini_installer...${c0}\n" &&
	cd ${CR_SRC_DIR} &&
	git apply --reject ./mini_installer.patch &&

	printf "\n" &&
	printf "${YEL}Applying other Misc. patches...${c0}\n" &&
	cd ${CR_SRC_DIR} &&
	printf "${YEL}Open in same tab patch...${c0}\n" &&
	git apply --reject ./open_in_same_tab.patch &&
	printf "${YEL}Close confirmation flag patch...${c0}\n" &&
	git apply --reject ./add-flag-for-close-confirmation.patch &&
	printf "${YEL}Close window with last tab patch...${c0}\n" &&
	git apply --reject ./add-flag-to-close-window-with-last-tab.patch &&
	printf "${YEL}Scroll tabs patch...${c0}\n" &&
	git apply --reject ./add-flag-to-scroll-tabs.patch &&
	printf "${YEL}Custom NTP patch...${c0}\n" &&
	git apply --reject ./add-flag-for-custom-ntp.patch &&
	printf "${YEL}Force disable tab outlines patch...${c0}\n" &&
	git apply --reject ./force-disable-tab-outlines.patch &&
	printf "${YEL}Disable Thorium DNS config patch...${c0}\n" &&
	git apply --reject ./disable-thorium-dns-config.patch &&
	printf "${YEL}Reduce DoH request headers patch...${c0}\n" &&
	git apply --reject ./reduce-doh-request-headers.patch &&
	printf "${YEL}Keep all history patch...${c0}\n" &&
	git apply --reject ./add-flag-to-keep-all-history.patch &&
	printf "${YEL}Enable parallel downloading by default patch...${c0}\n" &&
	git apply --reject ./enable-parallel-downloading-by-default.patch &&
	printf "${YEL}Thorium Dino game patch...${c0}\n" &&
	git apply --reject ./thorium-dino-game.patch &&
	printf "${YEL}Allow insecure downloads patch...${c0}\n" &&
	git apply --reject ./allow-insecure-downloads.patch &&
	printf "${YEL}Disable download quarantine patch...${c0}\n" &&
	git apply --reject ./disable-download-quarantine.patch &&
	printf "${YEL}Disable Vulkan GPU log warnings patch...${c0}\n" &&
	git apply --reject ./disable-vulkan-gpu-log-warnings.patch &&
	printf "${YEL}Thorium sandbox compatibility patch...${c0}\n" &&
	git apply --reject ./thorium-sandbox-compat.patch &&
	printf "${YEL}ThoriumOS Ash vector icons patch...${c0}\n" &&
	git apply --reject ./thoriumos-ash-vector-icons.patch &&
	printf "${YEL}ThoriumOS Help App discovery patch...${c0}\n" &&
	git apply --reject ./thoriumos-help-app-discovery.patch &&
	printf "${YEL}ThoriumOS Sample System Web App patch...${c0}\n" &&
	git apply --reject ./thoriumos-sample-system-web-app.patch &&
	printf "${YEL}Auto dark mode patch...${c0}\n" &&
	git apply --reject ./add-flag-for-auto-dark-mode.patch &&
	printf "${YEL}Disable Thorium icons patch...${c0}\n" &&
	git apply --reject ./disable-thorium-icons.patch &&
	printf "${YEL}Always enable reload menu patch...${c0}\n" &&
	git apply --reject ./always-enable-reload-menu.patch &&
	printf "${YEL}Allow Manifest V2 extensions...${c0}\n" &&
	git apply --reject ./allow_manifest_v2_extensions.patch &&
	printf "${YEL}Increase Declarative Net Request limits...${c0}\n" &&
	git apply --reject ./increase-dnr-limits.patch &&
	printf "${YEL}Show hosted apps in extensions settings...${c0}\n" &&
	git apply --reject ./show-hosted-apps-in-extensions.patch &&
	printf "${YEL}Thorium WebUI patch...${c0}\n" &&
	git apply --reject ./thorium_webui.patch &&
	printf "${YEL}Thorium Updater patch...${c0}\n" &&
	git apply --reject ./win_updater.patch &&
	printf "${YEL}Thorium Keyboard Shortcuts patch...${c0}\n" &&
	git apply --reject ./keyboard_shortcuts.patch &&
	printf "${YEL}Keep expired flags patch...${c0}\n" &&
	git apply --reject ./keep-expired-flags.patch &&
	printf "${YEL}Disable Privacy Sandbox patch...${c0}\n" &&
	git apply --reject ./disable-privacy-sandbox.patch &&
	printf "${YEL}Disable encryption patch...${c0}\n" &&
	git apply --reject ./disable-encryption.patch &&
	printf "${YEL}Disable feature promos patch...${c0}\n" &&
	git apply --reject ./disable-feature-promos.patch &&
	printf "${YEL}Thorium install/static branding patch...${c0}\n" &&
	git apply --reject ./thorium-install-static-branding.patch &&
	printf "${YEL}Some crashes fixes...${c0}\n" &&
	git apply --reject ./disable-aero.patch &&
    printf "${YEL}Disable signin without account manager...${c0}\n" &&
	git apply --reject ./android-disable-signin-without-account-manager.patch &&
	printf "${YEL}Android extensions support patch...${c0}\n" &&
	git apply --reject ./android-extensions-support.patch &&
	printf "${YEL}Chrome Web Store protection patch...${c0}\n" &&
	git apply --reject ./chrome-web-store-protection.patch &&
	printf "${YEL}Enable extension in incognito patch...${c0}\n" &&
	git apply --reject ./enable-extension-in-incognito.patch
}
[ -f ${CR_SRC_DIR}/fix-policy-templates.patch ] || patchThor;

patchAC3 () {
	#cp -v other/ffmpeg_hevc_ac3.patch ${CR_SRC_DIR}/third_party/ffmpeg/ &&

	#printf "\n" &&
	#printf "${YEL}Patching FFMPEG for AC3 & E-AC3...${c0}\n" &&
	#cd ${CR_SRC_DIR}/third_party/ffmpeg &&
	#git apply --reject ./ffmpeg_hevc_ac3.patch &&
	cd ~/thorium
}

patchSSE2 () {
	cp -v other/SSE2/angle-lockfree.patch ${CR_SRC_DIR}/third_party/angle/src/ &&

	printf "\n" &&
	printf "${YEL}Patching ANGLE for SSE2...${c0}\n" &&
	cd ${CR_SRC_DIR}/third_party/angle/src &&
	git apply --reject ./angle-lockfree.patch &&
	cd ~/thorium
}

cd ~/thorium &&

printf "\n" &&
echo "Copying other files to \`out/thorium\`" &&

# Add default_apps dir for uBlock Origin extension.
mkdir -v -p ${CR_SRC_DIR}/out/thorium/default_apps &&
cp -r -v infra/default_apps/. ${CR_SRC_DIR}/out/thorium/default_apps/ &&

# Add initial preferences file to open Thorium welcome page on first run.
cp -v infra/initial_preferences ${CR_SRC_DIR}/out/thorium/ &&
cp -v infra/thor_ver ${CR_SRC_DIR}/out/thorium/ &&

# MacOS ARMv8.3-A optimizations
copyMacOS () {
	printf "\n" &&
	printf "${YEL}Copying files for MacOS...${c0}\n" &&
	cp -v arm/mac_arm.gni ${CR_SRC_DIR}/build/config/arm.gni &&
	cp -v other/Mac/thorium_version.txt ${CR_SRC_DIR}/ui/webui/resources/text/ &&
	cp -r -v arm/third_party/* ${CR_SRC_DIR}/third_party/ &&
	cd ${CR_SRC_DIR} &&
	python3 tools/update_pgo_profiles.py --target=mac update --gs-url-base=chromium-optimization-profiles/pgo_profiles &&
	python3 tools/update_pgo_profiles.py --target=mac-arm update --gs-url-base=chromium-optimization-profiles/pgo_profiles &&
	cd ~/thorium &&
	[ -f ${CR_SRC_DIR}/third_party/ffmpeg/ffmpeg_hevc_ac3.patch ] || patchAC3;
	printf "\n"
}
case $1 in
	--mac) copyMacOS;
esac
case $1 in
	--macos) copyMacOS;
esac

# Raspberry Pi Source Files
copyRaspi () {
	printf "\n" &&
	printf "${YEL}Copying Raspberry Pi build files...${c0}\n" &&
	cp -r -v arm/third_party/* ${CR_SRC_DIR}/third_party/ &&
	cp -r -v arm/raspi/* ${CR_SRC_DIR}/ &&
	cp -v arm/thorium_version.txt ${CR_SRC_DIR}/ui/webui/resources/text/ &&
	cp -v other/thor_ver_linux/wrapper-raspi ${CR_SRC_DIR}/chrome/installer/linux/common/wrapper &&
	cp -v pak_src/binaries/pak_arm64 ${CR_SRC_DIR}/out/thorium/pak &&
	#./infra/fix_libaom.sh &&
	printf "\n" &&
	cp -r -v arm/raspi/build/config/* ${CR_SRC_DIR}/build/config/ &&
	printf "\n" &&
	# Display raspi ascii art
	cat logos/raspi_ascii_art.txt
}
case $1 in
	--raspi) copyRaspi;
esac
case $1 in
	--arm64) copyRaspi;
esac

# Windows on ARM64 files
copyWOA () {
	printf "\n" &&
	printf "${YEL}Copying Windows on ARM build files...${c0}\n" &&
	cp -v arm/thorium_version.txt ${CR_SRC_DIR}/ui/webui/resources/text/ &&
	cp -r -v arm/third_party/* ${CR_SRC_DIR}/third_party/ &&
	cd ${CR_SRC_DIR} &&
	python3 tools/update_pgo_profiles.py --target=win-arm64 update --gs-url-base=chromium-optimization-profiles/pgo_profiles &&
	cd ~/thorium &&
	# Use regular arm.gni from src, pending further testing
	# cp -v arm/woa_arm.gni ${CR_SRC_DIR}/build/config/arm.gni &&
	printf "\n"
}
case $1 in
	--woa) copyWOA;
esac

# Copy AVX512 files
copyAVX512 () {
	printf "\n" &&
	printf "${YEL}Copying AVX-512 build files...${c0}\n" &&
	cp -r -v other/AVX2/third_party/* ${CR_SRC_DIR}/third_party/ &&
	cp -v other/AVX512/thor_ver ${CR_SRC_DIR}/out/thorium/ &&
	cp -v other/AVX512/thorium_version.txt ${CR_SRC_DIR}/ui/webui/resources/text/ &&
	cp -v other/thor_ver_linux/wrapper-avx512 ${CR_SRC_DIR}/chrome/installer/linux/common/wrapper &&
	[ -f ${CR_SRC_DIR}/third_party/ffmpeg/ffmpeg_hevc_ac3.patch ] || patchAC3;
	printf "\n"
}
case $1 in
	--avx512) copyAVX512;
esac

# Copy AVX2 files
copyAVX2 () {
	printf "\n" &&
	printf "${YEL}Copying AVX2 build files...${c0}\n" &&
	cp -r -v other/AVX2/third_party/* ${CR_SRC_DIR}/third_party/ &&
	cp -v other/AVX2/thor_ver ${CR_SRC_DIR}/out/thorium/ &&
	cp -v other/AVX2/thorium_version.txt ${CR_SRC_DIR}/ui/webui/resources/text/ &&
	cp -v other/thor_ver_linux/wrapper-avx2 ${CR_SRC_DIR}/chrome/installer/linux/common/wrapper &&
	[ -f ${CR_SRC_DIR}/third_party/ffmpeg/ffmpeg_hevc_ac3.patch ] || patchAC3;
	printf "\n"
}
case $1 in
	--avx2) copyAVX2;
esac

# Copy SSE4.1 files
copySSE4 () {
	printf "\n" &&
	printf "${YEL}Copying SSE4.1 build files...${c0}\n" &&
	cp -v other/SSE4.1/thor_ver ${CR_SRC_DIR}/out/thorium/ &&
	cp -v other/SSE4.1/thorium_version.txt ${CR_SRC_DIR}/ui/webui/resources/text/ &&
	cp -v other/thor_ver_linux/wrapper-sse4 ${CR_SRC_DIR}/chrome/installer/linux/common/wrapper &&
	[ -f ${CR_SRC_DIR}/third_party/ffmpeg/ffmpeg_hevc_ac3.patch ] || patchAC3;
	printf "\n"
}
case $1 in
	--sse4) copySSE4;
esac

# Copy SSE3 files
copySSE3 () {
	printf "\n" &&
	printf "${YEL}Copying SSE3 build files...${c0}\n" &&
	cp -v other/SSE3/thor_ver ${CR_SRC_DIR}/out/thorium/ &&
	cp -v other/SSE3/thorium_version.txt ${CR_SRC_DIR}/ui/webui/resources/text/ &&
	cp -v other/thor_ver_linux/wrapper-sse3 ${CR_SRC_DIR}/chrome/installer/linux/common/wrapper &&
	cd ${CR_SRC_DIR} &&
	python3 tools/update_pgo_profiles.py --target=win32 update --gs-url-base=chromium-optimization-profiles/pgo_profiles &&
	cd ~/thorium &&
	[ -f ${CR_SRC_DIR}/third_party/ffmpeg/ffmpeg_hevc_ac3.patch ] || patchAC3;
	printf "\n"
}
case $1 in
	--sse3) copySSE3;
esac

# Copy SSE2 files
copySSE2 () {
	printf "\n" &&
	printf "${YEL}Copying SSE2 (32-bit) build files...${c0}\n" &&
	cp -v other/SSE2/thor_ver ${CR_SRC_DIR}/out/thorium/ &&
	cp -v other/SSE2/thorium_version.txt ${CR_SRC_DIR}/ui/webui/resources/text/ &&
	cp -v other/thor_ver_linux/wrapper-sse2 ${CR_SRC_DIR}/chrome/installer/linux/common/wrapper &&
	cd ${CR_SRC_DIR} &&
	python3 tools/update_pgo_profiles.py --target=win32 update --gs-url-base=chromium-optimization-profiles/pgo_profiles &&
	cd ~/thorium &&
	[ -f ${CR_SRC_DIR}/third_party/ffmpeg/ffmpeg_hevc_ac3.patch ] || patchAC3;
	[ -f ${CR_SRC_DIR}/third_party/angle/src/angle-lockfree.patch ] || patchSSE2;
	printf "\n"
}
case $1 in
	--sse2) copySSE2;
esac

# Copy Android files
copyAndroid () {
	printf "\n" &&
	printf "${YEL}Copying Android (ARM64 and ARM32) build files...${c0}\n" &&
	cp -r -v arm/third_party/* ${CR_SRC_DIR}/third_party/ &&
	printf "\n" &&
	cp -r -v arm/android/* ${CR_SRC_DIR}/ &&
	printf "\n" &&
	rm -v -f ${CR_SRC_DIR}/chrome/android/java/res_base/drawable-v26/ic_launcher.xml &&
	rm -v -f ${CR_SRC_DIR}/chrome/android/java/res_base/drawable-v26/ic_launcher_round.xml &&
	rm -v -f ${CR_SRC_DIR}/chrome/android/java/res_chromium_base/mipmap-mdpi/layered_app_icon_background.png &&
	#rm -v -f ${CR_SRC_DIR}/chrome/android/java/res_chromium_base/mipmap-mdpi/layered_app_icon.png &&
	rm -v -f ${CR_SRC_DIR}/chrome/android/java/res_chromium_base/mipmap-xhdpi/layered_app_icon_background.png &&
	#rm -v -f ${CR_SRC_DIR}/chrome/android/java/res_chromium_base/mipmap-xhdpi/layered_app_icon.png &&
	rm -v -f ${CR_SRC_DIR}/chrome/android/java/res_chromium_base/mipmap-xxxhdpi/layered_app_icon_background.png &&
	#rm -v -f ${CR_SRC_DIR}/chrome/android/java/res_chromium_base/mipmap-xxxhdpi/layered_app_icon.png &&
	rm -v -f ${CR_SRC_DIR}/chrome/android/java/res_chromium_base/mipmap-nodpi/layered_app_icon_foreground.xml &&
	rm -v -f ${CR_SRC_DIR}/chrome/android/java/res_chromium_base/mipmap-hdpi/layered_app_icon_background.png &&
	#rm -v -f ${CR_SRC_DIR}/chrome/android/java/res_chromium_base/mipmap-hdpi/layered_app_icon.png &&
	rm -v -f ${CR_SRC_DIR}/chrome/android/java/res_chromium_base/mipmap-xxhdpi/layered_app_icon_background.png &&
	#rm -v -f ${CR_SRC_DIR}/chrome/android/java/res_chromium_base/mipmap-xxhdpi/layered_app_icon.png &&
	#./infra/fix_libaom.sh &&
	printf "\n" &&
	printf "${YEL}Downloading PGO profiles...${c0}\n" &&
	cd ${CR_SRC_DIR} &&
	# python3 tools/update_pgo_profiles.py --target=android-desktop-arm64 update --gs-url-base=chromium-optimization-profiles/pgo_profiles &&
	python3 tools/update_pgo_profiles.py --target=android-arm32 update --gs-url-base=chromium-optimization-profiles/pgo_profiles &&
	cd ~/thorium &&
	printf "\n"
}
case $1 in
	--android) copyAndroid;
esac

# Copy CrOS files
copyCros () {
	printf "\n" &&
	printf "${YEL}Copying ChromiumOS build files...${c0}\n" &&
	cp -r -v other/CrOS/* ${CR_SRC_DIR}/ &&
	cp -v other/CrOS/thorium_version.txt ${CR_SRC_DIR}/ui/webui/resources/text/ &&
	[ -f ${CR_SRC_DIR}/third_party/ffmpeg/ffmpeg_hevc_ac3.patch ] || patchAC3;
	printf "\n"
}
case $1 in
	--cros) copyCros;
esac

printf "\n" &&
printf "${GRE}Done!${c0}\n" &&

#. ~/thorium/aliases.txt &&

#printf "\n" &&
#printf "export ${CYA}NINJA_SUMMARIZE_BUILD=1${c0}\n" &&
#printf "export ${CYA}EDITOR=nano${c0}\n" &&
#printf "export ${CYA}VISUAL=nano${c0}\n" &&
#printf "\n" &&
#printf "alias ${YEL}origin${c0} = ${CYA}git checkout -f origin/main${c0}\n" &&
#printf "alias ${YEL}gfetch${c0} = ${CYA}git fetch --tags${c0}\n" &&
#printf "alias ${YEL}rebase${c0} = ${CYA}git rebase-update${c0}\n" &&
#printf "alias ${YEL}gsync${c0} = ${CYA}gclient sync --with_branch_heads --with_tags -f -R -D${c0}\n" &&
#printf "alias ${YEL}args${c0} = ${CYA}gn args out/thorium${c0}\n" &&
#printf "alias ${YEL}gnls${c0} = ${CYA}gn ls out/thorium${c0}\n" &&
#printf "alias ${YEL}show${c0} = ${CYA}git show-ref${c0}\n" &&
#printf "alias ${YEL}runhooks${c0} = ${CYA}gclient runhooks${c0}\n" &&
#printf "alias ${YEL}pgo${c0} = ${CYA}python3 tools/update_pgo_profiles.py --target=linux update --gs-url-base=chromium-optimization-profiles/pgo_profiles${c0}\n" &&
#printf "alias ${YEL}pgow${c0} = ${CYA}python3 tools/update_pgo_profiles.py --target=win64 update --gs-url-base=chromium-optimization-profiles/pgo_profiles${c0}\n" &&
#printf "alias ${YEL}pgom${c0} = ${CYA}python3 tools/update_pgo_profiles.py --target=mac update --gs-url-base=chromium-optimization-profiles/pgo_profiles${c0}\n" &&
#printf "alias ${YEL}pgomac-arm${c0} = ${CYA}python3 tools/update_pgo_profiles.py --target=mac-arm update --gs-url-base=chromium-optimization-profiles/pgo_profiles${c0}\n" &&
#printf "\n" &&

cd ~/thorium &&
cat ./logos/thorium_ascii_art.txt &&

printf "${YEL}Tip: See the ${CYA}aliases.txt${YEL} file for some handy bash aliases.${c0}\n" &&
printf "\n" &&
printf "${RED} IMPORTANT: If you ran setup.sh without any flags, you must also run ./patch_ac3.sh for AC3/E-AC3 support.\n" &&
printf "\n" &&
printf "${GRE}  Enjoy Thorium!\n" &&
printf "\n" &&
tput sgr0
