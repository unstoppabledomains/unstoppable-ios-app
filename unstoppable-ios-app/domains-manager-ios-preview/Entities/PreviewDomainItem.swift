//
//  PreviewDomainItem.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation

struct DomainItem: DomainEntity {
    var name = ""
    var ownerWallet: String? = ""
    var blockchain: BlockchainType? = .Matic
}


struct PublicDomainDisplayInfo: Hashable {
    let walletAddress: String
    let name: String
}

extension DomainItem {
    static func getViewingDomainFor(messagingProfile: MessagingChatUserProfileDisplayInfo) async -> DomainItem? {
        nil
    }
}
