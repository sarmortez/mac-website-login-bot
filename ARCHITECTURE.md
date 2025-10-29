# Architecture Overview

## System Design

The Website Login Bot consists of three primary components working together:

```
┌────────────────────────┐
│  WebsiteLoginBot.app   │  <- Menu Bar UI
│  (Always Running)      │
└───────────┬────────────┘
           │
           │ Shares Keychain & UserDefaults
           │
┌───────────┴────────────┐
│    LoginWorker Tool    │  <- CLI Worker
│ (Invoked by launchd)  │
└───────────┬────────────┘
           │
           │ Scheduled by
           │
┌───────────┴─────────────────────────┐
│         launchd                      │  <- macOS Scheduler
│  - hourly.plist (every hour)       │
│  - retry.plist (every 15 minutes)  │
└─────────────────────────────────────┘
```

## Component Details

### 1. WebsiteLoginBot.app (Menu Bar Application)

**Purpose**: Provides user interface and configuration management

**Key Files**:
- `AppDelegate.swift` - Application lifecycle, login item registration
- `MenuBarController.swift` - Menu bar UI, user interactions
- `NetworkManager.swift` - HTTP client, login logic
- `KeychainManager.swift` - Secure credential storage
- `Info.plist` - App configuration (LSUIElement = true)

**Responsibilities**:
- Display menu bar icon
- Provide configuration interface
- Store credentials in Keychain
- Allow manual login testing
- Register as login item
- Remain running in background

**Technologies**:
- AppKit (NSStatusItem for menu bar)
- Keychain Services API
- Service Management Framework (SMLoginItemSetEnabled/SMAppService)
- URLSession for networking

### 2. LoginWorker (Command-Line Tool)

**Purpose**: Performs scheduled login attempts

**Key Files**:
- `main.swift` - Entry point, login workflow

**Responsibilities**:
- Check network connectivity
- Retrieve credentials from Keychain
- Perform HTTP login request
- Verify session validity
- Log results
- Update success/failure state

**Invocation**:
- Called by launchd on schedule
- Can be manually tested: `LoginWorker --test`
- Exits after each run (not a daemon)

**State Management**:
- Uses UserDefaults to track last attempt
- Stores success/failure for retry logic

### 3. LaunchAgent Configuration

**Purpose**: Schedule automated login attempts

#### Hourly Agent (`com.websiteloginbot.hourly.plist`)

```xml
<key>StartCalendarInterval</key>
<dict>
    <key>Minute</key>
    <integer>0</integer>
</dict>
```

- Triggers at XX:00 every hour
- Uses `StartCalendarInterval` for precise timing
- Primary scheduled login mechanism

#### Retry Agent (`com.websiteloginbot.retry.plist`)

```xml
<key>StartInterval</key>
<integer>900</integer>
```

- Triggers every 15 minutes (900 seconds)
- Uses `StartInterval` for repeating execution
- Handles failed login retries
- Worker tool checks last success before attempting

## Data Flow

### Configuration Flow

```
User Input (Menu Bar)
     ↓
MenuBarController.showConfiguration()
     ↓
KeychainManager.storeCredentials()
     ↓
macOS Keychain (Encrypted)
     +
UserDefaults (URL only)
```

### Login Flow

```
launchd triggers LoginWorker
     ↓
Check network connectivity
     ↓
Retrieve credentials from Keychain
     ↓
Retrieve URL from UserDefaults
     ↓
HTTP POST to login endpoint
     ↓
Receive cookies/session token
     ↓
HTTP GET to verify session
     ↓
Update state in UserDefaults
     ↓
Log results to file
     ↓
Exit (success or failure code)
```

## Security Architecture

### Credential Storage

```
Keychain Item:
  Service: "com.websiteloginbot.credentials"
  Account: "username"
  Data: <encrypted username>
  
Keychain Item:
  Service: "com.websiteloginbot.credentials"
  Account: "password"
  Data: <encrypted password>
```

**Protection Level**: `kSecAttrAccessibleAfterFirstUnlock`
- Accessible after first device unlock
- Persists across reboots
- Protected by Keychain encryption

### Network Security

- Uses URLSession with default security policies
- Enforces HTTPS (recommended)
- Stores session cookies in HTTPCookieStorage
- Sets User-Agent to avoid bot detection

## File System Layout

