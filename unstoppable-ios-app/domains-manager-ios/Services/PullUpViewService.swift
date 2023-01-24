//
//  PullUpViewService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.05.2022.
//

import UIKit

@MainActor
protocol PullUpViewServiceProtocol {
    func showLegalSelectionPullUp(in viewController: UIViewController) async throws -> LegalType
    func showAddWalletSelectionPullUp(in viewController: UIViewController,
                                      actions: [WalletDetailsAddWalletAction]) async throws -> WalletDetailsAddWalletAction
    func showManageBackupsSelectionPullUp(in viewController: UIViewController) async throws -> ManageBackupsAction
    func showDeleteAllICloudBackupsPullUp(in viewController: UIViewController) async throws
    func showRestoreFromICloudBackupSelectionPullUp(in viewController: UIViewController,
                                                    backups: [ICloudBackupDisplayInfo]) async throws -> ICloudBackupDisplayInfo
    func showWalletTransactionsSelectionPullUp(in viewController: UIViewController,
                                               walletInfo: WalletDisplayInfo,
                                               isZilSupported: Bool,
                                               canViewWallet: Bool,
                                               transactionSelectedCallback: @escaping (WalletViewTransactionsAction)->(),
                                               copyButtonPressedCallback: @escaping EmptyCallback,
                                               viewWalletCallback: EmptyCallback?)
    func showCopyWalletAddressSelectionPullUp(in viewController: UIViewController,
                                              wallet: UDWallet,
                                              transactionSelectedCallback: @escaping (WalletCopyAddressAction)->())
    func showRemoveWalletPullUp(in viewController: UIViewController,
                                walletInfo: WalletDisplayInfo) async throws
    func showConnectedWalletInfoPullUp(in viewController: UIViewController)
    func showAppearanceStyleSelectionPullUp(in viewController: UIViewController,
                                            selectedStyle: UIUserInterfaceStyle,
                                            styleChangedCallback: @escaping AppearanceStyleChangedCallback)
    func showManageDomainRouteCryptoPullUp(in viewController: UIViewController,
                                           numberOfCrypto: Int)
    func showDomainProfileChangesConfirmationPullUp(in viewController: UIViewController,
                                             changes: [DomainProfileSectionUIChangeType]) async throws
    func showDiscardRecordChangesConfirmationPullUp(in viewController: UIViewController) async throws
    func showPayGasFeeConfirmationPullUp(gasFeeInCents: Int,
                                         in viewController: UIViewController) async throws
    func showMintDomainConfirmationPullUp(in viewController: UIViewController) async throws -> MintDomainPullUpAction
    func showServerConnectConfirmationPullUp(for connectionConfig: WCRequestUIConfiguration, in viewController: UIViewController) async throws -> WalletConnectService.ConnectionUISettings
    func showConnectingAppVerifiedPullUp(in viewController: UIViewController)
    func showNetworkNotSupportedPullUp(in viewController: UIViewController)
    func showWCRequestNotSupportedPullUp(in viewController: UIViewController)
    func showGasFeeInfoPullUp(in viewController: UIViewController, for network: BlockchainType)
    func showWCConnectionFailedPullUp(in viewController: UIViewController)
    func showWCTransactionFailedPullUp(in viewController: UIViewController)
    func showWCInvalidQRCodePullUp(in viewController: UIViewController) async
    func showWCLowBalancePullUp(in viewController: UIViewController)
    func showYouAreOfflinePullUp(in viewController: UIViewController,
                                 unavailableFeature: PullUpViewService.UnavailableOfflineFeature) async
    func showShareDomainPullUp(domain: DomainDisplayInfo, qrCodeImage: UIImage, in viewController: UIViewController) async -> ShareDomainSelectionResult
    func showSaveDomainImageTypePullUp(description: SaveDomainImageDescription,
                                       in viewController: UIViewController) async throws -> SaveDomainSelectionResult
    func showZilDomainsNotSupportedPullUp(in viewController: UIViewController) async throws
    func showDomainTLDDeprecatedPullUp(tld: String,
                                       in viewController: UIViewController) async throws
    func showMintingNotAvailablePullUp(in viewController: UIViewController) async
    func showWCFriendlyReminderPullUp(in viewController: UIViewController)
    func showExternalWalletDisconnected(from walletDisplayInfo: WalletDisplayInfo, in viewController: UIViewController) async
    func showSwitchExternalWalletConfirmation(from walletDisplayInfo: WalletDisplayInfo, in viewController: UIViewController) async throws
    func showLoadingIndicator(in viewController: UIViewController)
    func showWhatIsReverseResolutionInfoPullUp(in viewController: UIViewController)
    func showSetupReverseResolutionPromptPullUp(walletInfo: WalletDisplayInfo,
                                                domain: DomainDisplayInfo,
                                                in viewController: UIViewController) async throws
    func showDomainMintedOnChainDescriptionPullUp(in viewController: UIViewController,
                                                  chain: BlockchainType)
    func showDomainProfileInfoPullUp(in viewController: UIViewController)
    func showBadgeInfoPullUp(in viewController: UIViewController, badgeDisplayInfo: DomainProfileViewController.DomainProfileBadgeDisplayInfo)
    func showImageTooLargeToUploadPullUp(in viewController: UIViewController) async throws
    func showSelectedImageBadPullUp(in viewController: UIViewController)
    func showAskToNotifyWhenRecordsUpdatedPullUp(in viewController: UIViewController) async throws
    func showWillNotifyWhenRecordsUpdatedPullUp(in viewController: UIViewController)
    func showFailedToFetchProfileDataPullUp(in viewController: UIViewController,
                                            isRefreshing: Bool,
                                            animatedTransition: Bool) async throws
    func showUpdateDomainProfileFailedPullUp(in viewController: UIViewController) async throws
    func showTryUpdateDomainProfileLaterPullUp(in viewController: UIViewController) async throws
    func showUpdateDomainProfileSomeChangesFailedPullUp(in viewController: UIViewController,
                                                        changes: [DomainProfileSectionUIChangeFailedItem]) async throws
    func showRefreshBadgesComingSoonPullUp(in viewController: UIViewController)
    func showShowcaseYourProfilePullUp(for domain: DomainDisplayInfo,
                                       in viewController: UIViewController) async throws
    func showDomainProfileAccessInfoPullUp(in viewController: UIViewController)
    func showRecentActivitiesInfoPullUp(in viewController: UIViewController) async throws
    func showConnectedAppNetworksInfoPullUp(in viewController: UIViewController)
    func showConnectedAppDomainInfoPullUp(for domain: DomainDisplayInfo,
                                          connectedApp: any UnifiedConnectAppInfoProtocol,
                                          in viewController: UIViewController) async
}

@MainActor
final class PullUpViewService {
    
    private let authentificationService: AuthentificationServiceProtocol
    
    nonisolated init(authentificationService: AuthentificationServiceProtocol) {
        self.authentificationService = authentificationService
    }
    
}

