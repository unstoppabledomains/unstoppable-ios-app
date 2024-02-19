//
//  ChatView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.02.2024.
//

import SwiftUI

struct ChatView: View {
    
    @StateObject var viewModel: ChatViewModel
    @FocusState var focused: Bool

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    ForEach(viewModel.messages.reversed(), id: \.id) { message in
                        messageRow(message)
                            .id(message.id)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                    .flippedUpsideDown()
                }
                .scrollDismissesKeyboard(.interactively)
                .scrollIndicators(.hidden)
                .listStyle(.plain)
                .clearListBackground()
                .animation(.default, value: UUID())
                .flippedUpsideDown()
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
        }
    }
}


// MARK: - Private methods
private extension ChatView {
    @ViewBuilder
    func messageRow(_ message: MessagingChatMessageDisplayInfo) -> some View {
        MessageRowView(message: message,
                       isGroupChatMessage: viewModel.isGroupChatMessage)
//            .contextMenu {
//                Button {
//                    print("Change country setting")
//                } label: {
//                    Label("Choose Country", systemImage: "globe")
//                }
//            }
    }
}

extension ChatView {
    enum TitleType {
        case domainName(DomainName)
        case walletAddress(HexAddress)
        case channel(MessagingNewsChannel)
        case group(MessagingGroupChatDetails)
        case community(MessagingCommunitiesChatDetails)
    }
    
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
    ChatView(viewModel: .init(profile: .init(id: "", 
                                             wallet: "",
                                             serviceIdentifier: .push),
                              conversationState: MockEntitiesFabric.Messaging.existingChatConversationState(isGroup: false)))
}
