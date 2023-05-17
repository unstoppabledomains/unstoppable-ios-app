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
        let wallets = appContext.udWalletsService.getUserWallets()
        
        if wallets.isEmpty {
            if appContext.firebaseAuthService.isAuthorised {
                let domains = appContext.firebaseDomainsService.getCachedDomains()
                if domains.isEmpty {
                    return .webAccountWithoutParkedDomains
                } else {
                    return .webAccountWithParkedDomains
                }
            } else {
                return .noWalletsOrWebAccount
            }
        } else {
            return .walletAdded
        }
    }
}

// MARK: - Open methods
extension AppSessionInterpreter {
    enum State {
        case noWalletsOrWebAccount
        case walletAdded
        case webAccountWithParkedDomains
        case webAccountWithoutParkedDomains
    }
}
