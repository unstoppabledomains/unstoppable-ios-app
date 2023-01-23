//
//  UnsConfigManagerTests.swift
//  domains-manager-iosTests
//
//  Created by Roman on 28.12.2021.
//

import XCTest
@testable import domains_manager_ios

class UnsConfigManagerTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func test_getBlockchainType_Ethereum() throws {
        let ethereumMainnet = try! UnsConfigManager.getBlockchainType(from: 1)
        XCTAssert(ethereumMainnet == .Ethereum, "1 is Ethereum mainnet")
        
        let ethereumTestnet = try! UnsConfigManager.getBlockchainType(from: 5)
        XCTAssert(ethereumTestnet == .Ethereum, "5 is Ethereum testnet")
    }
    
    func test_getBlockchainType_Polygon() throws {
        let polygonMainnet = try! UnsConfigManager.getBlockchainType(from: 137)
        XCTAssert(polygonMainnet == .Matic, "137 is Polygon mainnet")
        
        let polygonTestnet = try! UnsConfigManager.getBlockchainType(from: 80001)
        XCTAssert(polygonTestnet == .Matic, "80001 is Polygon testnet")
    }
}
