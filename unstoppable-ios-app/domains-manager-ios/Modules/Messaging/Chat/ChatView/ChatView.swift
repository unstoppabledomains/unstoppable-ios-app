//
//  ChatView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.02.2024.
//

import SwiftUI

struct ChatView: View, ViewAnalyticsLogger {
    
    @EnvironmentObject var navigationState: NavigationStateManager
    @StateObject var viewModel: ChatViewModel
    @FocusState var focused: Bool
    @State private var scrollViewHandler: ChatViewScrollHandler?

    var analyticsName: Analytics.ViewName { .chatDialog }
    
    var body: some View {
        ZStack {
            if !viewModel.isLoading,
               viewModel.messages.isEmpty {
                ChatMessagesEmptyView(mode: emptyStateMode)
            } else {
                chatContentView()
                    .opacity(viewModel.chatState == .loading ? 0 : 1)
            }
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .displayError($viewModel.error)
        .background(Color.backgroundMuted2)
        .onChange(of: viewModel.keyboardFocused) { keyboardFocused in
            withAnimation {
                focused = keyboardFocused
            }
        }
        .onChange(of: viewModel.input) { _ in
            withAnimation {
                viewModel.showMentionSuggestionsIfNeeded()
            }
        }
        .toolbar {
            if !viewModel.navActions.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    navActionButton()
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if hasBottomView {
                bottomView()
                    .frame(maxWidth: .infinity)
            }
        }
        .environmentObject(viewModel)
        .passViewAnalyticsDetails(logger: self)
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension ChatView {
    func onAppear() {
        withAnimation {
            navigationState.setCustomTitle(customTitle: { ChatNavTitleView(titleType: viewModel.titleType) },
                                           id: UUID().uuidString)
            navigationState.isTitleVisible = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            guard let scrollView = findFirstUIViewOfType(UIScrollView.self) else { return }
            
            scrollViewHandler = ChatViewScrollHandler(scrollView: scrollView, viewModel: viewModel)
        }
    }
    
    var emptyStateMode: ChatMessagesEmptyView.Mode {
        if case .existingChat(let chat) = viewModel.conversationState,
           case .community = chat.type {
            return .community
        } else {
            if viewModel.isAbleToContactUser {
                return viewModel.isChannelEncrypted ? .chatEncrypted : .chatUnEncrypted
            } else {
                return .cantContact
            }
        }
    }
}

// MARK: - Views
private extension ChatView {
    @ViewBuilder
    func chatContentView() -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    if viewModel.isLoadingMessages {
                        topLoadingView()
                    }
                    ForEach(viewModel.messages.reversed(), id: \.id) { message in
                        messageRow(message)
                            .id(message.id)
                    }
                }
            }
            .padding(.init(horizontal: 16))
            .frame(maxWidth: .infinity)
            .scrollDismissesKeyboard(.interactively)
            .withoutAnimation()
            .onChange(of: viewModel.scrollToMessage) { scrollToMessage in
                proxy.scrollTo(scrollToMessage?.id, anchor: .top)
            }
        }
    }
    
    @ViewBuilder
    func topLoadingView() -> some View {
        HStack(alignment: .center) {
            ProgressView()
                .tint(.white)
        }
        .padding()
    }
    
    @ViewBuilder
    func messageRow(_ message: MessagingChatMessageDisplayInfo) -> some View {
        MessageRowView(message: message,
                       isGroupChatMessage: viewModel.isGroupChatMessage)
        .onAppear {
            viewModel.willDisplayMessage(message)
        }
    }
    
    @ViewBuilder
    func navActionButton() -> some View {
        Menu {
            ForEach(viewModel.navActions, id: \.type) { action in
                Button(role: action.type.isDestructive ? .destructive : .cancel) {
                    UDVibration.buttonTap.vibrate()
                    action.callback()
                } label: {
                    Label(
                        title: { Text(action.type.title) },
                        icon: { Image(uiImage: action.type.icon) }
                    )
                }
            }
        } label: {
            Image.dotsCircleIcon
                .foregroundStyle(Color.foregroundDefault)
        }
        .onButtonTap {
            logButtonPressedAnalyticEvents(button: .dots)
        }
    }
    
    var hasBottomView: Bool {
        switch viewModel.chatState {
        case .loading:
            return false
        default:
            return true
        }
    }
    
    @ViewBuilder
    func bottomView() -> some View {
        switch viewModel.chatState {
        case .loading:
            if true { }
        case .chat:
            chatInputView()
        case .otherUserIsBlocked:
            otherUserBlockedBottomView()
        case .userIsBlocked:
            thisUserBlockedBottomView()
        case .cantContactUser:
            if viewModel.isAbleToContactUser {
                inviteUserBottomView()
            }
        }
    }
    
    @ViewBuilder
    func chatInputView() -> some View {
        VStack {
            if !viewModel.suggestingUsers.isEmpty {
                mentionSuggestionsView()
            }
            
            VStack(spacing: 0) {
                if let messageToReply = viewModel.messageToReply {
                    ChatReplyInfoView(messageToReply: messageToReply)
                }
                messageInputView()
                    .background(.regularMaterial)
            }
        }
    }
    
    @ViewBuilder
    func messageInputView() -> some View {
        MessageInputView(input: $viewModel.input,
                         placeholder: viewModel.placeholder,
                         focused: $focused,
                         sendCallback: viewModel.sendPressed,
                         additionalActionCallback: viewModel.additionalActionPressed)
    }
    
    @ViewBuilder
    func mentionSuggestionsView() -> some View {
        ChatMentionSuggestionsView(suggestingUsers: viewModel.suggestingUsers,
                                   selectionCallback: viewModel.didSelectMentionSuggestion)
        .padding(.init(horizontal: 20))
    }
    
    @ViewBuilder
    func inviteUserBottomView() -> some View {
        UDButtonView(text: String.Constants.messagingInvite.localized(),
                     style: .large(.raisedPrimary)) {  }
                     .padding()
    }
    
    @ViewBuilder
    func otherUserBlockedBottomView() -> some View {
        UDButtonView(text: String.Constants.unblock.localized(),
                     style: .medium(.ghostPrimary)) {
            logButtonPressedAnalyticEvents(button: .unblock)
            viewModel.didPressUnblockButton()
        }
                     .padding(.init(vertical: 8))
    }
    
    @ViewBuilder
    func thisUserBlockedBottomView() -> some View {
        Text(String.Constants.messagingYouAreBlocked.localized())
            .foregroundStyle(Color.foregroundDefault)
            .font(.currentFont(size: 16, weight: .medium))
            .padding(.init(vertical: 8))
    }
}

