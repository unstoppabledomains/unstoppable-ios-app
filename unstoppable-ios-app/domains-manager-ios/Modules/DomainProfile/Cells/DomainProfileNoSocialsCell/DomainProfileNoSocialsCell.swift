//
//  DomainProfileNoSocialsCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.11.2022.
//

import UIKit

final class DomainProfileNoSocialsCell: UICollectionViewCell {

    
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var manageButton: RaisedTertiaryButton!
    
    private var manageButtonPressedCallback: EmptyCallback?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.white.withAlphaComponent(0.16).cgColor
        titleLabel.setAttributedTextWith(text: String.Constants.comingSoon.localized(),
                                         font: .currentFont(withSize: 16, weight: .medium),
                                         textColor: .white.withAlphaComponent(0.56))
        subtitleLabel.setAttributedTextWith(text: String.Constants.profileSocialsEmptyMessage.localized(),
                                         font: .currentFont(withSize: 14, weight: .regular),
                                         textColor: .white.withAlphaComponent(0.32),
                                         lineHeight: 20)
        manageButton.setTitle(String.Constants.manageOnTheWebsite.localized(), image: nil)
    }

}

// MARK: - Open methods
extension DomainProfileNoSocialsCell {
    func setWith(displayInfo: DomainProfileViewController.DomainProfileSocialsEmptyDisplayInfo) {
        manageButtonPressedCallback = displayInfo.manageButtonPressedCallback
    }
}

// MARK: - Private methods
private extension DomainProfileNoSocialsCell {
    @IBAction func manageButtonPressed() {
        UDVibration.buttonTap.vibrate()
        manageButtonPressedCallback?()
    }
}
