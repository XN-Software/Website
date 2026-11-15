#!/usr/bin/env bash
# Installs Flash: runs its installer, the same command as its README. Run it with: bash install-flash.sh
set -e
echo "Installing Flash."
curl -fsSL https://raw.githubusercontent.com/Natuworkguy/Flash/main/install.sh | bash
