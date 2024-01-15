//
//  HomeWalletViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.01.2024.
//

import SwiftUI

extension HomeWalletView {
    @MainActor
    final class HomeWalletViewPresenter: ObservableObject {
        
        @Published private(set) var tokens: [TokenDescription] = TokenDescription.mock()
        @Published private(set) var domains: [DomainDisplayInfo] = createMockDomains()
        @Published var selectedContentType: ContentType = .tokens
        
        
    }
}

extension HomeWalletView {
    enum ContentType: String, CaseIterable {
        case tokens, collectibles, domains
        
        var title: String { rawValue }
    }
    
    enum WalletAction: String, CaseIterable {
        case receive, profile, copy, more
        
        var title: String { rawValue }
        var icon: Image { .systemGlobe }
    }
}

struct TokenDescription: Hashable, Identifiable {
    var id: String { ticker }
    
    let ticker: String
    let fullName: String
    let value: Double
    let fiatValue: Double
    
    
    static func mock() -> [TokenDescription] {
        var tickers = ["ETH", "MATIC", "USDC", "1INCH",
                       "SOL", "USDT", "DOGE", "DAI"]
        tickers += ["AAVE", "ADA", "AKT", "APT", "ARK", "CETH"]
        var tokens = [TokenDescription]()
        for ticker in tickers {
            let value = Double(arc4random_uniform(10000)) + 20
            let token = TokenDescription(ticker: ticker,
                                         fullName: ticker,
                                         value: value,
                                         fiatValue: value)
            tokens.append(token)
            
        }
        
        return tokens
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
