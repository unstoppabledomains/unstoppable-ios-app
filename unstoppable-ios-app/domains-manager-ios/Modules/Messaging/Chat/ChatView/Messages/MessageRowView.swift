//
//  MessageRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.02.2024.
//

import SwiftUI

struct MessageRowView: View, ViewAnalyticsLogger {
    
    @EnvironmentObject var viewModel: ChatViewModel
    @Environment(\.analyticsViewName) var analyticsName
    @Environment(\.analyticsAdditionalProperties) var additionalAppearAnalyticParameters
    
    let message: MessagingChatMessageDisplayInfo
    let isGroupChatMessage: Bool
    @State private var otherUserAvatar: UIImage?
    @State private var showingReactionsPopover = false
    private let groupChatImageXOffset: CGFloat = 46
    
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
                groupAvatarXOffsetViewOfNeeded()
                underMessageView()
                if isFailedMessage, isThisUser {
                    Spacer()
                        .frame(width: 40)
                }
            }
            HStack {
                groupAvatarXOffsetViewOfNeeded()
                reactionsView()
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.clear)
        .modifier(SwipeToReplyGestureModifier(message: message))
    }
}

// MARK: - Private methods
private extension MessageRowView {
    var isFailedMessage: Bool {
        message.isFailedMessage
    }
    var sender: MessagingChatSender { message.senderType }
    var isThisUser: Bool { sender.isThisUser }
    var isNeedToAddGroupAvatarXOffset: Bool { isGroupChatMessage && !isThisUser }
    
    @ViewBuilder
    func messageContentView() -> some View {
        MessageRowContentView(message: message,
                              messageType: message.type,
                              referenceMessageId: nil)
    }
    
    struct MessageRowContentView: View {
        
        let message: MessagingChatMessageDisplayInfo
        let messageType: MessagingChatMessageDisplayType
        let referenceMessageId: String?
        
        var body: some View {
            switch messageType {
            case .text(let info):
                TextMessageRowView(message: message,
                                   info: info,
                                   referenceMessageId: referenceMessageId)
            case .imageData(let info):
                ImageMessageRowView(message: message,
                                    image: info.image)
            case .imageBase64(let info):
                ImageMessageRowView(message: message,
                                    image: info.image)
            case .remoteContent:
                RemoteContentMessageRowView(sender: message.senderType)
            case .unknown(let info):
                UnknownMessageRowView(message: message,
                                      info: info)
            case .reply(let info):
                MessageRowContentView(message: message,
                                      messageType: info.contentType,
                                      referenceMessageId: info.messageId)
            case .reaction(let info):
                Text(info.content)
            }
        }
    }
    
    @ViewBuilder
    func underMessageView() -> some View {
        if isFailedMessage {
            failedToSendMessageView()
        } else {
            timeLabelView()
        }
    }
    
    @ViewBuilder
    func groupAvatarXOffsetViewOfNeeded() -> some View {
        if isNeedToAddGroupAvatarXOffset {
            groupAvatarXOffsetView()
        }
    }
    
    @ViewBuilder
    func groupAvatarXOffsetView() -> some View {
        Spacer()
            .frame(width: groupChatImageXOffset)
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
            let name = userInfo.displayName
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
            logButtonPressedAnalyticEvents(button: .selectReaction)
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

// MARK: - Private methods
private extension MessageRowView {
    struct SwipeToReplyGestureModifier: ViewModifier, ViewAnalyticsLogger {
        
        @EnvironmentObject var viewModel: ChatViewModel
        @Environment(\.analyticsViewName) var analyticsName
        @Environment(\.analyticsAdditionalProperties) var additionalAppearAnalyticParameters

        let message: MessagingChatMessageDisplayInfo
        @State private var offset: CGFloat = 0
        @State private var didNotifyWithHapticForCurrentSwipeSession: Bool = false
        private let offsetToStartReply: CGFloat = 100
        private var progressToStartReply: CGFloat { abs(offset) / offsetToStartReply }
        
        func body(content: Content) -> some View {
            if message.senderType.isThisUser || !viewModel.isAbleToReply {
                content
            } else {
                HStack(spacing: 10) {
                    content
                    replyIndicatorView()
                    Spacer()
                }
                    .animation(.linear, value: offset)
                    .offset(x: offset)
                    .highPriorityGesture(
                        DragGesture()
                            .onChanged { gesture in
                                let translation = gesture.translation.width
                                calculateOffsetFor(xTranslation: translation)
                            }
                            .onEnded { _ in
                                didFinishSwipe()
                            }
                    )
            }
        }
        
        @ViewBuilder
        func replyIndicatorView() -> some View {
            Image(systemName: "arrowshape.turn.up.left")
                .foregroundStyle(.white)
                .padding(.init(8))
                .background(Color.white.opacity(0.2))
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(lineWidth: 0.5)
                        .foregroundStyle(Color.white.opacity(0.3))
                    
                }
                .offset(y: -30)
                .opacity(progressToStartReply)
        }
        
        private func calculateOffsetFor(xTranslation: CGFloat) {
            if xTranslation >= 0 {
                offset = 0
                return
            }
            let frictionlessOffset: CGFloat = offsetToStartReply
            
            let absXTranslation = abs(xTranslation)
            if absXTranslation <= frictionlessOffset {
                offset = -absXTranslation
            } else {
                if !didNotifyWithHapticForCurrentSwipeSession {
                    Vibration.success.vibrate()
                    didNotifyWithHapticForCurrentSwipeSession = true
                }
                offset = -(frictionlessOffset + (absXTranslation - frictionlessOffset) / 3)
            }
        }
        
        private func didFinishSwipe() {
            if isSwipeOffsetEnoughToReply() {
                didSwipeToReply()
            }
            resetOffset()
            didNotifyWithHapticForCurrentSwipeSession = false
        }
        
        private func isSwipeOffsetEnoughToReply() -> Bool {
            abs(offset) > offsetToStartReply
        }
        
        private func didSwipeToReply() {
            logButtonPressedAnalyticEvents(button: .didSwipeToReply)
            viewModel.handleChatMessageAction(.reply(message))
        }
        
        private func resetOffset() {
            offset = .zero
        }
    }
}

#Preview {
    let reactions = MockEntitiesFabric.Reactions.reactionsToTest
    var message = MockEntitiesFabric.Messaging.createTextMessage(text: "Hello @oleg.x, here's the link: https://google.com",
                                                                 isThisUser: false,
                                                                 deliveryState: .delivered,
                                                                 reactions: reactions)
    message.type = .reply(.init(contentType: message.type, messageId: "1"))
    return MessageRowView(message: message,
                   isGroupChatMessage: true)
    .environmentObject(ChatViewModel(profile: .init(id: "",
                                            wallet: "",
                                            serviceIdentifier: .push),
                             conversationState: MockEntitiesFabric.Messaging.existingChatConversationState(isGroup: true),
                             router: HomeTabRouter(profile: .wallet(MockEntitiesFabric.Wallet.mockEntities().first!))))
    .padding()
}
