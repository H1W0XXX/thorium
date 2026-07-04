#!/bin/bash

# Copyright (c) 2026 Alex313031.

YEL='\033[1;33m' # Yellow
CYA='\033[1;96m' # Cyan
RED='\033[1;31m' # Red
GRE='\033[1;32m' # Green
c0='\033[0m' # Reset Text
bold='\033[1m' # Bold Text

# Error handling.
yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "${RED}Failed $*"; }

# --help.
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
	--help|-h) displayHelp; exit 0;;
esac

# chromium/src dir env variable.
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

# Copy Thorium sources.
cp -r -v src/chrome ${CR_SRC_DIR}/ &&
cp -r -v src/components ${CR_SRC_DIR}/ &&
cp -r -v src/content ${CR_SRC_DIR}/ &&
cp -r -v src/third_party ${CR_SRC_DIR}/ &&
cp -r -v src/ui ${CR_SRC_DIR}/ &&

cp -r -v thorium_shell/. ${CR_SRC_DIR}/out/thorium/ &&
cp -r -v pak_src/binaries/pak ${CR_SRC_DIR}/out/thorium/ &&
cp -r -v pak_src/binaries/pak-win/. ${CR_SRC_DIR}/out/thorium/ &&

applyThoriumSeries () {
	local condition_args=()

	for arg in "$@"; do
		case "${arg}" in
			--woa)
				condition_args+=(--condition woa)
				;;
			--raspi|--arm64)
				condition_args+=(--condition raspi)
				;;
			--sse2)
				condition_args+=(--condition sse2)
				;;
		esac
	done

	printf "\n" &&
	printf "${YEL}Applying Thorium patch series...${c0}\n" &&
	python3 patch_scripts/series/apply_series.py --source-tree "${CR_SRC_DIR}" --apply "${condition_args[@]}"
}
try applyThoriumSeries "$@";

applyGrdRebase () {
	printf "\n" &&
	printf "${YEL}Applying Thorium GRD/XTB rebase...${c0}\n" &&
	python3 patch_scripts/grd_rebase/sync_grd_strings.py "${CR_SRC_DIR}" \
		--file-allowlist patch_scripts/grd_rebase/config/file_allowlist.csv \
		--message-allowlist patch_scripts/grd_rebase/config/message_allowlist.csv \
		--feature-message-ownership patch_scripts/grd_rebase/config/feature_patch_message_ownership.csv &&
	python3 patch_scripts/grd_rebase/merge_thorium_xtb.py "${CR_SRC_DIR}"
}
try applyGrdRebase;

cd ~/thorium &&

printf "\n" &&
echo "Copying other files to \`out/thorium\`" &&

cp -v infra/thor_ver ${CR_SRC_DIR}/out/thorium/ &&

# MacOS optimizations.
copyMacOS () {
	printf "\n" &&
	printf "${YEL}Copying files for MacOS...${c0}\n" &&
	cp -v other/Mac/thorium_version.txt ${CR_SRC_DIR}/ui/webui/resources/text/ &&
	cd ${CR_SRC_DIR} &&
	python3 tools/update_pgo_profiles.py --target=mac update --gs-url-base=chromium-optimization-profiles/pgo_profiles &&
	python3 tools/update_pgo_profiles.py --target=mac-arm update --gs-url-base=chromium-optimization-profiles/pgo_profiles &&
	cd ~/thorium &&
	printf "\n"
}
case $1 in
	--mac|--macos) copyMacOS;
esac

