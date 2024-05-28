//
//  DeepLinksServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.05.2022.
//

import Foundation

enum DeepLinkEvent: Equatable {
    case mintDomainsVerificationCode(email: String, code: String)
    case showUserDomainProfile(domain: DomainDisplayInfo, wallet: WalletEntity, action: PreRequestedProfileAction?)
    case showPublicDomainProfile(publicDomainDisplayInfo: PublicDomainDisplayInfo, wallet: WalletEntity, action: PreRequestedProfileAction?)
    case activateMPCWallet(email: String?)
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

enum PreRequestedProfileAction: Equatable {
    case showBadge(code: String)
}

enum DeepLinksParameterKey: String {
    case operation
    case email, code
    case uri
    case openBadgeCode
}
