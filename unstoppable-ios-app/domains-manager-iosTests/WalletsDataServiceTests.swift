//
//  WalletsDataServiceTests.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 11.03.2024.
//

import XCTest
@testable import domains_manager_ios
import Combine

final class WalletsDataServiceTests: BaseTestClass {
    private var networkService = MockNetworkService()
    private var udDomainsService = TestableUDDomainsService()
    private var udWalletsService = TestableUDWalletsService()
    private var domainTransactionService = TestableDomainTransactionsService()
    private var walletConnectService = TestableWalletConnectServiceV2()
    private var walletNFTsService = TestableWalletNFTsService()
    private var walletsDataService: WalletsDataService!
    
    override func setUp() async throws {
        networkService = MockNetworkService()
        udDomainsService = TestableUDDomainsService()
        udWalletsService = TestableUDWalletsService()
        domainTransactionService = TestableDomainTransactionsService()
        walletConnectService = TestableWalletConnectServiceV2()
        walletNFTsService = TestableWalletNFTsService()
        walletsDataService = WalletsDataService(domainsService: udDomainsService,
                                                walletsService: udWalletsService,
                                                transactionsService: domainTransactionService,
                                                walletConnectServiceV2: walletConnectService,
                                                walletNFTsService: walletNFTsService,
                                                networkService: networkService)
    }
    
}

// MARK: - Open methods
extension WalletsDataServiceTests {
    func testSubscribedToUDWalletsService() {
        XCTAssertTrue(udWalletsService.listeners[0] === walletsDataService)
    }
    
    func testWalletsListSyncOnLaunch() {
        XCTAssertEqual(Set(udWalletsService.wallets.map { $0.address }), Set(walletsDataService.wallets.map { $0.address }))
    }
    
    func testSelectedWalletNotAssignedAutomatically() {
        XCTAssertNil(walletsDataService.selectedWallet)
    }
    
    func testRecordsAPICalledDuringSetup() async {
        let wallet = await setSelectedWalletInService()
        XCTAssertEqual(networkService.getRecordsCalledNames, [wallet.profileDomainName!])
    }
    
    func testNoAdditionalWalletsRequestsMadeIfNoRecords() async {
        networkService.recordsToReturn = [:]
        let wallet = await setSelectedWalletInService()
        XCTAssertEqual(networkService.calledAddresses, [wallet.address])
    }
    
    func testNoAdditionalWalletsRequestsIfUnknownRecords() async {
        networkService.recordsToReturn = ["com.unknownAddress" : "123"]
        let wallet = await setSelectedWalletInService()
        XCTAssertEqual(networkService.calledAddresses, [wallet.address])
    }
    
    func testAdditionalRequestsMadeForOnlyPresentedRecords() async {
        let value = "123"
        networkService.recordsToReturn = [Constants.additionalSupportedTokens[0] : value]
        let wallet = await setSelectedWalletInService()
        XCTAssertEqual(networkService.calledAddresses, [wallet.address, value])
    }
    
    func testAdditionalRequestsMadeForAllPresentedRecords() async {
        networkService.recordsToReturn.removeAll()
        let additionalSupportedTokens = Constants.additionalSupportedTokens
        var expectedCalls = [String]()
        for i in 0..<additionalSupportedTokens.count {
            let value = String(i)
            let token = additionalSupportedTokens[i]
            networkService.recordsToReturn[token] = value
            expectedCalls.append(value)
        }
        let wallet = await setSelectedWalletInService()
        XCTAssertEqual(Set(networkService.calledAddresses), Set([wallet.address] + expectedCalls))
    }
}

// MARK: - Private methods
private extension WalletsDataServiceTests {
    @discardableResult
    func setSelectedWalletInService(withRRDomain: Bool = true) async -> WalletEntity {
        let wallet = walletsDataService.wallets.first!
        if withRRDomain {
            let mockDomains = MockEntitiesFabric.Domains.mockDomainsItems(ownerWallet: wallet.address)
            udDomainsService.domainsToReturn = mockDomains
            udWalletsService.rrDomainNamePerWallet[wallet.address] = mockDomains[0].name
        }
        walletsDataService.setSelectedWallet(wallet)
        await Task.sleep(seconds: 0.3)
        return wallet
    }
}

private final class MockNetworkService: WalletsDataNetworkServiceProtocol, FailableService {
    
    var recordsToReturn: [String : String] = [:]
    var shouldFail = false
    var error: TestableGenericError { TestableGenericError.generic }
    var calledAddresses: [String] = []
    var getRecordsCalledNames: [String] = []
    let serialQueue = DispatchQueue(label: "com.mock.network")
  
    func fetchCryptoPortfolioFor(wallet: String) async throws -> [WalletTokenPortfolio] {
        try failIfNeeded()
        serialQueue.sync {
            calledAddresses.append(wallet)
        }
        return []
    }
    
    func fetchProfileRecordsFor(domainName: String) async throws -> [String : String] {
        try failIfNeeded()

        serialQueue.sync {
            getRecordsCalledNames.append(domainName)
        }
        return serialQueue.sync { recordsToReturn }
    }
}
