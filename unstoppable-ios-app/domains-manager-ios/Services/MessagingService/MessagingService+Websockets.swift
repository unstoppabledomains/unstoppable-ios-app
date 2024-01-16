//
//  MessagingService+Websockets.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.10.2023.
//

import Foundation

extension MessagingService {
    func setupSocketConnection(profile: MessagingChatUserProfile) {
        Task {
            let serviceProvider = try getServiceAPIProviderWith(identifier: profile.serviceIdentifier)
            let webSocketsService = serviceProvider.webSocketsService
            
            do {
                webSocketsService.disconnectAll()
                try webSocketsService.subscribeFor(profile: profile,
                                                   eventCallback: { [weak self] event in
                    self?.handleWebSocketEvent(event)
                })
                
                channelsWebSocketsService.disconnectAll()
                try channelsWebSocketsService.subscribeFor(profile: profile,
                                                           eventCallback: { [weak self] event in
                    self?.handleWebSocketEvent(event)
                })
            } catch { }
        }
    }
    
    func disconnectAllSocketsConnections() {
        serviceProviders.forEach { serviceProvider in
            serviceProvider.webSocketsService.disconnectAll()
        }
        channelsWebSocketsService.disconnectAll()
    }
}

// MARK: - Private methods
private extension MessagingService {
    func handleWebSocketEvent(_ event: MessagingWebSocketEvent) {
        Task {
            func addNewChatMessages(_ chatMessages: [GroupChatMessageWithProfile]) async {
                guard !chatMessages.isEmpty else { return }
                
                if await stateHolder.isSendingMessage,
                   chatMessages.first(where: { $0.message.displayInfo.senderType.isThisUser }) != nil {
                    return
                }
                
                await storageService.saveMessages(chatMessages.map({ $0.message }))
                for messageWithProfile in chatMessages {
                    let message = messageWithProfile.message
                    let profile = messageWithProfile.profile
                    let chatId = message.displayInfo.chatId
                    /// UI always interact with default messaging profile
                    guard let defaultProfile = try? await getDefaultProfile(for: profile) else { continue }

                    notifyListenersChangedDataType(.messagesAdded([message.displayInfo],
                                                                  chatId: chatId,
                                                                  userId: defaultProfile.id))
                    try? await setLastMessageAndNotify(lastMessage: message.displayInfo, serviceIdentifier: profile.serviceIdentifier)
                }
            }
            
            func addNewChannelFeed(_ feed: MessagingNewsChannelFeed, to channel: MessagingNewsChannel) async throws {
                var channel = channel
                let profile = try storageService.getUserProfileWith(userId: channel.userId,
                                                                    serviceIdentifier: defaultServiceIdentifier)
                await storageService.saveChannelsFeed([feed], in: channel)
                channel.lastMessage = feed
                await storageService.saveChannels([channel], for: profile)
                notifyListenersChangedDataType(.channelFeedAdded(feed, channelId: channel.id))
                notifyChannelsChanged(userId: profile.id)
            }
            
            do {
                switch event {
                case .channelNewFeed(let feed, let channelAddress, _):
                    if let channel = try await getOrFetchChannelOfCurrentUserWithAddress(channelAddress, isCurrentUserSubscribed: true) {
                        try await addNewChannelFeed(feed, to: channel)
                    }
                case .channelSpamFeed(let feed, let channelAddress, _):
                    if let channel = try await getOrFetchChannelOfCurrentUserWithAddress(channelAddress, isCurrentUserSubscribed: false) {
                        try await addNewChannelFeed(feed, to: channel)
                    }
                case .groupChatReceivedMessage(let message):
                    let chatMessages = try await convertMessagingWebSocketGroupMessageEntityToMessage(message)
                    await addNewChatMessages(chatMessages)
                case .chatReceivedMessage(let message):
                    let chatMessages = try await convertMessagingWebSocketMessageEntityToMessage(message)
                    await addNewChatMessages(chatMessages)
                case .newChat(let webSocketsChat):
                    let profile = try storageService.getUserProfileWith(userId: webSocketsChat.userId,
                                                                        serviceIdentifier: webSocketsChat.serviceIdentifier)
                    guard let chat = webSocketsChat.transformToChatBlock(webSocketsChat, profile) else { return }
                    
                    let updatedChats = try await refreshChatsMetadata(remoteChats: [chat], localChats: [], for: profile)
                    await storageService.saveChats(updatedChats)
                    notifyChatsChanged(wallet: profile.wallet, serviceIdentifier: profile.serviceIdentifier)
                    await refreshUsersInfoFor(profile: profile)
                }
            } catch { }
        }
    }
    
    func convertMessagingWebSocketMessageEntityToMessage(_ messageEntity: MessagingWebSocketMessageEntity) async throws -> [GroupChatMessageWithProfile] {
        var messages: [GroupChatMessageWithProfile] = []
        
        func getMessageFor(wallet: String, otherUserWallet: String) async throws -> GroupChatMessageWithProfile {
            let profile = try await getUserProfileWith(wallet: wallet, serviceIdentifier: messageEntity.serviceIdentifier)
            let chats = try await storageService.getChatsFor(profile: profile)
            guard let chat = chats.first(where: { $0.displayInfo.type.otherUserDisplayInfo?.wallet == otherUserWallet }) else { throw MessagingServiceError.chatNotFound }
            guard let message = await messageEntity.transformToMessageBlock(messageEntity, chat, filesService) else { throw MessagingServiceError.failedToConvertWebsocketMessage }
            return GroupChatMessageWithProfile(message: message, profile: profile)
        }
        
        if let message = try? await getMessageFor(wallet: messageEntity.receiverWallet,
                                                  otherUserWallet: messageEntity.senderWallet) {
            messages.append(message)
        }
        
        if let message = try? await getMessageFor(wallet: messageEntity.senderWallet,
                                                  otherUserWallet: messageEntity.receiverWallet) {
            messages.append(message)
        }
        
        return messages
    }
    
    func convertMessagingWebSocketGroupMessageEntityToMessage(_ messageEntity: MessagingWebSocketGroupMessageEntity) async throws -> [GroupChatMessageWithProfile] {
        var messages: [GroupChatMessageWithProfile] = []
        
        let profiles = try storageService.getAllUserProfiles()
        for profile in profiles {
            if let chat = await storageService.getChatWith(id: messageEntity.chatId,
                                                           of: profile.id,
                                                           serviceIdentifier: profile.serviceIdentifier),
               let message = await messageEntity.transformToMessageBlock(messageEntity, chat, filesService) {
                messages.append(.init(message: message, profile: profile))
            }
        }
        
        return messages
    }
    
    struct GroupChatMessageWithProfile {
        let message: MessagingChatMessage
        let profile: MessagingChatUserProfile
    }
}
