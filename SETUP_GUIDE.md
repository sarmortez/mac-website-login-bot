# Setup Guide for Website Login Bot

This guide will walk you through building, installing, and configuring the Website Login Bot application.

## Prerequisites

- macOS 11.0 (Big Sur) or later
- Xcode 13.0 or later installed
- Xcode Command Line Tools installed:
  ```bash
  xcode-select --install
  ```
- Administrator access to install the application

## Step 1: Clone the Repository

```bash
git clone https://github.com/sarmortez/mac-website-login-bot.git
cd mac-website-login-bot
```

## Step 2: Build the Application

### Option A: Using the Build Script (Recommended)

```bash
chmod +x build.sh
./build.sh
```

The script will:
- Compile both the menu-bar app and worker tool
- Package them together
- Prepare LaunchAgent configurations
- Create a `build/` directory with everything ready

### Option B: Using Xcode

1. Open `WebsiteLoginBot.xcodeproj` in Xcode
2. Select "WebsiteLoginBot" scheme
3. Product → Build (⌘B)
4. Select "LoginWorker" scheme
5. Product → Build (⌘B)

## Step 3: Install the Application

```bash
# Copy the app to Applications folder
sudo cp -R build/WebsiteLoginBot.app /Applications/

# Set proper permissions
sudo chmod -R 755 /Applications/WebsiteLoginBot.app
```

## Step 4: Configure the Application

1. Launch the application:
   ```bash
   open /Applications/WebsiteLoginBot.app
   ```

2. Look for the globe icon (🌐) in your menu bar (top-right)

3. Click the icon and select **"Configure..."**

4. Enter the required information:
   - **Website URL**: The full URL of the login page (e.g., `https://example.com/login`)
   - **Username**: Your account username
   - **Password**: Your account password

5. Click **"Save"**

Your credentials are now securely stored in the macOS Keychain.

## Step 5: Install LaunchAgents

The LaunchAgents are responsible for scheduling the automatic login attempts.

```bash
# Create LaunchAgents directory if it doesn't exist
mkdir -p ~/Library/LaunchAgents

# Copy the LaunchAgent files
cp build/LaunchAgents/com.websiteloginbot.hourly.plist ~/Library/LaunchAgents/
cp build/LaunchAgents/com.websiteloginbot.retry.plist ~/Library/LaunchAgents/

# Load the agents
launchctl load ~/Library/LaunchAgents/com.websiteloginbot.hourly.plist
launchctl load ~/Library/LaunchAgents/com.websiteloginbot.retry.plist
```

### Verify LaunchAgents are Loaded

```bash
launchctl list | grep websiteloginbot
```

You should see two entries:
- `com.websiteloginbot.hourly`
- `com.websiteloginbot.retry`

## Step 6: Verify Auto-Start at Login

The application automatically registers itself as a login item on first launch.

To verify:
1. Open **System Preferences** → **Users & Groups**
2. Click on your user account
3. Select the **Login Items** tab
4. Look for **WebsiteLoginBot** in the list

If it's not there, the app will attempt to register on next launch.

## Step 7: Test the Configuration

### Test Manually from Menu Bar

1. Click the menu bar icon
2. Select **"Test Login Now"**
3. Watch for a system notification indicating success or failure

### Test from Command Line

```bash
/Applications/WebsiteLoginBot.app/Contents/MacOS/LoginWorker --test
```

Check the logs:
```bash
cat ~/Library/Logs/WebsiteLoginBot/worker.log
```

## Step 8: Monitor Logs

Logs are stored in `~/Library/Logs/WebsiteLoginBot/`:

- `app.log` - Main application logs
- `network.log` - Network and login operation logs
- `worker.log` - Worker tool logs
- `hourly.log` - Output from hourly scheduled tasks
- `retry.log` - Output from retry scheduled tasks

### View Logs in Real-Time

```bash
# Watch all logs
tail -f ~/Library/Logs/WebsiteLoginBot/*.log

# Watch just hourly attempts
tail -f ~/Library/Logs/WebsiteLoginBot/hourly.log
```

### Open Logs in Console.app

From the menu bar:
1. Click the icon
2. Select **"View Logs"**

Or from Terminal:
```bash
open ~/Library/Logs/WebsiteLoginBot/
```

## Customization

### Adjusting Schedule Intervals

#### Change Hourly Schedule

Edit `~/Library/LaunchAgents/com.websiteloginbot.hourly.plist`:

```xml
<!-- Run at specific times -->
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

After editing, reload:
```bash
launchctl unload ~/Library/LaunchAgents/com.websiteloginbot.hourly.plist
launchctl load ~/Library/LaunchAgents/com.websiteloginbot.hourly.plist
```

#### Change Retry Interval

Edit `~/Library/LaunchAgents/com.websiteloginbot.retry.plist`:

```xml
<!-- Change from 900 seconds (15 min) to 600 seconds (10 min) -->
<key>StartInterval</key>
<integer>600</integer>
```

Reload after editing.

### Adapting to Your Website

The default implementation uses JSON POST for login. If your website uses a different format:

1. Edit `WebsiteLoginBot/NetworkManager.swift`
2. Modify the `login()` method
3. Update the request format (JSON vs form-encoded)
4. Adjust the session verification endpoint
5. Rebuild the application

## Troubleshooting

### Application Not Appearing in Menu Bar

```bash
# Check if the app is running
ps aux | grep WebsiteLoginBot

# Try launching from Terminal to see errors
/Applications/WebsiteLoginBot.app/Contents/MacOS/WebsiteLoginBot
```

### LaunchAgent Not Running

```bash
# Check agent status
launchctl list | grep websiteloginbot

# Check for errors in system logs
log show --predicate 'subsystem == "com.apple.launchd"' --last 30m | grep websiteloginbot

# Manually trigger
launchctl start com.websiteloginbot.hourly
```

### Login Failures

1. **Check credentials**: Use "Configure" to re-enter
2. **Verify URL**: Ensure it points to the correct login endpoint
3. **Check logs**: Look for HTTP status codes in network.log
4. **Test manually**: Use "Test Login Now" from menu bar
5. **Website changes**: Target site may have changed their API

### Permission Issues

```bash
# Fix app permissions
sudo chmod -R 755 /Applications/WebsiteLoginBot.app
sudo chown -R $(whoami):staff /Applications/WebsiteLoginBot.app

# Fix LaunchAgent permissions
chmod 644 ~/Library/LaunchAgents/com.websiteloginbot.*.plist
```

## Security Notes

- Credentials are stored using macOS Keychain Services (encrypted)
- No credentials are written to log files
- Always use HTTPS URLs for secure communication
- Review target website's Terms of Service before use

## Uninstallation

See the main README.md for complete uninstallation instructions.

Quick uninstall:
```bash
launchctl unload ~/Library/LaunchAgents/com.websiteloginbot.*.plist
rm ~/Library/LaunchAgents/com.websiteloginbot.*.plist
rm -rf /Applications/WebsiteLoginBot.app
rm -rf ~/Library/Logs/WebsiteLoginBot
```

Then delete credentials from Keychain Access.app.

## Getting Help

- **Issues**: Open an issue on GitHub
- **Logs**: Include relevant log excerpts when reporting issues
- **System Info**: Include macOS version and Xcode version

## Next Steps

- Customize the login logic for your specific website
- Add additional verification steps
- Implement error notifications
- Contribute improvements back to the project
