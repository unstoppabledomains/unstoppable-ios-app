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
        
        @Published private(set) var selectedWallet: WalletWithInfo = WalletWithInfo.mock.first!
        @Published private(set) var tokens: [TokenDescription] = TokenDescription.mock()
        @Published private(set) var domains: [DomainDisplayInfo] = createMockDomains()
        @Published private(set) var nftsCollections: [NFTsCollectionDescription] = NFTsCollectionDescription.mock()
        @Published var nftsCollectionsExpandedIds: Set<String> = []
        @Published var selectedContentType: ContentType = .tokens
        @Published var selectedTokensSortingOption: TokensSortingOptions = .highestValue
        @Published var selectedCollectiblesSortingOption: CollectiblesSortingOptions = .mostCollected
        @Published var selectedDomainsSortingOption: DomainsSortingOptions = .salePrice
        private var subscribers: Set<AnyCancellable> = []

        var totalBalance: Int { 20000 }
        
        init() {
            selectedWallet.displayInfo?.reverseResolutionDomain = .init(name: "oleg.x", ownerWallet: "", isSetForRR: true)
            tokens.append(.createSkeletonEntity())
            
            $selectedTokensSortingOption.sink { [weak self] sortOption in
                self?.sortTokens(sortOption)
            }.store(in: &subscribers)
            $selectedCollectiblesSortingOption.sink { [weak self] sortOption in
                self?.sortCollectibles(sortOption)
            }.store(in: &subscribers)
            $selectedDomainsSortingOption.sink { [weak self] sortOption in
                self?.sortDomains(sortOption)
            }.store(in: &subscribers)
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
            print("Action pressed \(action.title)")
        }
        
        func walletSubActionPressed(_ subAction: WalletSubAction) {
            print("SubAction pressed \(subAction.title)")
            
        }
        
        func domainNamePressed() {
            
        }
        
        func loadIconIfNeededFor(token: TokenDescription) {
            guard !token.isSkeleton,
                  token.icon == nil else { return }
            
            token.loadIconIfNeeded { [weak self] image in
                DispatchQueue.main.async {
                    if let i = self?.tokens.firstIndex(where: { $0.id == token.id }) {
                        self?.tokens[i].icon = image
                    }
                }
            }
        }
        
        func loadIconIfNeededForNFT(_ nft: NFTDisplayInfo, in collection: NFTsCollectionDescription) {
            guard nft.icon == nil,
                nft.imageUrl != nil else { return }
            
            Task { @MainActor in
                if let icon = await nft.loadIcon(),
                   let i = nftsCollections.firstIndex(where: { $0.id == collection.id }),
                   let j = nftsCollections[i].nfts.firstIndex(where: { $0.id == nft.id }) {
                    nftsCollections[i].nfts[j].icon = icon
                }
            }
        }
    }
}

func createMockDomains() -> [DomainDisplayInfo] {
    var domains = [DomainDisplayInfo]()
    
    for i in 0..<100 {
        let domain = DomainDisplayInfo(name: "oleg_\(i).x",
                                       ownerWallet: "",
                                       isSetForRR: false)
        domains.append(domain)
    }
    
    return domains
}
