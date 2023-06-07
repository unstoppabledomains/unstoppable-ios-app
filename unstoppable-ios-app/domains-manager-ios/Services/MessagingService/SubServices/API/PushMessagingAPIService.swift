//
//  PushMessagingAPIService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.05.2023.
//

import Foundation
import Push

final class PushMessagingAPIService {
    
    private let pushRESTService = PushRESTAPIService()
    
    private var walletToPushUserCache: [HexAddress : PushUser] = [:]
    
}

// MARK: - MessagingAPIServiceProtocol
extension PushMessagingAPIService: MessagingAPIServiceProtocol {
    func getUserFor(wallet: HexAddress) async throws -> MessagingChatUserDisplayInfo {
        let pushUser = try await getPushUserFor(wallet: wallet)
        return convertPushUserToChatUser(pushUser)
    }
    
    func createUser(for domain: DomainItem) async throws -> MessagingChatUserDisplayInfo {
        let wallet = try await domain.getAddress()
        let env = getCurrentPushEnvironment()
        let pushUser = try await PushUser.create(options: .init(env: env,
                                                                 signer: domain,
                                                                 version: .PGP_V3,
                                                                 progressHook: nil))
        walletToPushUserCache[wallet] = pushUser
        let chatUser = convertPushUserToChatUser(pushUser)
        return chatUser
    }
    
    func getChatsListForWallet(_ wallet: HexAddress,
                               page: Int,
                               limit: Int) async throws -> [MessagingChat] {
        let pushChats = try await pushRESTService.getChats(for: wallet,
                                                       page: page,
                                                       limit: limit,
                                                       isRequests: false)
        
        let chats = pushChats.compactMap({ convertPushChatToChat($0,
                                                                 userWallet: wallet,
                                                                 isApproved: true) })
        return chats
    }
    
    func getChatRequestsForWallet(_ wallet: HexAddress,
                                  page: Int,
                                  limit: Int) async throws -> [MessagingChat] {
        let pushChats = try await pushRESTService.getChats(for: wallet,
                                                           page: page,
                                                           limit: limit,
                                                           isRequests: true)
        let chats = pushChats.compactMap({ convertPushChatToChat($0,
                                                                 userWallet: wallet,
                                                                 isApproved: false) })
        return chats
    }
    
    func getMessagesForChat(_ chat: MessagingChat,
                            fetchLimit: Int) async throws -> [MessagingChatMessage] {
        let chatMetadata: ChatServiceMetadata = try decodeServiceMetadata(from: chat.serviceMetadata)
        guard let threadHash = chatMetadata.threadHash else {
            return [] // NULL threadHash means there's no messages in the chat yet
        }
        
        let wallet = chat.displayInfo.thisUserDetails.wallet
        let pgpPrivateKey = try await getPGPPrivateKeyFor(wallet: wallet)
        let env = getCurrentPushEnvironment()
        let pushMessages = try await Push.PushChat.History(threadHash: threadHash,
                                                    limit: fetchLimit,
                                                    pgpPrivateKey: pgpPrivateKey,
                                                    env: env)
        
        let messages = pushMessages.compactMap({ convertPushMessageToChatMessage($0, in: chat) })
        return messages
    }
    
    func sendMessage(_ messageType: MessagingChatMessageDisplayType,
                     in chat: MessagingChat) async throws -> MessagingChatMessage {
        let env = getCurrentPushEnvironment()
        let pushMessageContent = getPushMessageContentFrom(displayType: messageType)
        let pushMessageType = getPushMessageTypeFrom(displayType: messageType)
        let sender = chat.displayInfo.thisUserDetails
        let pgpPrivateKey = try await getPGPPrivateKeyFor(wallet: sender.wallet)

        switch chat.displayInfo.type {
        case .private(let otherUserDetails):
            let receiver = otherUserDetails.otherUser
            let sendOptions = Push.PushChat.SendOptions(messageContent: pushMessageContent,
                                                        messageType: pushMessageType.rawValue,
                                                        receiverAddress: receiver.wallet,
                                                        account: sender.wallet,
                                                        pgpPrivateKey: pgpPrivateKey,
                                                        env: env)
            let chatMetadata: ChatServiceMetadata = try decodeServiceMetadata(from: chat.serviceMetadata)
            let isConversationFirst = chatMetadata.threadHash == nil
            
            let message: Push.Message
            if isConversationFirst {
                message = try await Push.PushChat.sendIntent(sendOptions)
            } else {
                message = try await Push.PushChat.sendMessage(sendOptions)
            }
            
            guard let chatMessage = convertPushMessageToChatMessage(message, in: chat) else { throw PushMessagingAPIServiceError.failedToConvertPushMessage }
            
            return chatMessage
        case .group(let groupDetails):
            throw PushMessagingAPIServiceError.sendMessageInGroupChatNotSupported  // Group chats not supported for now
        }
    }
    
