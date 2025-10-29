#!/bin/bash

# Test script for Website Login Bot
# Tests the login worker and displays results

set -e

echo "🧪 Website Login Bot - Test Script"
echo ""

# Check if app is installed
if [ ! -d "/Applications/WebsiteLoginBot.app" ]; then
    echo "❌ Error: WebsiteLoginBot.app is not installed"
    echo "Please install the application first."
    exit 1
fi

# Check if LoginWorker exists
WORKER="/Applications/WebsiteLoginBot.app/Contents/MacOS/LoginWorker"
if [ ! -f "$WORKER" ]; then
    echo "❌ Error: LoginWorker not found in app bundle"
    exit 1
fi

echo "[1/3] Checking configuration..."

# Check if URL is configured
URL=$(defaults read com.websiteloginbot.app websiteURL 2>/dev/null || echo "")
if [ -z "$URL" ]; then
    echo "❌ Error: Website URL not configured"
    echo "Please configure the app from the menu bar first."
    exit 1
fi
echo "  ✓ URL configured: $URL"

# Check if credentials exist in Keychain
if ! security find-generic-password -s "com.websiteloginbot.credentials" -a "username" >/dev/null 2>&1; then
    echo "❌ Error: Credentials not found in Keychain"
    echo "Please configure credentials from the menu bar first."
    exit 1
fi
echo "  ✓ Credentials found in Keychain"

echo ""
echo "[2/3] Running login test..."
echo ""

# Create logs directory if needed
mkdir -p ~/Library/Logs/WebsiteLoginBot

# Run the worker with test flag
if "$WORKER" --test; then
    echo ""
    echo "✅ Login test SUCCEEDED"
    EXIT_CODE=0
else
    echo ""
    echo "❌ Login test FAILED"
    EXIT_CODE=1
fi

echo ""
echo "[3/3] Test results:"
echo ""

# Show last few log entries
if [ -f ~/Library/Logs/WebsiteLoginBot/worker.log ]; then
    echo "Last 10 log entries:"
    echo "-------------------"
    tail -n 10 ~/Library/Logs/WebsiteLoginBot/worker.log
    echo "-------------------"
else
    echo "No log file found."
fi

echo ""

if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Test completed successfully"
else
    echo "❌ Test failed - check logs for details"
    echo ""
    echo "Common issues:"
    echo "  - Incorrect URL"
    echo "  - Invalid credentials"
    echo "  - Network connectivity"
    echo "  - Website API changes"
    echo ""
    echo "View full logs: tail -f ~/Library/Logs/WebsiteLoginBot/worker.log"
fi

exit $EXIT_CODE
