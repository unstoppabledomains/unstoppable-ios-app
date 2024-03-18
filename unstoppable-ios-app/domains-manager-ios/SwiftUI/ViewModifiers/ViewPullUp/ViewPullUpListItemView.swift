//
//  ViewPullUpListItemView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.03.2024.
//

import SwiftUI

struct ViewPullUpListItemView: View {
    
    let item: PullUpCollectionViewCellItem
    
    @State private var icon: UIImage?

    
    var body: some View {
        HStack(spacing: 16) {
            iconView()
            
            HStack(spacing: 0) {
                titlesView()
                
                trailingIndicatorView()
            }
        }
        .frame(height: item.height)
        .task {
            self.icon = await item.icon
        }
    }
}

// MARK: - Private methods
private extension ViewPullUpListItemView {
    @ViewBuilder
    func iconView() -> some View {
        ZStack {
            Color(uiColor: item.backgroundColor)
            if let icon {
                Image(uiImage: icon)
                    .resizable()
                    .foregroundStyle(Color(uiColor: item.tintColor))
                    .squareFrame(iconSize)
            }
        }
        .squareFrame(iconContainerSize)
        .clipShape(Circle())
        .overlay {
            if case .imageCentered = item.imageStyle {
                Circle()
                    .stroke(Color.borderSubtle, lineWidth: 1)
            }
        }
    }
    
    var iconSize: CGFloat {
        switch item.imageStyle {
        case .largeImage:
            item.imageSize.containerSize
        case .smallImage:
            item.imageSize.imageSize
        case .imageCentered:
            item.imageSize.imageSize
        }
    }
    var iconContainerSize: CGFloat {
        switch item.imageStyle {
        case .largeImage:
            item.imageSize.containerSize
        case .smallImage:
            item.imageSize.imageSize
        case .imageCentered:
            item.imageSize.containerSize
        }
    }
    
    @ViewBuilder
    func titlesView() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(item.title)
                    .font(.currentFont(size: 16, weight: .medium))
                    .foregroundStyle(Color(uiColor: item.titleColor))
                
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.currentFont(size: 14))
                        .foregroundStyle(Color(uiColor: item.subtitleColor))
                }
            }
            .truncationMode(.tail)
            .lineLimit(1)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    func trailingIndicatorView() -> some View {
        switch item.disclosureIndicatorStyle {
        case .none:
            EmptyView()
        case .actionButton(let title, let callback):
            actionButtonTrailingView(title: title,
                                     callback: callback)
        default:
            defaultTrailingView()
        }
    }
    
    @ViewBuilder
    func actionButtonTrailingView(title: String,
                                  callback: @escaping EmptyCallback) -> some View {
        UDButtonView(text: title,
                     style: .medium(.raisedPrimary),
                     callback: callback)
    }
    
    @ViewBuilder
    func defaultTrailingView() -> some View {
        if let icon = item.disclosureIndicatorStyle.icon {
            Image(uiImage: icon)
                .resizable()
                .foregroundStyle(Color.foregroundMuted)
                .squareFrame(24)
        }
    }
}

#Preview {
    let chatPullUpItem = MessagingChatUserPullUpSelectionItem.init(userInfo: .init(wallet: "adasdsdf sd fsd fsdf sd fsd"), isAdmin: false, isPending: false,
                                                         unblockCallback:  { })
    let legalItem = LegalType.termsOfUse
    
    return ViewPullUpListItemView(item: legalItem)
}
