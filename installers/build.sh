#!/usr/bin/env bash
# Builds the downloads. For each app: a Windows .exe (windows/), a zipped macOS app (macos/) and a Linux script
# (linux/). Each asks first, with a box to tick for the dev version where the app has one, runs the app's own
# installer (the same command as its README), shows what it says in a window of its own as it says it, and pops up
# when it is done. Riptide's go in this site's assets/downloads; Flash's in flashproject.dev's (the Flash-Site
# repository, checked out beside this one, or wherever FLASH_SITE says). Needs Go and Python 3.
set -euo pipefail
cd "$(dirname "$0")"
FLASH_SITE="${FLASH_SITE:-../../flash-site}"
WINRES="${GOWINRES:-go run github.com/tc-hib/go-winres@v0.3.3}"

# app ^ icon ^ where ^ Windows command ^ macOS and Linux command ^ and the same two for the dev version
# (split on ^: the commands have pipes in them). The dev installers come from the dev branch, which knows --dev.
APPS=(
  "Flash^flash^$FLASH_SITE/assets/downloads^irm https://flashproject.dev/install.ps1 | iex^curl -fsSL https://flashproject.dev/install.sh | bash^& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Natuworkguy/Flash/dev/install.ps1))) -Dev^curl -fsSL https://raw.githubusercontent.com/Natuworkguy/Flash/dev/install.sh | bash -s -- --dev"
  # Riptide's releases branch has no installer yet: its downloads install the dev version, with nothing to choose
  "Riptide^riptide^../assets/downloads^& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Natuworkguy/Riptide/dev/install.ps1))) -Dev^curl -fsSL https://raw.githubusercontent.com/Natuworkguy/Riptide/dev/install.sh | bash -s -- --dev^^"
)

for row in "${APPS[@]}"; do
  IFS='^' read -r APP ICON OUT WIN UNIX DEVWIN DEVUNIX <<< "$row"
  lower=$(echo "$APP" | tr '[:upper:]' '[:lower:]')
  mkdir -p "$OUT"
  case "$UNIX$WIN$DEVUNIX$DEVWIN" in *"'"*) echo "a command has a single quote in it: the scripts quote them with single quotes" >&2; exit 1 ;; esac

  # Windows: no console, its own window (Windows Forms), the app's icon and details
  ( cd windows && rm -f rsrc_windows_*.syso
    $WINRES simply --arch amd64 --icon "../icons/$ICON.ico" --manifest gui \
      --product-name "$APP" --file-description "Installs $APP" --original-filename "$lower-setup.exe" \
      --copyright "XN Software, open source" --file-version 1.0.0.0 --product-version 1.0.0.0 )
  GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -trimpath \
    -ldflags "-s -w -H windowsgui -X 'main.app=$APP' -X 'main.command=$WIN' -X 'main.devCommand=$DEVWIN'" -o "$OUT/$lower-setup.exe" ./windows
  rm -f windows/rsrc_windows_*.syso

  # Linux: the script, with the app filled in
  python3 - "$APP" "$UNIX" "$DEVUNIX" "install-$lower.sh" linux/install.sh "$OUT/install-$lower.sh" <<'PY'
import sys
app, cmd, dev, name, src, out = sys.argv[1:]
open(out, 'w').write(open(src).read().replace('@APP@', app).replace('@DEVCOMMAND@', dev).replace('@COMMAND@', cmd).replace('@FILE@', name))
PY
  chmod +x "$OUT/install-$lower.sh"

  # macOS: "Install <App>.app", zipped so it keeps its permissions
  python3 - "$APP" "$ICON" "$UNIX" "$DEVUNIX" "$OUT/install-$lower-macos.zip" <<'PY'
import sys, zipfile, time
app, icon, cmd, dev, out = sys.argv[1:]
top = f'Install {app}.app/'; root = top + 'Contents/'
plist = f'''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Install {app}</string>
  <key>CFBundleDisplayName</key><string>Install {app}</string>
  <key>CFBundleIdentifier</key><string>software.xn.install-{app.lower()}</string>
  <key>CFBundleExecutable</key><string>install</string>
  <key>CFBundleIconFile</key><string>icon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.2</string>
  <key>CFBundleVersion</key><string>3</string>
  <key>LSMinimumSystemVersion</key><string>11.0</string>
</dict></plist>
'''
launcher = open('macos/install').read().replace('@APP@', app).replace('@DEVCOMMAND@', dev).replace('@COMMAND@', cmd)
def add(z, name, data, mode):
    info = zipfile.ZipInfo(name, time.localtime()[:6]); info.create_system = 3
    info.external_attr = (mode << 16) | (0x10 if name.endswith('/') else 0); info.compress_type = zipfile.ZIP_DEFLATED
    z.writestr(info, data)
with zipfile.ZipFile(out, 'w') as z:
    for d in (top, root, root + 'MacOS/', root + 'Resources/'): add(z, d, b'', 0o40755)
    add(z, root + 'Info.plist', plist.encode(), 0o100644)
    add(z, root + 'MacOS/install', launcher.encode(), 0o100755)
    add(z, root + 'Resources/window.js', open('macos/window.js', 'rb').read(), 0o100644)
    add(z, root + 'Resources/icon.icns', open(f'icons/{icon}.icns', 'rb').read(), 0o100644)
PY
  ls -la "$OUT" | grep -i "$lower"
done
