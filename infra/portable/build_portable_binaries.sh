#!/bin/bash

# Copyright (c) 2026 Alex313031.

GRE='\033[1;32m' # Green
c0=$'\033[0m' # Reset Text
bold=$'\033[1m' # Bold Text

# --help.
displayHelp () {
	printf "\n" &&
	printf "${bold}${GRE}Script to re-generate the portable binaries.${c0}\n" &&
	printf "${bold}${GRE}It simply uses \`shc\` to compile the *.sh scripts.${c0}\n" &&
	printf "${bold}${GRE}Use the --help flag to show this help.${c0}\n" &&
	printf "\n"
}
case $1 in
	--help) displayHelp; exit 0;;
esac

printf "\n" &&
printf "${bold}${GRE}Script to re-generate the portable binaries.${c0}\n" &&
printf "${bold}${GRE}It simply uses \`shc\` to compile the *.sh scripts.${c0}\n" &&
printf "${bold}${GRE}Use the --help flag to show this help.${c0}\n" &&
printf "\n"

# The point of all this is to have a binary that can simply
# be double-clicked, instead of having to set exec permissions
# on the .sh scripts, and then run them from the command line.
# Some OSes and file managers (like Thunar) have options to
# allow executing bash scripts, but this is not guaranteed,
# and decreases the security of the system.

# shc -r relaxes security to make a redistributable binary.
# There isn't anything malicious here so it's OK.

# Cleanup old binaries.
rm -f -v ./THORIUM-PORTABLE &&
rm -f -v ./THORIUM-SHELL &&
rm -f -v ./C/THORIUM-PORTABLE.sh.x.c &&
rm -f -v ./C/THORIUM-SHELL.sh.x.c &&

sleep 1s &&

shc -r -v -o ./THORIUM-PORTABLE -f ./THORIUM-PORTABLE.sh &&
shc -r -v -o ./THORIUM-SHELL -f ./THORIUM-SHELL.sh &&

# Move generated C files for possible future use.
mv -f -v ./THORIUM-PORTABLE.sh.x.c ./C/ &&
mv -f -v ./THORIUM-SHELL.sh.x.c ./C/ &&

printf "\n" &&
printf "${GRE}Done!\n" &&
printf "\n" &&
tput sgr0
