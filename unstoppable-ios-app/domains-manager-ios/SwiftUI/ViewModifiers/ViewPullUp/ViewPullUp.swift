//
//  ViewPullUp.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.12.2023.
//

import SwiftUI

struct ViewPullUp: ViewModifier {
    
    static let sideOffset: CGFloat = 16
    static let headerSpacing: CGFloat = 40
    static let imageSize: CGFloat = 40
    static let titleLineHeight: CGFloat = 28
    static let listContentPadding: CGFloat = 4
    
    @Binding var type: ViewPullUpConfigurationType?
    var typeChangedCallback: ((ViewPullUpConfigurationType?)->())? = nil
    @State private var tag = 0
    @State private var dismissAnalyticParameters = Analytics.EventParameters()
    @State private var dismissCallback: EmptyCallback?
    
    func body(content: Content) -> some View {
        content
            .sheet(item: $type, onDismiss: {
                if type?.id == nil {
                    didDismissCurrentPullUp()
                }
            }, content: { type in
                pullUpContentView(type: type)
                    .onAppear {
                        appContext.analyticsService.log(event: .pullUpDidAppear,
                                                        withParameters: [.pullUpName : type.analyticName.rawValue].adding(type.additionalAnalyticParameters))
                    }
                    .presentationDetents([.height(type.calculateHeight())])
            })
            .onChange(of: type) { newValue in
                if let newValue {
                    if tag > 0  {
                        didDismissCurrentPullUp()
                    }
                    dismissCallback = newValue.dismissCallback
                    dismissAnalyticParameters = [.pullUpName : newValue.analyticName.rawValue].adding(newValue.additionalAnalyticParameters)
                }
                if newValue == nil {
                    tag = 0
                } else if tag > 0 {
                    withAnimation {
                        type = newValue
                        tag += 1
                    }
                } else {
                    tag += 1
                }
                typeChangedCallback?(newValue)
            }
    }
    
    private func closeAndPassCallback(_ callback: MainActorAsyncCallback?) {
        close()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            callback?()
        }
    }
    
    func close() {
        type = nil
    }
    
    private func didDismissCurrentPullUp() {
        appContext.analyticsService.log(event: .pullUpClosed,
                                        withParameters: dismissAnalyticParameters)
        dismissCallback?()
    }
}

// MARK: - View builders
private extension ViewPullUp {
    @ViewBuilder
    func pullUpContentView(type: ViewPullUpConfigurationType) -> some View {
        switch type {
        case .default(let configuration):
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
                        labelViewFor(configuration: configuration,
                                     labelType: label,
                                     fontSize: 22,
                                     fontWeight: .bold,
                                     textColor: .foregroundDefault,
                                     lineHeight: 28)
                    }
                    if let subtitle = configuration.subtitle {
                        subtitleViewFor(configuration: configuration, subtitle: subtitle)
                    }
                }
                .multilineTextAlignment(alignmentFrom(textAlignment: getCurrentContentAlignment(configuration: configuration)))
                
                
                viewForItemsList(items: configuration.items,
                                 selectionCallback: configuration.itemSelectedCallback)
                
                if let actionButton = configuration.actionButton {
                    buttonViewFor(configuration: configuration, buttonType: actionButton)
                        .padding(EdgeInsets(top: 14, leading: 0, bottom: 0, trailing: 0))
                }
                
