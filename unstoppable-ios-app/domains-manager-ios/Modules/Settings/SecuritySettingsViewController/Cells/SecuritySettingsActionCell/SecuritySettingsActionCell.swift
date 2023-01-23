//
//  SecuritySettingsActionCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.05.2022.
//

import UIKit

final class SecuritySettingsActionCell: BaseListCollectionViewCell {

    @IBOutlet private weak var nameLabel: UILabel!
    
    func setWith(action: SecuritySettingsViewController.Action) {
        nameLabel.setAttributedTextWith(text: action.title,
                                        font: .currentFont(withSize: 16, weight: .medium),
                                        textColor: .foregroundAccent)
    }
    
}
