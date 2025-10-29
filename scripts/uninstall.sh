#!/bin/bash

# Uninstall script for Website Login Bot
# This script removes the application, LaunchAgents, and optionally logs and credentials

set -e

echo "🗑️  Website Login Bot Uninstaller"
echo ""

# Check if running with sudo (needed for /Applications)
if [ "$EUID" -ne 0 ]; then 
    echo "This script needs sudo access to remove the application."
    echo "Please run: sudo $0"
    exit 1
fi

# Get the actual user (when run with sudo)
ACTUAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(eval echo ~$ACTUAL_USER)

echo "Uninstalling for user: $ACTUAL_USER"
echo ""

# Function to safely run commands as the actual user
run_as_user() {
    sudo -u "$ACTUAL_USER" "$@"
}

# 1. Stop and unload LaunchAgents
echo "[1/5] Stopping LaunchAgents..."
run_as_user launchctl unload "$USER_HOME/Library/LaunchAgents/com.websiteloginbot.hourly.plist" 2>/dev/null || true
run_as_user launchctl unload "$USER_HOME/Library/LaunchAgents/com.websiteloginbot.retry.plist" 2>/dev/null || true
echo "  ✓ LaunchAgents stopped"

# 2. Remove LaunchAgent files
echo "[2/5] Removing LaunchAgent files..."
rm -f "$USER_HOME/Library/LaunchAgents/com.websiteloginbot.hourly.plist"
rm -f "$USER_HOME/Library/LaunchAgents/com.websiteloginbot.retry.plist"
echo "  ✓ LaunchAgent files removed"

# 3. Quit the application if running
echo "[3/5] Quitting application..."
run_as_user osascript -e 'quit app "WebsiteLoginBot"' 2>/dev/null || true
sleep 1
# Force quit if still running
pkill -u "$ACTUAL_USER" WebsiteLoginBot 2>/dev/null || true
echo "  ✓ Application quit"

# 4. Remove application
echo "[4/5] Removing application..."
rm -rf /Applications/WebsiteLoginBot.app
echo "  ✓ Application removed"

# 5. Remove preferences
echo "[5/5] Removing preferences..."
rm -f "$USER_HOME/Library/Preferences/com.websiteloginbot.app.plist"
run_as_user defaults delete com.websiteloginbot.app 2>/dev/null || true
echo "  ✓ Preferences removed"

echo ""
echo "✅ Uninstallation complete!"
echo ""

# Ask about logs
read -p "Remove log files? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$USER_HOME/Library/Logs/WebsiteLoginBot"
    echo "  ✓ Log files removed"
else
    echo "  Logs kept at: $USER_HOME/Library/Logs/WebsiteLoginBot"
fi

echo ""

# Inform about Keychain
echo "⚠️  Note: Credentials remain in Keychain"
echo "To remove credentials:"
echo "  1. Open Keychain Access.app"
echo "  2. Search for: WebsiteLoginBot"
echo "  3. Delete the keychain items"
echo ""
echo "Or run: security delete-generic-password -s com.websiteloginbot.credentials"
echo ""

echo "Thank you for using Website Login Bot!"
