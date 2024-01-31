//
//  AppSessionInterpreter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.03.2023.
//

import Foundation

final class AppSessionInterpreter {
    
    static let shared = AppSessionInterpreter()
    
    private init() { }
    
}

// MARK: - Open methods
extension AppSessionInterpreter {
    func state() -> State {
        if let wallet = appContext.walletsDataService.selectedWallet {
            return .walletAdded(wallet)
        } else {
            if let user = appContext.firebaseParkedDomainsAuthenticationService.firebaseUser {
                let domains = appContext.firebaseParkedDomainsService.getCachedDomains()
                if domains.isEmpty {
                    return .webAccountWithoutParkedDomains
                } else {
                    return .webAccountWithParkedDomains(user)
                }
            } else {
                return .noWalletsOrWebAccount
            }
        }
    }
}

// MARK: - Open methods
extension AppSessionInterpreter {
    enum State {
        case noWalletsOrWebAccount
        case walletAdded(WalletEntity)
        case webAccountWithParkedDomains(FirebaseUser)
        case webAccountWithoutParkedDomains
    }
}
