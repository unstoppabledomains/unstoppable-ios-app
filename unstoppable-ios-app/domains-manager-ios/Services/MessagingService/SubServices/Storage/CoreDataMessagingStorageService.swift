//
//  CoreDataMessagingStorageService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2023.
//

import Foundation
import CoreData

final class CoreDataMessagingStorageService: CoreDataService {
    
    private let queue = DispatchQueue(label: "com.coredata")
    
}

// MARK: - MessagingStorageServiceProtocol
extension CoreDataMessagingStorageService: MessagingStorageServiceProtocol {
    // User Profile
    func getUserProfileFor(domain: DomainItem) throws -> MessagingChatUserProfile {
        try queue.sync {
            guard let wallet = domain.ownerWallet else { throw Error.domainWithoutWallet }
            if let coreDataMessage: CoreDataMessagingUserProfile = getCoreDataEntityWith(key: "normalizedWallet", value: wallet) {
                return convertCoreDataUserProfileToMessagingUserProfile(coreDataMessage)
            }
            throw Error.entityNotFound
        }
    }
    
    func saveUserProfile(_ profile: MessagingChatUserProfile) async {
        queue.sync {
            let _ = try? convertMessagingUserProfileToCoreDataUserProfile(profile)
            saveContext(backgroundContext)
        }
    }
    
    // Messages
    func getMessagesFor(chat: MessagingChatDisplayInfo,
                        decrypter: MessagingContentDecrypterService) async throws -> [MessagingChatMessage] {
        try queue.sync {
            let predicate = NSPredicate(format: "chatId == %@", chat.id)
            let timeSortDescriptor = NSSortDescriptor(key: "time", ascending: false)
            let coreDataMessages: [CoreDataMessagingChatMessage] = try getEntities(predicate: predicate,
                                                                                   sortDescriptions: [timeSortDescriptor],
                                                                                   from: backgroundContext)
            return coreDataMessages.compactMap { convertCoreDataMessageToChatMessage($0,
                                                                                     decrypter: decrypter,
                                                                                     wallet: chat.thisUserDetails.wallet) }
        }
    }
    
    func getMessagesFor(chat: MessagingChatDisplayInfo,
                        decrypter: MessagingContentDecrypterService,
                        before message: MessagingChatMessageDisplayInfo?,
                        limit: Int) async throws -> [MessagingChatMessage] {
        let timeSortDescriptor = NSSortDescriptor(key: "time", ascending: false)
        let predicate: NSPredicate
        let chatIdPredicate = NSPredicate(format: "chatId == %@", chat.id)
        
        if let message {
            let timePredicate = NSPredicate(format: "time < %@", message.time as NSDate)
            predicate = NSCompoundPredicate(type: .and, subpredicates: [chatIdPredicate, timePredicate])
        } else {
            predicate = chatIdPredicate
        }
        
        return try fetchAndParseMessagesFor(chat: chat,
                                            decrypter: decrypter,
                                            predicate: predicate,
                                            sortDescriptions: [timeSortDescriptor],
                                            limit: limit)
    }
    
    func getMessagesFor(chat: MessagingChatDisplayInfo,
                        decrypter: MessagingContentDecrypterService,
                        after message: MessagingChatMessageDisplayInfo,
                        limit: Int) async throws -> [MessagingChatMessage] {
        let timeSortDescriptor = NSSortDescriptor(key: "time", ascending: true)
        let chatIdPredicate = NSPredicate(format: "chatId == %@", chat.id)
        let timePredicate = NSPredicate(format: "time > %@", message.time as NSDate)
        let predicate = NSCompoundPredicate(type: .and, subpredicates: [chatIdPredicate, timePredicate])
        
        return try fetchAndParseMessagesFor(chat: chat,
                                            decrypter: decrypter,
                                            predicate: predicate,
                                            sortDescriptions: [timeSortDescriptor],
                                            limit: limit)
    }
    
