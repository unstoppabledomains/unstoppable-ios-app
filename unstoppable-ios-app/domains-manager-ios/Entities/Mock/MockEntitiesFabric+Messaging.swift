//
//  MockEntitiesFabric+Messaging.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.02.2024.
//

import UIKit

// MARK: - Messaging
extension MockEntitiesFabric {
    enum Reactions {
        static let reactionsToTest: [MessageReactionDescription] =
        [.init(content: "😜", messageId: "1", referenceMessageId: "1", isUserReaction: true),
         .init(content: "😜", messageId: "1", referenceMessageId: "1", isUserReaction: false),
         .init(content: "😅", messageId: "1", referenceMessageId: "1", isUserReaction: false),
         .init(content: "🤓", messageId: "1", referenceMessageId: "1", isUserReaction: false),
         .init(content: "🫂", messageId: "1", referenceMessageId: "1", isUserReaction: false),
         .init(content: "😜", messageId: "1", referenceMessageId: "1", isUserReaction: false)]
    }
    
    enum Messaging {
        static func createProfileDisplayInfo(wallet: String = "0x",
                                             serviceIdentifier: MessagingServiceIdentifier = .xmtp) -> MessagingChatUserProfileDisplayInfo {
            MessagingChatUserProfileDisplayInfo(id: UUID().uuidString,
                                                wallet: wallet,
                                                serviceIdentifier: serviceIdentifier)
        }
        
        static func newChatConversationState() -> MessagingChatConversationState {
            .newChat(.init(userInfo: .init(wallet: "123"), messagingService: .xmtp))
        }
        
        static func existingChatConversationState(isGroup: Bool) -> MessagingChatConversationState {
            .existingChat(isGroup ? mockGroupChat(numberOfMembers: 4) : mockPrivateChat())
        }
        
        static func createChannelsForUITesting() -> [MessagingNewsChannel] {
            [mockChannel(name: "Push channel"),
             mockChannel(name: "Lens Protocol", lastMessage: mockChannelFeed(title: "Title", message: "Message content")),
             mockChannel(name: "Unsubscribed", isCurrentUserSubscribed: false)]
        }
        
        static func mockChannel(name: String,
                                isCurrentUserSubscribed: Bool = true,
                                lastMessage: MessagingNewsChannelFeed? = nil) -> MessagingNewsChannel {
            let id = UUID().uuidString
            return .init(id: id,
                         userId: "1",
                         channel: id,
                         name: name,
                         info: "This channel is for testing purposes only",
                         url: URLs.generic,
                         icon: MockEntitiesFabric.ImageURLs.aiAvatar.url,
                         verifiedStatus: 1,
                         blocked: 0,
                         subscriberCount: 100,
                         unreadMessagesCount: 0,
                         isCurrentUserSubscribed: isCurrentUserSubscribed,
                         isSearchResult: false,
                         lastMessage: lastMessage)
        }
        
        static func createChannelsFeedForUITesting() -> [MessagingNewsChannelFeed] {
            [mockChannelFeed(title: "Preview", message: "One"),
             mockChannelFeed(title: "Preview with link", message: "One", minutesOffset: -1, withLink: true),
             mockChannelFeed(title: "Preview", message: "Slkj lfdkj aldjfh ajhalskdfhjlaskdjfh akslhf lkas dfkjshd fkljsha k skfljsdkfskdj fhskj fhskjd fhskjdhf skdjfhskdj fhskdjf skdhf ksdjf hkjh", minutesOffset: -10),
             mockChannelFeed(title: "Preview", message: "Slkj lfdkj aldjfh ajhalskdfhjlaskdjfh akslhf lkas dfkjshd fkljsha k skfljsdkfskdj fhskj fhskjd fhskjdhf skdjfhskdj fhskdjf skdhf ksdjf hkjh", minutesOffset: -19, withLink: true)]
        }
        
        static func mockChannelFeed(title: String,
                                    message: String,
                                    minutesOffset: TimeInterval = 0,
                                    withLink: Bool = false,
                                    isRead: Bool = true) -> MessagingNewsChannelFeed {
            
            return .init(id: UUID().uuidString,
                         title: title,
                         message: message,
                         link: withLink ? URLs.generic : nil,
                         time: Date().addingTimeInterval(minutesOffset * 60),
                         isRead: isRead,
                         isFirstInChannel: false)
        }
        
