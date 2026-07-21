#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
swift build -c release
root="$(pwd)"
app="$root/build/Stargazing MyMac.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$root/.build/release/StargazingMyMacApp" "$app/Contents/MacOS/StargazingMyMacApp"
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>StargazingMyMacApp</string>
<key>CFBundleIdentifier</key><string>dev.stargazing.mymac</string>
<key>CFBundleName</key><string>Stargazing MyMac</string>
<key>CFBundleDisplayName</key><string>Stargazing MyMac</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSUIElement</key><true/>
<key>NSAppleEventsUsageDescription</key><string>Stargazing changes macOS light and dark appearance when you use its appearance toggle.</string>
</dict></plist>
PLIST
codesign --force --deep --sign - "$app"
printf '%s\n' "$app"
