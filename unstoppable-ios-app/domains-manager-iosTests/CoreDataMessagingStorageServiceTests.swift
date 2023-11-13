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
        await runCreateDeleteOperationsOnSingleThread()
    }
    
    func testStressCreateDeleteEntitiesMultipleThread() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask {
                    await self.runCreateDeleteOperationsOnSingleThread(id: i)
                }
            }
            
            for try await result in group {
                _ = result
            }
        }
    }
    
    
}

// MARK: - Private methods
private extension CoreDataMessagingStorageServiceTests {
    func runCreateDeleteOperationsOnSingleThread(id: Int = 0) async {
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
        
        for chat in chats {
            coreDataService.deleteChat(chat, filesService: messagingFilesService)
        }
        Debugger.printInfo("Did delete chats for operation \(id)")
    }
}

// MARK: - Private methods
private extension CoreDataMessagingStorageServiceTests {
    func createUsers(_ count: Int = 2) -> [MessagingChatUserProfile] {
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
                        count: Int = 2) -> [MessagingChat] {
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
    
    func createMessages(in chat: MessagingChat, count: Int = 2) -> [MessagingChatMessage] {
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

