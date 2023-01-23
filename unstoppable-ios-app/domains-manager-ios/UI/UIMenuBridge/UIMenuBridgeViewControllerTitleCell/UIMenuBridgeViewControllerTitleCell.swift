//
//  UIMenuBridgeViewControllerTitleCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.08.2022.
//

import UIKit

final class UIMenuBridgeViewControllerTitleCell: UITableViewCell {

    @IBOutlet private weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel.textColor = .secondaryLabel
    }

    func setTitle(_ title: String) {
        titleLabel.text = title
    }
    
}
