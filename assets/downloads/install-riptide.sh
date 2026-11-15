#!/usr/bin/env bash
# Installs Riptide: runs its installer, the same command as its README. Run it with: bash install-riptide.sh
set -e
echo "Installing Riptide."
curl -fsSL https://raw.githubusercontent.com/Natuworkguy/Riptide/dev/install.sh | bash -s -- --dev
