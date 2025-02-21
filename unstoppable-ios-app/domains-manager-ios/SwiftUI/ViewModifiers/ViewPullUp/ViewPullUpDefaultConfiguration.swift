//
//  ViewPullUpConfiguration.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.01.2024.
//

import UIKit

struct ViewPullUpDefaultConfiguration {
    typealias ItemCallback = ((PullUpCollectionViewCellItem)->())
    
    let id = UUID()
    var icon: IconContent? = nil
    var title: LabelType?
    var subtitle: Subtitle? = nil
    var contentAlignment: ContentAlignment = .center
    var items: [PullUpCollectionViewCellItem] = PullUpSelectionViewEmptyItem.allCases
    var itemSelectedCallback: ItemCallback? = nil
    var actionButton: ButtonType? = nil
    var extraButton: ButtonType? = nil
    var cancelButton: ButtonType? = nil
    var isScrollingEnabled: Bool = false
    var dismissAble: Bool = true
    var analyticName: Analytics.PullUp
    var additionalAnalyticParameters: Analytics.EventParameters = [:]
    var dismissCallback: EmptyCallback? = nil

    // Title
    enum LabelType {
        case text(_ text: String)
        case highlightedText(_ highlightedText: HighlightedText)
    }
    
    struct HighlightedText {
        let text: String
        let highlightedText: [HighlightedTextDescription]
        let analyticsActionName: Analytics.Button?
        let action: EmptyCallback?
    }
    
    struct HighlightedTextDescription {
        let highlightedText: String
        let highlightedColor: UIColor
    }
    
    // Content
    enum ContentAlignment {
        case left, center
        
        var textAlignment: NSTextAlignment {
            switch self {
            case .left:
                return .left
            case .center:
                return .center
            }
        }
    }
    
    // Subtitle
    enum Subtitle {
        case label(_ label: LabelType)
        case button(_ button: ButtonType)
    }
    
    // Icon
    enum IconSize {
        case largeCentered, large, small
        case fixedHeight(CGFloat)
        
        var size: CGFloat {
            switch self {
            case .largeCentered, .large:
                return 56
            case .small:
                return 40
            case .fixedHeight(let height):
                return height
            }
        }
    }
    
    enum IconCorners {
        case none, circle, custom(_ value: CGFloat)
    }
    
    struct IconContent {
        let icon: UIImage
        let size: IconSize
        var corners: IconCorners = .none
        var backgroundColor: UIColor = .clear
        var tintColor: UIColor = .foregroundMuted
        
        var iconSize: CGFloat { size.size }
    }
    
    // Button
    struct ButtonContent: Equatable {
        let title: String
        var icon: UIImage? = nil
        var imageLayout: ButtonImageLayout = .leading
        var analyticsName: Analytics.Button
        var isSuccessState: Bool = false
        var isLoading: Bool = false
        var isUserInteractionEnabled: Bool = true
        let action: MainActorAsyncCallback?
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.title == rhs.title
        }
        
    }
    
    enum ButtonType: Equatable {
        static let cancelButton: ButtonType = .secondary(content: .init(title: String.Constants.cancel.localized(),
                                                                        icon: nil,
                                                                        analyticsName: .cancel,
                                                                        action: nil))
        static let laterButton: ButtonType = .secondary(content: .init(title: String.Constants.later.localized(),
                                                                       icon: nil,
                                                                       analyticsName: .later,
                                                                       action: nil))
        static let continueButton: ButtonType = .main(content: .init(title: String.Constants.continue.localized(),
                                                                       icon: nil,
                                                                       analyticsName: .continue,
                                                                       action: nil))
        static func gotItButton(action: MainActorAsyncCallback? = nil) -> ButtonType {
            .secondary(content: .init(title: String.Constants.gotIt.localized(),
                                      icon: nil,
                                      analyticsName: .gotIt,
                                      action: action))
        }
        
        case main(content: ButtonContent)
        case primaryDanger(content: ButtonContent)
        case primaryGhost(content: ButtonContent)
        case secondary(content: ButtonContent)
        case secondaryDanger(content: ButtonContent)
        case textTertiary(content: ButtonContent)
        case applePay(content: ButtonContent)
        case raisedTertiary(content: ButtonContent)
        case largeRaisedTertiary(content: ButtonContent)
        
        var height: CGFloat {
            switch self {
            case .main, .secondary, .primaryDanger, .secondaryDanger, .applePay, .raisedTertiary, .primaryGhost, .largeRaisedTertiary:
                return 48
            case .textTertiary:
                return 24
            }
        }
        
        @MainActor
        func callAction() {
            switch self {
            case .main(let content), .secondary(let content), .textTertiary(let content), .primaryDanger(let content), .secondaryDanger(let content), .applePay(let content), .raisedTertiary(let content), .primaryGhost(let content), .largeRaisedTertiary(let content):
                content.action?()
            }
        }
        
        var content: ButtonContent {
            switch self {
            case .main(let content), .secondary(let content), .textTertiary(let content), .primaryDanger(let content), .secondaryDanger(let content), .applePay(let content), .raisedTertiary(let content), .primaryGhost(let content), .largeRaisedTertiary(let content):
                return content
            }
        }
    }
}

