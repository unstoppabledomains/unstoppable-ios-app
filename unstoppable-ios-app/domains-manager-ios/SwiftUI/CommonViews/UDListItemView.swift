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
    var image: Image
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
            image
                .resizable()
                .frame(width: iconSize - offset.leading - offset.trailing,
                       height: iconSize - offset.top - offset.bottom)
                .foregroundStyle(Color.foregroundDefault)
                .padding(offset)
                .background(Color.backgroundMuted)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(Color.borderSubtle, lineWidth: 1) // border subtle
                }
        case .full:
            image
                .resizable()
                .squareFrame(iconSize)
                .clipShape(Circle())
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
            switch rightViewStyle {
            case .chevron:
                Image.chevronRight
                    .resizable()
                    .squareFrame(20)
                    .foregroundStyle(Color.foregroundMuted)
            case .checkmark:
                Image.checkCircle
                    .resizable()
                    .squareFrame(20)
                    .foregroundStyle(Color.foregroundAccent)
            }
        }
    }
}

// MARK: - Open methods
extension UDListItemView {
    enum ImageStyle {
        case centred(offset: EdgeInsets = EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
        case full
    }
    
    enum RightViewStyle {
        case chevron, checkmark
    }
}

#Preview {
    UDListItemView(title: "US ZIP code",
                   subtitle: "Taxes: $10.00",
                   value: "14736 (NY)",
                   image: .udWalletListIcon,
                   imageStyle: .full,
                   rightViewStyle: .checkmark)
}
