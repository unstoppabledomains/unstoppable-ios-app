//
//  BaseSignTransactionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.06.2022.
//

import Foundation
import UIKit

@MainActor
class BaseSignTransactionView: UIView, SelfNameable, NibInstantiateable {
    
    @IBOutlet var containerView: UIView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet private(set) weak var contentStackView: UIStackView!
    @IBOutlet private weak var appImageBackgroundView: UIView!
    @IBOutlet private weak var appImageView: UIImageView!
    @IBOutlet private weak var appHostButton: TextButton!
    @IBOutlet private(set) weak var cancelButton: TertiaryButton!
    @IBOutlet private(set) weak var confirmButton: MainButton!
    
    private var walletImageView: UIImageView?
    private var walletNameButton: SelectorButton?
    private var wallet: WalletEntity?
    private var appInfo: WalletConnectServiceV2.WCServiceAppInfo?
    var network: BlockchainType?
    var pullUp: Analytics.PullUp = .unspecified
    
    var confirmButtonTitle: String { String.Constants.confirm.localized() }
    
    var confirmationCallback: ((WalletConnectServiceV2.ConnectionUISettings)->())?
    var walletButtonCallback: ((WalletEntity)->())?

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
    func additionalSetup() { }
    
    func buildWalletInfoView() -> UIStackView {
        let imageSize: CGFloat = 20
        let walletImageView = UIImageView()
        walletImageView.translatesAutoresizingMaskIntoConstraints = false
        walletImageView.clipsToBounds = true
        walletImageView.layer.cornerRadius = imageSize / 2
        walletImageView.heightAnchor.constraint(equalToConstant: imageSize).isActive = true
        walletImageView.widthAnchor.constraint(equalTo: walletImageView.heightAnchor, multiplier: 1).isActive = true

        let walletNameButton = SelectorButton()
        walletNameButton.customTitleEdgePadding = 0
        walletNameButton.translatesAutoresizingMaskIntoConstraints = false
        walletNameButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
        walletNameButton.addTarget(self, action: #selector(walletButtonPressed), for: .touchUpInside)
        
        self.walletImageView = walletImageView
        self.walletNameButton = walletNameButton
        
        let walletInfoStack = UIStackView(arrangedSubviews: [walletImageView, walletNameButton])
        walletInfoStack.axis = .horizontal
        walletInfoStack.spacing = -2
        walletInfoStack.alignment = .center

        let walletLabel = UILabel()
        walletLabel.translatesAutoresizingMaskIntoConstraints = false
        walletLabel.setAttributedTextWith(text: String.Constants.profile.localized(),
                                          font: .currentFont(withSize: 14, weight: .medium),
                                          textColor: .foregroundSecondary)
        
        let stack = UIStackView(arrangedSubviews: [walletLabel, walletInfoStack])
        stack.spacing = 16
        stack.alignment = .center

        return stack
    }
}

// MARK: - Open methods
extension BaseSignTransactionView {
    func setRequireSA(_ isRequired: Bool) {
        if isRequired {
            var icon: UIImage?
            if User.instance.getSettings().touchIdActivated {
                icon = appContext.authentificationService.biometricIcon
            }
            confirmButton.setTitle(confirmButtonTitle, image: icon)
        } else {
            confirmButton.setTitle(confirmButtonTitle, image: nil)
        }
        cancelButton.setTitle(String.Constants.cancel.localized(), image: nil)
    }
    
    func setWith(appInfo: WalletConnectServiceV2.WCServiceAppInfo) {
        self.appInfo = appInfo
        Task {
            let icon: UIImage? = await appContext.imageLoadingService.loadImage(from: .wcApp(appInfo, size: .default),
                                                                      downsampleDescription: nil)
            appImageView.image = icon
            if appInfo.getIconURL() == nil {
                appImageBackgroundView.isHidden = true
            } else {
                appImageBackgroundView.isHidden = false
                let color: UIColor? = await icon?.getColors()?.background
                appImageBackgroundView.backgroundColor = (color ?? .brandWhite)
            }
        }
         
        appImageView.layer.borderColor = UIColor.borderSubtle.cgColor
        appImageView.layer.borderWidth = 1
        appHostButton.setTitle(appInfo.getDappHostDisplayName(),
                               image: appInfo.isTrusted ? .checkBadge : nil)
    }
    
    func setNetworkFrom(appInfo: WalletConnectServiceV2.WCServiceAppInfo) {
        self.network = getChainFromAppInfo(appInfo)
    }
    
