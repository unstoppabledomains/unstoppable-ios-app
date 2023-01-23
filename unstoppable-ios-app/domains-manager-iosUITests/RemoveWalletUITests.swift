//
//  WalletInteractionUITests.swift
//  domains-manager-iosUITests
//
//  Created by Oleg Kuplin on 31.08.2022.
//

import Foundation

final class SuccessRemoveWalletUITest: BaseXCTestCase {
    
    private lazy var walletsToUse: [TestsEnvironment.TestWalletDescription] = {
        [.init(type: "generatedLocally", name: "Vault", hasBeenBackedUp: true, isExternal: false),
         .init(type: "mnemonicsEntered", name: nil, hasBeenBackedUp: true, isExternal: false),
         .init(type: "privateKeyEntered", name: nil, hasBeenBackedUp: false, isExternal: false),
         .init(type: "importedUnverified", name: "Rainbow", hasBeenBackedUp: false, isExternal: true)]
    }()
    override var launchEnvironment: [String : String] { [TestsEnvironment.numberOfDomains.rawValue : "0",
                                                         TestsEnvironment.wallets.rawValue : TestsEnvironment.TestWalletDescription.groupedWalletsStr(from: walletsToUse)] }
    
    func testRemoveWallet() {
        NavigationRobot(app)
            .openWalletDetails(walletName: walletsToUse[0].name!)
        
        WalletDetailsRobot(app)
            .tapOnCellWith(name: "Remove vault")

        PullUpRobot(app)
            .tapConfirm()
        
        WalletsListRobot(app)
            .ensureNumberOfCells(walletsToUse.count - 1)
            .ensureCell(with: "Vault", visible: false)
    }
    
}

final class FailRemoveWalletUITest: BaseXCTestCase {
    
    private lazy var walletsToUse: [TestsEnvironment.TestWalletDescription] = {
        [.init(type: "generatedLocally", name: "Vault", hasBeenBackedUp: true, isExternal: false),
         .init(type: "mnemonicsEntered", name: nil, hasBeenBackedUp: true, isExternal: false),
         .init(type: "privateKeyEntered", name: nil, hasBeenBackedUp: false, isExternal: false),
         .init(type: "importedUnverified", name: "Rainbow", hasBeenBackedUp: false, isExternal: true)]
    }()
    override var launchEnvironment: [String : String] { [TestsEnvironment.numberOfDomains.rawValue : "0",
                                                         TestsEnvironment.shouldFailAuth.rawValue : "1",
                                                         TestsEnvironment.wallets.rawValue : TestsEnvironment.TestWalletDescription.groupedWalletsStr(from: walletsToUse)] }
    
    func testRemoveWalletFailed() {
        prepare()
        
        PullUpRobot(app)
            .tapConfirm()
        
        checkExpectedResult()
    }
    
    func testRemoveWalletCancelled() {
        prepare()
        
        PullUpRobot(app)
            .tapCancel()
        
        checkExpectedResult()
    }
    
    private func prepare() {
        NavigationRobot(app)
            .openWalletDetails(walletName: walletsToUse[0].name!)
        
        WalletDetailsRobot(app)
            .tapOnCellWith(name: "Remove vault")
    }
    
    private func checkExpectedResult() {
        WalletsListRobot(app)
            .back()
            .ensureNumberOfCells(walletsToUse.count)
            .ensureCell(with: "Vault", visible: true)
    }
    
}
