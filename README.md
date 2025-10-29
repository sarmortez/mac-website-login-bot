# macOS Website Login Bot

A macOS menu-bar application that automatically logs into a website every hour using launchd scheduling.

## ⚠️ Important Disclaimer

**This application is for educational purposes only.** Many websites prohibit automated logins in their Terms of Service. Before using this application, ensure you have permission to automate logins to your target website. The authors are not responsible for any misuse or violations of Terms of Service.

## Features

- 🔒 **Secure Credential Storage**: Credentials stored in macOS Keychain
- ⏰ **Automated Scheduling**: Uses launchd for reliable hourly login attempts
- 🔄 **Retry Logic**: Automatically retries failed logins every 15 minutes
- 📱 **Menu Bar Interface**: Lightweight menu-bar app with no dock icon
- 🚀 **Auto-Start**: Launches automatically at user login
- 🌐 **Network Aware**: Checks connectivity before attempting login

## Architecture

The application consists of three main components:

1. **WebsiteLoginBot.app** - Menu-bar UI application
2. **LoginWorker** - Command-line tool that performs the actual login
3. **LaunchAgent plists** - Schedule the login tasks via launchd

## Requirements

- macOS 11.0 (Big Sur) or later
- Xcode 13.0 or later
- Swift 5.5 or later

## Building the Application

### Option 1: Using Xcode

1. Open `WebsiteLoginBot.xcodeproj` in Xcode
2. Select the "WebsiteLoginBot" scheme
3. Build (⌘B) and Run (⌘R)

### Option 2: Using the Build Script

```bash
chmod +x build.sh
./build.sh
```

This will:
- Build both the app and the worker tool
- Create a `build` folder with the compiled applications
- Package everything ready for installation

## Installation

### Step 1: Install the Application

```bash
# After building
cp -R build/WebsiteLoginBot.app /Applications/
```

### Step 2: First Run Setup

1. Launch the app from `/Applications/WebsiteLoginBot.app`
2. Look for the icon in your menu bar (top-right corner)
3. Click the icon and select "Configure"
4. Enter:
   - Website URL (e.g., `https://example.com/login`)
   - Username
   - Password

Credentials are securely stored in your macOS Keychain.

### Step 3: Install LaunchAgents

The build script creates LaunchAgent plists in `build/LaunchAgents/`. Install them:

```bash
# Copy LaunchAgent files
cp build/LaunchAgents/com.websiteloginbot.hourly.plist ~/Library/LaunchAgents/
cp build/LaunchAgents/com.websiteloginbot.retry.plist ~/Library/LaunchAgents/

# Load the agents
launchctl load ~/Library/LaunchAgents/com.websiteloginbot.hourly.plist
launchctl load ~/Library/LaunchAgents/com.websiteloginbot.retry.plist
```

### Step 4: Enable Auto-Start at Login

The app will automatically register itself as a login item on first launch using the Service Management framework.

To manually verify:
1. Open System Preferences → Users & Groups → Login Items
2. Ensure "WebsiteLoginBot" is in the list

## How It Works

### Scheduling with launchd

The application uses two LaunchAgent configurations:

1. **Hourly Task** (`com.websiteloginbot.hourly.plist`)
   - Runs at the top of every hour (XX:00)
   - Uses `StartCalendarInterval` with `Minute = 0`
   - Triggers the login workflow

2. **Retry Task** (`com.websiteloginbot.retry.plist`)
   - Runs every 15 minutes (900 seconds)
   - Uses `StartInterval = 900`
   - Only attempts login if previous attempt failed

### Login Workflow

1. **Check Network**: Verify internet connectivity
2. **Retrieve Credentials**: Fetch from Keychain
3. **HTTP Login**: POST credentials to login endpoint
4. **Session Verification**: Call GET endpoint to verify session
5. **State Management**: Update success/failure state
6. **Retry Logic**: If failed, retry task picks up on next interval

## Configuration Files

### LaunchAgent Plists

Located in `LaunchAgents/`:

- `com.websiteloginbot.hourly.plist` - Hourly trigger
- `com.websiteloginbot.retry.plist` - Retry trigger

Edit these files to customize:
- Working directory
- Log file locations
- Timing intervals

### Info.plist Settings

Key settings in the app's `Info.plist`:

```xml
<key>LSUIElement</key>
<true/>
```

This hides the app from the Dock and keeps it menu-bar only.

## Usage

### Menu Bar Options

- **Status** - Shows last login status and next scheduled time
- **Configure** - Update credentials and URL
- **Test Login** - Manually trigger a login attempt
- **View Logs** - Open log file in Console.app
- **Quit** - Exit the application

### Command Line Testing

You can test the LoginWorker directly:

```bash
/Applications/WebsiteLoginBot.app/Contents/MacOS/LoginWorker --test
```

### Viewing Logs

Logs are written to:
- `~/Library/Logs/WebsiteLoginBot/hourly.log`
- `~/Library/Logs/WebsiteLoginBot/retry.log`
- `~/Library/Logs/WebsiteLoginBot/app.log`