# Raspberry Pi Source Files.
copyRaspi () {
	printf "\n" &&
	printf "${YEL}Copying Raspberry Pi build files...${c0}\n" &&
	cp -r -v arm/third_party/widevine/* ${CR_SRC_DIR}/third_party/widevine/ &&
	cp -v arm/thorium_version.txt ${CR_SRC_DIR}/ui/webui/resources/text/ &&
	cp -v other/thor_ver_linux/wrapper-raspi ${CR_SRC_DIR}/chrome/installer/linux/common/wrapper &&
	cp -v pak_src/binaries/pak_arm64 ${CR_SRC_DIR}/out/thorium/pak &&
	cd ~/thorium &&
	printf "\n" &&
	# Display raspi ascii art.
	cat logos/raspi_ascii_art.txt
}
case $1 in
	--raspi|--arm64) copyRaspi;
esac

# Windows on ARM64 files.
copyWOA () {
	printf "\n" &&
	printf "${YEL}Copying Windows on ARM build files...${c0}\n" &&
	cp -v arm/thor_ver ${CR_SRC_DIR}/out/thorium/ &&
	cp -v arm/thorium_version.txt ${CR_SRC_DIR}/ui/webui/resources/text/ &&
	cd ${CR_SRC_DIR} &&
	python3 tools/update_pgo_profiles.py --target=win-arm64 update --gs-url-base=chromium-optimization-profiles/pgo_profiles &&
	cd ~/thorium &&
	printf "\n"
}
case $1 in
	--woa) copyWOA;
esac

# Copy AVX512 files.
copyAVX512 () {
	printf "\n" &&
	printf "${YEL}Copying AVX-512 build files...${c0}\n" &&
	cp -v other/AVX512/thor_ver ${CR_SRC_DIR}/out/thorium/ &&
	cp -v other/AVX512/thorium_version.txt ${CR_SRC_DIR}/ui/webui/resources/text/ &&
	cp -v other/thor_ver_linux/wrapper-avx512 ${CR_SRC_DIR}/chrome/installer/linux/common/wrapper &&
	printf "\n"
}
case $1 in
	--avx512) copyAVX512;
esac

# Copy AVX2 files.
copyAVX2 () {
	printf "\n" &&
	printf "${YEL}Copying AVX2 build files...${c0}\n" &&
	cp -v other/AVX2/thor_ver ${CR_SRC_DIR}/out/thorium/ &&
	cp -v other/AVX2/thorium_version.txt ${CR_SRC_DIR}/ui/webui/resources/text/ &&
	cp -v other/thor_ver_linux/wrapper-avx2 ${CR_SRC_DIR}/chrome/installer/linux/common/wrapper &&
	printf "\n"
}
case $1 in
	--avx2) copyAVX2;
esac

# Copy SSE4.1 files.
copySSE4 () {
	printf "\n" &&
	printf "${YEL}Copying SSE4.1 build files...${c0}\n" &&
	cp -v other/SSE4.1/thor_ver ${CR_SRC_DIR}/out/thorium/ &&
	cp -v other/SSE4.1/thorium_version.txt ${CR_SRC_DIR}/ui/webui/resources/text/ &&
	cp -v other/thor_ver_linux/wrapper-sse4 ${CR_SRC_DIR}/chrome/installer/linux/common/wrapper &&
	printf "\n"
}
case $1 in
	--sse4) copySSE4;
esac

# Copy SSE3 files.
copySSE3 () {
	printf "\n" &&
	printf "${YEL}Copying SSE3 build files...${c0}\n" &&
	cp -v other/SSE3/thor_ver ${CR_SRC_DIR}/out/thorium/ &&
	cp -v other/SSE3/thorium_version.txt ${CR_SRC_DIR}/ui/webui/resources/text/ &&
	cp -v other/thor_ver_linux/wrapper-sse3 ${CR_SRC_DIR}/chrome/installer/linux/common/wrapper &&
	cd ${CR_SRC_DIR} &&
	python3 tools/update_pgo_profiles.py --target=win32 update --gs-url-base=chromium-optimization-profiles/pgo_profiles &&
	cd ~/thorium &&
	printf "\n"
}
case $1 in
	--sse3) copySSE3;
esac

# Copy SSE2 files.
copySSE2 () {
	printf "\n" &&
	printf "${YEL}Copying SSE2 (32-bit) build files...${c0}\n" &&
	cp -v other/SSE2/thor_ver ${CR_SRC_DIR}/out/thorium/ &&
	cp -v other/SSE2/thorium_version.txt ${CR_SRC_DIR}/ui/webui/resources/text/ &&
	cp -v other/thor_ver_linux/wrapper-sse2 ${CR_SRC_DIR}/chrome/installer/linux/common/wrapper &&
	cd ${CR_SRC_DIR} &&
	python3 tools/update_pgo_profiles.py --target=win32 update --gs-url-base=chromium-optimization-profiles/pgo_profiles &&
	cd ~/thorium &&
	printf "\n"
}
case $1 in
	--sse2) copySSE2;
esac

# Copy Android files.
copyAndroid () {
	rm -v -f ${CR_SRC_DIR}/chrome/android/java/res_base/drawable-v26/ic_launcher.xml &&
	rm -v -f ${CR_SRC_DIR}/chrome/android/java/res_base/drawable-v26/ic_launcher_round.xml &&
	rm -v -f ${CR_SRC_DIR}/chrome/android/java/res_chromium_base/mipmap-mdpi/layered_app_icon_background.png &&
	rm -v -f ${CR_SRC_DIR}/chrome/android/java/res_chromium_base/mipmap-xhdpi/layered_app_icon_background.png &&
	rm -v -f ${CR_SRC_DIR}/chrome/android/java/res_chromium_base/mipmap-xxxhdpi/layered_app_icon_background.png &&
	rm -v -f ${CR_SRC_DIR}/chrome/android/java/res_chromium_base/mipmap-nodpi/layered_app_icon_foreground.xml &&
	rm -v -f ${CR_SRC_DIR}/chrome/android/java/res_chromium_base/mipmap-hdpi/layered_app_icon_background.png &&
	rm -v -f ${CR_SRC_DIR}/chrome/android/java/res_chromium_base/mipmap-xxhdpi/layered_app_icon_background.png &&
	printf "\n" &&
	printf "${YEL}Downloading PGO profiles...${c0}\n" &&
	cd ${CR_SRC_DIR} &&
	python3 tools/update_pgo_profiles.py --target=android-arm32 update --gs-url-base=chromium-optimization-profiles/pgo_profiles &&
	cd ~/thorium &&
	printf "\n"
}
case $1 in
	--android) copyAndroid;
esac

# Copy CrOS files.
copyCros () {
	printf "\n" &&
	printf "${YEL}Copying ChromiumOS build files...${c0}\n" &&
	cp -v other/CrOS/thorium_version.txt ${CR_SRC_DIR}/ui/webui/resources/text/ &&
	printf "\n"
}
case $1 in
	--cros) copyCros;
esac

printf "\n" &&
printf "${GRE}Done!${c0}\n" &&

cd ~/thorium &&
cat ./logos/thorium_ascii_art.txt &&

printf "${YEL}Tip: See the ${CYA}aliases.txt${YEL} file for some handy bash aliases.${c0}\n" &&
printf "\n" &&
printf "${GRE}Enjoy Thorium!\n" &&
printf "\n" &&
tput sgr0
