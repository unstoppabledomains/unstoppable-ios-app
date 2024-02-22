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
    @State private var showingReactionsPopover = false
    
    var body: some View {
        VStack(alignment: message.senderType.isThisUser ? .trailing : .leading) {
            HStack(alignment: .bottom, spacing: 8) {
                if message.senderType.isThisUser {
                    Spacer()
                } else if isGroupChatMessage {
                    otherUserAvatarView()
                }
                messageContentView()
                if isFailedMessage {
                    deleteMessageView()
                }
                if !message.senderType.isThisUser {
                    Spacer()
                }
            }
            
            HStack {
                if isGroupChatMessage, !isThisUser {
                    Spacer()
                        .frame(width: 46)
                }
                timeView()
                if isFailedMessage, isThisUser {
                    Spacer()
                        .frame(width: 40)
                }
            }
            reactionsView()
        }
        .frame(maxWidth: .infinity)
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

// MARK: - Reactions
private extension MessageRowView {
    enum ReactionActionType: Hashable, Identifiable {
        case addReaction
        case existingReaction(MessagingChatMessageDisplayInfo.ReactionUIDescription)
        
        var id: String {
            switch self {
            case .addReaction:
                return "addReaction"
            case .existingReaction(let description):
                return description.content
            }
        }
    }
    
    var reactionsList: [ReactionActionType] {
        if isThisUser {
            return message.buildReactionsUIDescription().map { .existingReaction($0) }
        }
        return message.buildReactionsUIDescription().map { .existingReaction($0) } + [.addReaction]
    }
    
    @ViewBuilder
    func reactionsView() -> some View {
        if isGroupChatMessage,
           !reactionsList.isEmpty {
            FlowLayoutView(reactionsList) { reactionType in
                reactionTypeView(reactionType)
            }
            .modifier(ReactionMirroredModifier(sender: sender))
            .frame(minHeight: 50)
        }
    }
    
    @ViewBuilder
    func reactionTypeView(_ reactionType: ReactionActionType) -> some View {
        switch reactionType {
        case .addReaction:
            addReactionButtonView()
        case .existingReaction(let reactionUIDescription):
            reactionView(reactionUIDescription)
        }
    }
    
    @ViewBuilder
    func addReactionButtonView() -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            showingReactionsPopover = true
        } label: {
            HStack(spacing: 2) {
                Image(systemName: "face.smiling.inverse")
                Text("+")
                    .bold()
            }
            .font(.currentFont(size: 17))
            .foregroundStyle(Color.foregroundDefault)
            .padding(.init(horizontal: 8, vertical: 8))
            .background(Color.backgroundMuted)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .alwaysPopover(isPresented: $showingReactionsPopover) {
            MessageReactionSelectionView(callback: { reactionType in
                viewModel.handleChatMessageAction(.sendReaction(content: reactionType.rawValue,
                                                                toMessage: message))
            })
        }
    }
    
    @ViewBuilder
    func reactionView(_ reaction: MessagingChatMessageDisplayInfo.ReactionUIDescription) -> some View {
        HStack {
            Text(reaction.content)
            Text("\(reaction.count)")
                .foregroundStyle(reaction.containsUserReaction ? Color.white : Color.foregroundDefault)
        }
        .padding(.init(horizontal: 10, vertical: 8))
        .background(reaction.containsUserReaction ? Color.blue : Color.backgroundMuted)
        .clipShape(Capsule())
        .modifier(ReactionMirroredModifier(sender: sender))
    }
    
    struct ReactionMirroredModifier: ViewModifier {
        let sender: MessagingChatSender
        func body(content: Content) -> some View {
            if sender.isThisUser {
                content
                    .scaleEffect(x: -1, y: 1, anchor: .center)
            } else {
                content
            }
        }
    }
}

#Preview {
    let reactions = MockEntitiesFabric.Reactions.reactionsToTest
    let message = MockEntitiesFabric.Messaging.createTextMessage(text: "Hello world js ",
                                                                 isThisUser: true,
                                                                 deliveryState: .delivered,
                                                                 reactions: reactions)
    return MessageRowView(message: message,
                   isGroupChatMessage: true)
    .padding()
}
