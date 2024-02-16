//
//  ChatViewModel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.02.2024.
//

import Foundation

extension ChatView {
    
    @MainActor
    final class ChatViewModel: ObservableObject {
        
        private let profile: MessagingChatUserProfileDisplayInfo
        private let messagingService: MessagingServiceProtocol
        private let featureFlagsService: UDFeatureFlagsServiceProtocol
        private var conversationState: MessagingChatConversationState
        private let fetchLimit: Int = 20
        @Published private(set) var isLoadingMessages = false
        @Published private(set) var blockStatus: MessagingPrivateChatBlockingStatus = .unblocked
        @Published private(set) var isChannelEncrypted: Bool = true
        @Published private(set) var isAbleToContactUser: Bool = true
        @Published private(set) var messages: [MessagingChatMessageDisplayInfo] = []
        @Published private(set) var scrollToMessage: MessagingChatMessageDisplayInfo?
        @Published private(set) var messagesCache: Set<MessagingChatMessageDisplayInfo> = []
        @Published var input: String = ""

        private let serialQueue = DispatchQueue(label: "com.unstoppable.chat.view.serial")
        private var messagesToReactions: [String : Set<MessageReactionDescription>] = [:]
        
        init(profile: MessagingChatUserProfileDisplayInfo,
             conversationState: MessagingChatConversationState,
             messagingService: MessagingServiceProtocol = appContext.messagingService,
             featureFlagsService: UDFeatureFlagsServiceProtocol = appContext.udFeatureFlagsService) {
            self.profile = profile
            self.conversationState = conversationState
            self.messagingService = messagingService
            self.featureFlagsService = featureFlagsService
        }
        
        
        func sendPressed() {
//            let newMessage = Message(text: input,
//                                     isCurrentUser: [true, false].randomElement()!)
//            messages.append(newMessage)
//            scrollToMessage = newMessage
            input = ""
        }
        
        func additionalActionPressed(_ action: MessageInputView.AdditionalAction) {
            
        }
    }
}
