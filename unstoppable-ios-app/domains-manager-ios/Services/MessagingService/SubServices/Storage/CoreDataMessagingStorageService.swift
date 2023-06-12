//
//  CoreDataMessagingStorageService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2023.
//

import Foundation
import CoreData

final class CoreDataMessagingStorageService: CoreDataService {
    
    override var currentContext: NSManagedObjectContext { backgroundContext }
    private var contextHolder: ContextHolder!
  
    override func didLoadPersistentContainer() {
        super.didLoadPersistentContainer()
        
        contextHolder = ContextHolder(context: currentContext)
    }
}

// MARK: - MessagingStorageServiceProtocol
extension CoreDataMessagingStorageService: MessagingStorageServiceProtocol {
    // Messages
    func getMessages(decrypter: MessagingContentDecrypterService,
                     wallet: String) async throws -> [MessagingChatMessage] {
        let coreDataMessages: [CoreDataMessagingChatMessage] = try getEntities()
        
        return coreDataMessages.compactMap { convertCoreDataMessageToChatMessage($0,
                                                                                 decrypter: decrypter,
                                                                                 wallet: wallet) }
    }
    
    func saveMessages(_ messages: [MessagingChatMessage]) async {
        let _ = messages.compactMap { (try? convertChatMessageToCoreDataMessage($0)) }
        contextHolder.save()
    }
    
    // Chats
    func getChatsFor(decrypter: MessagingContentDecrypterService,
                     wallet: String) async throws -> [MessagingChat] {
        let predicate = NSPredicate(format: "thisUserWallet == %@", wallet)
        let timeSortDescriptor = NSSortDescriptor(key: "lastMessageTime", ascending: false)
        let coreDataChats: [CoreDataMessagingChat] = try getEntities(predicate: predicate,
                                                                     sortDescriptions: [timeSortDescriptor])
        
        return coreDataChats.compactMap { convertCoreDataChatToMessagingChat($0,
                                                                             decrypter: decrypter) }
    }
    
    func saveChats(_ chats: [MessagingChat]) async {
        let _ = chats.compactMap { (try? convertMessagingChatToCoreDataChat($0)) }
        contextHolder.save()
    }
    
    // User info
    func saveMessagingUserInfo(_ info: MessagingChatUserDisplayInfo) async {
        let _ = try? convertChatUserDisplayInfoToMessagingUserInfo(info)
        contextHolder.save()
    }
    
    // Channels
    func getChannelsFor(wallet: String) async throws -> [MessagingNewsChannel] {
        let predicate = NSPredicate(format: "wallet == %@", wallet)
        let coreDataChannels: [CoreDataMessagingNewsChannel] = try getEntities(predicate: predicate)
        
        return coreDataChannels.compactMap { convertCoreDataChannelToMessagingChannel($0) }
    }
    
    func saveChannels(_ channels: [MessagingNewsChannel],
                      for wallet: String) async {
        let _ = channels.compactMap { (try? convertMessagingChannelToCoreDataChannel($0, for: wallet)) }
        contextHolder.save()
    }
    
    // Channels Feed
    func getChannelsFeedFor(channel: MessagingNewsChannel) async throws -> [MessagingNewsChannelFeed] {
        let predicate = NSPredicate(format: "channelId == %@", channel.id)
        let coreDataChannelsFeed: [CoreDataMessagingNewsChannelFeed] = try getEntities(predicate: predicate)
        
        return coreDataChannelsFeed.compactMap { convertCoreDataChannelFeedToMessagingChannelFeed($0) }
    }
    
    func saveChannelsFeed(_ feed: [MessagingNewsChannelFeed],
                          in channel: MessagingNewsChannel) async {
        let _ = feed.compactMap { (try? convertMessagingChannelFeedToCoreDataChannelFeed($0, in: channel)) }
        contextHolder.save()
    }
    
    // Clear
    func clear() {
        do {
            let coreDataChats: [CoreDataMessagingChat] = try getEntities()
            deleteObjects(coreDataChats, shouldSaveContext: false)

            let coreDataMessages: [CoreDataMessagingChatMessage] = try getEntities()
            deleteObjects(coreDataMessages, shouldSaveContext: false)
            
            let coreDataNews: [CoreDataMessagingNewsChannel] = try getEntities()
            deleteObjects(coreDataNews, shouldSaveContext: false)
            
            let coreDataNewsFeed: [CoreDataMessagingNewsChannelFeed] = try getEntities()
            deleteObjects(coreDataNewsFeed, shouldSaveContext: false)
            
            let coreDataUsersInfo: [CoreDataMessagingUserInfo] = try getEntities()
            deleteObjects(coreDataUsersInfo, shouldSaveContext: true)
        } catch { }
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
        }
        
        let thisUserDetails = getThisUserDetails(from: coreDataChat)
        let displayInfo = MessagingChatDisplayInfo(id: coreDataChat.id!,
                                                   thisUserDetails: thisUserDetails,
                                                   avatarURL: coreDataChat.avatarURL,
                                                   type: chatType,
                                                   unreadMessagesCount: 0,
                                                   isApproved: coreDataChat.isApproved,
                                                   lastMessageTime: coreDataChat.lastMessageTime!,
                                                   lastMessage: lastMessage)
        
