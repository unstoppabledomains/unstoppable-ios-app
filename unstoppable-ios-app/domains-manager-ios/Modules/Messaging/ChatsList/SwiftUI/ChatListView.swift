//
//  ChatListView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.02.2024.
//

import SwiftUI

struct ChatListView: View {

    @EnvironmentObject var tabRouter: HomeTabRouter
    @State private var navigationState: NavigationStateManager?
    
    @StateObject var viewModel: ChatListViewModel
    @FocusState var focused: Bool

    var body: some View {
        NavigationViewWithCustomTitle(content: {
            ZStack {
                List {
                    chatListContentView()
                }
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .displayError($viewModel.error)
            .background(Color.backgroundMuted2)
            .searchable(text: $viewModel.searchText,
                        placement: .navigationBarDrawer(displayMode: .automatic),
                        prompt: Text(String.Constants.search.localized()))
            .onChange(of: viewModel.keyboardFocused) { keyboardFocused in
                withAnimation {
                    focused = keyboardFocused
                }
            }
            .toolbar {
                //            if !viewModel.navActions.isEmpty {
                //                ToolbarItem(placement: .topBarTrailing) {
                //                    navActionButton()
                //                }
                //            }
            }
        }, navigationStateProvider: { state in
            self.navigationState = state
        }, path: $tabRouter.chatTabNavPath)
        .onAppear(perform: onAppear)
    }
    
}

// MARK: - Private methods
private extension ChatListView {
    func onAppear() {
        navigationState?.setCustomTitle(customTitle: { ChatListNavTitleView(profile: viewModel.selectedProfile) },
                                       id: UUID().uuidString)
        navigationState?.isTitleVisible = true
    }
    
    @ViewBuilder
    func chatListContentView() -> some View {
        chatDataTypePickerView()
    }
    
    @ViewBuilder
    func chatDataTypePickerView() -> some View {
        switch viewModel.chatState {
        case .noWallet, .createProfile, .loading:
            if true { }
        case .chatsList, .requestsList:
            ChatListDataTypeSelectorView(dataType: $viewModel.selectedDataType)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(0))
        }
    }
    
}

// MARK: - Open methods
extension ChatListView {
    enum DataType: String, Hashable, CaseIterable {
        case chats, communities, channels
        
        var title: String {
            switch self {
            case .chats:
                return String.Constants.chats.localized()
            case .communities:
                return String.Constants.communities.localized()
            case .channels:
                return String.Constants.appsInbox.localized()
            }
        }
    }
    
    
    enum ViewState {
        case noWallet
        case createProfile
        case chatsList
        case loading
        case requestsList(DataType)
    }
}

#Preview {
    let wallet = MockEntitiesFabric.Wallet.mockEntities().first!
    let profile = UserProfile.wallet(wallet)
    let router = HomeTabRouter(profile: profile)
    
    return ChatListView(viewModel: .init(presentOptions: .default,
                                         selectedProfile: profile,
                                         router: router,
                                         messagingService: appContext.messagingService))
    .environmentObject(router)
}
