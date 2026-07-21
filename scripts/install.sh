#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
scripts/build-app.sh >/dev/null
app="$(pwd)/build/Stargazing MyMac.app"
mkdir -p "$HOME/Applications" "$HOME/.local/bin" "$HOME/Library/LaunchAgents"
rm -rf "$HOME/Applications/Stargazing MyMac.app"
cp -R "$app" "$HOME/Applications/Stargazing MyMac.app"
cp .build/release/stargazing-mymac "$HOME/.local/bin/stargazing-mymac"
cat > "$HOME/Library/LaunchAgents/dev.stargazing.mymac.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Label</key><string>dev.stargazing.mymac</string>
<key>ProgramArguments</key><array><string>$HOME/Applications/Stargazing MyMac.app/Contents/MacOS/StargazingMyMacApp</string></array>
<key>RunAtLoad</key><true/>
<key>ProcessType</key><string>Interactive</string>
</dict></plist>
PLIST
domain="gui/$(id -u)"
service="$domain/dev.stargazing.mymac"
if launchctl print "$service" >/dev/null 2>&1; then
    launchctl kickstart -k "$service"
else
    launchctl bootstrap "$domain" "$HOME/Library/LaunchAgents/dev.stargazing.mymac.plist"
fi
printf 'Installed Stargazing MyMac and enabled launch at login.\n'
