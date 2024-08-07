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
    @StateObject private var okLinkFlagTracker = UDMaintenanceModeFeatureFlagTracker(featureFlag: .isMaintenanceOKLinkEnabled)
    @StateObject private var profilesAPIFlagTracker = UDMaintenanceModeFeatureFlagTracker(featureFlag: .isMaintenanceProfilesAPIEnabled)
    @StateObject var viewModel: HomeActivityViewModel

    var isOtherScreenPushed: Bool { !tabRouter.activityTabNavPath.isEmpty }
    var analyticsName: Analytics.ViewName { .homeActivity }
    
    @State private var showingFiltersView = false

    var body: some View {
        NavigationViewWithCustomTitle(content: {
            contentList()
            .animation(.default, value: UUID())
            .background(Color.backgroundDefault)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .passViewAnalyticsDetails(logger: self)
            .displayError($viewModel.error)
            .background(Color.backgroundMuted2)
            .refreshable {
                logAnalytic(event: .didPullToRefresh)
                await viewModel.didPullToRefresh()
            }
            .onReceive(KeyboardService.shared.keyboardOpenedPublisher.receive(on: DispatchQueue.main)) { value in
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
                ToolbarItem(placement: .topBarTrailing) {
                    filterButtonView()
                }
            })
            .sheet(isPresented: $showingFiltersView, content: {
                HomeActivityFilterView()
            })
            .environmentObject(viewModel)
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
        if okLinkFlagTracker.maintenanceData?.isCurrentlyEnabled == true {
            MaintenanceDetailsEmbeddedView(serviceType: .activity,
                                           maintenanceData: okLinkFlagTracker.maintenanceData)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if profilesAPIFlagTracker.maintenanceData?.isCurrentlyEnabled == true {
            MaintenanceDetailsEmbeddedView(serviceType: .activity,
                                           maintenanceData: profilesAPIFlagTracker.maintenanceData)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.groupedTxs.isEmpty,
           !viewModel.isLoadingMore {
            GeometryReader { geometry in
                /// ScrollView needed to keep PTR functionality
                ScrollView {
                    HomeActivityEmptyView()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        } else {
            txsList()
        }
    }
    
    @ViewBuilder
    func txsList() -> some View {
        List {
            ForEach(viewModel.groupedTxs, id: \.self) { groupedTx in
                HomeActivityTransactionsSectionView(groupedTxs: groupedTx)
            }
        }.environment(\.defaultMinListRowHeight, 28)
            .listStyle(.plain)
            .listRowSpacing(0)
    }
    
    @ViewBuilder
    func filterButtonView() -> some View {
        ZStack(alignment: .topTrailing) {
            Button {
                UDVibration.buttonTap.vibrate()
                showingFiltersView = true
            } label: {
                Image.filter
                    .resizable()
                    .foregroundStyle(Color.foregroundDefault)
                    .squareFrame(28)
            }
            
            if viewModel.isFiltersApplied {
                Circle()
                    .squareFrame(16)
                    .foregroundStyle(Color.foregroundAccent)
                    .offset(x: 6, y: -2)
            }
        }
    }
}

#Preview {
    let router = MockEntitiesFabric.Home.createHomeTabRouter()
    let viewModel = MockEntitiesFabric.WalletTxs.createViewModelUsing(router)
    
    return HomeActivityView(viewModel: viewModel)
        .environmentObject(router)
}
