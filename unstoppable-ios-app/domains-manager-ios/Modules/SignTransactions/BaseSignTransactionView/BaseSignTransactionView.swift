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
    
    private var domainImageView: UIImageView?
    private var domainNameButton: SelectorButton?
    private var domain: DomainItem?
    private var appInfo: WalletConnectServiceV2.WCServiceAppInfo?
    var network: BlockchainType?
    var pullUp: Analytics.PullUp = .unspecified
    
    var confirmButtonTitle: String { String.Constants.confirm.localized() }
    
    var confirmationCallback: ((WalletConnectServiceV2.ConnectionUISettings)->())?
    var domainButtonCallback: ((DomainItem)->())?

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
    func additionalSetup() { }
    
    func buildDomainInfoView() -> UIStackView {
        let imageSize: CGFloat = 20
        let domainImageView = UIImageView()
        domainImageView.translatesAutoresizingMaskIntoConstraints = false
        domainImageView.clipsToBounds = true
        domainImageView.layer.cornerRadius = imageSize / 2
        domainImageView.heightAnchor.constraint(equalToConstant: imageSize).isActive = true
        domainImageView.widthAnchor.constraint(equalTo: domainImageView.heightAnchor, multiplier: 1).isActive = true

        let domainNameButton = SelectorButton()
        domainNameButton.customTitleEdgePadding = 0
        domainNameButton.translatesAutoresizingMaskIntoConstraints = false
        domainNameButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
        domainNameButton.addTarget(self, action: #selector(domainButtonPressed), for: .touchUpInside)
        
        self.domainImageView = domainImageView
        self.domainNameButton = domainNameButton
        
        let domainInfoStack = UIStackView(arrangedSubviews: [domainImageView, domainNameButton])
        domainInfoStack.axis = .horizontal
        domainInfoStack.spacing = 8
        domainInfoStack.alignment = .center

        let domainLabel = UILabel()
        domainLabel.translatesAutoresizingMaskIntoConstraints = false
        domainLabel.setAttributedTextWith(text: String.Constants.domain.localized(),
                                          font: .currentFont(withSize: 14, weight: .medium),
                                          textColor: .foregroundSecondary)
        
        let stack = UIStackView(arrangedSubviews: [domainLabel, domainInfoStack])
        
        return stack
    }
}

// MARK: - Open methods
extension BaseSignTransactionView {
    func setRequireSA(_ isRequired: Bool) {
        if isRequired {
            var icon: UIImage?
            if User.instance.getSettings().touchIdActivated {
                icon = appContext.authentificationService.biometricType == .faceID ? .faceIdIcon : .touchIdIcon
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
            let icon = await appContext.imageLoadingService.loadImage(from: .wcApp(appInfo, size: .default), downsampleDescription: nil)
            appImageView.image = icon
            if appInfo.getIconURL() == nil {
                appImageBackgroundView.isHidden = true
            } else {
                appImageBackgroundView.isHidden = false
                let color = await icon?.getColors()?.background
                appImageBackgroundView.backgroundColor = (color ?? .brandWhite)
            }
        }
         
        appImageView.layer.borderColor = UIColor.borderSubtle.cgColor
        appImageView.layer.borderWidth = 1
        appHostButton.setTitle(appInfo.getDappHostDisplayName(),
                               image: appInfo.isTrusted ? .checkBadge : nil)
    }
    
    func setNetworkFrom(appInfo: WalletConnectServiceV2.WCServiceAppInfo, domain: DomainItem) {
        self.network = getChainFromAppInfo(appInfo, domain: domain)
    }
    
    func getChainFromAppInfo(_ appInfo: WalletConnectServiceV2.WCServiceAppInfo, domain: DomainItem) -> BlockchainType {
        let appBlockchainTypes = appInfo.getChainIds().compactMap({ (try? UnsConfigManager.getBlockchainType(from: $0)) })
        if let domainBlockchainType = appBlockchainTypes.first(where: { $0 == domain.getBlockchainType() }) {
            return domainBlockchainType
        }
        return appBlockchainTypes.first ?? .Ethereum
    }
    
    func setDomainInfo(_ domain: DomainItem, isSelectable: Bool) {
        self.domain = domain
        if let domainImageView {
            Task {
                let domainsDisplayInfo = await appContext.dataAggregatorService.getDomainsDisplayInfo()
                if let domainDisplayInfo = domainsDisplayInfo.first(where: { $0.name == domain.name }) {
                    domainImageView.image = await appContext.imageLoadingService.loadImage(from: .domainInitials(domainDisplayInfo, size: .full),
                                                                                           downsampleDescription: nil)
                    let image = await appContext.imageLoadingService.loadImage(from: .domainItemOrInitials(domainDisplayInfo, size: .full),
                                                                               downsampleDescription: nil)
                    domainImageView.image = image
                }
            }
        }
        domainNameButton?.setTitle(domain.name, image: isSelectable ? .chevronDown : nil)
        domainNameButton?.setSelectorEnabled(isSelectable)
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
        let domainName = domain?.name ?? "n/a"
        var analyticParameters: Analytics.EventParameters = [.pullUpName: pullUp.rawValue,
                                                             .wcAppName: wcAppName,
                                                             .hostURL: hostName,
                                                             .domainName: domainName]
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
    }
    
    @IBAction func confirmButtonPressed(_ sender: Any) {
        logButtonPressed(.confirm)
        guard let domain = self.domain else {
            Debugger.printFailure("Invalid DomainItem: nil", critical: true)
            return }
        guard let network = self.network else {
            Debugger.printFailure("Invalid Network: nil", critical: true)
            return }
        
        confirmationCallback?(.init(domain: domain,
                                    blockchainType: network))
    }
    
    
    @IBAction func appNameButtonPressed(_ sender: Any) {
        logButtonPressed(.wcDAppName)
        if let viewController = findViewController() {
            appContext.pullUpViewService.showConnectingAppVerifiedPullUp(in: viewController)
        }
    }
    
    @objc func domainButtonPressed() {
        logButtonPressed(.wcDomainName)
        guard let domain = self.domain else { return }
        
        domainButtonCallback?(domain)
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
