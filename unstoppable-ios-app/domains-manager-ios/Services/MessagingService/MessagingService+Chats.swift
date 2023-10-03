//
//  MessagingService+Chats.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.10.2023.
//

import Foundation

extension MessagingService {
    func refreshChatsForProfile(_ profile: MessagingChatUserProfile, shouldRefreshUserInfo: Bool) {
        Task {
            dataRefreshManager.startUpdatingChats(for: profile.displayInfo)
            var startTime = Date()
            do {
                let allLocalChats = try await storageService.getChatsFor(profile: profile)
                let localChats = allLocalChats.filter { $0.displayInfo.isApproved}
                let localRequests = allLocalChats.filter { !$0.displayInfo.isApproved}
                
                async let remoteChatsTask = updatedLocalChats(localChats, forProfile: profile, isRequests: false)
                async let remoteRequestsTask = updatedLocalChats(localRequests, forProfile: profile, isRequests: true)
                
                let (remoteChats, remoteRequests) = try await (remoteChatsTask, remoteRequestsTask)
                let allRemoteChats = remoteChats + remoteRequests
                
                let updatedChats = try await refreshChatsMetadata(remoteChats: allRemoteChats,
                                                                  localChats: allLocalChats,
                                                                  for: profile)
                await storageService.saveChats(updatedChats)
                
                let updatedStoredChats = try await getCachedChatsInAllServicesFor(profile: profile.displayInfo)
                let chatsDisplayInfo = updatedStoredChats.sortedByLastMessage().map({ $0.displayInfo })
                notifyListenersChangedDataType(.chats(chatsDisplayInfo, profile: profile.displayInfo))
                Debugger.printTimeSensitiveInfo(topic: .Messaging,
                                                "to refresh chats list for \(profile.wallet)",
                                                startDate: startTime,
                                                timeout: 3)
                
                if shouldRefreshUserInfo {
                    startTime = Date()
                    await refreshUsersInfoFor(profile: profile)
                    Debugger.printTimeSensitiveInfo(topic: .Messaging,
                                                    "to refresh users info for chats list for \(profile.wallet)",
                                                    startDate: startTime,
                                                    timeout: 3)
                }
                dataRefreshManager.stopUpdatingChats(for: profile.displayInfo)
            } catch {
                Debugger.printFailure("Failed to refresh chats list for \(profile.wallet) with error: \(error.localizedDescription)")
            }
        }
    }

    func refreshChatsMetadata(remoteChats: [MessagingChat],
                              localChats: [MessagingChat],
                              for profile: MessagingChatUserProfile) async throws -> [MessagingChat] {
        let apiService = try getAPIServiceWith(identifier: profile.serviceIdentifier)
        var updatedChats = [MessagingChat]()

        await withTaskGroup(of: MessagingChat.self, body: { group in
            for remoteChat in remoteChats {
                group.addTask {
                    if !apiService.capabilities.isRequiredToReloadLastMessage,
                       let localChat = localChats.first(where: { $0.displayInfo.id == remoteChat.displayInfo.id }),
                       localChat.isUpToDateWith(otherChat: remoteChat) {
                        return localChat
                    } else {
                        if var lastMessage = try? await apiService.getMessagesForChat(remoteChat,
                                                                                           before: nil,
                                                                                           cachedMessages: [],
                                                                                           fetchLimit: 1,
                                                                                           isRead: false,
                                                                                           for: profile,
                                                                                           filesService: self.filesService).first {
                            
                            var updatedChat = remoteChat
                            if let storedMessage = await self.storageService.getMessageWith(id: lastMessage.displayInfo.id,
                                                                                            in: remoteChat) {
                                lastMessage.displayInfo.isRead = storedMessage.displayInfo.isRead
                            } else {
                                switch lastMessage.displayInfo.senderType {
                                case .thisUser:
                                    lastMessage.displayInfo.isRead = true
                                case .otherUser:
                                    lastMessage.displayInfo.isRead = localChats.isEmpty // If loading channels for the first time - messages is read by default.
                                }
                            }
                            
                            if !lastMessage.displayInfo.senderType.isThisUser && !lastMessage.displayInfo.isRead {
                                updatedChat.displayInfo.unreadMessagesCount += 1
                            }
                            updatedChat.displayInfo.lastMessage = lastMessage.displayInfo
                            await self.storageService.saveMessages([lastMessage])
                            return updatedChat
                        } else {
                            return remoteChat
                        }
                    }
                }
            }
            
            for await chat in group {
                updatedChats.append(chat)
            }
        })
        
        return updatedChats
    }
    
