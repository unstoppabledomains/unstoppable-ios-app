//
//  DeepLinksServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.05.2022.
//

import Foundation

enum DeepLinkEvent {
    case mintDomainsVerificationCode(email: String, code: String)
    case showUserDomainProfile(domain: DomainDisplayInfo, wallet: UDWallet, walletInfo: WalletDisplayInfo, action: PreRequestedProfileAction?)
//    case showPublicDomainProfile(domainNameProfile: PublicDomainDisplayInfo, badgeCode: String?)
}

protocol DeepLinksServiceProtocol {
    func handleUniversalLink(_ incomingURL: URL, receivedState: ExternalEventReceivedState)
    func addListener(_ listener: DeepLinkServiceListener)
    func removeListener(_ listener: DeepLinkServiceListener)
}

protocol DeepLinkServiceListener: AnyObject {
    func didReceiveDeepLinkEvent(_ event: DeepLinkEvent, receivedState: ExternalEventReceivedState)
}

final class DeepLinkListenerHolder: Equatable {
    
    weak var listener: DeepLinkServiceListener?
    
    init(listener: DeepLinkServiceListener) {
        self.listener = listener
    }
    
    static func == (lhs: DeepLinkListenerHolder, rhs: DeepLinkListenerHolder) -> Bool {
        guard let lhsListener = lhs.listener,
              let rhsListener = rhs.listener else { return false }
        
        return lhsListener === rhsListener
    }
    
}
