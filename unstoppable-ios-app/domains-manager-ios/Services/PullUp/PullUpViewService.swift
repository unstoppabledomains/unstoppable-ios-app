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
                                      presentationOptions: PullUpNamespace.AddWalletPullUpPresentationOptions,
                                      actions: [WalletDetailsAddWalletAction]) async throws -> WalletDetailsAddWalletAction
    func showManageBackupsSelectionPullUp(in viewController: UIViewController) async throws -> ManageBackupsAction
    func showDeleteAllICloudBackupsPullUp(in viewController: UIViewController) async throws
    func showRestoreFromICloudBackupSelectionPullUp(in viewController: UIViewController,
                                                    backups: [ICloudBackupDisplayInfo]) async throws -> ICloudBackupDisplayInfo
    func showCopyWalletAddressSelectionPullUp(in viewController: UIViewController,
                                              wallet: UDWallet,
                                              transactionSelectedCallback: @escaping (WalletCopyAddressAction)->())
    func showRemoveWalletPullUp(in viewController: UIViewController,
                                walletInfo: WalletDisplayInfo) async throws
    func showAppearanceStyleSelectionPullUp(in viewController: UIViewController,
                                            selectedStyle: UIUserInterfaceStyle,
                                            styleChangedCallback: @escaping AppearanceStyleChangedCallback)
    func showAddDomainSelectionPullUp(in viewController: UIViewController) async throws -> AddDomainPullUpAction

    func showYouAreOfflinePullUp(in viewController: UIViewController,
                                 unavailableFeature: PullUpViewService.UnavailableOfflineFeature) async
    func showZilDomainsNotSupportedPullUp(in viewController: UIViewController) async throws
    func showDomainTLDDeprecatedPullUp(tld: String,
                                       in viewController: UIViewController) async throws
    func showMintingNotAvailablePullUp(in viewController: UIViewController) async
    func showLoadingIndicator(in viewController: UIViewController)
    func showWhatIsReverseResolutionInfoPullUp(in viewController: UIViewController)
    func showSetupReverseResolutionPromptPullUp(walletInfo: WalletDisplayInfo,
                                                domain: DomainDisplayInfo,
                                                in viewController: UIViewController) async throws
    func showDomainMintedOnChainDescriptionPullUp(in viewController: UIViewController,
                                                  chain: BlockchainType)
    func showRecentActivitiesInfoPullUp(in viewController: UIViewController, isGetNewDomain: Bool) async throws
    func showChooseCoinVersionPullUp(for coin: CoinRecord,
                                     in viewController: UIViewController) async throws -> CoinVersionSelectionResult
    func showLogoutConfirmationPullUp(in viewController: UIViewController) async throws
    func showParkedDomainInfoPullUp(in viewController: UIViewController)
    func showParkedDomainTrialExpiresPullUp(in viewController: UIViewController,
                                            expiresDate: Date)
    func showParkedDomainExpiresSoonPullUp(in viewController: UIViewController,
                                           expiresDate: Date)
    func showParkedDomainExpiredPullUp(in viewController: UIViewController)
    func showApplePayRequiredPullUp(in viewController: UIViewController)
    func showWalletsNumberLimitReachedPullUp(in viewController: UIViewController,
                                             maxNumberOfWallets: Int)
    func showWalletsNumberLimitReachedAlreadyPullUp(in viewController: UIViewController,
                                                    maxNumberOfWallets: Int)
    
    // MARK: - External wallet
    func showConnectedWalletInfoPullUp(in viewController: UIViewController)
    func showServerConnectConfirmationPullUp(for connectionConfig: WCRequestUIConfiguration, in viewController: UIViewController) async throws -> WalletConnectServiceV2.ConnectionUISettings
    func showConnectingAppVerifiedPullUp(in viewController: UIViewController)
    func showGasFeeInfoPullUp(in viewController: UIViewController, for network: BlockchainType)
    func showNetworkNotSupportedPullUp(in viewController: UIViewController) async
    func showWCRequestNotSupportedPullUp(in viewController: UIViewController) async
    func showWCConnectionFailedPullUp(in viewController: UIViewController) async
    func showWCTransactionFailedPullUp(in viewController: UIViewController) async
    func showWCInvalidQRCodePullUp(in viewController: UIViewController) async
    func showWCLowBalancePullUp(in viewController: UIViewController) async
    func showWCFriendlyReminderPullUp(in viewController: UIViewController)
    func showExternalWalletDisconnected(from walletDisplayInfo: WalletDisplayInfo, in viewController: UIViewController) async -> Bool
    func showSwitchExternalWalletConfirmation(from walletDisplayInfo: WalletDisplayInfo, in viewController: UIViewController) async throws
    func showConnectedAppNetworksInfoPullUp(in viewController: UIViewController)
    func showConnectedAppDomainInfoPullUp(for domain: DomainDisplayInfo,
                                          connectedApp: any UnifiedConnectAppInfoProtocol,
                                          in viewController: UIViewController) async
    func showExternalWalletConnectionHintPullUp(for walletRecord: WCWalletsProvider.WalletRecord,
                                                in viewController: UIViewController) async
    func showExternalWalletFailedToSignPullUp(in viewController: UIViewController) async
    
    // MARK: - Domain profile
    func showManageDomainRouteCryptoPullUp(in viewController: UIViewController,
                                           numberOfCrypto: Int)
    func showDomainProfileChangesConfirmationPullUp(in viewController: UIViewController,
                                                    changes: [DomainProfileSectionUIChangeType]) async throws
    func showDiscardRecordChangesConfirmationPullUp(in viewController: UIViewController) async throws
    func showPayGasFeeConfirmationPullUp(gasFeeInCents: Int,
                                         in viewController: UIViewController) async throws
    func showShareDomainPullUp(domain: DomainDisplayInfo, qrCodeImage: UIImage, in viewController: UIViewController) async -> ShareDomainSelectionResult
    func showSaveDomainImageTypePullUp(description: SaveDomainImageDescription,
                                       in viewController: UIViewController) async throws -> SaveDomainSelectionResult
    func showDomainProfileInfoPullUp(in viewController: UIViewController)
    func showDomainProfileAccessInfoPullUp(in viewController: UIViewController)

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
    func showShowcaseYourProfilePullUp(for domain: DomainDisplayInfo,
                                       in viewController: UIViewController) async throws
    func showUserProfilePullUp(with email: String,
                               domainsCount: Int,
                               in viewController: UIViewController) async throws -> UserProfileAction
    
    // MARK: - Badges
    func showBadgeInfoPullUp(in viewController: UIViewController,
                             badgeDisplayInfo: DomainProfileBadgeDisplayInfo,
                             domainName: String)
    
    // MARK: - Messaging
    func showMessagingChannelInfoPullUp(channel: MessagingNewsChannel,
                                        in viewController: UIViewController) async throws
    func showMessagingBlockConfirmationPullUp(blockUserName: String,
                                              in viewController: UIViewController) async throws
    func showUnencryptedMessageInfoPullUp(in viewController: UIViewController)
    func showHandleChatLinkSelectionPullUp(in viewController: UIViewController) async throws -> Chat.ChatLinkHandleAction
    func showGroupChatInfoPullUp(groupChatDetails: MessagingGroupChatDetails,
                                 by messagingProfile: MessagingChatUserProfileDisplayInfo,
                                 in viewController: UIViewController) async
    func showCommunityChatInfoPullUp(communityDetails: MessagingCommunitiesChatDetails,
                                     by messagingProfile: MessagingChatUserProfileDisplayInfo,
                                     in viewController: UIViewController) async
}

