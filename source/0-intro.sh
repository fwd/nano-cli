#!/bin/bash

#################################
## XNO: Nano Command Line Tool ##
## (c) 2018 - 3001 @nano2dev   ##
## Released under MIT License  ##
#################################

VERSION="Alpha-0.1.0"
GREEN=$'\e[0;32m'
BLUE=$'\e[0;34m'
CYAN=$'\e[1;36m'
RED=$'\e[0;31m'
NC=$'\e[0m'
GREEN2=$'\e[1;92m'
DIR=$(eval echo "~$different_user")

# Project Folder
mkdir -p $DIR/.xno

# Install '7z' if needed.
# if ! command -v 7z &> /dev/null; then
# 	if [  -n "$(uname -a | grep Ubuntu)" ]; then
# 		sudo apt install 7z -y
# 	else
# 		echo "${CYAN}Cloud${NC}: We could not auto install '7z'. Please install it manually, before continuing."
# 		exit 0
# 	fi
# fi

if ! command -v jq &> /dev/null; then
	if [  -n "$(uname -a | grep Ubuntu)" ]; then
		sudo apt install jq -y
	else
		echo "${CYAN}Error${NC}: Could not auto install 'jq'. Please install it manually, before continuing."
		exit 0
	fi
fi

# Install 'curl' if needed.
if ! command -v curl &> /dev/null; then
	# Really?! What kind of rinky-dink machine is this?
	if [  -n "$(uname -a | grep Ubuntu)" ]; then
		sudo apt install curl -y
	else
		echo "${CYAN}Error${NC}: Could not auto install 'curl'. Please install it manually, before continuing."
		exit 0
	fi
fi
