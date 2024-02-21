//
//  MessageRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.02.2024.
//

import SwiftUI

struct MessageRowView: View {
    
    @EnvironmentObject var viewModel: ChatViewModel

    let message: MessagingChatMessageDisplayInfo
    let isGroupChatMessage: Bool
    @State private var otherUserAvatar: UIImage?
    private let timeViewOffset: CGFloat = 18
    
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
            if isFailedMessage {
                deleteMessageView()
            }
        }
        .background(Color.clear)
    }
}
// MARK: - Private methods
private extension MessageRowView {
    var isFailedMessage: Bool {
        message.deliveryState == .failedToSend
    }
    var sender: MessagingChatSender { message.senderType }
    var isThisUser: Bool { sender.isThisUser }
    
    @ViewBuilder
    func messageContentView() -> some View {
        switch message.type {
        case .text(let info):
            TextMessageRowView(info: info,
                               sender: sender,
                               isFailed: isFailedMessage)
        case .imageData(let info):
            ImageMessageRowView(image: info.image,
                                sender: sender)
        case .imageBase64(let info):
            ImageMessageRowView(image: info.image,
                                sender: sender)
        case .remoteContent:
            RemoteContentMessageRowView(sender: sender)
        case .unknown(let info):
            UnknownMessageRowView(message: message,
                                  info: info,
                                  sender: sender)
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
    
    var timeLabelText: String {
        if message.deliveryState == .sending {
            return String.Constants.sending.localized() + "..."
        }
        return MessageDateFormatter.formatMessageDate(message.time)
    }
    
    @ViewBuilder
    func timeLabelView() -> some View {
        Text(timeLabelText)
            .font(.currentFont(size: 11))
            .foregroundStyle(Color.foregroundSecondary)
    }
    
    @ViewBuilder
    func failedToSendMessageView() -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            viewModel.handleChatMessageAction(.resend(message))
        } label: {
            HStack(spacing: 2) {
                Text(String.Constants.sendingFailed.localized() + ".")
                    .foregroundStyle(Color.foregroundDanger)
                Text(String.Constants.tapToRetry.localized())
                    .foregroundStyle(Color.foregroundAccent)
            }
            .font(.currentFont(size: 11))
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    func deleteMessageView() -> some View {
        UDIconButtonView(icon: .trashIcon,
                         style: .circle(size: .small,
                                        style: .raisedTertiary)) {
            UDVibration.buttonTap.vibrate()
            viewModel.handleChatMessageAction(.delete(message))
        }
                                        .offset(y: -timeViewOffset)
    }
    
    @ViewBuilder
    func otherUserAvatarView() -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            viewModel.handleChatMessageAction(.viewSenderProfile(message.senderType))
        } label: {
            UIImageBridgeView(image: otherUserAvatar,
                              width: 36,
                              height: 35)
            .squareFrame(36)
            .clipShape(Circle())
            .onAppear(perform: loadAvatarForOtherUserInfo)
            .offset(y: -timeViewOffset)
        }
        .buttonStyle(.plain)
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
