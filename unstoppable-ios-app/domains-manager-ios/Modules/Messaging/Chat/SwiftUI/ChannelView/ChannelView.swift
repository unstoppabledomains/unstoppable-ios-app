//
//  ChannelView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.02.2024.
//

import SwiftUI

struct ChannelView: View, ViewAnalyticsLogger {
    
    @EnvironmentObject var navigationState: NavigationStateManager
    @StateObject var viewModel: ChannelViewModel
    var analyticsName: Analytics.ViewName { .chatDialog }
    var additionalAppearAnalyticParameters: Analytics.EventParameters { [.channelName: viewModel.channel.name] }
    
    var body: some View {
        ZStack {
            if !viewModel.isLoading,
               viewModel.feed.isEmpty {
                ChannelFeedEmptyView()
            } else {
                chatContentView()
                    .opacity(viewModel.channelState == .loading ? 0 : 1)
            }
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .environment(\.analyticsViewName, analyticsName)
        .environment(\.analyticsAdditionalProperties, additionalAppearAnalyticParameters)
        .displayError($viewModel.error)
        .background(Color.backgroundMuted2)
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
                    .background(.regularMaterial)
            }
        }
        .onAppear(perform: onAppear)
    }
    
}

// MARK: - Private methods
private extension ChannelView {
    func onAppear() {
        navigationState.setCustomTitle(customTitle: { ChatNavTitleView(titleType: .channel(viewModel.channel)) },
                                       id: UUID().uuidString)
        navigationState.isTitleVisible = true
    }
    
    @ViewBuilder
    func chatContentView() -> some View {
        ScrollViewReader { proxy in
            List {
                ForEach(viewModel.feed.reversed(), id: \.id) { feed in
                    messageRow(feed)
                        .id(feed.id)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.hidden)
            .listStyle(.plain)
            .clearListBackground()
            .animation(.default, value: UUID())
            .onChange(of: viewModel.scrollToFeed) { scrollToFeed in
                proxy.scrollTo(scrollToFeed?.id, anchor: .top)
            }
        }
    }
    
    @ViewBuilder
    func messageRow(_ feed: MessagingNewsChannelFeed) -> some View {
        ChannelFeedRowView(feed: feed)
            .onAppear {
                viewModel.willDisplayFeed(feed)
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
        switch viewModel.channelState {
        case .loading, .viewChannel:
            return false
        default:
            return true
        }
    }
    
    @ViewBuilder
    func bottomView() -> some View {
        switch viewModel.channelState {
        case .loading, .viewChannel:
            if true { }
        case .joinChannel:
            joinChannelBottomView()
        }
    }
    
    @ViewBuilder
    func joinChannelBottomView() -> some View {
        UDButtonView(text: String.Constants.join.localized(),
                     style: .large(.raisedPrimary)) {
            logButtonPressedAnalyticEvents(button: .join)
            viewModel.joinButtonPressed()
        }
                     .padding()
    }
}

// MARK: - Open methods
extension ChannelView {
    enum State {
        case loading
        case viewChannel
        case joinChannel
    }
    
    struct NavAction {
        let type: NavActionType
        let callback: EmptyCallback
    }
    
    enum NavActionType {
        case viewInfo, leave
        
        var title: String {
            switch self {
            case .viewInfo:
                return String.Constants.viewInfo.localized()
            case .leave:
                return String.Constants.leave.localized()
            }
        }
        
        var icon: UIImage {
            switch self {
            case .viewInfo:
                return .arrowUpRight
            case .leave:
                return .systemRectangleArrowRight
            }
        }
        
        var isDestructive: Bool {
            switch self {
            case .viewInfo:
                return false
            case .leave:
                return true
            }
        }
    }
}

#Preview {
    NavigationViewWithCustomTitle(content: {
        ChannelView(viewModel: .init(profile: .init(id: "",
                                                    wallet: "",
                                                    serviceIdentifier: .push),
                                     channel: MockEntitiesFabric.Messaging.mockChannel(name: "Preview")))
    }, navigationStateProvider: { state in
    }, path: .constant([0]))
}
