//
//  KeychainManager.swift
//  WebsiteLoginBot
//
//  Manages secure storage and retrieval of credentials using macOS Keychain.
//

import Foundation
import Security

class KeychainManager {
    
    // MARK: - Singleton
    
    static let shared = KeychainManager()
    
    private init() {}
    
    // MARK: - Properties
    
    private let service = "com.websiteloginbot.credentials"
    private let usernameKey = "username"
    private let passwordKey = "password"
    
    // MARK: - Credentials Structure
    
    struct Credentials {
        let username: String
        let password: String
    }
    
    // MARK: - Error Types
    
    enum KeychainError: Error, LocalizedError {
        case itemNotFound
        case duplicateItem
        case invalidData
        case unexpectedStatus(OSStatus)
        
        var errorDescription: String? {
            switch self {
            case .itemNotFound:
                return "Credentials not found in Keychain"
            case .duplicateItem:
                return "Credentials already exist in Keychain"
            case .invalidData:
                return "Invalid credential data"
            case .unexpectedStatus(let status):
                return "Keychain error: \(status)"
            }
        }
    }
    
    // MARK: - Store Credentials
    
    /// Stores credentials securely in the macOS Keychain
    /// - Parameters:
    ///   - username: The username to store
    ///   - password: The password to store
    /// - Throws: KeychainError if the operation fails
    func storeCredentials(username: String, password: String) throws {
        // First, try to delete existing credentials
        try? deleteCredentials()
        
        // Store username
        try storeItem(key: usernameKey, value: username)
        
        // Store password
        try storeItem(key: passwordKey, value: password)
    }
    
    /// Stores a single item in the Keychain
    private func storeItem(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            throw KeychainError.duplicateItem
        } else if status != errSecSuccess {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    // MARK: - Retrieve Credentials
    
    /// Retrieves credentials from the macOS Keychain
    /// - Returns: Credentials structure with username and password
    /// - Throws: KeychainError if credentials cannot be retrieved
    func retrieveCredentials() throws -> Credentials {
        let username = try retrieveItem(key: usernameKey)
        let password = try retrieveItem(key: passwordKey)
        
        return Credentials(username: username, password: password)
    }
    
    /// Retrieves a single item from the Keychain
    private func retrieveItem(key: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            throw KeychainError.itemNotFound
        } else if status != errSecSuccess {
            throw KeychainError.unexpectedStatus(status)
        }
        
        guard let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        
        return value
    }
    
    // MARK: - Delete Credentials
    
    /// Deletes all stored credentials from the Keychain
    /// - Throws: KeychainError if deletion fails
    func deleteCredentials() throws {
        try deleteItem(key: usernameKey)
        try deleteItem(key: passwordKey)
    }
    
    /// Deletes a single item from the Keychain
    private func deleteItem(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        // Ignore "item not found" errors during deletion
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    // MARK: - Update Credentials
    
    /// Updates existing credentials in the Keychain
    /// - Parameters:
    ///   - username: New username
    ///   - password: New password
    /// - Throws: KeychainError if update fails
    func updateCredentials(username: String, password: String) throws {
        // Delete and re-add (simpler than updating)
        try deleteCredentials()
        try storeCredentials(username: username, password: password)
    }
    
    // MARK: - Validation
    
    /// Checks if credentials exist in the Keychain
    /// - Returns: True if credentials exist, false otherwise
    func hasCredentials() -> Bool {
        do {
            _ = try retrieveCredentials()
            return true
        } catch {
            return false
        }
    }
}
