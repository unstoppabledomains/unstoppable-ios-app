//
//  ResolutionInitTests.swift
//  domains-manager-iosTests
//
//  Created by Roman Medvid on 05.01.2022.
//

import XCTest
@testable import domains_manager_ios

class ResolutionInitTests: XCTestCase {
    func test_NetworksNames_Mainnet() throws {
        let netNames = NetworkConfig.getNetNames(env: .mainnet)
        XCTAssert(netNames.l1 == "mainnet", "Infura name for Ethereum must be 'mainnet'")
        XCTAssert(netNames.l2 == "polygon-mainnet", "Infura name for Polygon must be 'polygon-mainnet'")
    }
    
    func test_NetworksNames_Testnet() throws {
        let netNames = NetworkConfig.getNetNames(env: .testnet)
        XCTAssert(netNames.l1 == "goerli", "Infura name for Ethereum Testnet must be 'goerli'")
        XCTAssert(netNames.l2 == "polygon-mumbai", "Infura name for Polygon Testnet must be 'polygon-mumbai'")
    }
}