    func isNewMessagesAvailable(for profile: MessagingChatUserProfile) async throws -> Bool {
        if try await isNewMessagesFromAcceptedChatsAvailable(for: profile) {
            return true
        }
        
        return try await isNewMessagesFromRequestChatsAvailable(for: profile)
    }
    
    func isNewMessagesFromAcceptedChatsAvailable(for profile: MessagingChatUserProfile) async throws -> Bool {
        let apiService = try getAPIServiceWith(identifier: profile.serviceIdentifier)
        let chats = try await apiService.getChatsListForUser(profile, page: 1, limit: 1)
        
        return try await isNewMessagesFromChatsAvailable(chats, for: profile)
    }
    
    func isNewMessagesFromRequestChatsAvailable(for profile: MessagingChatUserProfile) async throws -> Bool {
        let apiService = try getAPIServiceWith(identifier: profile.serviceIdentifier)
        let chats = try await apiService.getChatRequestsForUser(profile, page: 1, limit: 1)
        
        return try await isNewMessagesFromChatsAvailable(chats, for: profile)
    }
    
    func isNewMessagesFromChatsAvailable(_ chats: [MessagingChat], for profile: MessagingChatUserProfile) async throws -> Bool {
        guard let latestChat = chats.first else { return false } /// No messages if no chats
        guard let localChat = await storageService.getChatWith(id: latestChat.displayInfo.id,
                                                               of: latestChat.userId,
                                                               serviceIdentifier: profile.serviceIdentifier) else { return true } /// New chat => new message
        
        return !localChat.isUpToDateWith(otherChat: latestChat)
    }
    
    func getCachedChatsInAllServicesFor(profile: MessagingChatUserProfileDisplayInfo) async throws -> [MessagingChat] {
        let profiles = try await getProfilesForAllServicesBy(userProfile: profile)
        var chats: [MessagingChat] = []
        for profile in profiles {
            if let profileChats = try? await storageService.getChatsFor(profile: profile) {
                chats.append(contentsOf: profileChats)
            }
        }
        return chats
    }
}

// MARK: - Private methods
private extension MessagingService {
    func updatedLocalChats(_ localChats: [MessagingChat],
                           forProfile profile: MessagingChatUserProfile,
                           isRequests: Bool) async throws -> [MessagingChat] {
        let apiService = try getAPIServiceWith(identifier: profile.serviceIdentifier)
        var remoteChats = [MessagingChat]()
        let limit = 30
        var page = 1
        while true {
            do {
                let chatsPage: [MessagingChat]
                if isRequests {
                    chatsPage = try await apiService.getChatRequestsForUser(profile, page: 1, limit: limit)
                } else {
                    chatsPage = try await apiService.getChatsListForUser(profile, page: 1, limit: limit)
                }
                
                remoteChats.append(contentsOf: chatsPage)
                if !apiService.capabilities.isSupportChatsListPagination || chatsPage.count < limit {
                    /// Loaded all chats
                    break
                } else if let lastPageChat = chatsPage.last,
                          let localChat = localChats.first(where: { $0.displayInfo.id == lastPageChat.displayInfo.id }),
                          lastPageChat.isUpToDateWith(otherChat: localChat) {
                    /// No changes for other chats
                    break
                } else {
                    page += 1
                }
            } catch {
                break
            }
        }
        
        await storageService.saveChats(remoteChats)
        
        return remoteChats
    }
}
