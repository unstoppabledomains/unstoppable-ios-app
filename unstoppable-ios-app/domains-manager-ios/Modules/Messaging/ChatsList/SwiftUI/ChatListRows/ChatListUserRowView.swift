//
//  ChatListUserRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.02.2024.
//

import SwiftUI

struct ChatListUserRowView: View {
    
    @Environment(\.imageLoadingService) private var imageLoadingService
    
    let user: MessagingChatUserDisplayInfo
    @State private var icon: UIImage?

    var body: some View {
        HStack(spacing: 16) {
            avatarsView()
            Text(chatName)
                .font(.currentFont(size: 16, weight: .medium))
                .foregroundStyle(Color.foregroundDefault)
            Spacer()
            Image.cellChevron
                .resizable()
                .squareFrame(20)
                .foregroundStyle(Color.foregroundMuted)
        }
        .frame(height: 60)
        .onAppear(perform: onAppear)
    }
    
}

// MARK: - Private methods
private extension ChatListUserRowView {
    func onAppear() {
        setAvatar()
    }
    
    func setAvatar() {
        setAvatarFrom(url: user.pfpURL, name: chatName)
    }
    
    var chatName: String {
        if user.rrDomainName == nil {
            return user.displayName
        } else {
            return user.rrDomainName ?? ""
        }
    }
    
    func setAvatarFrom(url: URL?, name: String) {
        icon = nil
        
        Task {
            icon = await imageLoadingService.loadImage(from: .initials(name,
                                                                       size: .default,
                                                                       style: .accent),
                                                       downsampleDescription: nil)
            if let avatarURL = url {
                if let image = await appContext.imageLoadingService.loadImage(from: .url(avatarURL), downsampleDescription: .icon) {
                    icon = image
                }
            }
        }
    }
    
    @ViewBuilder
    func avatarsView() -> some View {
        UIImageBridgeView(image: icon,
                          width: 40,
                          height: 40)
        .squareFrame(40)
                .clipShape(Circle())
    }
    
}

#Preview {
    ChatListUserRowView(user: .init(wallet: "0x", rrDomainName: "oleg.x"))
}