        static func createChatsForUITesting() -> [MessagingChatDisplayInfo] {
            [mockPrivateChat(lastMessage: nil, unreadMessagesCount: 1),
             mockPrivateChat(lastMessage: createTextMessage(text: "Hello ksjd kjshf ksjdh fkjsdh fkjsdh fksjhd fkjsdhf  oskjdfl ksdjflksdjflkjsdlfkjsdlk fjsldkj f", isThisUser: false),
                             unreadMessagesCount: 10),
             mockPrivateChat(lastMessage: createImageMessage(image: .alertCircle, isThisUser: false)),
             mockPrivateChat(lastMessage: createRemoteContentMessage(isThisUser: false)),
             mockPrivateChat(lastMessage: createUnknownContentMessage(isThisUser: false)),
             mockGroupChat(numberOfMembers: 10),
             mockGroupChat(numberOfMembers: 10, lastMessage: createTextMessage(text: "Hello ksjd kjshf ksjdh fkjsdh fkjsdh fksjhd fkjsdhf  oskjdfl ksdjflksdjflkjsdlfkjsdlk fjsldkj f", isThisUser: false)),
             mockCommunityChat(name: "Web3 Domain", numberOfMembers: 30),
             mockCommunityChat(name: "Polygon holders", numberOfMembers: 30, isJoined: false),
             mockCommunityChat(name: "4 Years Club", numberOfMembers: 10, unreadMessagesCount: 5, lastMessage: createTextMessage(text: "Nice to join this awesome community!", isThisUser: false))]
        }
        
        static func mockPrivateChat(lastMessage: MessagingChatMessageDisplayInfo? = nil,
                                    unreadMessagesCount: Int = 0) -> MessagingChatDisplayInfo {
            let chatId = UUID().uuidString
            let sender = chatSenderFor(isThisUser: true)
            let otherSender = chatSenderFor(isThisUser: false)
            let avatarURL = MockEntitiesFabric.ImageURLs.aiAvatar.url
            let chat = MessagingChatDisplayInfo(id: chatId,
                                                thisUserDetails: sender.userDisplayInfo,
                                                avatarURL: avatarURL,
                                                serviceIdentifier: .xmtp,
                                                type: .private(.init(otherUser: otherSender.userDisplayInfo)),
                                                unreadMessagesCount: unreadMessagesCount,
                                                isApproved: true,
                                                lastMessageTime: lastMessage?.time ?? Date(),
                                                lastMessage: lastMessage)
            
            return chat
        }
        
        static func mockGroupChat(numberOfMembers: Int,
                                  lastMessage: MessagingChatMessageDisplayInfo? = nil) -> MessagingChatDisplayInfo {
            let chatId = UUID().uuidString
            let sender = chatSenderFor(isThisUser: true)
            var members = [sender.userDisplayInfo]
            for _ in 0..<numberOfMembers {
                let sender = chatSenderFor(isThisUser: false)
                members.append(sender.userDisplayInfo)
            }
            let unreadMessagesCount = 0
            let chat = MessagingChatDisplayInfo(id: chatId,
                                                thisUserDetails: sender.userDisplayInfo,
                                                avatarURL: nil,
                                                serviceIdentifier: .xmtp,
                                                type: .group(.init(members: members,
                                                                   pendingMembers: [],
                                                                   name: "Group chat",
                                                                   adminWallets: [],
                                                                   isPublic: false)),
                                                unreadMessagesCount: unreadMessagesCount,
                                                isApproved: true,
                                                lastMessageTime: lastMessage?.time ?? Date(),
                                                lastMessage: lastMessage)
            
            return chat
        }
        
        static func mockCommunityChat(name: String,
                                      numberOfMembers: Int,
                                      isJoined: Bool = true,
                                      unreadMessagesCount: Int = 0,
                                      lastMessage: MessagingChatMessageDisplayInfo? = nil) -> MessagingChatDisplayInfo {
            let chatId = UUID().uuidString
            let sender = chatSenderFor(isThisUser: true)
            var members = [sender.userDisplayInfo]
            for _ in 0..<numberOfMembers {
                let sender = chatSenderFor(isThisUser: false)
                members.append(sender.userDisplayInfo)
            }
            let badgeInfo = BadgeDetailedInfo(badge: .init(code: chatId,
                                                           name: name,
                                                           logo: MockEntitiesFabric.ImageURLs.aiAvatar.rawValue,
                                                           description: "This is community for this badge holders."),
                                              usage: .init(rank: 10, holders: 10, domains: 10, featured: nil))
            let type: MessagingCommunitiesChatDetails.CommunityType = .badge(badgeInfo)
            let chat = MessagingChatDisplayInfo(id: chatId,
                                                thisUserDetails: sender.userDisplayInfo,
                                                avatarURL: nil,
                                                serviceIdentifier: .xmtp,
                                                type: .community(.init(type: type,
                                                                       isJoined: isJoined,
                                                                       isPublic: true,
                                                                       members: members,
                                                                       pendingMembers: [],
                                                                       adminWallets: [],
                                                                       blockedUsersList: [])),
                                                unreadMessagesCount: unreadMessagesCount,
                                                isApproved: isJoined,
                                                lastMessageTime: lastMessage?.time ?? Date(),
                                                lastMessage: lastMessage)
            
            return chat
        }
        
