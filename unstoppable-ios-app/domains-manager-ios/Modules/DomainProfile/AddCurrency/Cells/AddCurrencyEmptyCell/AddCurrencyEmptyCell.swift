//
//  AddCurrencyEmptyCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.05.2022.
//

import UIKit

final class AddCurrencyEmptyCell: UICollectionViewCell {

    @IBOutlet private weak var noResultsLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        noResultsLabel.setAttributedTextWith(text: String.Constants.noResults.localized(),
                                             font: .currentFont(withSize: 22, weight: .bold),
                                             textColor: .foregroundSecondary)
    }

}
