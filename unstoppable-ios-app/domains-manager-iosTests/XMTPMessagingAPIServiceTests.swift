//
//  XMTPMessagingAPIServiceTests.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 11.08.2023.
//

import XCTest
import Push
@testable import domains_manager_ios

final class XMTPMessagingAPIServiceTests: XCTestCase {
    
    private var dataProvider: MockMessagingServiceDataProvider!
    private var messagingService: XMTPMessagingAPIService!
    private let filesService = MessagingFilesServiceProtocolMock(decrypterService: SymmetricMessagingContentDecrypterService())
    private let user = MessagingChatUserProfile(id: "", wallet: "", displayInfo: .init(id: "", wallet: "", serviceIdentifier: .xmtp))
    private let fetchLimit = 5
    private var firstMessage: MessagingChatMessage { getMockMessage(at: 0) }
    private var firstMessageId: String { firstMessage.displayInfo.id }
    
    override func setUp() async throws {
        try await super.setUp()
        
        dataProvider = MockMessagingServiceDataProvider()
        messagingService = XMTPMessagingAPIService(dataProvider: dataProvider)
    }
    
    //MARK: - Do not pass before message
    func testAllMessagesReturnBasedOnNoBeforeMessage() async throws {
        let chat = createMessagingChat(lastMessage: nil)
        let messages = try await getMessagesForChat(chat,
                                                    before: nil,
                                                    cachedMessages: [])
        
        XCTAssertEqual(messages, MessagesMockData.allMessages)
        XCTAssertEqual(dataProvider.requests, [.init(before: nil, fetchLimit: fetchLimit)])
    }
    
    func testAllMessagesReturnBasedOnNoBeforeMessageHaveCacheNotFirstMessage() async throws {
        let chat = createMessagingChat(lastMessage: nil)
        let messages = try await getMessagesForChat(chat,
                                                    before: nil,
                                                    cachedMessages: [getMockMessage(at: 1)])
        
        XCTAssertEqual(messages, MessagesMockData.allMessages)
        XCTAssertEqual(dataProvider.requests, [.init(before: nil, fetchLimit: fetchLimit)])
    }
    
    func testAllMessagesReturnBasedOnNoBeforeMessageHaveCacheFirstMessage() async throws {
        let chat = createMessagingChat(lastMessage: nil)
        let messages = try await getMessagesForChat(chat,
                                                    before: nil,
                                                    cachedMessages: [firstMessage])
        
        XCTAssertEqual(messages, MessagesMockData.allMessages)
        XCTAssertEqual(dataProvider.requests, [.init(before: nil, fetchLimit: fetchLimit)])
    }
    
    func testAllMessagesReturnBasedOnNoBeforeMessageHaveCacheFirstTwoMessages() async throws {
        let chat = createMessagingChat(lastMessage: nil)
        let messages = try await getMessagesForChat(chat,
                                                    before: nil,
                                                    cachedMessages: [firstMessage,
                                                                     getMockMessage(at: 1)])
        
        XCTAssertEqual(messages, MessagesMockData.allMessages)
        XCTAssertEqual(dataProvider.requests, [.init(before: nil, fetchLimit: fetchLimit)])
    }
    
    func testAllMessagesInCacheNoBefore() async throws {
        let chat = createMessagingChat(lastMessage: nil)
        let messages = try await getMessagesForChat(chat,
                                                    before: nil,
                                                    cachedMessages: MessagesMockData.allMessages)
        
        XCTAssertEqual(messages, MessagesMockData.allMessages)
        XCTAssertEqual(dataProvider.requests, [.init(before: nil, fetchLimit: fetchLimit)])
    }
    
    //MARK: - Pass before message
    func testAllMessagesReturnBasedOnLastMessageOneMessageNoCache() async throws {
        let chat = createMessagingChat(lastMessage: nil)
        let messages = try await getMessagesForChat(chat,
                                                    before: firstMessage,
                                                    cachedMessages: [])
        
        XCTAssertEqual(messages, Array(MessagesMockData.allMessages.suffix(5)))
        XCTAssertEqual(dataProvider.requests, [.init(before: firstMessage.displayInfo.time, fetchLimit: fetchLimit)])
    }
    