extension ViewPullUpDefaultConfiguration {
    @MainActor
    func calculateHeight() -> CGFloat {
        let contentWidth = UIScreen.main.bounds.width - (ViewPullUp.sideOffset * 2)
        var height = ViewPullUp.headerSpacing
        height += 44 // Safe area
        
        if icon != nil {
            height += ViewPullUp.imageSize
        }
        
        if let title {
            height += heightForLabel(title,
                                     fontSize: 22,
                                     fontWeight: .bold,
                                     contentWidth: contentWidth)
        }
        
        if let icon {
            height += heightForIconContent(icon)
            height += ViewPullUp.sideOffset
        }
        
        if let subtitle {
            height += 8 // Space from title
            height += heightForSubtitle(subtitle,
                                        contentWidth: contentWidth)
        }
        
        if !items.isEmpty {
            let itemsHeight = items.reduce(0.0, { $0 + $1.height }) 
            height += itemsHeight
            height += ViewPullUp.listContentPadding * 2 // Top and bottom
            height += ViewPullUp.sideOffset
        }
        
        if let actionButton {
            height += heightForButtonType(actionButton,
                                          contentWidth: contentWidth)
            height += ViewPullUp.sideOffset
        }
        if let extraButton {
            height += heightForButtonType(extraButton,
                                          contentWidth: contentWidth)
            height += ViewPullUp.sideOffset
        }
        if let cancelButton {
            height += heightForButtonType(cancelButton,
                                          contentWidth: contentWidth)
            height += ViewPullUp.sideOffset
        }
        
        return height
    }
    
    private func heightForLabel(_ labelType: ViewPullUpDefaultConfiguration.LabelType,
                                fontSize: CGFloat,
                                fontWeight: UIFont.Weight,
                                contentWidth: CGFloat) -> CGFloat {
        switch labelType {
        case .text(let text):
            let font = UIFont.currentFont(withSize: fontSize, weight: fontWeight)
            return text.height(withConstrainedWidth: contentWidth, font: font)
        case .highlightedText(let description):
            return heightForLabel(.text(description.text), fontSize: fontSize, fontWeight: fontWeight, contentWidth: contentWidth)
        }
    }
    
    private func heightForSubtitle(_ subtitle: ViewPullUpDefaultConfiguration.Subtitle,
                                   contentWidth: CGFloat) -> CGFloat {
        switch subtitle {
        case .label(let labelType):
            return heightForLabel(labelType, fontSize: 16, fontWeight: .regular, contentWidth: contentWidth)
        case .button(let buttonType):
            return buttonType.height
        }
    }
    
    private func heightForButtonType(_ buttonType: ViewPullUpDefaultConfiguration.ButtonType,
                                     contentWidth: CGFloat) -> CGFloat {
        buttonType.height
    }
    
