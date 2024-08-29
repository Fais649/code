#!/bin/bash

if [ ! -d $HOME/.platformio/platforms/espressif32/boards/ ]; then
	echo "Platformio project not initialized..."
	echo "Initializing Platformio..."
	platformio project init --ide vim
fi

cp ./DfRobotResources/platformio/boards/* $HOME/.platformio/platforms/espressif32/boards/
