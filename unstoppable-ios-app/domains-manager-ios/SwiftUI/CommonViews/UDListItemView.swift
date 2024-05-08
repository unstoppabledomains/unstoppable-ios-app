//
//  UDListItemView.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 28.11.2023.
//

import SwiftUI

struct UDListItemView: View {
    
    static let height: CGFloat = 48
    
    private let iconSize: CGFloat = 40
    
    let title: String
    var titleColor: Color = .foregroundDefault
    var subtitle: String? = nil
    var subtitleStyle: SubtitleStyle = .default
    var value: String? = nil
    var imageType: ImageType
    var imageStyle: ImageStyle = .centred()
    var rightViewStyle: RightViewStyle? = nil
    
    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 16) {
                imageView()
                VStack(alignment: .leading, spacing: 0) {
                    titleView()
                    subtitleView()
                }
            }
            Spacer()
            HStack(spacing: 8) {
                valueView()
                rightView()
            }
        }
        .frame(minHeight: UDListItemView.height)
    }
}

// MARK: - Private methods
private extension UDListItemView {
    @ViewBuilder
    func imageView() -> some View {
        switch imageStyle {
        case .centred(let offset, let foreground, let background, let bordered):
            imageForCurrentType(size: CGSize(width: iconSize - offset.leading - offset.trailing,
                                             height: iconSize - offset.top - offset.bottom),
                                tintColor: foreground.uiColor)
                .foregroundStyle(foreground)
                .padding(offset)
                .background(background)
                .clipShape(Circle())
                .overlay {
                    if bordered {
                        Circle()
                            .stroke(Color.borderSubtle, lineWidth: 1) // border subtle
                    }
                }
        case .full:
            imageForCurrentType(size: .square(size: iconSize),
                                tintColor: nil)
                .clipShape(Circle())
        }
    }
    
    @ViewBuilder
    func imageForCurrentType(size: CGSize,
                             tintColor: UIColor?) -> some View {
        switch imageType {
        case .image(let image):
            image
                .resizable()
                .frame(width: size.width,
                       height: size.height)
        case .uiImage(let uiImage):
            UIImageBridgeView(image: uiImage,
                              tintColor: tintColor)
            .frame(width: size.width,
                   height: size.height)
        }
    }
    
    @ViewBuilder
    func titleView() -> some View {
        Text(title)
            .font(.currentFont(size: 16, weight: .medium))
            .foregroundStyle(titleColor)
            .frame(height: 24)
    }
    
    @ViewBuilder
    func subtitleView() -> some View {
        switch subtitleStyle {
        case .default:
            subtitleText()
                .foregroundStyle(Color.foregroundSecondary)
        case .accent:
            subtitleText(fontWeight: .medium)
                .foregroundStyle(Color.foregroundAccent)
        case .warning:
            HStack(spacing: 8) {
                Image.warningIcon
                    .resizable()
                    .squareFrame(16)
                subtitleText()
            }
            .foregroundStyle(Color.foregroundWarning)
        }
    }
    
    @ViewBuilder
    func subtitleText(fontWeight: UIFont.Weight = .regular) -> some View {
        if let subtitle {
            Text(subtitle)
                .font(.currentFont(size: 14, weight: fontWeight))
                .frame(height: 20)
        }
    }
    
    @ViewBuilder
    func valueView() -> some View {
        if let value {
            Text(value)
                .font(.currentFont(size: 16))
                .foregroundStyle(Color.foregroundSecondary)
        }
    }
    
    @ViewBuilder
    func rightView() -> some View {
        if let rightViewStyle  {
            rightViewStyle.view()
        }
    }
}

// MARK: - Open methods
extension UDListItemView {
    enum ImageType {
        case image(Image)
        case uiImage(UIImage)
    }
    
    enum ImageStyle {
        case centred(offset: EdgeInsets = EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10),
                     foreground: Color = .foregroundDefault,
                     background: Color = .backgroundMuted,
                     bordered: Bool = true)
        case full
        
        static func clearImage(foreground: Color) -> ImageStyle {
            .centred(foreground: foreground, background: .clear, bordered: false)
        }
    }
    
    enum SubtitleStyle {
        case `default`
        case warning
        case accent
    }
    
    enum RightViewStyle {
        case chevron, checkmark, checkmarkEmpty, errorCircle
        case toggle(isOn: Bool, callback: (Bool)->())
        
        var image: Image {
            switch self {
            case .chevron:
                return .chevronRight
            case .checkmark:
                return .checkCircle
            case .checkmarkEmpty:
                return .checkCircleEmpty
            case .errorCircle:
                return .infoIcon
            case .toggle:
                return .infoIcon
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .chevron:
                return .foregroundMuted
            case .checkmark:
                return .foregroundAccent
            case .checkmarkEmpty:
                return .borderEmphasis
            case .errorCircle:
                return .foregroundDanger
            case .toggle:
                return .foregroundDanger
            }
        }
        
        @ViewBuilder
        func view() -> some View {
            switch self {
            case .toggle(let isOn, let callback):
                ListToggleView(isOn: isOn,
                               callback: callback)
            default:
                image
                    .resizable()
                    .squareFrame(20)
                    .foregroundStyle(foregroundColor)
            }
        }
    }
}

// MARK: - Private methods
private extension UDListItemView {
    struct ListToggleView: View {
        
    @State var isOn: Bool
    let callback: (Bool)->()
        
        var body: some View {
            Toggle("", isOn: $isOn)
                .tint(.backgroundAccentEmphasis)
                .onChange(of: isOn) { newValue in
                    callback(newValue)
                }
        }
        
    }
}

#Preview {
    UDListItemView(title: "US ZIP code",
                   subtitle: "Taxes: $10.00",
                   value: "14736 (NY)",
                   imageType: .uiImage(.udWalletListIcon),
                   imageStyle: .full,
                   rightViewStyle: .checkmark)
}
