//
//  MessagingService+UserInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.10.2023.
//

import Foundation

extension MessagingService {
    func refreshUsersInfoFor(profile: MessagingChatUserProfile) async{
        do {
            let chats = try await storageService.getChatsFor(profile: profile)
            await withTaskGroup(of: Void.self, body: { group in
                for chat in chats {
                    group.addTask {
                        if let otherUserInfo = try? await self.loadUserInfoFor(chat: chat) {
                            for info in otherUserInfo {
                                await self.storageService.saveMessagingUserInfo(info)
                            }
                        }
                        return Void()
                    }
                }
                
                for await _ in group {
                    Void()
                }
            })
            
            let updatedChats = try await getCachedChatsInAllServicesFor(profile: profile.displayInfo)
            notifyListenersChangedDataType(.chats(updatedChats.map { $0.displayInfo }, profile: profile.displayInfo))
        } catch { }
    }
    
    func loadUserInfoFor(chat: MessagingChat) async throws -> [MessagingChatUserDisplayInfo] {
        switch chat.displayInfo.type {
        case .private(let details):
            let wallet = details.otherUser.wallet
            if let userInfo = await loadUserInfoFor(wallet: wallet) {
                return [userInfo]
            }
            return []
        case .group(let details):
            return await loadGroupUserInfosFor(members: details.allMembers)
        case .community(let details):
            return await loadGroupUserInfosFor(members: details.members)
        }
    }
    
    func loadUserInfoFor(wallet: String) async -> MessagingChatUserDisplayInfo? {
        if let domain = try? await appContext.udWalletsService.reverseResolutionDomainName(for: wallet.normalized),
           !domain.isEmpty {
            let pfpInfo = await appContext.udDomainsService.loadPFP(for: domain)
            var pfpURL: URL?
            if let urlString = pfpInfo?.pfpURL,
               let url = URL(string: urlString) {
                pfpURL = url
            }
            return MessagingChatUserDisplayInfo(wallet: wallet,
                                                domainName: domain,
                                                pfpURL: pfpURL)
        } else if var userInfo = await loadGlobalUserInfoFor(value: wallet) {
            userInfo.wallet = wallet // Fix lower/uppercase inconsistency issue
            return userInfo
        }
        
        return nil
    }
    
    // Value can be either wallet address or domain name
    func loadGlobalUserInfoFor(value: String) async -> MessagingChatUserDisplayInfo? {
        if let rrInfo = try? await NetworkService().fetchGlobalReverseResolution(for: value.lowercased()) {
            return MessagingChatUserDisplayInfo(wallet: rrInfo.address,
                                                domainName: rrInfo.name,
                                                pfpURL: rrInfo.pfpURLToUse)
        }
        return nil
    }
}

// MARK: - Private methods
private extension MessagingService {
    func loadGroupUserInfosFor(members: [MessagingChatUserDisplayInfo]) async -> [MessagingChatUserDisplayInfo] {
        var infos: [MessagingChatUserDisplayInfo] = []
        let members = members.prefix(3) // Only first 3 members will be displayed on the UI
        for member in members {
            if let userInfo = await loadUserInfoFor(wallet: member.wallet) {
                infos.append(userInfo)
            }
        }
        return infos
    }
}
