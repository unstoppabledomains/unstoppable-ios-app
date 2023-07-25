//
//  XMTPEntitiesTransformer.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.07.2023.
//

import UIKit
import XMTP

struct XMTPEntitiesTransformer {
    
    static func convertXMTPClientToChatUser(_ client: XMTP.Client) -> MessagingChatUserProfile {
        let wallet = client.address
        let userId = client.address
        let displayInfo = MessagingChatUserProfileDisplayInfo(id: userId,
                                                              wallet: wallet,
                                                              name: nil,
                                                              about: nil,
                                                              unreadMessagesCount: nil)
        let userProfile = MessagingChatUserProfile(id: userId,
                                                   wallet: wallet,
                                                   displayInfo: displayInfo,
                                                   serviceMetadata: nil)
        return userProfile
        
    }
    
    
    static func convertXMTPChatToChat(_ xmtpChat: XMTP.Conversation,
                                      userId: String,
                                      userWallet: String,
                                      isApproved: Bool) -> MessagingChat? {
        
        let thisUserInfo = MessagingChatUserDisplayInfo(wallet: userWallet)
        let chatType: MessagingChatType
        
        // MARK: - Group chats not supported at the moment
        //        if xmtpChat.isGroup {
        //            let groupChatDetails = MessagingGroupChatDetails(members: [],
        //                                                             pendingMembers: [],
        //                                                             name: "",
        //                                                             adminWallets: [userWallet],
        //                                                             isPublic: false)
        //            chatType = .group(groupChatDetails)
        //        } else {
        let otherUserWallet = xmtpChat.peerAddress
        let otherUserInfo = MessagingChatUserDisplayInfo(wallet: otherUserWallet)
        let privateChatDetails = MessagingPrivateChatDetails(otherUser: otherUserInfo)
        chatType = .private(privateChatDetails)
        //        }
        
        let avatarURL: URL? = nil
        let lastMessageTime = Date() // TODO: - Make optional?
        let chatId = xmtpChat.topic
        let displayInfo = MessagingChatDisplayInfo(id: chatId,
                                                   thisUserDetails: thisUserInfo,
                                                   avatarURL: avatarURL,
                                                   type: chatType,
                                                   unreadMessagesCount: 0,
                                                   isApproved: isApproved,
                                                   lastMessageTime: lastMessageTime,
                                                   lastMessage: nil)
        
        let metadataModel = XMTPEnvironmentNamespace.ChatServiceMetadata(encodedContainer: xmtpChat.encodedContainer)
        let serviceMetadata = metadataModel.jsonData()
        let chat = MessagingChat(userId: userId,
                                 displayInfo: displayInfo,
                                 serviceMetadata: serviceMetadata)
        return chat
    }
    
