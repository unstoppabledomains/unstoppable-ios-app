//
//  MockMessagingService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2023.
//

import Foundation

final class MockMessagingService {
   
    private var domainsChannels: [DomainName: [ChatChannelType]] = [:]
    private var channelsMessages: [ChatChannelType : [ChatMessageType]] = [:]
    
}

// MARK: - MessagingServiceProtocol
extension MockMessagingService: MessagingServiceProtocol {
    func getChannelsForDomain(_ domain: DomainDisplayInfo) async -> [ChatChannelType] {
        if let cachedChannels = domainsChannels[domain.name] {
            return cachedChannels
        }
        
        let channels = createMockChannelsFor(domain: domain).sorted(by: { $0.lastMessage?.time ?? Date() > $1.lastMessage?.time ?? Date() })
        domainsChannels[domain.name] = channels
        return channels
    }
    
    func getNumberOfUnreadMessagesInChannelsForDomain(_ domain: DomainDisplayInfo) async -> Int {
        let channels = await getChannelsForDomain(domain)
        let unreadMessagesSum = channels.reduce(0, { $0 + $1.unreadMessagesCount })
        
        return unreadMessagesSum
    }
    
    func getMessagesForChannel(_ channel: ChatChannelType) async -> [ChatMessageType] {
        if let cachedMessages = channelsMessages[channel] {
            return cachedMessages
        }
        
        let messages = createMockMessages().sorted(by: { $0.time < $1.time })
        channelsMessages[channel] = messages
        return messages
    }
}

// MARK: - Private methods
private extension MockMessagingService {
    func createMockChannelsFor(domain: DomainDisplayInfo) -> [ChatChannelType] {
        var channels = [ChatChannelType]()
        var mockDomainChatInfos = getMockDomainChatInfos()
        let numberOfChannelsToTake = max(1, arc4random_uniform(UInt32(mockDomainChatInfos.count)))
        
        for _ in 0..<numberOfChannelsToTake {
            if let randomChat = mockDomainChatInfos.randomElement() {
                let sender = createRandomChatSender()
                let newChannel = DomainChatChannel(avatarURL: URL(string: randomChat.imageURL),
                                                   lastMessage: createMockLastMessageForChannelWithSender(sender),
                                                   unreadMessagesCount: createMockChannelUnreadMessagesCount(),
                                                   domainName: randomChat.domainName)
                channels.append(.domain(channel: newChannel))
                mockDomainChatInfos.removeAll(where: { $0 == randomChat })
            }
        }
        
        return channels
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
               imageURL: "https://storage.googleapis.com/unstoppable-client-assets/images/domain/oleg.kuplin.wallet/ae428a7f-c4a1-450a-aab4-202b4603aef9.png")]
    }
    
    func createRandomChatSender() -> ChatSender {
        let bools = [true, false]
        
        if bools.randomElement() == true {
            return .user
        }
        return .friend
    }
    
    func createMockLastMessageForChannelWithSender(_ sender: ChatSender) -> ChatMessageType {
        .text(message: .init(sender: sender,
                             time: createMockMessageDate(),
                             text: mockLastMessageTexts.randomElement()!))
    }
    
    struct MockDomainChatInfo: Hashable {
        let domainName: DomainName
        let imageURL: String
    }
    
    func createMockMessageDate() -> Date {
        let timePassed = arc4random_uniform(604800)
        return Date().addingTimeInterval(-Double(timePassed))
    }
    
    func createMockChannelUnreadMessagesCount() -> Int {
        Int(arc4random_uniform(10))
    }
    
    var mockLastMessageTexts: [String] {
        ["Hey, I'm here at the restaurant. Where are you?",
        "Okay, I'm signing off for the night. Have a good one!",
        "Thanks for chatting with me today. Let's catch up again soon!",
        "Alright, time for bed. Goodnight!",
        "It was nice talking to you. Let's continue this conversation another time"]
    }
    
    func createMockMessages() -> [ChatMessageType] {
        let numberOfMessages = arc4random_uniform(40) + 1
        
        var messages = [ChatMessageType]()
        
        for _ in 0..<numberOfMessages {
            let sender = createRandomChatSender()
            let time = createMockMessageDate()
            let text = mockLastMessageTexts.randomElement()!
            let textMessage = ChatTextMessage(sender: sender,
                                              time: time,
                                              text: text)
            let messageType = ChatMessageType.text(message: textMessage)
            messages.append(messageType)
        }
        
        return messages
    }
}
