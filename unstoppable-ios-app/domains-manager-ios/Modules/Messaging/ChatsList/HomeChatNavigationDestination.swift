//
//  HomeChatNavigationDestination.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.02.2024.
//

import SwiftUI

enum HomeChatNavigationDestination: Hashable {
    case chat(profile: MessagingChatUserProfileDisplayInfo, conversationState: MessagingChatConversationState)
    case channel(profile: MessagingChatUserProfileDisplayInfo, channel: MessagingNewsChannel)
    case requests(profile: MessagingChatUserProfileDisplayInfo, dataType: ChatRequestsListView.DataType)
}

struct HomeChatLinkNavigationDestination {
    
    @MainActor
    @ViewBuilder
    static func viewFor(navigationDestination: HomeChatNavigationDestination,
                        tabRouter: HomeTabRouter) -> some View {
        switch navigationDestination {
        case .chat(let profile, let conversationState):
            ChatView(viewModel: .init(profile: profile,
                                      conversationState: conversationState,
                                      router: tabRouter))
        case .channel(let profile, let channel):
            ChannelView(viewModel: .init(profile: profile,
                                         channel: channel))
        case .requests(let profile, let dataType):
            ChatRequestsListView(viewModel: .init(dataType: dataType,
                                                  profile: profile,
                                                  router: tabRouter))
        }
    }
    
}
