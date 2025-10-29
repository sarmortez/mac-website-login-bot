# Configuration Examples

This document provides examples for adapting Website Login Bot to different types of websites and authentication systems.

## Basic JSON Login

Most modern websites use JSON for authentication.

### Example 1: Simple JSON POST

```swift
// In NetworkManager.swift - login() method

let body: [String: Any] = [
    "username": username,
    "password": password
]

request.setValue("application/json", forHTTPHeaderField: "Content-Type")
request.httpBody = try JSONSerialization.data(withJSONObject: body)
```

**Works with:**
- Most REST APIs
- Modern web applications
- SaaS platforms

### Example 2: Nested JSON Structure

```swift
let body: [String: Any] = [
    "user": [
        "email": username,
        "password": password
    ],
    "remember_me": true
]
```

**Used by:**
- Rails applications
- Some Node.js apps

### Example 3: JSON with Additional Fields

```swift
let body: [String: Any] = [
    "username": username,
    "password": password,
    "grant_type": "password",
    "client_id": "your-app-client-id",
    "scope": "read write"
]
```

**Used by:**
- OAuth2 password grant
- API-first applications

## Form-Encoded Login

Older websites often use form encoding.

### Example 4: URL-Encoded Form

```swift
// In NetworkManager.swift - login() method

request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

let bodyString = "username=\(username)&password=\(password)"
request.httpBody = bodyString.data(using: .utf8)
```

**Works with:**
- Traditional HTML forms
- Many PHP applications
- WordPress login

### Example 5: Form with CSRF Token

```swift
// First, fetch the login page to get CSRF token
func fetchCSRFToken() async -> String? {
    let (data, _) = try? await session.data(from: loginPageURL)
    guard let html = String(data: data, encoding: .utf8) else { return nil }
    
    // Parse HTML for CSRF token (adjust regex for your site)
    let pattern = #"<input[^>]*name=["']csrf["'][^>]*value=["']([^"']+)["']"#
    if let match = html.range(of: pattern, options: .regularExpression) {
        return String(html[match])
    }
    return nil
}

// Then include in login request
if let csrf = await fetchCSRFToken() {
    let bodyString = "username=\(username)&password=\(password)&csrf_token=\(csrf)"
    request.httpBody = bodyString.data(using: .utf8)
}
```

**Required by:**
- Security-conscious applications
- Most modern frameworks (Django, Rails, etc.)

## Session Verification

### Example 6: Cookie-Based Sessions

```swift
// In NetworkManager.swift - verifySession() method

func verifySession(baseURL: URL) async -> Bool {
    // Check if we have cookies
    guard let cookies = HTTPCookieStorage.shared.cookies(for: baseURL),
          !cookies.isEmpty else {
        return false
    }
    
    // Verify session with a protected endpoint
    var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)!
    components.path = "/api/user/profile"  // Adjust for your site
    
    let request = URLRequest(url: components.url!)
    let (_, response) = try await session.data(for: request)
    
    return (response as? HTTPURLResponse)?.statusCode == 200
}
```

### Example 7: Token-Based Sessions

```swift
func verifySession(baseURL: URL) async -> Bool {
    // Extract token from login response
    // Store token from login response:
    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
       let token = json["access_token"] as? String {
        UserDefaults.standard.set(token, forKey: "authToken")
    }
    
    // Verify with token
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        return false
    }
    
    var request = URLRequest(url: verifyURL)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let (_, response) = try await session.data(for: request)
    return (response as? HTTPURLResponse)?.statusCode == 200
}
```

## Custom Headers

### Example 8: API Key Authentication

```swift
request.setValue("your-api-key", forHTTPHeaderField: "X-API-Key")
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
```

### Example 9: Custom User Agent

```swift
// Mimic a specific browser
request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", 
                 forHTTPHeaderField: "User-Agent")
```

### Example 10: Accept-Language Header

```swift
request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
request.setValue("text/html,application/json", forHTTPHeaderField: "Accept")
```

## Real-World Examples

### Example 11: WordPress Login

```swift
func loginToWordPress(url: URL, username: String, password: String) async -> Bool {
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    
    let bodyString = "log=\(username)&pwd=\(password)&wp-submit=Log+In&redirect_to=/wp-admin/"
    request.httpBody = bodyString.data(using: .utf8)
    
    let (_, response) = try await session.data(for: request)
    
    // WordPress redirects on success
    return (response as? HTTPURLResponse)?.url?.path.contains("wp-admin") ?? false
}
```

### Example 12: GitHub API (Personal Access Token)

```swift
func loginToGitHub() async -> Bool {
    // GitHub uses PAT (Personal Access Token)
    guard let token = try? keychainManager.retrieveCredentials().password else {
        return false
    }
    
    var request = URLRequest(url: URL(string: "https://api.github.com/user")!)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
    
    let (_, response) = try await session.data(for: request)
    return (response as? HTTPURLResponse)?.statusCode == 200
}
```

