//
//  CoreDataMessagingStorageServiceTests.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 13.11.2023.
//

import XCTest
@testable import domains_manager_ios

class CoreDataMessagingStorageServiceTests: XCTestCase {
    
    
    private var coreDataService: CoreDataMessagingStorageService!
    private var decrypterService: MockDecrypter!
    private var messagingFilesService: MockMessagingFilesService!
    
    override func setUp() async throws {
        decrypterService = MockDecrypter()
        messagingFilesService = MockMessagingFilesService(decrypterService: decrypterService)
        coreDataService = CoreDataMessagingStorageService(decrypterService: decrypterService, inMemory: true)
    }
    
    override func tearDown() async throws {
        coreDataService.clear()
    }
    
    func testStressCreateDeleteEntitiesSingleThread() async throws {
        try await runCreateDeleteOperationsOnSingleThread()
    }
    
    func testStressCreateDeleteEntitiesMultipleThread() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask {
                    try await self.runCreateDeleteOperationsOnSingleThread(id: i)
                }
            }
            
            for try await result in group {
                _ = result
            }
        }
    }
    
    func testLastMessageWontExistInDB() async throws {
        let user = createUsers()[0]
        await coreDataService.saveUserProfile(user)
        var chat = createChatsFor(profile: user)[0]
        let message = createMessages(in: chat)[0]
        chat.displayInfo.lastMessage = message.displayInfo
        await coreDataService.saveChats([chat])
        
        let coreDataChat = try await coreDataService.getChatsFor(profile: user)[0]
        XCTAssertNil(coreDataChat.displayInfo.lastMessage)
    }
    
    func testLastMessageNotYetExistInDB() async throws {
        let user = createUsers()[0]
        await coreDataService.saveUserProfile(user)
        var chat = createChatsFor(profile: user)[0]
        let message = createMessages(in: chat)[0]
        chat.displayInfo.lastMessage = message.displayInfo
        await coreDataService.saveChats([chat])
        await coreDataService.saveMessages([message])
        
        let coreDataChat = try await coreDataService.getChatsFor(profile: user)[0]
        XCTAssertNotNil(coreDataChat.displayInfo.lastMessage)
    }
    
    func testLastMessageChatNotYetExistInDB() async throws {
        let user = createUsers()[0]
        await coreDataService.saveUserProfile(user)
        var chat = createChatsFor(profile: user)[0]
        let message = createMessages(in: chat)[0]
        chat.displayInfo.lastMessage = message.displayInfo
        await coreDataService.saveMessages([message])
        await coreDataService.saveChats([chat])
        
        let coreDataChat = try await coreDataService.getChatsFor(profile: user)[0]
        XCTAssertNotNil(coreDataChat.displayInfo.lastMessage)
    }
    
    func testLastMessageDeleted() async throws {
        let user = createUsers()[0]
        await coreDataService.saveUserProfile(user)
        var chat = createChatsFor(profile: user)[0]
        let message = createMessages(in: chat)[0]
        chat.displayInfo.lastMessage = message.displayInfo
        await coreDataService.saveMessages([message])
        await coreDataService.saveChats([chat])
        
        let coreDataChat = try await coreDataService.getChatsFor(profile: user)[0]
        XCTAssertNotNil(coreDataChat.displayInfo.lastMessage)
        
        coreDataService.deleteMessage(message.displayInfo)
        let coreDataChat2 = try await coreDataService.getChatsFor(profile: user)[0]
        XCTAssertNil(coreDataChat2.displayInfo.lastMessage)
    }
    
    func testLastMessageReplaced() async throws {
        let user = createUsers()[0]
        await coreDataService.saveUserProfile(user)
        var chat1 = createChatsFor(profile: user)[0]
        let message = createMessages(in: chat1)[0]
        chat1.displayInfo.lastMessage = message.displayInfo
        await coreDataService.saveMessages([message])
        await coreDataService.saveChats([chat1])
        
        try await XCTAssertEqualAsync(1, try await coreDataService.getChatsFor(profile: user).count)
        try await XCTAssertNotNilAsync(try await coreDataService.getChatsFor(profile: user)[0].displayInfo.lastMessage)
        
        let message2 = createMessages(in: chat1)[0]
        try await coreDataService.replaceMessage(message, with: message2)
        try await XCTAssertEqualAsync(1, try await coreDataService.getMessagesFor(chat: chat1, before: nil, limit: .max).count)
        try await XCTAssertNilAsync(try await coreDataService.getChatsFor(profile: user)[0].displayInfo.lastMessage)
        
        var chat2 = createChatsFor(profile: user)[0]
        chat2.displayInfo.lastMessage = message2.displayInfo
        try await coreDataService.replaceChat(chat1, with: chat2)
        try await XCTAssertEqualAsync(1, try await coreDataService.getChatsFor(profile: user).count)
    }
    
    func testAddSameMessagesStress() async throws {
        let users = createUsers(2)
        let chat1 = createChatsFor(profile: users[0])[0]
        let chat2 = createChatsFor(profile: users[1])[0]
        let message = createMessages(in: chat1)[0]
        let message2 = MessagingChatMessage(displayInfo: .init(id: message.id,
                                                               chatId: chat2.id,
                                                               userId: chat2.userId,
                                                               senderType: message.displayInfo.senderType,
                                                               time: message.displayInfo.time,
                                                               type: message.displayInfo.type,
                                                               isRead: message.displayInfo.isRead,
                                                               isFirstInChat: message.displayInfo.isFirstInChat,
                                                               deliveryState: message.displayInfo.deliveryState,
                                                               isEncrypted: message.displayInfo.isEncrypted))
        
        for user in users {
            await coreDataService.saveUserProfile(user)
        }
        
        await coreDataService.saveChats([chat1])
        await coreDataService.saveChats([chat1, chat2])
        await coreDataService.saveMessages([message])
        await coreDataService.saveMessages([message, message, message2])
        try await XCTAssertEqualAsync(1, try await coreDataService.getMessagesFor(chat: chat1, before: nil, limit: .max).count)
        try await XCTAssertEqualAsync(1, try await coreDataService.getMessagesFor(chat: chat2, before: nil, limit: .max).count)

        await withTaskGroup(of: Void.self) { task in
            for _ in 0..<1000 {
                task.addTask {
                    await self.coreDataService.saveMessages([message])
                    await self.coreDataService.saveMessages([message, message2])
                }
            }
            
            for await _ in task {
                
            }
        }
        
        try await XCTAssertEqualAsync(1, try await coreDataService.getMessagesFor(chat: chat1, before: nil, limit: .max).count)
        try await XCTAssertEqualAsync(1, try await coreDataService.getMessagesFor(chat: chat2, before: nil, limit: .max).count)
    }
}

