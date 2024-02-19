//
//  ChatView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.02.2024.
//

import SwiftUI

struct ChatView: View {
    
    @EnvironmentObject var navigationState: NavigationStateManager
    @StateObject var viewModel: ChatViewModel
    @FocusState var focused: Bool
    @Binding var isNavTitleVisible: Bool

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
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    
                } label: {
                    Image.plusIcon18
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
