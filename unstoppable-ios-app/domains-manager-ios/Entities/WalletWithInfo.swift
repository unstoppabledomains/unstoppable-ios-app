//
//  WalletWithInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.06.2022.
//

import Foundation

struct WalletWithInfo {

    private static let mockWallets: [UDWallet] = [.init(aliasName: "0xc4a748796805dfa42cafe0901ec182936584cc6e", address: "0xc4a748796805dfa42cafe0901ec182936584cc6e", type: .importedUnverified),
                                                  .init(aliasName: "Custom name", address: "0x537e2EB956AEC859C99B3e5e28D8E45200C4Fa52", type: .importedUnverified),
                                                  .init(aliasName: "0xcA429897570aa7083a7D296CD0009FA286731ED2", address: "0xcA429897570aa7083a7D296CD0009FA286731ED2", type: .generatedLocally),
                                                  .init(aliasName: "UD", address: "0xCeBF5440FE9C85e037A80fFB4dF0F6a9BAcb3d01", type: .generatedLocally)]
    static let mock: [WalletWithInfo] = mockWallets.map { WalletWithInfo(wallet: $0, displayInfo: .init(wallet: $0, domainsCount: Int(arc4random_uniform(3)), udDomainsCount: Int(arc4random_uniform(3))))}

    var wallet: UDWallet
    var displayInfo: WalletDisplayInfo?
}

fileprivate extension UDWallet {
    init(aliasName: String,
         address: String,
         type: WalletType,
         hasBeenBackedUp: Bool = false) {
        self.aliasName = aliasName
        self.type = type
        self.hasBeenBackedUp = hasBeenBackedUp
    }
}