// MARK: - Private methods
private extension CoreDataMessagingStorageServiceTests {
    func runCreateDeleteOperationsOnSingleThread(id: Int = 0) async throws {
        Debugger.printInfo("Will run operation \(id)")
        let users = createUsers(4)
        let chats = users.reduce([MessagingChat](), { $0 + createChatsFor(profile: $1, count: 20) })
        let messages = chats.reduce([MessagingChatMessage](), { $0 + createMessages(in: $1, count: 50) })
        Debugger.printInfo("Did create entities for operation \(id)")
        
        for user in users {
            await coreDataService.saveUserProfile(user)
        }
        Debugger.printInfo("Did save users for operation \(id)")
        
        await coreDataService.saveChats(chats)
        Debugger.printInfo("Did save chats for operation \(id)")
        await coreDataService.saveMessages(messages)
        Debugger.printInfo("Did save messages for operation \(id)")
        
        let coreDataUsers = try coreDataService.getAllUserProfiles()
        
        var coreDataChats: [MessagingChat] = []
        for profile in coreDataUsers {
            let chats = try await coreDataService.getChatsFor(profile: profile)
            coreDataChats.append(contentsOf: chats)
        }
        
        var coreDataMessages: [MessagingChatMessage] = []
        for chat in coreDataChats {
            let messages = try await coreDataService.getMessagesFor(chat: chat, before: nil, limit: 1000)
            coreDataMessages.append(contentsOf: messages)
        }
        
        for chat in coreDataChats {
            coreDataService.deleteChat(chat, filesService: messagingFilesService)
        }
        Debugger.printInfo("Did delete chats for operation \(id)")
    }
}

