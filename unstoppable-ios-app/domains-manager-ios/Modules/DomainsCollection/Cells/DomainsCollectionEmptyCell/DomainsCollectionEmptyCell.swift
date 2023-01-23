//
//  DomainsCollectionEmptyCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.04.2022.
//

import UIKit

final class DomainsCollectionEmptyCell: UICollectionViewCell {

    @IBOutlet private weak var mintDomainContainerView: UIView!
    @IBOutlet private weak var alreadyOwnDomainLabel: UILabel!
    @IBOutlet private weak var mintDomainButton: TextButton!
    @IBOutlet private weak var wantToBuyDomainLabel: UILabel!
    @IBOutlet private weak var buyDomainContainerView: UIView!
    @IBOutlet private weak var buyDomainButton: TextTertiaryButton!

    var mintButtonPressed: EmptyCallback?
    var buyButtonPressed: EmptyCallback?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        setup()
    }

}

// MARK: - Actions
private extension DomainsCollectionEmptyCell {
    @objc func didTapMintDomainContainer() {
        UDVibration.buttonTap.vibrate()
        didPressMintDomainButton(0)
    }
    
    @IBAction func didPressMintDomainButton(_ sender: Any) {
        mintButtonPressed?()
    }
    
    @objc func didTapBuyDomainContainer() {
        UDVibration.buttonTap.vibrate()
        didPressMintDomainButton(0)
    }
    
    @IBAction func didPressBuyDomainButton(_ sender: Any) {
        buyButtonPressed?()
    }
}

// MARK: - Setup methods
private extension DomainsCollectionEmptyCell {
    func setup() {
        localizeContent()
        addGestures()
    }
    
    func localizeContent() {
        alreadyOwnDomainLabel.setAttributedTextWith(text: String.Constants.alreadyOwnADomain.localized(),
                                                    font: .currentFont(withSize: 22, weight: .bold),
                                                    textColor: .foregroundDefault,
                                                    lineHeight: 28)
        wantToBuyDomainLabel.setAttributedTextWith(text: String.Constants.wantToBuyADomain.localized(),
                                                    font: .currentFont(withSize: 22, weight: .bold),
                                                    textColor: .foregroundDefault,
                                                    lineHeight: 28)
        mintDomainButton.setTitle(String.Constants.mintDomain.localized(), image: .sparklesIcon)
        buyDomainButton.setTitle(String.Constants.buyDomain.localized(), image: .cartIcon)
    }
    
    func addGestures() {
        mintDomainContainerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector((didTapMintDomainContainer))))
        buyDomainContainerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector((didTapBuyDomainContainer))))
    }
}