                if let extraButton = configuration.extraButton {
                    buttonViewFor(configuration: configuration, buttonType: extraButton)
                }
                if let cancelButton = configuration.cancelButton {
                    buttonViewFor(configuration: configuration, buttonType: cancelButton)
                }
                Spacer()
            }
            .padding(EdgeInsets(top: ViewPullUp.sideOffset,
                                leading: ViewPullUp.sideOffset,
                                bottom: ViewPullUp.sideOffset,
                                trailing: ViewPullUp.sideOffset))
            .interactiveDismissDisabled(!configuration.dismissAble)
        case .custom(let configuration):
            AnyView(configuration.content())
        }
    }
    
    @ViewBuilder
    func viewForItemsList(items: [PullUpCollectionViewCellItem],
                          selectionCallback: ((PullUpCollectionViewCellItem)->())?) -> some View {
        VStack(spacing: 0) {
            ForEach(items, id: \.title) { item in
                selectableListItemView(item: item,
                                       selectionCallback: selectionCallback)
            }
        }
        .padding(Self.listContentPadding)
        .background(Color.backgroundOverlay)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.borderMuted, lineWidth: 1)
        }
    }
    
    @ViewBuilder
    func selectableListItemView(item: PullUpCollectionViewCellItem,
                                selectionCallback: ((PullUpCollectionViewCellItem)->())?) -> some View {
        UDCollectionListRowButton(content: {
            ViewPullUpListItemView(item: item)
                .padding(.init(horizontal: 12))
        }, callback: {
            UDVibration.buttonTap.vibrate()
            appContext.analyticsService.log(event: .buttonPressed,
                                            withParameters: [.button: item.analyticsName,
                                                             .pullUpName: type?.analyticName.rawValue ?? ""])
            
            selectionCallback?(item)
            close()
        })
            .allowsHitTesting(item.isSelectable)
    }
    
    @ViewBuilder
    func labelViewFor(configuration: ViewPullUpDefaultConfiguration,
                      labelType: ViewPullUpDefaultConfiguration.LabelType,
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
                                                 alignment: getCurrentContentAlignment(configuration: configuration)),
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
    
    func getCurrentContentAlignment(configuration: ViewPullUpDefaultConfiguration) -> NSTextAlignment {
        switch configuration.contentAlignment {
        case .left:
            return .left
        case .center:
            return .center
        }
    }
    
    @ViewBuilder
    func subtitleViewFor(configuration: ViewPullUpDefaultConfiguration, 
                         subtitle: ViewPullUpDefaultConfiguration.Subtitle) -> some View {
        switch subtitle {
        case .label(let label):
            labelViewFor(configuration: configuration,
                         labelType: label,
                         fontSize: 16,
                         fontWeight: .regular,
                         textColor: .foregroundSecondary, 
                         lineHeight: 24)
        case .button(let button):
            buttonViewFor(configuration: configuration, buttonType: button)
        }
    }
    
    @ViewBuilder
    func buttonViewFor(configuration: ViewPullUpDefaultConfiguration,
                       buttonType: ViewPullUpDefaultConfiguration.ButtonType) -> some View {
        switch buttonType {
        case .main(let content):
            buttonWithContent(content, style: .large(.raisedPrimary), configuration: configuration)
        case .primaryDanger(let content):
            buttonWithContent(content, style: .large(.raisedDanger), configuration: configuration)
        case .secondary(let content):
            buttonWithContent(content, style: .large(.raisedTertiary), configuration: configuration)
        case .secondaryDanger(let content):
            buttonWithContent(content, style: .large(.ghostDanger), configuration: configuration)
        case .textTertiary(let content):
            buttonWithContent(content, style: .medium(.ghostTertiary), configuration: configuration)
        case .applePay(let content):
            buttonWithContent(content, style: .large(.applePay), configuration: configuration)
        case .raisedTertiary(let content):
            buttonWithContent(content, style: .medium(.raisedTertiary), configuration: configuration)
        case .primaryGhost(let content):
            buttonWithContent(content, style: .large(.ghostPrimary), configuration: configuration)
            
        }
    }
    
    @ViewBuilder
    func buttonWithContent(_ content: ViewPullUpDefaultConfiguration.ButtonContent,
                           style: UDButtonStyle,
                           configuration: ViewPullUpDefaultConfiguration) -> some View {
        UDButtonView(text: content.title,
                     icon: content.icon == nil ? nil : Image(uiImage: content.icon!),
                     iconAlignment: buttonIconAlignmentFor(buttonImageLayout: content.imageLayout),
                     style: style,
                     isLoading: content.isLoading, isSuccess: content.isSuccessState, callback: {
            appContext.analyticsService.log(event: .buttonPressed,
                                            withParameters: [.button : content.analyticsName.rawValue,
                                                             .pullUpName: configuration.analyticName.rawValue].adding(configuration.additionalAnalyticParameters))
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
    func viewForIconContent(_ iconContent: ViewPullUpDefaultConfiguration.IconContent) -> some View {
        switch iconContent.size {
        case .large, .largeCentered, .small:
            Image(uiImage: iconContent.icon)
                .resizable()
                .squareFrame(iconContent.iconSize)
                .foregroundStyle(Color(uiColor: iconContent.tintColor))
        case .fixedHeight(let height):
            Image(uiImage: iconContent.icon)
                .resizable()
                .frame(height: height)
                .frame(maxWidth: .infinity)
                .foregroundStyle(Color(uiColor: iconContent.tintColor))
        }
    }
}

extension View {
    func viewPullUp(_ type: Binding<ViewPullUpConfigurationType?>,
                    typeChangedCallback: ((ViewPullUpConfigurationType?)->())? = nil) -> some View {
        self.modifier(ViewPullUp(type: type,
                                 typeChangedCallback: typeChangedCallback))
    }
}
