//
//  HomeWalletViewModel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.01.2024.
//

import SwiftUI
import Combine

extension HomeWalletView {
    @MainActor
    final class HomeWalletViewModel: ObservableObject {
        
        @Published private(set) var selectedWallet: WalletEntity
        @Published private(set) var tokens: [TokenDescription] = []
        @Published private(set) var nftsCollections: [NFTsCollectionDescription] = []
        @Published private(set) var domains: [DomainDisplayInfo] = []
        @Published private(set) var subdomains: [DomainDisplayInfo] = []
        @Published var nftsCollectionsExpandedIds: Set<String> = []
        @Published var selectedContentType: ContentType = .domains
        @Published var selectedTokensSortingOption: TokensSortingOptions = .highestValue
        @Published var selectedCollectiblesSortingOption: CollectiblesSortingOptions = .mostCollected
        @Published var selectedDomainsSortingOption: DomainsSortingOptions = .salePrice
        @Published var isSubdomainsVisible: Bool = false 
        private var subscribers: Set<AnyCancellable> = []
        private var router: HomeTabRouter
        
        init(selectedWallet: WalletEntity,
             router: HomeTabRouter) {
            self.selectedWallet = selectedWallet
            self.router = router
            
            setSelectedWallet(selectedWallet)
            
            $selectedTokensSortingOption.sink { [weak self] sortOption in
                self?.sortTokens(sortOption)
            }.store(in: &subscribers)
            $selectedCollectiblesSortingOption.sink { [weak self] sortOption in
                self?.sortCollectibles(sortOption)
            }.store(in: &subscribers)
            $selectedDomainsSortingOption.sink { [weak self] sortOption in
                self?.sortDomains(sortOption)
            }.store(in: &subscribers)
            appContext.walletsDataService.selectedWalletPublisher.receive(on: DispatchQueue.main).sink { [weak self] selectedWallet in
                if let selectedWallet {
                    self?.setSelectedWallet(selectedWallet)
                }
            }.store(in: &subscribers)
        }
        
        private func setSelectedWallet(_ wallet: WalletEntity) {
            selectedWallet = wallet
            tokens = wallet.balance.map { TokenDescription.extractFrom(walletBalance: $0) }.flatMap({ $0 })
            tokens.append(.createSkeletonEntity())
            domains = wallet.domains.filter({ !$0.isSubdomain })
            subdomains = wallet.domains.filter({ $0.isSubdomain })
            
            let collectionNameToNFTs: [String : [NFTDisplayInfo]] = .init(grouping: wallet.nfts, by: { $0.collection })
            var collections: [NFTsCollectionDescription] = []
            
            for (collectionName, nfts) in collectionNameToNFTs {                
                let collection = NFTsCollectionDescription(collectionName: collectionName, nfts: nfts)
                collections.append(collection)
            }
            
            self.nftsCollections = collections
            sortCollectibles(selectedCollectiblesSortingOption)
            sortDomains(selectedDomainsSortingOption)
            sortTokens(selectedTokensSortingOption)
            runSelectRRDomainInSelectedWalletIfNeeded()
        }
        
        private func sortTokens(_ sortOption: TokensSortingOptions) {
            switch sortOption {
            case .alphabetical:
                tokens = tokens.sorted(by: { lhs, rhs in
                    if lhs.isSkeleton {
                        return false
                    }
                    return lhs.symbol < rhs.symbol
                })
            case .highestValue:
                tokens = tokens.sorted(by: { lhs, rhs in
                    if lhs.isSkeleton {
                        return false
                    }
                    return lhs.balanceUsd > rhs.balanceUsd
                })
            case .marketCap:
                tokens = tokens.sorted(by: { lhs, rhs in
                    if lhs.isSkeleton {
                        return false
                    }
                    return lhs.balance > rhs.balance
                })
            }
        }
        
        private func sortCollectibles(_ sortOption: CollectiblesSortingOptions) {
            switch sortOption {
            case .mostCollected:
                nftsCollections = nftsCollections.sorted(by: { lhs, rhs in
                    lhs.nfts.count > rhs.nfts.count
                })
            case .alphabetical:
                nftsCollections = nftsCollections.sorted(by: { lhs, rhs in
                    lhs.collectionName < rhs.collectionName
                })
            }
        }
        
        private func sortDomains(_ sortOption: DomainsSortingOptions) {
            subdomains = subdomains.sorted(by: { lhs, rhs in
                lhs.name < rhs.name
            })
            switch sortOption {
            case .alphabetical:
                domains = domains.sorted(by: { lhs, rhs in
                    lhs.name < rhs.name
                })
            case .salePrice:
                domains = domains.shuffled()
            }
        }
        
        func walletActionPressed(_ action: WalletAction) {
            switch action {
            case .receive:
                return
            case .profile:
                return
            case .copy:
                CopyWalletAddressPullUpHandler.copyToClipboard(address: selectedWallet.address, ticker: "ETH")
            case .more:
                return
            }
        }
        
        func walletSubActionPressed(_ subAction: WalletSubAction) {
            switch subAction {
            case .connectedApps:
                router.isConnectedAppsListPresented = true
            }
        }
        
        func domainNamePressed() {
            router.isSelectWalletPresented = true
        }
        
        private func runSelectRRDomainInSelectedWalletIfNeeded() {
            Task {
                guard selectedWallet.rrDomain == nil else { return }
                try? await Task.sleep(seconds: 0.5)
                
                if router.resolvingPrimaryDomainWallet == nil,
                   selectedWallet.isReverseResolutionChangeAllowed() {
                    router.resolvingPrimaryDomainWallet = selectedWallet
                }
            }
        }
    }
}
