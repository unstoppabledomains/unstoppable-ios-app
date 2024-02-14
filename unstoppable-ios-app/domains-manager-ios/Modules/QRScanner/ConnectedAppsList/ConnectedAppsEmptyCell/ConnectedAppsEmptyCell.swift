//
//  ConnectedAppsEmptyCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.01.2024.
//

import UIKit

final class ConnectedAppsEmptyCell: UICollectionViewCell {

    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var actionButton: UDConfigurableButton!
    
    private var actionButtonCallback: EmptyCallback?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        iconImageView.image = .widgetIcon
        titleLabel.setAttributedTextWith(text: String.Constants.noConnectedApps.localized(),
                                         font: .currentFont(withSize: 20, weight: .bold),
                                         textColor: .foregroundSecondary,
                                         alignment: .center,
                                         lineHeight: 24)
        subtitleLabel.isHidden = true
        actionButton.setConfiguration(.mediumRaisedPrimaryButtonConfiguration)
        actionButton.setTitle(String.Constants.scanToConnect.localized(), image: .qrBarCodeIcon)
    }
    
    func set(actionCallback: @escaping MainActorAsyncCallback) {
        self.actionButtonCallback = actionCallback
    }
    
    @IBAction func actionButtonPressed(_ sender: Any) {
        actionButtonCallback?()
    }
}
