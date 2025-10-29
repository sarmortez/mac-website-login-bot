//
//  NetworkManager.swift
//  WebsiteLoginBot
//
//  Handles network connectivity checks, HTTP login, and session verification.
//

import Foundation
import SystemConfiguration

class NetworkManager {
    
    // MARK: - Singleton
    
    static let shared = NetworkManager()
    
    private init() {}
    
    // MARK: - Properties
    
    private let keychainManager = KeychainManager.shared
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()
    
    // MARK: - Network Connectivity
    
    /// Checks if the device has an active internet connection
    func hasNetworkConnection() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let reachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(reachability, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        return isReachable && !needsConnection
    }
    
    // MARK: - Login Flow
    
    /// Performs the complete login workflow
    /// - Returns: True if login was successful, false otherwise
    func performLogin() async -> Bool {
        // Check network connectivity
        guard hasNetworkConnection() else {
            logMessage("No network connection available")
            return false
        }
        
        // Retrieve credentials
        guard let credentials = try? keychainManager.retrieveCredentials() else {
            logMessage("Failed to retrieve credentials from keychain")
            return false
        }
        
        // Get website URL
        guard let urlString = UserDefaults.standard.string(forKey: "websiteURL"),
              let loginURL = URL(string: urlString) else {
            logMessage("Invalid or missing website URL")
            return false
        }
        
        logMessage("Starting login attempt to \(loginURL.absoluteString)")
        
        // Perform login request
        let loginSuccess = await login(url: loginURL, username: credentials.username, password: credentials.password)
        
        if !loginSuccess {
            logMessage("Login failed")
            // Store failure state for retry mechanism
            UserDefaults.standard.set(false, forKey: "lastLoginSuccess")
            UserDefaults.standard.set(Date(), forKey: "lastLoginAttempt")
            return false
        }
        
        logMessage("Login successful")
        
        // Verify session
        let sessionValid = await verifySession(baseURL: loginURL)
        
        if sessionValid {
            logMessage("Session verified successfully")
            UserDefaults.standard.set(true, forKey: "lastLoginSuccess")
            UserDefaults.standard.set(Date(), forKey: "lastLoginAttempt")
            return true
        } else {
            logMessage("Session verification failed")
            UserDefaults.standard.set(false, forKey: "lastLoginSuccess")
            UserDefaults.standard.set(Date(), forKey: "lastLoginAttempt")
            return false
        }
    }
    
    // MARK: - HTTP Requests
    
    /// Performs HTTP POST login request
    private func login(url: URL, username: String, password: String) async -> Bool {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        
        // Create JSON body
        // NOTE: This is a generic format. You may need to adjust based on the target website
        let body: [String: Any] = [
            "username": username,
            "password": password
        ]
        
        // Alternative: Form-encoded body (uncomment if needed)
        // request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        // let bodyString = "username=\(username)&password=\(password)"
        // request.httpBody = bodyString.data(using: .utf8)
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            logMessage("Failed to encode login request: \(error.localizedDescription)")
            return false
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logMessage("Invalid response type")
                return false
            }
            
            logMessage("Login response status: \(httpResponse.statusCode)")
            
            // Check for successful status codes (200-299)
            guard (200...299).contains(httpResponse.statusCode) else {
                if let responseString = String(data: data, encoding: .utf8) {
                    logMessage("Login failed with response: \(responseString)")
                }
                return false
            }
            
            // Parse response to check for login success
            // NOTE: Adjust this based on your target website's response format
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                logMessage("Login response: \(json)")
                
                // Example: Check for success field
                if let success = json["success"] as? Bool {
                    return success
                }
                
                // Example: Check for error field
                if let error = json["error"] as? String {
                    logMessage("Login error: \(error)")
                    return false
                }
            }
            
            // If we got a 200 response and cookies were set, assume success
            if let cookies = HTTPCookieStorage.shared.cookies(for: url), !cookies.isEmpty {
                logMessage("Received \(cookies.count) cookies")
                return true
            }
            
            // Default to success if we got a 2xx status code
            return true
            
        } catch {
            logMessage("Login request failed: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Verifies the session is active by making a GET request
    private func verifySession(baseURL: URL) async -> Bool {
        // Construct verification URL
        // NOTE: Adjust this based on your target website
        // Common patterns: /api/user, /dashboard, /profile, /api/session
        let verificationPath = "/api/user" // Change this to match your website
        
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true) else {
            return false
        }
        components.path = verificationPath
        
        guard let verifyURL = components.url else {
            return false
        }
        
        var request = URLRequest(url: verifyURL)
        request.httpMethod = "GET"
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            
            logMessage("Session verification status: \(httpResponse.statusCode)")
            
            // Check for successful status codes
            if (200...299).contains(httpResponse.statusCode) {
                if let responseString = String(data: data, encoding: .utf8) {
                    logMessage("Session verification response: \(responseString.prefix(200))")
                }
                return true
            }
            
            // 401 or 403 typically means not authenticated
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                logMessage("Session verification failed: Not authenticated")
                return false
            }
            
            return false
            
        } catch {
            logMessage("Session verification failed: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Logging
    
    private func logMessage(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logMessage = "[\(timestamp)] NetworkManager: \(message)\n"
        
        let logDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/WebsiteLoginBot")
        
        try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)
        
        let logFile = logDir.appendingPathComponent("network.log")
        
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
        
        print(logMessage)
    }
}
