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
    private var actions: [DomainProfileMetadataSection.MetadataAction] = []

    override func awakeFromNib() {
        super.awakeFromNib()

        actionButton.setTitle("", for: .normal)
    }

}

// MARK: - Open methods
extension DomainProfileMetadataCell {
    func setWith(displayInfo: DomainProfileViewController.DomainProfileMetadataDisplayInfo) {
        self.actionButtonPressedCallback = displayInfo.actionButtonPressedCallback
        self.actions = displayInfo.availableActions
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
            actionButton.isHidden = actions.isEmpty
            
            if value.isEmpty {
                let placeholder = String.Constants.addN.localized(type.title.lowercased())
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
        
        if #available(iOS 14.0, *) {
            let bannerMenuElements = displayInfo.availableActions.compactMap({ menuElement(for: $0) })
            let bannerMenu = UIMenu(title: "", children: bannerMenuElements)
            actionButton.menu = bannerMenu
            actionButton.showsMenuAsPrimaryAction = true
            actionButton.addAction(UIAction(handler: { [weak self] _ in
                self?.actionButtonPressedCallback?()
                UDVibration.buttonTap.vibrate()
            }), for: .menuActionTriggered)
        } else {
            self.actions = displayInfo.availableActions
            actionButton.addTarget(self, action: #selector(actionsButtonPressed), for: .touchUpInside)
        }
    }
}

// MARK: - Private methods
private extension DomainProfileMetadataCell {
    @objc func actionsButtonPressed() {
        guard let view = self.findViewController()?.view else { return }
        
        actionButtonPressedCallback?()
        UDVibration.buttonTap.vibrate()
        let actions: [UIActionBridgeItem] = actions.map({ action in uiActionBridgeItem(for: action) }).reduce(into: [UIActionBridgeItem]()) { partialResult, result in
            partialResult += result
        }
        let popoverViewController = UIMenuBridgeView.instance(with: "",
                                                              actions: actions)
        popoverViewController.show(in: view, sourceView: actionButton)
    }
    
    func menuElement(for action: DomainProfileMetadataSection.MetadataAction) -> UIMenuElement {
        switch action {
        case .edit(_, let callback), .copy(_, let callback):
            return UIAction(title: action.title, image: action.icon, identifier: .init(UUID().uuidString), handler: { _ in callback() })
        case .remove(_, let callback):
            let remove = UIAction(title: action.title, image: action.icon, identifier: .init(UUID().uuidString), attributes: .destructive, handler: { _ in callback() })
            return UIMenu(title: "", options: .displayInline, children: [remove])
        }
    }
    
    func uiActionBridgeItem(for action: DomainProfileMetadataSection.MetadataAction) -> [UIActionBridgeItem] {
        switch action {
        case .edit(_, let callback), .copy(_, let callback):
            return [UIActionBridgeItem(title: action.title, image: action.icon, handler: {  callback() })]
        case .remove(_, let callback):
            return [UIActionBridgeItem(title: action.title, image: action.icon, attributes: [.destructive], handler: { callback() })]
        }
    }
}
