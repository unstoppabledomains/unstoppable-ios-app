//
//  DomainsCollectionTitleMintingProgressView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.12.2022.
//

import UIKit

final class DomainsCollectionTitleMintingProgressView: UIView {
    
    typealias MintingDomainSelectionCallback = (DomainDisplayInfo)->()
    
    private var statusButton: UDButton!
    private let height: CGFloat = 24
    private let buttonFont: UIFont = .currentFont(withSize: 16, weight: .semibold)
    private let maxVisibleMintingDomains = 3
    private var mintingDomains = [DomainDisplayInfo]()
    var mintedDomainSelectedCallback: MintingDomainSelectionCallback?
    var showMoreSelectedCallback: EmptyCallback?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.bounds.size = statusButton.bounds.size
        statusButton.frame.origin = .zero
    }
    
}

// MARK: - Open methods
extension DomainsCollectionTitleMintingProgressView {
    func setMintingDomains(_ mintingDomains: [DomainDisplayInfo]) {
        self.mintingDomains = mintingDomains
        
        let mintingWord = String.Constants.moving.localized()
        let title = "\(mintingWord) · \(mintingDomains.count)"
        statusButton.setTitle(title, image: nil)
        setActionsForMintingButton()
        
        setNeedsLayout()
        layoutIfNeeded()
    }
}

// MARK: - Actions
private extension DomainsCollectionTitleMintingProgressView {
    func setActionsForMintingButton() {
        if mintingDomains.count > 1 {
            Task {
                let visibleDomains = mintingDomains.prefix(maxVisibleMintingDomains)
                var actions: [UIMenuElement] = []
                
                for domain in visibleDomains {
                    let action = await menuElement(for: domain)
                    actions.append(action)
                }
                
                if mintingDomains.count > maxVisibleMintingDomains {
                    actions.append(showMoreMenuElement())
                }
                
                let menu = UIMenu(title: "", children: actions)
                statusButton.menu = menu
                statusButton.showsMenuAsPrimaryAction = true
                statusButton.addAction(UIAction(handler: { _ in
                    UDVibration.buttonTap.vibrate()
                }), for: .menuActionTriggered)
            }
        } else {
            statusButton.addTarget(self, action: #selector(statusButtonPressed), for: .touchUpInside)
        }
    }
    
    @objc func statusButtonPressed() {
        if let selectedDomain = mintingDomains.first {
            mintedDomainSelectedCallback?(selectedDomain)
        }
    }
}

// MARK: - Private methods
private extension DomainsCollectionTitleMintingProgressView {
    func menuElement(for domain: DomainDisplayInfo) async -> UIMenuElement {
        let avatar = await avatarFor(domain: domain)
        let action = UIAction(title: domain.name,
                              image: avatar,
                              identifier: .init(UUID().uuidString),
                              handler: { [weak self] _ in
            UDVibration.buttonTap.vibrate()
            self?.mintedDomainSelectedCallback?(domain)
        })
        
        return action
    }
    
    func showMoreMenuElement() -> UIMenuElement {
        let action = UIAction(title: String.Constants.showMore.localized(),
                              image: .chevronDown,
                              identifier: .init(UUID().uuidString), handler: { [weak self] _ in
            UDVibration.buttonTap.vibrate()
            self?.showMoreSelectedCallback?()
        })
        return UIMenu(title: "", options: .displayInline, children: [action])
    }
    
    func avatarFor(domain: DomainDisplayInfo) async -> UIImage? {
        var avatar = await appContext.imageLoadingService.loadImage(from: .domain(domain),
                                                                    downsampleDescription: nil)
        
        if let image = avatar {
            avatar = image.uiMenuCroppedImage()
        } else {
            avatar = await appContext.imageLoadingService.loadImage(from: .domainInitials(domain,
                                                                                          size: .default),
                                                                    downsampleDescription: nil)
        }
        return avatar
    }
}

// MARK: - Setup methods
private extension DomainsCollectionTitleMintingProgressView {
    func setup() {
        setupStatusButton()
        setMintingDomains([])
    }
    
    func setupStatusButton() {
        statusButton = UDButton(frame: .init(origin: .zero,
                                             size: .init(width: height,
                                                         height: height)))
        
        let buttonConfiguration = UDButtonConfiguration(backgroundIdleColor: .clear,
                                                        backgroundHighlightedColor: .clear,
                                                        backgroundDisabledColor: .clear,
                                                        textColor: .foregroundDefault,
                                                        textHighlightedColor: .foregroundDefault,
                                                        textDisabledColor: .foregroundDefault,
                                                        fontWeight: .semibold,
                                                        fontSize: 16)
        statusButton.setConfiguration(buttonConfiguration)
        
        addSubview(statusButton)
    }
}
