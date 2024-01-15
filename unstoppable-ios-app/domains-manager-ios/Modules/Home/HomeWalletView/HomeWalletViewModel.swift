//
//  HomeWalletViewModel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.01.2024.
//

import SwiftUI

extension HomeWalletView {
    @MainActor
    final class HomeWalletViewModel: ObservableObject {
        
        @Published private(set) var selectedWallet: WalletWithInfo = WalletWithInfo.mock.first!
        @Published private(set) var tokens: [TokenDescription] = TokenDescription.mock()
        @Published private(set) var domains: [DomainDisplayInfo] = createMockDomains()
        @Published private(set) var nftsCollections: [NFTsCollectionDescription] = NFTsCollectionDescription.mock()
        @Published var nftsCollectionsExpandedIds: Set<String> = []
        @Published var selectedContentType: ContentType = .collectibles
        
        var totalBalance: Int { 20000 }
        
        func walletActionPressed(_ action: WalletAction) {
            
        }
        
        func domainNamePressed() {
            
        }
        
        func loadIconIfNeededFor(token: TokenDescription) {
            guard token.icon == nil else { return }
            
            token.loadIconIfNeeded { [weak self] image in
                DispatchQueue.main.async {
                    if let i = self?.tokens.firstIndex(where: { $0.id == token.id }) {
                        self?.tokens[i].icon = image
                    }
                }
            }
        }
    }
}

extension HomeWalletView {
    enum ContentType: String, CaseIterable {
        case tokens, collectibles, domains
        
        var title: String {
            switch self {
            case .tokens:
                return String.Constants.tokens.localized()
            case .collectibles:
                return String.Constants.collectibles.localized()
            case .domains:
                return String.Constants.domains.localized()
            }
        }
    }
    
    enum WalletAction: String, CaseIterable {
        case receive, profile, copy, more
        
        var title: String {
            switch self {
            case .receive:
                return String.Constants.receive.localized()
            case .profile:
                return String.Constants.profile.localized()
            case .copy:
                return String.Constants.copy.localized()
            case .more:
                return String.Constants.more.localized()
            }
        }
        var icon: Image {
            switch self {
            case .receive:
                return .arrowBottom
            case .profile:
                return .personIcon
            case .copy:
                return .squareBehindSquareIcon
            case .more:
                return .dotsIcon
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
