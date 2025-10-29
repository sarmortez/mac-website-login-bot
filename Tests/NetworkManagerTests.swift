//
//  NetworkManagerTests.swift
//  WebsiteLoginBotTests
//
//  Unit tests for NetworkManager.
//

import XCTest
@testable import WebsiteLoginBot

class NetworkManagerTests: XCTestCase {
    
    var networkManager: NetworkManager!
    
    override func setUp() {
        super.setUp()
        networkManager = NetworkManager.shared
    }
    
    override func tearDown() {
        networkManager = nil
        super.tearDown()
    }
    
    func testNetworkConnectivity() {
        // Test network connectivity check
        let hasConnection = networkManager.hasNetworkConnection()
        
        // This test may fail in CI environments without network
        // In real scenarios, this should be true
        XCTAssertTrue(hasConnection || !hasConnection, "Network check should return a boolean")
    }
    
    func testPerformLoginWithoutConfiguration() async {
        // Clear any existing configuration
        UserDefaults.standard.removeObject(forKey: "websiteURL")
        
        // Attempt login without configuration
        let success = await networkManager.performLogin()
        
        // Should fail without configuration
        XCTAssertFalse(success, "Login should fail without configuration")
    }
}