        static func createMessagesForUITesting(isFixedID: Bool = true) -> [MessagingChatMessageDisplayInfo] {
            func resolveMessageId(fixedID: String) -> String {
                isFixedID ? fixedID : UUID().uuidString
            }
            
            return [createTextMessage(id: resolveMessageId(fixedID: "1"),
                                      text: "Hello my friend",
                                      isThisUser: false),
                    createTextMessage(id: resolveMessageId(fixedID: "11"),
                                      text: "This is link https://google.com among message content",
                                      isThisUser: false),
                    createTextMessage(id: resolveMessageId(fixedID: "2"),
                                      text: "This is link https://google.com among message content",
                                      isThisUser: true),
                    createTextMessage(id: resolveMessageId(fixedID: "21"),
                                      text: "I'm failed!",
                                      isThisUser: true,
                                      deliveryState: .failedToSend),
                    createTextMessage(id: resolveMessageId(fixedID: "22"),
                                      text: "And i'm sending",
                                      isThisUser: true,
                                      deliveryState: .sending),
                    createImageMessage(id: resolveMessageId(fixedID: "3"),
                                       image: UIImage.Preview.previewLandscape,
                                       isThisUser: false),
                    createImageMessage(id: resolveMessageId(fixedID: "31"),
                                       image: UIImage.Preview.previewPortrait,
                                       isThisUser: false),
                    createImageMessage(id: resolveMessageId(fixedID: "32"),
                                       image: UIImage.Preview.previewSquare,
                                       isThisUser: false),
                    createImageMessage(id: resolveMessageId(fixedID: "33"),
                                       image: nil,
                                       isThisUser: false),
                    createImageMessage(id: resolveMessageId(fixedID: "4"),
                                       image: UIImage.Preview.previewPortrait,
                                       isThisUser: true),
                    createImageMessage(id: resolveMessageId(fixedID: "4"),
                                       image: nil,
                                       isThisUser: true),
                    createImageMessage(id: resolveMessageId(fixedID: "41"),
                                       image: UIImage.Preview.previewSquare,
                                       isThisUser: true,
                                       deliveryState: .failedToSend),
                    createImageMessage(id: resolveMessageId(fixedID: "42"),
                                       image: UIImage.Preview.previewLandscape,
                                       isThisUser: true,
                                       deliveryState: .sending),
                    createRemoteContentMessage(id: resolveMessageId(fixedID: "5"),
                                               isThisUser: false),
                    createRemoteContentMessage(id: resolveMessageId(fixedID: "6"),
                                               isThisUser: true),
                    createUnknownContentMessage(id: resolveMessageId(fixedID: "7"),
                                                isThisUser: false),
                    createUnknownContentMessage(id: resolveMessageId(fixedID: "71"),
                                                name: "Name of file",
                                                isThisUser: false),
                    createUnknownContentMessage(id: resolveMessageId(fixedID: "72"),
                                                size: 100000,
                                                isThisUser: false),
                    createUnknownContentMessage(id: resolveMessageId(fixedID: "73"),
                                                name: "Name of file",
                                                size: 100000,
                                                isThisUser: false),
                    createUnknownContentMessage(id: resolveMessageId(fixedID: "8"),
                                                isThisUser: true),
                    createUnknownContentMessage(id: resolveMessageId(fixedID: "81"),
                                                name: "Name of file",
                                                isThisUser: true),
                    createUnknownContentMessage(id: resolveMessageId(fixedID: "82"),
                                                size: 100000,
                                                isThisUser: true),
                    createUnknownContentMessage(id: resolveMessageId(fixedID: "83"),
                                                name: "Name of file",
                                                size: 100000,
                                                isThisUser: true),
                    createUnknownContentMessage(id: resolveMessageId(fixedID: "83"),
                                                name: "Name of file",
                                                size: 100000,
                                                isThisUser: true,
                                                deliveryState: .sending),
                    createUnknownContentMessage(id: resolveMessageId(fixedID: "83"),
                                                name: "Name of file",
                                                size: 100000,
                                                isThisUser: true,
                                                deliveryState: .failedToSend)]
        }
        
