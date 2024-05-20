//
//  PullUpViewServic+ExternalWallets.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.10.2023.
//

import UIKit 

// MARK: - Open methods
extension PullUpViewService {
    func showConnectedWalletInfoPullUp(in viewController: UIViewController) {
        let selectionViewHeight: CGFloat = 352
        let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.connectWalletExternal.localized()),
                                                                     contentAlignment: .center,
                                                                     icon: .init(icon: .externalWalletIndicator,
                                                                                 size: .small),
                                                                     subtitle: .label(.text(String.Constants.importConnectedWalletDescription.localized())),
                                                                     cancelButton: .gotItButton()),
                                                items: PullUpSelectionViewEmptyItem.allCases)
        
        showOrUpdate(in: viewController, pullUp: .connectedExternalWalletInfo, contentView: selectionView, height: selectionViewHeight)
    }
    
    func showWCRequestConfirmationPullUp(for connectionConfig: WCRequestUIConfiguration,
                                             in viewController: UIViewController) async throws -> WalletConnectServiceV2.ConnectionUISettings {
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let signTransactionView: BaseSignTransactionView
            let selectionViewHeight: CGFloat
            let pullUp: Analytics.PullUp
            let connectionConfiguration: WalletConnectServiceV2.ConnectionConfig
            let viewFrame: CGRect = UIScreen.main.bounds
            
            switch connectionConfig {
            case .signMessage(let configuration):
                let signMessageConfirmationView = SignMessageRequestConfirmationView(frame: viewFrame)
                signMessageConfirmationView.configureWith(configuration)
                selectionViewHeight = signMessageConfirmationView.requiredHeight()
                signTransactionView = signMessageConfirmationView
                pullUp = .wcRequestSignMessageConfirmation
                connectionConfiguration = configuration.connectionConfig
            case .payment(let configuration):
                let signPaymentConfirmationView = PaymentTransactionRequestConfirmationView(frame: viewFrame)
                signPaymentConfirmationView.configureWith(configuration)
                selectionViewHeight = configuration.isGasFeeOnlyTransaction ? 512 : 564
                signTransactionView = signPaymentConfirmationView
                pullUp = .wcRequestTransactionConfirmation
                connectionConfiguration = configuration.connectionConfig
            case .connectWallet(let connectionConfig):
                let connectServerConfirmationView = ConnectServerRequestConfirmationView(frame: viewFrame)
                connectServerConfirmationView.setWith(connectionConfig: connectionConfig)
                selectionViewHeight = 376
                signTransactionView = connectServerConfirmationView
                pullUp = .wcRequestConnectConfirmation
                connectionConfiguration = connectionConfig
            }
            
            signTransactionView.setRequireSA(connectionConfig.isSARequired)
            signTransactionView.pullUp = pullUp
            
            let chainIds = connectionConfiguration.appInfo.getChainIds().map({ String($0) }).joined(separator: ",")
            let analyticParameters: Analytics.EventParameters = [.wcAppName: connectionConfiguration.appInfo.getDappName(),
                                                                 .hostURL: connectionConfiguration.appInfo.getDappHostName(),
                                                                 .chainId: chainIds]
            
            let pullUpView = showOrUpdate(in: viewController,
                                          pullUp: pullUp,
                                          additionalAnalyticParameters: analyticParameters,
                                          contentView: signTransactionView,
                                          height: selectionViewHeight,
                                          closedCallback: {
                completion(.failure(PullUpError.dismissed))
            })
            
            signTransactionView.confirmationCallback = { [weak pullUpView] connectionSettings in
                guard let pullUpView = pullUpView else { return }
                
                Task {
                    if connectionConfig.isSARequired {
                        do {
                            try await self.authentificationService.verifyWith(uiHandler: pullUpView, purpose: .confirm)
                            completion(.success(connectionSettings))
                        }
                    } else {
                        completion(.success(connectionSettings))
                    }
                }
            }
            
            signTransactionView.walletButtonCallback = { [weak pullUpView] wallet in
                Task {
                    do {
                        guard let pullUpView = pullUpView else { return }
                        
                        UDRouter().showProfileSelectionScreen(selectedWallet: wallet,
                                                              in: pullUpView)
                    }
                }
            }
            
            if case .payment = connectionConfig,
               !UserDefaults.wcFriendlyReminderShown {
                UserDefaults.wcFriendlyReminderShown = true
                showWCFriendlyReminderPullUp(in: pullUpView)
            }
        }
    }
    
    func showConnectingAppVerifiedPullUp(in viewController: UIViewController) {
        let selectionViewHeight: CGFloat = 304
        let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.walletVerifiedInfoTitle.localized()),
                                                                     contentAlignment: .center,
                                                                     icon: .init(icon: .checkBadge,
                                                                                 size: .small),
                                                                     subtitle: .label(.text(String.Constants.walletVerifiedInfoDescription.localized())),
                                                                     cancelButton: .gotItButton()),
                                                items: PullUpSelectionViewEmptyItem.allCases)
        
        showOrUpdate(in: viewController, pullUp: .wcAppVerifiedInfo, contentView: selectionView, height: selectionViewHeight)
    }
    
    func showGasFeeInfoPullUp(in viewController: UIViewController, for network: BlockchainType) {
        let selectionViewHeight: CGFloat = 304
        let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.networkGasFeeInfoTitle.localized(network.fullName)),
                                                                     contentAlignment: .center,
                                                                     icon: .init(icon: .gasFeeIcon,
                                                                                 size: .small),
                                                                     subtitle: .label(.text(String.Constants.networkGasFeeInfoDescription.localized(network.fullName, network.fullName))),
                                                                     cancelButton: .gotItButton()),
                                                items: PullUpSelectionViewEmptyItem.allCases)
        
        presentPullUpView(in: viewController, pullUp: .wcETHGasFeeInfo, contentView: selectionView, isDismissAble: true, height: selectionViewHeight)
        
    }
    
    func showNetworkNotSupportedPullUp(in viewController: UIViewController) async {
        await withSafeCheckedMainActorContinuation(critical: false) { completion in
            let selectionViewHeight: CGFloat = 304
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.networkNotSupportedInfoTitle.localized()),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .grimaseIcon,
                                                                                     size: .small),
                                                                         subtitle: .label(.text(String.Constants.networkNotSupportedInfoDescription.localized())),
                                                                         cancelButton: .gotItButton()),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            showOrUpdate(in: viewController, pullUp: .wcNetworkNotSupported, contentView: selectionView, height: selectionViewHeight, closedCallback: { completion(Void()) })
        }
    }
    
    func showWCRequestNotSupportedPullUp(in viewController: UIViewController) async {
        await withSafeCheckedMainActorContinuation(critical: false) { completion in
            let selectionViewHeight: CGFloat = 280
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.wcRequestNotSupportedInfoTitle.localized()),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .grimaseIcon,
                                                                                     size: .small),
                                                                         subtitle: .label(.text(String.Constants.wcRequestNotSupportedInfoDescription.localized())),
                                                                         cancelButton: .gotItButton()),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            showOrUpdate(in: viewController, pullUp: .wcRequestNotSupported, contentView: selectionView, height: selectionViewHeight, closedCallback: { completion(Void()) })
        }
    }
    
    func showWCConnectionFailedPullUp(in viewController: UIViewController) async {
        await withSafeCheckedMainActorContinuation(critical: false) { completion in
            let selectionViewHeight: CGFloat = 280
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.signTransactionFailedAlertTitle.localized()),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .grimaseIcon,
                                                                                     size: .small),
                                                                         subtitle: .label(.text(String.Constants.signTransactionFailedAlertDescription.localized())),
                                                                         cancelButton: .gotItButton()),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            showOrUpdate(in: viewController, pullUp: .wcConnectionFailed, contentView: selectionView, height: selectionViewHeight, closedCallback: { completion(Void()) })
        }
    }
    
    func showWCTransactionFailedPullUp(in viewController: UIViewController) async {
        await withSafeCheckedMainActorContinuation(critical: false) { completion in
            let selectionViewHeight: CGFloat = 280
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.transactionFailed.localized()),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .cancelCircleIcon,
                                                                                     size: .small),
                                                                         subtitle: .label(.text(String.Constants.signTransactionFailedAlertDescription.localized())),
                                                                         cancelButton: .gotItButton()),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            showOrUpdate(in: viewController, pullUp: .wcTransactionFailed, contentView: selectionView, height: selectionViewHeight, closedCallback: { completion(Void()) })
        }
    }
    
    func showWCInvalidQRCodePullUp(in viewController: UIViewController) async {
        await withSafeCheckedMainActorContinuation(critical: false) { completion in
            let selectionViewHeight: CGFloat = 280
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.walletConnectInvalidQRCodeAlertTitle.localized()),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .cancelCircleIcon,
                                                                                     size: .small),
                                                                         subtitle: .label(.text(String.Constants.walletConnectInvalidQRCodeAlertDescription.localized())),
                                                                         cancelButton: .gotItButton()),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            showOrUpdate(in: viewController, pullUp: .wcInvalidQRCode, contentView: selectionView, height: selectionViewHeight, closedCallback: { completion(Void()) })
        }
    }
    
    func showWCLowBalancePullUp(in viewController: UIViewController) async {
        await withSafeCheckedMainActorContinuation(critical: false) { completion in
            let selectionViewHeight: CGFloat = 280
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.insufficientBalance.localized()),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .cancelCircleIcon,
                                                                                     size: .small),
                                                                         subtitle: .label(.text(String.Constants.walletConnectLowBalanceAlertDescription.localized())),
                                                                         cancelButton: .gotItButton()),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            showOrUpdate(in: viewController, pullUp: .wcLowBalance, contentView: selectionView, height: selectionViewHeight, closedCallback: { completion(Void()) })
        }
    }
    
    func showWCFriendlyReminderPullUp(in viewController: UIViewController) {
        let selectionViewHeight: CGFloat = 304
        let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.wcFriendlyReminderTitle.localized()),
                                                                     contentAlignment: .center,
                                                                     icon: .init(icon: .smileIcon,
                                                                                 size: .small),
                                                                     subtitle: .label(.text(String.Constants.wcFriendlyReminderMessage.localized())),
                                                                     cancelButton: .gotItButton()),
                                                items: PullUpSelectionViewEmptyItem.allCases)
        
        presentPullUpView(in: viewController, pullUp: .wcFriendlyReminder, contentView: selectionView, isDismissAble: true, height: selectionViewHeight)
    }
    
    func showExternalWalletDisconnected(from walletDisplayInfo: WalletDisplayInfo, in viewController: UIViewController) async -> Bool {
        var providerName: String = ""
        var icon: UIImage = .init()
        switch walletDisplayInfo.source {
        case .external(let name, let make):
            providerName = name
            icon = make.icon
        default:
            Debugger.printFailure("Showing disconnected pull-up for not external wallet", critical: true)
        }
        let walletAddress = walletDisplayInfo.address.walletAddressTruncated
        let title = String.Constants.wcExternalWalletDisconnectedMessage.localized(walletAddress, providerName)
        
        return await withSafeCheckedMainActorContinuation(critical: false) { completion in
            let selectionViewHeight: CGFloat = 356
            let selectionView = PullUpSelectionView(configuration: .init(title: .highlightedText(.init(text: title,
                                                                                                       highlightedText: [.init(highlightedText: walletAddress,
                                                                                                                               highlightedColor: .foregroundSecondary)],
                                                                                                       analyticsActionName: nil,
                                                                                                       action: nil)),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: icon,
                                                                                     size: .large),
                                                                         // TODO: - set title, icon, analytics name
                                                                         actionButton: .main(content: .init(title: "Reconnect",
                                                                                                            icon: .appleIcon,
                                                                                                            analyticsName: .domainRecord,
                                                                                                            action: { completion(true) })),
                                                                         cancelButton: .gotItButton()),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            showOrUpdate(in: viewController, pullUp: .externalWalletDisconnected, contentView: selectionView, height: selectionViewHeight, closedCallback: { completion(false) })
        }
    }
    
    func showSwitchExternalWalletConfirmation(from walletDisplayInfo: WalletDisplayInfo, in viewController: UIViewController) async throws {
        var providerName: String = ""
        var icon: UIImage = .init()
        switch walletDisplayInfo.source {
        case .external(let name, let make):
            providerName = name
            icon = make.icon
        default:
            Debugger.printFailure("Showing disconnected pull-up for not external wallet", critical: true)
        }
        let title = String.Constants.wcSwitchToExternalWalletTitle.localized(providerName)
        let subtitle = String.Constants.wcSwitchToExternalWalletMessage.localized()
        let buttonTitle = String.Constants.wcSwitchToExternalWalletOpen.localized(providerName)
        
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionViewHeight: CGFloat = 384
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(title),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: icon,
                                                                                     size: .large),
                                                                         subtitle: .label(.text(subtitle)),
                                                                         actionButton: .main(content: .init(title: buttonTitle,
                                                                                                            icon: nil,
                                                                                                            analyticsName: .confirm,
                                                                                                            action: { completion(.success(Void()))
                
            })),
                                                                         cancelButton: .cancelButton),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            showOrUpdate(in: viewController, pullUp: .switchExternalWalletConfirmation, contentView: selectionView, height: selectionViewHeight, closedCallback: { completion(.failure(PullUpError.dismissed)) })
        }
    }
    
    func showConnectedAppNetworksInfoPullUp(in viewController: UIViewController) {
        let selectionViewHeight: CGFloat = 292
        
        let illustration = buildImageViewWith(image: .connectedAppNetworksInfoIllustration,
                                              width: 358,
                                              height: 64)
        
        let selectionView = PullUpSelectionView(configuration: .init(customHeader: illustration,
                                                                     title: .text(String.Constants.connectedAppNetworksInfoInfoTitle.localized()),
                                                                     contentAlignment: .center,
                                                                     cancelButton: .gotItButton()),
                                                items: PullUpSelectionViewEmptyItem.allCases)
        
        presentPullUpView(in: viewController, pullUp: .connectedAppNetworksInfo, contentView: selectionView, isDismissAble: true, height: selectionViewHeight)
    }
    
    func showConnectedAppDomainInfoPullUp(for domain: DomainDisplayInfo,
                                          connectedApp: any UnifiedConnectAppInfoProtocol,
                                          in viewController: UIViewController) async {
        let selectionViewHeight: CGFloat = 296
        
        let avatarImage = await appContext.imageLoadingService.loadImage(from: .domainItemOrInitials(domain,
                                                                                                     size: .default),
                                                                         downsampleDescription: .icon) ?? .init()
        let domainImageView = buildImageViewWith(image: avatarImage.circleCroppedImage(size: 56),
                                                 width: 56,
                                                 height: 56)
        
        let connectedAppImageBackgroundView = buildImageViewWith(image: avatarImage,
                                                                 width: 20,
                                                                 height: 20)
        connectedAppImageBackgroundView.image = nil
        connectedAppImageBackgroundView.clipsToBounds = true
        connectedAppImageBackgroundView.layer.cornerRadius = 8
        let connectedAppImageView = buildImageViewWith(image: avatarImage,
                                                       width: 20,
                                                       height: 20)
        
        let icon = await appContext.imageLoadingService.loadImage(from: .connectedApp(connectedApp, size: .default), downsampleDescription: .mid)
        if connectedApp.appIconUrls.isEmpty {
            connectedAppImageBackgroundView.backgroundColor = .clear
        } else {
            let color = await ConnectedAppsImageCache.shared.colorForApp(connectedApp)
            connectedAppImageBackgroundView.backgroundColor = (color ?? .brandWhite)
        }
        connectedAppImageView.image = icon
        
        connectedAppImageBackgroundView.addSubview(connectedAppImageView)
        connectedAppImageView.centerXAnchor.constraint(equalTo: connectedAppImageBackgroundView.centerXAnchor).isActive = true
        connectedAppImageView.centerYAnchor.constraint(equalTo: connectedAppImageBackgroundView.centerYAnchor).isActive = true
        
        domainImageView.addSubview(connectedAppImageBackgroundView)
        connectedAppImageBackgroundView.trailingAnchor.constraint(equalTo: domainImageView.trailingAnchor).isActive = true
        connectedAppImageBackgroundView.bottomAnchor.constraint(equalTo: domainImageView.bottomAnchor).isActive = true
        
        
        let title = String.Constants.connectedAppDomainInfoTitle.localized(domain.name, connectedApp.displayName)
        var subtitle: String?
        if let connectionDate = connectedApp.connectionStartDate {
            let formattedDate = DateFormattingService.shared.formatRecentActivityDate(connectionDate)
            subtitle = String.Constants.connectedAppDomainInfoSubtitle.localized(formattedDate)
        }
        
        let selectionView = PullUpSelectionView(configuration: .init(customHeader: domainImageView,
                                                                     title: .text(title),
                                                                     contentAlignment: .center,
                                                                     subtitle: subtitle == nil ? nil : .label(.text(subtitle ?? "")),
                                                                     cancelButton: .gotItButton()),
                                                items: PullUpSelectionViewEmptyItem.allCases)
        
        presentPullUpView(in: viewController, pullUp: .connectedAppDomainInfo, additionalAnalyticParameters: [.domainName: domain.name, .wcAppName: connectedApp.appName], contentView: selectionView, isDismissAble: true, height: selectionViewHeight)
    }
    
    func showExternalWalletConnectionHintPullUp(for walletRecord: WCWalletsProvider.WalletRecord,
                                                in viewController: UIViewController) async {
        await withSafeCheckedMainActorContinuation(critical: false) { completion in
            
            let selectionViewHeight: CGFloat = 358
            let walletName = walletRecord.name
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.externalWalletConnectionHintPullUpTitle.localized(walletName)),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .externalWalletIndicator,
                                                                                     size: .large),
                                                                         subtitle: .label(.highlightedText(.init(text: String.Constants.externalWalletConnectionHintPullUpSubtitle.localized(walletName),
                                                                                                                 highlightedText: [.init(highlightedText: String.Constants.learnMore.localized(),
                                                                                                                                         highlightedColor: .foregroundAccent)],
                                                                                                                 analyticsActionName: .learnMore,
                                                                                                                 action: { [weak viewController] in
                guard let viewController else { return }
                UDVibration.buttonTap.vibrate()
                viewController.topVisibleViewController().openLink(.udExternalWalletTutorial)
            }))),
                                                                         cancelButton: .gotItButton()),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            presentPullUpView(in: viewController, pullUp: .externalWalletConnectionHint, contentView: selectionView, isDismissAble: true, height: selectionViewHeight, closedCallback: { completion(Void()) })
        }
    }
    
    func showExternalWalletFailedToSignPullUp(in viewController: UIViewController) async {
        await withSafeCheckedMainActorContinuation(critical: false) { completion in
            let selectionViewHeight: CGFloat = 304
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.externalWalletFailedToSignPullUpTitle.localized()),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .grimaseIcon,
                                                                                     size: .small),
                                                                         subtitle: .label(.text(String.Constants.externalWalletFailedToSignPullUpSubtitle.localized())),
                                                                         cancelButton: .gotItButton()),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            showOrUpdate(in: viewController, pullUp: .externalWalletFailedToSign, contentView: selectionView, height: selectionViewHeight, closedCallback: { completion(Void()) })
        }
    }
    
}
