//
//  AddCurrencyCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.05.2022.
//

import UIKit

final class AddCurrencyCell: BaseListCollectionViewCell {

    @IBOutlet private weak var currencyImageView: UIImageView!
    @IBOutlet private weak var currencyNameLabel: UILabel!
    @IBOutlet private weak var currencyTickerLabel: UILabel!
    private var currencyImageLoader: CurrencyImageLoader!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        currencyImageLoader = CurrencyImageLoader(currencyImageView: currencyImageView,
                                                  initialsSize: .default)
    }
    
}

// MARK: - Open methods
extension AddCurrencyCell {
    func setWithCurrency(_ currency: CoinRecord) {
        currencyImageLoader.loadImage(for: currency)
        
        currencyNameLabel.setAttributedTextWith(text: nameFor(currency: currency),
                                                font: .currentFont(withSize: 16, weight: .medium),
                                                textColor: .foregroundDefault)
        currencyTickerLabel.setAttributedTextWith(text: currency.ticker,
                                                  font: .currentFont(withSize: 14, weight: .regular),
                                                  textColor: .foregroundSecondary)
    }
}

// MARK: - Private methods
private extension AddCurrencyCell {
    func nameFor(currency: CoinRecord) -> String {
        return currency.fullName ?? currency.ticker
    }
}
