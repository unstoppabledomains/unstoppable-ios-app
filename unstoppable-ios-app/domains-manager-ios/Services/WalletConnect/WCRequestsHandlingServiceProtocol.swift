//
//  WCRequestsHandlingServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.12.2023.
//

import Foundation

protocol WCRequestsHandlingServiceProtocol {
    func handleWCRequest(_ request: WCRequest, target: (UDWallet, DomainItem)) async throws
    func setUIHandler(_ uiHandler: WalletConnectUIErrorHandler)
    func addListener(_ listener: WalletConnectServiceConnectionListener)
    func removeListener(_ listener: WalletConnectServiceConnectionListener)
    func expectConnection()
}
