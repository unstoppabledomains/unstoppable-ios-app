//
//  AddWalletUITests.swift
//  domains-manager-iosUITests
//
//  Created by Oleg Kuplin on 31.08.2022.
//

import Foundation
import XCTest

class AddWalletUITests: BaseXCTestCase {
    
    private lazy var walletsToUse: [TestsEnvironment.TestWalletDescription] = {
        [.init(type: "mnemonicsEntered", name: nil, hasBeenBackedUp: true, isExternal: false)]
    }()
    
    override var launchEnvironment: [String : String] { [TestsEnvironment.numberOfDomains.rawValue : "0",
                                                         TestsEnvironment.wallets.rawValue : TestsEnvironment.TestWalletDescription.groupedWalletsStr(from: walletsToUse)] }
    
    func openAddWalletSelection() {
        NavigationRobot(app)
            .openWalletsList()
        
        WalletsListRobot(app)
            .tapPlusButton()
    }
    
    func back() {
        Robot(app)
            .tap(app.buttons["Add Wallet Navigation Back Button"])
    }
    
}

final class AddUDWalletUITests: AddWalletUITests {
    private func createUDWallet() {
        openAddWalletSelection()
        
        PullUpRobot(app)
            .tapOnCellWith(name: "Create vault")
    }
    
    func testCreateAndCancelUDWallet() {
        createUDWallet()
        back()
        WalletsListRobot(app)
            .ensureNumberOfCells(1)
    }
}