    func makeChatRequest(_ chat: MessagingChat, approved: Bool) async throws {
        guard approved else { throw PushMessagingAPIServiceError.declineRequestNotSupported }
        guard case .private(let otherUserDetails) = chat.displayInfo.type else { throw PushMessagingAPIServiceError.sendMessageInGroupChatNotSupported }
        
        let env = getCurrentPushEnvironment()
        let sender = chat.displayInfo.thisUserDetails
        let pgpPrivateKey = try await getPGPPrivateKeyFor(wallet: sender.wallet)

        let approveOptions = Push.PushChat.ApproveOptions(fromAddress: sender.wallet ,
                                                          toAddress: otherUserDetails.otherUser.wallet,
                                                          privateKey: pgpPrivateKey,
                                                          env: env)
        _ = try await Push.PushChat.approve(approveOptions)
    }
}

// MARK: - Private methods
private extension PushMessagingAPIService {
    func getPushUserFor(wallet: HexAddress) async throws -> PushUser {
        if let pushUser = walletToPushUserCache[wallet] {
            return pushUser
        }
        let env = getCurrentPushEnvironment()
        guard let pushUser = try await PushUser.get(account: wallet, env: env) else {
            throw PushMessagingAPIServiceError.failedToGetPushUser
        }
        return pushUser
    }
    
    func getPGPPrivateKeyFor(wallet: HexAddress) async throws -> String {
        let user = try await getPushUserFor(wallet: wallet)
        let domain = try await getReverseResolutionDomainItem(for: wallet)
        let pgpPrivateKey = try await PushUser.DecryptPGPKey(encryptedPrivateKey: user.encryptedPrivateKey, signer: domain)
        return pgpPrivateKey
    }
    
    func getReverseResolutionDomainItem(for wallet: HexAddress) async throws -> DomainItem {
        guard let domainName = await appContext.dataAggregatorService.getReverseResolutionDomain(for: wallet) else {
            throw PushMessagingAPIServiceError.noRRDomainForWallet
        }
        
        return try await appContext.dataAggregatorService.getDomainWith(name: domainName)
    }
    
    func getCurrentPushEnvironment() -> Push.ENV {
        let isTestnetUsed = User.instance.getSettings().isTestnetUsed
        return isTestnetUsed ? .DEV : .PROD
    }
    
    func convertPushUserToChatUser(_ pushUser: PushUser) -> MessagingChatUserDisplayInfo {
        MessagingChatUserDisplayInfo(wallet: pushUser.wallets,
                                     domain: nil)
    }
    
    func convertPushChatToChat(_ pushChat: PushChat,
                               userWallet: String,
                               isApproved: Bool) -> MessagingChat? {
        
        func convertChatMembersToUserDisplayInfo(_ members: [PushGroupChatMember]) -> [MessagingChatUserDisplayInfo] {
            members.compactMap({
                if $0.wallet == userWallet {
                    return nil // Exclude current user from other members list
                } else {
                    return getWalletAddressFrom(eip155String: $0.wallet)
                }
            }).map({ MessagingChatUserDisplayInfo(wallet: $0) })
        }
        
        let thisUserInfo = MessagingChatUserDisplayInfo(wallet: userWallet)
        let chatType: MessagingChatType
        if let groupInfo = pushChat.groupInformation {
            let members = convertChatMembersToUserDisplayInfo(groupInfo.members)
            let pendingMembers = convertChatMembersToUserDisplayInfo(groupInfo.pendingMembers)
            let groupChatDetails = MessagingGroupChatDetails(members: members,
                                                               pendingMembers: pendingMembers)
            chatType = .group(groupChatDetails)
        } else {
            let fromUserEip = pushChat.intentSentBy
            guard let fromUserWallet = getWalletAddressFrom(eip155String: fromUserEip),
                  let toUserEip = pushChat.did,
                  let toUserWallet = getWalletAddressFrom(eip155String: toUserEip) else { return nil }
            let otherUserWallet = userWallet.lowercased() == fromUserWallet.lowercased() ? toUserWallet : fromUserWallet
            let otherUserInfo = MessagingChatUserDisplayInfo(wallet: otherUserWallet)
            let privateChatDetails = MessagingPrivateChatDetails(otherUser: otherUserInfo)
            chatType = .private(privateChatDetails)
        }
        
        var avatarURL: URL?
        if let profilePicture = pushChat.profilePicture {
            avatarURL = URL(string: profilePicture)
        }
        
        let displayInfo = MessagingChatDisplayInfo(id: pushChat.chatId,
                                                   thisUserDetails: thisUserInfo,
                                                   avatarURL: avatarURL,
                                                   type: chatType,
                                                   unreadMessagesCount: 0,
                                                   isApproved: isApproved,
                                                   lastMessage: nil)
        
        let metadataModel = ChatServiceMetadata(threadHash: pushChat.threadhash)
        let serviceMetadata = metadataModel.jsonData()
        let chat = MessagingChat(displayInfo: displayInfo,
                                    serviceMetadata: serviceMetadata)
        return chat
    }

