//
//  DomainProfileWeb3WebsiteCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.11.2022.
//

import UIKit

final class DomainProfileWeb3WebsiteCell: BaseListCollectionViewCell {

    @IBOutlet private weak var previewImageView: UIImageView!
    @IBOutlet private weak var placeholderImageView: UIImageView!
    @IBOutlet private weak var domainNameLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var secondaryLabel: UILabel!

    @IBOutlet private weak var actionButton: UIButton!

    override var containerColor: UIColor { .clear }

    private var actionButtonPressedCallback: EmptyCallback?
    private var actions: [DomainProfileWeb3WebsiteSection.WebsiteAction] = []
    
    override func awakeFromNib() {
        super.awakeFromNib()

        actionButton.setTitle("", for: .normal)
        secondaryLabel.isHidden = true
        titleLabel.setAttributedTextWith(text: "")
    }

}

// MARK: - Open methods
extension DomainProfileWeb3WebsiteCell {
    func setWith(displayInfo: DomainProfileViewController.DomainProfileWeb3WebsiteDisplayInfo) {
        self.actionButtonPressedCallback = displayInfo.actionButtonPressedCallback
        self.actions = displayInfo.availableActions
        
        set(domainName: displayInfo.domainName, title: nil, previewImage: nil)
        Task { [weak self] in
            let metadataDescription = await appContext.linkPresentationService.fetchLinkPresentationDescription(for: displayInfo.web3Url)
            self?.set(domainName: displayInfo.domainName, title: metadataDescription.title, previewImage: metadataDescription.image)
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
private extension DomainProfileWeb3WebsiteCell {
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
    
    func menuElement(for action: DomainProfileWeb3WebsiteSection.WebsiteAction) -> UIMenuElement {
        switch action {
        case .open(_, let callback):
            return UIAction(title: action.title, image: action.icon, identifier: .init(UUID().uuidString), handler: { _ in callback() })
        }
    }
    
    func uiActionBridgeItem(for action: DomainProfileWeb3WebsiteSection.WebsiteAction) -> [UIActionBridgeItem] {
        switch action {
        case .open(_, let callback):
            return [UIActionBridgeItem(title: action.title, image: action.icon, handler: {  callback() })]
        }
    }
    
    func set(domainName: String,
             title: String?,
             previewImage: UIImage?) {
      
        titleLabel.isHidden = title == nil
        previewImageView.image = previewImage
        placeholderImageView.isHidden = previewImage != nil 
        if let title {
            titleLabel.setAttributedTextWith(text: title,
                                             font: .currentFont(withSize: 16, weight: .semibold),
                                             textColor: .foregroundOnEmphasis,
                                             lineBreakMode: .byTruncatingTail)
            domainNameLabel.setAttributedTextWith(text: domainName,
                                                  font: .currentFont(withSize: 14, weight: .medium),
                                                  textColor: .white.withAlphaComponent(0.56),
                                                  lineBreakMode: .byTruncatingTail)
        } else {
            domainNameLabel.setAttributedTextWith(text: domainName,
                                                  font: .currentFont(withSize: 16, weight: .semibold),
                                                  textColor: .foregroundOnEmphasis,
                                                  lineBreakMode: .byTruncatingTail)
        }
    }
}
