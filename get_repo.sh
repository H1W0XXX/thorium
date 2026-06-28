#!/bin/bash

# Copyright (c) 2026 Alex313031.

YEL='\033[1;33m' # Yellow
GRE='\033[1;32m' # Green

printf "\n" &&
printf "${GRE}Script to download all prerequisites to build Thorium...\n" &&
tput sgr0 &&

# Give user a chance to stop if they wish.
tput setaf 1 &&
read -p "This script requires git. Press Enter to continue, otherwise use Ctrl+C to stop and install it first."
tput sgr0 &&

printf "\n" &&
printf "${YEL}Installing depot_tools, cloning Thorium repo, and creating Chromium directories...\n" &&
tput sgr0 &&
sleep 1 &&

cd &&
# Clone repos.
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git &&
printf "\n" &&
git clone --recursive https://github.com/Alex313031/thorium.git &&

# Make Chromium dirs.
printf "\n" &&
mkdir -v ~/chromium &&
mkdir -v ~/chromium/src &&

# Alert user to .bashrc changes.
printf "\n" &&
printf "${YEL}Adding these lines to your .bashrc...\n" &&
tput sgr0 &&
printf "umask 022\n" &&
printf "PATH=\$PATH:\$HOME/depot_tools\n" &&

# Give user a chance to stop if they wish.
tput setaf 1 &&
read -p "Press Enter to continue, otherwise use Ctrl + C to stop."
tput sgr0 &&

cd &&
# Append lines to .bashrc.
echo 'umask 022' >> .bashrc &&

echo 'PATH="$PATH:$HOME/depot_tools"' >> .bashrc &&

printf "\n" &&
printf "${YEL}Running source ~/.bashrc..\n" &&
tput sgr0 &&

# Source .bashrc so changes take effect.
cd &&
source .bashrc &&

printf "\n" &&
printf "${YEL}Downloading Chromium source (This will take a while)...\n" &&
tput sgr0 &&
sleep 1 &&

# Use depot_tools fetch to download full Chromium source tree.
cd ~/chromium &&

fetch --nohooks chromium &&

printf "\n" &&
printf "${YEL}Running install-build-deps.sh to make sure prerequisites are installed...\n" &&
tput sgr0 &&

# Run script to install needed libraries.
cd ~/chromium/src &&
sudo dpkg --add-architecture i386 &&
sudo apt update &&

./build/install-build-deps.sh --arm --chromeos-fonts &&

printf "\n" &&
printf "${YEL}Running hooks...\n" &&
tput sgr0 &&

# Run hooks for Chromium.
cd ~/chromium/src &&
gclient runhooks &&

# Alert user to .gclient file changes.
printf "\n" &&
printf "${YEL}Appending target_os = [ 'linux' ] to .gclient file...\n" &&
tput sgr0 &&

cd ~/chromium &&
# Append line to chromium/.gclient file.
echo "target_os = [ 'linux' ]" >> .gclient &&

printf "\n" &&
printf "${YEL}Running set_exec.sh in ~/thorium...\n" &&
tput sgr0 &&

# Make set_exec.sh executable so it can make all other scripts executable.
cd ~/thorium &&
chmod +x set_exec.sh &&

# Run set_exec.sh.
./set_exec.sh &&

printf "\n" &&
printf "${YEL}Running trunk.sh in ~/thorium...\n" &&
tput sgr0 &&

# Run final trunk.sh to sync/rebase everything with tags and branches.
./trunk.sh &&

# Land user in ~/chromium/src.
cd ~/chromium/src

printf "${YEL}Done!\n" &&

printf "${GRE}Done! ${YEL}You can now run ./setup.sh or build vanilla Chromium.\n"
tput sgr0
