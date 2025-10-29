# Changelog

All notable changes to Website Login Bot will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Log rotation implementation
- Multiple website support
- System notification for failures
- Improved error handling
- Session monitoring dashboard
- OAuth2 support
- Two-factor authentication support

## [1.0.0] - 2025-10-29

### Added
- Initial release
- Menu-bar application with LSUIElement
- Secure credential storage using macOS Keychain
- HTTP login with URLSession
- Network connectivity checking
- Session verification via GET requests
- LoginWorker command-line tool
- LaunchAgent for hourly scheduling (StartCalendarInterval)
- LaunchAgent for retry scheduling (StartInterval)
- Service Management integration for login items
- Build script for automation
- Comprehensive documentation:
  - README.md with full instructions
  - SETUP_GUIDE.md with detailed setup
  - QUICKSTART.md for fast setup
  - ARCHITECTURE.md with system design
  - CONTRIBUTING.md for contributors
  - SECURITY.md with security practices
- Helper scripts:
  - build.sh for building
  - scripts/install.sh for installation
  - scripts/uninstall.sh for removal
  - scripts/test-login.sh for testing
- Makefile with convenient commands
- Unit tests for KeychainManager and NetworkManager
- Xcode project configuration
- GitHub issue templates
- MIT License

### Security
- Keychain encryption for credentials
- No plain-text credential storage
- Hardened runtime enabled
- Input validation for URLs and credentials
- Secure logging (no credentials in logs)

## Version History

### v1.0.0 - Initial Release (2025-10-29)

First public release of Website Login Bot.

**Features:**
- ✅ Menu-bar only application (no dock icon)
- ✅ Secure Keychain credential storage
- ✅ Hourly automated login attempts
- ✅ 15-minute retry for failed logins
- ✅ Auto-start at user login
- ✅ Network connectivity checking
- ✅ Session verification
- ✅ Comprehensive logging
- ✅ Manual testing from menu bar
- ✅ Native launchd scheduling

**Documentation:**
- Complete README with examples
- Setup guide with troubleshooting
- Quick start for fast deployment
- Architecture overview
- Contributing guidelines
- Security policy

**Known Limitations:**
- Single website support only
- Basic authentication only
- No 2FA support
- No CAPTCHA handling
- Manual log cleanup required
- No GUI for advanced settings

**System Requirements:**
- macOS 11.0 (Big Sur) or later
- Xcode 13.0 or later (for building)

---

## Release Notes Format

### Version Format
```
[MAJOR.MINOR.PATCH]

MAJOR: Breaking changes
MINOR: New features (backward compatible)
PATCH: Bug fixes (backward compatible)
```

### Change Categories

- **Added**: New features
- **Changed**: Changes to existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security improvements

---

[Unreleased]: https://github.com/sarmortez/mac-website-login-bot/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/sarmortez/mac-website-login-bot/releases/tag/v1.0.0