// MARK: - PullUpViewServiceProtocol
extension PullUpViewService: PullUpViewServiceProtocol {
    func showLegalSelectionPullUp(in viewController: UIViewController) async throws -> LegalType {
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { continuation in
            let selectionViewHeight: CGFloat = 276
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.settingsLegal.localized()),
                                                                         contentAlignment: .left),
                                                    items: LegalType.allCases,
                                                    itemSelectedCallback: { legalType in
                continuation(.success(legalType))
            })
            
            showOrUpdate(in: viewController, pullUp: .settingsLegalSelection, contentView: selectionView, height: selectionViewHeight, closedCallback: { continuation(.failure(PullUpError.dismissed)) })
        }
    }
    
    func showAddWalletSelectionPullUp(in viewController: UIViewController,
                                      actions: [WalletDetailsAddWalletAction]) async throws -> WalletDetailsAddWalletAction {
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { continuation in
            let selectionViewHeight: CGFloat = 72 + (CGFloat(actions.count) * PullUpCollectionViewCell.Height)
            let selectionView = PullUpSelectionView(configuration: .init(title: nil,
                                                                         contentAlignment: .left),
                                                    items: actions,
                                                    itemSelectedCallback: { action in
                continuation(.success(action))
            })
            
            showOrUpdate(in: viewController, pullUp: .addWalletSelection, contentView: selectionView, height: selectionViewHeight, closedCallback: { continuation(.failure(PullUpError.dismissed)) })
        }
    }
    
    func showManageBackupsSelectionPullUp(in viewController: UIViewController) async throws -> ManageBackupsAction {
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { continuation in
            let selectionViewHeight: CGFloat = 244
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.manageICloudBackups.localized()),
                                                                         contentAlignment: .left),
                                                    items: ManageBackupsAction.allCases,
                                                    itemSelectedCallback: { action in continuation(.success(action)) })
            
            showOrUpdate(in: viewController, pullUp: .manageBackupsSelection, contentView: selectionView, height: selectionViewHeight, closedCallback: { continuation(.failure(PullUpError.dismissed)) })
        }
    }
    
    func showDeleteAllICloudBackupsPullUp(in viewController: UIViewController) async throws {
        let selectionViewHeight: CGFloat = 340
        var icon: UIImage?
        if User.instance.getSettings().touchIdActivated {
            icon = authentificationService.biometricType == .faceID ? .faceIdIcon : .touchIdIcon
        }
        
        let title: String = String.Constants.deleteICloudBackupsConfirmationMessage.localized()
        let buttonTitle: String = String.Constants.deleteICloudBackups.localized()
        
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(title),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .warningIconLarge,
                                                                                     size: .small),
                                                                         actionButton: .primaryDanger(content: .init(title: buttonTitle,
                                                                                                                     icon: icon,
                                                                                                                     analyticsName: .delete,
                                                                                                                     action: { completion(.success(Void())) })),
                                                                         cancelButton: .cancelButton),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            showOrUpdate(in: viewController, pullUp: .deleteAllICloudBackupsConfirmation, contentView: selectionView, height: selectionViewHeight, closedCallback: { completion(.failure(PullUpError.dismissed)) })
        }
    }
    
    func showRestoreFromICloudBackupSelectionPullUp(in viewController: UIViewController,
                                                    backups: [ICloudBackupDisplayInfo]) async throws -> ICloudBackupDisplayInfo {
        let selectionViewHeight: CGFloat = 312 + (CGFloat(backups.count) * PullUpCollectionViewCell.Height)
        let title = String.Constants.restoreFromICloudBackup.localized()
        let subtitle = String.Constants.restoreFromICloudBackupDescription.localized()
        let highlightedSubtitle = String.Constants.learnMore.localized()

        return try await withSafeCheckedThrowingMainActorContinuation(critical: false) { continuation in
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(title),
                                                                         contentAlignment: .left,
                                                                         subtitle: .label(.highlightedText(.init(text: subtitle,
                                                                                                                 highlightedText: [.init(highlightedText: highlightedSubtitle,
                                                                                                                                         highlightedColor: .foregroundAccent)],
                                                                                                                 analyticsActionName: .restoreFromICloud,
                                                                                                                 action: { [weak viewController] in
                UDVibration.buttonTap.vibrate()
                viewController?.presentedViewController?.showInfoScreenWith(preset: .restoreFromICloudBackup)
            }))),
                                                                         cancelButton: .cancelButton),
                                                    items: backups,
                                                    itemSelectedCallback: { option in continuation(.success(option)) })
            
            showOrUpdate(in: viewController, pullUp: .restoreFromICloudBackupsSelection, contentView: selectionView, height: selectionViewHeight, closedCallback: { continuation(.failure(PullUpError.dismissed)) })
        }
    }
    
    func showWalletTransactionsSelectionPullUp(in viewController: UIViewController,
                                               walletInfo: WalletDisplayInfo,
                                               isZilSupported: Bool,
                                               canViewWallet: Bool,
                                               transactionSelectedCallback: @escaping (WalletViewTransactionsAction)->(),
                                               copyButtonPressedCallback: @escaping EmptyCallback,
                                               viewWalletCallback: EmptyCallback?) {
        let selectionViewHeight: CGFloat = canViewWallet ? 460 : 388
        let walletAddress = walletInfo.address.walletAddressTruncated
        let copyAddressTitle: String
        switch walletInfo.source {
        case .external:
            copyAddressTitle = String.Constants.copyAddress.localized()
        case .imported, .locallyGenerated:
            if walletInfo.isNameSet {
                copyAddressTitle = walletAddress
            } else {
                copyAddressTitle = String.Constants.copyAddress.localized()
            }
        }
        
        let iconBackground: UIColor = walletInfo.source == .imported ? .backgroundMuted2 : .brandUnstoppableBlue
        let iconSize: PullUpSelectionViewConfiguration.IconSize
        switch walletInfo.source {
        case .external, .locallyGenerated:
            iconSize = .large
        case .imported:
            iconSize = .largeCentered
        }
        
        let selectionView = PullUpSelectionView(configuration: .init(title: .text(walletInfo.displayName),
                                                                     contentAlignment: .center,
                                                                     icon: .init(icon: walletInfo.source.displayIcon,
                                                                                 size: iconSize,
                                                                                 corners: .circle,
                                                                                 backgroundColor: iconBackground,
                                                                                 tintColor: .foregroundDefault),
                                                                     subtitle: .button(.textTertiary(content: .init(title: copyAddressTitle,
                                                                                                                    icon: .copyToClipboardIcon,
                                                                                                                    imageLayout: .trailing,
                                                                                                                    analyticsName: .copyToClipboard,
                                                                                                                    action: copyButtonPressedCallback))),
                                                                     actionButton: canViewWallet ? .secondary(content: .init(title: String.Constants.viewWallet.localized(),
                                                                                                                             icon: nil,
                                                                                                                             analyticsName: .viewWallet,
                                                                                                                             action: {
            viewWalletCallback?()
        })) : nil),
                                                items: WalletViewTransactionsAction.allCases,
                                                itemSelectedCallback: transactionSelectedCallback)
        
        showOrUpdate(in: viewController, pullUp: .walletTransactionsSelection, contentView: selectionView, height: selectionViewHeight)
    }
    
    func showCopyWalletAddressSelectionPullUp(in viewController: UIViewController,
                                              wallet: UDWallet,
                                              transactionSelectedCallback: @escaping (WalletCopyAddressAction)->()) {
        let selectionViewHeight: CGFloat = 224
        let walletAddress: [WalletCopyAddressAction] = [.ethereum(address: wallet.getActiveAddress(for: .UNS) ?? ""),
                                                        .zil(address: wallet.getActiveAddress(for: .ZNS) ?? "")]
        
        let selectionView = PullUpSelectionView(configuration: .init(title: nil,
                                                                     contentAlignment: .left),
                                                items: walletAddress,
                                                itemSelectedCallback: transactionSelectedCallback)
        
        showOrUpdate(in: viewController, pullUp: .copyWalletAddressSelection, contentView: selectionView, height: selectionViewHeight)
    }
    
    func showRemoveWalletPullUp(in viewController: UIViewController,
                                walletInfo: WalletDisplayInfo) async throws {
        let selectionViewHeight: CGFloat
        let address = walletInfo.address.walletAddressTruncated
        var icon: UIImage?
        if User.instance.getSettings().touchIdActivated {
            icon = authentificationService.biometricType == .faceID ? .faceIdIcon : .touchIdIcon
        }
        
        let title: String
        var subtitle: String?
        let buttonTitle: String
        
        if !walletInfo.isConnected {
            selectionViewHeight = 420
            title = String.Constants.removeWalletAlertTitle.localized(walletInfo.walletSourceName.lowercased(), address)
            subtitle = walletInfo.isWithPrivateKey ? String.Constants.removeWalletAlertSubtitlePrivateKey.localized() : String.Constants.removeWalletAlertSubtitleRecoveryPhrase.localized()
            buttonTitle = String.Constants.removeWallet.localized(walletInfo.walletSourceName.lowercased())
        } else {
            selectionViewHeight = 368
            title = String.Constants.disconnectWalletAlertTitle.localized(address)
            subtitle = nil
            buttonTitle = String.Constants.disconnectWallet.localized()
        }
        
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionView = PullUpSelectionView(configuration: .init(title: .highlightedText(.init(text: title,
                                                                                                       highlightedText: [.init(highlightedText: address,
                                                                                                                               highlightedColor: .foregroundSecondary)],
                                                                                                       analyticsActionName: nil,
                                                                                                       action: nil)),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .warningIconLarge,
                                                                                     size: .small),
                                                                         subtitle: subtitle == nil ? nil : .label(.text(subtitle!)),
                                                                         actionButton: .primaryDanger(content: .init(title: buttonTitle,
                                                                                                                     icon: icon,
                                                                                                                     analyticsName: .walletRemove,
                                                                                                                     action: { completion(.success(Void())) })),
                                                                         cancelButton: .cancelButton),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            showOrUpdate(in: viewController, pullUp: .removeWalletConfirmation, contentView: selectionView, height: selectionViewHeight, closedCallback: { completion(.failure(PullUpError.dismissed)) })
        }
    }
    
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

    func showAppearanceStyleSelectionPullUp(in viewController: UIViewController,
                                            selectedStyle: UIUserInterfaceStyle,
                                            styleChangedCallback: @escaping AppearanceStyleChangedCallback) {
        var selectionViewHeight: CGFloat = 340
        switch deviceSize {
        case .i4Inch,
                .i4_7Inch,
                .i5_5Inch:
            selectionViewHeight = 320
        default:
            Void()
        }
        
        let contentView = SelectAppearanceThemePullUpView(appearanceStyle: selectedStyle)
        contentView.styleChangedCallback = styleChangedCallback
        showOrUpdate(in: viewController, pullUp: .themeSelection, contentView: contentView, height: selectionViewHeight)
    }
    
    func showManageDomainRouteCryptoPullUp(in viewController: UIViewController,
                                           numberOfCrypto: Int) {
        let selectionViewHeight: CGFloat = 304
        let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.manageDomainRouteCryptoHeader.localized()),
                                                                     contentAlignment: .center,
                                                                     icon: .init(icon: .walletBTCIcon,
                                                                                 size: .small),
                                                                     subtitle: .label(.text(String.Constants.manageDomainRouteCryptoDescription.localized())),
                                                                     cancelButton: .gotItButton()),
                                                items: PullUpSelectionViewEmptyItem.allCases)
        
        showOrUpdate(in: viewController, pullUp: .routeCryptoInfo, contentView: selectionView, height: selectionViewHeight)
    }
    
    func showDomainProfileChangesConfirmationPullUp(in viewController: UIViewController,
                                             changes: [DomainProfileSectionUIChangeType]) async throws {
        let selectionViewHeight: CGFloat = 268 + (CGFloat(changes.count) * PullUpCollectionViewCell.Height)

        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            var didFireContinuation = false
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.confirmUpdates.localized()),
                                                                         contentAlignment: .center,
                                                                         actionButton: .main(content: .init(title: String.Constants.update.localized(),
                                                                                                            icon: nil,
                                                                                                            analyticsName: .confirm,
                                                                                                            action: { completion(.success(Void())) })),
                                                                         cancelButton: .secondaryDanger(content: .init(title: String.Constants.discard.localized(),
                                                                                                                       icon: nil,
                                                                                                                       analyticsName: .cancel,
                                                                                                                       action: { didFireContinuation = true; completion(.failure(PullUpError.cancelled)) }))),
                                                    items: changes)
            
            showOrUpdate(in: viewController, pullUp: .domainRecordsChangesConfirmation, contentView: selectionView, height: selectionViewHeight, closedCallback: { if !didFireContinuation { completion(.failure(PullUpError.dismissed)) } })
        }
    }

    func showDiscardRecordChangesConfirmationPullUp(in viewController: UIViewController) async throws {
        let selectionViewHeight: CGFloat = 276
        
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.discardChangesConfirmationMessage.localized()),
                                                                         contentAlignment: .center,
                                                                         actionButton: .main(content: .init(title: String.Constants.discardChanges.localized(),
                                                                                                            icon: nil,
                                                                                                            analyticsName: .confirm,
                                                                                                            action: { completion(.success(Void())) })),
                                                                         cancelButton: .cancelButton),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            showOrUpdate(in: viewController, pullUp: .discardDomainRecordsChangesConfirmation, contentView: selectionView, height: selectionViewHeight, closedCallback: { completion(.failure(PullUpError.dismissed)) })
        }
    }
    
    func showPayGasFeeConfirmationPullUp(gasFeeInCents: Int,
                                         in viewController: UIViewController) async throws {
        let selectionViewHeight: CGFloat = 464
        let gasFeeLabel = UILabel()
        gasFeeLabel.translatesAutoresizingMaskIntoConstraints = false
        gasFeeLabel.setAttributedTextWith(text: String.Constants.gasFee.localized(),
                                          font: .currentFont(withSize: 16, weight: .medium),
                                          textColor: .foregroundSecondary)
        let gasFeeValueLabel = UILabel()
        gasFeeValueLabel.translatesAutoresizingMaskIntoConstraints = false
        let gasFeeString = String(format: "$%.02f", PaymentConfiguration.centsIntoDollars(cents: gasFeeInCents))
        gasFeeValueLabel.setAttributedTextWith(text: gasFeeString,
                                          font: .currentFont(withSize: 16, weight: .medium),
                                          textColor: .foregroundDefault)
        gasFeeValueLabel.setContentHuggingPriority(.init(rawValue: 1000), for: .horizontal)
        
        let stack = UIStackView(arrangedSubviews: [gasFeeLabel, gasFeeValueLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.alignment = .fill
        stack.spacing = 8
        stack.heightAnchor.constraint(equalToConstant: 24).isActive = true
        
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.gasFeePullUpTitle.localized()),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .gasFeeIcon,
                                                                                     size: .small),
                                                                         subtitle: .label(.highlightedText(.init(text: String.Constants.gasFeePullUpSubtitle.localized(),
                                                                                                                 highlightedText: [.init(highlightedText: String.Constants.gasFeePullUpSubtitleHighlighted.localized(),
                                                                                                                                         highlightedColor: .foregroundAccent)],
                                                                                                                 analyticsActionName: .learnMore,
                                                                                                                 action: { [weak self, weak viewController] in
                if let vc = viewController?.presentedViewController {
                    self?.showGasFeeInfoPullUp(in: vc, for: .Ethereum)
                    
                }
            }))),
                                                                         extraViews: [stack],
                                                                         actionButton: .applePay(content: .init(title: String.Constants.pay.localized(),
                                                                                                                icon: nil,
                                                                                                                analyticsName: .pay,
                                                                                                                action: { completion(.success(Void())) })),
                                                                         cancelButton: .cancelButton),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            showOrUpdate(in: viewController, pullUp: .gasFeeConfirmation, contentView: selectionView, height: selectionViewHeight, closedCallback: { completion(.failure(PullUpError.dismissed)) })
        }
    }
    
    func showMintDomainConfirmationPullUp(in viewController: UIViewController) async throws -> MintDomainPullUpAction {
        let selectionViewHeight: CGFloat = 408
        
        return try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.importYourDomains.localized()),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .walletOpen,
                                                                                     size: .small)),
                                                    items: MintDomainPullUpAction.allCases,
                                                    itemSelectedCallback: { action in
                completion(.success(action))
            })
            
            showOrUpdate(in: viewController, pullUp: .mintDomainsSelection, contentView: selectionView, height: selectionViewHeight, closedCallback: { completion(.failure(PullUpError.dismissed)) })
        }
    }

    func showServerConnectConfirmationPullUp(for connectionConfig: WCRequestUIConfiguration,
                                             in viewController: UIViewController) async throws -> WalletConnectService.ConnectionUISettings {
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let signTransactionView: BaseSignTransactionView
            let selectionViewHeight: CGFloat
            let pullUp: Analytics.PullUp
            let connectionConfiguration: WalletConnectService.ConnectionConfig
            
            switch connectionConfig {
            case .signMessage(let configuration):
                let signMessageConfirmationView = SignMessageRequestConfirmationView()
                signMessageConfirmationView.configureWith(configuration)
                selectionViewHeight = signMessageConfirmationView.requiredHeight()
                signTransactionView = signMessageConfirmationView
                pullUp = .wcRequestSignMessageConfirmation
                connectionConfiguration = configuration.connectionConfig
            case .payment(let configuration):
                let signPaymentConfirmationView = PaymentTransactionRequestConfirmationView()
                signPaymentConfirmationView.configureWith(configuration)
                selectionViewHeight = configuration.isGasFeeOnlyTransaction ? 512 : 564
                signTransactionView = signPaymentConfirmationView
                pullUp = .wcRequestTransactionConfirmation
                connectionConfiguration = configuration.connectionConfig
            case .connectWallet(let connectionConfig):
                let connectServerConfirmationView = ConnectServerRequestConfirmationView()
                connectServerConfirmationView.setWith(connectionConfig: connectionConfig)
                if case .version2 = connectionConfig.appInfo.dAppInfoInternal {
                    selectionViewHeight = 376
                } else {
                    selectionViewHeight = 420
                }
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
            
            signTransactionView.domainButtonCallback = { [weak pullUpView, weak signTransactionView] domain in
                Task {
                    do {
                        
                        guard let pullUpView = pullUpView else { return }
                        let isSetForRR = await appContext.dataAggregatorService.isReverseResolutionSet(for: domain.name)
                        let selectedDomain = DomainDisplayInfo(domainItem: domain, isSetForRR: isSetForRR)
                        let newDomain = try await UDRouter().showSignTransactionDomainSelectionScreen(selectedDomain: selectedDomain,
                                                                                                      swipeToDismissEnabled: false,
                                                                                                      in: pullUpView)
                        
                        let domain = try await appContext.dataAggregatorService.getDomainWith(name: newDomain.0.name)
                        signTransactionView?.setDomainInfo(domain, isSelectable: true)
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
    
    func showNetworkNotSupportedPullUp(in viewController: UIViewController) {
        let selectionViewHeight: CGFloat = 304
        let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.networkNotSupportedInfoTitle.localized()),
                                                                     contentAlignment: .center,
                                                                     icon: .init(icon: .grimaseIcon,
                                                                                 size: .small),
                                                                     subtitle: .label(.text(String.Constants.networkNotSupportedInfoDescription.localized())),
                                                                     cancelButton: .gotItButton()),
                                                items: PullUpSelectionViewEmptyItem.allCases)
        
        showOrUpdate(in: viewController, pullUp: .wcNetworkNotSupported, contentView: selectionView, height: selectionViewHeight)
    }
    
    func showWCRequestNotSupportedPullUp(in viewController: UIViewController) {
        let selectionViewHeight: CGFloat = 280
        let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.wcRequestNotSupportedInfoTitle.localized()),
                                                                     contentAlignment: .center,
                                                                     icon: .init(icon: .grimaseIcon,
                                                                                 size: .small),
                                                                     subtitle: .label(.text(String.Constants.wcRequestNotSupportedInfoDescription.localized())),
                                                                     cancelButton: .gotItButton()),
                                                items: PullUpSelectionViewEmptyItem.allCases)
        
        showOrUpdate(in: viewController, pullUp: .wcRequestNotSupported, contentView: selectionView, height: selectionViewHeight)
    }
    
    func showWCConnectionFailedPullUp(in viewController: UIViewController) {
        let selectionViewHeight: CGFloat = 280
        let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.signTransactionFailedAlertTitle.localized()),
                                                                     contentAlignment: .center,
                                                                     icon: .init(icon: .grimaseIcon,
                                                                                 size: .small),
                                                                     subtitle: .label(.text(String.Constants.signTransactionFailedAlertDescription.localized())),
                                                                     cancelButton: .gotItButton()),
                                                items: PullUpSelectionViewEmptyItem.allCases)
        
        showOrUpdate(in: viewController, pullUp: .wcConnectionFailed, contentView: selectionView, height: selectionViewHeight)
    }
    
    func showWCTransactionFailedPullUp(in viewController: UIViewController) {
        let selectionViewHeight: CGFloat = 280
        let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.transactionFailed.localized()),
                                                                     contentAlignment: .center,
                                                                     icon: .init(icon: .cancelCircleIcon,
                                                                                 size: .small),
                                                                     subtitle: .label(.text(String.Constants.signTransactionFailedAlertDescription.localized())),
                                                                     cancelButton: .gotItButton()),
                                                items: PullUpSelectionViewEmptyItem.allCases)
        
        showOrUpdate(in: viewController, pullUp: .wcTransactionFailed, contentView: selectionView, height: selectionViewHeight)
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
    
    func showWCLowBalancePullUp(in viewController: UIViewController) {
        let selectionViewHeight: CGFloat = 280
        let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.insufficientBalance.localized()),
                                                                     contentAlignment: .center,
                                                                     icon: .init(icon: .cancelCircleIcon,
                                                                                 size: .small),
                                                                     subtitle: .label(.text(String.Constants.walletConnectLowBalanceAlertDescription.localized())),
                                                                     cancelButton: .gotItButton()),
                                                items: PullUpSelectionViewEmptyItem.allCases)
        
        showOrUpdate(in: viewController, pullUp: .wcLowBalance, contentView: selectionView, height: selectionViewHeight)
    }
    
    func showYouAreOfflinePullUp(in viewController: UIViewController,
                                 unavailableFeature: UnavailableOfflineFeature) async {
        await withSafeCheckedMainActorContinuation(critical: false) { completion in
            let selectionViewHeight: CGFloat = 304
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.youAreOfflinePullUpTitle.localized()),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .cloudOfflineIcon,
                                                                                     size: .small),
                                                                         subtitle: .label(.text(String.Constants.youAreOfflinePullUpMessage.localized(unavailableFeature.title))),
                                                                         cancelButton: .gotItButton()),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            showOrUpdate(in: viewController, pullUp: .userOffline, contentView: selectionView, height: selectionViewHeight, closedCallback: { completion(Void()) })
        }
    }
    
    func showShareDomainPullUp(domain: DomainDisplayInfo, qrCodeImage: UIImage, in viewController: UIViewController) async -> ShareDomainSelectionResult {
        await withSafeCheckedMainActorContinuation(critical: false) { completion in
            let selectionViewHeight: CGFloat = 512
            let shareDomainPullUpView = ShareDomainImagePullUpView()
            shareDomainPullUpView.setWithDomain(domain, qrImage: qrCodeImage)
            var isSelected = false
            shareDomainPullUpView.selectionCallback = { result in
                guard !isSelected else { return }
                
                isSelected = true
                completion(result)
            }
            
            showOrUpdate(in: viewController, pullUp: .shareDomainSelection, contentView: shareDomainPullUpView, height: selectionViewHeight, closedCallback: {
                completion(.cancel)
            })
        }
    }
    
    func showSaveDomainImageTypePullUp(description: SaveDomainImageDescription,
                                       in viewController: UIViewController) async throws -> SaveDomainSelectionResult {
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionViewHeight: CGFloat = 316
            let shareDomainPullUpView = SaveDomainImageTypePullUpView()
            shareDomainPullUpView.setPreview(with: description)
            shareDomainPullUpView.selectionCallback = { result in
                completion(.success(result))
            }
            
            showOrUpdate(in: viewController, pullUp: .exportDomainPFPStyleSelection, contentView: shareDomainPullUpView, height: selectionViewHeight, closedCallback: {
                completion(.failure(PullUpError.cancelled))
            })
        }
    }
    
    func showZilDomainsNotSupportedPullUp(in viewController: UIViewController) async throws {
        let selectionViewHeight: CGFloat = 390
        
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.domainsOnZilNotSupportedInfoTitle.localized()),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .warningIconLarge, size: .small),
                                                                         subtitle: .label(.text(String.Constants.domainsOnZilNotSupportedInfoMessage.localized())),
                                                                         actionButton: .main(content: .init(title: String.Constants.freeUpgradeToPolygon.localized(),
                                                                                                            icon: nil,
                                                                                                            analyticsName: .confirm,
                                                                                                            action: { completion(.success(Void())) })),
                                                                         cancelButton: .cancelButton),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            showOrUpdate(in: viewController, pullUp: .zilDomainsNotSupported, contentView: selectionView, height: selectionViewHeight, closedCallback: { completion(.failure(PullUpError.dismissed)) })
        }
    }
    
    func showDomainTLDDeprecatedPullUp(tld: String,
                                       in viewController: UIViewController) async throws {
        let selectionViewHeight: CGFloat = 360
        
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.tldHasBeenDeprecated.localized(tld)),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .warningIconLarge, size: .small),
                                                                         subtitle: .label(.text(String.Constants.tldDeprecatedRefundDescription.localized(tld))),
                                                                         actionButton: .main(content: .init(title: String.Constants.learnMore.localized(),
                                                                                                            icon: nil,
                                                                                                            analyticsName: .confirm,
                                                                                                            action: { completion(.success(Void())) })),
                                                                         cancelButton: .cancelButton),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            showOrUpdate(in: viewController, pullUp: .tldIsDeprecated, contentView: selectionView, height: selectionViewHeight, closedCallback: { completion(.failure(PullUpError.dismissed)) })
        }
    }
    
    func showMintingNotAvailablePullUp(in viewController: UIViewController) async {
        await withSafeCheckedMainActorContinuation(critical: false) { completion in
            let selectionViewHeight: CGFloat = 304
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.mintingNotAvailablePullUpTitle.localized()),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .repairIcon,
                                                                                     size: .small),
                                                                         subtitle: .label(.text(String.Constants.mintingNotAvailablePullUpMessage.localized())),
                                                                         cancelButton: .gotItButton()),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            showOrUpdate(in: viewController, pullUp: .mintingNotAvailable, contentView: selectionView, height: selectionViewHeight, closedCallback: { completion(Void()) })
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
    
    func showExternalWalletDisconnected(from walletDisplayInfo: WalletDisplayInfo, in viewController: UIViewController) async {
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
        
        await withSafeCheckedMainActorContinuation(critical: false) { completion in
            let selectionViewHeight: CGFloat = 292
            let selectionView = PullUpSelectionView(configuration: .init(title: .highlightedText(.init(text: title,
                                                                                                       highlightedText: [.init(highlightedText: walletAddress,
                                                                                                                               highlightedColor: .foregroundSecondary)],
                                                                                                       analyticsActionName: nil,
                                                                                                       action: nil)),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: icon,
                                                                                     size: .large),
                                                                         cancelButton: .gotItButton()),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            showOrUpdate(in: viewController, pullUp: .externalWalletDisconnected, contentView: selectionView, height: selectionViewHeight, closedCallback: { completion(Void()) })
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
    
    func showLoadingIndicator(in viewController: UIViewController) {
        let selectionViewHeight: CGFloat = 428
        let loadingView = UIView()
        loadingView.backgroundColor = .backgroundDefault
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.color = .foregroundDefault
        loadingView.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor, constant: -36).isActive = true
        activityIndicator.startAnimating()
        
        showIfNotPresent(in: viewController, pullUp: .wcLoading, contentView: loadingView, isDismissAble: true, height: selectionViewHeight)
    }
    
    func showWhatIsReverseResolutionInfoPullUp(in viewController: UIViewController) {
        let selectionViewHeight: CGFloat = 412
        let headerView = ReverseResolutionIllustrationView(frame: .zero)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        let width: CGFloat = deviceSize == .i4Inch ? 288 : 326
        headerView.widthAnchor.constraint(equalToConstant: width).isActive = true
        headerView.heightAnchor.constraint(equalToConstant: 144).isActive = true
        headerView.set(style: .small)
        headerView.setInfoData()
        
        let selectionView = PullUpSelectionView(configuration: .init(customHeader: headerView,
                                                                     title: .text(String.Constants.reverseResolutionInfoTitle.localized()),
                                                                     contentAlignment: .center,
                                                                     subtitle: .label(.text(String.Constants.reverseResolutionInfoSubtitle.localized())),
                                                                     cancelButton: .secondary(content: .init(title: String.Constants.gotIt.localized(),
                                                                                                             icon: nil,
                                                                                                             analyticsName: .gotIt,
                                                                                                             action: nil))),
                                                items: PullUpSelectionViewEmptyItem.allCases)
        
        showOrUpdate(in: viewController, pullUp: .whatIsReverseResolutionInfo, contentView: selectionView, height: selectionViewHeight)
    }
    
    func showSetupReverseResolutionPromptPullUp(walletInfo: WalletDisplayInfo,
                                                domain: DomainDisplayInfo,
                                                in viewController: UIViewController) async throws {
        let selectionViewHeight: CGFloat = 512
        let headerView = ReverseResolutionIllustrationView(frame: .zero)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        let width: CGFloat = deviceSize == .i4Inch ? 288 : 326
        headerView.widthAnchor.constraint(equalToConstant: width).isActive = true
        headerView.heightAnchor.constraint(equalToConstant: 144).isActive = true
        headerView.set(style: .small)
        headerView.setWith(walletInfo: walletInfo, domain: domain)
        
        var icon: UIImage?
        if User.instance.getSettings().touchIdActivated {
            icon = authentificationService.biometricType == .faceID ? .faceIdIcon : .touchIdIcon
        }
        let walletAddress = walletInfo.address.walletAddressTruncated
        let domainName = domain.name
        
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionView = PullUpSelectionView(configuration: .init(customHeader: headerView,
                                                                         title: .text(String.Constants.setupReverseResolution.localized()),
                                                                         contentAlignment: .center,
                                                                         subtitle: .label(.highlightedText(.init(text: String.Constants.setupReverseResolutionDescription.localized(domainName, walletAddress),
                                                                                                                 highlightedText: [.init(highlightedText: domainName,
                                                                                                                                         highlightedColor: .foregroundDefault),
                                                                                                                                   .init(highlightedText: walletAddress,
                                                                                                                                         highlightedColor: .foregroundDefault)],
                                                                                                                 analyticsActionName: nil,
                                                                                                                 action: nil))),
                                                                         actionButton: .main(content: .init(title: String.Constants.confirm.localized(),
                                                                                                            icon: icon,
                                                                                                            analyticsName: .confirm,
                                                                                                            action: { completion(.success(Void())) })),
                                                                         cancelButton: .secondary(content: .init(title: String.Constants.later.localized(),
                                                                                                                 icon: nil,
                                                                                                                 analyticsName: .later,
                                                                                                                 action: nil))),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            showOrUpdate(in: viewController, pullUp: .setupReverseResolutionPrompt, contentView: selectionView, height: selectionViewHeight, closedCallback: { completion(.failure(PullUpError.dismissed)) })
        }
    }
    
    func showDomainMintedOnChainDescriptionPullUp(in viewController: UIViewController,
                                                  chain: BlockchainType) {
        let selectionViewHeight: CGFloat
        let icon = UIImage.getNetworkLargeIcon(by: chain)!
        let description: String
        switch chain {
        case .Ethereum:
            description = String.Constants.mintedOnEthereumDescription.localized()
            selectionViewHeight = 328
        case .Matic:
            description = String.Constants.mintedOnPolygonDescription.localized()
            selectionViewHeight = 304
        default:
            description = ""
            selectionViewHeight = 304
            Debugger.printFailure("Attempting to show domain minted on chain description for unsupported chain", critical: true)
        }
        let selectionView = PullUpSelectionView(configuration: .init(title: .text(chain.fullName),
                                                                     contentAlignment: .center,
                                                                     icon: .init(icon: icon,
                                                                                 size: .small),
                                                                     subtitle: .label(.text(description)),
                                                                     cancelButton: .gotItButton()),
                                                items: PullUpSelectionViewEmptyItem.allCases)
        
        showOrUpdate(in: viewController, pullUp: .domainMintedOnChainDescription, contentView: selectionView, height: selectionViewHeight)
    }
    
    func showDomainProfileInfoPullUp(in viewController: UIViewController) {
        showDomainProfileInfoPullUp(in: viewController, page: 1)
    }

    private func showDomainProfileInfoPullUp(in viewController: UIViewController,
                                             page: Int) {
        showDomainProfileTutorialPullUp(in: viewController,
                                        useCase: .pullUp)
    }
    
    func showBadgeInfoPullUp(in viewController: UIViewController, badgeDisplayInfo: DomainProfileViewController.DomainProfileBadgeDisplayInfo) {
        let badge = badgeDisplayInfo.badge
        var selectionViewHeight: CGFloat = 256
        let description = badge.description
        let labelWidth = UIScreen.main.bounds.width - 32 // 16 * 2 side offsets
        let descriptionHeight = description.height(withConstrainedWidth: labelWidth,
                                                         font: .currentFont(withSize: 16,
                                                                            weight: .regular))
        selectionViewHeight += descriptionHeight
        Task {
            var badgeIcon = badgeDisplayInfo.defaultIcon
            if let url = URL(string: badgeDisplayInfo.badge.logo),
               let image = await appContext.imageLoadingService.loadImage(from: .url(url),
                                                                          downsampleDescription: nil) {
                badgeIcon = image
            }
            
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(badge.name),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: badgeIcon,
                                                                                     size: .small),
                                                                         subtitle: .label(.text(description)),
                                                                         cancelButton: .gotItButton()),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            showOrUpdate(in: viewController, pullUp: .badgeInfo, contentView: selectionView, height: selectionViewHeight)
        }
    }
    
    func showImageTooLargeToUploadPullUp(in viewController: UIViewController) async throws {
        let selectionViewHeight: CGFloat = 280
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.profileImageTooLargeToUploadTitle.localized()),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .smileIcon,
                                                                                     size: .small),
                                                                         subtitle: .label(.text(String.Constants.profileImageTooLargeToUploadDescription.localized())),
                                                                         actionButton: .secondary(content: .init(title: String.Constants.changePhoto.localized(),
                                                                                                                 icon: nil,
                                                                                                                 analyticsName: .changePhoto,
                                                                                                                 action: { completion(.success(Void())) }))),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            presentPullUpView(in: viewController, pullUp: .selectedImageTooLarge, contentView: selectionView, isDismissAble: true, height: selectionViewHeight, closedCallback: { completion(.failure(PullUpError.dismissed)) })
        }
    }
    
    func showSelectedImageBadPullUp(in viewController: UIViewController) {
        let selectionViewHeight: CGFloat = 280
        let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.somethingWentWrong.localized()),
                                                                     contentAlignment: .center,
                                                                     icon: .init(icon: .smileIcon,
                                                                                 size: .small),
                                                                     subtitle: .label(.text(String.Constants.profileImageBadDescription.localized())),
                                                                     cancelButton: .gotItButton()),
                                                items: PullUpSelectionViewEmptyItem.allCases)
        
        presentPullUpView(in: viewController, pullUp: .selectedImageBad, contentView: selectionView, isDismissAble: true, height: selectionViewHeight)
    }
    
    func showAskToNotifyWhenRecordsUpdatedPullUp(in viewController: UIViewController) async throws {
        let selectionViewHeight: CGFloat = 368
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.updatingRecords.localized()),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .refreshIcon,
                                                                                     size: .small),
                                                                         subtitle: .label(.text(String.Constants.profileUpdatingRecordsNotifyWhenFinishedDescription.localized())),
                                                                         actionButton: .main(content: .init(title: String.Constants.notifyMeWhenFinished.localized(),
                                                                                                            icon: .bellIcon,
                                                                                                                 analyticsName: .notifyWhenFinished,
                                                                                                                 action: { completion(.success(Void())) })),
                                                                         cancelButton: .gotItButton()),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            presentPullUpView(in: viewController, pullUp: .askToNotifyWhenRecordsUpdated, contentView: selectionView, isDismissAble: true, height: selectionViewHeight, closedCallback: { completion(.failure(PullUpError.dismissed)) })
        }
    }
    
    func showWillNotifyWhenRecordsUpdatedPullUp(in viewController: UIViewController) {
        let selectionViewHeight: CGFloat = 368
        let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.updatingRecords.localized()),
                                                                     contentAlignment: .center,
                                                                     icon: .init(icon: .refreshIcon,
                                                                                 size: .small),
                                                                     subtitle: .label(.text(String.Constants.profileUpdatingRecordsWillNotifyWhenFinishedDescription.localized())),
                                                                     actionButton: .main(content: .init(title: String.Constants.weWillNotifyYouWhenFinished.localized(),
                                                                                                             icon: nil,
                                                                                                             analyticsName: .notifyWhenFinished,
                                                                                                             isSuccessState: true,
                                                                                                        action: { [weak viewController] in viewController?.dismissPullUpMenu()})),
                                                                     cancelButton: .gotItButton()),
                                                items: PullUpSelectionViewEmptyItem.allCases)
        
        presentPullUpView(in: viewController, pullUp: .willNotifyWhenRecordsUpdated, contentView: selectionView, isDismissAble: true, height: selectionViewHeight)
    }
    
    func showFailedToFetchProfileDataPullUp(in viewController: UIViewController,
                                            isRefreshing: Bool,
                                            animatedTransition: Bool) async throws {
        let selectionViewHeight: CGFloat = 344
        let refreshTitle = String.Constants.refresh.localized()
        let refreshingTitle = String.Constants.refreshing.localized()
        let buttonTitle = isRefreshing ? refreshingTitle : refreshTitle
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.profileLoadingFailedTitle.localized()),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .grimaseIcon,
                                                                                     size: .small),
                                                                         subtitle: .label(.text(String.Constants.profileLoadingFailedDescription.localized())),
                                                                         actionButton: .main(content: .init(title: buttonTitle,
                                                                                                            icon: nil,
                                                                                                            analyticsName: .refresh,
                                                                                                            isLoading: isRefreshing,
                                                                                                            isUserInteractionEnabled: !isRefreshing,
                                                                                                            action: { completion(.success(Void())) })),
                                                                         cancelButton: .secondary(content: .init(title: String.Constants.profileViewOfflineProfile.localized(),
                                                                                                                 icon: nil,
                                                                                                                 analyticsName: .viewOfflineProfile,
                                                                                                                 action: nil))),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            showOrUpdate(in: viewController, pullUp: .failedToFetchProfileData, contentView: selectionView, isDismissAble: true, height: selectionViewHeight, animated: animatedTransition, closedCallback: { completion(.failure(PullUpError.dismissed)) })
        }
    }
    
    func showUpdateDomainProfileFailedPullUp(in viewController: UIViewController) async throws {
        let selectionViewHeight: CGFloat = 344
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.profileUpdateFailed.localized()),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .grimaseIcon,
                                                                                     size: .small),
                                                                         subtitle: .label(.text(String.Constants.pleaseTryAgain.localized())),
                                                                         actionButton: .main(content: .init(title: String.Constants.tryAgain.localized(),
                                                                                                            icon: nil,
                                                                                                            analyticsName: .tryAgain,
                                                                                                            action: { completion(.success(Void())) })),
                                                                         cancelButton: .cancelButton),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            presentPullUpView(in: viewController, pullUp: .updateDomainProfileFailed, contentView: selectionView, isDismissAble: true, height: selectionViewHeight, closedCallback: { completion(.failure(PullUpError.dismissed)) })
        }
    }
    
    func showTryUpdateDomainProfileLaterPullUp(in viewController: UIViewController) async throws {
        let selectionViewHeight: CGFloat = 344
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.tryAgainLater.localized()),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .hammerWrenchIcon24,
                                                                                     size: .small,
                                                                                     tintColor: .foregroundWarning),
                                                                         subtitle: .label(.text(String.Constants.profileTryUpdateProfileLater.localized())),
                                                                         actionButton: .main(content: .init(title: String.Constants.tryAgain.localized(),
                                                                                                            icon: nil,
                                                                                                            analyticsName: .tryAgain,
                                                                                                            action: { completion(.success(Void())) })),
                                                                         cancelButton: .cancelButton),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            presentPullUpView(in: viewController, pullUp: .tryUpdateProfileLater, contentView: selectionView, isDismissAble: true, height: selectionViewHeight, closedCallback: { completion(.failure(PullUpError.dismissed)) })
        }
    }
    
    func showUpdateDomainProfileSomeChangesFailedPullUp(in viewController: UIViewController,
                                                        changes: [DomainProfileSectionUIChangeFailedItem]) async throws {
        let selectionViewHeight: CGFloat = 268 + (CGFloat(changes.count) * PullUpCollectionViewCell.Height)
        
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.confirmUpdates.localized()),
                                                                         contentAlignment: .center,
                                                                         actionButton: .main(content: .init(title: String.Constants.tryAgain.localized(),
                                                                                                            icon: nil,
                                                                                                            analyticsName: .tryAgain,
                                                                                                            action: { completion(.success(Void())) })),
                                                                         cancelButton: .cancelButton),
                                                    items: changes)
            
            showOrUpdate(in: viewController, pullUp: .updateDomainProfileSomeChangesFailed, contentView: selectionView, height: selectionViewHeight, closedCallback: { completion(.failure(PullUpError.dismissed)) })
        }
    }
    
    func showRefreshBadgesComingSoonPullUp(in viewController: UIViewController) {
        let selectionViewHeight: CGFloat = 304
        let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.comingSoon.localized()),
                                                                     contentAlignment: .center,
                                                                     icon: .init(icon: .refreshArrow24,
                                                                                 size: .small),
                                                                     subtitle: .label(.text(String.Constants.profileBadgesComingSoonDescription.localized())),
                                                                     cancelButton: .gotItButton()),
                                                items: PullUpSelectionViewEmptyItem.allCases)
        
        presentPullUpView(in: viewController, pullUp: .refreshBadgesComingSoon, contentView: selectionView, isDismissAble: true, height: selectionViewHeight)
    }
    
    func showShowcaseYourProfilePullUp(for domain: DomainDisplayInfo,
                                       in viewController: UIViewController) async throws {
        let selectionViewHeight: CGFloat = 388
        
        let illustration = buildImageViewWith(image: .showcaseDomainProfileIllustration,
                                              width: 358,
                                              height: 56)
        
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionView = PullUpSelectionView(configuration: .init(customHeader: illustration,
                                                                         title: .text(String.Constants.profileShowcaseProfileTitle.localized(domain.name)),
                                                                         contentAlignment: .center,
                                                                         subtitle: .label(.text(String.Constants.profileShowcaseProfileDescription.localized())),
                                                                         actionButton: .main(content: .init(title: String.Constants.shareProfile.localized(),
                                                                                                            icon: nil,
                                                                                                            analyticsName: .share,
                                                                                                            action: { completion(.success(Void())) })),
                                                                         cancelButton: .cancelButton),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            presentPullUpView(in: viewController, pullUp: .showcaseYourProfile, contentView: selectionView, isDismissAble: true, height: selectionViewHeight, closedCallback: { completion(.failure(PullUpError.dismissed)) })
        }
    }
    
    func showDomainProfileAccessInfoPullUp(in viewController: UIViewController) {
        showDomainProfileTutorialPullUp(in: viewController,
                                        useCase: .pullUpPrivacyOnly)
    }
    
    func showRecentActivitiesInfoPullUp(in viewController: UIViewController) async throws {
        let selectionViewHeight: CGFloat = 368
        
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.recentActivityInfoTitle.localized()),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .timeIcon24,
                                                                                     size: .small),
                                                                         subtitle: .label(.text(String.Constants.recentActivityInfoSubtitle.localized())),
                                                                         actionButton: .main(content: .init(title: String.Constants.scanToConnect.localized(),
                                                                                                            icon: nil,
                                                                                                            analyticsName: .scanToConnect,
                                                                                                            action: { completion(.success(Void())) })),
                                                                         cancelButton: .gotItButton()),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            presentPullUpView(in: viewController, pullUp: .recentActivityInfo, contentView: selectionView, isDismissAble: true, height: selectionViewHeight, closedCallback: { completion(.failure(PullUpError.dismissed)) })
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
                                                                         downsampleDescription: nil) ?? .init()
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
        
        let icon = await appContext.imageLoadingService.loadImage(from: .connectedApp(connectedApp, size: .default), downsampleDescription: nil)
        if connectedApp.appIconUrls.isEmpty {
            connectedAppImageBackgroundView.backgroundColor = .clear
        } else {
            let color = await icon?.getColors()?.background
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
        
        presentPullUpView(in: viewController, pullUp: .connectedAppDomainInfo, contentView: selectionView, isDismissAble: true, height: selectionViewHeight)
    }
}