// MARK: - Private methods
private extension CoreDataMessagingStorageServiceTests {
    func createUsers(_ count: Int = 1) -> [MessagingChatUserProfile] {
        var users: [MessagingChatUserProfile] = []
        for i in 0..<count {
            let id = UUID().uuidString
            let wallet = "0x537e2EB956AEC859C99B3e5e28D8E45200C4Fa5\(i)"
            let user = MessagingChatUserProfile(id: id,
                                                wallet: wallet,
                                                displayInfo: .init(id: id,
                                                                   wallet: wallet,
                                                                   serviceIdentifier: .xmtp))
            users.append(user)
        }
        return users
    }
    
    func createChatsFor(profile: MessagingChatUserProfile,
                        count: Int = 1) -> [MessagingChat] {
        var chats = [MessagingChat]()
        
        for i in 0..<count {
            let avatarURL: [URL?] = [nil, URL(string: "https://google.com")]
            let chat = MessagingChat(userId: profile.id,
                                     displayInfo: .init(id: UUID().uuidString,
                                                        thisUserDetails: .init(wallet: profile.wallet),
                                                        avatarURL: avatarURL.randomElement()!,
                                                        serviceIdentifier: profile.serviceIdentifier,
                                                        type: .private(.init(otherUser: .init(wallet: UUID().uuidString))),
                                                        unreadMessagesCount: 0,
                                                        isApproved: [true, false].randomElement()!,
                                                        lastMessageTime: Date().addingTimeInterval(-Double(i)),
                                                        lastMessage: nil),
                                     serviceMetadata: nil)
            chats.append(chat)
        }
        
        return chats
    }
    
    func createMessages(in chat: MessagingChat, count: Int = 1) -> [MessagingChatMessage] {
        var messages = [MessagingChatMessage]()

        for i in 0..<count {
            let senderType: [MessagingChatSender] = [.thisUser(.init(wallet: chat.userId)), .otherUser(.init(wallet: chat.userId))]
            let message = MessagingChatMessage(displayInfo: .init(id: UUID().uuidString,
                                                                  chatId: chat.id,
                                                                  userId: chat.userId,
                                                                  senderType: senderType.randomElement()!,
                                                                  time: Date().addingTimeInterval(-Double(i)),
                                                                  type: .text(.init(text: UUID().uuidString)),
                                                                  isRead: true,
                                                                  isFirstInChat: i == count-1,
                                                                  deliveryState: .delivered,
                                                                  isEncrypted: true))
            
            
            messages.append(message)
        }
        
        return messages
    }
}

private final class MockDecrypter: MessagingContentDecrypterService {
    func encryptText(_ text: String) throws -> String {
        text
    }
    
    func decryptText(_ text: String) throws -> String {
        text
    }
}

private final class MockMessagingFilesService: MessagingFilesServiceProtocol {
    init(decrypterService: domains_manager_ios.MessagingContentDecrypterService) {
        
    }
    
    func saveData(_ data: Data, fileName: String) throws -> URL {
        URL(fileURLWithPath: "")
    }
    
    func deleteDataWith(fileName: String) {
        
    }
    
    func decryptedContentURLFor(message: domains_manager_ios.MessagingChatMessageDisplayInfo) async -> URL? {
        nil
    }
}

