//
//  WalletAutonamingTests.swift
//  domains-manager-iosTests
//
//  Created by Roman on 05.05.2022.
//

import XCTest
@testable import domains_manager_ios

class WalletAutonamingTests: XCTestCase {

    func testParseIndices() throws {
        let names = ["Wallet 1", "Wallet 2",
                     "Wallet 4", "Wallet 10", "Wallet 11"]
                    .map({$0.trimmedSpaces})
        let indices = names.getIndices(startingWith: "Wallet")
        
        XCTAssert(indices.contains(1))
        XCTAssert(indices.contains(2))
        XCTAssert(indices.contains(4))
        XCTAssert(indices.contains(10))
        XCTAssert(indices.contains(11))
        
        XCTAssert(indices.count == 5)
    }
    
    func testParseIndices2() throws {
        let names = ["Cryo1", "Wallet 2",
                     "Wallet    4", "Wallet s10",
                     "Wallet 11-", "Waller 20"]
                    .map({$0.trimmedSpaces})
        let indices = names.getIndices(startingWith: "Wallet")
        
        XCTAssert(indices.contains(2))
        XCTAssert(indices.contains(4))
        
        XCTAssert(indices.count == 2)
    }
    
    func testParseIndices_PrefixNoIndex() throws {
        let names = ["Wallet", "Cryo1", "Wallet 2",
                     "Wallet    4", "Wallet s10",
                     "Wallet 11-", "Waller 20"]
                    .map({$0.trimmedSpaces})
        let index = UDWalletsStorage.getLowestUnoccupiedIndex(startingWith: "Wallet", from: names)
        
        XCTAssert(index == 3)
    }
    
    func testLowestIndex() throws {
        let names = ["Wallet 1", "Wallet 2", "Wallet 4",
                     "Wallet 10", "Wallet 11"]
                    .map({$0.trimmedSpaces})
        let indices = names.getIndices(startingWith: "Wallet")
        let lowest = indices.getLowestUnoccupiedInt()
        
        XCTAssert(lowest == 3)
    }

    func testLowestIndex2() throws {
        let names = ["Wallet 0", "Wallet 2", "Wallet 4",
                     "Wallet 10", "Wallet 11"]
                    .map({$0.trimmedSpaces})
        let indices = names.getIndices(startingWith: "Wallet")
        let lowest = indices.getLowestUnoccupiedInt()
        
        XCTAssert(lowest == 1)
    }
    
    func testLowestIndex_PrefixNoIndex() throws {
        let names = ["Wallet", "Wallet 2", "Wallet 3",
                     "Wallet 10", "Wallet 11"]
                    .map({$0.trimmedSpaces})
        let lowest = UDWalletsStorage.getLowestUnoccupiedIndex(startingWith: "Wallet", from: names)
        
        XCTAssert(lowest == 4)
    }

}
