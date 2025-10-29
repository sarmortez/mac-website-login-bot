# Makefile for Website Login Bot
# Provides convenient commands for building, installing, and managing the application

.PHONY: help build clean install uninstall test logs

# Default target
help:
	@echo "Website Login Bot - Available Commands:"
	@echo ""
	@echo "  make build      - Build the application"
	@echo "  make clean      - Clean build artifacts"
	@echo "  make install    - Install the application"
	@echo "  make uninstall  - Uninstall the application"
	@echo "  make test       - Run unit tests"
	@echo "  make logs       - View application logs"
	@echo "  make status     - Check LaunchAgent status"
	@echo ""

# Build the application
build:
	@echo "🚀 Building Website Login Bot..."
	@chmod +x build.sh
	@./build.sh

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf build/
	@rm -rf .build/
	@xcodebuild clean -project WebsiteLoginBot.xcodeproj -scheme WebsiteLoginBot 2>/dev/null || true
	@xcodebuild clean -project WebsiteLoginBot.xcodeproj -scheme LoginWorker 2>/dev/null || true
	@echo "✅ Clean complete"

# Install the application
install: build
	@echo "📦 Installing Website Login Bot..."
	@sudo cp -R build/WebsiteLoginBot.app /Applications/
	@sudo chmod -R 755 /Applications/WebsiteLoginBot.app
	@mkdir -p ~/Library/LaunchAgents
	@cp build/LaunchAgents/com.websiteloginbot.hourly.plist ~/Library/LaunchAgents/
	@cp build/LaunchAgents/com.websiteloginbot.retry.plist ~/Library/LaunchAgents/
	@launchctl load ~/Library/LaunchAgents/com.websiteloginbot.hourly.plist 2>/dev/null || true
	@launchctl load ~/Library/LaunchAgents/com.websiteloginbot.retry.plist 2>/dev/null || true
	@echo "✅ Installation complete"
	@echo ""
	@echo "To complete setup:"
	@echo "  1. Launch: open /Applications/WebsiteLoginBot.app"
	@echo "  2. Configure credentials from menu bar icon"

# Uninstall the application
uninstall:
	@echo "🗑️  Uninstalling Website Login Bot..."
	@launchctl unload ~/Library/LaunchAgents/com.websiteloginbot.hourly.plist 2>/dev/null || true
	@launchctl unload ~/Library/LaunchAgents/com.websiteloginbot.retry.plist 2>/dev/null || true
	@rm -f ~/Library/LaunchAgents/com.websiteloginbot.hourly.plist
	@rm -f ~/Library/LaunchAgents/com.websiteloginbot.retry.plist
	@sudo rm -rf /Applications/WebsiteLoginBot.app
	@echo "✅ Uninstallation complete"
	@echo ""
	@echo "Note: Credentials remain in Keychain"
	@echo "To remove: Open Keychain Access.app and search for 'WebsiteLoginBot'"

# Run tests
test:
	@echo "⚙️  Running tests..."
	@xcodebuild test -project WebsiteLoginBot.xcodeproj -scheme WebsiteLoginBot

# View logs
logs:
	@echo "📜 Viewing logs (Ctrl+C to exit)..."
	@tail -f ~/Library/Logs/WebsiteLoginBot/*.log

# Check LaunchAgent status
status:
	@echo "🔍 Checking LaunchAgent status..."
	@echo ""
	@echo "Loaded agents:"
	@launchctl list | grep websiteloginbot || echo "  No agents loaded"
	@echo ""
	@echo "LaunchAgent files:"
	@ls -la ~/Library/LaunchAgents/com.websiteloginbot.*.plist 2>/dev/null || echo "  No plist files found"
	@echo ""
	@echo "Application:"
	@ls -la /Applications/WebsiteLoginBot.app 2>/dev/null || echo "  Not installed"
