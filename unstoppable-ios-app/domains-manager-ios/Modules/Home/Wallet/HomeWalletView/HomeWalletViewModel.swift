//
//  HomeWalletViewModel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.01.2024.
//

import SwiftUI
import Combine

@MainActor
protocol HomeWalletViewCoordinator: AnyObject {
    func domainPurchased()
}

extension HomeWalletView {
    @MainActor
    final class HomeWalletViewModel: ObservableObject, HomeWalletViewCoordinator {
        
        @Published private(set) var selectedWallet: WalletEntity
        @Published private(set) var tokens: [BalanceTokenUIDescription] = []
        @Published private(set) var nftsCollections: [NFTsCollectionDescription] = []
        @Published private(set) var chainsNotMatch: [HomeWalletView.NotMatchedRecordsDescription] = []
        @Published var domainsData: HomeWalletView.DomainsSectionData = .init(domainsGroups: [], subdomains: [])
        @Published var nftsCollectionsExpandedIds: Set<String> = []
        @Published var selectedContentType: ContentType = .tokens
        @Published var selectedTokensSortingOption: TokensSortingOptions = .highestValue
        @Published var selectedCollectiblesSortingOption: CollectiblesSortingOptions = .mostCollected
        @Published var selectedDomainsSortingOption: DomainsSortingOptions = .alphabeticalAZ
        @Published var isNotMatchingTokensVisible: Bool = false
        
        private var cancellables: Set<AnyCancellable> = []
        private var router: HomeTabRouter
        private var lastVerifiedRecordsWalletAddress: String? = nil
        var isWCSupported: Bool { selectedWallet.udWallet.type != .mpc }
        