```
/Applications/WebsiteLoginBot.app/
  Contents/
    MacOS/
      WebsiteLoginBot          <- Main app binary
      LoginWorker              <- Worker tool binary
    Info.plist                 <- App configuration
    Resources/                 <- (future: icons, assets)

~/Library/LaunchAgents/
  com.websiteloginbot.hourly.plist
  com.websiteloginbot.retry.plist

~/Library/Logs/WebsiteLoginBot/
  app.log                      <- Main app logs
  network.log                  <- Network operation logs
  worker.log                   <- Worker tool logs
  hourly.log                   <- Hourly task output
  hourly-error.log             <- Hourly task errors
  retry.log                    <- Retry task output
  retry-error.log              <- Retry task errors

~/Library/Preferences/
  com.websiteloginbot.app.plist  <- UserDefaults (URL, state)
```

## Process Communication

### Shared Data Stores

1. **Keychain** (Read/Write by both)
   - Main app: Write credentials
   - Worker tool: Read credentials

2. **UserDefaults** (Read/Write by both)
   - Main app: Write URL
   - Worker tool: Read URL, write state

3. **File System** (Read/Write by both)
   - Both write to separate log files
   - No file locking needed (append-only)

### No IPC Required

- Menu bar app and worker don't communicate directly
- State synchronized through UserDefaults
- Worker runs independently

## Scheduling Details

### Why Two LaunchAgents?

1. **Hourly Agent**: Ensures login happens reliably every hour
2. **Retry Agent**: Handles failures without waiting until next hour

### Retry Logic

```swift
func shouldAttemptLogin() -> Bool {
    let lastSuccess = UserDefaults.standard.bool(forKey: "lastLoginSuccess")
    
    if lastSuccess {
        // Check if it's been at least 55 minutes
        if let lastAttempt = UserDefaults.standard.object(forKey: "lastLoginAttempt") as? Date {
            let timeSince = Date().timeIntervalSince(lastAttempt)
            if timeSince < 55 * 60 {
                return false  // Skip retry if recent success
            }
        }
    }
    
    return true  // Attempt if failed or time elapsed
}
```

### Scheduling Trade-offs

**Chosen Approach**: Separate hourly + retry agents
- ✅ Simple, reliable
- ✅ Uses native macOS scheduling
- ✅ Survives reboots
- ✅ No daemon process needed

**Alternative Approaches** (not used):
- Single agent with complex logic: More complicated
- Daemon process: Higher resource usage
- Cron jobs: Not recommended on macOS

## Extension Points

### Adding New Features

1. **Custom Login Flows**: Edit `NetworkManager.login()`
2. **Different Websites**: Subclass or configure NetworkManager
3. **Notifications**: Add UserNotifications framework
4. **Multiple Sites**: Refactor to support multiple configurations
5. **OAuth**: Implement OAuth flow in NetworkManager

### Testing Strategy

- **Unit Tests**: KeychainManager, NetworkManager (mock)
- **Integration Tests**: Full login flow with test server
- **Manual Tests**: Menu bar UI, LaunchAgent scheduling
- **CLI Testing**: Run LoginWorker with --test flag

## Performance Considerations

### Resource Usage

- **Menu Bar App**: ~20-30 MB RAM (idle)
- **LoginWorker**: ~10-15 MB RAM (during execution)
- **Network**: Minimal (2-3 HTTP requests per login)
- **Disk**: Log rotation not implemented (manual cleanup)

### Optimization Opportunities

1. Log rotation (implement file size limits)
2. Reduce retry frequency during known downtime
3. Cache session tokens longer
4. Implement exponential backoff for failures

## Deployment

### Build Process

1. Compile Swift code with Xcode
2. Create .app bundle
3. Embed LoginWorker inside bundle
4. Code sign (optional but recommended)
5. Package LaunchAgent plists

### Installation Steps

1. Copy .app to /Applications
2. Copy plists to ~/Library/LaunchAgents
3. Load LaunchAgents with launchctl
4. Launch app (registers as login item)

### Distribution Options

- **Manual**: Zip file with build script
- **Package**: Create .pkg installer
- **Mac App Store**: Would require sandboxing changes
- **Homebrew**: Create cask formula

## Future Enhancements

1. **GUI Configuration**: More sophisticated UI
2. **Multiple Sites**: Support for multiple website configs
3. **Status Bar Updates**: Show last login time/status
4. **Notifications**: System notifications for failures
5. **Log Viewer**: Built-in log viewing
6. **Session Monitoring**: Continuous session validation
7. **Proxy Support**: Configure HTTP proxies
8. **Two-Factor Auth**: TOTP integration
