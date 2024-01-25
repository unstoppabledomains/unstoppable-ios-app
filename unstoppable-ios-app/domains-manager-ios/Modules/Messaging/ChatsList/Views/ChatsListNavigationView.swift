//
//  ChatsListNavigationView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.06.2023.
//

import UIKit
import SwiftUI

final class ChatsListNavigationView: UIView {
    
    private let height: CGFloat = 24
    private let elementsSpacing: CGFloat = 8
    private let titleFont: UIFont = .currentFont(withSize: 16, weight: .semibold)
    private let activityScale: CGFloat = 0.7
    
    private var imageView: UIImageView!
    private var titleButton: UIButton!
    private var chevron: UIImageView!
    private var activityIndicator: UIActivityIndicatorView!
    private var isLoading = false
    
    var pressedCallback: EmptyCallback?
    var walletSelectedCallback: ((WalletEntity)->())?
    
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
        
        var imageOrigin: CGFloat = 0
        
        if isLoading {
            let indicatorY = (height - activityIndicator.bounds.height * activityScale) / 2
            activityIndicator.frame.origin = CGPoint(x: 0,
                                                     y: indicatorY)
            imageOrigin = activityIndicator.frame.maxX + elementsSpacing
        }
        
        let imageY = (height - imageView.bounds.height) / 2
        imageView.frame.origin = CGPoint(x: imageOrigin,
                                         y: imageY)

        let titleRequiredWidth = calculateTitleButtonWidth()
        let titleMaxWidth = UIScreen.main.bounds.width * 0.5
        let titleWidth = min(titleMaxWidth, titleRequiredWidth)
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
        self.isLoading = configuration.isLoading
        activityIndicator.startAnimating()
        activityIndicator.isHidden = !isLoading
        setNeedsLayout()
        layoutIfNeeded()
    }
}

// MARK: - Private methods
private extension ChatsListNavigationView {
    func setWithWallet(_ wallet: WalletEntity) {
        let title = getTitleFor(wallet: wallet)
        titleButton.setAttributedTextWith(text: title,
                                          font: titleFont,
                                          textColor: .foregroundDefault,
                                          lineBreakMode: .byTruncatingTail)
        Task { imageView.image = await getAvatarImageFor(wallet: wallet) }
    }

    func getTitleFor(wallet: WalletEntity) -> String {
        wallet.rrDomain?.name ?? wallet.displayName
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
            titleButton.addAction(UIAction(handler: { [weak self]  _ in
                UDVibration.buttonTap.vibrate()
                self?.pressedCallback?()
            }), for: .menuActionTriggered)
        }
    }
    
    func menuAction(for walletTitleInfo: WalletTitleInfo) async -> UIMenuElement {
        let wallet = walletTitleInfo.wallet
        let title = getTitleFor(wallet: wallet)
        var subtitle: String
        if wallet.rrDomain == nil {
            subtitle = String.Constants.messagingSetPrimaryDomain.localized()
        } else {
            subtitle = wallet.displayName
            if let number = walletTitleInfo.numberOfUnreadMessages,
               number > 0 {
                subtitle = String.Constants.newMessage.localized() + " · " + subtitle
            }
        }
        
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
    
    func getAvatarImageFor(wallet: WalletEntity) async -> UIImage {
        if let rrDomain = wallet.rrDomain,
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
        setupActivityIndicator()
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
    
    func setupActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.transform = .identity.scaledBy(x: activityScale, y: activityScale)
        addSubview(activityIndicator)
    }
}

// MARK: - Open methods
extension ChatsListNavigationView {
    struct Configuration {
        let selectedWallet: WalletEntity
        let wallets: [WalletTitleInfo]
        let isLoading: Bool
        
    }

    struct WalletTitleInfo {
        let wallet: WalletEntity
        let numberOfUnreadMessages: Int?
    }
}

@available (iOS 17.0, *)
#Preview {
    let view =  ChatsListNavigationView(frame: CGRect(x: 0, y: 0, width: 390, height: 40))
    let wallets = MockEntitiesFabric.Wallet.mockEntities()
    let wallet = wallets[0]
    let wallet2 = wallets[1]
    view.setWithConfiguration(.init(selectedWallet: wallet,
                                    wallets: [.init(wallet: wallet, numberOfUnreadMessages: nil),
                                              .init(wallet: wallet2, numberOfUnreadMessages: 0)],
                                    isLoading: false))
    return view 
}
