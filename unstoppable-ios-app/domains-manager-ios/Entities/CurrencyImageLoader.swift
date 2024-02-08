//
//  CurrencyImageLoader.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.07.2022.
//

import UIKit

@MainActor
final class CurrencyImageLoader {
    
    private(set) weak var currencyImageView: UIImageView?
    private(set) var ticker: String?
    private(set) var initialsSize: InitialsView.InitialsSize
    private(set) var initialsStyle: InitialsView.Style
    private let downsampleDescription: DownsampleDescription = .icon

    nonisolated
    init(currencyImageView: UIImageView,
         initialsSize: InitialsView.InitialsSize,
         initialsStyle: InitialsView.Style = .gray) {
        self.currencyImageView = currencyImageView
        self.initialsSize = initialsSize
        self.initialsStyle = initialsStyle
    }
    
    func loadImage(for currency: CoinRecord) {
        self.ticker = currency.ticker
        currencyImageView?.backgroundColor = nil
        
        if let cachedImage = appContext.imageLoadingService.cachedImage(for: .currency(currency,
                                                                                       size: initialsSize,
                                                                                       style: initialsStyle),
                                                                        downsampleDescription: downsampleDescription) {
            set(currencyImage: cachedImage)
        } else {
            if let cachedImage = appContext.imageLoadingService.cachedImage(for: .initials(currency.ticker,
                                                                                       size: initialsSize,
                                                                                           style: initialsStyle),
                                                                            downsampleDescription: downsampleDescription) {
                set(currencyImage: cachedImage)
                Task {
                    await loadIcon(for: currency)
                }
            } else {
                set(currencyImage: nil)
                Task {
                    await loadInitials(for: currency)
                    await loadIcon(for: currency)
                }
            }
        }
    }
    
    func loadInitials(for currency: CoinRecord) async {
        let ticker = currency.ticker
        let initialsImage = await appContext.imageLoadingService.loadImage(from: .initials(currency.ticker,
                                                                                       size: initialsSize,
                                                                                       style: initialsStyle), downsampleDescription: downsampleDescription)
        if ticker == self.ticker {
            set(currencyImage: initialsImage)
        }
    }
    
    func loadIcon(for currency: CoinRecord) async {
        let ticker = currency.ticker
        let image = await appContext.imageLoadingService.loadImage(from: .currency(currency,
                                                                                   size: initialsSize,
                                                                                   style: initialsStyle), downsampleDescription: downsampleDescription)
        if ticker == self.ticker {
            set(currencyImage: image)
        }
    }
    
    func set(currencyImage: UIImage?) {
        currencyImageView?.image = currencyImage
        currencyImageView?.backgroundColor = currencyImage == nil ? initialsStyle.backgroundColor : nil
    }
}
