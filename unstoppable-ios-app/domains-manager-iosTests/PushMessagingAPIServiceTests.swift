//
//  PushMessagingAPIServiceTests.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 20.07.2023.
//

import XCTest
import Push
@testable import domains_manager_ios

final class PushMessagingAPIServiceTests: XCTestCase {
    
    private var dataProvider: MockMessagingServiceDataProvider!
    private var messagingService: PushMessagingAPIService!
    private let filesService = MessagingFilesServiceProtocolMock(decrypterService: SymmetricMessagingContentDecrypterService())
    private let user = MessagingChatUserProfile(id: "", wallet: "", displayInfo: .init(id: "", wallet: "", serviceIdentifier: .xmtp))
    private let fetchLimit = 5
    private var firstMessage: MessagingChatMessage { getMockMessage(at: 0) }
    private var firstMessageId: String { firstMessage.displayInfo.id }
    
    override func setUp() async throws {
        try await super.setUp()
        
        dataProvider = MockMessagingServiceDataProvider()
        messagingService = PushMessagingAPIService(dataProvider: dataProvider)
    }
    
    //MARK: - Do not pass before message
    func testNoMessagesReturnBecauseNoThreadHashNoBeforeMessage() async throws {
        let chat = createMessagingChat(lastMessage: nil, threadHash: nil)
        let messages = try await getMessagesForChat(chat,
                                                    before: nil,
                                                    cachedMessages: [])
        
        XCTAssertEqual(messages, [])
        XCTAssertEqual(dataProvider.requests, [])
    }
    
    func testAllMessagesReturnBasedOnChatThreadHashNoBeforeMessage() async throws {
        let chat = createMessagingChat(lastMessage: nil, threadHash: firstMessageId)
        let messages = try await getMessagesForChat(chat,
                                                    before: nil,
                                                    cachedMessages: [])
        
        XCTAssertEqual(messages, MessagesMockData.allMessages)
        XCTAssertEqual(dataProvider.requests, [.init(threadHash: firstMessageId, fetchLimit: fetchLimit)])
    }
    
    func testAllMessagesReturnBasedOnChatThreadHashNoBeforeMessageHaveCacheNotFirstMessage() async throws {
        let chat = createMessagingChat(lastMessage: nil, threadHash: firstMessageId)
        let messages = try await getMessagesForChat(chat,
                                                    before: nil,
                                                    cachedMessages: [getMockMessage(at: 1)])
        
        XCTAssertEqual(messages, MessagesMockData.allMessages)
        XCTAssertEqual(dataProvider.requests, [.init(threadHash: firstMessageId, fetchLimit: fetchLimit)])
    }
    
    func testAllMessagesReturnBasedOnChatThreadHashNoBeforeMessageHaveCacheFirstMessage() async throws {
        let chat = createMessagingChat(lastMessage: nil, threadHash: firstMessageId)
        let messages = try await getMessagesForChat(chat,
                                                    before: nil,
                                                    cachedMessages: [firstMessage])
        
        XCTAssertEqual(messages, MessagesMockData.allMessages)
        XCTAssertEqual(dataProvider.requests, [.init(threadHash: getMockMessageId(at: 1), fetchLimit: fetchLimit - 1)])
    }
    
    func testAllMessagesReturnBasedOnChatThreadHashNoBeforeMessageHaveCacheFirstTwoMessages() async throws {
        let chat = createMessagingChat(lastMessage: nil, threadHash: firstMessageId)
        let messages = try await getMessagesForChat(chat,
                                                    before: nil,
                                                    cachedMessages: [firstMessage,
                                                                     getMockMessage(at: 1)])
        
        XCTAssertEqual(messages, MessagesMockData.allMessages)
        XCTAssertEqual(dataProvider.requests, [.init(threadHash: getMockMessageId(at: 2), fetchLimit: fetchLimit - 2)])
    }
    
    func testAllMessagesInCacheNoBefore() async throws {
        let chat = createMessagingChat(lastMessage: nil, threadHash: firstMessageId)
        let messages = try await getMessagesForChat(chat,
                                                    before: nil,
                                                    cachedMessages: MessagesMockData.allMessages)
        
        XCTAssertEqual(messages, MessagesMockData.allMessages)
        XCTAssertEqual(dataProvider.requests, [])
    }
    
