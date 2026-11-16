#!/usr/bin/env bash
# Builds the downloads in assets/downloads. For each app: a Windows .exe (windows/), a zipped macOS app (macos/) and
# a Linux script (linux/). Each runs the app's own installer, the same command as its README, shows what the
# installer says in a window of its own as it says it, and pops up when it is done. Needs Go and Python 3.
set -euo pipefail
cd "$(dirname "$0")"
OUT=../assets/downloads
mkdir -p "$OUT"
WINRES="${GOWINRES:-go run github.com/tc-hib/go-winres@v0.3.3}"

# app ^ icon ^ Windows command ^ macOS and Linux command (split on ^: the commands have pipes in them)
APPS=(
  "Flash^flash^irm https://raw.githubusercontent.com/Natuworkguy/Flash/main/install.ps1 | iex^curl -fsSL https://raw.githubusercontent.com/Natuworkguy/Flash/main/install.sh | bash"
  # Riptide's releases branch has no installer yet: its downloads install the dev version
  "Riptide^riptide^& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Natuworkguy/Riptide/dev/install.ps1))) -Dev^curl -fsSL https://raw.githubusercontent.com/Natuworkguy/Riptide/dev/install.sh | bash -s -- --dev"
)

for row in "${APPS[@]}"; do
  IFS='^' read -r APP ICON WIN UNIX <<< "$row"
  lower=$(echo "$APP" | tr '[:upper:]' '[:lower:]')
  case "$UNIX$WIN" in *"'"*) echo "a command has a single quote in it: the scripts quote them with single quotes" >&2; exit 1 ;; esac

  # Windows: no console, its own window (Windows Forms), the app's icon and details
  ( cd windows && rm -f rsrc_windows_*.syso
    $WINRES simply --arch amd64 --icon "../icons/$ICON.ico" --manifest gui \
      --product-name "$APP" --file-description "Installs $APP" --original-filename "$lower-setup.exe" \
      --copyright "XN Software, open source" --file-version 1.0.0.0 --product-version 1.0.0.0 )
  GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -trimpath \
    -ldflags "-s -w -H windowsgui -X 'main.app=$APP' -X 'main.command=$WIN'" -o "$OUT/$lower-setup.exe" ./windows
  rm -f windows/rsrc_windows_*.syso

  # Linux: the script, with the app filled in
  python3 - "$APP" "$UNIX" "install-$lower.sh" linux/install.sh "$OUT/install-$lower.sh" <<'PY'
import sys
app, cmd, name, src, out = sys.argv[1:]
open(out, 'w').write(open(src).read().replace('@APP@', app).replace('@COMMAND@', cmd).replace('@FILE@', name))
PY
  chmod +x "$OUT/install-$lower.sh"

  # macOS: "Install <App>.app", zipped so it keeps its permissions
  python3 - "$APP" "$ICON" "$UNIX" "$OUT/install-$lower-macos.zip" <<'PY'
import sys, zipfile, time
app, icon, cmd, out = sys.argv[1:]
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
  <key>CFBundleShortVersionString</key><string>1.1</string>
  <key>CFBundleVersion</key><string>2</string>
  <key>LSMinimumSystemVersion</key><string>11.0</string>
</dict></plist>
'''
launcher = open('macos/install').read().replace('@APP@', app).replace('@COMMAND@', cmd)
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
done
ls -la "$OUT"
