#!/bin/bash

# OpenAI Model Installer Launcher
# This script ensures we get the latest version bypassing any cache

echo "Downloading latest installer..."
TIMESTAMP=$(date +%s)
curl -fsSL "https://raw.githubusercontent.com/gmoyle/OpenWebUI-Model-Installer/main/install-OpenAI-MacOS.sh?v=${TIMESTAMP}" -o /tmp/install-OpenAI-MacOS.sh

if [ -f /tmp/install-OpenAI-MacOS.sh ]; then
    chmod +x /tmp/install-OpenAI-MacOS.sh
    /tmp/install-OpenAI-MacOS.sh
    rm -f /tmp/install-OpenAI-MacOS.sh
else
    echo "Failed to download installer"
    exit 1
fi