// MARK: - Private methods
private extension PullUpViewService {
    func showDomainProfileTutorialPullUp(in viewController: UIViewController,
                                         useCase: DomainProfileTutorialViewController.UseCase) {
        var selectionViewHeight: CGFloat
        let pullUp: Analytics.PullUp
        
        switch useCase {
        case .largeTutorial:
            Debugger.printFailure("Should not be used in pull up", critical: true)
            return
        case .pullUp:
            selectionViewHeight = UIScreen.main.bounds.width > 400 ? 540 : 520
            pullUp = .domainProfileInfo
        case .pullUpPrivacyOnly:
            selectionViewHeight = 420
            pullUp = .domainProfileAccessInfo
        }
        
        switch deviceSize {
        case .i4Inch:
            selectionViewHeight -= 40
        case .i4_7Inch:
            selectionViewHeight -= 30
        default:
            Void()
        }
        
        let vc = DomainProfileTutorialViewController()
        vc.completionCallback = { [weak viewController] in
            viewController?.dismissPullUpMenu()
        }
        vc.useCase = useCase
        
        let pullUpVC = showOrUpdate(in: viewController, pullUp: pullUp, contentView: vc.view!, height: selectionViewHeight)
        
        vc.didMove(toParent: pullUpVC)
        pullUpVC.addChild(vc)
    }
}

