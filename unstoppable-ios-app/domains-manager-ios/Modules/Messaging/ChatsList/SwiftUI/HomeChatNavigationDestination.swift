//
//  HomeChatNavigationDestination.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.02.2024.
//

import SwiftUI

enum HomeChatNavigationDestination: Hashable {
    case chat(profile: MessagingChatUserProfileDisplayInfo, conversationState: MessagingChatConversationState)
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
                                      router: tabRouter),
                     isNavTitleVisible: .constant(true))
                
        }
    }
    
}
