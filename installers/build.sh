#!/usr/bin/env bash
# Builds the downloads in assets/downloads: for each app, a Windows .exe (installer.go, with the app's icon), a macOS
# app that opens Terminal and runs the installer (zipped, so it keeps its permissions), and a Linux shell script.
# Each runs the same install command as the app's README. Needs Go and Python 3 (with Pillow only for new icons).
set -euo pipefail
cd "$(dirname "$0")"
OUT=../assets/downloads
mkdir -p "$OUT"
WINRES="${GOWINRES:-go run github.com/tc-hib/go-winres@v0.3.3}"

# app ^ icon base ^ Windows command ^ macOS and Linux command (split on ^: the commands have pipes in them)
APPS=(
  "Flash^flash^irm https://raw.githubusercontent.com/Natuworkguy/Flash/main/install.ps1 | iex^curl -fsSL https://raw.githubusercontent.com/Natuworkguy/Flash/main/install.sh | bash"
  # Riptide's releases branch has no installer yet: its downloads install the dev version
  "Riptide^riptide^& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Natuworkguy/Riptide/dev/install.ps1))) -Dev^curl -fsSL https://raw.githubusercontent.com/Natuworkguy/Riptide/dev/install.sh | bash -s -- --dev"
)

for row in "${APPS[@]}"; do
  IFS='^' read -r APP ICON WIN UNIX <<< "$row"
  lower=$(echo "$APP" | tr '[:upper:]' '[:lower:]')

  # Windows: the program, its icon and version details, as a console window
  rm -f rsrc_windows_*.syso
  $WINRES simply --arch amd64 --icon "icons/$ICON.ico" --manifest cli \
    --product-name "$APP" --file-description "Installs $APP" --original-filename "$lower-setup.exe" \
    --copyright "XN Software, open source" --file-version 1.0.0.0 --product-version 1.0.0.0
  GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -trimpath \
    -ldflags "-s -w -X 'main.app=$APP' -X 'main.command=$WIN'" -o "$OUT/$lower-setup.exe" .
  rm -f rsrc_windows_*.syso

  # Linux: a script to run with bash
  cat > "$OUT/install-$lower.sh" <<SH
#!/usr/bin/env bash
# Installs $APP: runs its installer, the same command as its README. Run it with: bash install-$lower.sh
set -e
echo "Installing $APP."
$UNIX
SH
  chmod +x "$OUT/install-$lower.sh"

  # macOS: "Install <App>.app", which opens Terminal and runs the installer there, so you see it work
  python3 - "$APP" "$ICON" "$UNIX" "$OUT/install-$lower-macos.zip" <<'PY'
import sys, zipfile, time
app, icon, cmd, out = sys.argv[1:]
root = f'Install {app}.app/Contents/'
plist = f'''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Install {app}</string>
  <key>CFBundleDisplayName</key><string>Install {app}</string>
  <key>CFBundleIdentifier</key><string>software.xn.install-{app.lower()}</string>
  <key>CFBundleExecutable</key><string>install</string>
  <key>CFBundleIconFile</key><string>icon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>11.0</string>
</dict></plist>
'''
esc = cmd.replace('\\', '\\\\').replace('"', '\\"')
script = f'''#!/bin/bash
# Opens Terminal and runs {app}'s installer there.
osascript <<OSA
tell application "Terminal"
  activate
  do script "echo 'Installing {app}.'; {esc}"
end tell
OSA
'''
def add(z, name, data, mode):
    info = zipfile.ZipInfo(name, time.localtime()[:6]); info.create_system = 3
    info.external_attr = (mode << 16) | (0x10 if name.endswith('/') else 0); info.compress_type = zipfile.ZIP_DEFLATED
    z.writestr(info, data)
with zipfile.ZipFile(out, 'w') as z:
    for d in ['', 'MacOS/', 'Resources/']: add(z, (f'Install {app}.app/' if not d else root + d) if d else f'Install {app}.app/', b'', 0o40755)
    add(z, root, b'', 0o40755)
    add(z, root + 'Info.plist', plist.encode(), 0o100644)
    add(z, root + 'MacOS/install', script.encode(), 0o100755)
    add(z, root + 'Resources/icon.icns', open(f'icons/{icon}.icns', 'rb').read(), 0o100644)
PY
done
ls -la "$OUT"
