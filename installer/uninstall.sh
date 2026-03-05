#!/bin/zsh

echo "Removing Mac Security Monitor..."

launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.fra.securitycheck.plist 2>/dev/null

rm ~/Library/LaunchAgents/com.fra.securitycheck.plist

rm -rf ~/.mac-security-monitor

sudo rm -f /usr/local/bin/security-monitor
sudo rm -f /usr/local/bin/security-monitor-update

echo "Removed."

