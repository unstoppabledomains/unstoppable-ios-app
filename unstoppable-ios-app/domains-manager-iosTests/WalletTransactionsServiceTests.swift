//
//  WalletTransactionsServiceTests.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 27.03.2024.
//

import Foundation
import XCTest
@testable import domains_manager_ios

final class WalletTransactionsServiceTests: XCTestCase, WalletDataValidator {
    
    private let wallet = "0x397ab335485c15be06deb7a64fd87ec93da836ee3ab189441f71d51e93bf7ce0"
    private var networkService: MockNetworkService!
    private var cache: MockCache!
    private var service: WalletTransactionsService!
    
    override func setUp() async throws {
        networkService = MockNetworkService()
        cache = MockCache()
        service = WalletTransactionsService(networkService: networkService, 
                                            cache: cache)
    }
    
}

// MARK: - Can load more
extension WalletTransactionsServiceTests {
    func testCanLoadMoreIfEmptyResponse() async throws {
        networkService.expectedResponse = []
        let transactionsResponse = try await service.getTransactionsFor(wallet: wallet, forceReload: false)
        
        XCTAssertEqual(transactionsResponse.canLoadMore, false)
    }
    
    func testCanLoadMoreIfAllCursorsNil() async throws {
        let expectedResponse: [WalletTransactionsPerChainResponse] = [
            WalletTransactionsPerChainResponse(chain: "ETH", cursor: nil, txs: []),
            WalletTransactionsPerChainResponse(chain: "MATIC", cursor: nil, txs: [])
        ]
        networkService.expectedResponse = expectedResponse
        let transactionsResponse = try await service.getTransactionsFor(wallet: wallet, forceReload: false)
        
        XCTAssertEqual(transactionsResponse.canLoadMore, false)
    }
    
    func testCanLoadMoreIfNotAllCursorsNil() async throws {
        let expectedResponse: [WalletTransactionsPerChainResponse] = [
            WalletTransactionsPerChainResponse(chain: "ETH", cursor: "1", txs: []),
            WalletTransactionsPerChainResponse(chain: "MATIC", cursor: nil, txs: [])
        ]
        networkService.expectedResponse = expectedResponse
        let transactionsResponse = try await service.getTransactionsFor(wallet: wallet, forceReload: false)
        
        XCTAssertEqual(transactionsResponse.canLoadMore, true)
    }
}

// MARK: - Network requests
extension WalletTransactionsServiceTests {
    func testNumberOfRequestsForFirstLoad() async throws {
        _ = try await service.getTransactionsFor(wallet: wallet, forceReload: false)
        
        XCTAssertEqual(networkService.requests, [.init(wallet: wallet, cursor: nil, chain: nil)])
    }
    
    func testRequestsWhenNoCacheForceReload() async throws {
        _ = try await service.getTransactionsFor(wallet: wallet, forceReload: true)
        
        XCTAssertEqual(networkService.requests, [.init(wallet: wallet, cursor: nil, chain: nil)])
    }
    
    func testRequestsWhenNoCacheNotForceReload() async throws {
        _ = try await service.getTransactionsFor(wallet: wallet, forceReload: false)
        
        XCTAssertEqual(networkService.requests, [.init(wallet: wallet, cursor: nil, chain: nil)])
    }
    
    func testRequestsWhenHasCachedNoCursorForceReload() async throws {
        let expectedResponse: [WalletTransactionsPerChainResponse] = [
            WalletTransactionsPerChainResponse(chain: "ETH", cursor: nil, txs: []),
            WalletTransactionsPerChainResponse(chain: "MATIC", cursor: nil, txs: [])
        ]
        cache.cache[wallet] = expectedResponse
        _ = try await service.getTransactionsFor(wallet: wallet, forceReload: true)
        
        XCTAssertEqual(networkService.requests, [.init(wallet: wallet, cursor: nil, chain: nil)])
    }
    
    func testRequestsWhenHasCachedNoCursorNotForceReload() async throws {
        let expectedResponse: [WalletTransactionsPerChainResponse] = [
            WalletTransactionsPerChainResponse(chain: "ETH", cursor: nil, txs: []),
            WalletTransactionsPerChainResponse(chain: "MATIC", cursor: nil, txs: [])
        ]
        cache.cache[wallet] = expectedResponse
        _ = try await service.getTransactionsFor(wallet: wallet, forceReload: false)
        
        XCTAssertEqual(networkService.requests, [])
    }
    
    func testRequestsWhenHasCachedWithCursorForceReload() async throws {
        let expectedResponse: [WalletTransactionsPerChainResponse] = [
            WalletTransactionsPerChainResponse(chain: "ETH", cursor: "1", txs: []),
            WalletTransactionsPerChainResponse(chain: "MATIC", cursor: nil, txs: [])
        ]
        cache.cache[wallet] = expectedResponse
        _ = try await service.getTransactionsFor(wallet: wallet, forceReload: true)
        
        XCTAssertEqual(networkService.requests, [.init(wallet: wallet, cursor: nil, chain: nil)])
    }
    
    func testRequestsWhenHasCachedWithCursorNotForceReload() async throws {
        let expectedResponse: [WalletTransactionsPerChainResponse] = [
            WalletTransactionsPerChainResponse(chain: "ETH", cursor: "1", txs: []),
            WalletTransactionsPerChainResponse(chain: "MATIC", cursor: nil, txs: [])
        ]
        cache.cache[wallet] = expectedResponse
        _ = try await service.getTransactionsFor(wallet: wallet, forceReload: false)
        
        XCTAssertEqual(networkService.requests, [.init(wallet: wallet, cursor: "1", chain: "ETH")])
    }
}

