//
//  TransactionsListViewModelTests.swift
//  domains-manager-iosTests
//
//  Created by Roman Medvid on 07.02.2021.
//

import XCTest
@testable import domains_manager_ios


class TransactionsStorageTests: XCTestCase {
    static let domainName1 = "01.crypto"

    static let id_1: UInt64 = 1
    static let hash_1 = "0x111111"
    
    static let timeout = 0.1

    var txsStorage: TxsStorage?

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
        let cache = [tx1_with_id, tx1_with_hash]
        txsStorage!.injectTxsUpdate_Blocking(cache)
        
        let txsArray = self.txsStorage!.getCachedTransactionsListSync(by: [DomainItem(name: Self.domainName1)])
        XCTAssertTrue(txsArray.count == 2)
    }
    
    func testInjectNotEqualTx() {
        let cache = [tx1_with_id, tx1_with_hash]
        txsStorage!.injectTxsUpdate_Blocking(cache)
        self.txsStorage!.injectTxsUpdate_Blocking([self.tx3])
        let txsArray = self.txsStorage!.getCachedTransactionsListSync(by: [DomainItem(name: Self.domainName1)])
        
        XCTAssertTrue(txsArray.count == 3)
    }
    
    func testInjectEqualTx() {
        let cache = [tx1_with_id, tx1_with_hash]
        txsStorage!.injectTxsUpdate_Blocking(cache)
        self.txsStorage!.injectTxsUpdate_Blocking([self.tx3])
        self.txsStorage!.injectTxsUpdate_Blocking([self.tx3_Equal])
        let txsArray = self.txsStorage!.getCachedTransactionsListSync(by: [DomainItem(name: Self.domainName1)])
        XCTAssertTrue(txsArray.count == 3)
    }
    
    func testInjectReconcilingTx() {
        let cache = [tx1_with_id, tx1_with_hash]
        txsStorage!.injectTxsUpdate_Blocking(cache)
        self.txsStorage!.injectTxsUpdate_Blocking([self.tx3])
        let txsArray1 = self.txsStorage!.getCachedTransactionsListSync(by: [DomainItem(name: Self.domainName1)])
        XCTAssertTrue(txsArray1.count == 3)
        
        self.txsStorage!.injectTxsUpdate_Blocking([self.tx_Reconciling_1_and_2])
        let txsArray2 = self.txsStorage!.getCachedTransactionsListSync(by: [DomainItem(name: Self.domainName1)])
        XCTAssertTrue(txsArray2.count == 2)
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
    
    func injectTxsUpdate_Blocking(_ newTxs: [TransactionItem]) {
        let transactionCache = storedTxs
        let updatedTxsCache = MockupTxsStorage.inject(newTxs: newTxs, into: transactionCache)
        storedTxs = updatedTxsCache
    }
}
