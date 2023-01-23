//
//  NavigationRobot.swift
//  domains-manager-iosUITests
//
//  Created by Oleg Kuplin on 30.08.2022.
//

import XCTest

final class NavigationRobot: Robot {
    
    func openSettings() {
        DomainsCollectionScreenRobot(app)
            .tapSettings()
    }
    
    func openWalletsList() {
        openSettings()
        SettingsRobot(app)
            .tapOnCellWith(name: "Domain vault")
    }
    
    func openWalletDetails(walletName: String) {
        openWalletsList()
        WalletsListRobot(app)
            .tapOnCellWith(name: walletName)

    }
    
}
