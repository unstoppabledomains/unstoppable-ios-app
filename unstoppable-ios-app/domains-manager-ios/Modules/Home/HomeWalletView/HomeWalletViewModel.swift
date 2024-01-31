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
        @Published private(set) var chainsNotMatch: [HomeWalletView.NotMatchedRecordsDescription] = []
        @Published var nftsCollectionsExpandedIds: Set<String> = []
        @Published var selectedContentType: ContentType = .tokens
        @Published var selectedTokensSortingOption: TokensSortingOptions = .highestValue
        @Published var selectedCollectiblesSortingOption: CollectiblesSortingOptions = .mostCollected
        @Published var selectedDomainsSortingOption: DomainsSortingOptions = .salePrice
        @Published var isSubdomainsVisible: Bool = false
        @Published var isNotMatchingTokensVisible: Bool = false
        
        private var cancellables: Set<AnyCancellable> = []
        private var router: HomeTabRouter
        private var lastVerifiedRecordsWalletAddress: String? = nil
        
        init(selectedWallet: WalletEntity,
             router: HomeTabRouter) {
            self.selectedWallet = selectedWallet
            self.router = router
            
            setSelectedWallet(selectedWallet)
            
            $selectedTokensSortingOption.sink { [weak self] sortOption in
                withAnimation {
                    self?.sortTokens(sortOption)
                }
            }.store(in: &cancellables)
            $selectedCollectiblesSortingOption.sink { [weak self] sortOption in
                withAnimation {
                    self?.sortCollectibles(sortOption)
                }
            }.store(in: &cancellables)
            $selectedDomainsSortingOption.sink { [weak self] sortOption in
                withAnimation {
                    self?.sortDomains(sortOption)
                }
            }.store(in: &cancellables)
            appContext.walletsDataService.selectedWalletPublisher.receive(on: DispatchQueue.main).sink { [weak self] selectedWallet in
                if let selectedWallet {
                    self?.setSelectedWallet(selectedWallet)
                }
            }.store(in: &cancellables)
        }
        
        func walletActionPressed(_ action: WalletAction) {
            switch action {
            case .receive:
                return
            case .profile:
                guard let rrDomain = selectedWallet.rrDomain else { return }
                
                router.presentedDomain = .init(domain: rrDomain, wallet: selectedWallet)
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
    }
}

fileprivate extension HomeWalletView.HomeWalletViewModel {
    func setSelectedWallet(_ wallet: WalletEntity) {
        selectedWallet = wallet
        tokens = wallet.balance.map { HomeWalletView.TokenDescription.extractFrom(walletBalance: $0) }.flatMap({ $0 })
        domains = wallet.domains.filter({ !$0.isSubdomain })
        subdomains = wallet.domains.filter({ $0.isSubdomain })
        
        let collectionNameToNFTs: [String : [NFTDisplayInfo]] = .init(grouping: wallet.nfts, by: { $0.collection })
        var collections: [HomeWalletView.NFTsCollectionDescription] = []
        
        for (collectionName, nfts) in collectionNameToNFTs {
            let collection = HomeWalletView.NFTsCollectionDescription(collectionName: collectionName, nfts: nfts)
            collections.append(collection)
        }
        
        self.nftsCollections = collections
        sortCollectibles(selectedCollectiblesSortingOption)
        sortDomains(selectedDomainsSortingOption)
        sortTokens(selectedTokensSortingOption)
        runSelectRRDomainInSelectedWalletIfNeeded()
        ensureRRDomainRecordsMatchOwnerWallet()
    }
    
    func sortTokens(_ sortOption: HomeWalletView.TokensSortingOptions) {
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
    
    func sortCollectibles(_ sortOption: HomeWalletView.CollectiblesSortingOptions) {
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
    
    func sortDomains(_ sortOption: HomeWalletView.DomainsSortingOptions) {
        subdomains = subdomains.sorted(by: { lhs, rhs in
            lhs.name < rhs.name
        })
        switch sortOption {
        case .alphabetical:
            domains = domains.sorted(by: { lhs, rhs in
                lhs.name < rhs.name
            })
        case .salePrice:
            domains = domains.sorted(by: { lhs, rhs in
                lhs.name > rhs.name
            })
        }
    }
    
    func runSelectRRDomainInSelectedWalletIfNeeded() {
        Task {
            guard selectedWallet.rrDomain == nil else { return }
            try? await Task.sleep(seconds: 0.5)
            
            if router.resolvingPrimaryDomainWallet == nil,
               selectedWallet.isReverseResolutionChangeAllowed() {
                router.resolvingPrimaryDomainWallet = selectedWallet
            }
        }
    }
    
    func ensureRRDomainRecordsMatchOwnerWallet() {
        Task {
            let walletAddress = selectedWallet.address
            guard lastVerifiedRecordsWalletAddress != selectedWallet.address,
                  let rrDomain = selectedWallet.rrDomain else { return }
            
            do {
                let profile = try await NetworkService().fetchPublicProfile(for: rrDomain.name,
                                                                            fields: [.records])
                let records = profile.records ?? [:]
                let coinRecords = await appContext.coinRecordsService.getCurrencies()
                let recordsData = DomainRecordsData(from: records,
                                                    coinRecords: coinRecords,
                                                    resolver: nil)
                let cryptoRecords = recordsData.records
                let chainsToVerify: [BlockchainType] = [.Ethereum, .Matic]
                chainsNotMatch = chainsToVerify.compactMap { chain in
                    let numberOfRecordsNotSetToChain = numberOfRecords(cryptoRecords,
                                                                       withChain: chain,
                                                                       notSetToWallet: walletAddress)
                    if numberOfRecordsNotSetToChain > 0 {
                        return HomeWalletView.NotMatchedRecordsDescription(chain: chain,
                                                                           numberOfRecordsNotSetToChain: numberOfRecordsNotSetToChain,
                                                                           ownerWallet: walletAddress)
                    } else {
                        return nil
                    }
                }
                
                lastVerifiedRecordsWalletAddress = selectedWallet.address
            }
        }
    }
    
    func numberOfRecords(_ records: [CryptoRecord],
                         withChain chain: BlockchainType,
                         notSetToWallet wallet: String) -> Int {
        let tickerRecords = records.filter { $0.coin.ticker == chain.rawValue }
        if tickerRecords.isEmpty {
            return 1
        }
        
        return tickerRecords.filter({ $0.address != wallet }).count
    }
}
