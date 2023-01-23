//
//  DomainDetailsViewControllerTests.swift
//  domains-manager-iosTests
//
//  Created by Roman on 28.01.2021.
//

import XCTest
@testable import domains_manager_ios

class DomainDetailsViewControllerTests: XCTestCase {

    let domainName = "will-goerli-1.nft"
    let maticMaticTicker = "crypto.MATIC.version.MATIC.address"
    let maticErc20Ticker = "crypto.MATIC.version.ERC20.address"
    let ethTicker = "crypto.ETH.address"
    let setAddress = "0xcecc2a18250a74eb536980d469662a4ddb66b393".lowercased()

    func test_FetchingRecords() async throws {
        let domain = DomainItem(name: domainName)
        let records = try await DomainRecordsService().getRecordsFor(domain: domain).records
        
        guard records.count == 3 else {
            XCTAssertEqual(records.count, 3)
            return
        }
        
        let maticMaticAddressDetected = records.filter({$0.coin.expandedTicker == self.maticMaticTicker})[0].address.lowercased()
        let maticErc20ddressDetected = records.filter({$0.coin.expandedTicker == self.maticErc20Ticker})[0].address.lowercased()
        let ethAddressDetected = records.filter({$0.coin.expandedTicker == self.ethTicker})[0].address.lowercased()
        XCTAssert(maticMaticAddressDetected == self.setAddress, "\(self.domainName) is expected to have \(self.maticMaticTicker) as \(self.setAddress)")
        XCTAssert(maticErc20ddressDetected == self.setAddress, "\(self.domainName) is expected to have \(self.maticErc20Ticker) as \(self.setAddress)")
        XCTAssert(ethAddressDetected == self.setAddress, "\(self.domainName) is expected to have \(self.ethTicker) as \(self.setAddress)")
    }
}