// MARK: - Response
extension WalletTransactionsServiceTests {
    func testTxsResponseNoCache() async throws {
        let txs = createMockTxs()
        let expectedResponse: [WalletTransactionsPerChainResponse] = [
            WalletTransactionsPerChainResponse(chain: "ETH", cursor: "1", txs: txs)
        ]
        networkService.expectedResponse = expectedResponse
        let transactionsResponse = try await service.getTransactionsFor(wallet: wallet, forceReload: false)
        isSameTxs(txs, transactionsResponse.txs)
    }
    
    func testTxsResponseWithCacheNoCursor() async throws {
        let txs = createMockTxs()
        let expectedResponse: [WalletTransactionsPerChainResponse] = [
            WalletTransactionsPerChainResponse(chain: "ETH", cursor: nil, txs: txs)
        ]
        cache.cache[wallet] = expectedResponse
        let transactionsResponse = try await service.getTransactionsFor(wallet: wallet, forceReload: false)
        isSameTxs(txs, transactionsResponse.txs)
    }
    
    func testTxsResponseWithCacheWithCursorNoForceReload() async throws {
        let txs = createMockTxs()
        let newTxs = createMockTxs(range: 4...6)
        let cachedResponse: [WalletTransactionsPerChainResponse] = [
            WalletTransactionsPerChainResponse(chain: "ETH", cursor: "1", txs: txs)
        ]
        cache.cache[wallet] = cachedResponse
        let networkResponse = [
            WalletTransactionsPerChainResponse(chain: "ETH", cursor: nil, txs: newTxs)
        ]
        networkService.expectedResponse = networkResponse
        
        let transactionsResponse = try await service.getTransactionsFor(wallet: wallet, forceReload: false)
        isSameTxs(txs + newTxs, transactionsResponse.txs)
    }
    
    func testTxsResponseWithCacheWithCursorForceReload() async throws {
        let txs = createMockTxs()
        let newTxs = createMockTxs(range: 4...6)
        let cachedResponse: [WalletTransactionsPerChainResponse] = [
            WalletTransactionsPerChainResponse(chain: "ETH", cursor: "1", txs: txs)
        ]
        cache.cache[wallet] = cachedResponse
        let networkResponse = [
            WalletTransactionsPerChainResponse(chain: "ETH", cursor: nil, txs: newTxs)
        ]
        networkService.expectedResponse = networkResponse
        
        let transactionsResponse = try await service.getTransactionsFor(wallet: wallet, forceReload: true)
        isSameTxs(newTxs, transactionsResponse.txs)
    }
    
    func testTxsResponseMerged() async throws {
        let txs = createMockTxs(range: 1...3)
        let newTxs = createMockTxs(range: 2...4)
        let cachedResponse: [WalletTransactionsPerChainResponse] = [
            WalletTransactionsPerChainResponse(chain: "ETH", cursor: "1", txs: txs)
        ]
        cache.cache[wallet] = cachedResponse
        let networkResponse = [
            WalletTransactionsPerChainResponse(chain: "ETH", cursor: nil, txs: newTxs)
        ]
        networkService.expectedResponse = networkResponse
        
        let transactionsResponse = try await service.getTransactionsFor(wallet: wallet, forceReload: false)
        isSameTxsIds((1...4).map { String($0)}, transactionsResponse.txs.map { $0.id })
    }
}

// MARK: - Private methods
private extension WalletTransactionsServiceTests {
    func createMockTxs(range: ClosedRange<Int> = 1...3) -> [SerializedWalletTransaction] {
        MockEntitiesFabric.WalletTxs.createMockEmptyTxs(range: range)
    }
    
    func isSameTxs(_ lhsTxs: [SerializedWalletTransaction], _ rhsTxs: [SerializedWalletTransaction]) {
        isSameTxsIds(lhsTxs.map { $0.id }, rhsTxs.map { $0.id })
    }
    
    func isSameTxsIds(_ lhsTxs: [String], _ rhsTxs: [String]) {
        XCTAssertEqual(lhsTxs.sorted(), rhsTxs.sorted())
    }
}

private final class MockNetworkService: WalletTransactionsNetworkServiceProtocol, FailableService {
    var expectedResponse: [WalletTransactionsPerChainResponse] = []
    var shouldFail: Bool = false
    var requests = [Request]()
    
    func getTransactionsFor(wallet: HexAddress, cursor: String?, chain: String?) async throws -> [WalletTransactionsPerChainResponse] {
        requests.append(.init(wallet: wallet, cursor: cursor, chain: chain))
        try failIfNeeded()
        return expectedResponse
    }
    
    struct Request: Hashable {
        let wallet: HexAddress
        let cursor: String?
        let chain: String?
    }
}

private final class MockCache: WalletTransactionsCacheProtocol {
    var cache: [String: [WalletTransactionsPerChainResponse]] = [:]
    
    func fetchTransactionsFromCache(wallet: HexAddress) async -> [WalletTransactionsPerChainResponse]? {
        cache[wallet]
    }
    
    func setTransactionsToCache(_ txs: [WalletTransactionsPerChainResponse], for wallet: HexAddress) async {
        cache[wallet] = txs
    }
}
