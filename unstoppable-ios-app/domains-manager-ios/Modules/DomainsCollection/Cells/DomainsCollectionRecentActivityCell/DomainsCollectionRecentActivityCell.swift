//
//  DomainsCollectionRecentActivityCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.12.2022.
//

import UIKit

final class DomainsCollectionRecentActivityCell: UICollectionViewCell {

    typealias Action = DomainsCollectionCarouselItemViewController.RecentActivitiesConfiguration.Action
    
    static let height: CGFloat = 68
    
    @IBOutlet private weak var iconImageView: ConnectedAppImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var actionButton: UIButton!
    @IBOutlet private weak var timeLabel: UILabel!
    
    private var actionButtonPressedCallback: EmptyCallback?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        actionButton.setTitle("", for: .normal)
    }
 
}

// MARK: - Open methods
extension DomainsCollectionRecentActivityCell {
    func setWith(configuration: DomainsCollectionCarouselItemViewController.RecentActivitiesConfiguration) {
        self.actionButtonPressedCallback = configuration.actionButtonPressedCallback
        let app = configuration.connectedApp
        iconImageView.setWith(app: app)
        nameLabel.setAttributedTextWith(text: app.displayName,
                                        font: .currentFont(withSize: 16, weight: .medium),
                                        textColor: .foregroundDefault,
                                        lineBreakMode: .byTruncatingTail)
        
        if let connectionDate = app.connectionStartDate {
            let formattedDate = DateFormattingService.shared.formatRecentActivityDate(connectionDate)
            timeLabel.setAttributedTextWith(text: formattedDate,
                                            font: .currentFont(withSize: 14, weight: .regular),
                                            textColor: .foregroundSecondary,
                                            lineBreakMode: .byTruncatingTail)
        }
        timeLabel.isHidden = app.connectionStartDate == nil
        
        // Actions
        let bannerMenuElements = configuration.availableActions.compactMap({ menuElement(for: $0) })
        let bannerMenu = UIMenu(title: app.displayName, children: bannerMenuElements)
        actionButton.menu = bannerMenu
        actionButton.showsMenuAsPrimaryAction = true
        actionButton.addAction(UIAction(handler: { [weak self] _ in
            self?.actionButtonPressedCallback?()
            UDVibration.buttonTap.vibrate()
        }), for: .menuActionTriggered)
    }
}

// MARK: - Actions
private extension DomainsCollectionRecentActivityCell {
    func menuElement(for action: Action) -> UIMenuElement {
        switch action {
        case .openApp(let callback):
            let action = UIAction(title: action.title, image: action.icon, identifier: .init(UUID().uuidString), handler: { _ in
                UDVibration.buttonTap.vibrate()
                callback()
            })
            return action
        case .disconnect(let callback):
            let disconnect = UIAction(title: action.title, image: action.icon, identifier: .init(UUID().uuidString), attributes: .destructive, handler: { _ in
                UDVibration.buttonTap.vibrate()
                callback()
            })
            return UIMenu(title: "", options: .displayInline, children: [disconnect])
        }
    }
}
