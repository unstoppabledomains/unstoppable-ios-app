//
//  MessageRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.02.2024.
//

import SwiftUI

struct MessageRowView: View {
    
    let message: MessagingChatMessageDisplayInfo
    let isGroupChatMessage: Bool
    @State private var otherUserAvatar: UIImage?
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.senderType.isThisUser {
                Spacer()
            } else if isGroupChatMessage {
                otherUserAvatarView()
            }
            VStack(alignment: message.senderType.isThisUser ? .trailing : .leading) {
                messageContentView()
                timeView()
            }
        }
        .background(Color.clear)
    }
}
// MARK: - Private methods
private extension MessageRowView {
    var isFailedMessage: Bool {
        true
//        message.deliveryState == .failedToSend
    }
    
    @ViewBuilder
    func messageContentView() -> some View {
        switch message.type {
        case .text(let info):
            TextMessageRowView(info: info,
                               isThisUser: message.senderType.isThisUser, 
                               isFailed: isFailedMessage)
        default:
            Text("Hello world")
        }
    }
    
    @ViewBuilder
    func timeView() -> some View {
        if isFailedMessage {
            failedToSendMessageView()
        } else {
            timeLabelView()
        }
    }
    
    @ViewBuilder
    func timeLabelView() -> some View {
        Text(MessageDateFormatter.formatMessageDate(message.time))
            .font(.currentFont(size: 11))
            .foregroundStyle(Color.foregroundSecondary)
    }
    
    @ViewBuilder
    func failedToSendMessageView() -> some View {
        Button {
            
        } label: {
            HStack(spacing: 2) {
                Text(String.Constants.sendingFailed.localized() + ".")
                    .foregroundStyle(Color.foregroundDanger)
                Text(String.Constants.tapToRetry.localized())
                    .foregroundStyle(Color.foregroundAccent)
            }
            .font(.currentFont(size: 11))
        }
    }
    
    @ViewBuilder
    func otherUserAvatarView() -> some View {
        UIImageBridgeView(image: otherUserAvatar,
                          width: 36,
                          height: 35)
        .squareFrame(36)
        .clipShape(Circle())
        .onAppear(perform: loadAvatarForOtherUserInfo)
        .offset(y: -18)
    }
    
    func loadAvatarForOtherUserInfo() {
        let userInfo = message.senderType.userDisplayInfo
        Task {
            let name = userInfo.domainName ?? userInfo.wallet.droppedHexPrefix
            otherUserAvatar = await appContext.imageLoadingService.loadImage(from: .initials(name,
                                                                                                        size: .default,
                                                                                                        style: .accent),
                                                                                        downsampleDescription: nil)
            
            let image = await appContext.imageLoadingService.loadImage(from: .messagingUserPFPOrInitials(userInfo,
                                                                                                         size: .default),
                                                                       downsampleDescription: .icon)
            if let image,
               userInfo.wallet == message.senderType.userDisplayInfo.wallet {
                otherUserAvatar = image
            }
        }
    }
}

#Preview {
    MessageRowView(message: MockEntitiesFabric.Messaging.createTextMessage(text: "Hello world js lkjs dflkj lksa fs dfsd fsd f", isThisUser: true),
                   isGroupChatMessage: true)
    .padding()
}
