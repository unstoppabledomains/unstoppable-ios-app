//
//  DomainsCollectionSuggestionCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.11.2023.
//

import UIKit

final class DomainsCollectionSuggestionCell: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    private var closeButtonPressedCallback: EmptyCallback?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
}

// MARK: - Open methods
extension DomainsCollectionSuggestionCell {
    func setWith(configuration: DomainsCollectionCarouselItemViewController.SuggestionConfiguration) {
        closeButtonPressedCallback = configuration.closeCallback
        titleLabel.setAttributedTextWith(text: "Get notifications from dApps",
                                         font: .currentFont(withSize: 16, weight: .regular),
                                         textColor: .foregroundDefault)
        subtitleLabel.setAttributedTextWith(text: "Receive the latest updates and news.",
                                         font: .currentFont(withSize: 14, weight: .regular),
                                         textColor: .foregroundSecondary)
    }
}

// MARK: - Actions
private extension DomainsCollectionSuggestionCell {
    @IBAction func closeButtonPressed(_ sender: Any) {
        UDVibration.buttonTap.vibrate()
        closeButtonPressedCallback?()
    }
}