    func heightForIconContent(_ iconContent: IconContent) -> CGFloat {
        iconContent.iconSize
    }
}

// MARK: - Open methods
extension ViewPullUpDefaultConfiguration {
    static func wcConnectionFailed(dismissCallback: EmptyCallback? = nil) -> ViewPullUpDefaultConfiguration {
        .init(icon: .init(icon: .grimaseIcon,
                          size: .small),
              title: .text(String.Constants.signTransactionFailedAlertTitle.localized()),
              subtitle: .label(.text(String.Constants.signTransactionFailedAlertDescription.localized())),
              cancelButton: .gotItButton(),
              analyticName: .wcConnectionFailed,
              dismissCallback: dismissCallback)
    }
    
    static func wcTransactionFailed(dismissCallback: EmptyCallback? = nil) -> ViewPullUpDefaultConfiguration {
        .init(icon: .init(icon: .cancelCircleIcon,
                          size: .small),
              title: .text(String.Constants.transactionFailed.localized()),
              subtitle: .label(.text(String.Constants.signTransactionFailedAlertDescription.localized())),
              cancelButton: .gotItButton(),
              analyticName: .wcTransactionFailed,
              dismissCallback: dismissCallback)
    }
    
    static func wcNetworkNotSupported(dismissCallback: EmptyCallback? = nil) -> ViewPullUpDefaultConfiguration {
        .init(icon: .init(icon: .grimaseIcon,
                          size: .small),
              title: .text(String.Constants.networkNotSupportedInfoTitle.localized()),
              subtitle: .label(.text(String.Constants.networkNotSupportedInfoDescription.localized())),
              cancelButton: .gotItButton(),
              analyticName: .wcNetworkNotSupported,
              dismissCallback: dismissCallback)
    }
    
    static func wcLowBalance(dismissCallback: EmptyCallback? = nil) -> ViewPullUpDefaultConfiguration {
        .init(icon: .init(icon: .cancelCircleIcon,
                          size: .small),
              title: .text(String.Constants.insufficientBalance.localized()),
              subtitle: .label(.text(String.Constants.walletConnectLowBalanceAlertDescription.localized())),
              cancelButton: .gotItButton(),
              analyticName: .wcLowBalance,
              dismissCallback: dismissCallback)
    }
    
    static func wcRequestNotSupported(dismissCallback: EmptyCallback? = nil) -> ViewPullUpDefaultConfiguration {
        .init(icon: .init(icon: .grimaseIcon,
                          size: .small),
              title: .text(String.Constants.wcRequestNotSupportedInfoTitle.localized()),
              subtitle: .label(.text(String.Constants.wcRequestNotSupportedInfoDescription.localized())),
              cancelButton: .gotItButton(),
              analyticName: .wcRequestNotSupported,
              dismissCallback: dismissCallback)
    }
    
    static func recordDoesNotMatchOwner(ticker: String,
                                        fullName: String,
                                        ownerAddress: String,
                                        updateRecordsCallback: @escaping MainActorAsyncCallback) async -> ViewPullUpDefaultConfiguration {
        let icon = await appContext.imageLoadingService.loadImage(from: .currencyTicker(ticker,
                                                                                        size: .default,
                                                                                        style: .gray),
                                                                  downsampleDescription: .icon)
        
        return .init(icon: .init(icon: icon ?? .appleIcon,
                                 size: .large),
                     title: .text(String.Constants.recordDoesNotMatchOwnersAddressPullUpTitle.localized(fullName)),
                     subtitle: .label(.highlightedText(.init(text: String.Constants.recordDoesNotMatchOwnersAddressPullUpMessage.localized(ownerAddress.walletAddressTruncated),
                                                             highlightedText: [.init(highlightedText: ownerAddress.walletAddressTruncated, highlightedColor: .foregroundDefault)], analyticsActionName: nil, action: nil))),
                     actionButton: .main(content: .init(title: String.Constants.gotIt.localized(),
                                                        analyticsName: .gotIt,
                                                        action: nil)),
                     extraButton: .primaryGhost(content: .init(title: String.Constants.updateRecords.localized(),
                                                               analyticsName: .aboutProfile,
                                                               action: updateRecordsCallback)),
                     analyticName: .wcRequestNotSupported,
                     dismissCallback: nil)
    }
    