    private func fetchAndParseMessagesFor(chat: MessagingChatDisplayInfo,
                                          decrypter: MessagingContentDecrypterService,
                                          predicate: NSPredicate? = nil,
                                          sortDescriptions: [NSSortDescriptor]? = nil,
                                          limit: Int?) throws -> [MessagingChatMessage]  {
        try queue.sync {
            let coreDataMessages: [CoreDataMessagingChatMessage] = try getEntities(predicate: predicate,
                                                                                   sortDescriptions: sortDescriptions,
                                                                                   fetchSize: limit,
                                                                                   from: backgroundContext)
            return coreDataMessages.compactMap { convertCoreDataMessageToChatMessage($0,
                                                                                     decrypter: decrypter,
                                                                                     wallet: chat.thisUserDetails.wallet) }
        }
    }
    
    func getMessageWith(id: String,
                        in chat: MessagingChatDisplayInfo,
                        decrypter: MessagingContentDecrypterService) async -> MessagingChatMessage? {
        queue.sync {
            if let coreDataMessage: CoreDataMessagingChatMessage = getCoreDataEntityWith(id: id) {
                return convertCoreDataMessageToChatMessage(coreDataMessage,
                                                           decrypter: decrypter,
                                                           wallet: chat.thisUserDetails.wallet)
            }
            return nil
        }
    }
    
    func saveMessages(_ messages: [MessagingChatMessage]) async {
        queue.sync {
            let _ = messages.compactMap { (try? convertChatMessageToCoreDataMessage($0)) }
            saveContext(backgroundContext)
        }
    }
    
    func replaceMessage(_ messageToReplace: MessagingChatMessage,
                        with newMessage: MessagingChatMessage) async throws {
        try queue.sync {
            guard let coreDataMessage: CoreDataMessagingChatMessage = getCoreDataEntityWith(id: messageToReplace.displayInfo.id) else { throw Error.entityNotFound }
            
            deleteObject(coreDataMessage, from: backgroundContext, shouldSaveContext: false)
            _ = try? convertChatMessageToCoreDataMessage(newMessage)
            saveContext(backgroundContext)
        }
    }
    
    func deleteMessage(_ message: MessagingChatMessageDisplayInfo) throws {
        try queue.sync {
            guard let coreDataMessage: CoreDataMessagingChatMessage = getCoreDataEntityWith(id: message.id) else { throw Error.entityNotFound }
            deleteObject(coreDataMessage, from: backgroundContext, shouldSaveContext: true)
        }
    }
    
    func markMessage(_ message: MessagingChatMessageDisplayInfo,
                     isRead: Bool) throws {
        try queue.sync {
            guard let coreDataMessage: CoreDataMessagingChatMessage = getCoreDataEntityWith(id: message.id) else { throw Error.entityNotFound }
            coreDataMessage.isRead = isRead
            saveContext(backgroundContext)
        }
    }
    
    func markSendingMessagesAsFailed() {
        Task {
            do {
                let messages: [CoreDataMessagingChatMessage] = try getEntities(from: backgroundContext)
                for message in messages where message.deliveryState == MessagingChatMessageDisplayInfo.DeliveryState.sending.rawValue {
                    message.deliveryState = Int64(MessagingChatMessageDisplayInfo.DeliveryState.failedToSend.rawValue)
                }
                saveContext(backgroundContext)
            } catch { }
        }
    }
    
    // Chats
    func getChatsFor(profile: MessagingChatUserProfile,
                     decrypter: MessagingContentDecrypterService) async throws -> [MessagingChat] {
        try queue.sync {
            let predicate = NSPredicate(format: "userId == %@", profile.id)
            let timeSortDescriptor = NSSortDescriptor(key: "lastMessageTime", ascending: false)
            let coreDataChats: [CoreDataMessagingChat] = try getEntities(predicate: predicate,
                                                                         sortDescriptions: [timeSortDescriptor],
                                                                         from: backgroundContext)
            return coreDataChats.compactMap { convertCoreDataChatToMessagingChat($0,
                                                                                 decrypter: decrypter) }.sortedByLastMessage()
        }
    }
    
    func getChatWith(id: String,
                     decrypter: MessagingContentDecrypterService) async -> MessagingChat? {
        queue.sync {
            if let coreDataMessage: CoreDataMessagingChat = getCoreDataEntityWith(id: id) {
                return convertCoreDataChatToMessagingChat(coreDataMessage,
                                                          decrypter: decrypter)
            }
            return nil
        }
    }
    
