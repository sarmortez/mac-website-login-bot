//
//  AppDelegate.swift
//  WebsiteLoginBot
//
//  Main application delegate handling app lifecycle and login item registration.
//

import Cocoa
import ServiceManagement

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Properties
    
    /// Menu bar controller managing the status item and UI
    private var menuBarController: MenuBarController!
    
    /// Network manager handling login operations
    private let networkManager = NetworkManager.shared
    
    /// Keychain manager for secure credential storage
    private let keychainManager = KeychainManager.shared
    
    // MARK: - Application Lifecycle
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize menu bar controller
        menuBarController = MenuBarController()
        
        // Register as login item on first launch
        registerAsLoginItem()
        
        // Check if configuration exists
        if !isConfigured() {
            // Show configuration dialog on first run
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.menuBarController.showConfiguration()
            }
        }
        
        // Log startup
        logMessage("WebsiteLoginBot started successfully")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        logMessage("WebsiteLoginBot terminating")
    }
    
    // MARK: - Login Item Registration
    
    /// Registers the application as a login item using Service Management framework
    private func registerAsLoginItem() {
        // Check if already registered
        let alreadyRegistered = UserDefaults.standard.bool(forKey: "loginItemRegistered")
        
        if alreadyRegistered {
            return
        }
        
        // Note: SMLoginItemSetEnabled is deprecated in macOS 13+
        // For newer macOS versions, use SMAppService instead
        if #available(macOS 13.0, *) {
            do {
                let service = SMAppService.mainApp
                try service.register()
                UserDefaults.standard.set(true, forKey: "loginItemRegistered")
                logMessage("Successfully registered as login item")
            } catch {
                logMessage("Failed to register as login item: \(error.localizedDescription)")
            }
        } else {
            // For older macOS versions
            let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.websiteloginbot.app"
            let success = SMLoginItemSetEnabled(bundleIdentifier as CFString, true)
            
            if success {
                UserDefaults.standard.set(true, forKey: "loginItemRegistered")
                logMessage("Successfully registered as login item (legacy)")
            } else {
                logMessage("Failed to register as login item (legacy)")
            }
        }
    }
    
    // MARK: - Configuration
    
    /// Check if the app has been configured with URL and credentials
    private func isConfigured() -> Bool {
        guard let _ = UserDefaults.standard.string(forKey: "websiteURL") else {
            return false
        }
        
        // Check if credentials exist in keychain
        do {
            let _ = try keychainManager.retrieveCredentials()
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Logging
    
    /// Log messages to the app log file
    private func logMessage(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
        let logMessage = "[\(timestamp)] \(message)\n"
        
        let logDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/WebsiteLoginBot")
        
        try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)
        
        let logFile = logDir.appendingPathComponent("app.log")
        
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
        
        // Also print to console for debugging
        print(logMessage)
    }
}
