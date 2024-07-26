//
//  SupportedTokensTests.swift
//  domains-manager-iosTests
//
//  Created by Roman Medvid on 16.07.2024.
//

import XCTest
@testable import domains_manager_ios

final class SupportedTokensTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testUSDCMainnetValue() throws {
        let bundler = Bundle.main
        let filePath = bundler.url(forResource: "supported-tokens", withExtension: "json")!
        let data = try! Data(contentsOf: filePath)
        print(String(data: data, encoding: .utf8)!)
        let tokensInfo = try! CryptoSender.SupportedToken.getContractArray()
        let usdc = tokensInfo[.usdc]![.Ethereum]!.mainnet
        XCTAssertEqual(usdc, "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48")
    }
}