// MARK: - Private methods
private extension PullUpViewService {
    func currentPullUpViewController(in viewController: UIViewController) -> PullUpViewController? {
        if let pullUpView = viewController.presentedViewController as? PullUpViewController {
            return pullUpView
        } else if let pullUpView = viewController as? PullUpViewController {
            return pullUpView
        }
        return nil
    }
    
    @discardableResult
    func showOrUpdate(in viewController: UIViewController,
                      pullUp: Analytics.PullUp,
                      additionalAnalyticParameters: Analytics.EventParameters = [:],
                      contentView: UIView,
                      isDismissAble: Bool = true,
                      height: CGFloat,
                      animated: Bool = true,
                      closedCallback: EmptyCallback? = nil) -> PullUpViewController {
        func updatePullUpView(_ pullUpView: PullUpViewController) {
            pullUpView.replaceContentWith(contentView, newHeight: height, pullUp: pullUp,
                                          animated: animated, didCloseCallback: closedCallback)
        }
        
        if let pullUpView = currentPullUpViewController(in: viewController) {
            updatePullUpView(pullUpView)
            return pullUpView
        } else {
            return presentPullUpView(in: viewController,
                                     pullUp: pullUp,
                                     additionalAnalyticParameters: additionalAnalyticParameters,
                                     contentView: contentView,
                                     isDismissAble: isDismissAble,
                                     height: height,
                                     closedCallback: closedCallback)
        }
    }
    