    func saveChats(_ chats: [MessagingChat]) async {
        queue.sync {
            let _ = chats.compactMap { (try? convertMessagingChatToCoreDataChat($0)) }
            saveContext(backgroundContext)
        }
    }
    
    func replaceChat(_ chatToReplace: MessagingChat,
                     with newChat: MessagingChat) async throws {
        try queue.sync {
            guard let coreDataChat: CoreDataMessagingChat = getCoreDataEntityWith(id: chatToReplace.displayInfo.id) else { throw Error.entityNotFound }
            
            deleteObject(coreDataChat, from: backgroundContext, shouldSaveContext: false)
            _ = try? convertMessagingChatToCoreDataChat(newChat)
            saveContext(backgroundContext)
        }
    }
    
    // User info
    func saveMessagingUserInfo(_ info: MessagingChatUserDisplayInfo) async {
        queue.sync {
            let _ = try? convertChatUserDisplayInfoToMessagingUserInfo(info)
            saveContext(backgroundContext)
        }
    }
    
    // Channels
    func getChannelsFor(profile: MessagingChatUserProfile) async throws -> [MessagingNewsChannel] {
        try queue.sync {
            let predicate = NSPredicate(format: "userId == %@", profile.id)
            let coreDataChannels: [CoreDataMessagingNewsChannel] = try getEntities(predicate: predicate, from: backgroundContext)
            
            return coreDataChannels.compactMap { convertCoreDataChannelToMessagingChannel($0) }.sortedByLastMessage()
        }
    }
    
    func saveChannels(_ channels: [MessagingNewsChannel],
                      for profile: MessagingChatUserProfile) async {
        queue.sync {
            let _ = channels.compactMap { (try? convertMessagingChannelToCoreDataChannel($0, for: profile.wallet)) }
            saveContext(backgroundContext)
        }
    }
    
    // Channels Feed
    func getChannelsFeedFor(channel: MessagingNewsChannel) async throws -> [MessagingNewsChannelFeed] {
        try queue.sync {
            let predicate = NSPredicate(format: "channelId == %@", channel.id)
            let coreDataChannelsFeed: [CoreDataMessagingNewsChannelFeed] = try getEntities(predicate: predicate, from: backgroundContext)
            
            return coreDataChannelsFeed.compactMap { convertCoreDataChannelFeedToMessagingChannelFeed($0) }
        }
    }
    
    func saveChannelsFeed(_ feed: [MessagingNewsChannelFeed],
                          in channel: MessagingNewsChannel) async {
        queue.sync {
            let _ = feed.compactMap { (try? convertMessagingChannelFeedToCoreDataChannelFeed($0, in: channel)) }
            saveContext(backgroundContext)
        }
    }
    
    // Clear
    func clear() {
        queue.sync {
            do {
                let coreDataChats: [CoreDataMessagingChat] = try getEntities(from: backgroundContext)
                deleteObjects(coreDataChats, from: backgroundContext, shouldSaveContext: false)
                
                let coreDataMessages: [CoreDataMessagingChatMessage] = try getEntities(from: backgroundContext)
                deleteObjects(coreDataMessages, from: backgroundContext, shouldSaveContext: false)
                
                let coreDataNews: [CoreDataMessagingNewsChannel] = try getEntities(from: backgroundContext)
                deleteObjects(coreDataNews, from: backgroundContext, shouldSaveContext: false)
                
                let coreDataNewsFeed: [CoreDataMessagingNewsChannelFeed] = try getEntities(from: backgroundContext)
                deleteObjects(coreDataNewsFeed, from: backgroundContext, shouldSaveContext: false)
                
                let coreDataUsersInfo: [CoreDataMessagingUserInfo] = try getEntities(from: backgroundContext)
                deleteObjects(coreDataUsersInfo, from: backgroundContext, shouldSaveContext: true)
            } catch { }
        }
    }
}

// MARK: - User Profile parsing
private extension CoreDataMessagingStorageService {
    func convertCoreDataUserProfileToMessagingUserProfile(_ coreDataUserProfile: CoreDataMessagingUserProfile) -> MessagingChatUserProfile {
        let displayInfo = MessagingChatUserProfileDisplayInfo(wallet: coreDataUserProfile.wallet!,
                                                              name: coreDataUserProfile.name,
                                                              about: coreDataUserProfile.about)
        
        return MessagingChatUserProfile(id: coreDataUserProfile.id!,
                                        wallet: coreDataUserProfile.wallet!,
                                        displayInfo: displayInfo,
                                        serviceMetadata: coreDataUserProfile.serviceMetadata)
    }
    
