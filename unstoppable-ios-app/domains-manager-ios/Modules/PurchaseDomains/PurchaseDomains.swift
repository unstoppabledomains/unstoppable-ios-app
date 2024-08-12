//
//  PurchaseDomains.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.08.2024.
//

import SwiftUI

enum PurchaseDomains { } // Namespace

extension PurchaseDomains {
    enum FlowAction {
        case didSelectDomains(_ domains: [DomainToPurchase])
        case didFillProfileForDomain(_ domain: DomainToPurchase, profileChanges: DomainProfilePendingChanges)
        case didRemoveAllDomainsFromTheCart
        case didPurchaseDomains
        case goToDomains
    }
}

extension PurchaseDomains {
    struct CheckoutData: Hashable {
        let domains: [DomainToPurchase]
        let profileChanges: DomainProfilePendingChanges?
        let selectedWallet: WalletEntity
        let wallets: [WalletEntity]
    }
    
    enum EmptyStateMode {
        case start
        case noResults
        case error
        
        var title: String {
            switch self {
            case .start:
                return String.Constants.startTyping.localized()
            case .noResults:
                return String.Constants.noAvailableDomains.localized()
            case .error:
                return String.Constants.somethingWentWrong.localized()
            }
        }
        
        var subtitle: String? {
            switch self {
            case .start:
                return nil
            case .noResults:
                return String.Constants.tryEnterDifferentName.localized()
            case .error:
                return String.Constants.pleaseCheckInternetConnection.localized()
            }
        }
        
        var icon: Image {
            switch self {
            case .start:
                return .searchIcon
            case .noResults, .error:
                return .grimaseIcon
            }
        }
    }
}

extension PurchaseDomains {
    struct LocalCart {
        
        private(set) var domains: [DomainToPurchase] = []
        var isShowingCart = false

        var totalPrice: Int { domains.reduce(0, { $0 + $1.price })}
        
        func isDomainInCart(_ domain: DomainToPurchase) -> Bool {
            domains.firstIndex(where: { $0.name == domain.name }) != nil
        }
        
        func canAddDomainToCart(_ domain: DomainToPurchase) -> Bool {
            let totalPriceWithNewDomain = totalPrice + domain.price
            return totalPriceWithNewDomain < Constants.maxPurchaseDomainsSum
        }
        
        mutating func addDomain(_ domain: DomainToPurchase) {
            guard !isDomainInCart(domain) else { return }
            
            domains.append(domain)
        }
        
        mutating func removeDomain(_ domain: DomainToPurchase) {
            if let i = domains.firstIndex(where: { $0.name == domain.name }) {
                domains.remove(at: i)
            }
        }
        
        mutating func clearCart() {
            domains.removeAll()
        }
    }
}

extension PurchaseDomains {
    struct SearchResultHolder {
        private(set) var availableDomains: [DomainToPurchase] = []
        private(set) var takenDomains: [DomainToPurchase] = []
        private(set) var recentSearches: [String] = []
        private let recentSearchesStorage: RecentDomainsToPurchaseSearchStorageProtocol = RecentDomainsToPurchaseSearchStorage.instance

        var isShowingTakenDomains = false
        
        var allDomains: [DomainToPurchase] {
            availableDomains + takenDomains
        }
        var hasTakenDomains: Bool { !takenDomains.isEmpty }
        
        var isEmpty: Bool {
            availableDomains.isEmpty && takenDomains.isEmpty
        }
        
        init() {
            loadRecentSearches()
        }
        
        mutating func clear() {
            availableDomains.removeAll()
            takenDomains.removeAll()
        }
        
        mutating func setDomains(_ domains: [DomainToPurchase],
                                 searchText: String) {
            let sortedDomains = sortSearchResult(domains, searchText: searchText)
            clear()
            for domain in sortedDomains {
                if domain.isTaken {
                    takenDomains.append(domain)
                } else {
                    availableDomains.append(domain)
                }
            }
            addRecentSearch(string: searchText)
        }
        
        private func sortSearchResult(_ searchResult: [DomainToPurchase], searchText: String) -> [DomainToPurchase] {
            var searchResult = searchResult
            /// Move exactly matched domain to the top of the list
            if let i = searchResult.firstIndex(where: { $0.name == searchText }),
               i != 0 {
                let matchingDomain = searchResult[i]
                searchResult.remove(at: i)
                searchResult.insert(matchingDomain, at: 0)
            }
            return searchResult
        }
        mutating func removeRecentSearch(string: String) {
            makeChangesToRecentProfilesStorage { storage in
                storage.removeDomainToPurchaseSearchToRecents(string)
            }
        }
        
        private mutating func addRecentSearch(string: String) {
            makeChangesToRecentProfilesStorage { storage in
                storage.addDomainToPurchaseSearchToRecents(string)
            }
        }

        private mutating func loadRecentSearches() {
            recentSearches = recentSearchesStorage.getRecentDomainsToPurchaseSearches()
        }
        
        private mutating func makeChangesToRecentProfilesStorage(_ block: (RecentDomainsToPurchaseSearchStorageProtocol)->()) {
            block(recentSearchesStorage)
            loadRecentSearches()
        }
    }
}

extension PurchaseDomains {
    struct SearchFiltersHolder {
        private(set) var tlds: Set<String> = []
        var isFiltersVisible = false
        
        mutating func setTLDs(_ tlds: Set<String>) {
            self.tlds = tlds
        }
    }
}

// MARK: - Open methods
extension PurchaseDomains {
    struct RecentDomainsToPurchaseSearchStorage: RecentDomainsToPurchaseSearchStorageProtocol {
        
        typealias Object = String
        static private let domainPFPStorageFileName = "purchase.domains.recent.search.data"
        
        static var instance = RecentDomainsToPurchaseSearchStorage()
        private let storage = SpecificStorage<[Object]>(fileName: RecentDomainsToPurchaseSearchStorage.domainPFPStorageFileName)
        private let maxNumberOfRecentSearches = 10
        
        private init() {}
        
        func getRecentDomainsToPurchaseSearches() -> [Object] {
            storage.retrieve() ?? []
        }
        
        func addDomainToPurchaseSearchToRecents(_ search: Object) {
            let targetProfileIndex = 0
            var profilesList = getRecentDomainsToPurchaseSearches()
            if let index = profilesList.firstIndex(where: { $0 == search }) {
                if index == targetProfileIndex {
                    return
                }
                profilesList.swapAt(index, targetProfileIndex)
            } else {
                profilesList.insert(search, at: targetProfileIndex)
                profilesList = Array(profilesList.prefix(maxNumberOfRecentSearches))
            }
            
            set(newProfilesList: profilesList)
        }
        
        func removeDomainToPurchaseSearchToRecents(_ search: Object) {
            var profilesList = getRecentDomainsToPurchaseSearches()
            if let index = profilesList.firstIndex(where: { $0 == search }) {
                profilesList.remove(at: index)
                set(newProfilesList: profilesList)
            }
        }
        
        private func set(newProfilesList: [Object]) {
            storage.store(newProfilesList)
        }
        
        func clearRecentDomainsToPurchaseSearches() {
            storage.remove()
        }
    }
}