    static func showFinishSetupProfilePullUp(pendingProfile: DomainProfilePendingChanges,
                                             signCallback: @escaping MainActorAsyncCallback) -> ViewPullUpDefaultConfiguration {
        let domainName = pendingProfile.domainName
        
        return .init(icon: .init(icon: .infoIcon,
                                 size: .large),
                     title: .highlightedText(.init(text: String.Constants.finishSetupProfilePullUpTitle.localized(String(domainName.prefix(40))),
                                                   highlightedText: [.init(highlightedText: domainName, highlightedColor: .foregroundSecondary)],
                                                   analyticsActionName: nil,
                                                   action: nil)),
                     subtitle: .label(.text(String.Constants.finishSetupProfilePullUpSubtitle.localized())),
                     actionButton: .main(content: .init(title: String.Constants.signTransaction.localized(),
                                                        analyticsName: .confirm,
                                                        action: signCallback)),
                     dismissAble: false,
                     analyticName: .finishProfileForPurchasedDomains,
                     dismissCallback: nil)
    }
    
    static func showFinishSetupProfileFailedPullUp(completion: @escaping ((Result<Void, Error>)->())) -> ViewPullUpDefaultConfiguration  {
        
        let title = String.Constants.finishSetupProfileFailedPullUpTitle.localized()
        
        
        return .init(icon: .init(icon: .grimaseIcon,
                                 size: .small),
                     title: .text(title),
                     subtitle: .label(.text(String.Constants.finishSetupProfilePullUpSubtitle.localized())),
                     actionButton: .main(content: .init(title: String.Constants.tryAgain.localized(),
                                                        analyticsName: .tryAgain,
                                                        action: { completion(.success(Void())) })),
                     cancelButton: .primaryGhost(content: .init(title: String.Constants.cancelSetup.localized(),
                                                                icon: nil,
                                                                analyticsName: .cancel,
                                                                action: { completion(.failure(PullUpError.dismissed)) })),
                     analyticName: .failedToFinishProfileForPurchasedDomains,
                     dismissCallback: nil)
    }
    
    static func showCreateYourProfilePullUp(buyCallback: @escaping MainActorAsyncCallback) -> ViewPullUpDefaultConfiguration {
        return .init(icon: .init(icon: .createProfilePullUpIllustration,
                                 size: .fixedHeight(132)),
                     title: .text(String.Constants.createYourProfilePullUpTitle.localized()),
                     subtitle: .label(.text(String.Constants.createYourProfilePullUpSubtitle.localized())),
                     actionButton: .main(content: .init(title: String.Constants.buyDomain.localized(),
                                                        analyticsName: .buyDomains,
                                                        action: buyCallback)),
                     cancelButton: .secondary(content: .init(title: String.Constants.gotIt.localized(),
                                                             analyticsName: .gotIt,
                                                             action: nil)),
                     dismissAble: true,
                     analyticName: .createYourProfile,
                     dismissCallback: nil)
    }
    
    static func legalSelectionPullUp(selectionCallback: @escaping (LegalType)->()) -> ViewPullUpDefaultConfiguration {
        var selectedItem: LegalType?
        
        return .init(title: .text(String.Constants.settingsLegal.localized()),
                     items: LegalType.allCases,
                     itemSelectedCallback: { item in
            selectedItem = item as? LegalType
        },
                     dismissAble: true,
                     analyticName: .settingsLegalSelection,
                     dismissCallback: {
            if let selectedItem {
                selectionCallback(selectedItem)
            }
        })
    }
    