        static func createTextMessage(id: String = UUID().uuidString,
                                      text: String,
                                      isThisUser: Bool,
                                      deliveryState: MessagingChatMessageDisplayInfo.DeliveryState = .delivered,
                                      reactions: [MessageReactionDescription] = []) -> MessagingChatMessageDisplayInfo {
            let sender = chatSenderFor(isThisUser: isThisUser)
            let textDetails = MessagingChatMessageTextTypeDisplayInfo(text: text)
            
            return MessagingChatMessageDisplayInfo(id: id,
                                                   chatId: "2",
                                                   userId: "1",
                                                   senderType: sender,
                                                   time: Date(),
                                                   type: .text(textDetails),
                                                   isRead: false,
                                                   isFirstInChat: false,
                                                   deliveryState: deliveryState,
                                                   isEncrypted: false,
                                                   reactions: reactions)
        }
        
        static func createImageMessage(id: String = UUID().uuidString,
                                       image: UIImage?,
                                       isThisUser: Bool,
                                       deliveryState: MessagingChatMessageDisplayInfo.DeliveryState = .delivered) -> MessagingChatMessageDisplayInfo {
            let sender = chatSenderFor(isThisUser: isThisUser)
            var imageDetails = MessagingChatMessageImageBase64TypeDisplayInfo(base64: "")
            imageDetails.image = image
            return MessagingChatMessageDisplayInfo(id: id,
                                                   chatId: "2",
                                                   userId: "1",
                                                   senderType: sender,
                                                   time: Date(),
                                                   type: .imageBase64(imageDetails),
                                                   isRead: false,
                                                   isFirstInChat: false,
                                                   deliveryState: deliveryState,
                                                   isEncrypted: false)
            
            
        }
        
        static func createRemoteContentMessage(id: String = UUID().uuidString,
                                               isThisUser: Bool,
                                               deliveryState: MessagingChatMessageDisplayInfo.DeliveryState = .delivered) -> MessagingChatMessageDisplayInfo {
            let sender = chatSenderFor(isThisUser: isThisUser)
            return MessagingChatMessageDisplayInfo(id: id,
                                                   chatId: "2",
                                                   userId: "1",
                                                   senderType: sender,
                                                   time: Date(),
                                                   type: .remoteContent(.init(serviceData: Data())),
                                                   isRead: false,
                                                   isFirstInChat: false,
                                                   deliveryState: deliveryState,
                                                   isEncrypted: false)
            
            
        }
        
        static func createUnknownContentMessage(id: String = UUID().uuidString,
                                                fileName: String = "oleg.zip",
                                                type: String = "zip",
                                                name: String? = nil,
                                                size: Int? = nil,
                                                isThisUser: Bool,
                                                deliveryState: MessagingChatMessageDisplayInfo.DeliveryState = .delivered) -> MessagingChatMessageDisplayInfo {
            let sender = chatSenderFor(isThisUser: isThisUser)
            let details = MessagingChatMessageUnknownTypeDisplayInfo(fileName: "oleg.zip",
                                                                     type: "zip",
                                                                     name: name,
                                                                     size: size)
            
            return MessagingChatMessageDisplayInfo(id: id,
                                                   chatId: "2",
                                                   userId: "1",
                                                   senderType: sender,
                                                   time: Date(),
                                                   type: .unknown(details),
                                                   isRead: false,
                                                   isFirstInChat: false,
                                                   deliveryState: deliveryState,
                                                   isEncrypted: false)
            
            
        }
        
        static func chatSenderFor(user: MessagingChatUserDisplayInfo? = nil,
                                  isThisUser: Bool) -> MessagingChatSender {
            let user = user ?? messagingChatUserDisplayInfo(domainName: "oleg.x", withPFP: true)
            
            return isThisUser ? .thisUser(user) : .otherUser(user)
        }
        
        static func messagingChatUserDisplayInfo(wallet: String = "13123",
                                                 domainName: String? = nil,
                                                 withPFP: Bool) -> MessagingChatUserDisplayInfo {
            let pfpURL: URL? = !withPFP ? nil : MockEntitiesFabric.ImageURLs.sunset.url
            return MessagingChatUserDisplayInfo(wallet: wallet, domainName: domainName, pfpURL: pfpURL)
        }
        
        static func suggestingGroupChatMembersDisplayInfo() -> [MessagingChatUserDisplayInfo] {
            [.init(wallet: "0x1"),
             .init(wallet: "0x2", domainName: "domain_oleg.x"),
             .init(wallet: "0x3", rrDomainName: "rr_domain_nick.crypto", pfpURL: MockEntitiesFabric.ImageURLs.sunset.url),
             .init(wallet: "0x4", domainName: "domain_daniil.x", rrDomainName: "rr_domain_daniil.x", pfpURL: MockEntitiesFabric.ImageURLs.aiAvatar.url)]
        }
    }
}