        init(selectedWallet: WalletEntity,
             router: HomeTabRouter) {
            self.selectedWallet = selectedWallet
            self.router = router
            router.homeWalletViewCoordinator = self
            
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
        
        func onAppear() {
            showGreetingsIfNeeded()
        }
        
        func walletActionPressed(_ action: WalletAction) {
            switch action {
            case .send:
                router.sendCryptoInitialData = .init(sourceWallet: selectedWallet)
            case .receive:
                router.showingWalletInfo = selectedWallet
            case .profile:
                switch selectedWallet.getCurrentWalletRepresentingDomainState() {
                case .udDomain(let domain), .ensDomain(let domain):
                    showProfile(of: domain)
                case .noRRDomain:
                    router.pullUp = .default(.showCreateYourProfilePullUp(buyCallback: { [weak self] in
                        self?.router.runPurchaseFlow()
                    }))
                }
            case .buy:
                router.pullUp = .default(.homeWalletBuySelectionPullUp(selectionCallback: { [weak self] buyOption in
                    self?.router.pullUp = nil
                    self?.didSelectBuyOption(buyOption)
                }))
            case .more:
                return
            }
        }
        
        func didSelectBuyOption(_ buyOption: HomeWalletView.BuyOptions) {
            switch buyOption {
            case .domains:
                router.runPurchaseFlow()
            case .crypto:
                router.runBuyCryptoFlowTo(wallet: selectedWallet)
            }
        }
        
        func didSelectDomain(_ domain: DomainDisplayInfo) {
            showProfile(of: domain)
        }
        
        func didSelectChangeRR() {
            if selectedWallet.isReverseResolutionChangeAllowed() {
                router.resolvingPrimaryDomainWallet = .init(wallet: selectedWallet, mode: .change)
            } else if let domain = selectedWallet.rrDomain {
                showProfile(of: domain)
            }
        }
        
        private func showProfile(of domain: DomainDisplayInfo) {
            Task {
                await router.showDomainProfile(domain, wallet: selectedWallet, preRequestedAction: nil, dismissCallback: nil)
            }
        }
        
        func walletSubActionPressed(_ subAction: WalletSubAction) {
            switch subAction {
            case .copyWalletAddress:
                switch selectedWallet.getAssetsType() {
                case .multiChain(let tokens):
                    router.pullUp = .custom(.copyMultichainAddressPullUp(tokens: tokens, selectionType: .copyOnly))
                case .singleChain(let token):
                    CopyWalletAddressPullUpHandler.copyToClipboard(token: token)
                }
            case .connectedApps:
                router.isConnectedAppsListPresented = true
            case .buyMPC:
                router.purchasingMPCWallet = true
            }
        }
        
        func domainNamePressed() {
            router.isSelectProfilePresented = true
        }
        
        func buyDomainPressed() {
            router.runPurchaseFlow()
        }
        
        func domainPurchased() {
            selectedContentType = .domains
        }
        
        var isProfileButtonEnabled: Bool {
            switch selectedWallet.getCurrentWalletRepresentingDomainState() {
            case .udDomain, .ensDomain:
                return true
            case .noRRDomain:
                return false
            }
        }
    }
}

fileprivate extension HomeWalletView.HomeWalletViewModel {
    func setSelectedWallet(_ wallet: WalletEntity) {
        selectedWallet = wallet
        tokens = wallet.balance.map { BalanceTokenUIDescription.extractFrom(walletBalance: $0) }.flatMap({ $0 })
        
        self.domainsData.setDomainsFrom(wallet: wallet)
        
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
        Task {
            await router.askToFinishSetupPurchasedProfileIfNeeded(domains: selectedWallet.domains)
        }
    }
    
    func sortTokens(_ sortOption: HomeWalletView.TokensSortingOptions) {
        switch sortOption {
        case .alphabetical:
            tokens = tokens.sorted(by: { lhs, rhs in
                lhs.symbol < rhs.symbol
            })
        case .highestValue:
            tokens = tokens.sorted(by: { lhs, rhs in
                lhs.balanceUsd > rhs.balanceUsd
            })
        case .marketValue:
            tokens = tokens.sorted(by: { lhs, rhs in
                (lhs.marketUsd ?? 0) > (rhs.marketUsd ?? 0)
            })
        }
    }
    
    func sortCollectibles(_ sortOption: HomeWalletView.CollectiblesSortingOptions) {
        switch sortOption {
        case .mostRecent:
            nftsCollections = nftsCollections.sorted(by: { lhs, rhs in
                if lhs.lastAcquiredDate == nil && rhs.lastAcquiredDate == nil {
                    return lhs.collectionName < rhs.collectionName /// Sort by name collections without sale date info
                } else if let lhsDate = lhs.lastAcquiredDate,
                          let rhsDate = rhs.lastAcquiredDate {
                    return lhsDate > rhsDate
                } else if lhs.lastAcquiredDate != nil {
                    return true
                } else {
                    return false
                }
            })
        case .mostCollected:
            nftsCollections = nftsCollections.sorted(by: { lhs, rhs in
                lhs.numberOfNFTs > rhs.numberOfNFTs
            })
        case .alphabetical:
            nftsCollections = nftsCollections.sorted(by: { lhs, rhs in
                lhs.collectionName < rhs.collectionName
            })
        }
    }
    
    func sortDomains(_ sortOption: HomeWalletView.DomainsSortingOptions) {
        domainsData.sortDomains(sortOption)
    }
    
    func runSelectRRDomainInSelectedWalletIfNeeded() {
        Task {
            guard selectedWallet.rrDomain == nil else { return }
            await Task.sleep(seconds: 0.5)
            
            if router.resolvingPrimaryDomainWallet == nil,
               !router.showingUpdatedToWalletGreetings,
               selectedWallet.isReverseResolutionChangeAllowed(),
               !router.isUpdatingPurchasedProfiles,
               router.walletViewNavPath.isEmpty {
                router.resolvingPrimaryDomainWallet = .init(wallet: selectedWallet, mode: .selectFirst)
            }
        }
    }
    
    func ensureRRDomainRecordsMatchOwnerWallet() {
        Task {
            let walletAddress = selectedWallet.address
            guard lastVerifiedRecordsWalletAddress != selectedWallet.address else { return }
            guard let rrDomain = selectedWallet.rrDomain else {
                lastVerifiedRecordsWalletAddress = selectedWallet.address
                chainsNotMatch = []
                return
            }
            
            do {
                let profile = try await appContext.domainProfilesService.fetchDomainProfileDisplayInfo(for: rrDomain.name)
                let records = profile.records
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
            } catch {
                chainsNotMatch = []
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
    
    func showGreetingsIfNeeded() {
        if UserDefaults.didUpdateToWalletVersion {
            UserDefaults.didUpdateToWalletVersion = false
            router.showingUpdatedToWalletGreetings = true
        }
    }
}
