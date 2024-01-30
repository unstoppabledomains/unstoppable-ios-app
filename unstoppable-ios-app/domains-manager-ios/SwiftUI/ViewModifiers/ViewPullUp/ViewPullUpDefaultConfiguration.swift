//
//  ViewPullUpConfiguration.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.01.2024.
//

import UIKit

struct ViewPullUpDefaultConfiguration {
    let id = UUID()
    var icon: IconContent? = nil
    var title: LabelType?
    var subtitle: Subtitle? = nil
    var contentAlignment: ContentAlignment = .center
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
        
        var size: CGFloat {
            switch self {
            case .largeCentered, .large:
                return 56
            case .small:
                return 40
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
        
        var height: CGFloat {
            switch self {
            case .main, .secondary, .primaryDanger, .secondaryDanger, .applePay, .raisedTertiary, .primaryGhost:
                return 48
            case .textTertiary:
                return 24
            }
        }
        
        @MainActor
        func callAction() {
            switch self {
            case .main(let content), .secondary(let content), .textTertiary(let content), .primaryDanger(let content), .secondaryDanger(let content), .applePay(let content), .raisedTertiary(let content), .primaryGhost(let content):
                content.action?()
            }
        }
        
        var content: ButtonContent {
            switch self {
            case .main(let content), .secondary(let content), .textTertiary(let content), .primaryDanger(let content), .secondaryDanger(let content), .applePay(let content), .raisedTertiary(let content), .primaryGhost(let content):
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
        height += 30 // Safe area
        
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
            height += heightForSubtitle(subtitle,
                                        contentWidth: contentWidth)
            height += 8 // Space from title
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
        let font = UIFont.currentFont(withSize: fontSize, weight: fontWeight)
        switch labelType {
        case .text(let text):
            return text.height(withConstrainedWidth: contentWidth, font: font)
        case .highlightedText(let description):
            return description.text.height(withConstrainedWidth: contentWidth, font: font)
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
    
    static func recordDoesNotMatchOwner(chain: BlockchainType,
                                        ownerAddress: String,
                                        updateRecordsCallback: @escaping MainActorAsyncCallback) async -> ViewPullUpDefaultConfiguration {
        let icon = await appContext.imageLoadingService.loadImage(from: .currencyTicker(chain.rawValue,
                                                                                        size: .default,
                                                                                        style: .gray),
                                                                  downsampleDescription: .icon)
        
        return .init(icon: .init(icon: icon ?? .appleIcon,
                                 size: .large),
                     title: .text(String.Constants.recordDoesNotMatchOwnersAddressPullUpTitle.localized(chain.fullName)),
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
    
}