    func getChainFromAppInfo(_ appInfo: WalletConnectServiceV2.WCServiceAppInfo) -> BlockchainType {
        let appBlockchainTypes = appInfo.getChainIds().compactMap({ (try? UnsConfigManager.getBlockchainType(from: $0)) })
        
        if appBlockchainTypes.contains(.Ethereum) {
            return .Ethereum
        } else if appBlockchainTypes.contains(.Matic) {
            return .Matic
        }
        return appBlockchainTypes.first ?? .Ethereum
    }
    
    func setWalletInfo(_ wallet: WalletEntity, isSelectable: Bool) {
        self.wallet = wallet
        if let walletImageView {
            Task {
                if let domainDisplayInfo = wallet.rrDomain {
                    walletImageView.image = await appContext.imageLoadingService.loadImage(from: .domainInitials(domainDisplayInfo, size: .full),
                                                                                           downsampleDescription: nil)
                    let image = await appContext.imageLoadingService.loadImage(from: .domainItemOrInitials(domainDisplayInfo, size: .full),
                                                                               downsampleDescription: .icon)
                    walletImageView.image = image
                }
                walletImageView.isHidden = wallet.rrDomain == nil
            }
        }
        walletNameButton?.setTitle(wallet.domainOrDisplayName, image: isSelectable ? .chevronDown : nil)
        walletNameButton?.setSelectorEnabled(isSelectable)
    }
    
    func logAnalytic(event: Analytics.Event, parameters: Analytics.EventParameters = [:]) {
        if pullUp == .unspecified {
            Debugger.printFailure("Did not specify analytics pull up property", critical: true)
        }
        if appInfo == nil {
            Debugger.printFailure("Did not provide app info", critical: true)
        }
        let wcAppName = appInfo?.getDappName() ?? "n/a"
        let hostName = appInfo?.getDappHostName() ?? "n/a"
        let wallet = wallet?.address ?? "n/a"
        var analyticParameters: Analytics.EventParameters = [.pullUpName: pullUp.rawValue,
                                                             .wcAppName: wcAppName,
                                                             .hostURL: hostName,
                                                             .wallet: wallet]
        if let chainId = appInfo?.getChainIds().first {
            analyticParameters[.chainId] = String(chainId)
        }
        appContext.analyticsService.log(event: event,
                                        withParameters: analyticParameters.adding(parameters))
    }
    
    func logButtonPressed(_ button: Analytics.Button, parameters: Analytics.EventParameters = [:]) {
        logAnalytic(event: .buttonPressed,
                    parameters: [.button: button.rawValue])
    }
}

// MARK: - Actions
private extension BaseSignTransactionView {
    @IBAction func cancelButtonPressed(_ sender: Any) {
        logButtonPressed(.cancel)
        pullUpView?.cancel()
        findViewController()?.dismiss(animated: true)
    }
    
    @IBAction func confirmButtonPressed(_ sender: Any) {
        logButtonPressed(.confirm)
        guard let wallet = self.wallet else {
            Debugger.printFailure("Invalid wallet: nil", critical: true)
            return }
        guard let network = self.network else {
            Debugger.printFailure("Invalid Network: nil", critical: true)
            return }
        
        confirmationCallback?(.init(wallet: wallet,
                                    blockchainType: network))
    }
    
    
    @IBAction func appNameButtonPressed(_ sender: Any) {
        logButtonPressed(.wcDAppName)
        if let viewController = findViewController() {
            appContext.pullUpViewService.showConnectingAppVerifiedPullUp(in: viewController)
        }
    }
    
    @objc func walletButtonPressed() {
        logButtonPressed(.wcWallet)
        guard let wallet = self.wallet else { return }
        
        walletButtonCallback?(wallet)
    }
}

// MARK: - Private methods
private extension BaseSignTransactionView {
    var pullUpView: PullUpView? {
        var view: UIView? = superview
        while view != nil {
            if view is PullUpView {
                break
            }
            view = view?.superview
        }
        return view as? PullUpView
    }
}

// MARK: - Setup methods
private extension BaseSignTransactionView {
    func setup() {
        commonViewInit(nibName: "BaseSignTransactionView")
        backgroundColor = .backgroundDefault
        localizeContent()
        additionalSetup()
        appHostButton.isUserInteractionEnabled = false // Disable it for now
    }
    
    func localizeContent() {
        cancelButton.setTitle(String.Constants.cancel.localized(), image: nil)
    }
}