        return MessagingChat(displayInfo: displayInfo,
                             serviceMetadata: serviceMetadata)
    }
    
    func convertMessagingChatToCoreDataChat(_ chat: MessagingChat) throws -> CoreDataMessagingChat {
        let coreDataChat: CoreDataMessagingChat = try createEntity()
        let displayInfo = chat.displayInfo
        
        coreDataChat.serviceMetadata = chat.serviceMetadata
        coreDataChat.id = displayInfo.id
        coreDataChat.avatarURL = displayInfo.avatarURL
        coreDataChat.isApproved = displayInfo.isApproved
        coreDataChat.lastMessageTime = displayInfo.lastMessageTime
        
        if let lastMessage = chat.displayInfo.lastMessage,
           let lastCoreDataMessage: CoreDataMessagingChatMessage = getCoreDataEntityWith(id: lastMessage.id) {
            coreDataChat.lastMessage = lastCoreDataMessage
        }
        
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
        guard let type = getMessageDisplayType(from: coreDataMessage,
                                               decrypter: decrypter,
                                               wallet: wallet) else { return nil }
        
        let senderType = getMessagingChatSender(from: coreDataMessage)
        let deliveryState = MessagingChatMessageDisplayInfo.DeliveryState(rawValue: Int(coreDataMessage.deliveryState))!
        let displayInfo = MessagingChatMessageDisplayInfo(id: coreDataMessage.id!,
                                                          chatId: coreDataMessage.chatId!,
                                                          senderType: senderType,
                                                          time: coreDataMessage.time!,
                                                          type: type,
                                                          isRead: coreDataMessage.isRead,
                                                          deliveryState: deliveryState)
        
        return MessagingChatMessage(displayInfo: displayInfo,
                                    serviceMetadata: coreDataMessage.serviceMetadata)
    }
    
    func convertChatMessageToCoreDataMessage(_ chatMessage: MessagingChatMessage) throws -> CoreDataMessagingChatMessage {
        let coreDataMessage: CoreDataMessagingChatMessage = try createEntity()
        let displayInfo = chatMessage.displayInfo
        coreDataMessage.serviceMetadata = chatMessage.serviceMetadata
        coreDataMessage.id = displayInfo.id
        coreDataMessage.chatId = displayInfo.chatId
        coreDataMessage.time = displayInfo.time
        coreDataMessage.isRead = displayInfo.isRead
        coreDataMessage.deliveryState = Int64(displayInfo.deliveryState.rawValue)
        saveMessageDisplayType(displayInfo.type, to: coreDataMessage)
        saveMessagingChatSender(displayInfo.senderType, to: coreDataMessage)
        
        return coreDataMessage
    }
    
    // Message type
    func getMessageDisplayType(from coreDataMessage: CoreDataMessagingChatMessage,
                               decrypter: MessagingContentDecrypterService,
                               wallet: String) -> MessagingChatMessageDisplayType? {
        if coreDataMessage.messageType == 0,
           let text = coreDataMessage.messageText {
            guard let decryptedText = try? decrypter.decryptText(text,
                                                                 with: coreDataMessage.serviceMetadata,
                                                                 wallet: wallet) else { return nil }
            
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
        let coreDataChannel: CoreDataMessagingNewsChannel = try createEntity()
        
        coreDataChannel.id = channel.id
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
        let coreDataMessage: CoreDataMessagingNewsChannelFeed = try createEntity()
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
        let coreDataUserInfo: CoreDataMessagingUserInfo = try createEntity()
        coreDataUserInfo.wallet = displayInfo.wallet
        coreDataUserInfo.name = displayInfo.domainName
        coreDataUserInfo.pfpURL = displayInfo.pfpURL
        
        return coreDataUserInfo
    }
    
    func getCoreDataDomainInfoFor(wallet: String) -> CoreDataMessagingUserInfo? {
        let predicate = NSPredicate(format: "wallet == %@", wallet)
        let infos: [CoreDataMessagingUserInfo]? = try? getEntities(predicate: predicate)
        return infos?.first
    }
}

// MARK: - Private methods
private extension CoreDataMessagingStorageService {
    func getCoreDataEntityWith<T: NSManagedObject>(id: String) -> T? {
        do {
            let predicate = NSPredicate(format: "id == %@", id)
            let messages: [T] = try getEntities(predicate: predicate)
            return messages.first
        } catch {
            return nil
        }
    }
}

// MARK: - ContextHolder
private extension CoreDataMessagingStorageService {
    final class ContextHolder {
        let context: NSManagedObjectContext
        private let queue = DispatchQueue(label: "com.unstoppabledomains.coredata.context")
        
        init(context: NSManagedObjectContext) {
            self.context = context
        }
        
        func save() {
            queue.sync {
                Debugger.printInfo(topic: .CoreData, "Save context")
                if self.context.hasChanges {
                    do {
                        try self.context.save()
                    } catch {
                        Debugger.printFailure("An error occurred while saving context, error: \(error)", critical: true)
                    }
                }
            }
        }
    }
}