extension ChatView {
    enum ChatState {
        case loading
        case chat
        case otherUserIsBlocked
        case userIsBlocked
        case cantContactUser
    }
    
    struct NavAction {
        let type: NavActionType
        let callback: EmptyCallback
    }
    
    enum NavActionType {
        case viewProfile, block, viewInfo, leave, copyAddress, blockedUsers
        case joinCommunity, leaveCommunity
        
        var title: String {
            switch self {
            case .viewProfile:
                return String.Constants.viewProfile.localized()
            case .block:
                return String.Constants.block.localized()
            case .viewInfo:
                return String.Constants.viewInfo.localized()
            case .leave:
                return String.Constants.leave.localized()
            case .copyAddress:
                return String.Constants.copyAddress.localized()
            case .joinCommunity:
                return String.Constants.join.localized()
            case .leaveCommunity:
                return String.Constants.leave.localized()
            case .blockedUsers:
                return String.Constants.blocked.localized()
            }
        }
        
        var icon: UIImage {
            switch self {
            case .viewProfile, .viewInfo:
                return .arrowUpRight
            case .block, .blockedUsers:
                return .systemMultiplyCircle
            case .leave, .leaveCommunity:
                return .systemRectangleArrowRight
            case .copyAddress:
                return .systemDocOnDoc
            case .joinCommunity:
                return .add
            }
        }
        
        var isDestructive: Bool {
            switch self {
            case .viewProfile, .viewInfo, .copyAddress, .joinCommunity, .blockedUsers:
                return false
            case .block, .leave, .leaveCommunity:
                return true
            }
        }
        
    }
}

#Preview {
    NavigationViewWithCustomTitle(content: {
        ChatView(viewModel: .init(profile: .init(id: "",
                                                 wallet: "",
                                                 serviceIdentifier: .push),
                                  conversationState: MockEntitiesFabric.Messaging.existingChatConversationState(isGroup: true),
                                  router: MockEntitiesFabric.Home.createHomeTabRouter()))
        
    }, navigationStateProvider: { state in
    }, path: .constant(EmptyNavigationPath()))
}
