//
//  WalletsListUITests.swift
//  domains-manager-iosUITests
//
//  Created by Oleg Kuplin on 30.08.2022.
//

import Foundation
import XCTest

final class WalletsListUITests: BaseXCTestCase {
    
    private lazy var walletsToUse: [TestsEnvironment.TestWalletDescription] = {
        [.init(type: "generatedLocally", name: "Vault", hasBeenBackedUp: true, isExternal: false),
         .init(type: "mnemonicsEntered", name: nil, hasBeenBackedUp: true, isExternal: false),
         .init(type: "privateKeyEntered", name: nil, hasBeenBackedUp: false, isExternal: false),
         .init(type: "importedUnverified", name: "Rainbow", hasBeenBackedUp: false, isExternal: true)]
    }()
    override var launchEnvironment: [String : String] { [TestsEnvironment.numberOfDomains.rawValue : "0",
                                                         TestsEnvironment.wallets.rawValue : TestsEnvironment.TestWalletDescription.groupedWalletsStr(from: walletsToUse)] }
    
    func testInitialState() {
        NavigationRobot(app)
            .openWalletsList()
        
        WalletsListRobot(app)
            .ensurePlusButton(visible: true)
            .ensureNumberOfCells(walletsToUse.count)
            .assertTextExists(["Managed ･ 3", "Connected ･ 1"])
    }
    
}
