//
//  TransactionsDecodingTests.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 10.06.2022.
//

import XCTest
@testable import domains_manager_ios

class TransactionsDecodingTests: XCTestCase {

    func testDecodingTxResponseSuccess() throws {
        let transactionResponseJSON = self.transcationResponseJSON()
        
        let transaction = NetworkService.TxResponse.objectFromJSON(transactionResponseJSON)
        XCTAssertNotNil(transaction)
        XCTAssertEqual(transaction?.operation, .chainLink)
    }

    func testDecodingTxResponseOperationFailed() throws {
        var transactionResponseJSON = self.transcationResponseJSON()
        transactionResponseJSON["operation"] = "smthing_invalid"
        
        let transaction = NetworkService.TxResponse.objectFromJSON(transactionResponseJSON)
        XCTAssertNil(transaction)
    }

}

// MARK: - Private methods
private extension TransactionsDecodingTests {
    func transcationResponseJSON() -> [String : Any] {
        ["id" : 10,
         "type" : TxType.maticTx.rawValue,
         "operation" : TxOperation.chainLink.rawValue,
         "statusGroup" : "st",
         "hash" : "",
         "domain" : dominResponseJSON()]
    }
    
    func dominResponseJSON() -> [String : Any] {
        ["id" : 1,
         "name" : "Name",
         "ownerAddress" : ""]
    }
}