### Example 13: REST API with JSON Response

```swift
func loginToAPI(url: URL, username: String, password: String) async -> Bool {
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body = ["email": username, "password": password]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)
    
    let (data, response) = try await session.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        return false
    }
    
    // Parse and store token
    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
       let token = json["token"] as? String {
        UserDefaults.standard.set(token, forKey: "authToken")
        return true
    }
    
    return false
}
```

## Error Handling Examples

### Example 14: Parsing Error Responses

```swift
func handleLoginError(data: Data, statusCode: Int) {
    // Parse JSON error response
    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
        if let errorMessage = json["error"] as? String {
            logMessage("Login error: \(errorMessage)")
        } else if let message = json["message"] as? String {
            logMessage("Login error: \(message)")
        }
    }
    
    // Handle specific status codes
    switch statusCode {
    case 401:
        logMessage("Authentication failed: Invalid credentials")
    case 403:
        logMessage("Access forbidden: Account may be locked")
    case 429:
        logMessage("Rate limited: Too many login attempts")
    case 500...599:
        logMessage("Server error: Try again later")
    default:
        logMessage("Login failed with status: \(statusCode)")
    }
}
```

### Example 15: Retry with Exponential Backoff

```swift
func loginWithRetry(maxAttempts: Int = 3) async -> Bool {
    var attempt = 0
    var delay = 1.0 // Start with 1 second
    
    while attempt < maxAttempts {
        if await performLogin() {
            return true
        }
        
        attempt += 1
        if attempt < maxAttempts {
            logMessage("Attempt \(attempt) failed, retrying in \(delay)s...")
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            delay *= 2 // Exponential backoff
        }
    }
    
    return false
}
```

## Advanced Configurations

### Example 16: Custom URL Session Configuration

```swift
let config = URLSessionConfiguration.default
config.httpCookieAcceptPolicy = .always
config.httpShouldSetCookies = true
config.timeoutIntervalForRequest = 30
config.timeoutIntervalForResource = 60
config.waitsForConnectivity = true

// Add custom headers to all requests
config.httpAdditionalHeaders = [
    "User-Agent": "MyApp/1.0",
    "X-Custom-Header": "value"
]

let session = URLSession(configuration: config)
```

### Example 17: Certificate Pinning

```swift
class NetworkManager: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, 
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Add certificate pinning logic here
        // For production, implement proper certificate validation
        
        completionHandler(.useCredential, URLCredential(trust: serverTrust))
    }
}
```

## LaunchAgent Customizations

### Example 18: Run at Specific Times

```xml
<!-- Run at 9 AM, 1 PM, and 5 PM every day -->
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
        <integer>13</integer>
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

### Example 19: Weekday-Only Schedule

```xml
<!-- Run every weekday at 9 AM -->
<key>StartCalendarInterval</key>
<array>
    <dict>
        <key>Hour</key>
        <integer>9</integer>
        <key>Minute</key>
        <integer>0</integer>
        <key>Weekday</key>
        <integer>1</integer> <!-- Monday -->
    </dict>
    <dict>
        <key>Hour</key>
        <integer>9</integer>
        <key>Minute</key>
        <integer>0</integer>
        <key>Weekday</key>
        <integer>2</integer> <!-- Tuesday -->
    </dict>
    <!-- Add Wednesday (3), Thursday (4), Friday (5) -->
</array>
```

### Example 20: Run on Specific Network

```xml
<!-- Only run when connected to specific WiFi -->
<key>WatchPaths</key>
<array>
    <string>/Library/Preferences/SystemConfiguration/com.apple.wifi.plist</string>
</array>

<!-- Then check SSID in your code -->
```

## Testing Examples

### Example 21: Mock Network Responses

```swift
class MockURLProtocol: URLProtocol {
    static var mockResponses: [URL: (Data, HTTPURLResponse)] = [:]
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        if let url = request.url,
           let (data, response) = MockURLProtocol.mockResponses[url] {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
}

// Use in tests
let config = URLSessionConfiguration.ephemeral
config.protocolClasses = [MockURLProtocol.self]
let session = URLSession(configuration: config)
```

## Complete Implementation Example

See `NetworkManager.swift` for a complete, working implementation that you can adapt to your needs.

## Tips for Adaptation

1. **Use Browser DevTools**: Inspect network traffic to see exact request format
2. **Check Documentation**: Look for API docs from the target website
3. **Test Incrementally**: Start with simple requests, add complexity gradually
4. **Log Everything**: Add detailed logging during development
5. **Handle Edge Cases**: Account for rate limiting, server errors, etc.

## Resources

- [URLSession Documentation](https://developer.apple.com/documentation/foundation/urlsession)
- [HTTP Status Codes](https://httpstatuses.com/)
- [JWT.io](https://jwt.io/) - For token-based auth
- [Postman](https://www.postman.com/) - For testing API requests

---

Need help adapting to a specific website? Open an issue with details!
