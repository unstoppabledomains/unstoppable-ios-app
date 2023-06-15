//
//  ChatsListNavigationView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.06.2023.
//

import UIKit

final class ChatsListNavigationView: UIView {
    
    private let height: CGFloat = 24
    private let elementsSpacing: CGFloat = 8
    private let titleFont: UIFont = .currentFont(withSize: 16, weight: .semibold)
    
    private var imageView: UIImageView!
    private var titleButton: UIButton!
    private var chevron: UIImageView!
    
    var walletSelectedCallback: ((WalletDisplayInfo)->())?
    
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
        
        let imageY = (height - imageView.bounds.height) / 2
        imageView.frame.origin = CGPoint(x: 0,
                                         y: imageY)

        let titleWidth = calculateTitleButtonWidth()
        titleButton.frame = CGRect(x: imageView.frame.maxX + elementsSpacing,
                                   y: 0,
                                   width: titleWidth,
                                   height: height)
        
        var trailingView: UIView = titleButton
        if !chevron.isHidden {
            let chevronY = (height - titleButton.bounds.height) / 2
            chevron.frame.origin = CGPoint(x: titleButton.frame.maxX + elementsSpacing,
                                           y: chevronY)
            trailingView = chevron
        }
        
        frame.size = CGSize(width: trailingView.frame.maxX,
                            height: height)
    }
    
}

// MARK: - Open methods
extension ChatsListNavigationView {
    func setWithConfiguration(_ configuration: Configuration) {
        setWithWallet(configuration.selectedWallet)
        setButtonWith(configuration: configuration)
        chevron.isHidden = configuration.wallets.count <= 1
        titleButton.isUserInteractionEnabled = !chevron.isHidden
        setNeedsLayout()
        layoutIfNeeded()
    }
}

// MARK: - Private methods
private extension ChatsListNavigationView {
    func setWithWallet(_ wallet: WalletDisplayInfo) {
        let title = getTitleFor(wallet: wallet)
        titleButton.setAttributedTextWith(text: title,
                                          font: titleFont,
                                          textColor: .foregroundDefault)
        Task { imageView.image = await getAvatarImageFor(wallet: wallet) }
    }

    func getTitleFor(wallet: WalletDisplayInfo) -> String {
        wallet.reverseResolutionDomain?.name ?? wallet.displayName
    }
    
    func setButtonWith(configuration: Configuration) {
        Task {
            var actions: [UIMenuElement] = []
            
            for wallet in configuration.wallets {
                let action = await menuAction(for: wallet)
                actions.append(action)
            }
            
            let menu = UIMenu(title: "", children: actions)
            titleButton.menu = menu
            titleButton.showsMenuAsPrimaryAction = true
            titleButton.addAction(UIAction(handler: {  _ in
                UDVibration.buttonTap.vibrate()
            }), for: .menuActionTriggered)
        }
    }
    
    func menuAction(for wallet: WalletDisplayInfo) async -> UIMenuElement {
        let title = getTitleFor(wallet: wallet)
        let subtitle = wallet.reverseResolutionDomain == nil ? "Set primary domain" : wallet.displayName
        let avatar = await getAvatarImageFor(wallet: wallet)
        let action = UIAction.createWith(title: title,
                                         subtitle: subtitle,
                                         image: avatar,
                                         handler: { [weak self] _ in
            UDVibration.buttonTap.vibrate()
            self?.walletSelectedCallback?(wallet)
        })
        return action
    }
    
    func getAvatarImageFor(wallet: WalletDisplayInfo) async -> UIImage {
        if let rrDomain = wallet.reverseResolutionDomain,
           let avatar = await UIMenuDomainAvatarLoader.menuAvatarFor(domain: rrDomain,
                                                                     size: 24) {
            return avatar
        }
        
        return .personCircle
    }
    
    func calculateTitleButtonWidth() -> CGFloat {
        guard let title = titleButton.attributedString?.string else { return 0 }
        
        return title.width(withConstrainedHeight: height, font: titleFont)
    }
    
    @objc func titleButtonPressed() {
        UDVibration.buttonTap.vibrate()
    }
}

// MARK: - Setup methods
private extension ChatsListNavigationView {
    func setup() {
        setupImageView()
        setupChevron()
        setupTitleButton()
    }
    
    func setupImageView() {
        let imageSize: CGFloat = 20
        imageView = UIImageView(frame: CGRect(origin: .zero,
                                              size: .square(size: imageSize)))
        imageView.layer.cornerRadius = imageSize / 2
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.tintColor = .foregroundDefault
        addSubview(imageView)
    }
    
    func setupChevron() {
        chevron = UIImageView(frame: CGRect(origin: .zero,
                                            size: .square(size: 20)))
        chevron.image = .chevronDown
        chevron.tintColor = .foregroundDefault
        addSubview(chevron)
    }
    
    func setupTitleButton() {
        titleButton = UIButton(frame: CGRect(origin: .zero,
                                             size: CGSize(width: 0, height: height)))
        titleButton.addTarget(self, action: #selector(titleButtonPressed), for: .touchUpInside)
        
        addSubview(titleButton)
    }
}

// MARK: - Open methods
extension ChatsListNavigationView {
    struct Configuration {
        let selectedWallet: WalletDisplayInfo
        let wallets: [WalletDisplayInfo]
    }
}