@MainActor
final class PullUpViewService {
    
    let authentificationService: AuthentificationServiceProtocol
    
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
                                      presentationOptions: PullUpNamespace.AddWalletPullUpPresentationOptions,
                                      actions: [WalletDetailsAddWalletAction]) async throws -> WalletDetailsAddWalletAction {
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { continuation in
            var selectionViewHeight: CGFloat = 72 + (CGFloat(actions.count) * PullUpCollectionViewCell.Height)
            
            var titleConfiguration: PullUpSelectionViewConfiguration.LabelType? = nil
            if let title = presentationOptions.title {
                titleConfiguration = .text(title)
                selectionViewHeight += 36
            }
            
            var subtitleConfiguration: PullUpSelectionViewConfiguration.Subtitle? = nil
            if let subtitle = presentationOptions.subtitle {
                subtitleConfiguration = .label(.text(subtitle))
                selectionViewHeight += 64
            }
            
            
            let selectionView = PullUpSelectionView(configuration: .init(title: titleConfiguration,
                                                                         contentAlignment: .center,
                                                                         subtitle: subtitleConfiguration),
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
            icon = authentificationService.biometricIcon
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
            icon = authentificationService.biometricIcon
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
    
    func showAddDomainSelectionPullUp(in viewController: UIViewController) async throws -> AddDomainPullUpAction {
        let selectionViewHeight: CGFloat = 436
        
        return try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.importYourDomains.localized()),
                                                                         contentAlignment: .center),
                                                    items: AddDomainPullUpAction.pullUpSections,
                                                    itemSelectedCallback: { action in
                completion(.success(action))
            })
            
            showOrUpdate(in: viewController, pullUp: .mintDomainsSelection, contentView: selectionView, height: selectionViewHeight, closedCallback: { completion(.failure(PullUpError.dismissed)) })
        }
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
            icon = authentificationService.biometricIcon
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
                                                                                                                 action: { completion(.failure(PullUpError.dismissed)) }))),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            showOrUpdate(in: viewController, pullUp: .setupReverseResolutionPrompt, additionalAnalyticParameters: [.domainName: domain.name], contentView: selectionView, height: selectionViewHeight, closedCallback: { completion(.failure(PullUpError.dismissed)) })
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
        
        showOrUpdate(in: viewController, pullUp: .domainMintedOnChainDescription, additionalAnalyticParameters: [.chainNetwork: chain.rawValue], contentView: selectionView, height: selectionViewHeight)
    }

    func showRecentActivitiesInfoPullUp(in viewController: UIViewController, isGetNewDomain: Bool) async throws {
        let selectionViewHeight: CGFloat = 368
        let buttonTitle = isGetNewDomain ? String.Constants.findYourDomain.localized() : String.Constants.scanToConnect.localized()
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.recentActivityInfoTitle.localized()),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .timeIcon24,
                                                                                     size: .small),
                                                                         subtitle: .label(.text(String.Constants.recentActivityInfoSubtitle.localized())),
                                                                         actionButton: .main(content: .init(title: buttonTitle,
                                                                                                            icon: nil,
                                                                                                            analyticsName: .scanToConnect,
                                                                                                            action: { completion(.success(Void())) })),
                                                                         cancelButton: .gotItButton()),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            presentPullUpView(in: viewController, pullUp: .recentActivityInfo, contentView: selectionView, isDismissAble: true, height: selectionViewHeight, closedCallback: { completion(.failure(PullUpError.dismissed)) })
        }
    }
 
    /// Return true if latest is selected and false if Legacy
    func showChooseCoinVersionPullUp(for coin: CoinRecord,
                                     in viewController: UIViewController) async throws -> CoinVersionSelectionResult {
        let selectionViewHeight: CGFloat = 404
        let ticker = coin.ticker
        let coinIcon = await appContext.imageLoadingService.loadImage(from: .currency(coin,
                                                                                      size: .default,
                                                                                      style: .gray),
                                                                      downsampleDescription: .mid)
        let segmentedControl = UDSegmentedControl(frame: .zero)
        segmentedControl.heightAnchor.constraint(equalToConstant: 36).isActive = true
        for (i, result) in CoinVersionSelectionResult.allCases.enumerated() {
            segmentedControl.insertSegment(withTitle: result.title, at: i, animated: false)
        }
        segmentedControl.selectedSegmentIndex = CoinVersionSelectionResult.preselected.rawValue
        
        return try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(coin.fullName ?? ticker),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: coinIcon ?? .warningIcon,
                                                                                     size: .large,
                                                                                     corners: .circle),
                                                                         subtitle: .label(.text(String.Constants.chooseCoinVersionPullUpDescription.localized())),
                                                                         extraViews: [segmentedControl],
                                                                         actionButton: .main(content: .init(title: String.Constants.addN.localized(ticker),
                                                                                                            icon: nil,
                                                                                                            analyticsName: .addCurrency,
                                                                                                            action: { [weak segmentedControl] in
                
                let selectedIndex = segmentedControl?.selectedSegmentIndex ?? 0
                let result = CoinVersionSelectionResult(rawValue: selectedIndex) ?? .both
                completion(.success(result))
            }))),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            presentPullUpView(in: viewController, pullUp: .chooseCoinVersion, additionalAnalyticParameters: [.coin: ticker], contentView: selectionView, isDismissAble: true, height: selectionViewHeight, closedCallback: { completion(.failure(PullUpError.dismissed)) })
        }
    }
 
    func showLogoutConfirmationPullUp(in viewController: UIViewController) async throws {
        let selectionViewHeight: CGFloat = 368
        var icon: UIImage?
        if User.instance.getSettings().touchIdActivated {
            icon = authentificationService.biometricIcon
        }
        
        let title: String = String.Constants.logOut.localized()
        let buttonTitle: String = String.Constants.confirm.localized()
        
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(title),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .logOutIcon24,
                                                                                     size: .small),
                                                                         subtitle: .label(.text(String.Constants.logOutConfirmationMessage.localized())),
                                                                         actionButton: .main(content: .init(title: buttonTitle,
                                                                                                            icon: icon,
                                                                                                            analyticsName: .logOut,
                                                                                                            action: { completion(.success(Void())) })),
                                                                         cancelButton: .cancelButton),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            showOrUpdate(in: viewController, pullUp: .logOutConfirmation, contentView: selectionView, height: selectionViewHeight, closedCallback: { completion(.failure(PullUpError.dismissed)) })
        }
    }
  
    func showParkedDomainInfoPullUp(in viewController: UIViewController) {
        let selectionViewHeight: CGFloat = 304
        let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.parkedDomainInfoPullUpTitle.localized()),
                                                                     contentAlignment: .center,
                                                                     icon: .init(icon: .parkingIcon24,
                                                                                 size: .small),
                                                                     subtitle: .label(.text(String.Constants.parkedDomainInfoPullUpSubtitle.localized())),
                                                                     cancelButton: .gotItButton()),
                                                items: PullUpSelectionViewEmptyItem.allCases)
        
        presentPullUpView(in: viewController, pullUp: .parkedDomainInfo, contentView: selectionView, isDismissAble: true, height: selectionViewHeight)
    }
    
    func showParkedDomainTrialExpiresPullUp(in viewController: UIViewController,
                                            expiresDate: Date) {
        let expiresDateString = DateFormattingService.shared.formatParkingExpiresDate(expiresDate)
        
        let selectionViewHeight: CGFloat = 380
        let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.parkedDomainTrialExpiresInfoPullUpTitle.localized(expiresDateString)),
                                                                     contentAlignment: .center,
                                                                     icon: .init(icon: .warningIcon,
                                                                                 size: .small,
                                                                                 tintColor: .foregroundWarning),
                                                                     subtitle: .label(.text(String.Constants.parkedDomainTrialExpiresInfoPullUpSubtitle.localized())),
                                                                     cancelButton: .gotItButton()),
                                                items: PullUpSelectionViewEmptyItem.allCases)
        
        presentPullUpView(in: viewController, pullUp: .parkedDomainTrialExpiresInfo, contentView: selectionView, isDismissAble: true, height: selectionViewHeight)
    }
    
    func showParkedDomainExpiresSoonPullUp(in viewController: UIViewController,
                                            expiresDate: Date) {
        let expiresDateString = DateFormattingService.shared.formatParkingExpiresDate(expiresDate)
        
        let selectionViewHeight: CGFloat = 328
        let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.parkedDomainExpiresSoonPullUpTitle.localized(expiresDateString)),
                                                                     contentAlignment: .center,
                                                                     icon: .init(icon: .warningIcon,
                                                                                 size: .small,
                                                                                 tintColor: .foregroundWarning),
                                                                     subtitle: .label(.text(String.Constants.parkedDomainExpiresSoonPullUpSubtitle.localized())),
                                                                     cancelButton: .gotItButton()),
                                                items: PullUpSelectionViewEmptyItem.allCases)
        
        presentPullUpView(in: viewController, pullUp: .parkedDomainExpiresSoonInfo, contentView: selectionView, isDismissAble: true, height: selectionViewHeight)
    }
    
    func showParkedDomainExpiredPullUp(in viewController: UIViewController) {
        let selectionViewHeight: CGFloat = 328
        let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.parkedDomainExpiredInfoPullUpTitle.localized()),
                                                                     contentAlignment: .center,
                                                                     icon: .init(icon: .warningIcon,
                                                                                 size: .small,
                                                                                 tintColor: .foregroundWarning),
                                                                     subtitle: .label(.text(String.Constants.parkedDomainExpiredInfoPullUpSubtitle.localized())),
                                                                     cancelButton: .gotItButton()),
                                                items: PullUpSelectionViewEmptyItem.allCases)
        
        presentPullUpView(in: viewController, pullUp: .parkedDomainExpiredInfo, contentView: selectionView, isDismissAble: true, height: selectionViewHeight)
    }

    func showApplePayRequiredPullUp(in viewController: UIViewController) {
        let selectionViewHeight: CGFloat = 304
        let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.applePayRequiredPullUpTitle.localized()),
                                                                     contentAlignment: .center,
                                                                     icon: .init(icon: .grimaseIcon,
                                                                                 size: .small),
                                                                     subtitle: .label(.text(String.Constants.applePayRequiredPullUpMessage.localized())),
                                                                     cancelButton: .gotItButton()),
                                                items: PullUpSelectionViewEmptyItem.allCases)
        
        presentPullUpView(in: viewController, pullUp: .applePayRequired, contentView: selectionView, isDismissAble: true, height: selectionViewHeight)
    }
    
    func showWalletsNumberLimitReachedPullUp(in viewController: UIViewController,
                                             maxNumberOfWallets: Int) {
        let selectionViewHeight: CGFloat = 268
        let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.walletsLimitReachedPullUpTitle.localized()),
                                                                     contentAlignment: .center,
                                                                     icon: .init(icon: .warningIcon,
                                                                                 size: .small,
                                                                                 tintColor: .foregroundWarning),
                                                                     subtitle: .label(.text(String.Constants.walletsLimitReachedPullUpSubtitle.localized(maxNumberOfWallets))),
                                                                     cancelButton: .gotItButton()),
                                                items: PullUpSelectionViewEmptyItem.allCases)
        
        presentPullUpView(in: viewController, pullUp: .walletsMaxNumberLimitReached, contentView: selectionView, isDismissAble: true, height: selectionViewHeight)
    }
    
    func showWalletsNumberLimitReachedAlreadyPullUp(in viewController: UIViewController,
                                                    maxNumberOfWallets: Int) {
        let selectionViewHeight: CGFloat = 268
        let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.walletsLimitReachedAlreadyPullUpTitle.localized()),
                                                                     contentAlignment: .center,
                                                                     icon: .init(icon: .warningIcon,
                                                                                 size: .small,
                                                                                 tintColor: .foregroundWarning),
                                                                     subtitle: .label(.text(String.Constants.walletsLimitReachedAlreadyPullUpSubtitle.localized(maxNumberOfWallets))),
                                                                     cancelButton: .gotItButton()),
                                                items: PullUpSelectionViewEmptyItem.allCases)
        
        presentPullUpView(in: viewController, pullUp: .walletsMaxNumberLimitReachedAlready, contentView: selectionView, isDismissAble: true, height: selectionViewHeight)
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
