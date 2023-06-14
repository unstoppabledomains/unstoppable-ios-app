//
//  MockMessagingService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2023.
//

import Foundation

final class MockMessagingService {
   
    private var domainsChats: [DomainName: [MessagingChatDisplayInfo]] = [:]
    private var chatsMessages: [MessagingChatDisplayInfo : [MessagingChatMessageDisplayInfo]] = [:]
    
}

// MARK: - MessagingServiceProtocol
extension MockMessagingService: MessagingServiceProtocol {
    func getUserProfile(for domain: DomainDisplayInfo) async throws -> MessagingChatUserProfileDisplayInfo { throw NSError() }
    func createUserProfile(for domain: DomainDisplayInfo) async throws -> MessagingChatUserProfileDisplayInfo { throw NSError() }
    func setCurrentUser(_ userProfile: MessagingChatUserProfileDisplayInfo) { }

    func getChatsListForProfile(_ profile: MessagingChatUserProfileDisplayInfo) async throws -> [MessagingChatDisplayInfo] {
        []
        /*
        if let cachedChats = domainsChats[domain.name] {
            return cachedChats
        }
        
        let chats = createMockChatsFor(domain: domain).sorted(by: { $0.lastMessage?.time ?? Date() > $1.lastMessage?.time ?? Date() })
        domainsChats[domain.name] = chats
        return chats
         */
    }
    
    func getCachedMessagesForChat(_ chatDisplayInfo: MessagingChatDisplayInfo) async throws -> [MessagingChatMessageDisplayInfo] {
        try await getMessagesForChat(chatDisplayInfo, fetchLimit: 30)
    }
    func getMessagesForChat(_ chatDisplayInfo: MessagingChatDisplayInfo,
                            before message: MessagingChatMessageDisplayInfo?,
                            limit: Int) async throws -> [MessagingChatMessageDisplayInfo] { [] }
    func getMessagesForChat(_ chatDisplayInfo: MessagingChatDisplayInfo,
                            after message: MessagingChatMessageDisplayInfo,
                            limit: Int) async throws -> [MessagingChatMessageDisplayInfo] { [] }
    private func getMessagesForChat(_ chat: MessagingChatDisplayInfo,
                            fetchLimit: Int) async throws -> [MessagingChatMessageDisplayInfo] {
        if let cachedMessages = chatsMessages[chat] {
            return cachedMessages
        }
        
        let messages = createMockMessages(chatId: chat.id).sorted(by: { $0.time < $1.time })
        chatsMessages[chat] = messages
        return messages
    }
    
    func sendMessage(_ messageType: MessagingChatMessageDisplayType,
                     in chat: MessagingChatDisplayInfo) throws -> MessagingChatMessageDisplayInfo {
        throw NSError()
    }
    
    func makeChatRequest(_ chat: MessagingChatDisplayInfo, approved: Bool) async throws { }
    func resendMessage(_ message: MessagingChatMessageDisplayInfo) throws { }
    func deleteMessage(_ message: MessagingChatMessageDisplayInfo) { }
    func markMessage(_ message: MessagingChatMessageDisplayInfo, isRead: Bool, wallet: String) throws { }
    
    func getSubscribedChannelsForProfile(_ profile: MessagingChatUserProfileDisplayInfo) async throws -> [MessagingNewsChannel] { [] }

    
    func addListener(_ listener: MessagingServiceListener) {}
    func removeListener(_ listener: MessagingServiceListener) {}
}

// MARK: - Private methods
private extension MockMessagingService {
    func createMockChatsFor(domain: DomainDisplayInfo) -> [MessagingChatDisplayInfo] {
        var chats = [MessagingChatDisplayInfo]()
        var mockDomainChatInfos = getMockDomainChatInfos()
        let numberOfChatsToTake = mockDomainChatInfos.count // max(1, arc4random_uniform(UInt32(mockDomainChatInfos.count)))
        
        for _ in 0..<numberOfChatsToTake {
            if let randomChat = mockDomainChatInfos.randomElement() {
                let chatId = UUID().uuidString
                let sender = createRandomChatSender()
                let avatarURL = URL(string: randomChat.imageURL)
                let lastMessage = createMockLastMessageForChatWithSender(sender,
                                                                            chatId: chatId)
                let unreadMessagesCount = createMockChatUnreadMessagesCount()
                let chat = MessagingChatDisplayInfo(id: chatId,
                                                    thisUserDetails: sender.userDisplayInfo,
                                                    avatarURL: avatarURL,
                                                    type: .private(.init(otherUser: sender.userDisplayInfo)),
                                                    unreadMessagesCount: unreadMessagesCount,
                                                    isApproved: true,
                                                    lastMessageTime: lastMessage.time,
                                                    lastMessage: lastMessage)
                
                chats.append(chat)
                mockDomainChatInfos.removeAll(where: { $0 == randomChat })
            }
        }
        
        return chats
    }
    