    func testAllMessagesReturnBasedOnLastMessageOneMessageInCache() async throws {
        let chat = createMessagingChat(lastMessage: nil)
        let messages = try await getMessagesForChat(chat,
                                                    before: firstMessage,
                                                    cachedMessages: [getMockMessage(at: 1)])
        
        XCTAssertEqual(messages, Array(MessagesMockData.allMessages.suffix(5)))
        XCTAssertEqual(dataProvider.requests, [.init(before: getMockMessageTime(at: 1), fetchLimit: fetchLimit - 1)])
    }
    
    func testAllMessagesReturnBasedOnLastMessageThreeMessageInCache() async throws {
        let chat = createMessagingChat(lastMessage: nil)
        let messages = try await getMessagesForChat(chat,
                                                    before: firstMessage,
                                                    cachedMessages: [getMockMessage(at: 1),
                                                                     getMockMessage(at: 2),
                                                                     getMockMessage(at: 3)])
        
        XCTAssertEqual(messages, Array(MessagesMockData.allMessages.suffix(5)))
        XCTAssertEqual(dataProvider.requests, [.init(before: getMockMessageTime(at: 3), fetchLimit: fetchLimit - 3)])
    }
    
    func testAllMessagesReturnBasedOnTwoMessagesWithBreakInCache() async throws {
        let chat = createMessagingChat(lastMessage: nil)
        let messages = try await getMessagesForChat(chat,
                                                    before: firstMessage,
                                                    cachedMessages: [getMockMessage(at: 1),
                                                                     getMockMessage(at: 3)])
        
        XCTAssertEqual(messages, Array(MessagesMockData.allMessages.suffix(5)))
        XCTAssertEqual(dataProvider.requests, [.init(before: getMockMessageTime(at: 1), fetchLimit: fetchLimit - 1)])
    }
    
    func testAllMessagesReturnBasedOnSomeMessagesInCache() async throws {
        let chat = createMessagingChat(lastMessage: nil)
        let messages = try await getMessagesForChat(chat,
                                                    before: getMockMessage(at: 2),
                                                    cachedMessages: [getMockMessage(at: 3)])
        
        XCTAssertEqual(messages, Array(MessagesMockData.allMessages.suffix(3)))
        XCTAssertEqual(dataProvider.requests, [.init(before: getMockMessageTime(at: 3), fetchLimit: fetchLimit - 1)])
    }
    
    func testAllMessagesInCache() async throws {
        let chat = createMessagingChat(lastMessage: nil)
        let messages = try await getMessagesForChat(chat,
                                                    before: firstMessage,
                                                    cachedMessages: Array(MessagesMockData.allMessages.suffix(4)))
        
        XCTAssertEqual(messages, Array(MessagesMockData.allMessages.suffix(4)))
        XCTAssertEqual(dataProvider.requests, [])
    }
    
    func testMessagesInCacheWithoutLink() async throws {
        let chat = createMessagingChat(lastMessage: nil)
        var firstMessage = self.firstMessage
        firstMessage.serviceMetadata = nil
        let messages = try await getMessagesForChat(chat,
                                                    before: firstMessage,
                                                    cachedMessages: [getMockMessage(at: 1)])
        
        XCTAssertEqual(messages.count, 5)
        XCTAssertEqual(dataProvider.requests, [.init(before: firstMessage.displayInfo.time, fetchLimit: fetchLimit)])
    }
}

// MARK: - Private methods
private extension XMTPMessagingAPIServiceTests {
    func createMessagingChat(lastMessage: MessagingChatMessageDisplayInfo?) -> MessagingChat {
        let displayInfo = MessagingChatDisplayInfo(id: "", thisUserDetails: .init(wallet: ""),
                                                   avatarURL: nil, 
                                                   serviceIdentifier: .xmtp,
                                                   type: .private(.init(otherUser: .init(wallet: ""))),
                                                   unreadMessagesCount: 0,
                                                   isApproved: true,
                                                   lastMessageTime: Date(),
                                                   lastMessage: lastMessage)
        return MessagingChat(userId: "", displayInfo: displayInfo, serviceMetadata: nil)
    }
    