    static func convertXMTPMessageToChatMessage(_ xmtpMessage: XMTP.DecodedMessage,
                                                in chat: MessagingChat,
                                                isRead: Bool,
                                                filesService: MessagingFilesServiceProtocol) -> MessagingChatMessage? {
        let id = xmtpMessage.id
        let userId = chat.userId
        let metadataModel = XMTPEnvironmentNamespace.MessageServiceMetadata(encodedContent: xmtpMessage.encodedContent)
        guard let serviceMetadata = metadataModel.jsonData(),
              let type = try? extractMessageType(from: xmtpMessage,
                                                 messageId: id,
                                                 userId: userId,
                                                 encryptedData: serviceMetadata,
                                                 filesService: filesService) else { return nil }
        
        let senderWallet = xmtpMessage.senderAddress
        let userDisplayInfo = MessagingChatUserDisplayInfo(wallet: senderWallet)
        let sender: MessagingChatSender
        if chat.displayInfo.thisUserDetails.wallet == senderWallet {
            sender = .thisUser(userDisplayInfo)
        } else {
            sender = .otherUser(userDisplayInfo)
        }
        let time = xmtpMessage.sent
        let isMessageEncrypted = true
        
        
        
        let displayInfo = MessagingChatMessageDisplayInfo(id: id,
                                                          chatId: chat.displayInfo.id,
                                                          userId: userId,
                                                          senderType: sender,
                                                          time: time,
                                                          type: type,
                                                          isRead: isRead,
                                                          isFirstInChat: false, // TODO: - Set this property
                                                          deliveryState: .delivered,
                                                          isEncrypted: isMessageEncrypted)
        let chatMessage = MessagingChatMessage(userId: userId,
                                               displayInfo: displayInfo,
                                               serviceMetadata: serviceMetadata)
        return chatMessage
    }
    
    
    private static func extractMessageType(from xmtpMessage: XMTP.DecodedMessage,
                                           messageId: String,
                                           userId: String,
                                           encryptedData: Data,
                                           filesService: MessagingFilesServiceProtocol) throws -> MessagingChatMessageDisplayType {
        let typeId = xmtpMessage.encodedContent.type.typeID
        if let knownType = XMTPEnvironmentNamespace.KnownType(rawValue: typeId) {
            switch knownType {
            case .text:
                let decryptedContent: String = try xmtpMessage.content()
                let encryptedContent = "" // TODO: - Encrypt content
                let textDisplayInfo = MessagingChatMessageTextTypeDisplayInfo(text: decryptedContent,
                                                                              encryptedText: encryptedContent)
                return .text(textDisplayInfo)
            case .attachment:
                let attachment: XMTP.Attachment = try xmtpMessage.content()
                if let image = UIImage(data: attachment.data) {
                    let imageDisplayInfo = MessagingChatMessageImageDataTypeDisplayInfo(encryptedData: attachment.data, // TODO: - Encrypt content
                                                                            data: attachment.data,
                                                                            image: image)
                    return .imageData(imageDisplayInfo)
                } else {
                    let name = attachment.filename
                    let data = attachment.data
                    
                    
                    let fileName = messageId + "_" + String(userId.suffix(4)) + "_" + name
                    try filesService.saveEncryptedData(encryptedData, fileName: fileName)// TODO: - Encrypt content
                    let unknownDisplayInfo = MessagingChatMessageUnknownTypeDisplayInfo(fileName: fileName,
                                                                                        type: typeId,
                                                                                        name: name,
                                                                                        size: data.count)
                    return .unknown(unknownDisplayInfo)
                }
            }
        } else {
            let fileName = messageId + "_" + String(userId.suffix(4))
            try filesService.saveEncryptedData(encryptedData, fileName: fileName)
            let unknownDisplayInfo = MessagingChatMessageUnknownTypeDisplayInfo(fileName: fileName,
                                                                                type: typeId,
                                                                                name: nil,
                                                                                size: nil)
            return .unknown(unknownDisplayInfo)
        }
    }
    
    static func convertXMTPMessageToWebSocketMessageEntity(_ xmtpMessage: XMTP.DecodedMessage,
                                                           peerAddress: String,
                                                           userAddress: String) -> MessagingWebSocketMessageEntity {
        let id = xmtpMessage.id
        let senderWallet = xmtpMessage.senderAddress
        let receiverWallet = senderWallet == peerAddress ? userAddress : peerAddress
        let serviceContent = XMTPEnvironmentNamespace.XMTPSocketMessageServiceContent(xmtpMessage: xmtpMessage)
        return MessagingWebSocketMessageEntity(id: id,
                                               senderWallet: senderWallet,
                                               receiverWallet: receiverWallet,
                                               serviceContent: serviceContent,
                                               transformToMessageBlock: convertMessagingWebSocketMessageEntityToChatMessage)
    }
    
    private static func convertMessagingWebSocketMessageEntityToChatMessage(_ webSocketMessage: MessagingWebSocketMessageEntity,
                                                                    in chat: MessagingChat,
                                                                    filesService: MessagingFilesServiceProtocol) -> MessagingChatMessage? {
        guard let serviceContent = webSocketMessage.serviceContent as? XMTPEnvironmentNamespace.XMTPSocketMessageServiceContent else { return nil }
        
        let thisUserWallet = chat.displayInfo.thisUserDetails.wallet
        
        return convertXMTPMessageToChatMessage(serviceContent.xmtpMessage,
                                               in: chat,
                                               isRead: thisUserWallet == webSocketMessage.senderWallet,
                                               filesService: filesService)
    }
    
    static func convertXMTPConversationToWebSocketChatEntity(_ conversation: Conversation,
                                                             userId: String) -> MessagingWebSocketChatEntity {
        let serviceContent = XMTPEnvironmentNamespace.XMTPSocketChatServiceContent(conversation: conversation)
        return MessagingWebSocketChatEntity(userId: userId,
                                            serviceContent: serviceContent,
                                            transformToChatBlock: convertMessagingWebSocketChatEntityToChat)
    }
    
    private static func convertMessagingWebSocketChatEntityToChat(_ webSocketChat: MessagingWebSocketChatEntity,
                                                                  profile: MessagingChatUserProfile) -> MessagingChat? {
        guard let serviceContent = webSocketChat.serviceContent as? XMTPEnvironmentNamespace.XMTPSocketChatServiceContent else { return nil }
        
        return convertXMTPChatToChat(serviceContent.conversation,
                                     userId: profile.id,
                                     userWallet: profile.wallet,
                                     isApproved: true)
    }
}
