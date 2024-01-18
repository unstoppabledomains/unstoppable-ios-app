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
        @Published private(set) var tokens: [TokenDescription] = TokenDescription.mock()
        @Published private(set) var domains: [DomainDisplayInfo] = createMockDomains()
        @Published private(set) var nftsCollections: [NFTsCollectionDescription] = NFTsCollectionDescription.mock()
        @Published var nftsCollectionsExpandedIds: Set<String> = []
        @Published var selectedContentType: ContentType = .tokens
        @Published var selectedTokensSortingOption: TokensSortingOptions = .highestValue
        @Published var selectedCollectiblesSortingOption: CollectiblesSortingOptions = .mostCollected
        @Published var selectedDomainsSortingOption: DomainsSortingOptions = .salePrice
        @Published var isSelectWalletPresented = false
        private var subscribers: Set<AnyCancellable> = []
        
        init(selectedWallet: WalletEntity) {
            self.selectedWallet = selectedWallet
            
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
            tokens = wallet.balance.map { TokenDescription(walletBalance: $0) }
            tokens.append(.createSkeletonEntity())
            domains = wallet.domains
            
            let collectionNameToNFTs: [String? : [NFTDisplayInfo]] = .init(grouping: wallet.nfts, by: { $0.collection })
            var collections: [NFTsCollectionDescription] = []
            
            for (collectionName, nfts) in collectionNameToNFTs {
                guard let collectionName else { continue }
                
                let collection = NFTsCollectionDescription(collectionName: collectionName, nfts: nfts)
                collections.append(collection)
            }
            
            self.nftsCollections = collections
            sortCollectibles(selectedCollectiblesSortingOption)
            sortDomains(selectedDomainsSortingOption)
            sortTokens(selectedTokensSortingOption)
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
                    return lhs.balance > rhs.balance
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
            print("SubAction pressed \(subAction.title)")
            
        }
        
        func domainNamePressed() {
            isSelectWalletPresented = true
        }
    }
}

func createMockDomains() -> [DomainDisplayInfo] {
    var domains = [DomainDisplayInfo]()
    
    for i in 0..<5 {
        let domain = DomainDisplayInfo(name: "oleg_\(i).x",
                                       ownerWallet: "",
                                       isSetForRR: false)
        domains.append(domain)
    }
    
    return domains
}
