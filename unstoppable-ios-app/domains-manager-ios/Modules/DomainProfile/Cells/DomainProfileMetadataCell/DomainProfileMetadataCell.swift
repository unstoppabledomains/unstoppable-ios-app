//
//  DomainProfileMetadataCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.11.2022.
//

import UIKit

final class DomainProfileMetadataCell: BaseListCollectionViewCell {

    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var infoNameLabel: UILabel!
    @IBOutlet private weak var metadataValueLabel: UILabel!
    @IBOutlet private weak var actionButton: UIButton!

    override var containerColor: UIColor { .clear }
    
    private var actionButtonPressedCallback: EmptyCallback?

    override func awakeFromNib() {
        super.awakeFromNib()

        actionButton.setTitle("", for: .normal)
    }

}

// MARK: - Open methods
extension DomainProfileMetadataCell {
    func setWith(displayInfo: DomainProfileViewController.DomainProfileMetadataDisplayInfo) {
        self.actionButtonPressedCallback = displayInfo.actionButtonPressedCallback
        self.isUserInteractionEnabled = displayInfo.isEnabled

        let type = displayInfo.type
        iconImageView.image = type.icon
        infoNameLabel.setAttributedTextWith(text: type.title,
                                            font: .currentFont(withSize: 16, weight: .medium),
                                            textColor: .white)
        switch displayInfo.type {
        case .humanityCheckVerified:
            metadataValueLabel.isHidden = true
            actionButton.isHidden = true
        case .email(let value):
            metadataValueLabel.isHidden = false
            actionButton.isHidden = displayInfo.availableActions.isEmpty
            
            if value.isEmpty {
                let placeholder = String.Constants.profileAddN.localized(type.title.lowercased())
                metadataValueLabel.setAttributedTextWith(text: placeholder,
                                                         font: .currentFont(withSize: 16, weight: .regular),
                                                         textColor: .white.withAlphaComponent(0.56),
                                                         lineBreakMode: .byTruncatingMiddle)
            } else {
                metadataValueLabel.setAttributedTextWith(text: value,
                                                         font: .currentFont(withSize: 16, weight: .regular),
                                                         textColor: .white,
                                                         lineBreakMode: .byTruncatingMiddle)
            }
        }
        
        // Actions
        let bannerMenuElements = displayInfo.availableActions.compactMap({ menuElement(for: $0) })
        let bannerMenu = UIMenu(title: "", children: bannerMenuElements)
        actionButton.menu = bannerMenu
        actionButton.showsMenuAsPrimaryAction = true
        actionButton.addAction(UIAction(handler: { [weak self] _ in
            self?.actionButtonPressedCallback?()
            UDVibration.buttonTap.vibrate()
        }), for: .menuActionTriggered)
    }
}

// MARK: - Private methods
private extension DomainProfileMetadataCell {
    func menuElement(for action: DomainProfileMetadataSection.MetadataAction) -> UIMenuElement {
        switch action {
        case .edit(_, let callback), .copy(_, let callback):
            return UIAction(title: action.title, image: action.icon, identifier: .init(UUID().uuidString), handler: { _ in callback() })
        case .remove(_, let callback):
            let remove = UIAction(title: action.title, image: action.icon, identifier: .init(UUID().uuidString), attributes: .destructive, handler: { _ in callback() })
            return UIMenu(title: "", options: .displayInline, children: [remove])
        }
    }
}
