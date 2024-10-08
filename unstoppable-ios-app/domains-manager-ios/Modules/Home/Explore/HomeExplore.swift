//
//  HomeExplore.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.02.2024.
//

import SwiftUI

// Namespace
enum HomeExplore { }

extension HomeExplore {
    enum SearchDomainsType: String, CaseIterable, UDSegmentedControlItem {
        case global, local
        
        var title: String {
            switch self {
            case .global:
                return String.Constants.global.localized()
            case .local:
                return String.Constants.yours.localized()
            }
        }
        
        var icon: Image? {
            switch self {
            case .global:
                return .globeBold
            case .local:
                return .walletExternalIcon
            }
        }
        
        var analyticButton: Analytics.Button { .exploreDomainsSearchType }
    }
    
    enum EmptyState {
        case noProfile
        case noFollowers
        case noFollowing
        
        var title: String {
            switch self {
            case .noProfile:
                if isActionAvailable {
                    String.Constants.exploreEmptyNoProfileTitle.localized()
                } else {
                    String.Constants.homeWalletDomainsEmptyTitle.localized()
                }
            case .noFollowers:
                String.Constants.exploreEmptyNoFollowersTitle.localized()
            case .noFollowing:
                String.Constants.exploreEmptyNoFollowingTitle.localized()
            }
        }
        
        var subtitle: String {
            switch self {
            case .noProfile:
                String.Constants.exploreEmptyNoProfileSubtitle.localized()
            case .noFollowers:
                String.Constants.exploreEmptyNoFollowersSubtitle.localized()
            case .noFollowing:
                String.Constants.exploreEmptyNoFollowingSubtitle.localized()
            }
        }
        
        var isActionAvailable: Bool {
            switch self {
            case .noProfile:
                appContext.udFeatureFlagsService.valueFor(flag: .isBuyDomainEnabled)
            case .noFollowers:
                true
            case .noFollowing:
                true
            }
        }
        
        var actionTitle: String {
            switch self {
            case .noProfile:
                String.Constants.findYourDomain.localized()
            case .noFollowers:
                String.Constants.exploreEmptyNoFollowersActionTitle.localized()
            case .noFollowing:
                String.Constants.exploreEmptyNoFollowingActionTitle.localized()
            }
        }
        
        var actionStyle: UDButtonStyle {
            switch self {
            case .noFollowers, .noFollowing:
                    .medium(.raisedTertiary)
            case .noProfile:
                    .medium(.raisedPrimary)
            }
        }
        
        var analyticButton: Analytics.Button {
            switch self {
            case .noProfile:
                    .exploreNoProfile
            case .noFollowers:
                    .exploreNoFollowers
            case .noFollowing:
                    .exploreNoFollowing
            }
        }
        
        static func forRelationshipType(_ relationshipType: DomainProfileFollowerRelationshipType) -> EmptyState {
            switch relationshipType {
            case .followers:
                    .noFollowers
            case .following:
                    .noFollowing
            }
        }
    }
    
    struct UserWalletNonEmptySearchResult: Identifiable {
        var id: String { wallet.address }
        
        let wallet: WalletDisplayInfo
        let domains: [DomainDisplayInfo]
        
        init?(wallet: WalletEntity, searchKey: String) {
            let domains: [DomainDisplayInfo]
            if searchKey.isEmpty {
                domains = wallet.domains
            } else {
                domains = wallet.domains.filter({ $0.name.contains(searchKey) })
            }
            
            guard !domains.isEmpty else { return nil }
            
            self.domains = domains
            self.wallet = wallet.displayInfo
        }
    }
}

// MARK: - Open methods
extension HomeExplore {
    struct RecentGlobalSearchProfilesStorage: RecentGlobalSearchProfilesStorageProtocol {
        
        typealias Object = SearchDomainProfile
        static let domainPFPStorageFileName = "explore.recent.global.search.data"

        static var instance = RecentGlobalSearchProfilesStorage()
        private let storage = SpecificStorage<[Object]>(fileName: RecentGlobalSearchProfilesStorage.domainPFPStorageFileName)
        private let maxNumberOfRecentProfiles = 3
        
        private init() {}

        func getRecentProfiles() -> [Object] {
            storage.retrieve() ?? []
        }
        
        func addProfileToRecent(_ profile: Object) {
            let targetProfileIndex = 0
            var profilesList = getRecentProfiles()
            if let index = profilesList.firstIndex(where: { $0.name == profile.name }) {
                if index == targetProfileIndex {
                    return
                }
                profilesList.swapAt(index, targetProfileIndex)
            } else {
                profilesList.insert(profile, at: targetProfileIndex)
            }
            
            profilesList = Array(profilesList.prefix(maxNumberOfRecentProfiles))
            
            set(newProfilesList: profilesList)
        }
        
        private func set(newProfilesList: [Object]) {
            storage.store(newProfilesList)
        }
        
        func clearRecentProfiles() {
            storage.remove()
        }
    }
}

// MARK: - Open methods
extension HomeExplore {
    struct DomainProfileSuggestionSectionsBuilder {
        
        let sections: [Section]
        
        init(profiles: [DomainProfileSuggestion]) {
            let numOfProfilesInSection = 3
            let maxNumOfSections = 3
            let maxNumOfProfiles = numOfProfilesInSection * maxNumOfSections
            
            var profilesToTake = Array(profiles.prefix(maxNumOfProfiles))
            var sections: [Section] = []
            
            let numOfSections = Double(profilesToTake.count) / Double(numOfProfilesInSection)
            let numOfSectionsRounded = Int(ceil(numOfSections))
            for _ in 0..<numOfSectionsRounded {
                let sectionProfiles = Array(profilesToTake.prefix(numOfProfilesInSection))
                let section = Section(profiles: sectionProfiles)
                sections.append(section)
                profilesToTake = Array(profilesToTake.dropFirst(numOfProfilesInSection))
            }
            
            self.sections = sections
        }
        
        func getProfilesMatrix() -> [[DomainProfileSuggestion]] {
            sections.map { $0.profiles }
        }
        
        struct Section {
            let profiles: [DomainProfileSuggestion]
        }
        
    }
}
