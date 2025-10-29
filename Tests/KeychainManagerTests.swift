//
//  KeychainManagerTests.swift
//  WebsiteLoginBotTests
//
//  Unit tests for KeychainManager.
//

import XCTest
@testable import WebsiteLoginBot

class KeychainManagerTests: XCTestCase {
    
    var keychainManager: KeychainManager!
    let testUsername = "testuser"
    let testPassword = "testpass123"
    
    override func setUp() {
        super.setUp()
        keychainManager = KeychainManager.shared
        
        // Clean up any existing test credentials
        try? keychainManager.deleteCredentials()
    }
    
    override func tearDown() {
        // Clean up after tests
        try? keychainManager.deleteCredentials()
        keychainManager = nil
        super.tearDown()
    }
    
    func testStoreAndRetrieveCredentials() {
        // Store credentials
        XCTAssertNoThrow(try keychainManager.storeCredentials(username: testUsername, password: testPassword))
        
        // Retrieve credentials
        do {
            let credentials = try keychainManager.retrieveCredentials()
            XCTAssertEqual(credentials.username, testUsername)
            XCTAssertEqual(credentials.password, testPassword)
        } catch {
            XCTFail("Failed to retrieve credentials: \(error)")
        }
    }
    
    func testHasCredentials() {
        // Initially should not have credentials
        XCTAssertFalse(keychainManager.hasCredentials())
        
        // Store credentials
        try? keychainManager.storeCredentials(username: testUsername, password: testPassword)
        
        // Now should have credentials
        XCTAssertTrue(keychainManager.hasCredentials())
    }
    
    func testDeleteCredentials() {
        // Store credentials
        try? keychainManager.storeCredentials(username: testUsername, password: testPassword)
        XCTAssertTrue(keychainManager.hasCredentials())
        
        // Delete credentials
        XCTAssertNoThrow(try keychainManager.deleteCredentials())
        
        // Should not have credentials anymore
        XCTAssertFalse(keychainManager.hasCredentials())
    }
    
    func testUpdateCredentials() {
        // Store initial credentials
        try? keychainManager.storeCredentials(username: testUsername, password: testPassword)
        
        // Update credentials
        let newUsername = "newuser"
        let newPassword = "newpass456"
        XCTAssertNoThrow(try keychainManager.updateCredentials(username: newUsername, password: newPassword))
        
        // Verify updated credentials
        do {
            let credentials = try keychainManager.retrieveCredentials()
            XCTAssertEqual(credentials.username, newUsername)
            XCTAssertEqual(credentials.password, newPassword)
        } catch {
            XCTFail("Failed to retrieve updated credentials: \(error)")
        }
    }
    
    func testRetrieveNonExistentCredentials() {
        // Ensure no credentials exist
        try? keychainManager.deleteCredentials()
        
        // Attempt to retrieve should throw
        XCTAssertThrowsError(try keychainManager.retrieveCredentials()) { error in
            XCTAssertTrue(error is KeychainManager.KeychainError)
        }
    }
}