    func convertMessagingUserProfileToCoreDataUserProfile(_ userProfile: MessagingChatUserProfile) throws -> CoreDataMessagingUserProfile {
        let coreDataUserProfile: CoreDataMessagingUserProfile = try createEntity(in: backgroundContext)
        
        coreDataUserProfile.id = userProfile.id
        coreDataUserProfile.wallet = userProfile.wallet
        coreDataUserProfile.normalizedWallet = userProfile.wallet.normalized
        coreDataUserProfile.serviceMetadata = userProfile.serviceMetadata
        coreDataUserProfile.name = userProfile.displayInfo.name
        coreDataUserProfile.about = userProfile.displayInfo.about
        
        return coreDataUserProfile
    }
}

// MARK: - Chats parsing
private extension CoreDataMessagingStorageService {
    func convertCoreDataChatToMessagingChat(_ coreDataChat: CoreDataMessagingChat,
                                            decrypter: MessagingContentDecrypterService) -> MessagingChat? {
        guard let chatType = getChatType(from: coreDataChat) else { return nil }
        
        let serviceMetadata = coreDataChat.serviceMetadata
      
        // Last message
        var lastMessage: MessagingChatMessageDisplayInfo?
        if let coreDataLastMessage = coreDataChat.lastMessage,
           let message = convertCoreDataMessageToChatMessage(coreDataLastMessage,
                                                             decrypter: decrypter,
                                                             wallet: coreDataChat.thisUserWallet!) {
            lastMessage = message.displayInfo
        } else if let lastMessageId = coreDataChat.lastMessageId,
                  let coreDataLastMessage: CoreDataMessagingChatMessage = getCoreDataEntityWith(id: lastMessageId),
                  let message = convertCoreDataMessageToChatMessage(coreDataLastMessage,
                                                                    decrypter: decrypter,
                                                                    wallet: coreDataChat.thisUserWallet!) {
            lastMessage = message.displayInfo
        }
        
        let chatIdPredicate = NSPredicate(format: "chatId == %@", coreDataChat.id!)
        let isNotReadPredicate = NSPredicate(format: "isRead == NO")
        let predicate = NSCompoundPredicate(type: .and, subpredicates: [chatIdPredicate, isNotReadPredicate])
        let unreadMessagesCount = (try? countEntities(CoreDataMessagingChatMessage.self,
                                                     predicate: predicate,
                                                     in: backgroundContext)) ?? 0
        
        let thisUserDetails = getThisUserDetails(from: coreDataChat)
        let displayInfo = MessagingChatDisplayInfo(id: coreDataChat.id!,
                                                   thisUserDetails: thisUserDetails,
                                                   avatarURL: coreDataChat.avatarURL,
                                                   type: chatType,
                                                   unreadMessagesCount: unreadMessagesCount,
                                                   isApproved: coreDataChat.isApproved,
                                                   lastMessageTime: coreDataChat.lastMessageTime!,
                                                   lastMessage: lastMessage)
        
        return MessagingChat(userId: coreDataChat.userId!,
                             displayInfo: displayInfo,
                             serviceMetadata: serviceMetadata)
    }
    
    func convertMessagingChatToCoreDataChat(_ chat: MessagingChat) throws -> CoreDataMessagingChat {
        let coreDataChat: CoreDataMessagingChat = try createEntity(in: backgroundContext)
        let displayInfo = chat.displayInfo
        
        coreDataChat.serviceMetadata = chat.serviceMetadata
        coreDataChat.id = displayInfo.id
        coreDataChat.userId = chat.userId
        coreDataChat.avatarURL = displayInfo.avatarURL
        coreDataChat.isApproved = displayInfo.isApproved
        coreDataChat.lastMessageTime = displayInfo.lastMessageTime
        
        if let lastMessage = chat.displayInfo.lastMessage,
           let lastCoreDataMessage: CoreDataMessagingChatMessage = getCoreDataEntityWith(id: lastMessage.id) {
            coreDataChat.lastMessage = lastCoreDataMessage
        }
        coreDataChat.lastMessageId = chat.displayInfo.lastMessage?.id
        
        saveThisUserDetails(displayInfo.thisUserDetails, to: coreDataChat)
        saveChatType(displayInfo.type, to: coreDataChat)
        
        return coreDataChat
    }

