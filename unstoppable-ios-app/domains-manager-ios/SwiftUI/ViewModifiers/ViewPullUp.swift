//
//  ViewPullUp.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.12.2023.
//

import SwiftUI

struct ViewPullUp: ViewModifier {
    
    static let sideOffset: CGFloat = 16
    static let headerSpacing: CGFloat = 36
    static let imageSize: CGFloat = 40
    static let titleLineHeight: CGFloat = 28
    
    @Binding var configuration: ViewPullUpConfiguration?
    var isPresented: Binding<Bool> {
        Binding {
            configuration != nil
        } set: { _ in
            configuration = nil
        }
    }
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: isPresented, content: {
                if #available(iOS 16.0, *) {
                    pullUpContentView()
                        .presentationDetents([.height(configuration?.calculateHeight() ?? 0)])
                } else {
                    pullUpContentView()
                }
            })
    }
    
    private func closeAndPassCallback(_ callback: MainActorAsyncCallback?) {
        configuration = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            callback?()
        }
    }
    
}

// MARK: - View builders
private extension ViewPullUp {
    @ViewBuilder
    func pullUpContentView() -> some View {
        if let configuration {
            VStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 2)
                    .frame(width: 40, height: 4)
                    .foregroundStyle(Color.foregroundSubtle)
                if let icon = configuration.icon {
                    viewForIconContent(icon)
                        .padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
                }
                VStack(spacing: 8) {
                    if let label = configuration.title {
                        labelViewFor(labelType: label,
                                     fontSize: 22,
                                     fontWeight: .bold,
                                     textColor: .foregroundDefault,
                                     lineHeight: 28)
                    }
                    if let subtitle = configuration.subtitle {
                        subtitleView(subtitle)
                    }
                }
                .multilineTextAlignment(alignmentFrom(textAlignment: getCurrentContentAlignment()))
                
                if let actionButton = configuration.actionButton {
                    buttonViewFor(buttonType: actionButton)
                        .padding(EdgeInsets(top: 14, leading: 0, bottom: 0, trailing: 0))
                }
                
                if let extraButton = configuration.extraButton {
                    buttonViewFor(buttonType: extraButton)
                }
                if let cancelButton = configuration.cancelButton {
                    buttonViewFor(buttonType: cancelButton)
                }
                Spacer()
            }
            .padding(EdgeInsets(top: ViewPullUp.sideOffset,
                                leading: ViewPullUp.sideOffset,
                                bottom: ViewPullUp.sideOffset,
                                trailing: ViewPullUp.sideOffset))
            .interactiveDismissDisabled(!configuration.dismissAble)
            .onAppear {
                appContext.analyticsService.log(event: .pullUpDidAppear,
                                                withParameters: [.pullUpName : configuration.analyticName.rawValue])
            }
            .onDisappear {
                appContext.analyticsService.log(event: .pullUpClosed,
                                                withParameters: [.pullUpName : configuration.analyticName.rawValue])
            }
        }
    }
    
    @ViewBuilder
    func labelViewFor(labelType: ViewPullUpConfiguration.LabelType,
                      fontSize: CGFloat,
                      fontWeight: UIFont.Weight,
                      textColor: UIColor,
                      lineHeight: CGFloat) -> some View {
        switch labelType {
        case .text(let text):
            Text(text)
                .font(.currentFont(size: fontSize, weight: fontWeight))
                .foregroundStyle(Color(uiColor: textColor))
        case .highlightedText(let description):
            AttributedText(attributesList: .init(text: description.text,
                                                 font: .currentFont(withSize: fontSize, weight: fontWeight),
                                                 textColor: textColor,
                                                 alignment: getCurrentContentAlignment(),
                                                 lineHeight: lineHeight),
                           width: UIScreen.main.bounds.width - (ViewPullUp.sideOffset * 2),
                           updatedAttributesList: description.highlightedText.map { AttributedText.AttributesList(text: $0.highlightedText,
                                                                                                                  textColor: $0.highlightedColor) })
            .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    func alignmentFrom(textAlignment: NSTextAlignment) -> TextAlignment {
        switch textAlignment {
        case .left:
            return .leading
        case .center:
            return .center
        case .right:
            return .trailing
        case .justified:
            return .center
        case .natural:
            return .center
        @unknown default:
            return .center
        }
    }
    
    func getCurrentContentAlignment() -> NSTextAlignment {
        switch configuration?.contentAlignment {
        case .left:
            return .left
        case .center, nil:
            return .center
        }
    }
    
    @ViewBuilder
    func subtitleView(_ subtitle: ViewPullUpConfiguration.Subtitle) -> some View {
        switch subtitle {
        case .label(let label):
            labelViewFor(labelType: label,
                         fontSize: 16,
                         fontWeight: .regular,
                         textColor: .foregroundSecondary, 
                         lineHeight: 24)
        case .button(let button):
            buttonViewFor(buttonType: button)
        }
    }
    
    @ViewBuilder
    func buttonViewFor(buttonType: ViewPullUpConfiguration.ButtonType) -> some View {
        switch buttonType {
        case .main(let content):
            buttonWithContent(content, style: .large(.raisedPrimary))
        case .primaryDanger(let content):
            buttonWithContent(content, style: .large(.raisedDanger))
        case .secondary(let content):
            buttonWithContent(content, style: .large(.raisedTertiary))
        case .secondaryDanger(let content):
            buttonWithContent(content, style: .large(.ghostDanger))
        case .textTertiary(let content):
            buttonWithContent(content, style: .medium(.ghostTertiary))
        case .applePay(let content):
            buttonWithContent(content, style: .large(.applePay))
        case .raisedTertiary(let content):
            buttonWithContent(content, style: .medium(.raisedTertiary))
        }
    }
    
    @ViewBuilder
    func buttonWithContent(_ content: ViewPullUpConfiguration.ButtonContent,
                           style: UDButtonStyle) -> some View {
        UDButtonView(text: content.title,
                     icon: content.icon == nil ? nil : Image(uiImage: content.icon!),
                     iconAlignment: buttonIconAlignmentFor(buttonImageLayout: content.imageLayout),
                     style: style,
                     isLoading: content.isLoading, isSuccess: content.isSuccessState, callback: {
            appContext.analyticsService.log(event: .buttonPressed,
                                            withParameters: [.button : content.analyticsName.rawValue,
                                                             .pullUpName: configuration?.analyticName.rawValue ?? ""])
            closeAndPassCallback(content.action)
        })
        .allowsHitTesting(content.isUserInteractionEnabled)
    }
    
    func buttonIconAlignmentFor(buttonImageLayout: ButtonImageLayout) -> UDButtonImage.Alignment {
        switch buttonImageLayout {
        case .leading:
            return .left
        case .trailing:
            return .right
        }
    }
    
    @ViewBuilder
    func viewForIconContent(_ iconContent: ViewPullUpConfiguration.IconContent) -> some View {
        Image(uiImage: iconContent.icon.templateImageOfSize(.square(size: iconContent.iconSize)))
            .resizable()
            .squareFrame(iconContent.iconSize)
            .foregroundStyle(Color(uiColor: iconContent.tintColor))
    }
}

extension View {
    func viewPullUp(_ configuration: Binding<ViewPullUpConfiguration?>) -> some View {
        self.modifier(ViewPullUp(configuration: configuration))
    }
}

fileprivate extension ViewPullUpConfiguration {
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
    
    private func heightForLabel(_ labelType: ViewPullUpConfiguration.LabelType,
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
    
    private func heightForSubtitle(_ subtitle: ViewPullUpConfiguration.Subtitle,
                                   contentWidth: CGFloat) -> CGFloat {
        switch subtitle {
        case .label(let labelType):
            return heightForLabel(labelType, fontSize: 16, fontWeight: .regular, contentWidth: contentWidth)
        case .button(let buttonType):
            return buttonType.height
        }
    }
    
    private func heightForButtonType(_ buttonType: ViewPullUpConfiguration.ButtonType,
                                     contentWidth: CGFloat) -> CGFloat {
        buttonType.height
    }
    
    func heightForIconContent(_ iconContent: IconContent) -> CGFloat {
        iconContent.iconSize
    }
}

struct ViewPullUpConfiguration {
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
        case secondary(content: ButtonContent)
        case secondaryDanger(content: ButtonContent)
        case textTertiary(content: ButtonContent)
        case applePay(content: ButtonContent)
        case raisedTertiary(content: ButtonContent)
        
        var height: CGFloat {
            switch self {
            case .main, .secondary, .primaryDanger, .secondaryDanger, .applePay, .raisedTertiary:
                return 48
            case .textTertiary:
                return 24
            }
        }
        
        @MainActor
        func callAction() {
            switch self {
            case .main(let content), .secondary(let content), .textTertiary(let content), .primaryDanger(let content), .secondaryDanger(let content), .applePay(let content), .raisedTertiary(let content):
                content.action?()
            }
        }
        
        var content: ButtonContent {
            switch self {
            case .main(let content), .secondary(let content), .textTertiary(let content), .primaryDanger(let content), .secondaryDanger(let content), .applePay(let content), .raisedTertiary(let content):
                return content
            }
        }
    }
}


