//
//  MessagingService+UserProfile.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 03.10.2023.
//

import Foundation

extension MessagingService {
    func createUserProfile(for wallet: WalletEntity, serviceIdentifier: MessagingServiceIdentifier) async throws -> MessagingChatUserProfileDisplayInfo {
        if let task = await stateHolder.getOngoingCreateProfileTask(for: wallet, serviceIdentifier: serviceIdentifier) {
            return try await task.value
        }
        
        let task = CreateProfileTask {
            let apiService = try getAPIServiceWith(identifier: serviceIdentifier)
            
            if let existingUser = try? await getUserProfile(for: wallet, serviceIdentifier: serviceIdentifier) {
                return existingUser
            }
            let newUser = try await apiService.createUser(for: wallet)
            if let domain = wallet.rrDomain {
                Task.detached {
                    try? await apiService.updateUserProfile(newUser, name: domain.name, avatar: domain.pfpSource.value)
                }
            }
            await storageService.saveUserProfile(newUser)
            return newUser.displayInfo
        }
        
        await stateHolder.setOngoingCreateProfileTask(task,
                                                      for: wallet,
                                                      serviceIdentifier: serviceIdentifier)
        let profile = try await task.value
        await stateHolder.setOngoingCreateProfileTask(nil,
                                                      for: wallet,
                                                      serviceIdentifier: serviceIdentifier)
        notifyListenersChangedDataType(.profileCreated(profile))
        return profile
    }
    
    func getUserProfile(for wallet: WalletEntity, serviceIdentifier: MessagingServiceIdentifier) async throws -> MessagingChatUserProfileDisplayInfo {
        try await getUserProfileFor(wallet: wallet, serviceIdentifier: serviceIdentifier)
    }
    
    func getUserProfileFor(wallet: WalletEntity, serviceIdentifier: MessagingServiceIdentifier) async throws -> MessagingChatUserProfileDisplayInfo {
        let apiService = try getAPIServiceWith(identifier: serviceIdentifier)
        if let cachedProfile = try? storageService.getUserProfileFor(wallet: wallet.address,
                                                                     serviceIdentifier: serviceIdentifier) {
            return cachedProfile.displayInfo
        }
        
        let remoteProfile = try await apiService.getUserFor(wallet: wallet)
        await storageService.saveUserProfile(remoteProfile)
        return remoteProfile.displayInfo
    }
    
    func getUserCommunitiesProfile(for messagingProfile: MessagingChatUserProfileDisplayInfo) async throws -> MessagingChatUserProfileDisplayInfo {
        let wallet = try findWalletEntityWithAddress(messagingProfile.wallet)
        return try await getUserProfileFor(wallet: wallet, serviceIdentifier: communitiesServiceIdentifier)
    }
    
    func findWalletEntityWithAddress(_ walletAddress: String) throws -> WalletEntity {
        guard let wallet = appContext.walletsDataService.wallets.findWithAddress(walletAddress) else {
            throw MessagingServiceError.walletNotFound
        }
        return wallet
    }
    
    func createUserCommunitiesProfile(for wallet: WalletEntity) async throws -> MessagingChatUserProfileDisplayInfo {
        try await createUserProfile(for: wallet, serviceIdentifier: communitiesServiceIdentifier)
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
