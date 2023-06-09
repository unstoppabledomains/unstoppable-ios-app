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
    
    override init() {
        super.init()
        contextHolder = ContextHolder(context: currentContext)
    }
}

// MARK: - MessagingStorageServiceProtocol
extension CoreDataMessagingStorageService: MessagingStorageServiceProtocol {
    func getMessages() async throws -> [MessagingChatMessage] {
        let coreDataMessages: [CoreDataMessagingChatMessage] = try getEntities()
        
        return coreDataMessages.compactMap { convertCoreDataMessageToChatMessage($0) }
    }
    
    func saveMessages(_ messages: [MessagingChatMessage]) async {
        let _ = messages.compactMap { (try? convertChatMessageToCoreDataMessage($0)) }
        await contextHolder.save()
    }
    
    func getChatsFor(wallet: String) async throws -> [MessagingChat] {
        let predicate = NSPredicate(format: "thisUserWallet == %@", wallet)
        let timeSortDescriptor = NSSortDescriptor(key: "lastMessageTime", ascending: false)
        let coreDataChats: [CoreDataMessagingChat] = try getEntities(predicate: predicate,
                                                                     sortDescriptions: [timeSortDescriptor])
        
        return coreDataChats.compactMap { convertCoreDataChatToMessagingChat($0) }
    }
    
    func saveChats(_ chats: [MessagingChat]) async {
        let _ = chats.compactMap { (try? convertMessagingChatToCoreDataChat($0)) }
        await contextHolder.save()
    }
    
    func clear() {
        do {
            let coreDataChats: [CoreDataMessagingChat] = try getEntities()
            deleteObjects(coreDataChats, shouldSaveContext: true)
        } catch { }
    }
}

// MARK: - Message parsing
private extension CoreDataMessagingStorageService {
    func convertCoreDataMessageToChatMessage(_ coreDataMessage: CoreDataMessagingChatMessage) -> MessagingChatMessage? {
        guard let type = getMessageDisplayType(from: coreDataMessage) else { return nil }
        
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
    func getMessageDisplayType(from coreDataMessage: CoreDataMessagingChatMessage) -> MessagingChatMessageDisplayType? {
        if coreDataMessage.messageType == 0,
           let text = coreDataMessage.messageText {
            let textDisplayInfo = MessagingChatMessageTextTypeDisplayInfo(text: text)
            return .text(textDisplayInfo)
        }
        
        return nil
    }
    
    func saveMessageDisplayType(_ messageType: MessagingChatMessageDisplayType, to coreDataMessage: CoreDataMessagingChatMessage) {
        switch messageType {
        case .text(let info):
            coreDataMessage.messageType = 0
            coreDataMessage.messageText = info.text
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

// MARK: - Chats parsing
private extension CoreDataMessagingStorageService {
    func convertCoreDataChatToMessagingChat(_ coreDataChat: CoreDataMessagingChat) -> MessagingChat? {
        guard let chatType = getChatType(from: coreDataChat) else { return nil }
        
        let serviceMetadata = coreDataChat.serviceMetadata
        // Avatar URL
        var avatarURL: URL?
        if let urlStr = coreDataChat.avatarURL {
            avatarURL = URL(string: urlStr)
        }
        
        // Last message
        var lastMessage: MessagingChatMessageDisplayInfo?
        if let coreDataLastMessage = coreDataChat.lastMessage,
           let message = convertCoreDataMessageToChatMessage(coreDataLastMessage) {
            lastMessage = message.displayInfo
        }
        
        let thisUserDetails = getThisUserDetails(from: coreDataChat)
        let displayInfo = MessagingChatDisplayInfo(id: coreDataChat.id!,
                                                   thisUserDetails: thisUserDetails,
                                                   avatarURL: avatarURL,
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
        coreDataChat.avatarURL = displayInfo.avatarURL?.absoluteString
        coreDataChat.isApproved = displayInfo.isApproved
        coreDataChat.lastMessageTime = displayInfo.lastMessageTime
        
        if let lastMessage = chat.displayInfo.lastMessage,
           let lastCoreDataMessage = getCoreDataMessageWith(id: lastMessage.id) {
            coreDataChat.lastMessage = lastCoreDataMessage
        }
        
        saveThisUserDetails(displayInfo.thisUserDetails, to: coreDataChat)
        saveChatType(displayInfo.type, to: coreDataChat)
        
        return coreDataChat
    }
    
    func getCoreDataMessageWith(id: String) -> CoreDataMessagingChatMessage? {
        do {
            let predicate = NSPredicate(format: "id == %@", id)
            let messages: [CoreDataMessagingChatMessage] = try getEntities(predicate: predicate)
            return messages.first
        } catch {
            return nil
        }
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
            let privateChatDetails = MessagingPrivateChatDetails(otherUser: .init(wallet: otherUserWallet))
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

// MARK: - Private methods
private extension CoreDataMessagingStorageService {
    actor ContextHolder {
        let context: NSManagedObjectContext
        
        init(context: NSManagedObjectContext) {
            self.context = context
        }
        
        func save() {
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
