//
//  DomainProfilesService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.03.2024.
//

import Foundation
import Combine

final class DomainProfilesService {
   
    private let storage: DomainProfileDisplayInfoStorageServiceProtocol
    private let networkService: DomainProfileNetworkServiceProtocol
    private let walletsDataService: WalletsDataServiceProtocol
    private let numberOfFollowersToTake = 40
    private let serialQueue = DispatchQueue(label: "com.domain_profiles_service.unstoppable")
    private var profilesSocialDetailsCache: [HexAddress : PublishableDomainProfileDetailsController] = [:]
    private var cancellables: Set<AnyCancellable> = []

    init(networkService: DomainProfileNetworkServiceProtocol = NetworkService(),
         storage: DomainProfileDisplayInfoStorageServiceProtocol,
         walletsDataService: WalletsDataServiceProtocol) {
        self.networkService = networkService
        self.storage = storage
        self.walletsDataService = walletsDataService
        walletsDataService.walletsPublisher.receive(on: DispatchQueue.main).sink { [weak self] wallets in
            self?.walletsListUpdated(wallets)
        }.store(in: &cancellables)
    }
    
    func walletsListUpdated(_ wallets: [WalletEntity]) {
        Task {
            for wallet in wallets {
                if let cachedController = getCachedProfileSocialDetailFor(walletAddress: wallet.address),
                   wallet.profileDomainName != (await cachedController.profileDomainName) {
                    await cachedController.resetAllDetails()
                    refreshAllProfileDetailsNonBlockingFor(controller: cachedController)
                }
            }
        }
    }
    
}

// MARK: - DomainProfilesServiceProtocol
extension DomainProfilesService: DomainProfilesServiceProtocol {
    func getCachedDomainProfileDisplayInfo(for domainName: String) -> DomainProfileDisplayInfo? {
        try? storage.retrieveProfileFor(domainName: domainName)
    }
 
    func fetchDomainProfileDisplayInfo(for domainName: DomainName) async throws -> DomainProfileDisplayInfo {
        let serializedProfile = try await getSerializedPublicDomainProfile(for: domainName)
        let profile = DomainProfileDisplayInfo(serializedProfile: serializedProfile)
        
        storage.store(profile: profile)
        
        return profile
    }
    
