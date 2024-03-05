//
//  ChatNavTitleView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.02.2024.
//

import SwiftUI

struct ChatNavTitleView: View {
    
    let titleType: TitleType
    @State private var icon: UIImage?
    private let iconSize: CGFloat = 20
    
    var body: some View {
        HStack(spacing: 8) {
            UIImageBridgeView(image: icon)
            .squareFrame(iconSize)
            .clipShape(Circle())
            Text(title)
                .foregroundStyle(Color.foregroundDefault)
                .font(.currentFont(size: 16, weight: .semibold))
        }
        .onChange(of: titleType, perform: { newValue in
            loadIconNonBlocking()
        })
        .onAppear(perform: loadIconNonBlocking)
    }
    
    private var title: String {
        switch titleType {
        case .domainName(let domainName):
            return domainName
        case .walletAddress(let walletAddress):
            return walletAddress.walletAddressTruncated
        case .channel(let channel):
            return channel.name
        case .group(let messagingGroupChatDetails):
            return messagingGroupChatDetails.displayName
        case .community(let messagingCommunitiesChatDetails):
            return messagingCommunitiesChatDetails.displayName
        }
    }
    
    private func loadIconNonBlocking() {
        Task {
            await loadIcon()
        }
    }
    
    private func loadIcon() async {
        switch titleType {
        case .domainName(let domainName):
            icon = await MessagingImageLoader.getIconImageFor(domainName: domainName)
        case .walletAddress(let walletAddress):
            icon = await MessagingImageLoader.getIconForWalletAddress(walletAddress)
        case .channel(let channel):
            icon = await MessagingImageLoader.getIconForChannel(channel)
        case .group(let groupDetails):
            icon = await MessagingImageLoader.buildImageForGroupChatMembers(groupDetails.allMembers,
                                                                            iconSize: iconSize)
        case .community(let communityDetails):
            switch communityDetails.type {
            case .badge(let badgeInfo):
                let displayInfo = DomainProfileBadgeDisplayInfo(badge: badgeInfo.badge)
                icon = await displayInfo.loadBadgeIcon()
            }
        }
    }
    
    enum TitleType: Hashable {
        case domainName(DomainName)
        case walletAddress(HexAddress)
        case channel(MessagingNewsChannel)
        case group(MessagingGroupChatDetails)
        case community(MessagingCommunitiesChatDetails)
    }
}

#Preview {
    ChatNavTitleView(titleType: .walletAddress("0x"))
}