    // This user details
    func getThisUserDetails(from coreDataChat: CoreDataMessagingChat) -> MessagingChatUserDisplayInfo {
        MessagingChatUserDisplayInfo(wallet: coreDataChat.thisUserWallet!)
    }
    
    func saveThisUserDetails(_ messagingChatUserDisplayInfo: MessagingChatUserDisplayInfo, to coreDataChat: CoreDataMessagingChat) {
        coreDataChat.thisUserWallet = messagingChatUserDisplayInfo.wallet
    }
    
    // Chat type
    func getChatType(from coreDataChat: CoreDataMessagingChat) -> MessagingChatType? {
        if coreDataChat.type == 0,
           let otherUserWallet = coreDataChat.otherUserWallet {
            var otherUserInfo = MessagingChatUserDisplayInfo(wallet: otherUserWallet)
            if let userInfo = getCoreDataDomainInfoFor(wallet: otherUserWallet) {
                otherUserInfo.domainName = userInfo.name
                otherUserInfo.pfpURL = userInfo.pfpURL
            }
            let privateChatDetails = MessagingPrivateChatDetails(otherUser: otherUserInfo)
            
            return .private(privateChatDetails)
        } else if coreDataChat.type == 1,
                  let memberWallets = coreDataChat.groupMemberWallets,
                  let pendingMembersWallets = coreDataChat.groupPendingMemberWallets {
            let members = memberWallets.map { MessagingChatUserDisplayInfo(wallet: $0) }
            let pendingMembers = pendingMembersWallets.map { MessagingChatUserDisplayInfo(wallet: $0) }
            
            let groupChatDetails = MessagingGroupChatDetails(members: members,
                                                             pendingMembers: pendingMembers)
            return .group(groupChatDetails)
        }
        
        return nil
    }
    
    func saveChatType(_ chatType: MessagingChatType, to coreDataChat: CoreDataMessagingChat) {
        switch chatType {
        case .private(let details):
            coreDataChat.type = 0
            coreDataChat.otherUserWallet = details.otherUser.wallet
        case .group(let details):
            coreDataChat.type = 1
            coreDataChat.groupMemberWallets = details.members.map { $0.wallet }
            coreDataChat.groupPendingMemberWallets = details.pendingMembers.map { $0.wallet }
        }
    }
}

// MARK: - Message parsing
private extension CoreDataMessagingStorageService {
    func convertCoreDataMessageToChatMessage(_ coreDataMessage: CoreDataMessagingChatMessage,
                                             decrypter: MessagingContentDecrypterService,
                                             wallet: String) -> MessagingChatMessage? {
        let deliveryState = MessagingChatMessageDisplayInfo.DeliveryState(rawValue: Int(coreDataMessage.deliveryState))!
        guard let type = getMessageDisplayType(from: coreDataMessage,
                                               decrypter: decrypter,
                                               deliveryState: deliveryState,
                                               wallet: wallet) else { return nil }
        
        let senderType = getMessagingChatSender(from: coreDataMessage)
        let displayInfo = MessagingChatMessageDisplayInfo(id: coreDataMessage.id!,
                                                          chatId: coreDataMessage.chatId!,
                                                          senderType: senderType,
                                                          time: coreDataMessage.time!,
                                                          type: type,
                                                          isRead: coreDataMessage.isRead,
                                                          isFirstInChat: coreDataMessage.isFirstInChat,
                                                          deliveryState: deliveryState)
        
        return MessagingChatMessage(displayInfo: displayInfo,
                                    serviceMetadata: coreDataMessage.serviceMetadata)
    }
    
