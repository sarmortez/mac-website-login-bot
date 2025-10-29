# Quick Start Guide

Get up and running with Website Login Bot in 5 minutes.

## Installation

### Option 1: Automated Install (Recommended)

```bash
# Clone the repository
git clone https://github.com/sarmortez/mac-website-login-bot.git
cd mac-website-login-bot

# Build and install
chmod +x build.sh scripts/install.sh
./build.sh
sudo ./scripts/install.sh
```

### Option 2: Using Make

```bash
# Clone the repository
git clone https://github.com/sarmortez/mac-website-login-bot.git
cd mac-website-login-bot

# Build and install in one command
make install
```

### Option 3: Manual Install

```bash
# Build
chmod +x build.sh
./build.sh

# Install app
sudo cp -R build/WebsiteLoginBot.app /Applications/

# Install LaunchAgents
cp build/LaunchAgents/*.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.websiteloginbot.hourly.plist
launchctl load ~/Library/LaunchAgents/com.websiteloginbot.retry.plist

# Launch
open /Applications/WebsiteLoginBot.app
```

## Configuration

1. **Launch the app** - Look for the globe icon (🌐) in your menu bar

2. **Click the icon** and select **"Configure..."**

3. **Enter your details**:
   - Website URL: `https://example.com/login`
   - Username: your username
   - Password: your password

4. **Click "Save"** - Credentials are stored securely in Keychain

## Testing

### Test from Menu Bar

1. Click the menu bar icon
2. Select **"Test Login Now"**
3. Watch for a notification with the result

### Test from Command Line

```bash
# Quick test
chmod +x scripts/test-login.sh
./scripts/test-login.sh

# Or run the worker directly
/Applications/WebsiteLoginBot.app/Contents/MacOS/LoginWorker --test
```

## Verification

### Check LaunchAgents

```bash
launchctl list | grep websiteloginbot
```

You should see:
- `com.websiteloginbot.hourly`
- `com.websiteloginbot.retry`

### Check Logs

```bash
# View all logs
tail -f ~/Library/Logs/WebsiteLoginBot/*.log

# Or use Make
make logs
```

### Check Login Item

1. Open **System Preferences** → **Users & Groups**
2. Click **Login Items** tab
3. Verify **WebsiteLoginBot** is in the list

## Usage

Once configured, the app will:

- ✅ Run automatically at login
- ✅ Attempt login every hour (at XX:00)
- ✅ Retry failed logins every 15 minutes
- ✅ Show status in menu bar

### Menu Options

- **Status** - View last login status
- **Configure** - Update credentials
- **Test Login Now** - Manual test
- **View Logs** - Open log directory
- **Quit** - Exit application

## Troubleshooting

### App not in menu bar?

```bash
# Check if running
ps aux | grep WebsiteLoginBot

# Try launching from Terminal
/Applications/WebsiteLoginBot.app/Contents/MacOS/WebsiteLoginBot
```

### Login failing?

```bash
# Check logs
tail -50 ~/Library/Logs/WebsiteLoginBot/network.log

# Test manually
chmod +x scripts/test-login.sh
./scripts/test-login.sh
```

### LaunchAgent not running?

```bash
# Check status
make status

# Reload agents
launchctl unload ~/Library/LaunchAgents/com.websiteloginbot.*.plist
launchctl load ~/Library/LaunchAgents/com.websiteloginbot.*.plist
```

## Uninstallation

### Automated Uninstall

```bash
chmod +x scripts/uninstall.sh
sudo ./scripts/uninstall.sh
```

### Or using Make

```bash
make uninstall
```

### Manual Uninstall

```bash
# Stop LaunchAgents
launchctl unload ~/Library/LaunchAgents/com.websiteloginbot.*.plist
rm ~/Library/LaunchAgents/com.websiteloginbot.*.plist

# Remove app
sudo rm -rf /Applications/WebsiteLoginBot.app

# Remove logs (optional)
rm -rf ~/Library/Logs/WebsiteLoginBot
```

Then delete credentials from **Keychain Access.app**.

## Customization

### Change Schedule

Edit `~/Library/LaunchAgents/com.websiteloginbot.hourly.plist`:

```xml
<!-- Run at 9 AM and 5 PM daily -->
<key>StartCalendarInterval</key>
<array>
    <dict>
        <key>Hour</key>
        <integer>9</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <dict>
        <key>Hour</key>
        <integer>17</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
</array>
```

Reload: `launchctl unload/load [plist]`

### Adapt to Your Website

Edit `WebsiteLoginBot/NetworkManager.swift` to customize:

1. Login endpoint URL
2. Request format (JSON vs form data)
3. Success detection logic
4. Session verification endpoint

Then rebuild: `./build.sh`

## Common Issues

| Issue | Solution |
|-------|----------|
| No menu bar icon | Check if LSUIElement=true in Info.plist |
| Permission denied | Run with sudo for /Applications |
| Login fails | Verify URL and credentials |
| Not auto-starting | Check Login Items in System Preferences |
| LaunchAgent not triggering | Check launchctl list |

## Next Steps

- Read [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed instructions
- Read [ARCHITECTURE.md](ARCHITECTURE.md) to understand the design
- Read [CONTRIBUTING.md](CONTRIBUTING.md) to contribute

## Support

- **Issues**: https://github.com/sarmortez/mac-website-login-bot/issues
- **Logs**: `~/Library/Logs/WebsiteLoginBot/`
- **Status**: `make status`

## Important Reminders

⚠️ **Always verify you have permission to automate logins to the target website.**

⚠️ **This tool is for educational purposes. Many websites prohibit automated access.**

⚠️ **Use at your own risk and respect Terms of Service.**

---

Happy automating! 🚀
