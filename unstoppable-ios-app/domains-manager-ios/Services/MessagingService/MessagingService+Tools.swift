//
//  MessagingService+Tools.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.10.2023.
//

import Foundation

extension MessagingService {
    func getReverseResolutionDomainItem(for wallet: String) async throws -> DomainItem {
        let walletsForMessaging = await fetchWalletsAvailableForMessaging()
        guard let wallet = walletsForMessaging.first(where: { $0.address == wallet.normalized }),
              let domainInfo = wallet.reverseResolutionDomain else {
            throw MessagingServiceError.noRRDomainForProfile
        }
        return try await appContext.dataAggregatorService.getDomainWith(name: domainInfo.name)
    }
    
    func getDomainEthWalletAddress(_ domain: DomainDisplayInfo) throws -> String {
        guard let ethAddress = domain.getETHAddress() else { throw MessagingServiceError.domainWithoutWallet }
        return ethAddress
    }
    
    func getMessagingChatFor(displayInfo: MessagingChatDisplayInfo,
                             userId: String) async throws -> MessagingChat {
        try await getMessagingChatWith(chatId: displayInfo.id, userId: userId)
    }
    
    func getMessagingChatWith(chatId: String,
                              userId: String) async throws -> MessagingChat {
        guard let chat = await storageService.getChatWith(id: chatId,
                                                          of: userId) else { throw MessagingServiceError.chatNotFound }
        
        return chat
    }
    
    func getUserProfileWith(wallet: String) async throws -> MessagingChatUserProfile {
        let rrDomain = try await getReverseResolutionDomainItem(for: wallet)
        return try storageService.getUserProfileFor(domain: rrDomain,
                                                    serviceIdentifier: apiService.serviceIdentifier)
    }
    
    func replaceCacheMessageAndNotify(_ messageToReplace: MessagingChatMessage,
                                      with newMessage: MessagingChatMessage) {
        Task {
            try? await storageService.replaceMessage(messageToReplace, with: newMessage)
            notifyListenersChangedDataType(.messageUpdated(messageToReplace.displayInfo, newMessage: newMessage.displayInfo))
        }
    }
    
    func refreshChatsInSameDomain(as chatId: String, userId: String) {
        Task {
            do {
                let chat = try await getMessagingChatWith(chatId: chatId, userId: userId)
                let profile = try await getUserProfileWith(wallet: chat.displayInfo.thisUserDetails.wallet)
                refreshChatsForProfile(profile, shouldRefreshUserInfo: false)
            } catch { }
        }
    }
    
    func setLastMessageAndNotify(lastMessage: MessagingChatMessageDisplayInfo) async throws {
        guard let chat = await storageService.getChatWith(id: lastMessage.chatId, of: lastMessage.userId) else { return }
        try await setLastMessageAndNotify(lastMessage, to: chat)
    }
    
    func setLastMessageAndNotify(_ lastMessage: MessagingChatMessageDisplayInfo,
                                 to chat: MessagingChat) async throws {
        var updatedChat = chat
        updatedChat.displayInfo.lastMessage = lastMessage
        updatedChat.displayInfo.lastMessageTime = lastMessage.time
        try await storageService.replaceChat(chat, with: updatedChat)
        notifyChatsChanged(wallet: chat.displayInfo.thisUserDetails.wallet)
        notifyReadStatusUpdatedFor(message: lastMessage)
    }
    
    func notifyChannelsChanged(userId: String) {
        Task {
            do {
                let profile = try storageService.getUserProfileWith(userId: userId,
                                                                    serviceIdentifier: apiService.serviceIdentifier)
                let channels = try await storageService.getChannelsFor(profile: profile)
                notifyListenersChangedDataType(.channels(channels, profile: profile.displayInfo))
            } catch { }
        }
    }
    
    func notifyChatsChanged(wallet: String) {
        Task {
            do {
                let profile = try await getUserProfileWith(wallet: wallet)
                let chats = try await storageService.getChatsFor(profile: profile)
                let displayInfo = chats.map { $0.displayInfo }
                notifyListenersChangedDataType(.chats(displayInfo, profile: profile.displayInfo))
            } catch { }
        }
    }
    
    func notifyListenersChangedDataType(_ messagingDataType: MessagingDataType) {
        Debugger.printInfo(topic: .Messaging, "Will notify listeners about data type: \(messagingDataType.debugDescription)")
        listenerHolders.forEach { holder in
            holder.listener?.messagingDataTypeDidUpdated(messagingDataType)
        }
    }

    func notifyReadStatusUpdatedFor(message: MessagingChatMessageDisplayInfo) {
        let number = unreadCountingService.getNumberOfUnreadMessagesIn(chatId: message.chatId, userId: message.userId)
        notifyListenersChangedDataType(.messageReadStatusUpdated(message, numberOfUnreadMessagesInSameChat: number))
    }
}