    func convertChatMessageToCoreDataMessage(_ chatMessage: MessagingChatMessage) throws -> CoreDataMessagingChatMessage {
        let coreDataMessage: CoreDataMessagingChatMessage = try createEntity(in: backgroundContext)
        let displayInfo = chatMessage.displayInfo
        coreDataMessage.serviceMetadata = chatMessage.serviceMetadata
        coreDataMessage.id = displayInfo.id
        coreDataMessage.chatId = displayInfo.chatId
        coreDataMessage.time = displayInfo.time
        coreDataMessage.isRead = displayInfo.isRead
        coreDataMessage.isFirstInChat = displayInfo.isFirstInChat
        coreDataMessage.deliveryState = Int64(displayInfo.deliveryState.rawValue)
        saveMessageDisplayType(displayInfo.type, to: coreDataMessage)
        saveMessagingChatSender(displayInfo.senderType, to: coreDataMessage)
        
        return coreDataMessage
    }
    
    // Message type
    func getMessageDisplayType(from coreDataMessage: CoreDataMessagingChatMessage,
                               decrypter: MessagingContentDecrypterService,
                               deliveryState: MessagingChatMessageDisplayInfo.DeliveryState,
                               wallet: String) -> MessagingChatMessageDisplayType? {
        if coreDataMessage.messageType == 0,
           let text = coreDataMessage.messageText {
            var decryptedText = text
            if deliveryState == .delivered {
                guard let decryptedContent = try? decrypter.decryptText(text,
                                                                     with: coreDataMessage.serviceMetadata,
                                                                     wallet: wallet) else {
                    return nil }
                decryptedText = decryptedContent
            }
            
            let textDisplayInfo = MessagingChatMessageTextTypeDisplayInfo(text: decryptedText, encryptedText: text)
            return .text(textDisplayInfo)
        }
        
        return nil
    }
    
    func saveMessageDisplayType(_ messageType: MessagingChatMessageDisplayType, to coreDataMessage: CoreDataMessagingChatMessage) {
        switch messageType {
        case .text(let info):
            coreDataMessage.messageType = 0
            coreDataMessage.messageText = info.encryptedText
        }
    }
    
    // Chat Sender
    func getMessagingChatSender(from coreDataMessage: CoreDataMessagingChatMessage) -> MessagingChatSender {
        let wallet = coreDataMessage.senderWallet!
        let userDisplayInfo = MessagingChatUserDisplayInfo(wallet: wallet)
        if coreDataMessage.senderType == 0 {
            return .thisUser(userDisplayInfo)
        } else {
            return .otherUser(userDisplayInfo)
        }
    }
    
    func saveMessagingChatSender(_ messagingChatSender: MessagingChatSender, to coreDataMessage: CoreDataMessagingChatMessage) {
        func saveUserDisplayInfo(_ displayInfo: MessagingChatUserDisplayInfo) {
            coreDataMessage.senderWallet = displayInfo.wallet
        }
        switch messagingChatSender {
        case .thisUser(let displayInfo):
            coreDataMessage.senderType = 0
            saveUserDisplayInfo(displayInfo)
        case .otherUser(let displayInfo):
            coreDataMessage.senderType = 1
            saveUserDisplayInfo(displayInfo)
        }
    }
}

// MARK: - News Channel
private extension CoreDataMessagingStorageService {
    func convertCoreDataChannelToMessagingChannel(_ coreDataChannel: CoreDataMessagingNewsChannel) -> MessagingNewsChannel? {
        // Last message
        var lastMessage: MessagingNewsChannelFeed?
        if let coreDataLastMessage = coreDataChannel.lastFeed,
           let message = convertCoreDataChannelFeedToMessagingChannelFeed(coreDataLastMessage) {
            lastMessage = message
        }
        
        let newsChannel = MessagingNewsChannel(id: coreDataChannel.id!,
                                               userId: coreDataChannel.userId!,
                                               channel: coreDataChannel.channel!,
                                               name: coreDataChannel.name!,
                                               info: coreDataChannel.info!,
                                               url: coreDataChannel.url!,
                                               icon: coreDataChannel.icon!,
                                               verifiedStatus: Int(coreDataChannel.verifiedStatus),
                                               blocked: coreDataChannel.blocked ? 1 : 0,
                                               subscriberCount: Int(coreDataChannel.subscriberCount),
                                               unreadMessagesCount: 0,
                                               lastMessage: lastMessage)
        
        return newsChannel
    }
    
