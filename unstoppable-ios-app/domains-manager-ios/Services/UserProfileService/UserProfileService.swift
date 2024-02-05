//
//  AppSessionInterpreter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.03.2023.
//

import Foundation

final class UserProfileService {
    
    private let firebaseParkedDomainsAuthenticationService: any FirebaseAuthenticationServiceProtocol
    private let firebaseParkedDomainsService: FirebaseDomainsServiceProtocol
    private let walletsDataService: WalletsDataServiceProtocol
    
    @Published private(set) var profiles: [UserProfile] = []
    @Published private(set) var selectedProfile: UserProfile? = nil
    var selectedProfilePublisher: Published<UserProfile?>.Publisher { $selectedProfile }
    
    init(firebaseParkedDomainsAuthenticationService: any FirebaseAuthenticationServiceProtocol,
         firebaseParkedDomainsService: FirebaseDomainsServiceProtocol,
         walletsDataService: WalletsDataServiceProtocol) {
        self.firebaseParkedDomainsAuthenticationService = firebaseParkedDomainsAuthenticationService
        self.firebaseParkedDomainsService = firebaseParkedDomainsService
        self.walletsDataService = walletsDataService
        loadProfilesAndSetSelected()
    }
    
}

// MARK: - Open methods
extension UserProfileService: UserProfileServiceProtocol {
    func setSelectedProfile(_ profile: UserProfile) {
        selectedProfile = profile
        UserDefaults.selectedProfileId = profile.id
        switch profile {
        case .wallet(let walletEntity):
            walletsDataService.setSelectedWallet(walletEntity)
        case .webAccount(let firebaseUser):
            return
        }
    }
}

// MARK: - FirebaseAuthenticationServiceListener
extension UserProfileService: FirebaseAuthenticationServiceListener {
    func firebaseUserUpdated(firebaseUser: FirebaseUser?) {
        loadProfilesAndSetSelected()
    }
}

// MARK: - UDWalletsServiceListener
extension UserProfileService: UDWalletsServiceListener {
    func walletsDataUpdated(notification: UDWalletsServiceNotification) {
        Task {
            switch notification {
            case .walletsUpdated:
                loadProfilesAndSetSelected()
            case .walletRemoved, .reverseResolutionDomainChanged:
                return
            }
        }
    }
}

// MARK: - Private methods
private extension UserProfileService {
    func loadProfilesAndSetSelected() {
        self.profiles = getAvailableProfiles()
        selectedProfile = profiles.first(where: { $0.id == UserDefaults.selectedProfileId }) ?? profiles.first
        UserDefaults.selectedProfileId = selectedProfile?.id
        
        if profiles.isEmpty {
            Task {
                await SceneDelegate.shared?.restartOnboarding()
                appContext.firebaseParkedDomainsAuthenticationService.logout()
            }
        }
        
        if case .wallet(let wallet) = selectedProfile {
            walletsDataService.setSelectedWallet(wallet)
            refreshWalletsAfterLaunchAsync(walletsDataService.wallets.filter({ $0.address != wallet.address}))
        } else {
            refreshWalletsAfterLaunchAsync(walletsDataService.wallets)
        }
    }
    
    func refreshWalletsAfterLaunchAsync(_ wallets: [WalletEntity]) {
        for wallet in wallets  {
            Task.detached { [weak self] in
                try? await self?.walletsDataService.refreshDataForWallet(wallet)
            }
        }
    }
    
    func getAvailableProfiles() -> [UserProfile] {
        var profiles = [UserProfile]()
        let wallets = walletsDataService.wallets
        profiles = wallets.map { UserProfile.wallet($0) }
        
        if var user = firebaseParkedDomainsAuthenticationService.firebaseUser {
            let parkedDomains = firebaseParkedDomainsService.getCachedDomains()
            if !parkedDomains.isEmpty {
                user.numberOfDomains = parkedDomains.count
                profiles.append(.webAccount(user))
            }
        }
        
        return profiles
    }
}

// MARK: - Open methods
extension UserProfileService {
    enum State {
        case noWalletsOrWebAccount
        case walletAdded(WalletEntity)
        case webAccountWithParkedDomains(FirebaseUser)
        case webAccountWithoutParkedDomains
    }
}

enum UserProfile {
    case wallet(WalletEntity) /// Pass selected wallet on app launch
    case webAccount(FirebaseUser)
    
    var id: String {
        switch self {
        case .wallet(let wallet):
            return wallet.address
        case .webAccount(let user):
            return user.displayName
        }
    }
}
