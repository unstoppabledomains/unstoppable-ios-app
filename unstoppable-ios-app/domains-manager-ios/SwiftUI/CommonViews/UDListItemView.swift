//
//  UDListItemView.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 28.11.2023.
//

import SwiftUI

struct UDListItemView: View {
    
    static let height: CGFloat = 56
    
    private let iconSize: CGFloat = 40
    
    let title: String
    var subtitle: String? = nil
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
        case .centred(let offset):
            imageForCurrentType(size: CGSize(width: iconSize - offset.leading - offset.trailing,
                                             height: iconSize - offset.top - offset.bottom))
                .foregroundStyle(Color.foregroundDefault)
                .padding(offset)
                .background(Color.backgroundMuted)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(Color.borderSubtle, lineWidth: 1) // border subtle
                }
        case .full:
            imageForCurrentType(size: .square(size: iconSize))
                .clipShape(Circle())
        }
    }
    
    @ViewBuilder
    func imageForCurrentType(size: CGSize) -> some View {
        switch imageType {
        case .image(let image):
            image
                .resizable()
                .frame(width: size.width,
                       height: size.height)
        case .uiImage(let uiImage):
            UIImageBridgeView(image: uiImage,
                              width: size.width,
                              height: size.height)
            .frame(width: size.width,
                   height: size.height)
        }
    }
    
    @ViewBuilder
    func titleView() -> some View {
        Text(title)
            .font(.currentFont(size: 16, weight: .medium))
            .foregroundStyle(Color.foregroundDefault)
            .frame(height: 24)
    }
    
    @ViewBuilder
    func subtitleView() -> some View {
        if let subtitle {
            Text(subtitle)
                .font(.currentFont(size: 14))
                .foregroundStyle(Color.foregroundSecondary)
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
            rightViewStyle.image
                .resizable()
                .squareFrame(20)
                .foregroundStyle(rightViewStyle.foregroundColor)
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
        case centred(offset: EdgeInsets = EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
        case full
    }
    
    enum RightViewStyle {
        case chevron, checkmark, errorCircle
        
        var image: Image {
            switch self {
            case .chevron:
                return .chevronRight
            case .checkmark:
                return .checkCircle
            case .errorCircle:
                return .infoIcon
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .chevron:
                return .foregroundMuted
            case .checkmark:
                return .foregroundAccent
            case .errorCircle:
                return .foregroundDanger
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