    func convertMessagingChannelToCoreDataChannel(_ channel: MessagingNewsChannel,
                                                  for wallet: String) throws -> CoreDataMessagingNewsChannel {
        let coreDataChannel: CoreDataMessagingNewsChannel = try createEntity(in: backgroundContext)
        
        coreDataChannel.id = channel.id
        coreDataChannel.userId = channel.userId
        coreDataChannel.channel = channel.channel
        coreDataChannel.wallet = wallet
        coreDataChannel.name = channel.name
        coreDataChannel.info = channel.info
        coreDataChannel.url = channel.url
        coreDataChannel.icon = channel.icon
        coreDataChannel.verifiedStatus = Int64(channel.verifiedStatus)
        coreDataChannel.blocked = channel.blocked == 1
        coreDataChannel.subscriberCount = Int64(channel.subscriberCount)
//        coreDataChannel.lastMessageTime = channel.lastMessageTime
        
        if let lastMessage = channel.lastMessage,
           let lastCoreDataMessage: CoreDataMessagingNewsChannelFeed = getCoreDataEntityWith(id: lastMessage.id) {
            coreDataChannel.lastFeed = lastCoreDataMessage
        }
        
        return coreDataChannel
    }
}

// MARK: - News Channel Feed
private extension CoreDataMessagingStorageService {
    func convertCoreDataChannelFeedToMessagingChannelFeed(_ coreDataNewsFeed: CoreDataMessagingNewsChannelFeed) -> MessagingNewsChannelFeed? {
        let feed = MessagingNewsChannelFeed(id: coreDataNewsFeed.id!,
                                            title: coreDataNewsFeed.title!,
                                            message: coreDataNewsFeed.message!,
                                            link: coreDataNewsFeed.link!,
                                            time: coreDataNewsFeed.time!,
                                            isRead: coreDataNewsFeed.isRead)
        
        return feed
    }
    
    func convertMessagingChannelFeedToCoreDataChannelFeed(_ channelFeed: MessagingNewsChannelFeed,
                                                          in channel: MessagingNewsChannel) throws -> CoreDataMessagingNewsChannelFeed {
        let coreDataMessage: CoreDataMessagingNewsChannelFeed = try createEntity(in: backgroundContext)
        coreDataMessage.id = channelFeed.id
        coreDataMessage.title = channelFeed.title
        coreDataMessage.message = channelFeed.message
        coreDataMessage.link = channelFeed.link
        coreDataMessage.time = channelFeed.time
        coreDataMessage.isRead = channelFeed.isRead
        coreDataMessage.channelId = channel.id
        
        return coreDataMessage
    }
}

// MARK: - User Info
private extension CoreDataMessagingStorageService {
    func convertChatUserDisplayInfoToMessagingUserInfo(_ displayInfo: MessagingChatUserDisplayInfo) throws -> CoreDataMessagingUserInfo {
        let coreDataUserInfo: CoreDataMessagingUserInfo = try createEntity(in: backgroundContext)
        coreDataUserInfo.wallet = displayInfo.wallet
        coreDataUserInfo.name = displayInfo.domainName
        coreDataUserInfo.pfpURL = displayInfo.pfpURL
        
        return coreDataUserInfo
    }
    
    func getCoreDataDomainInfoFor(wallet: String) -> CoreDataMessagingUserInfo? {
        let predicate = NSPredicate(format: "wallet == %@", wallet)
        let infos: [CoreDataMessagingUserInfo]? = try? getEntities(predicate: predicate, from: backgroundContext)
        return infos?.first
    }
}

// MARK: - Private methods
private extension CoreDataMessagingStorageService {
    func getCoreDataEntityWith<T: NSManagedObject>(id: String) -> T? {
        getCoreDataEntityWith(key: "id", value: id)
    }
    
    func getCoreDataEntityWith<T: NSManagedObject>(key: String, value: String) -> T? {
        do {
            let predicate = NSPredicate(format: "%K == %@", key, value)
            let messages: [T] = try getEntities(predicate: predicate, from: backgroundContext)
            return messages.first
        } catch {
            
            return nil
        }
    }
}

// MARK: - Open methods
extension CoreDataMessagingStorageService {
    enum Error: Swift.Error {
        case domainWithoutWallet
        case failedToFetch
        case entityNotFound
    }
}
