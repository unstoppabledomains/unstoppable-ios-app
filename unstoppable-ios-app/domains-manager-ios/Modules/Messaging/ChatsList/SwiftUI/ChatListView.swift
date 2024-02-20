//
//  ChatListView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.02.2024.
//

import SwiftUI

struct ChatListView: View, ViewAnalyticsLogger {

    @EnvironmentObject var tabRouter: HomeTabRouter
    @State private var navigationState: NavigationStateManager?
    @State private var isNavTitleVisible: Bool = true
    
    @StateObject var viewModel: ChatListViewModel
    @FocusState var focused: Bool
    private var hasBottomView: Bool { viewModel.chatState == .createProfile }
    var analyticsName: Analytics.ViewName { .chatsHome }
    var isOtherScreenPushed: Bool { !tabRouter.chatTabNavPath.isEmpty }

    var body: some View {
        NavigationViewWithCustomTitle(content: {
            ZStack {
                if viewModel.chatState == .chatsList {
                    List {
                        chatListContentView()
                    }
                    .sectionSpacing(16)
                    .searchable(text: $viewModel.searchText,
                                placement: .navigationBarDrawer(displayMode: .automatic),
                                prompt: Text(String.Constants.search.localized()))
                } else {
                    List {
                        Text("")
                            .listRowBackground(Color.clear)
                    }
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
            .onChange(of: tabRouter.chatTabNavPath) { path in
                tabRouter.isTabBarVisible = !isOtherScreenPushed
                if path.isEmpty {
                    setupTitle()
                }
            }
            .toolbar {
                //            if !viewModel.navActions.isEmpty {
                //                ToolbarItem(placement: .topBarTrailing) {
                //                    navActionButton()
                //                }
                //            }
            }
            .safeAreaInset(edge: .bottom) {
                if hasBottomView {
                    bottomView()
                        .frame(maxWidth: .infinity)
                        .background(.regularMaterial)
                }
            }
            .navigationDestination(for: HomeChatNavigationDestination.self) { destination in
                HomeChatLinkNavigationDestination.viewFor(navigationDestination: destination,
                                                          tabRouter: tabRouter)
                .environmentObject(navigationState!)
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
        setupTitle()
    }
    
    func setupTitle() {
        navigationState?.setCustomTitle(customTitle: { ChatListNavTitleView(profile: viewModel.selectedProfile) },
                                        id: UUID().uuidString)
        navigationState?.isTitleVisible = true
    }
    
    @ViewBuilder
    func chatListContentView() -> some View {
        chatDataTypePickerView()
        chatStateContentView()
    }
    
    var bioImage: Image? {
        if let bioUIImage {
            return Image(uiImage: bioUIImage)
        }
        return nil
    }
    
    var bioUIImage: UIImage? {
        if User.instance.getSettings().touchIdActivated {
            return appContext.authentificationService.biometricIcon
        }
        return nil
    }
    
    @ViewBuilder
    func bottomView() -> some View {
        if case .createProfile = viewModel.chatState {
            UDButtonView(text: String.Constants.enable.localized(),
                         icon: bioImage,
                         style: .large(.raisedPrimary),
                         callback: {
                
            })
            .padding()
        }
    }
 
    @ViewBuilder
    func chatStateContentView() -> some View {
        switch viewModel.chatState {
        case .noWallet:
            noWalletStateContentView()
        case .createProfile:
            createProfileStateContentView()
        case .chatsList:
            chatsListStateContentView()
        case .loading:
            loadingStateContentView()
        }
    }
    
    @ViewBuilder
    func noWalletStateContentView() -> some View {
        ChatListEmptyStateView(title: String.Constants.messagingNoWalletsTitle.localized(),
                       subtitle: String.Constants.messagingNoWalletsSubtitle.localized(),
                       icon: .walletIcon,
                       buttonTitle: String.Constants.addWalletTitle.localized(),
                       buttonIcon: .plusIcon18,
                       buttonStyle: .medium(.raisedPrimary),
                       buttonCallback: {
            logButtonPressedAnalyticEvents(button: .createMessagingProfile)
            viewModel.actionButtonPressed()
        })
    }
    
    @ViewBuilder
    func createProfileStateContentView() -> some View {
        ChatCreateMessagingProfileView()
        .frame(maxWidth: .infinity)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(0))
    }
    
    @ViewBuilder
    func loadingStateContentView() -> some View {
        ProgressView()
            .frame(maxWidth: .infinity)
            .frame(height: 400)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
   
    @ViewBuilder
    func chatDataTypePickerView() -> some View {
        switch viewModel.chatState {
        case .noWallet, .createProfile, .loading:
            if true { }
        case .chatsList:
            ChatListDataTypeSelectorView(dataType: $viewModel.selectedDataType)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(0))
        }
    }
    
    @ViewBuilder
    func chatsListStateContentView() -> some View {
        chatsListForSelectedDataTypeView()
    }
    
    @ViewBuilder
    func chatsListForSelectedDataTypeView() -> some View {
        switch viewModel.selectedDataType {
        case .chats:
            chatsListContentView()
        case .communities:
            communitiesListContentView()
        case .channels:
            channelsListContentView()
        }
    }
    
    @ViewBuilder
    func chatsListContentView() -> some View {
        if viewModel.chatsListToShow.isEmpty {
            chatsListEmptyView()
        } else {
            chatsListContentViewFor(chats: viewModel.chatsListToShow,
                                    requests: viewModel.chatsRequests)
        }
    }
    
    @ViewBuilder
    func chatsListEmptyView() -> some View {
        ChatListEmptyStateView(title: String.Constants.messagingChatsListEmptyTitle.localized(),
                       subtitle: String.Constants.messagingChatsListEmptySubtitle.localized(),
                       icon: .messageCircleIcon24,
                       buttonTitle: String.Constants.newMessage.localized(),
                       buttonIcon: .newMessageIcon,
                       buttonStyle: .medium(.raisedPrimary),
                       buttonCallback: {
            logButtonPressedAnalyticEvents(button: .emptyMessagingAction,
                                           parameters: [.value: DataType.chats.rawValue])
            viewModel.searchMode = .chatsOnly
            viewModel.keyboardFocused = true
        })
    }
    
    @ViewBuilder
    func communitiesListContentView() -> some View {
        if viewModel.communitiesListToShow.isEmpty {
            communitiesListEmptyView()
        } else {
            chatsListContentViewFor(chats: viewModel.communitiesListToShow,
                                    requests: [])
        }
    }
    
    @ViewBuilder
    func communitiesListEmptyView() -> some View {
        ChatListEmptyStateView(title: String.Constants.messagingCommunitiesEmptyTitle.localized(),
                               subtitle: String.Constants.messagingCommunitiesEmptySubtitle.localized(),
                               icon: .messageCircleIcon24,
                               buttonTitle: String.Constants.learnMore.localized(),
                               buttonIcon: .infoIcon,
                               buttonStyle: .medium(.raisedPrimary),
                               buttonCallback: {
            logButtonPressedAnalyticEvents(button: .emptyMessagingAction,
                                           parameters: [.value: DataType.communities.rawValue])
            openLink(.communitiesInfo)
        })
    }
    
    @ViewBuilder
    func chatsListContentViewFor(chats: [MessagingChatDisplayInfo],
                                 requests: [MessagingChatDisplayInfo]) -> some View {
        Section {
            chatsRequestsContentView(requests: requests)
            ForEach(chats, id: \.id) { chat in
                chatRowView(chat: chat)
            }
        }
        .listRowBackground(Color.backgroundOverlay)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(4))
    }
    
    @ViewBuilder
    func chatsRequestsContentView(requests: [MessagingChatDisplayInfo]) -> some View {
        if !requests.isEmpty {
            UDCollectionListRowButton(content: {
                ChatListRequestsRowView(dataType: .chats, numberOfRequests: requests.count)
            }, callback: {
                UDVibration.buttonTap.vibrate()
                logButtonPressedAnalyticEvents(button: .chatRequests)
                viewModel.showCurrentDataTypeRequests()
            })
        }
    }
    
    @ViewBuilder
    func chatRowView(chat: MessagingChatDisplayInfo) -> some View {
        UDCollectionListRowButton(content: {
            ChatListChatRowView(chat: chat)
        }, callback: {
            UDVibration.buttonTap.vibrate()
            logButtonPressedAnalyticEvents(button: .chatInList)
            viewModel.openChatWith(conversationState: .existingChat(chat))
        })
    }
  
    @ViewBuilder
    func channelsListContentView() -> some View {
        if viewModel.channelsToShow.isEmpty {
            channelsListEmptyView()
        } else {
            channelsListView()
        }
    }
    
    @ViewBuilder
    func channelsListEmptyView() -> some View {
        ChatListEmptyStateView(title: String.Constants.messagingChannelsEmptyTitle.localized(),
                               subtitle: String.Constants.messagingChannelsEmptySubtitle.localized(),
                               icon: .messageCircleIcon24,
                               buttonTitle: String.Constants.searchApps.localized(),
                               buttonIcon: .searchIcon,
                               buttonStyle: .medium(.raisedTertiary),
                               buttonCallback: {
            logButtonPressedAnalyticEvents(button: .emptyMessagingAction,
                                           parameters: [.value: DataType.channels.rawValue])
            viewModel.searchMode = .channelsOnly
            viewModel.keyboardFocused = true
        })
    }
    
    @ViewBuilder
    func channelsListView() -> some View {
        Section {
            channelsRequestsContentView()
            ForEach(viewModel.channelsToShow, id: \.id) { channel in
                channelRowView(channel: channel)
            }
        }
        .listRowBackground(Color.backgroundOverlay)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(4))
    }
    
    @ViewBuilder
    func channelRowView(channel: MessagingNewsChannel) -> some View {
        UDCollectionListRowButton(content: {
            ChatListChannelRowView(channel: channel)
        }, callback: {
            UDVibration.buttonTap.vibrate()
            logButtonPressedAnalyticEvents(button: .channelInList)
            viewModel.openChannel(channel)
        })
    }
    
    @ViewBuilder
    func channelsRequestsContentView() -> some View {
        if !viewModel.channelsRequests.isEmpty {
            UDCollectionListRowButton(content: {
                ChatListRequestsRowView(dataType: .channels, numberOfRequests: viewModel.channelsRequests.count)
            }, callback: {
                UDVibration.buttonTap.vibrate()
                logButtonPressedAnalyticEvents(button: .channelsSpam)
                viewModel.showCurrentDataTypeRequests()
            })
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
    }
}

#Preview {
    let wallet = MockEntitiesFabric.Wallet.mockEntities().first!
    let profile = UserProfile.wallet(wallet)
    let router = HomeTabRouter(profile: profile)
    
    return ChatListView(viewModel: .init(presentOptions: .default,
                                         router: router))
    .environmentObject(router)
}