    private func getMockMessage(at index: Int) -> MessagingChatMessage {
        MessagesMockData.allMessages[index]
    }
    
    func getMockMessageTime(at index: Int) -> Date {
        getMockMessage(at: index).displayInfo.time
    }
    
    func getMessagesForChat(_ chat: MessagingChat,
                            before message: MessagingChatMessage?,
                            cachedMessages: [MessagingChatMessage],
                            fetchLimit: Int? = nil) async throws -> [MessagingChatMessage] {
        try await messagingService.getMessagesForChat(chat,
                                                      before: message,
                                                      cachedMessages: cachedMessages,
                                                      fetchLimit: fetchLimit ?? self.fetchLimit,
                                                      isRead: true,
                                                      for: user,
                                                      filesService: filesService)
    }
}

// MARK: - Private methods
private extension XMTPMessagingAPIServiceTests {
    final class MockMessagingServiceDataProvider: XMTPMessagingAPIServiceDataProvider {
        var requests: [RequestDescription] = []
        
        func getPreviousMessagesForChat(_ chat: MessagingChat,
                                        before: Date?,
                                        cachedMessages: [MessagingChatMessage],
                                        fetchLimit: Int,
                                        isRead: Bool,
                                        filesService: MessagingFilesServiceProtocol,
                                        for user: MessagingChatUserProfile) async throws -> [MessagingChatMessage] {
            requests.append(.init(before: before, fetchLimit: fetchLimit))
            let messages = MessagesMockData.messagesBefore(before).prefix(fetchLimit)
            return Array(messages)
        }
        
        struct RequestDescription: Equatable {
            let before: Date?
            let fetchLimit: Int
        }
    }
    
    final class MessagingFilesServiceProtocolMock: MessagingFilesServiceProtocol {
        init(decrypterService: MessagingContentDecrypterService) { }
        
        @discardableResult
        func saveData(_ data: Data, fileName: String) throws -> URL { throw NSError() }
        func deleteDataWith(fileName: String) { }
        func decryptedContentURLFor(message: MessagingChatMessageDisplayInfo) async -> URL? { nil }
    }
    
    
    struct MessagesMockData {
        
        static let message1 = createMessageWith(id: "0", link: "1", timeOffset: 0)
        static let message2 = createMessageWith(id: "1", link: "2", timeOffset: -1)
        static let message3 = createMessageWith(id: "2", link: "3", timeOffset: -2)
        static let message4 = createMessageWith(id: "3", link: "4", timeOffset: -3)
        static let message5 = createMessageWith(id: "4", link: "5", isFirstInChat: true, timeOffset: -4)
        
        static var allMessages: [MessagingChatMessage] {
            [message1,
             message2,
             message3,
             message4,
             message5]
        }
        
        static func messagesBefore(_ date: Date?) -> [MessagingChatMessage] {
            if let date {
                return allMessages.filter({ $0.displayInfo.time < date })
            }
            return allMessages
        }
        
        static func createMessageWith(id: String, link: String, isFirstInChat: Bool = false,
                                      timeOffset: TimeInterval) -> MessagingChatMessage {
            var serviceMetadata = XMTPEnvironmentNamespace.MessageServiceMetadata(encodedContent: .init())
            serviceMetadata.previousMessageId = link
            let displayInfo = MessagingChatMessageDisplayInfo(id: id,
                                                              chatId: "",
                                                              userId: "",
                                                              senderType: .thisUser(.init(wallet: "")),
                                                              time: Date().addingTimeInterval(timeOffset),
                                                              type: .text(.init(text: "")),
                                                              isRead: true,
                                                              isFirstInChat: isFirstInChat,
                                                              deliveryState: .delivered,
                                                              isEncrypted: false)
            return MessagingChatMessage(displayInfo: displayInfo, serviceMetadata: serviceMetadata.jsonData())
        }
    }
    
}