    func convertPushMessageToChatMessage(_ pushMessage: Push.Message,
                                         in chat: MessagingChat) -> MessagingChatMessage? {
        guard let senderWallet = getWalletAddressFrom(eip155String: pushMessage.fromDID),
              let messageType = PushMessageType(rawValue: pushMessage.messageType) else { return nil }
        
        switch messageType {
        case .text:
            var time = Date()
            var id = "\(pushMessage.fromDID)_\(pushMessage.messageContent)"
            
            if let timestamp = pushMessage.timestamp {
                time = Date(millisecondsSince1970: timestamp)
                id += "_\(timestamp)"
            }
            let textDisplayInfo = MessagingChatMessageTextTypeDisplayInfo(text: pushMessage.messageContent)
            let userDisplayInfo = MessagingChatUserDisplayInfo(wallet: senderWallet)
            let sender: MessagingChatSender
            if chat.displayInfo.thisUserDetails.wallet == senderWallet {
                sender = .thisUser(userDisplayInfo)
            } else {
                sender = .otherUser(userDisplayInfo)
            }
            let displayInfo = MessagingChatMessageDisplayInfo(id: id,
                                                              chatId: chat.displayInfo.id,
                                                              senderType: sender,
                                                              time: time,
                                                              type: .text(textDisplayInfo),
                                                              isRead: false,
                                                              deliveryState: .delivered)
            let textMessage = MessagingChatMessage(displayInfo: displayInfo,
                                                   serviceMetadata: nil)
            return textMessage
        default:
            return nil // Not supported for now
        }
    }
    
    func decodeServiceMetadata<T: Codable>(from data: Data?) throws -> T {
        guard let data else {
            throw PushMessagingAPIServiceError.failedToDecodeServiceData
        }
        guard let serviceMetadata = T.objectFromData(data) else {
            throw PushMessagingAPIServiceError.failedToDecodeServiceData
        }
        
        return serviceMetadata
    }
   
    func getPushMessageContentFrom(displayType: MessagingChatMessageDisplayType) -> String {
        switch displayType {
        case .text(let details):
            return details.text
        }
    }
    
    func getPushMessageTypeFrom(displayType: MessagingChatMessageDisplayType) -> PushMessageType {
        switch displayType {
        case .text:
            return .text
        }
    }
}

// MARK: - Private methods
private extension PushMessagingAPIService {
    struct ChatServiceMetadata: Codable {
        let threadHash: String?
    }
    
    func getWalletAddressFrom(eip155String: String) -> String? {
        let components = eip155String.components(separatedBy: ":")
        if components.count == 2 {
            return components[1]
        }
        return nil
    }
    
    enum PushMessageType: String {
        case text = "Text"
        case image = "Image"
        case file = "File"
        case gif = "GIF"
    }
}

// MARK: - Open methods
extension PushMessagingAPIService {
    enum PushMessagingAPIServiceError: Error {
        case noRRDomainForWallet
        case noOwnerWalletInDomain
        case failedToGetPushUser
        case incorrectDataState
        
        case failedToDecodeServiceData
        case failedToConvertPushMessage
        case sendMessageInGroupChatNotSupported
        case declineRequestNotSupported
    }
}

extension DomainItem: Push.Signer {
    func getEip191Signature(message: String) async throws -> String {
        try await self.personalSign(message: message)
    }
    
    func getAddress() async throws -> String {
        guard let ownerWallet else { throw PushMessagingAPIService.PushMessagingAPIServiceError.noOwnerWalletInDomain }
        
        return ownerWallet
    }
}
