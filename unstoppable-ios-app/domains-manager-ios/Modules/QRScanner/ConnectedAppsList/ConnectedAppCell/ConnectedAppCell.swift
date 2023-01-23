//
//  ConnectedAppCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.06.2022.
//

import UIKit

final class ConnectedAppCell: BaseListCollectionViewCell {

    @IBOutlet private weak var appImageBackgroundView: UIView!
    @IBOutlet private weak var appImageView: UIImageView!
    @IBOutlet private weak var appNameLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var actionButton: UIButton!
    
    private var actionCallback: ConnectedAppCellItemActionCallback?
    private var actionsMenuTitle: String = ""
    private var actions: [ConnectedAppsListViewController.ItemAction] = []
    
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
                
        Task {
            let icon = await appContext.imageLoadingService.loadImage(from: .connectedApp(displayInfo.app, size: .default), downsampleDescription: nil)
            if displayInfo.app.appIconUrls.isEmpty {
                appImageBackgroundView.isHidden = true
            } else {
                appImageBackgroundView.isHidden = false
                let color = await icon?.getColors()?.background
                appImageBackgroundView.backgroundColor = (color ?? .brandWhite)
            }
            appImageView.image = icon
        }
        
        appImageView.layer.borderColor = UIColor.borderSubtle.cgColor
        appImageView.layer.borderWidth = 1
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
        
        actionsMenuTitle = "\(app.displayName)"
        Task {
            if #available(iOS 14.0, *) {
                var menuElements = [UIMenuElement]()
                for action in displayInfo.actions {
                    let menuElement = await menuElement(for: action)
                    menuElements.append(menuElement)
                }
                let menu = UIMenu(title: actionsMenuTitle, children: menuElements)
                actionButton.menu = menu
                actionButton.showsMenuAsPrimaryAction = true
                actionButton.addAction(UIAction(handler: { _ in
                    appContext.analyticsService.log(event: .buttonPressed,
                                                    withParameters: [.button: Analytics.Button.connectedAppDot.rawValue])
                    UDVibration.buttonTap.vibrate()
                }), for: .menuActionTriggered)
            } else {
                self.actions = displayInfo.actions
                actionButton.addTarget(self, action: #selector(actionsButtonPressed), for: .touchUpInside)
            }
        }
    }
}

// MARK: - Actions
private extension ConnectedAppCell {
    @objc func actionsButtonPressed(_ sender: Any) {
        appContext.analyticsService.log(event: .buttonPressed,
                                    withParameters: [.button: Analytics.Button.connectedAppDot.rawValue])
        guard let view = self.findViewController()?.view else { return }

        UDVibration.buttonTap.vibrate()
        Task {
            var actions: [UIActionBridgeItem] = []
            
            for action in self.actions {
                let action = await uiAlertAction(for: action)
                actions.append(contentsOf: action)
            }
            let popoverViewController = UIMenuBridgeView.instance(with: actionsMenuTitle,
                                                                  actions: actions)
            popoverViewController.show(in: view, sourceView: actionButton)
        }
    }
}

// MARK: - Private methods
private extension ConnectedAppCell {
    func menuElement(for action: ConnectedAppsListViewController.ItemAction) async -> UIMenuElement {
        switch action {
        case .domainInfo, .networksInfo:
            if #available(iOS 15.0, *) {
                return UIAction(title: action.title,
                                subtitle: action.subtitle,
                                image: await action.icon,
                                identifier: .init(UUID().uuidString),
                                handler: { [weak self] _ in  self?.actionCallback?(action) })
            } else {
                return UIAction(title: action.title,
                                image: await action.icon,
                                identifier: .init(UUID().uuidString),
                                handler: { [weak self] _ in  self?.actionCallback?(action) })
            }
        case .disconnect:
            let action = UIAction(title: action.title, image: await action.icon, identifier: .init(UUID().uuidString), attributes: .destructive, handler: { [weak self] _ in self?.actionCallback?(action) })
            return UIMenu(options: [.displayInline], children: [action])
        }
    }
    
    func uiAlertAction(for action: ConnectedAppsListViewController.ItemAction) async -> [UIActionBridgeItem] {
        switch action {
        case .disconnect, .domainInfo, .networksInfo:
            return [UIActionBridgeItem(title: action.title, image: await action.icon, attributes: [.destructive], handler: { [weak self] in self?.actionCallback?(action) })]
        }
    }
}
