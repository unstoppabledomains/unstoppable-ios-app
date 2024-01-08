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
                                                              serviceIdentifier: .xmtp,
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
                                                   serviceIdentifier: .xmtp,
                                                   type: chatType,
                                                   unreadMessagesCount: 0,
                                                   isApproved: isApproved,
                                                   lastMessageTime: lastMessageTime,
                                                   lastMessage: nil)
        
        let metadataModel = XMTPEnvironmentNamespace.ChatServiceMetadata(encodedContainer: xmtpChat.encodedContainer)
        
        // Bridging for PNs
        AppGroupsBridgeService.shared.saveXMTPConversationData(conversationData: xmtpChat.encodedContainer.jsonData(),
                                                               topic: xmtpChat.topic,
                                                               userWallet: userWallet)
        //
        
        let serviceMetadata = metadataModel.jsonData()
        let chat = MessagingChat(userId: userId,
                                 displayInfo: displayInfo,
                                 serviceMetadata: serviceMetadata)
        return chat
    }
    
    static func convertXMTPMessageToChatMessage(_ xmtpMessage: XMTP.DecodedMessage,
                                                cachedMessage: MessagingChatMessage?,
                                                in chat: MessagingChat,
                                                isRead: Bool,
                                                filesService: MessagingFilesServiceProtocol) async -> MessagingChatMessage? {
        var isRead = isRead
        if Constants.shouldHideBlockedUsersLocally,
           XMTPBlockedUsersStorage.shared.isOtherUserBlockedInChat(chat.displayInfo) {
            isRead = true /// Messages from other user should always be marked as read
        }
        
        if var cachedMessage {
            cachedMessage.displayInfo.isRead = isRead 
            return cachedMessage
        }
        
        let id = xmtpMessage.id
        let userId = chat.userId
        let metadataModel = XMTPEnvironmentNamespace.MessageServiceMetadata(encodedContent: xmtpMessage.encodedContent)
        guard let serviceMetadata = metadataModel.jsonData(),
              let type = try? await extractMessageType(from: xmtpMessage,
                                                       messageId: id,
                                                       userId: userId,
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
                                                          isFirstInChat: false,
                                                          deliveryState: .delivered,
                                                          isEncrypted: isMessageEncrypted)
        let chatMessage = MessagingChatMessage(displayInfo: displayInfo,
                                               serviceMetadata: serviceMetadata)
        return chatMessage
    }
    
    
    private static func extractMessageType(from xmtpMessage: XMTP.DecodedMessage,
                                           messageId: String,
                                           userId: String,
                                           filesService: MessagingFilesServiceProtocol) async throws -> MessagingChatMessageDisplayType? {
        if let knownType = XMTPMessageKnownTypeFrom(xmtpMessage) {
            switch knownType {
            case .text:
                let decryptedContent: String = try xmtpMessage.content()
                let textDisplayInfo = MessagingChatMessageTextTypeDisplayInfo(text: decryptedContent)
                return .text(textDisplayInfo)
            case .attachment:
                let attachment: XMTP.Attachment = try xmtpMessage.content()
                return try await getMessageTypeFor(attachment: attachment,
                                             messageId: messageId,
                                             userId: userId,
                                             filesService: filesService)
            case .remoteStaticAttachment:
                let remoteAttachment: XMTP.RemoteAttachment = try xmtpMessage.content()
                let attachmentProperties = RemoteAttachmentProperties(remoteAttachment: remoteAttachment)
                let serviceData = try attachmentProperties.jsonDataThrowing()
                let displayInfo = MessagingChatMessageRemoteContentTypeDisplayInfo(serviceData: serviceData)
                return .remoteContent(displayInfo)
            }
        } else {
            guard let contentData: Data = try? xmtpMessage.content() else { return nil }

            let fileName = messageId + "_" + String(userId.suffix(4))
            try filesService.saveData(contentData, fileName: fileName)
            let unknownDisplayInfo = MessagingChatMessageUnknownTypeDisplayInfo(fileName: fileName,
                                                                                type: XMTPMessageTypeIDFrom(xmtpMessage),
                                                                                name: nil,
                                                                                size: nil)
            return .unknown(unknownDisplayInfo)
        }
    }
    
    static func XMTPMessageTypeIDFrom(_ xmtpMessage: XMTP.DecodedMessage) -> String {
        xmtpMessage.encodedContent.type.typeID
    }
    
    static func XMTPMessageKnownTypeFrom(_ xmtpMessage: XMTP.DecodedMessage) -> XMTPEnvironmentNamespace.KnownType? {
        XMTPEnvironmentNamespace.KnownType(rawValue: XMTPMessageTypeIDFrom(xmtpMessage))
    }
    
    private static func getMessageTypeFor(attachment: Attachment,
                                          messageId: String,
                                          userId: String,
                                          filesService: MessagingFilesServiceProtocol) async throws -> MessagingChatMessageDisplayType {
        if let image = await UIImage.createWith(anyData: attachment.data) {
            let imageDisplayInfo = MessagingChatMessageImageDataTypeDisplayInfo(data: attachment.data,
                                                                                image: image)
            return .imageData(imageDisplayInfo)
        } else {
            let name = attachment.filename
            let data = attachment.data
            
            let fileName = messageId + "_" + String(userId.suffix(4)) + "_" + name
            try filesService.saveData(data, fileName: fileName)
            let unknownDisplayInfo = MessagingChatMessageUnknownTypeDisplayInfo(fileName: fileName,
                                                                                type: XMTPEnvironmentNamespace.KnownType.attachment.rawValue,
                                                                                name: name,
                                                                                size: data.count)
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
                                               serviceIdentifier: .xmtp,
                                               serviceContent: serviceContent,
                                               transformToMessageBlock: convertMessagingWebSocketMessageEntityToChatMessage)
    }
    
    private static func convertMessagingWebSocketMessageEntityToChatMessage(_ webSocketMessage: MessagingWebSocketMessageEntity,
                                                                    in chat: MessagingChat,
                                                                    filesService: MessagingFilesServiceProtocol) async -> MessagingChatMessage? {
        guard let serviceContent = webSocketMessage.serviceContent as? XMTPEnvironmentNamespace.XMTPSocketMessageServiceContent else { return nil }
        
        let thisUserWallet = chat.displayInfo.thisUserDetails.wallet
        
        return await convertXMTPMessageToChatMessage(serviceContent.xmtpMessage,
                                                     cachedMessage: nil,
                                                     in: chat,
                                                     isRead: thisUserWallet == webSocketMessage.senderWallet,
                                                     filesService: filesService)
    }
    
    static func convertXMTPConversationToWebSocketChatEntity(_ conversation: Conversation,
                                                             userId: String) -> MessagingWebSocketChatEntity {
        let serviceContent = XMTPEnvironmentNamespace.XMTPSocketChatServiceContent(conversation: conversation)
        return MessagingWebSocketChatEntity(userId: userId,
                                            serviceContent: serviceContent,
                                            serviceIdentifier: .xmtp,
                                            transformToChatBlock: convertMessagingWebSocketChatEntityToChat)
    }
    
    private static func convertMessagingWebSocketChatEntityToChat(_ webSocketChat: MessagingWebSocketChatEntity,
                                                                  profile: MessagingChatUserProfile) -> MessagingChat? {
        guard let serviceContent = webSocketChat.serviceContent as? XMTPEnvironmentNamespace.XMTPSocketChatServiceContent else { return nil }
        let approvedAddressesList = XMTPServiceHelper.getListOfApprovedAddressesForUser(profile)

        return convertXMTPChatToChat(serviceContent.conversation,
                                     userId: profile.id,
                                     userWallet: profile.wallet,
                                     isApproved: approvedAddressesList.contains(serviceContent.conversation.peerAddress))
    }
    
    static func loadRemoteContentFrom(data: Data,
                                      messageId: String,
                                      userId: String,
                                      client: XMTP.Client,
                                      filesService: MessagingFilesServiceProtocol) async throws -> MessagingChatMessageDisplayType {
        let remoteAttachmentProperties = try RemoteAttachmentProperties.objectFromDataThrowing(data)
        let remoteAttachment = try remoteAttachmentProperties.createRemoteAttachment()
        let remoteAttachmentEncodedContent = try await remoteAttachment.content()
        let attachment: Attachment = try remoteAttachmentEncodedContent.decoded(with: client)
        return try await getMessageTypeFor(attachment: attachment,
                                           messageId: messageId,
                                           userId: userId,
                                           filesService: filesService)
    }
    
    private struct RemoteAttachmentProperties: Codable {
        let url: String
        let contentDigest: String
        let secret: Data
        let salt: Data
        let nonce: Data
        let scheme: String
        
        init(remoteAttachment: XMTP.RemoteAttachment) {
            self.url = remoteAttachment.url
            self.contentDigest = remoteAttachment.contentDigest
            self.secret = remoteAttachment.secret
            self.salt = remoteAttachment.salt
            self.nonce = remoteAttachment.nonce
            self.scheme = remoteAttachment.scheme.rawValue
        }
        
        func createRemoteAttachment() throws -> XMTP.RemoteAttachment {
            try XMTP.RemoteAttachment(url: url,
                                      contentDigest: contentDigest,
                                      secret: secret,
                                      salt: salt,
                                      nonce: nonce,
                                      scheme: .init(rawValue: scheme)!)
        }
    }
}
