//
//  DomainProfileSocialCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.11.2022.
//

import UIKit

final class DomainProfileSocialCell: BaseListCollectionViewCell {

    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var infoNameLabel: UILabel!
    @IBOutlet private weak var socialValueLabel: UILabel!
    @IBOutlet private weak var actionButton: UIButton!

    override var containerColor: UIColor { .clear }

    private var socialDescription: DomainProfileSocialAccount?
    private var actionButtonPressedCallback: EmptyCallback?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        actionButton.setTitle("", for: .normal)
    }

}

// MARK: - Open methods
extension DomainProfileSocialCell {
    func setWith(displayInfo: DomainProfileViewController.DomainProfileSocialsDisplayInfo) {
        self.actionButtonPressedCallback = displayInfo.actionButtonPressedCallback
        self.isUserInteractionEnabled = displayInfo.isEnabled
        
        let description = displayInfo.description
        self.socialDescription = description
        iconImageView.image = description.type.icon
        infoNameLabel.setAttributedTextWith(text: description.type.title,
                                            font: .currentFont(withSize: 16, weight: .medium),
                                            textColor: .white)
        if description.value.isEmpty {
            let placeholder = description.type.placeholder
            socialValueLabel.setAttributedTextWith(text: placeholder,
                                                   font: .currentFont(withSize: 16, weight: .regular),
                                                   textColor: .white.withAlphaComponent(0.56))
        } else {
            let prefix = description.type.prefix
            let value = description.type.displayStringForValue(description.value)
            socialValueLabel.setAttributedTextWith(text: value,
                                                   font: .currentFont(withSize: 16, weight: .regular),
                                                   textColor: .white,
                                                   lineBreakMode: .byTruncatingTail)
            socialValueLabel.updateAttributesOf(text: prefix,
                                                textColor: .white.withAlphaComponent(0.56),
                                                numberOfRepeatanceToUpdate: 1)
        }
         
        setupControlsForCurrentMode(isEnabled: displayInfo.isEnabled)
        
        // Actions
        let bannerMenuElements = displayInfo.availableActions.compactMap({ menuElement(for: $0) })
        let bannerMenu = UIMenu(title: actionMenuTitle, children: bannerMenuElements)
        actionButton.menu = bannerMenu
        actionButton.showsMenuAsPrimaryAction = true
        actionButton.addAction(UIAction(handler: { [weak self] _ in
            self?.actionButtonPressedCallback?()
            UDVibration.buttonTap.vibrate()
        }), for: .menuActionTriggered)
    }
}

// MARK: - Private methods
private extension DomainProfileSocialCell {
    var actionMenuTitle: String {
        "\(socialDescription?.type.title ?? "") • \(socialValueLabel.attributedString?.string ?? "")"
    }
    
    func menuElement(for action: DomainProfileSocialsSection.SocialsAction) -> UIMenuElement {
        switch action {
        case .edit(_, let callback), .open(_, let callback), .copy(_, let callback):
            return UIAction(title: action.title, image: action.icon, identifier: .init(UUID().uuidString), handler: { _ in callback() })
        case .remove(_, let callback):
            let remove = UIAction(title: action.title, image: action.icon, identifier: .init(UUID().uuidString), attributes: .destructive, handler: { _ in callback() })
            return UIMenu(title: "", options: .displayInline, children: [remove])
        }
    }
    
    func setupControlsForCurrentMode(isEnabled: Bool) {
        actionButton.isHidden = !isEnabled
    }
}