View in real-time:
```bash
tail -f ~/Library/Logs/WebsiteLoginBot/hourly.log
```

## Uninstallation

### Step 1: Unload LaunchAgents

```bash
launchctl unload ~/Library/LaunchAgents/com.websiteloginbot.hourly.plist
launchctl unload ~/Library/LaunchAgents/com.websiteloginbot.retry.plist
rm ~/Library/LaunchAgents/com.websiteloginbot.hourly.plist
rm ~/Library/LaunchAgents/com.websiteloginbot.retry.plist
```

### Step 2: Remove Application

```bash
rm -rf /Applications/WebsiteLoginBot.app
```

### Step 3: Remove Credentials from Keychain

1. Open Keychain Access.app
2. Search for "WebsiteLoginBot"
3. Delete the keychain items

### Step 4: Remove Logs (Optional)

```bash
rm -rf ~/Library/Logs/WebsiteLoginBot
```

## Troubleshooting

### Application doesn't appear in menu bar

- Check Console.app for crash logs
- Ensure the app has accessibility permissions if needed
- Try running from Terminal to see error messages

### Login attempts failing

1. Check the website URL is correct
2. Verify credentials are valid
3. Check logs for HTTP response codes
4. Website may have changed their login endpoint
5. Website may be blocking automated requests

### LaunchAgent not triggering

```bash
# Check if agent is loaded
launchctl list | grep websiteloginbot

# Check system logs
log show --predicate 'subsystem == "com.apple.launchd"' --last 1h

# Reload the agent
launchctl unload ~/Library/LaunchAgents/com.websiteloginbot.hourly.plist
launchctl load ~/Library/LaunchAgents/com.websiteloginbot.hourly.plist
```

### "Operation not permitted" errors

Grant the app necessary permissions in System Preferences → Security & Privacy.

## Development

### Project Structure

```
WebsiteLoginBot/
├── WebsiteLoginBot/          # Main menu-bar app
│   ├── AppDelegate.swift     # App lifecycle and login item setup
│   ├── MenuBarController.swift # Menu bar UI
│   ├── NetworkManager.swift  # HTTP client and login logic
│   ├── KeychainManager.swift # Secure credential storage
│   └── Info.plist
├── LoginWorker/              # CLI tool for scheduled tasks
│   └── main.swift
├── LaunchAgents/             # launchd configuration
│   ├── com.websiteloginbot.hourly.plist
│   └── com.websiteloginbot.retry.plist
├── Tests/                    # Unit tests
└── build.sh                  # Build automation script
```

### Running Tests

```bash
xcodebuild test -scheme WebsiteLoginBot
```

### Code Organization

- **AppDelegate**: Handles app lifecycle, Service Management API
- **MenuBarController**: NSStatusItem management, menu UI
- **NetworkManager**: URLSession, connectivity checks, login flow
- **KeychainManager**: Keychain API wrapper for secure storage
- **LoginWorker**: Standalone CLI tool invoked by launchd

## Customization

### Changing Schedule Intervals

Edit the plist files before installation:

**For hourly (every 2 hours at XX:00):**
```xml
<key>StartCalendarInterval</key>
<array>
    <dict>
        <key>Minute</key>
        <integer>0</integer>
        <key>Hour</key>
        <integer>0</integer>
    </dict>
    <dict>
        <key>Minute</key>
        <integer>0</integer>
        <key>Hour</key>
        <integer>2</integer>
    </dict>
    <!-- etc -->
</array>
```

**For retry (every 10 minutes instead of 15):**
```xml
<key>StartInterval</key>
<integer>600</integer>
```

### Adapting to Different Websites

Edit `NetworkManager.swift` to customize:

1. **Login endpoint**: Change the URL path
2. **Request format**: Modify POST body (JSON vs form-encoded)
3. **Session verification**: Adjust the GET endpoint
4. **Success detection**: Parse response differently

## Security Considerations

- ✅ Credentials stored in Keychain (encrypted)
- ✅ No plain-text storage of passwords
- ✅ HTTPS recommended for all connections
- ⚠️ Ensure target website allows automated access
- ⚠️ Consider using API tokens instead of passwords where possible
- ⚠️ Logs may contain sensitive data - review log output

## Known Limitations

1. **Single Website**: App currently supports one website at a time
2. **Simple Auth**: Designed for basic username/password login
3. **No 2FA**: Two-factor authentication not supported
4. **No CAPTCHA**: Cannot handle CAPTCHA challenges
5. **Session Duration**: Assumes website maintains session state

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes with tests
4. Submit a pull request

## License

MIT License - see LICENSE file for details

## References

- [launchd.info](https://www.launchd.info/) - launchd and LaunchAgent documentation
- [Apple Service Management](https://developer.apple.com/documentation/servicemanagement) - Login item API
- [Sarun W. - Menu Bar Apps](https://sarunw.com/) - Menu-bar app development
- [Keychain Services](https://developer.apple.com/documentation/security/keychain_services) - Secure credential storage

## Support

For issues, questions, or contributions, please open an issue on GitHub.

---

**Remember**: Always respect website Terms of Service and use automation responsibly. 🙏