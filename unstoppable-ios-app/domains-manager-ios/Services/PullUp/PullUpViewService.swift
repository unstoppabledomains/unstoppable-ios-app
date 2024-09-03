//
//  PullUpViewService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.05.2022.
//

import UIKit

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
            var actions = actions
            var actionButton: PullUpSelectionViewConfiguration.ButtonType?
            if actions.contains(.create) {
                actions.removeAll(where: { $0 == .create })
                actionButton = .raisedTertiary(content: .init(title: String.Constants.createNew.localized(),
                                                              icon: nil,
                                                              analyticsName: .createVault,
                                                              action: {
                    continuation(.success(.create))
                }))
            }
            var selectionViewHeight: CGFloat = 72 + (CGFloat(actions.count) * PullUpCollectionViewCell.Height)
            if actionButton != nil {
                selectionViewHeight += 72
            }
            
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
                                                                         subtitle: subtitleConfiguration,
                                                                         actionButton: actionButton),
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
            if walletInfo.source == .mpc {
                subtitle = String.Constants.removeWalletAlertSubtitleMPC.localized()
            } else {
                subtitle = walletInfo.isWithPrivateKey ? String.Constants.removeWalletAlertSubtitlePrivateKey.localized() : String.Constants.removeWalletAlertSubtitleRecoveryPhrase.localized()
            }
            buttonTitle = String.Constants.removeWallet.localized()
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
    
    func showDomainMintedOnChainDescriptionPullUp(in viewController: UIViewController,
                                                  chain: BlockchainType) {
        let selectionViewHeight: CGFloat
        let icon = chain.icon
        let description: String
        switch chain {
        case .Ethereum:
            description = String.Constants.mintedOnEthereumDescription.localized()
            selectionViewHeight = 328
        case .Matic:
            description = String.Constants.mintedOnPolygonDescription.localized()
            selectionViewHeight = 304
        case .Base:
            description = String.Constants.mintedOnBaseDescription.localized()
            selectionViewHeight = 304
        case .Bitcoin, .Solana:
            Debugger.printFailure("Minting can be only on Ethereum and Polygon", critical: true)
            description = "\(chain.fullName)"
            selectionViewHeight = 304
        }
        
        let selectionView = PullUpSelectionView(configuration: .init(title: .text(chain.fullName),
                                                                     contentAlignment: .center,
                                                                     icon: .init(icon: icon,
                                                                                 size: .small),
                                                                     subtitle: .label(.text(description)),
                                                                     cancelButton: .gotItButton()),
                                                items: PullUpSelectionViewEmptyItem.allCases)
        
        showOrUpdate(in: viewController, pullUp: .domainMintedOnChainDescription, additionalAnalyticParameters: [.chainNetwork: chain.shortCode], contentView: selectionView, height: selectionViewHeight)
    }

    func showRecentActivitiesInfoPullUp(in viewController: UIViewController, isGetNewDomain: Bool) async throws {
        let selectionViewHeight: CGFloat = 368
        let buttonTitle = isGetNewDomain ? String.Constants.findYourDomain.localized() : String.Constants.scanToConnect.localized()
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.recentActivityInfoTitle.localized()),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .clock,
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
                                             maxNumberOfWallets: Int) async {
        await withSafeCheckedMainActorContinuation(critical: false) { completion in
            let selectionViewHeight: CGFloat = 308
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.walletsLimitReachedPullUpTitle.localized()),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .warningIcon,
                                                                                     size: .small,
                                                                                     tintColor: .foregroundWarning),
                                                                         subtitle: .label(.text(String.Constants.walletsLimitReachedPullUpSubtitle.localized(maxNumberOfWallets))),
                                                                         cancelButton: .gotItButton()),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            presentPullUpView(in: viewController, pullUp: .walletsMaxNumberLimitReached, contentView: selectionView, isDismissAble: true, height: selectionViewHeight, closedCallback: { completion(Void()) })
        }
    }
    
    func showWalletsNumberLimitReachedAlreadyPullUp(in viewController: UIViewController,
                                                    maxNumberOfWallets: Int) {
        let selectionViewHeight: CGFloat = 328
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
    
    func showCopyMultichainWalletAddressesPullUp(in viewController: UIViewController,
                                                 tokens: [BalanceTokenUIDescription]) {
        let selectionViewHeight: CGFloat = CopyMultichainWalletAddressesPullUpView.calculateHeightFor(tokens: tokens,
                                                                                                      selectionType: .copyOnly)
        let selectionView = UIHostingController(rootView: CopyMultichainWalletAddressesPullUpView(tokens: tokens,
                                                                                                  selectionType: .copyOnly,
                                                                                                  withDismissIndicator: false))
            .view!
        
        presentPullUpView(in: viewController, pullUp: .walletsMaxNumberLimitReachedAlready, contentView: selectionView, isDismissAble: true, height: selectionViewHeight)
    }
    
    func showDomainProfileInMaintenancePullUp(in viewController: UIViewController) {
        showMaintenanceInProgressPullUp(in: viewController, 
                                        pullUp: .domainProfileMaintenance,
                                        serviceType: .domainProfile,
                                        featureFlag: .isMaintenanceProfilesAPIEnabled)
    }
    
    func showMessageSigningInMaintenancePullUp(in viewController: UIViewController) {
        showMaintenanceInProgressPullUp(in: viewController,
                                        pullUp: .signMessagesMaintenance,
                                        serviceType: .signMessages,
                                        featureFlag: .isMaintenanceMPCEnabled)
    }
    
    private func showMaintenanceInProgressPullUp(in viewController: UIViewController,
                                                 pullUp: Analytics.PullUp,
                                                 serviceType: MaintenanceServiceType,
                                                 featureFlag: UDFeatureFlag) {
        let view = MaintenanceDetailsPullUpView(serviceType: serviceType, featureFlag: featureFlag)
            .frame(height: 380)
        let vc = UIHostingController(rootView: view)
        
        showIfNotPresent(in: viewController,
                         pullUp: pullUp,
                         contentView: vc.view,
                         isDismissAble: true,
                         height: 380)
    }
}

import SwiftUI

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
