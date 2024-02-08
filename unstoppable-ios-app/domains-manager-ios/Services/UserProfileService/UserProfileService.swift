//
//  AppSessionInterpreter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.03.2023.
//

import Foundation
import Combine

final class UserProfileService {
    
    private let firebaseParkedDomainsAuthenticationService: any FirebaseAuthenticationServiceProtocol
    private let firebaseParkedDomainsService: FirebaseDomainsServiceProtocol
    private let walletsDataService: WalletsDataServiceProtocol
    
    @Published private(set) var profiles: [UserProfile] = []
    @Published private(set) var selectedProfile: UserProfile? = nil
    var selectedProfilePublisher: Published<UserProfile?>.Publisher { $selectedProfile }
    private var cancellables: Set<AnyCancellable> = []

    init(firebaseParkedDomainsAuthenticationService: any FirebaseAuthenticationServiceProtocol,
         firebaseParkedDomainsService: FirebaseDomainsServiceProtocol,
         walletsDataService: WalletsDataServiceProtocol) {
        self.firebaseParkedDomainsAuthenticationService = firebaseParkedDomainsAuthenticationService
        self.firebaseParkedDomainsService = firebaseParkedDomainsService
        self.walletsDataService = walletsDataService
        loadProfilesAndSetSelected()
        firebaseParkedDomainsService.parkedDomainsPublisher.receive(on: DispatchQueue.main).sink { [weak self] parkedDomains in
            if parkedDomains.isEmpty {
                self?.removeWebProfileIfNeeded()
            }
        }.store(in: &cancellables)
        walletsDataService.walletsPublisher.receive(on: DispatchQueue.main).sink { [weak self] _ in
            self?.updateProfilesList()
        }.store(in: &cancellables)
        firebaseParkedDomainsAuthenticationService.authorizedUserPublisher.receive(on: DispatchQueue.main).sink { [weak self] _ in
            self?.updateProfilesList()
        }.store(in: &cancellables)
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
        case .webAccount:
            walletsDataService.setSelectedWallet(nil)
        }
    }
}

// MARK: - UDWalletsServiceListener
extension UserProfileService: UDWalletsServiceListener {
    func walletsDataUpdated(notification: UDWalletsServiceNotification) {
        Task {
            switch notification {
            case .walletsUpdated:
                updateProfilesList()
            case .walletRemoved, .reverseResolutionDomainChanged:
                return
            }
        }
    }
}

// MARK: - Private methods
private extension UserProfileService {
    func loadProfilesAndSetSelected() {
        updateProfilesList()
        
        if case .wallet(let wallet) = selectedProfile {
            walletsDataService.setSelectedWallet(wallet)
            refreshWalletsAfterLaunchAsync(walletsDataService.wallets.filter({ $0.address != wallet.address}))
        } else {
            refreshWalletsAfterLaunchAsync(walletsDataService.wallets)
        }
    }
    
    func updateProfilesList() {
        let currentProfilesList = self.profiles
        let currentSelectedProfile = self.selectedProfile
        self.profiles = getAvailableProfiles()
        let selectedProfile = profiles.first(where: { $0.id == UserDefaults.selectedProfileId }) ?? profiles.first
        setSelectedProfile(selectedProfile)
        
        if profiles.isEmpty {
            Task {
                await SceneDelegate.shared?.restartOnboarding()
                firebaseParkedDomainsAuthenticationService.logOut()
            }
            return
        }
        
        if currentSelectedProfile?.id != selectedProfile?.id,
           case .wallet(let wallet) = selectedProfile {
            walletsDataService.setSelectedWallet(wallet)
        }
        
        if !currentProfilesList.isEmpty,
           profiles.count > currentProfilesList.count,
           let newProfile = profiles.first(where: { profile in
               return currentProfilesList.first(where: { $0.id == profile.id }) == nil
           }) {
            /// New profile(s) added. Set as selected
            setSelectedProfile(newProfile)
        }
    }
    
    func setSelectedProfile(_ profile: UserProfile?) {
        selectedProfile = profile
        UserDefaults.selectedProfileId = profile?.id
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
        
        if let user = firebaseParkedDomainsAuthenticationService.firebaseUser {
            let parkedDomains = firebaseParkedDomainsService.getCachedDomains()
            if !parkedDomains.isEmpty {
                profiles.append(.webAccount(user))
            }
        }
        
        return profiles
    }
    
    func removeWebProfileIfNeeded() {
        for profile in self.profiles {
            if case .webAccount = profile {
                loadProfilesAndSetSelected()
            }
        }
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
