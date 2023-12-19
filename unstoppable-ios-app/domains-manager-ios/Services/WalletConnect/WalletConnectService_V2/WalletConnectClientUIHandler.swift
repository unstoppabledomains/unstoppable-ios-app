//
//  WalletConnectClientUIHandler.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.12.2023.
//

import Foundation

@MainActor
protocol WalletConnectClientUIHandler: AnyObject {
    func didDisconnect(walletDisplayInfo: WalletDisplayInfo)
    func askToReconnectExternalWallet(_ walletDisplayInfo: WalletDisplayInfo) async -> Bool
    func showExternalWalletDidNotRespondPullUp(for connectingWallet: WCWalletsProvider.WalletRecord) async
}
