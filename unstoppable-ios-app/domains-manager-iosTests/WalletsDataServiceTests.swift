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
    private var udDomainsService = TestableUDDomainsService()
    private var udWalletsService = TestableUDWalletsService()
    private var domainTransactionService = TestableDomainTransactionsService()
    private var walletConnectService = TestableWalletConnectServiceV2()
    private var walletNFTsService = TestableWalletNFTsService()
    private var walletsDataService: WalletsDataService!
    
    override func setUp() async throws {
        udDomainsService = TestableUDDomainsService()
        udWalletsService = TestableUDWalletsService()
        domainTransactionService = TestableDomainTransactionsService()
        walletConnectService = TestableWalletConnectServiceV2()
        walletNFTsService = TestableWalletNFTsService()
        walletsDataService = WalletsDataService(domainsService: udDomainsService,
                                                walletsService: udWalletsService,
                                                transactionsService: domainTransactionService,
                                                walletConnectServiceV2: walletConnectService,
                                                walletNFTsService: walletNFTsService)
    }
    
}
