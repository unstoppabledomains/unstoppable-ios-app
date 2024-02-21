//
//  ChatRequestsListView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.02.2024.
//

import SwiftUI

struct ChatRequestsListView: View, ViewAnalyticsLogger {
    
    @EnvironmentObject var navigationState: NavigationStateManager
    @StateObject var viewModel: ChatRequestsListViewModel
    var analyticsName: Analytics.ViewName { viewModel.analyticsName }

    var body: some View {
        ZStack {
            requestsListContentView()
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .displayError($viewModel.error)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, .constant(viewModel.isEditing ? .active : .inactive))
        .animation(.default, value: UUID())
        .background(Color.backgroundMuted2)
        .toolbar {
            if case .chatRequests = viewModel.dataType {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        UDVibration.buttonTap.vibrate()
                        logButtonPressedAnalyticEvents(button: viewModel.isEditing ? .cancel : .edit)
                        viewModel.isEditing.toggle()
                    } label: {
                        Text(viewModel.isEditing ? String.Constants.cancel.localized() : String.Constants.editButtonTitle.localized())
                            .foregroundStyle(Color.foregroundDefault)
                            .font(.currentFont(size: 16, weight: .medium))
                    }
                }
            }
            
            if viewModel.isEditing {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        UDVibration.buttonTap.vibrate()
                        viewModel.selectAllButtonPressed()
                        logButtonPressedAnalyticEvents(button: .selectAll)
                    } label: {
                        Text(String.Constants.selectAll.localized())
                            .foregroundStyle(Color.foregroundDefault)
                            .font(.currentFont(size: 16, weight: .medium))
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if viewModel.isEditing {
                bottomView()
                    .frame(maxWidth: .infinity)
                    .background(.regularMaterial)
            }
        }
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension ChatRequestsListView {
    func onAppear() {
        navigationState.isTitleVisible = false
    }
    
    var title: String {
        switch viewModel.dataType {
        case .chatRequests:
            return String.Constants.chatRequests.localized()
        case .channelsSpam:
            return String.Constants.spam.localized()
        }
    }
    
    @ViewBuilder
    func bottomView() -> some View {
        UDButtonView(text: String.Constants.block.localized(),
                     style: .large(.raisedDanger),
                     callback: {
            logButtonPressedAnalyticEvents(button: .block)
            viewModel.blockButtonPressed()
        })
        .padding()
    }
    
    @ViewBuilder
    func requestsListContentView() -> some View {
        switch viewModel.dataType {
        case .chatRequests(let array):
            chatsListContentView(array)
        case .channelsSpam(let array):
            channelsListContentView(array)
        }
    }
    
    @ViewBuilder
    func chatsListContentView(_ chats: [MessagingChatDisplayInfo]) -> some View {
        List(chats, id: \.self, selection: $viewModel.selectedChats) { chat in
            SelectableChatRowView(chat: chat,
                                  chatSelectedCallback: { chat in
                viewModel.openChat(chat)
            })
            .allowsHitTesting(!viewModel.isEditing)
            .listRowBackground(Color.backgroundOverlay)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(4))
        }
    }
    
    @ViewBuilder
    func channelsListContentView(_ channels: [MessagingNewsChannel]) -> some View {
        List {
            Section {
                ForEach(channels, id: \.id) { channel in
                    UDCollectionListRowButton(content: {
                        ChatListChannelRowView(channel: channel)
                    }, callback: {
                        UDVibration.buttonTap.vibrate()
                        logButtonPressedAnalyticEvents(button: .channelInList)
                        viewModel.openChannel(channel)
                    })
                    .allowsHitTesting(!viewModel.isEditing)
                }
            }
            .listRowBackground(Color.backgroundOverlay)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(4))
        }
    }
}

// MARK: - Open methods
extension ChatRequestsListView {
    enum DataType: Hashable {
        case chatRequests([MessagingChatDisplayInfo])
        case channelsSpam([MessagingNewsChannel])
    }
}

#Preview {
    let wallet = MockEntitiesFabric.Wallet.mockEntities().first!
    let profile = UserProfile.wallet(wallet)
    let router = HomeTabRouter(profile: profile)
    
    return NavigationStack {
        ChatRequestsListView(viewModel: .init(dataType: .channelsSpam(MockEntitiesFabric.Messaging.createChannelsForUITesting()),
                                              profile: MockEntitiesFabric.Messaging.createProfileDisplayInfo(),
                                              router: router))
    }
    .environmentObject(router)

}
