//
//  main.swift
//  LoginWorker
//
//  Command-line tool invoked by launchd to perform scheduled login attempts.
//  This tool is called by the LaunchAgent plists on schedule.
//

import Foundation

// MARK: - Configuration

let service = "com.websiteloginbot.credentials"
let logDir = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent("Library/Logs/WebsiteLoginBot")

// Ensure log directory exists
try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)

// MARK: - Logging

func log(_ message: String, to filename: String = "worker.log") {
    let timestamp = ISO8601DateFormatter().string(from: Date())
    let logMessage = "[\(timestamp)] \(message)\n"
    
    let logFile = logDir.appendingPathComponent(filename)
    
    if let data = logMessage.data(using: .utf8) {
        if FileManager.default.fileExists(atPath: logFile.path) {
            if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        } else {
            try? data.write(to: logFile)
        }
    }
    
    // Also print to stdout for launchd logs
    print(logMessage, terminator: "")
}

// MARK: - Network Connectivity

func hasNetworkConnection() -> Bool {
    // Simple check: try to connect to a well-known host
    let url = URL(string: "https://www.google.com")!
    var request = URLRequest(url: url)
    request.timeoutInterval = 5
    request.httpMethod = "HEAD"
    
    let semaphore = DispatchSemaphore(value: 0)
    var connected = false
    
    let task = URLSession.shared.dataTask(with: request) { _, response, error in
        if let httpResponse = response as? HTTPURLResponse,
           (200...299).contains(httpResponse.statusCode) {
            connected = true
        }
        semaphore.signal()
    }
    
    task.resume()
    _ = semaphore.wait(timeout: .now() + 6)
    
    return connected
}

// MARK: - Keychain Access

func retrieveCredentials() throws -> (username: String, password: String) {
    let usernameQuery: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: "username",
        kSecReturnData as String: true,
        kSecMatchLimit as String: kSecMatchLimitOne
    ]
    
    let passwordQuery: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: "password",
        kSecReturnData as String: true,
        kSecMatchLimit as String: kSecMatchLimitOne
    ]
    
    var usernameResult: AnyObject?
    var passwordResult: AnyObject?
    
    let usernameStatus = SecItemCopyMatching(usernameQuery as CFDictionary, &usernameResult)
    let passwordStatus = SecItemCopyMatching(passwordQuery as CFDictionary, &passwordResult)
    
    guard usernameStatus == errSecSuccess,
          passwordStatus == errSecSuccess,
          let usernameData = usernameResult as? Data,
          let passwordData = passwordResult as? Data,
          let username = String(data: usernameData, encoding: .utf8),
          let password = String(data: passwordData, encoding: .utf8) else {
        throw NSError(domain: "KeychainError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve credentials"])
    }
    
    return (username, password)
}

// MARK: - Login Logic

func performLogin() async -> Bool {
    // Check network
    guard hasNetworkConnection() else {
        log("No network connection")
        return false
    }
    
    log("Network connection verified")
    
    // Get credentials
    guard let credentials = try? retrieveCredentials() else {
        log("Failed to retrieve credentials from keychain")
        return false
    }
    
    log("Retrieved credentials for user: \(credentials.username)")
    
    // Get URL
    guard let urlString = UserDefaults.standard.string(forKey: "websiteURL"),
          let loginURL = URL(string: urlString) else {
        log("Invalid or missing website URL")
        return false
    }
    
    log("Attempting login to: \(loginURL.absoluteString)")
    
    // Perform login
    var request = URLRequest(url: loginURL)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
    request.timeoutInterval = 30
    
    let body: [String: Any] = [
        "username": credentials.username,
        "password": credentials.password
    ]
    
    guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
        log("Failed to encode login request")
        return false
    }
    
    request.httpBody = httpBody
    
    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            log("Invalid response type")
            return false
        }
        
        log("Login response status: \(httpResponse.statusCode)")
        
        if (200...299).contains(httpResponse.statusCode) {
            if let responseString = String(data: data, encoding: .utf8) {
                log("Login successful. Response: \(responseString.prefix(200))")
            } else {
                log("Login successful")
            }
            
            // Verify session
            let sessionVerified = await verifySession(baseURL: loginURL)
            if sessionVerified {
                log("Session verified successfully")
                return true
            } else {
                log("Session verification failed")
                return false
            }
        } else {
            if let responseString = String(data: data, encoding: .utf8) {
                log("Login failed. Response: \(responseString.prefix(200))")
            } else {
                log("Login failed with status: \(httpResponse.statusCode)")
            }
            return false
        }
    } catch {
        log("Login request error: \(error.localizedDescription)")
        return false
    }
}

func verifySession(baseURL: URL) async -> Bool {
    guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true) else {
        return false
    }
    
    components.path = "/api/user" // Adjust based on target website
    
    guard let verifyURL = components.url else {
        return false
    }
    
    var request = URLRequest(url: verifyURL)
    request.httpMethod = "GET"
    request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
    request.timeoutInterval = 30
    
    do {
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            return false
        }
        
        log("Session verification status: \(httpResponse.statusCode)")
        
        return (200...299).contains(httpResponse.statusCode)
    } catch {
        log("Session verification error: \(error.localizedDescription)")
        return false
    }
}

// MARK: - Retry Logic

func shouldAttemptLogin() -> Bool {
    // Check if we're in retry mode
    let lastSuccess = UserDefaults.standard.bool(forKey: "lastLoginSuccess")
    
    // If last login was successful, only proceed if called by hourly schedule
    // This is determined by checking the calling context
    if lastSuccess {
        // Check if it's been at least 55 minutes since last attempt
        if let lastAttempt = UserDefaults.standard.object(forKey: "lastLoginAttempt") as? Date {
            let timeSince = Date().timeIntervalSince(lastAttempt)
            if timeSince < 55 * 60 {
                log("Skipping: Last successful login was recent (\(Int(timeSince / 60)) minutes ago)")
                return false
            }
        }
    }
    
    return true
}

// MARK: - Main Entry Point

func main() async {
    log("=== LoginWorker Started ===")
    
    // Parse command-line arguments
    let arguments = CommandLine.arguments
    let isTest = arguments.contains("--test")
    
    if isTest {
        log("Running in test mode")
    }
    
    // Check if we should attempt login
    if !isTest && !shouldAttemptLogin() {
        log("=== LoginWorker Finished (Skipped) ===")
        exit(0)
    }
    
    // Perform login
    let success = await performLogin()
    
    // Store result
    UserDefaults.standard.set(success, forKey: "lastLoginSuccess")
    UserDefaults.standard.set(Date(), forKey: "lastLoginAttempt")
    
    if success {
        log("\u2705 Login completed successfully")
        log("=== LoginWorker Finished (Success) ===")
        exit(0)
    } else {
        log("❌ Login failed")
        log("=== LoginWorker Finished (Failed) ===")
        exit(1)
    }
}

// Run main
await main()
