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
        @Published var selectedContentType: ContentType = .tokens
        
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
    
    struct TokenDescription: Hashable, Identifiable {
        var id: String { symbol }
        
        let symbol: String
        let name: String
        let balance: Double
        var marketUsd: Double?
        var icon: UIImage? = nil
        var fiatValue: Double? {
            if let marketUsd {
                return marketUsd * balance
            }
            return nil
        }
        
        static let iconSize: InitialsView.InitialsSize = .default
        static let iconStyle: InitialsView.Style = .gray
        
        init(walletBalance: ProfileWalletBalance) {
            self.symbol = walletBalance.symbol
            self.name = walletBalance.name
            self.balance = walletBalance.balance
            self.marketUsd = walletBalance.value?.marketUsd
            self.icon = appContext.imageLoadingService.cachedImage(for: .currencyTicker(symbol,
                                                                                        size: TokenDescription.iconSize,
                                                                                        style: TokenDescription.iconStyle))
        }
        
        init(symbol: String, name: String, balance: Double, marketUsd: Double? = nil, icon: UIImage? = nil) {
            self.symbol = symbol
            self.name = name
            self.balance = balance
            self.marketUsd = marketUsd
            self.icon = icon
        }
        
        func loadIconIfNeeded(iconUpdated: @escaping (UIImage?)->()) {
            guard icon == nil else { return }
            
            Task {
                let size = TokenDescription.iconSize
                let style = TokenDescription.iconStyle
                let ticker = symbol
                let initials = await appContext.imageLoadingService.loadImage(from: .initials(ticker,
                                                                                              size: size,
                                                                                              style: style),
                                                                              downsampleDescription: nil)
                iconUpdated(initials)
                
                
                if let icon = await appContext.imageLoadingService.loadImage(from: .currencyTicker(ticker,
                                                                                                   size: size,
                                                                                                   style: style),
                                                                             downsampleDescription: .icon) {
                    iconUpdated(icon)
                }
            }
        }
        
        static func mock() -> [TokenDescription] {
            let tickers = ["ETH", "MATIC"]
//            var tickers = ["ETH", "MATIC", "USDC", "1INCH",
//                           "SOL", "USDT", "DOGE", "DAI"]
//            tickers += ["AAVE", "ADA", "AKT", "APT", "ARK", "CETH"]
            var tokens = [TokenDescription]()
            for ticker in tickers {
                let value = Double(arc4random_uniform(10000))
                let token = TokenDescription(symbol: ticker,
                                             name: ticker,
                                             balance: value,
                                             marketUsd: value)
                tokens.append(token)
                
            }
            
            return tokens
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
