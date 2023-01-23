//
//  WalletDetailsUITests.swift
//  domains-manager-iosUITests
//
//  Created by Oleg Kuplin on 31.08.2022.
//

import Foundation
import XCTest

final class WalletDetailsUDBackedUpUITests: BaseXCTestCase {
    
    private lazy var walletsToUse: [TestsEnvironment.TestWalletDescription] = {
        [.init(type: "generatedLocally", name: "Vault", hasBeenBackedUp: true, isExternal: false, domainNames: ["joshgordon_0.x"])]
    }()
    override var launchEnvironment: [String : String] { [TestsEnvironment.numberOfDomains.rawValue : "1",
                                                         TestsEnvironment.wallets.rawValue : TestsEnvironment.TestWalletDescription.groupedWalletsStr(from: walletsToUse)] }
    
    func testBackedUpUDVaultAndRename() {
        NavigationRobot(app)
            .openWalletDetails(walletName: walletsToUse[0].name!)
        
        WalletDetailsRobot(app)
            .ensureNumberOfCells(7)
            .ensureCell(with: "Info Vault", visible: true)
            .ensureCell(with: "Backed up to iCloud", visible: true)
            .ensureCell(with: "View recovery phrase", visible: true)
            .ensureCell(with: "Rename", visible: true)
            .ensureCell(with: "See 1 domain stored in vault", visible: true)
            .ensureCell(with: "Remove vault", visible: true)
            
        // Test rename cancelled
            .tapOnCellWith(name: "Rename")
        RenameWalletRobot(app)
            .ensureRenameScreen(visible: true)
            .ensureConfirmButton(enabled: true)
            .clearInput()
            .ensureConfirmButton(enabled: false)
            .setNewWalletName("Custom Name")
            .ensureConfirmButton(enabled: true)
            .cancelRenameWallet()
            .ensureRenameScreen(visible: false)

        WalletDetailsRobot(app)
            .ensureCell(with: "Info Vault", visible: true)
            .ensureCell(with: "Info Custom Name", visible: false)

        // Test rename
            .tapOnCellWith(name: "Rename")
        RenameWalletRobot(app)
            .ensureRenameScreen(visible: true)
            .clearInput()
            .setNewWalletName("Custom Name")
            .confirmRenameWallet()
            .ensureRenameScreen(visible: false)

        WalletDetailsRobot(app)
            .ensureCell(with: "Info Vault", visible: false)
            .ensureCell(with: "Info Custom Name", visible: true)

            .tapOnCellWith(name: "See 1 domain stored in vault")
        WalletsListRobot(app)
            .ensureNumberOfCells(1)
            .back()
        
        WalletDetailsRobot(app)
            .ensureCell(with: "Info Custom Name", visible: true)
    }
    
}

final class WalletDetailsImportedNotBackedUpUITests: BaseXCTestCase {
    
    private lazy var walletsToUse: [TestsEnvironment.TestWalletDescription] = {
        [.init(type: "privateKeyEntered", name: "Custom Name", hasBeenBackedUp: false, isExternal: false)]
    }()
    override var launchEnvironment: [String : String] { [TestsEnvironment.numberOfDomains.rawValue : "0",
                                                         TestsEnvironment.wallets.rawValue : TestsEnvironment.TestWalletDescription.groupedWalletsStr(from: walletsToUse)] }
    
    func testNotBackedUpImportedVault() {
        NavigationRobot(app)
            .openWalletDetails(walletName: walletsToUse[0].name!)
        
        WalletDetailsRobot(app)
            .ensureNumberOfCells(5)
            .ensureCell(with: "Info Custom Name", visible: true)
        
            .ensureCell(with: "Back up to iCloud", visible: true)
            .ensureCell(with: "View private key", visible: true)
            .ensureCell(with: "Rename", visible: true)
            .ensureCell(with: "Remove wallet", visible: true)
        
            .back()
    }
    
}

final class WalletDetailsExternalUITests: BaseXCTestCase {
    
    private lazy var walletsToUse: [TestsEnvironment.TestWalletDescription] = {
        [.init(type: "importedUnverified", name: "Rainbow", hasBeenBackedUp: false, isExternal: true)]
    }()
    override var launchEnvironment: [String : String] { [TestsEnvironment.numberOfDomains.rawValue : "0",
                                                         TestsEnvironment.wallets.rawValue : TestsEnvironment.TestWalletDescription.groupedWalletsStr(from: walletsToUse)] }
    
    func testNotBackedUpImportedVault() {
        NavigationRobot(app)
            .openWalletDetails(walletName: walletsToUse[0].name!)
        
        WalletDetailsRobot(app)
            .ensureNumberOfCells(3)
            .ensureCell(with: "Info Rainbow", visible: true)
            .ensureCell(with: "Rename", visible: true)
            .ensureCell(with: "Disconnect wallet", visible: true)
            .back()
    }
    
}
