//
//  ConnectedAppCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.06.2022.
//

import UIKit

final class ConnectedAppCell: BaseListCollectionViewCell {

    @IBOutlet private weak var appImageView: ConnectedAppImageView!
    @IBOutlet private weak var appNameLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var actionButton: UIButton!
    
    private var actionCallback: ConnectedAppCellItemActionCallback?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        actionButton.setTitle("", for: .normal)
        isSelectable = false
    }
}

// MARK: - Open methods
extension ConnectedAppCell {
    func setWith(displayInfo: ConnectedAppsListViewController.AppItemDisplayInfo, actionCallback: @escaping ConnectedAppCellItemActionCallback) {
        let app = displayInfo.app
        self.actionCallback = actionCallback
        appImageView.setWith(app: app)
        appNameLabel.setAttributedTextWith(text: app.displayName,
                                           font: .currentFont(withSize: 16, weight: .medium),
                                           textColor: .foregroundDefault,
                                           lineBreakMode: .byTruncatingTail)
        if let connectionDate = app.connectionStartDate {
            let formattedDate = DateFormattingService.shared.formatRecentActivityDate(connectionDate)
            subtitleLabel.setAttributedTextWith(text: formattedDate,
                                                font: .currentFont(withSize: 14, weight: .medium),
                                                textColor: .foregroundSecondary,
                                                lineBreakMode: .byTruncatingTail)
        }
        subtitleLabel.isHidden = app.connectionStartDate == nil
        
        // Actions
        Task {
            var menuElements = [UIMenuElement]()
            for action in displayInfo.actions {
                let menuElement = await menuElement(for: action)
                menuElements.append(menuElement)
            }
            let menu = UIMenu(title: "\(app.displayName)", children: menuElements)
            actionButton.menu = menu
            actionButton.showsMenuAsPrimaryAction = true
            actionButton.addAction(UIAction(handler: { _ in
                appContext.analyticsService.log(event: .buttonPressed,
                                                withParameters: [.button: Analytics.Button.connectedAppDot.rawValue])
                UDVibration.buttonTap.vibrate()
            }), for: .menuActionTriggered)
        }
    }
}

// MARK: - Private methods
private extension ConnectedAppCell {
    func menuElement(for action: ConnectedAppsListViewController.ItemAction) async -> UIMenuElement {
        switch action {
        case .networksInfo:
            return UIAction.createWith(title: action.title,
                                       subtitle: action.subtitle,
                                       image: await action.icon,
                                       handler: { [weak self] _ in  self?.actionCallback?(action) })
        case .disconnect:
            let action = UIAction(title: action.title, image: await action.icon, identifier: .init(UUID().uuidString), attributes: .destructive, handler: { [weak self] _ in self?.actionCallback?(action) })
            return UIMenu(options: [.displayInline], children: [action])
        }
    }
}
