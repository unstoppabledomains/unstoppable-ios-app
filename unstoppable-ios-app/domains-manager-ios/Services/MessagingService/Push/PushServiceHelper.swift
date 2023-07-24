//
//  PushServiceHelper.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.07.2023.
//

import Foundation
import Push

struct PushServiceHelper {
    func getCurrentPushEnvironment() -> Push.ENV {
        let isTestnetUsed = User.instance.getSettings().isTestnetUsed
        return isTestnetUsed ? .STAGING : .PROD
    }
    
    func getAnyDomainItem(for wallet: HexAddress) async throws -> DomainItem {
        let wallet = wallet.normalized
        guard let domain = await appContext.dataAggregatorService.getDomainItems().first(where: { $0.ownerWallet == wallet }) else {
            throw PushHelperError.noDomainForWallet
        }
        
        return domain
    }
    
    enum PushHelperError: String, LocalizedError {
        case noDomainForWallet
        
        public var errorDescription: String? { rawValue }
    }
}
