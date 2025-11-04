//
//  MenuBarController.swift
//  WebsiteLoginBot
//
//  Controls the menu bar icon and menu interactions.
//

import Cocoa
import AppKit

class MenuBarController: NSObject {
    
    // MARK: - Properties
    
    /// The status item displayed in the menu bar
    private var statusItem: NSStatusItem!
    
    /// The menu attached to the status item
    private var menu: NSMenu!
    
    /// Network manager for testing login
    private let networkManager = NetworkManager.shared
    
    /// Keychain manager for credentials
    private let keychainManager = KeychainManager.shared
    
    /// Last login status
    private var lastLoginStatus: String = "Not attempted"
    private var lastLoginTime: Date?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupMenuBar()
        updateMenu()
    }
    
    // MARK: - Menu Bar Setup
    
    /// Creates and configures the menu bar status item
    private func setupMenuBar() {
        // Create status item in the menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        // Set the icon (using SF Symbol)
        if let button = statusItem.button {
            // Use a globe icon to represent web login
            if let image = NSImage(systemSymbolName: "globe", accessibilityDescription: "Website Login Bot") {
                button.image = image
            } else {
                // Fallback to text if symbol not available
                button.title = "🌐"
            }
        }
        
        // Create the menu
        menu = NSMenu()
        statusItem.menu = menu
    }
    
    // MARK: - Menu Management
    
    /// Updates the menu items
    private func updateMenu() {
        menu.removeAllItems()
        
        // Status item
        let statusTitle = "Status: \(lastLoginStatus)"
        let statusItem = NSMenuItem(title: statusTitle, action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        menu.addItem(statusItem)
        
        // Last login time
        if let lastTime = lastLoginTime {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            let timeString = formatter.string(from: lastTime)
            let timeItem = NSMenuItem(title: "Last: \(timeString)", action: nil, keyEquivalent: "")
            timeItem.isEnabled = false
            menu.addItem(timeItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Configure
        menu.addItem(NSMenuItem(title: "Configure...", action: #selector(showConfiguration), keyEquivalent: "c"))
        
        // Test Login
        menu.addItem(NSMenuItem(title: "Test Login Now", action: #selector(testLogin), keyEquivalent: "t"))
        
        menu.addItem(NSMenuItem.separator())
        
        // View Logs
        menu.addItem(NSMenuItem(title: "View Logs", action: #selector(viewLogs), keyEquivalent: "l"))
        
        menu.addItem(NSMenuItem.separator())
        
        // About
        menu.addItem(NSMenuItem(title: "About", action: #selector(showAbout), keyEquivalent: "a"))
        
        // Quit
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
    }
    
    // MARK: - Menu Actions
    
    /// Shows the configuration dialog
    @objc func showConfiguration() {
        let configurationAlert = NSAlert()
        configurationAlert.messageText = "Configure Website Login"
        configurationAlert.informativeText = "Enter the website URL and your credentials. These will be stored securely in your Keychain."
        configurationAlert.alertStyle = .informational
        
        // Create input fields
        let stackView = NSStackView(frame: NSRect(x: 0, y: 0, width: 400, height: 120))
        stackView.orientation = .vertical
        stackView.spacing = 8
        
        // URL field
        let urlLabel = NSTextField(labelWithString: "Website URL:")
        let urlField = NSTextField(frame: NSRect(x: 0, y: 0, width: 400, height: 24))
        urlField.placeholderString = "https://example.com/login"
        if let savedURL = UserDefaults.standard.string(forKey: "websiteURL") {
            urlField.stringValue = savedURL
        }
        
        // Username field
        let usernameLabel = NSTextField(labelWithString: "Username:")
        let usernameField = NSTextField(frame: NSRect(x: 0, y: 0, width: 400, height: 24))
        usernameField.placeholderString = "your-username"
        if let credentials = try? keychainManager.retrieveCredentials() {
            usernameField.stringValue = credentials.username
        }
        
        // Password field
        let passwordLabel = NSTextField(labelWithString: "Password:")
        let passwordField = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 400, height: 24))
        passwordField.placeholderString = "your-password"
        
        // Add to stack
        stackView.addArrangedSubview(urlLabel)
        stackView.addArrangedSubview(urlField)
        stackView.addArrangedSubview(usernameLabel)
        stackView.addArrangedSubview(usernameField)
        stackView.addArrangedSubview(passwordLabel)
        stackView.addArrangedSubview(passwordField)
        
        configurationAlert.accessoryView = stackView
        configurationAlert.addButton(withTitle: "Save")
        configurationAlert.addButton(withTitle: "Cancel")
        
        // Show alert
        let response = configurationAlert.runModal()
        
        if response == .alertFirstButtonReturn {
            // Save configuration
            let url = urlField.stringValue
            let username = usernameField.stringValue
            let password = passwordField.stringValue
            
            if !url.isEmpty && !username.isEmpty && !password.isEmpty {
                // Save URL
                UserDefaults.standard.set(url, forKey: "websiteURL")
                
                // Save credentials to keychain
                do {
                    try keychainManager.storeCredentials(username: username, password: password)
                    
                    let successAlert = NSAlert()
                    successAlert.messageText = "Configuration Saved"
                    successAlert.informativeText = "Your settings have been saved securely."
                    successAlert.alertStyle = .informational
                    successAlert.runModal()
                } catch {
                    let failureAlert = NSAlert()
                    failureAlert.messageText = "Failed to Save Credentials"
                    failureAlert.informativeText = error.localizedDescription
                    failureAlert.alertStyle = .critical
                    failureAlert.runModal()
                }
            } else {
                let validationAlert = NSAlert()
                validationAlert.messageText = "Invalid Input"
                validationAlert.informativeText = "Please fill in all fields."
                validationAlert.alertStyle = .warning
                validationAlert.runModal()
            }
        }
    }
    
    /// Tests the login immediately
    @objc func testLogin() {
        lastLoginStatus = "Testing..."
        updateMenu()
        
        Task {
            let success = await networkManager.performLogin()
            
            await MainActor.run {
                lastLoginStatus = success ? "Success ✓" : "Failed ✗"
                lastLoginTime = Date()
                updateMenu()
                
                // Show notification
                let notification = NSUserNotification()
                notification.title = "Login Test"
                notification.informativeText = success ? "Login successful" : "Login failed"
                notification.soundName = NSUserNotificationDefaultSoundName
                NSUserNotificationCenter.default.deliver(notification)
            }
        }
    }
    
    /// Opens the logs directory in Finder
    @objc func viewLogs() {
        let logDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/WebsiteLoginBot")
        NSWorkspace.shared.open(logDir)
    }
    
    /// Shows about dialog
    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Website Login Bot"
        alert.informativeText = "Version 1.0\n\nA macOS menu-bar application that automatically logs into websites using launchd scheduling.\n\n⚠️ Ensure you have permission to automate logins to your target website."
        alert.alertStyle = .informational
        alert.runModal()
    }
    
    /// Quits the application
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}