    func getCachedAndRefreshDomainProfileStream(for domainName: DomainName) -> AsyncThrowingStream<DomainProfileDisplayInfo, Error> {
        AsyncThrowingStream { continuation in
            Task {
                if let cachedProfile = getCachedDomainProfileDisplayInfo(for: domainName) {
                    continuation.yield(cachedProfile)
                }
                
                do {
                    let refreshedProfile = try await fetchDomainProfileDisplayInfo(for: domainName)
                    continuation.yield(refreshedProfile)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    @discardableResult // TODO: - Update function to return DomainProfileDisplayInfo
    func updateUserDomainProfile(for domain: DomainDisplayInfo,
                                        request: ProfileUpdateRequest) async throws -> SerializedUserDomainProfile {
        let serializedProfile = try await networkService.updateUserDomainProfile(for: domain.toDomainItem(),
                                                                                 request: request)
        try resetDomainDisplayInfoForWalletOwning(domain: domain)
        return serializedProfile
    }
    
    func followProfileWith(domainName: String, by domain: DomainDisplayInfo) async throws {
        try await networkService.follow(domainName, by: domain.toDomainItem())
        try resetSocialsCacheForWalletOwning(domain: domain)
    }
    
    func unfollowProfileWith(domainName: String, by domain: DomainDisplayInfo) async throws {
        try await networkService.unfollow(domainName, by: domain.toDomainItem())
        try resetSocialsCacheForWalletOwning(domain: domain)
    }
    
    func publisherForWalletDomainProfileDetails(wallet: WalletEntity) async -> CurrentValueSubject<WalletDomainProfileDetails, Never> {
        await getOrCreateProfileDetailsControllerFor(walletAddress: wallet.address).publisher
    }
    
    func loadMoreSocialIfAbleFor(relationshipType: DomainProfileFollowerRelationshipType,
                                 in wallet: WalletEntity) {
        loadMoreSocialIfAbleFor(relationshipType: relationshipType, walletAddress: wallet.address)
    }
}

// MARK: - Private methods
private extension DomainProfilesService {
    func getOrCreateProfileDetailsControllerFor(walletAddress: HexAddress) -> PublishableDomainProfileDetailsController {
        if let cachedController = getCachedProfileSocialDetailFor(walletAddress: walletAddress) {
            return cachedController
        }
        
        let profileDomainName = getProfileDomainNameFor(walletAddress: walletAddress)
        let domainProfileDisplayInfo = getDomainProfileDisplayInfoForNewControllerFor(profileDomainName: profileDomainName)
        let newController = PublishableDomainProfileDetailsController(walletAddress: walletAddress,
                                                                      profileDomainName: profileDomainName,
                                                                      displayInfo: domainProfileDisplayInfo)
        cacheProfileSocialDetail(newController, for: walletAddress)
        refreshAllProfileDetailsNonBlockingFor(controller: newController)
        
        return newController
    }
    
    func refreshAllProfileDetailsNonBlockingFor(controller: PublishableDomainProfileDetailsController) {
        Task {
            let walletAddress = await controller.walletAddress
            refreshSocialDetailsNonBlockingFor(walletAddress: walletAddress)
            await refreshDomainProfileDisplayInfo(in: controller)
        }
    }
    
    func refreshDomainProfileDisplayInfo(in controller: PublishableDomainProfileDetailsController) async {
        if let profileDomainName = await controller.profileDomainName {
            do {
                let displayInfo = try await fetchDomainProfileDisplayInfo(for: profileDomainName)
                await controller.setProfileDisplayInfo(displayInfo)
            } catch { }
        }
    }
    
    func resetDomainDisplayInfoForWalletOwning(domain: DomainDisplayInfo) throws {
        let walletAddress = try domain.getOwnerWallet()
        Task {
            let controller = getOrCreateProfileDetailsControllerFor(walletAddress: walletAddress)
            let profileDomainName = await controller.profileDomainName
            if domain.name == profileDomainName {
                await refreshDomainProfileDisplayInfo(in: controller)
            }
        }
    }

    func refreshSocialDetailsNonBlockingFor(walletAddress: HexAddress) {
        loadMoreSocialIfAbleFor(relationshipType: .followers, walletAddress: walletAddress)
        loadMoreSocialIfAbleFor(relationshipType: .following, walletAddress: walletAddress)
    }
    
    func getDomainProfileDisplayInfoForNewControllerFor(profileDomainName: DomainName?) -> DomainProfileDisplayInfo? {
        if let profileDomainName {
            return getCachedDomainProfileDisplayInfo(for: profileDomainName)
        }
        return nil
    }
    
    func getCachedProfileSocialDetailFor(walletAddress: HexAddress) -> PublishableDomainProfileDetailsController? {
        serialQueue.sync {
            profilesSocialDetailsCache[walletAddress]
        }
    }
    
    func cacheProfileSocialDetail(_ details: PublishableDomainProfileDetailsController,
                                  for walletAddress: HexAddress) {
        serialQueue.sync {
            profilesSocialDetailsCache[walletAddress] = details
        }
    }
    
    func getProfileDomainNameFor(walletAddress: HexAddress) -> DomainName? {
        let wallet = appContext.walletsDataService.wallets.findWithAddress(walletAddress)
        return wallet?.profileDomainName
    }
    
    func getSerializedPublicDomainProfile(for domainName: DomainName) async throws -> SerializedPublicDomainProfile {
        let serializedProfile = try await networkService.fetchPublicProfile(for: domainName,
                                                                            fields: [.profile, .records, .socialAccounts])
        return serializedProfile
    }
    
    func loadMoreSocialIfAbleFor(relationshipType: DomainProfileFollowerRelationshipType,
                                 walletAddress: HexAddress) {
        Task {
            let profileController = getOrCreateProfileDetailsControllerFor(walletAddress: walletAddress)
            
            guard let profileDomainName = await profileController.profileDomainName,
                  await profileController.isAbleToLoadMoreSocialsFor(relationshipType: relationshipType) else { return }
            
            await profileController.setLoading(relationshipType: relationshipType)
            
            do {
                let cursor = await profileController.getPaginationCursorFor(relationshipType: relationshipType)
                let response = try await networkService.fetchListOfFollowers(for: profileDomainName,
                                                                               relationshipType: relationshipType,
                                                                               count: numberOfFollowersToTake,
                                                                               cursor: cursor)
                await profileController.applyDetailsFrom(response: response)
            }
            
            await profileController.setNotLoading(relationshipType: relationshipType)
        }
    }
    
    func resetSocialsCacheForWalletOwning(domain: DomainDisplayInfo) throws {
        let walletAddress = try domain.getOwnerWallet()
        Task {
            let controller = getOrCreateProfileDetailsControllerFor(walletAddress: walletAddress)
            await controller.resetSocialDetails()
            refreshSocialDetailsNonBlockingFor(walletAddress: walletAddress)
        }
    }
}

// MARK: - Open methods
extension DomainProfilesService {
    enum DomainProfilesServiceError: String, LocalizedError {
        case noDomainForSocialDetails
        
        public var errorDescription: String? {
            return rawValue
        }
    }
}

// MARK: - Private methods
private extension DomainProfilesService {
    actor PublishableDomainProfileDetailsController {
        private var details: WalletDomainProfileDetails {
            didSet {
                publisher.send(details)
            }
        }
        private(set) var publisher: CurrentValueSubject<WalletDomainProfileDetails, Never>
        private var loadingRelationshipTypes: Set<DomainProfileFollowerRelationshipType> = []
        
        init(walletAddress: HexAddress,
             profileDomainName: DomainName?,
             displayInfo: DomainProfileDisplayInfo?) {
            self.details = WalletDomainProfileDetails(walletAddress: walletAddress,
                                                      profileDomainName: profileDomainName,
                                                      displayInfo: displayInfo)
            self.publisher = CurrentValueSubject(details)
        }
        
        var walletAddress: HexAddress { details.walletAddress }
        var profileDomainName: DomainName? { details.profileDomainName }
        
        func getPaginationCursorFor(relationshipType: DomainProfileFollowerRelationshipType) -> Int? {
            details.socialDetails?.getPaginationInfoFor(relationshipType: relationshipType).cursor
        }
        
        func isAbleToLoadMoreSocialsFor(relationshipType: DomainProfileFollowerRelationshipType) -> Bool {
            details.socialDetails?.getPaginationInfoFor(relationshipType: relationshipType).canLoadMore == true &&
            !isLoading(relationshipType: relationshipType)
        }
        
        private func isLoading(relationshipType: DomainProfileFollowerRelationshipType) -> Bool {
            loadingRelationshipTypes.contains(relationshipType)
        }
        
        func setLoading(relationshipType: DomainProfileFollowerRelationshipType) {
            loadingRelationshipTypes.insert(relationshipType)
        }
        
        func setNotLoading(relationshipType: DomainProfileFollowerRelationshipType) {
            loadingRelationshipTypes.remove(relationshipType)
        }
        
        func applyDetailsFrom(response: DomainProfileFollowersResponse) {
            details.socialDetails?.applyDetailsFrom(response: response)
        }
        
        func setProfileDisplayInfo(_ displayInfo: DomainProfileDisplayInfo) {
            details.displayInfo = displayInfo
        }
        
        func resetSocialDetails() {
            details.resetSocialDetails()
        }
        
        func resetAllDetails() {
            details.resetAllDetails()
        }
    }
}
