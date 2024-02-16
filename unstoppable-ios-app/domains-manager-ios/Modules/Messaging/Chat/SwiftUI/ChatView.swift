//
//  ChatView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.02.2024.
//

import SwiftUI

struct ChatView: View {
    
    @StateObject var viewModel: ChatViewModel
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    ForEach(viewModel.messages.reversed(), id: \.id) { message in
                        messageRow(message)
                            .id(message.id)
                            .listRowSeparator(.hidden)
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
    func confirmView() -> some View {
        Button {
            
        } label: {
            Text("Send")
                .frame(maxWidth: .infinity)
                .padding()
        }
        .padding()
        .buttonStyle(.borderedProminent)
    }
    
    @ViewBuilder
    func messageRow(_ message: MessagingChatMessageDisplayInfo) -> some View {
        messageViewFor(message)
            .contextMenu {
                Button {
                    print("Change country setting")
                } label: {
                    Label("Choose Country", systemImage: "globe")
                }
            }
    }
    
    @ViewBuilder
    func messageViewFor(_ message: MessagingChatMessageDisplayInfo) -> some View {
        Text(message.id)
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
}

#Preview {
    ChatView(viewModel: .init(profile: .init(id: "", 
                                             wallet: "",
                                             serviceIdentifier: .push),
                              conversationState: .newChat(.init(userInfo: .init(wallet: "123"),
                                                                messagingService: .push))))
}