    //MARK: - Pass before message
    func testAllMessagesReturnBasedOnLastMessageOneMessageNoCache() async throws {
        let chat = createMessagingChat(lastMessage: nil, threadHash: firstMessageId)
        let messages = try await getMessagesForChat(chat,
                                                    before: firstMessage,
                                                    cachedMessages: [])
        
        XCTAssertEqual(messages, Array(MessagesMockData.allMessages.suffix(4)))
        XCTAssertEqual(dataProvider.requests, [.init(threadHash: getMockMessageId(at: 1), fetchLimit: fetchLimit)])
    }
    
    func testAllMessagesReturnBasedOnLastMessageOneMessageInCache() async throws {
        let chat = createMessagingChat(lastMessage: nil, threadHash: firstMessageId)
        let messages = try await getMessagesForChat(chat,
                                                    before: firstMessage,
                                                    cachedMessages: [getMockMessage(at: 1)])
        
        XCTAssertEqual(messages, Array(MessagesMockData.allMessages.suffix(4)))
        XCTAssertEqual(dataProvider.requests, [.init(threadHash: getMockMessageId(at: 2), fetchLimit: fetchLimit - 1)])
    }
    
    func testAllMessagesReturnBasedOnLastMessageThreeMessageInCache() async throws {
        let chat = createMessagingChat(lastMessage: nil, threadHash: firstMessageId)
        let messages = try await getMessagesForChat(chat,
                                                    before: firstMessage,
                                                    cachedMessages: [getMockMessage(at: 1),
                                                                     getMockMessage(at: 2),
                                                                     getMockMessage(at: 3)])
        
        XCTAssertEqual(messages, Array(MessagesMockData.allMessages.suffix(4)))
        XCTAssertEqual(dataProvider.requests, [.init(threadHash: getMockMessageId(at: 4), fetchLimit: fetchLimit - 3)])
    }
    
    func testAllMessagesReturnBasedOnTwoMessagesWithBreakInCache() async throws {
        let chat = createMessagingChat(lastMessage: nil, threadHash: firstMessageId)
        let messages = try await getMessagesForChat(chat,
                                                    before: firstMessage,
                                                    cachedMessages: [getMockMessage(at: 1),
                                                                     getMockMessage(at: 3)])
        
        XCTAssertEqual(messages, Array(MessagesMockData.allMessages.suffix(4)))
        XCTAssertEqual(dataProvider.requests, [.init(threadHash: getMockMessageId(at: 2), fetchLimit: fetchLimit - 1)])
    }
    
    func testAllMessagesReturnBasedOnLastMessageAndSomeLatestMessagesInCache() async throws {
        let chat = createMessagingChat(lastMessage: nil, threadHash: firstMessageId)
        let messages = try await getMessagesForChat(chat,
                                                    before: firstMessage,
                                                    cachedMessages: [firstMessage,
                                                                     getMockMessage(at: 1)])
        
        XCTAssertEqual(messages, Array(MessagesMockData.allMessages.suffix(4)))
        XCTAssertEqual(dataProvider.requests, [.init(threadHash: getMockMessageId(at: 1), fetchLimit: fetchLimit)])
    }
    
    func testAllMessagesReturnBasedOnLastMessageAndSomeRandomMessagesInCache() async throws {
        let chat = createMessagingChat(lastMessage: nil, threadHash: firstMessageId)
        let messages = try await getMessagesForChat(chat,
                                                    before: firstMessage,
                                                    cachedMessages: [getMockMessage(at: 3)])
        
        XCTAssertEqual(messages, Array(MessagesMockData.allMessages.suffix(4)))
        XCTAssertEqual(dataProvider.requests, [.init(threadHash: getMockMessageId(at: 1), fetchLimit: fetchLimit)])
    }
    
    func testAllMessagesReturnBasedOnSomeMessagesInCache() async throws {
        let chat = createMessagingChat(lastMessage: nil, threadHash: firstMessageId)
        let messages = try await getMessagesForChat(chat,
                                                    before: getMockMessage(at: 2),
                                                    cachedMessages: [getMockMessage(at: 3)])
        
        XCTAssertEqual(messages, Array(MessagesMockData.allMessages.suffix(2)))
        XCTAssertEqual(dataProvider.requests, [.init(threadHash: getMockMessageId(at: 4), fetchLimit: fetchLimit - 1)])
    }
    
