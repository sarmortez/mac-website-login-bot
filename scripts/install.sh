#!/bin/bash

# Installation script for Website Login Bot
# Automates the complete installation process

set -e

echo "🚀 Website Login Bot Installer"
echo ""

# Check if build exists
if [ ! -d "build/WebsiteLoginBot.app" ]; then
    echo "❌ Error: build/WebsiteLoginBot.app not found"
    echo "Please run ./build.sh first"
    exit 1
fi

echo "[1/4] Installing application..."

# Check if we need sudo
if [ -w "/Applications" ]; then
    cp -R build/WebsiteLoginBot.app /Applications/
else
    echo "  Need administrator access..."
    sudo cp -R build/WebsiteLoginBot.app /Applications/
    sudo chmod -R 755 /Applications/WebsiteLoginBot.app
fi

echo "  ✓ Application installed to /Applications"

echo "[2/4] Installing LaunchAgents..."

# Create LaunchAgents directory
mkdir -p ~/Library/LaunchAgents

# Copy plist files
cp build/LaunchAgents/com.websiteloginbot.hourly.plist ~/Library/LaunchAgents/
cp build/LaunchAgents/com.websiteloginbot.retry.plist ~/Library/LaunchAgents/

echo "  ✓ LaunchAgent files copied"

echo "[3/4] Loading LaunchAgents..."

# Load the agents
launchctl load ~/Library/LaunchAgents/com.websiteloginbot.hourly.plist 2>/dev/null || true
launchctl load ~/Library/LaunchAgents/com.websiteloginbot.retry.plist 2>/dev/null || true

echo "  ✓ LaunchAgents loaded"

echo "[4/4] Creating log directory..."

mkdir -p ~/Library/Logs/WebsiteLoginBot

echo "  ✓ Log directory created"

echo ""
echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Launch the app: open /Applications/WebsiteLoginBot.app"
echo "  2. Look for the globe icon in your menu bar"
echo "  3. Click the icon and select 'Configure'"
echo "  4. Enter your website URL and credentials"
echo "  5. Test login with 'Test Login Now'"
echo ""
echo "The app will now:"
echo "  • Run automatically at login"
echo "  • Attempt login every hour at XX:00"
echo "  • Retry failed logins every 15 minutes"
echo ""
echo "View logs: tail -f ~/Library/Logs/WebsiteLoginBot/*.log"
echo ""

# Ask if user wants to launch now
read -p "Launch the app now? (Y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    open /Applications/WebsiteLoginBot.app
    echo "App launched! Look for the icon in your menu bar."
fi
