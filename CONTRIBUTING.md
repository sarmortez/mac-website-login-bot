# Contributing to Website Login Bot

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to the project.

## Code of Conduct

Be respectful, constructive, and collaborative. We're all here to build something useful.

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in Issues
2. Use the bug report template
3. Include:
   - macOS version
   - Xcode version
   - Steps to reproduce
   - Expected vs actual behavior
   - Relevant log excerpts

### Suggesting Features

1. Check if the feature has already been requested
2. Describe the use case clearly
3. Explain why it would be valuable
4. Consider implementation complexity

### Submitting Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Write or update tests
5. Update documentation
6. Commit with clear messages
7. Push to your fork
8. Open a Pull Request

## Development Setup

### Prerequisites

```bash
# Ensure Xcode and command line tools are installed
xcode-select --install

# Clone your fork
git clone https://github.com/YOUR_USERNAME/mac-website-login-bot.git
cd mac-website-login-bot

# Open in Xcode
open WebsiteLoginBot.xcodeproj
```

### Building

```bash
# Build with script
./build.sh

# Or build with xcodebuild
xcodebuild -project WebsiteLoginBot.xcodeproj -scheme WebsiteLoginBot -configuration Debug build
```

### Running Tests

```bash
xcodebuild test -scheme WebsiteLoginBot
```

## Code Style

### Swift Guidelines

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use 4 spaces for indentation (not tabs)
- Maximum line length: 120 characters
- Use meaningful variable names
- Comment complex logic

### Example

```swift
// Good
func performLogin() async -> Bool {
    guard hasNetworkConnection() else {
        logMessage("No network connection")
        return false
    }
    // ... implementation
}

// Bad
func login() async -> Bool {
    if !hasNet() { return false }
    // ...
}
```

### Documentation

- Add doc comments for public APIs
- Use `///` for documentation
- Include parameter descriptions

```swift
/// Stores credentials securely in the macOS Keychain
/// - Parameters:
///   - username: The username to store
///   - password: The password to store
/// - Throws: KeychainError if the operation fails
func storeCredentials(username: String, password: String) throws {
    // Implementation
}
```

## Testing Guidelines

### Unit Tests

- Test public interfaces
- Use XCTest framework
- Mock external dependencies
- Name tests clearly: `testMethodName_Scenario_ExpectedBehavior`

```swift
func testStoreCredentials_ValidInput_SuccessfullyStores() {
    XCTAssertNoThrow(try keychainManager.storeCredentials(
        username: "test",
        password: "pass"
    ))
}
```

### Integration Tests

- Test end-to-end workflows
- Use test servers for network tests
- Clean up test data in tearDown

### Manual Testing

- Test menu bar interactions
- Verify LaunchAgent scheduling
- Check log output
- Test with real websites (with permission)

## Commit Messages

Use clear, descriptive commit messages:

```
# Good
Add retry logic for failed login attempts

Implements exponential backoff when login fails.
Retries up to 3 times before giving up.

Fixes #42

# Bad
fix bug
```

### Format

```
<type>: <subject>

<body>

<footer>
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting, missing semicolons, etc.
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance

## Pull Request Process

1. **Update Documentation**: Ensure README, code comments, and guides are current
2. **Add Tests**: Include tests for new functionality
3. **Update CHANGELOG**: Add entry for your changes
4. **Pass CI**: Ensure all tests pass
5. **Request Review**: Tag maintainers for review
6. **Address Feedback**: Make requested changes
7. **Squash Commits**: Clean up commit history if needed

## Project Structure

```
WebsiteLoginBot/
├── WebsiteLoginBot/          # Main app
│   ├── AppDelegate.swift
│   ├── MenuBarController.swift
│   ├── NetworkManager.swift
│   └── KeychainManager.swift
├── LoginWorker/              # CLI tool
│   └── main.swift
├── Tests/                    # Unit tests
├── LaunchAgents/             # Plist files
└── Documentation/            # Guides
```

## Areas for Contribution

### High Priority

- [ ] Log rotation implementation
- [ ] Better error handling
- [ ] Support for more authentication types
- [ ] Improved retry logic
- [ ] System notification support

### Medium Priority

- [ ] Multiple website support
- [ ] GUI improvements
- [ ] Proxy configuration
- [ ] Export/import configuration
- [ ] Statistics tracking

### Low Priority

- [ ] Dark mode icon variants
- [ ] Localization
- [ ] Custom scheduling options
- [ ] Session monitoring dashboard

## Security Considerations

### When Contributing

1. **Never log credentials**: Don't print passwords or tokens
2. **Use Keychain**: Always use Keychain for sensitive data
3. **Validate input**: Sanitize user input
4. **HTTPS only**: Enforce secure connections
5. **Code review**: Security-sensitive changes need careful review

### Reporting Security Issues

Do not open public issues for security vulnerabilities.

Email: [maintainer email] with details.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Questions?

Feel free to open an issue with the "question" label.

## Recognition

Contributors will be acknowledged in the README and CHANGELOG.

Thank you for contributing! 🚀