    static func homeWalletBuySelectionPullUp(selectionCallback: @escaping (HomeWalletView.BuyOptions)->()) -> ViewPullUpDefaultConfiguration {
        var selectedItem: HomeWalletView.BuyOptions?
        
        return .init(title: nil,
                     items: HomeWalletView.BuyOptions.allCases,
                     itemSelectedCallback: { item in
            selectedItem = item as? HomeWalletView.BuyOptions
        },
                     dismissAble: true,
                     analyticName: .homeWalletBuyOptions,
                     dismissCallback: {
            if let selectedItem {
                selectionCallback(selectedItem)
            }
        })
    }
    
    static func maxCryptoSendInfoPullUp(token: BalanceTokenUIDescription) -> ViewPullUpDefaultConfiguration {
        .init(icon: .init(icon: .infoBubble,
                          size: .small),
              title: .text(String.Constants.sendMaxCryptoInfoPullUpTitle.localized(token.symbol)),
              cancelButton: .continueButton,
              analyticName: .sendMaxCryptoInfo)
    }
    
    static func showUserDidNotSetRecordToDomainToSendCryptoPullUp(domainName: String,
                                                                  chatCallback: @escaping MainActorAsyncCallback) -> ViewPullUpDefaultConfiguration {
        return .init(icon: .init(icon: .squareInfo,
                                 size: .large),
                     title: .text(String.Constants.noRecordsToSendCryptoPullUpTitle.localized(domainName)),
                     subtitle: .label(.text(String.Constants.noRecordsToSendCryptoMessage.localized())),
                     actionButton: .main(content: .init(title: String.Constants.chatToNotify.localized(),
                                                        analyticsName: .messaging,
                                                        action: chatCallback)),
                     cancelButton: .secondary(content: .init(title: String.Constants.gotIt.localized(),
                                                             analyticsName: .gotIt,
                                                             action: nil)),
                     dismissAble: true,
                     analyticName: .noRecordsSetToSendCrypto,
                     dismissCallback: nil)
    }
    
    static func showSendCryptoForTheFirstTimeConfirmationPullUp(confirmCallback: @escaping MainActorAsyncCallback) -> ViewPullUpDefaultConfiguration {
        var icon: UIImage?
        if User.instance.getSettings().touchIdActivated,
           let image = appContext.authentificationService.biometricIcon {
            icon = image
        }
        return .init(icon: .init(icon: .paperPlaneTopRightSend,
                                 size: .small),
                     title: .text(String.Constants.sendCryptoFirstTimePullUpTitle.localized()),
                     subtitle: .label(.text(String.Constants.sendCryptoFirstTimePullUpSubtitle.localized())),
                     actionButton: .secondary(content: .init(title: String.Constants.reviewTxAgain.localized(),
                                                             analyticsName: .reviewTxAgain,
                                                             action: nil)),
                     cancelButton: .main(content: .init(title: String.Constants.confirmAndSend.localized(),
                                                        icon: icon,
                                                        analyticsName: .confirm,
                                                        action: confirmCallback)),
                     dismissAble: true,
                     analyticName: .sendCryptoForTheFirstTimeConfirmation,
                     dismissCallback: nil)
    }
    
    static func loginOptionsSelectionPullUp(selectionCallback: @escaping (LoginProvider)->()) -> ViewPullUpDefaultConfiguration {
        var selectedItem: LoginProvider?
        
        return .init(icon: .init(icon: .vaultSafeIcon, size: .large),
                     title: .text(String.Constants.viewOrMoveVaultedDomains.localized()),
                     items: LoginProvider.allCases,
                     itemSelectedCallback: { item in
            selectedItem = item as? LoginProvider
        },
                     dismissAble: true,
                     analyticName: .settingsLoginSelection,
                     dismissCallback: {
            if let selectedItem {
                selectionCallback(selectedItem)
            }
        })
    }
    
