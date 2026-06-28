#!/bin/bash

# Copyright (c) 2026 Alex313031 and midzer.

YEL='\033[1;33m' # Yellow
GRE='\033[1;32m' # Green
c0='\033[0m' # Reset Text
bold='\033[1m' # Bold Text
underline='\033[4m' # Underline Text

# --help.
displayHelp () {
	printf "\n" &&
	printf "${bold}${GRE}Script to build Thorium and Thorium Shell on MacOS.${c0}\n" &&
	printf "${underline}${YEL}Usage:${c0} build.sh # (where # is number of jobs)${c0}\n" &&
	printf "${YEL}Use the --build-shell flag to also build the thorium_shell target.${c0}\n" &&
	printf "\n"
}
case $1 in
	--help) displayHelp; exit 0;;
esac

# chromium/src dir env variable.
if [ -z "${CR_DIR}" ]; then 
    CR_SRC_DIR="$HOME/chromium/src"
    export CR_SRC_DIR
else 
    CR_SRC_DIR="${CR_DIR}"
    export CR_SRC_DIR
fi

# Build Thorium Shell in addition to the others.
buildShell () {
	printf "\n" &&
	printf "${YEL}Building Thorium and Thorium Shell for MacOS...\n" &&
	printf "\n" &&
	
	# Build Thorium.
	export NINJA_SUMMARIZE_BUILD=1 &&
	export NINJA_STATUS="[%r processes, %f/%t @ %o/s | %e sec. ] " &&
	
	cd ${CR_SRC_DIR} &&
	autoninja -C out/thorium thorium chromedriver thorium_shell policy_templates -j$@ &&

	printf "\n" &&
	cat ~/thorium/logos/thorium_logo_ascii_art.txt &&
	printf "\n" &&
	
	printf "${GRE}${bold}Build Completed. ${YEL}${bold}You can now run \'./create_dmg.sh\', and copy the Thorium Shell.app out.\n" &&
	tput sgr0
}
case $1 in
	--build-shell) buildShell; exit 0;;
esac

printf "\n" &&
printf "${YEL}Building Thorium for MacOS...\n" &&
printf "\n" &&

# Build Thorium.
export NINJA_SUMMARIZE_BUILD=1 &&
export NINJA_STATUS="[%r processes, %f/%t @ %o/s | %e sec. ] " &&

cd ${CR_SRC_DIR} &&
# For restoring individual build targets for customization
#autoninja -C out/thorium thorium chromedriver policy_templates -j$@ &&
autoninja -C out/thorium thorium_all -j$@ &&
printf "${GRE}\nBuilding installer...\n" &&
autoninja -C out/thorium chrome/installer/mac minidump_stackwalk -j$@ &&

printf "\n" &&
cat ~/thorium/logos/thorium_logo_ascii_art.txt &&
printf "\n" &&

printf "${GRE}${bold}Build Completed. ${YEL}${bold}You can now run \'./create_dmg.sh\'\n" &&
tput sgr0
