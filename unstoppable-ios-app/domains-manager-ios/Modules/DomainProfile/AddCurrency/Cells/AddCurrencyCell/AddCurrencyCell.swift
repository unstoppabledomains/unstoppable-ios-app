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
    @IBOutlet private weak var legacyLabel: UILabel!
    @IBOutlet private weak var horizontalContentStackView: UIStackView!
    
    private var currencyImageLoader: CurrencyImageLoader!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        currencyImageLoader = CurrencyImageLoader(currencyImageView: currencyImageView,
                                                  initialsSize: .default)
        legacyLabel.setAttributedTextWith(text: String.Constants.legacy.localized(),
                                          font: .currentFont(withSize: 16, weight: .regular),
                                          textColor: .foregroundSecondary)
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
        legacyLabel.isHidden = !currency.isDeprecated
        horizontalContentStackView.spacing = currency.isDeprecated ? 8 : 0
    }
}

// MARK: - Private methods
private extension AddCurrencyCell {
    func nameFor(currency: CoinRecord) -> String {
        return currency.fullName ?? currency.ticker
    }
}
