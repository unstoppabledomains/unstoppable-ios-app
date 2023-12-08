//
//  ExternalEventUIFlow.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.12.2023.
//

import Foundation

enum ExternalEventUIFlow {
    case showDomainProfile(domain: DomainDisplayInfo, walletWithInfo: WalletWithInfo)
    case primaryDomainMinted(domain: DomainDisplayInfo)
    case showHomeScreenList
    case showPullUpLoading
    case showChatsList(profile: MessagingChatUserProfileDisplayInfo?)
    case showChat(chatId: String, profile: MessagingChatUserProfileDisplayInfo)
    case showNewChat(description: MessagingChatNewConversationDescription, profile: MessagingChatUserProfileDisplayInfo)
    case showChannel(channelId: String, profile: MessagingChatUserProfileDisplayInfo)
}