    func testAllMessagesInCache() async throws {
        let chat = createMessagingChat(lastMessage: nil, threadHash: firstMessageId)
        let messages = try await getMessagesForChat(chat,
                                                    before: firstMessage,
                                                    cachedMessages: Array(MessagesMockData.allMessages.suffix(4)))
        
        XCTAssertEqual(messages, Array(MessagesMockData.allMessages.suffix(4)))
        XCTAssertEqual(dataProvider.requests, [])
    }
    
}

// MARK: - Private methods
private extension PushMessagingAPIServiceTests {
    func createMessagingChat(lastMessage: MessagingChatMessageDisplayInfo?, threadHash: String?) -> MessagingChat {
        let serviceMetadata = PushEnvironment.ChatServiceMetadata(threadHash: threadHash).jsonData()
        let displayInfo = MessagingChatDisplayInfo(id: "", thisUserDetails: .init(wallet: ""),
                                                   avatarURL: nil, 
                                                   serviceIdentifier: .xmtp,
                                                   type: .private(.init(otherUser: .init(wallet: ""))),
                                                   unreadMessagesCount: 0,
                                                   isApproved: true,
                                                   lastMessageTime: Date(),
                                                   lastMessage: lastMessage)
        return MessagingChat(userId: "", displayInfo: displayInfo, serviceMetadata: serviceMetadata)
    }
    
    private func getMockMessage(at index: Int) -> MessagingChatMessage {
        MessagesMockData.allMessages[index]
    }
    
    func getMockMessageId(at index: Int) -> String {
        getMockMessage(at: index).displayInfo.id
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
private extension PushMessagingAPIServiceTests {
    final class MockMessagingServiceDataProvider: PushMessagingAPIServiceDataProvider {
        var requests: [RequestDescription] = []
        
        func getPreviousMessagesForChat(_ chat: MessagingChat,
                                        threadHash: String,
                                        fetchLimit: Int,
                                        isRead: Bool,
                                        filesService: MessagingFilesServiceProtocol,
                                        for user: MessagingChatUserProfile) async throws -> [MessagingChatMessage] {
            requests.append(.init(threadHash: threadHash, fetchLimit: fetchLimit))
            let messages = MessagesMockData.messagesBefore(threadHash).prefix(fetchLimit)
            return Array(messages)
        }
        
        struct RequestDescription: Equatable {
            let threadHash: String
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
        
        static let message1 = createMessageWith(id: "0", link: "1")
        static let message2 = createMessageWith(id: "1", link: "2")
        static let message3 = createMessageWith(id: "2", link: "3")
        static let message4 = createMessageWith(id: "3", link: "4")
        static let message5 = createMessageWith(id: "4", link: "5", isFirstInChat: true)
        
        static var allMessages: [MessagingChatMessage] {
            [message1,
             message2,
             message3,
             message4,
             message5]
        }
        
        static func messagesBefore(_ threadHash: String?) -> [MessagingChatMessage] {
            if let threadHash {
                guard let i = allMessages.firstIndex(where: { $0.displayInfo.id == threadHash }) else {
                    fatalError()
                }
                
                return Array(allMessages[i..<allMessages.count])
            }
            return allMessages
        }
        
        static func createMessageWith(id: String, link: String, isFirstInChat: Bool = false) -> MessagingChatMessage {
            let serviceMetadata = PushEnvironment.MessageServiceMetadata(encType: "",
                                                                         link: link).jsonData()
            let displayInfo = MessagingChatMessageDisplayInfo(id: id,
                                                              chatId: "",
                                                              userId: "",
                                                              senderType: .thisUser(.init(wallet: "")),
                                                              time: Date(),
                                                              type: .text(.init(text: "")),
                                                              isRead: true,
                                                              isFirstInChat: isFirstInChat,
                                                              deliveryState: .delivered,
                                                              isEncrypted: false)
            return MessagingChatMessage(displayInfo: displayInfo, serviceMetadata: serviceMetadata)
        }
    }

}
