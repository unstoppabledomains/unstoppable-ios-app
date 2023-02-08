//
//  TransactionsListViewModelTests.swift
//  domains-manager-iosTests
//
//  Created by Roman Medvid on 07.02.2021.
//

import XCTest
import PromiseKit
@testable import domains_manager_ios


class TransactionsStorageTests: XCTestCase {
    static let domainName1 = "01.crypto"

    static let id_1: UInt64 = 1
    static let hash_1 = "0x111111"
    
    static let timeout = 0.1

    var txsStorage: MockupTxsStorage?

    let tx1_with_id = TransactionItem(id: id_1,
                              transactionHash: nil,
                              domainName: domainName1,
                              isPending: true)
    let tx1_with_hash = TransactionItem(id: nil,
                              transactionHash: hash_1,
                              domainName: domainName1,
                              isPending: true)
    
    let tx_Reconciling_1_and_2 = TransactionItem(id: id_1,
                              transactionHash: hash_1,
                              domainName: domainName1,
                              isPending: true)

    
    let tx3 = TransactionItem(id: nil,
                              transactionHash: "0x2222222",
                              domainName: domainName1,
                              isPending: true)
    
    let tx3_Equal = TransactionItem(id: 2,
                              transactionHash: "0x2222222",
                              domainName: domainName1,
                              isPending: true)
    
    
    
    override func setUpWithError() throws {
        txsStorage = MockupTxsStorage()
    }
    
    
    override func tearDownWithError() throws {
        txsStorage = nil
    }
    
    
    
    func testInjectArrayOfTxs() {
        let ex = expectation(description: "InjectArrayOfTxs")
        
        let cache = [tx1_with_id, tx1_with_hash]
        txsStorage!.injectTxsUpdate(cache)
            .then {
                self.txsStorage!.getCachedTransactionsList(by: [DomainItem(name: Self.domainName1)]) }
            .done { txsArray in
                XCTAssertTrue(txsArray.count == 2)
                ex.fulfill()
            }
            .cauterize()
        waitForExpectations(timeout: Self.timeout)
    }
    
    func testInjectNotEqualTx() {
        let ex = expectation(description: "InjectNotEqualTx")
        
        let cache = [tx1_with_id, tx1_with_hash]
        txsStorage!.injectTxsUpdate(cache)
            .then { self.txsStorage!.injectTxsUpdate([self.tx3]) }
            .then { self.txsStorage!.getCachedTransactionsList(by: [DomainItem(name: Self.domainName1)])}
            .done { txsArray in
                XCTAssertTrue(txsArray.count == 3)
                ex.fulfill()
            }
            .cauterize()
        waitForExpectations(timeout: Self.timeout)
    }
    
    func testInjectEqualTx() {
        let ex = expectation(description: "InjectEqualTx")
        
        let cache = [tx1_with_id, tx1_with_hash]
        txsStorage!.injectTxsUpdate(cache)
            .then { self.txsStorage!.injectTxsUpdate([self.tx3]) }
            .then { self.txsStorage!.injectTxsUpdate([self.tx3_Equal]) }
            .then { self.txsStorage!.getCachedTransactionsList(by: [DomainItem(name: Self.domainName1)]) }
            .done { txsArray in
                XCTAssertTrue(txsArray.count == 3)
                ex.fulfill()
            }
            .cauterize()
        waitForExpectations(timeout: Self.timeout)
    }
    
    func testInjectReconcilingTx() {
        let ex = expectation(description: "InjectReconcilingTx")
        let cache = [tx1_with_id, tx1_with_hash]
        txsStorage!.injectTxsUpdate(cache)
            .then { self.txsStorage!.injectTxsUpdate([self.tx3]) }
            .then { self.txsStorage!.getCachedTransactionsList(by: [DomainItem(name: Self.domainName1)]) }
            .done { txsArray in
                XCTAssertTrue(txsArray.count == 3) }
            //                print(txsArray.count) }
            .then {
                self.txsStorage!.injectTxsUpdate([self.tx_Reconciling_1_and_2])
            }.done {
                self.txsStorage!.getCachedTransactionsList(by: [DomainItem(name: Self.domainName1)])
                    .done {
                        txsArray in
                        XCTAssertTrue(txsArray.count == 2)
                        ex.fulfill()
                    }.cauterize()
            }.cauterize()
        
        waitForExpectations(timeout: Self.timeout)
        
    }
    
    func testRemoveDuplicates() {
        let cache = [tx1_with_id, tx_Reconciling_1_and_2, tx3, tx3_Equal]
        let trimmed = MockupTxsStorage.removeDuplicates(for: [tx_Reconciling_1_and_2, tx3_Equal], _transactionCache: cache)
        XCTAssertTrue(trimmed.count == 2)
    }
}
    
class MockupTxsStorage: TxsStorage {
    var storedTxs: [TransactionItem] = []

    func getCachedTransactionsListSync(by domains: [DomainItem]) -> [TransactionItem] {
        return storedTxs
    }
    
    func getCachedTransactionsList(by domains: [DomainItem]) -> Promise<[TransactionItem]> {
        return Promise { seal in seal.fulfill(storedTxs) }
    }
    
    func injectTxsUpdate(_ newTxs: [TransactionItem]) -> Promise<Void> {
        guard newTxs.count > 0 else { return Promise {seal in seal.fulfill(()) } }
        return Promise { seal in
            let transactionCache = storedTxs
            let updatedTxsCache = MockupTxsStorage.inject(newTxs: newTxs, into: transactionCache)
            storedTxs = updatedTxsCache
            seal.fulfill(())
        }
    }
}