    static func askToReconnectMPCWalletPullUp(walletAddress: HexAddress,
                                              removeCallback: @escaping MainActorAsyncCallback) -> ViewPullUpDefaultConfiguration {
        return .init(icon: .init(icon: .trashFill,
                                 size: .small),
                     title: .text(String.Constants.removeMPCWalletPullUpTitle.localizedMPCProduct()),
                     subtitle: .label(.text(String.Constants.removeMPCWalletPullUpSubtitle.localized())),
                     actionButton: .primaryDanger(content: .init(title: String.Constants.removeWallet.localized(),
                                                                 analyticsName: .walletRemove,
                                                                 action: {
            removeCallback()
        })),
                     cancelButton: .secondary(content: .init(title: String.Constants.cancel.localized(),
                                                             analyticsName: .cancel,
                                                             action: nil)),
                     dismissAble: true,
                     analyticName: .removeMPCWalletConfirmation,
                     dismissCallback: nil)
    }
    
    static func buyDomainFromTheWebsite(goToWebCallback: MainActorAsyncCallback?) -> ViewPullUpDefaultConfiguration {
        .init(icon: .init(icon: .unsTLDLogo,
                          size: .small),
              title: .text(String.Constants.buyDomainFromWebPullUpTitle.localized()),
              subtitle: .label(.text(String.Constants.buyDomainFromWebPullUpSubtitle.localized())),
              actionButton: .main(content: .init(title: String.Constants.goToWebsite.localized(),
                                                 analyticsName: .goToWebsite,
                                                 action: goToWebCallback)),
              analyticName: .wcRequestNotSupported)
    }
    
    static func checkoutFromTheWebsite(goToWebCallback: MainActorAsyncCallback?) -> ViewPullUpDefaultConfiguration {
        .init(icon: .init(icon: .unsTLDLogo,
                          size: .small),
              title: .text(String.Constants.checkoutFromWebPullUpTitle.localized()),
              subtitle: .label(.text(String.Constants.checkoutFromWebPullUpSubtitle.localized())),
              actionButton: .main(content: .init(title: String.Constants.goToWebsite.localized(),
                                                 analyticsName: .goToWebsite,
                                                 action: goToWebCallback)),
              analyticName: .wcRequestNotSupported)
    }
    
    static func transferDomainsFromVaultUnavailable() -> ViewPullUpDefaultConfiguration {
        .init(icon: .init(icon: .hammerWrenchIcon24,
                          size: .small),
              title: .text(String.Constants.transferDomainsFromVaultMaintenanceMessageTitle.localized()),
              subtitle: .label(.text(String.Constants.transferDomainsFromVaultMaintenanceMessageSubtitle.localized())),
              cancelButton: .gotItButton(),
              analyticName: .transferDomainsFromVaultMaintenance)
    }
    
    static func mpc2FAEnabled(disableCallback: @escaping MainActorAsyncCallback) -> ViewPullUpDefaultConfiguration {
        .init(icon: .init(icon: .shieldCheckmarkFilled,
                          size: .small,
                          tintColor: .foregroundSuccess),
              title: .text(String.Constants.mpc2FAEnabledPullUpTitle.localized()),
              subtitle: .label(.text(String.Constants.mpc2FAEnabledPullUpSubtitle.localized())),
              actionButton: .largeRaisedTertiary(content: .init(title: String.Constants.disable2FA.localized(),
                                                 analyticsName: .disable2FA,
                                                 action: disableCallback)),
              analyticName: .mpc2FAEnabled)
    }
    
    static func mpc2FADisableConfirmation(disableCallback: @escaping MainActorAsyncCallback) -> ViewPullUpDefaultConfiguration {
        .init(icon: .init(icon: .warningIcon,
                          size: .small),
              title: .text(String.Constants.mpc2FADisableConfirmationPullUpTitle.localized()),
              subtitle: .label(.text(String.Constants.mpc2FADisableConfirmationPullUpSubtitle.localized())),
              actionButton: .primaryDanger(content: .init(title: String.Constants.disable2FA.localized(),
                                                          analyticsName: .disable2FA,
                                                          action: disableCallback)),
              cancelButton: .secondary(content: .init(title: String.Constants.cancel.localized(),
                                                      analyticsName: .cancel,
                                                      action: nil)),
              analyticName: .mpc2FADisableConfirmation)
    }
    
}

// MARK: - Open methods
extension ViewPullUpDefaultConfiguration {
    enum PullUpError: Error {
        case dismissed
    }
}
