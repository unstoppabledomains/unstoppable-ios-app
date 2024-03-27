//
//  ActivityView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.03.2024.
//

import SwiftUI

struct HomeActivityView: View, ViewAnalyticsLogger {
    
    @EnvironmentObject var tabRouter: HomeTabRouter
    @State private var navigationState: NavigationStateManager?
    @StateObject var viewModel: HomeActivityViewModel
    
    var isOtherScreenPushed: Bool { !tabRouter.activityTabNavPath.isEmpty }
    var analyticsName: Analytics.ViewName { .homeActivity }
    
    var body: some View {
        NavigationViewWithCustomTitle(content: {
            contentList()
            .animation(.default, value: UUID())
            .background(Color.backgroundDefault)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .environmentObject(viewModel)
            .passViewAnalyticsDetails(logger: self)
            .displayError($viewModel.error)
            .background(Color.backgroundMuted2)
            .onReceive(keyboardPublisher) { value in
                viewModel.isKeyboardActive = value
                if !value {
                    UDVibration.buttonTap.vibrate()
                }
            }
            .onChange(of: tabRouter.activityTabNavPath) { path in
                withAnimation {
                    tabRouter.isTabBarVisible = !isOtherScreenPushed
                    if path.isEmpty {
                        setupTitle()
                    } else {
                        setTitleVisibility()
                    }
                }
            }
            .navigationDestination(for: HomeActivityNavigationDestination.self) { destination in
                HomeActivityLinkNavigationDestination.viewFor(navigationDestination: destination,
                                                             tabRouter: tabRouter)
                .environmentObject(navigationState!)
                .environmentObject(viewModel)
            }
            .toolbar(content: {
                // To keep nav bar background visible when scrolling
                ToolbarItem(placement: .topBarLeading) {
                    Color.clear
                }
            })
        }, navigationStateProvider: { state in
            self.navigationState = state
        }, path: $tabRouter.activityTabNavPath)
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension HomeActivityView {
    func onAppear() {
        setupTitle()
    }
    
    func setupTitle() {
        navigationState?.setCustomTitle(customTitle: { HomeProfileSelectorNavTitleView() },
                                        id: UUID().uuidString)
        setTitleVisibility()
    }
    
    func setTitleVisibility() {
        withAnimation {
            navigationState?.isTitleVisible = !isOtherScreenPushed
        }
    }
}

// MARK: - Views
private extension HomeActivityView {
    @ViewBuilder
    func contentList() -> some View {
        List {
            txsList()
        }
        .listStyle(.plain)
    }
    
    @ViewBuilder
    func txsList() -> some View {
        ForEach(viewModel.groupedTxs, id: \.self) { groupedTx in
            HomeActivityTransactionsSectionView(groupedTxs: groupedTx)
        }
    }
}

#Preview {
    let router = MockEntitiesFabric.Home.createHomeTabRouter()
    let viewModel = MockEntitiesFabric.WalletTxs.createViewModelUsing(router)
    
    return HomeActivityView(viewModel: viewModel)
        .environmentObject(router)

}