    func showIfNotPresent(in viewController: UIViewController,
                          pullUp: Analytics.PullUp,
                          additionalAnalyticParameters: Analytics.EventParameters = [:],
                          contentView: UIView,
                          isDismissAble: Bool,
                          height: CGFloat,
                          closedCallback: EmptyCallback? = nil) {
        guard currentPullUpViewController(in: viewController) == nil else { return }
        
        presentPullUpView(in: viewController,
                          pullUp: pullUp,
                          additionalAnalyticParameters: additionalAnalyticParameters,
                          contentView: contentView,
                          isDismissAble: isDismissAble,
                          height: height,
                          closedCallback: closedCallback)
    }
    
    @discardableResult
    func presentPullUpView(in viewController: UIViewController,
                           pullUp: Analytics.PullUp,
                           additionalAnalyticParameters: Analytics.EventParameters = [:],
                           contentView: UIView,
                           isDismissAble: Bool,
                           height: CGFloat,
                           closedCallback: EmptyCallback? = nil)  -> PullUpViewController {
        let pullUpView = PullUpViewController(pullUp: pullUp,
                                              additionalAnalyticParameters: additionalAnalyticParameters,
                                              height: height,
                                              subview: contentView,
                                              isDismissAble: isDismissAble,
                                              backgroundColor: .backgroundDefault,
                                              didCloseCallback: closedCallback)
        viewController.present(pullUpView, animated: false)
        return pullUpView
    }
    
    func buildImageViewWith(image: UIImage,
                            width: CGFloat,
                            height: CGFloat) -> UIImageView {
        let imageView = UIImageView()
        imageView.image = image
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalToConstant: width).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: height).isActive = true
        
        return imageView
    }
}

extension PullUpViewService {
    enum PullUpError: Error {
        case dismissed
        case cancelled
    }
    
    enum UnavailableOfflineFeature {
        case minting, scanning
        
        var title: String {
            switch self {
            case .minting: return String.Constants.minting.localized()
            case .scanning: return String.Constants.scanning.localized()
            }
        }
    }
}
