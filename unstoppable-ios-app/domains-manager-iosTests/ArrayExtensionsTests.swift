//
//  ArrayExtensionsTests.swift
//  domains-manager-iosTests
//
//  Created by Roman Medvid on 21.01.2022.
//

import XCTest
@testable import domains_manager_ios

class ArrayExtensionsTests: XCTestCase {
    
    let allTlds = AppVersionInfo().tlds
    
    func testSqueezeTlds() throws {
        let tlds1 = ["wallet"]
        let array1 = allTlds.squeeze(to: Set(tlds1))
        XCTAssert(array1 == ["wallet"])
        
        let tlds2 = ["888", "dao", "x"]
        let array2 = allTlds.squeeze(to: Set(tlds2))
        XCTAssert(array2 == ["x", "888", "dao"])
                                                              
                                                              
        let tlds3 = ["dao", "zil", "nft"]
        let array3 = allTlds.squeeze(to: Set(tlds3))
        XCTAssert(array3 == ["nft", "dao", "zil"])
        
        let tlds4 = ["888", "bitcoin", "nft", "crypto"]
        let array4 = allTlds.squeeze(to: Set(tlds4))
        XCTAssert(array4 == ["crypto", "bitcoin", "888", "nft"])
    }
}