    func getMockDomainChatInfos() -> [MockDomainChatInfo] {
        [.init(domainName: "dominic.crypto",
               imageURL: "https://storage.googleapis.com/unstoppable-client-assets/images/domain/kuplin.hi/f9bed9e5-c6e5-4946-9c32-a655d87e670c.png"),
         .init(domainName: "ericrodriguez.nft",
               imageURL: "https://metadata.unstoppabledomains.com/image-src/kuplin.wallet?withOverlay=false&ref=1/erc1155:0x495f947276749ce646f68ac8c248420045cb7b5e/23005389916031419495497068831589288009900632785309905146382159665318238093313"),
         .init(domainName: "itsphil.nft",
               imageURL: "https://storage.googleapis.com/unstoppable-client-assets/images/domain/misterfirst.nft/f6d0046b-635f-47ac-9003-3507f7594f51.png"),
         .init(domainName: "iurevych.crypto",
               imageURL: "https://storage.googleapis.com/unstoppable-client-assets/images/domain/misterfirst.x/3efb99b7-9d84-4037-b8b3-7bdd610cbb6b.png"),
         .init(domainName: "ryan.crypto",
               imageURL: "https://storage.googleapis.com/unstoppable-client-assets/images/domain/oleg.kuplin.wallet/ae428a7f-c4a1-450a-aab4-202b4603aef9.png"),
         .init(domainName: "ryan2.crypto",
               imageURL: "https://storage.googleapis.com/unstoppable-client-assets/images/domain/oleg.kuplin.wallet/ae428a7f-c4a1-450a-aab4-202b4603aef9.png"),
         .init(domainName: "ryan3.crypto",
               imageURL: "https://storage.googleapis.com/unstoppable-client-assets/images/domain/oleg.kuplin.wallet/ae428a7f-c4a1-450a-aab4-202b4603aef9.png"),
         .init(domainName: "ryan4.crypto",
               imageURL: "https://storage.googleapis.com/unstoppable-client-assets/images/domain/oleg.kuplin.wallet/ae428a7f-c4a1-450a-aab4-202b4603aef9.png"),
         .init(domainName: "ryan5.crypto",
               imageURL: "https://storage.googleapis.com/unstoppable-client-assets/images/domain/oleg.kuplin.wallet/ae428a7f-c4a1-450a-aab4-202b4603aef9.png"),
         .init(domainName: "ryan6.crypto",
               imageURL: "https://storage.googleapis.com/unstoppable-client-assets/images/domain/oleg.kuplin.wallet/ae428a7f-c4a1-450a-aab4-202b4603aef9.png"),
         .init(domainName: "ryan7.crypto",
               imageURL: "https://storage.googleapis.com/unstoppable-client-assets/images/domain/oleg.kuplin.wallet/ae428a7f-c4a1-450a-aab4-202b4603aef9.png"),
         .init(domainName: "ryan8.crypto",
               imageURL: "https://storage.googleapis.com/unstoppable-client-assets/images/domain/oleg.kuplin.wallet/ae428a7f-c4a1-450a-aab4-202b4603aef9.png"),
         .init(domainName: "ryan9.crypto",
               imageURL: "https://storage.googleapis.com/unstoppable-client-assets/images/domain/oleg.kuplin.wallet/ae428a7f-c4a1-450a-aab4-202b4603aef9.png"),
         .init(domainName: "ryan10.crypto",
               imageURL: "https://storage.googleapis.com/unstoppable-client-assets/images/domain/oleg.kuplin.wallet/ae428a7f-c4a1-450a-aab4-202b4603aef9.png")]
    }
    
    func createRandomChatSender() -> MessagingChatSender {
        let bools = [true, false]
        let info = MessagingChatUserDisplayInfo(wallet: "")
        if bools.randomElement() == true {
            return .thisUser(info)
        }
        return .otherUser(info)
    }
    
    func createMockLastMessageForChatWithSender(_ sender: MessagingChatSender,
                                                   chatId: String) -> MessagingChatMessageDisplayInfo {
        .init(id: UUID().uuidString,
              chatId: chatId,
              senderType: sender,
              time: createMockMessageDate(),
              type: .text(.init(text: mockLastMessageTexts.randomElement()!,
                                encryptedText: mockLastMessageTexts.randomElement()!)),
              isRead: true,
              isFirstInChat: false,
              deliveryState: .delivered)
    }
    
    struct MockDomainChatInfo: Hashable {
        let domainName: DomainName
        let imageURL: String
    }
    
    func createMockMessageDate() -> Date {
        let timePassed = arc4random_uniform(604800)
        return Date().addingTimeInterval(-Double(timePassed))
    }
    
    func createMockChatUnreadMessagesCount() -> Int {
        Int(arc4random_uniform(10))
    }
    
    var mockLastMessageTexts: [String] {
        ["Hey, I'm here at the restaurant. Where are you?",
        "Okay, I'm signing off for the night. Have a good one!",
        "Thanks for chatting with me today. Let's catch up again soon!",
        "Alright, time for bed. Goodnight!",
        "It was nice talking to you. Let's continue this conversation another time"]
    }
    
    func createMockMessages(chatId: String) -> [MessagingChatMessageDisplayInfo] {
        let numberOfMessages = arc4random_uniform(40) + 1
        
        var messages = [MessagingChatMessageDisplayInfo]()
        
        for _ in 0..<numberOfMessages {
            let sender = createRandomChatSender()
            let time = createMockMessageDate()
            let text = mockLastMessageTexts.randomElement()!
            let message = MessagingChatMessageDisplayInfo(id: UUID().uuidString,
                                                          chatId: chatId,
                                                          senderType: sender,
                                                          time: time,
                                                          type: .text(.init(text: text,
                                                                           encryptedText: text)),
                                                          isRead: true,
                                                          isFirstInChat: false,
                                                          deliveryState: .delivered)
            messages.append(message)
        }
        
        return messages
    }
}
