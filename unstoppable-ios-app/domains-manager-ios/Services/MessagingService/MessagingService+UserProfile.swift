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
        try await getUserProfileFor(domainName: domain.name, serviceIdentifier: serviceIdentifier)
    }
    
    func getUserProfileFor(domainName: String, serviceIdentifier: MessagingServiceIdentifier) async throws -> MessagingChatUserProfileDisplayInfo {
        let domain = try await appContext.dataAggregatorService.getDomainWith(name: domainName)
        return try await getUserProfileFor(domainItem: domain, serviceIdentifier: serviceIdentifier)
    }
    
    func getUserProfileFor(domainItem: DomainItem, serviceIdentifier: MessagingServiceIdentifier) async throws -> MessagingChatUserProfileDisplayInfo {
        let apiService = try getAPIServiceWith(identifier: serviceIdentifier)
        if let cachedProfile = try? storageService.getUserProfileFor(domain: domainItem,
                                                                     serviceIdentifier: serviceIdentifier) {
            return cachedProfile.displayInfo
        }
        
        let remoteProfile = try await apiService.getUserFor(domain: domainItem)
        await storageService.saveUserProfile(remoteProfile)
        return remoteProfile.displayInfo
    }
    
    func getUserCommunitiesProfile(for messagingProfile: MessagingChatUserProfileDisplayInfo) async throws -> MessagingChatUserProfileDisplayInfo {
        let wallet = messagingProfile.wallet
        let domain = try await getReverseResolutionDomainItem(for: wallet)
        return try await getUserProfileFor(domainItem: domain, serviceIdentifier: communitiesServiceIdentifier)
    }
    
    func createUserCommunitiesProfile(for domain: DomainDisplayInfo) async throws -> MessagingChatUserProfileDisplayInfo {
        try await createUserProfile(for: domain, serviceIdentifier: communitiesServiceIdentifier)
    }
    
    /// Return at least one existing profile or throw error
    func getProfilesForAllServicesBy(userProfile: MessagingChatUserProfileDisplayInfo) async throws -> [MessagingChatUserProfile] {
        let profile = try await getUserProfileWith(wallet: userProfile.wallet, serviceIdentifier: userProfile.serviceIdentifier)
        var profiles = [profile]
        
        for serviceIdentifier in MessagingServiceIdentifier.allCases where serviceIdentifier != userProfile.serviceIdentifier {
            if let profile = try? await getUserProfileWith(wallet: userProfile.wallet, serviceIdentifier: serviceIdentifier) {
                profiles.append(profile)
            }
        }
        
        return profiles
    }
    
    func getDefaultProfile(for profile: MessagingChatUserProfile) async throws -> MessagingChatUserProfile? {
        if profile.serviceIdentifier == defaultServiceIdentifier {
            return profile
        }
        let profiles = try await getProfilesForAllServicesBy(userProfile: profile.displayInfo)
        return profiles.first(where: { $0.serviceIdentifier == defaultServiceIdentifier })
    }
}
