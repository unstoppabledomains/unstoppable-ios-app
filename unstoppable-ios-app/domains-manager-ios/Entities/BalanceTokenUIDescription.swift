//
//  BalanceTokenUIDescription.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.03.2024.
//

import UIKit

struct BalanceTokenUIDescription: Hashable, Identifiable {
    var id: String { "\(chain)/\(symbol)" }
    
    let chain: String
    let symbol: String
    let name: String
    let balance: Double
    let balanceUsd: Double
    var marketUsd: Double?
    var marketPctChange24Hr: Double?
    var parentSymbol: String?
    var logoURL: URL?
    var parentLogoURL: URL?
    private(set) var isSkeleton: Bool = false
    
    static let iconSize: InitialsView.InitialsSize = .default
    static let iconStyle: InitialsView.Style = .gray
    
    init(walletBalance: WalletTokenPortfolio) {
        self.chain = walletBalance.symbol
        self.symbol = walletBalance.symbol
        self.name = walletBalance.name
        self.balance = walletBalance.balanceAmt.rounded(toDecimalPlaces: 2)
        self.balanceUsd = walletBalance.value.walletUsdAmt
        self.marketUsd = walletBalance.value.marketUsdAmt ?? 0
        self.marketPctChange24Hr = walletBalance.value.marketPctChange24Hr
    }
    
    init(chain: String,
         symbol: String,
         name: String,
         balance: Double,
         balanceUsd: Double,
         marketUsd: Double? = nil,
         marketPctChange24Hr: Double? = nil,
         icon: UIImage? = nil) {
        self.chain = chain
        self.symbol = symbol
        self.name = name
        self.balance = balance
        self.balanceUsd = balanceUsd
        self.marketUsd = marketUsd
        self.marketPctChange24Hr = marketPctChange24Hr
    }
    
    init(chain: String, walletToken: WalletTokenPortfolio.Token, parentSymbol: String, parentLogoURL: URL?) {
        self.chain = chain
        self.symbol = walletToken.symbol
        self.name = walletToken.name
        self.balance = walletToken.balanceAmt.rounded(toDecimalPlaces: 2)
        self.balanceUsd = walletToken.value?.walletUsdAmt ?? 0
        self.marketUsd = walletToken.value?.marketUsdAmt ?? 0
        self.marketPctChange24Hr = walletToken.value?.marketPctChange24Hr
        self.parentSymbol = parentSymbol
        self.logoURL = URL(string: walletToken.logoUrl ?? "")
    }
    
    static func extractFrom(walletBalance: WalletTokenPortfolio) -> [BalanceTokenUIDescription] {
        let tokenDescription = BalanceTokenUIDescription(walletBalance: walletBalance)
        let parentSymbol = walletBalance.symbol
        let parentLogoURL = URL(string: walletBalance.logoUrl ?? "")
        let chainSymbol = walletBalance.symbol
        let subTokenDescriptions = walletBalance.tokens?.map({ BalanceTokenUIDescription(chain: chainSymbol,
                                                                                         walletToken: $0,
                                                                                         parentSymbol: parentSymbol,
                                                                                         parentLogoURL: parentLogoURL) })
            .filter({ $0.balanceUsd >= 1 }) ?? []
        
        return [tokenDescription] + subTokenDescriptions
    }

}

// MARK: - Open methods
extension BalanceTokenUIDescription {
    var formattedBalanceWithSymbol: String {
        BalanceStringFormatter.tokenBalanceString(self)
    }
    
    var formattedBalanceUSD: String {
        BalanceStringFormatter.tokensBalanceUSDString(balanceUsd)
    }
}

// MARK: - Load icons
extension BalanceTokenUIDescription {
    func loadTokenIcon(iconUpdated: @escaping (UIImage?)->()) {
        BalanceTokenUIDescription.loadIconFor(ticker: symbol, logoURL: logoURL, iconUpdated: iconUpdated)
    }
    
    func loadParentIcon(iconUpdated: @escaping (UIImage?)->()) {
        if let parentSymbol {
            BalanceTokenUIDescription.loadIconFor(ticker: parentSymbol, logoURL: parentLogoURL, iconUpdated: iconUpdated)
        } else {
            iconUpdated(nil)
        }
    }
    
    static func loadIconFor(ticker: String, logoURL: URL?, iconUpdated: @escaping (UIImage?)->()) {
        if let logoURL,
           let cachedImage = appContext.imageLoadingService.cachedImage(for: .url(logoURL, maxSize: nil), downsampleDescription: .icon) {
            iconUpdated(cachedImage)
            return
        }
        
        let size = BalanceTokenUIDescription.iconSize
        let style = BalanceTokenUIDescription.iconStyle
        if let cachedImage = appContext.imageLoadingService.cachedImage(for: .currencyTicker(ticker,
                                                                                             size: size,
                                                                                             style: style),
                                                                        downsampleDescription: .icon),
           logoURL == nil {
            iconUpdated(cachedImage)
            return
        }
        Task { @MainActor in
            let initials = await appContext.imageLoadingService.loadImage(from: .initials(ticker,
                                                                                          size: size,
                                                                                          style: style),
                                                                          downsampleDescription: nil)
            iconUpdated(initials)
            
            if let logoURL,
               let icon = await appContext.imageLoadingService.loadImage(from: .url(logoURL,
                                                                                    maxSize: nil),
                                                                         downsampleDescription: .icon) {
                iconUpdated(icon)
            } else if let icon = await appContext.imageLoadingService.loadImage(from: .currencyTicker(ticker,
                                                                                                      size: size,
                                                                                                      style: style),
                                                                                downsampleDescription: .icon) {
                iconUpdated(icon)
            }
        }
    }
}

// MARK: - Skeleton
extension BalanceTokenUIDescription {
    static func createSkeletonEntity() -> BalanceTokenUIDescription {
        var token = BalanceTokenUIDescription(chain: "ETH", symbol: "000", name: "0000000000000000", balance: 10000, balanceUsd: 10000, marketUsd: 1)
        token.isSkeleton = true
        return token
    }
}

extension Array where Element == BalanceTokenUIDescription {
    
    func totalBalanceUSD() -> Double {
        self.reduce(0.0, { $0 + $1.balanceUsd })
    }
    
}
