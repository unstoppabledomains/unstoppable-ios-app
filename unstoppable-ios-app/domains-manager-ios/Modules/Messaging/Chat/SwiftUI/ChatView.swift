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
    @Binding var isNavTitleVisible: Bool
    var analyticsName: Analytics.ViewName { .chatDialog }
    var additionalAppearAnalyticParameters: Analytics.EventParameters { [:] }
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(viewModel.messages.reversed(), id: \.id) { message in
                    messageRow(message)
                        .id(message.id)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
//                .flippedUpsideDown()
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.hidden)
            .listStyle(.plain)
            .clearListBackground()
            .animation(.default, value: UUID())
//            .flippedUpsideDown()
            .onChange(of: viewModel.scrollToMessage) { scrollToMessage in
                withAnimation {
                    proxy.scrollTo(scrollToMessage?.id)
                }
            }
        }
        .displayError($viewModel.error)
        .background(Color.backgroundMuted2)
        .onChange(of: viewModel.keyboardFocused) { keyboardFocused in
            withAnimation {
                focused = keyboardFocused
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
            MessageInputView(input: $viewModel.input,
                             focused: $focused,
                             sendCallback: viewModel.sendPressed,
                             additionalActionCallback: viewModel.additionalActionPressed)
            .background(.regularMaterial)
        }
        .onAppear(perform: onAppear)
    }
}


// MARK: - Private methods
private extension ChatView {
    func onAppear() {
        navigationState.setCustomTitle(customTitle: { ChatNavTitleView(titleType: viewModel.titleType) },
                                       id: UUID().uuidString)
        navigationState.isTitleVisible = true
    }
    
    @ViewBuilder
    func messageRow(_ message: MessagingChatMessageDisplayInfo) -> some View {
        MessageRowView(message: message,
                       isGroupChatMessage: viewModel.isGroupChatMessage)
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
}

extension ChatView {
    enum State {
        case loading
        case chat
        case viewChannel
        case joinChannel
        case otherUserIsBlocked
        case userIsBlocked
        case cantContactUser(ableToInvite: Bool)
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
                                  conversationState: MockEntitiesFabric.Messaging.existingChatConversationState(isGroup: false)),
                 isNavTitleVisible: .constant(true))
        
    }, navigationStateProvider: { state in
    }, path: .constant(.init()))
}
