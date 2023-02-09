//
//  DomainsCollectionEmptyListCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.07.2022.
//

import UIKit

final class DomainsCollectionEmptyListCell: BaseListCollectionViewCell {

    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var headLabel: UILabel!
    @IBOutlet private weak var subheadLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        iconImageView.tintColor = .foregroundAccent
    }

}

// MARK: - Open methods
extension DomainsCollectionEmptyListCell {
    func setWith(item: DomainsCollectionEmptyStateView.EmptyListItemType) {
        accessibilityIdentifier = "Domains Collection Cell \(item.title)"
        self.iconImageView.image = item.icon
        headLabel.setAttributedTextWith(text: item.title,
                                        font: .currentFont(withSize: 20, weight: .bold),
                                        textColor: .foregroundDefault)
        subheadLabel.setAttributedTextWith(text: item.subtitle ?? "",
                                           font: .currentFont(withSize: 16, weight: .regular),
                                           textColor: .foregroundSecondary,
                                           lineHeight: 24)
        subheadLabel.isHidden = item.subtitle == nil
    }
}
