//
//  MessagingService+UserProfile.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 03.10.2023.
//

import Foundation

extension MessagingService {
    func createUserProfile(for domain: DomainDisplayInfo, serviceIdentifier: MessagingServiceIdentifier) async throws -> MessagingChatUserProfileDisplayInfo {
        let apiService = try getAPIServiceWith(identifier: serviceIdentifier)
        
        if let existingUser = try? await getUserProfile(for: domain, serviceIdentifier: serviceIdentifier) {
            return existingUser
        }
        let domainItem = try await appContext.dataAggregatorService.getDomainWith(name: domain.name)
        let newUser = try await apiService.createUser(for: domainItem)
        Task.detached {
            try? await apiService.updateUserProfile(newUser, name: domain.name, avatar: domain.pfpSource.value)
        }
        await storageService.saveUserProfile(newUser)
        return newUser.displayInfo
    }
    
    func getUserProfile(for domain: DomainDisplayInfo, serviceIdentifier: MessagingServiceIdentifier) async throws -> MessagingChatUserProfileDisplayInfo {
        let apiService = try getAPIServiceWith(identifier: serviceIdentifier)
        let domain = try await appContext.dataAggregatorService.getDomainWith(name: domain.name)
        if let cachedProfile = try? storageService.getUserProfileFor(domain: domain,
                                                                     serviceIdentifier: serviceIdentifier) {
            return cachedProfile.displayInfo
        }
        
        let remoteProfile = try await apiService.getUserFor(domain: domain)
        await storageService.saveUserProfile(remoteProfile)
        return remoteProfile.displayInfo
    }
}
